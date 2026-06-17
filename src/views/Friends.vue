<template>
  <div class="friends-page">
    <!-- ==================== 左侧栏 ==================== -->
    <div class="friends-left">
      <!-- 标题 -->
      <h2 class="friends-title">我的好友</h2>

      <!-- 搜索框 -->
      <div class="friends-search">
        <el-input
          v-model="searchKeyword"
          placeholder="通过ID或用户名搜索..."
          :prefix-icon="Search"
          clearable
          @input="onSearch"
        />
      </div>

      <!-- 统计栏 -->
      <div class="friends-stats-bar">
        <span class="stat-item" :class="{ active: activeTab === 'friends' }" @click="showTab('friends')">
          好友 <strong>{{ friendCount }}</strong>
        </span>
        <span class="stat-item" :class="{ active: activeTab === 'following' }" @click="showTab('following')">
          关注 <strong>{{ followingCount }}</strong>
        </span>
        <span class="stat-item" :class="{ active: activeTab === 'followers' }" @click="showTab('followers')">
          粉丝 <strong>{{ followerCount }}</strong>
        </span>
      </div>

      <!-- 标签页 -->
      <div class="friends-tabs">
        <button
          class="friends-tab"
          :class="{ active: activeTab === 'friends' }"
          @click="showTab('friends')"
        >好友</button>
        <button
          class="friends-tab"
          :class="{ active: activeTab === 'following' }"
          @click="showTab('following')"
        >关注</button>
        <button
          class="friends-tab"
          :class="{ active: activeTab === 'followers' }"
          @click="showTab('followers')"
        >粉丝</button>
      </div>

      <!-- 用户列表 -->
      <div class="friends-list" v-loading="loading">
        <div class="friends-list-end" v-if="displayList.length === 0 && !loading">
          <p v-if="searchKeyword">未找到匹配的用户</p>
          <p v-else-if="activeTab === 'friends'">暂无好友，去发现页认识新朋友吧</p>
          <p v-else-if="activeTab === 'following'">还没有关注任何人</p>
          <p v-else>还没有粉丝</p>
        </div>
        <div
          class="friend-item"
          :class="{ active: (selectedFriend?.userId || selectedFriend?.id) === (user.userId || user.id) }"
          v-for="user in displayList"
          :key="user.userId || user.id"
          @click="selectUser(user)"
        >
          <div class="friend-avatar-wrap">
            <el-avatar :size="44" :src="user.avatar">
              <el-icon :size="22"><User /></el-icon>
            </el-avatar>
          </div>
          <div class="friend-item-info">
            <span class="friend-item-name">{{ user.nickname }}</span>
            <span class="friend-item-bio">{{ user.bio || '这个人很懒，什么都没写' }}</span>
          </div>
          <div class="friend-item-actions">
            <template v-if="activeTab === 'friends'">
              <button class="btn-capsule" @click.stop="viewCapsules(user)">胶囊</button>
              <button class="btn-chat" @click.stop="startChat(user)">私聊</button>
              <button class="btn-unfollow-sm" @click.stop="unfollowUser(user)" title="取消关注">×</button>
            </template>
            <template v-else>
              <template v-if="(user.userId || user.id) === currentUserId">
                <button class="btn-self" disabled>自己</button>
              </template>
              <template v-else>
                <button
                  v-if="user.isFollowing && user.isFollowedBy"
                  class="btn-following"
                  @click.stop="unfollowUser(user)"
                >互相关注</button>
                <button
                  v-else-if="user.isFollowing"
                  class="btn-following"
                  @click.stop="unfollowUser(user)"
                >已关注</button>
                <button
                  v-else
                  class="btn-follow"
                  @click.stop="followUser(user)"
                >关注</button>
              </template>
            </template>
          </div>
        </div>
      </div>

      <!-- 推荐/发现 区域 -->
      <div class="discover-section" v-if="recommendations.length > 0 && activeTab !== 'followers'">
        <div class="recommend-card">
          <div class="recommend-header">
            <span class="recommend-label">推荐关注</span>
          </div>
          <div class="recommend-item" v-for="rec in recommendations" :key="rec.userId || rec.id">
            <el-avatar :size="36" :src="rec.avatar">
              <el-icon :size="18"><User /></el-icon>
            </el-avatar>
            <div class="recommend-info">
              <span class="recommend-name">{{ rec.nickname }}</span>
              <span class="recommend-bio">{{ rec.bio || '你可能认识的人' }}</span>
            </div>
            <button class="btn-follow-sm" @click="followUser(rec)">关注</button>
          </div>
        </div>
      </div>
    </div>

    <!-- ==================== 右侧栏 ==================== -->
    <div class="friends-right">
      <template v-if="selectedFriend">
        <!-- 用户详情头部 -->
        <div class="chat-header">
          <div class="chat-header-info">
            <div class="chat-avatar-wrap">
              <el-avatar :size="44" :src="selectedFriend.avatar">
                <el-icon :size="22"><User /></el-icon>
              </el-avatar>
            </div>
            <div class="chat-header-text">
              <span class="chat-friend-name">{{ selectedFriend.nickname }}</span>
              <span class="chat-friend-status" v-if="selectedFriend.relationType === 'friend'">好友</span>
            </div>
          </div>
          <div class="chat-header-actions">
            <template v-if="(selectedFriend.userId || selectedFriend.id) === currentUserId">
              <button class="btn-self" disabled>自己</button>
            </template>
            <template v-else>
              <button
                v-if="selectedFriend.isFollowing"
                class="btn-following"
                @click="unfollowUser(selectedFriend)"
              >{{ selectedFriend.isFollowing && selectedFriend.isFollowedBy ? '互相关注' : '已关注' }}</button>
              <button
                v-else
                class="btn-follow"
                @click="followUser(selectedFriend)"
              >关注</button>
            </template>
          </div>
        </div>

        <!-- 聊天记录 -->
        <div class="chat-messages" ref="chatMessagesRef">
          <div class="chat-empty" v-if="!isMutual">
            <div class="chat-empty-icon">🔒</div>
            <p>互相关注后即可开始聊天</p>
          </div>
          <div class="chat-empty" v-else-if="chatMessages.length === 0">
            <div class="chat-empty-icon">💬</div>
            <p>开始和 {{ selectedFriend.nickname }} 聊天吧</p>
          </div>
          <div
            class="chat-msg-row"
            :class="{ 'is-mine': msg.senderId === currentUserId }"
            v-for="(msg, idx) in chatMessages"
            :key="idx"
          >
            <el-avatar :size="32" :src="msg.senderId === currentUserId ? myAvatar : selectedFriend.avatar" class="chat-msg-avatar">
              <el-icon :size="16"><User /></el-icon>
            </el-avatar>
            <div class="chat-msg-body">
              <div class="chat-msg-bubble">
                {{ msg.content }}
              </div>
              <span class="chat-msg-time">{{ msg.time }}</span>
            </div>
          </div>
        </div>

        <!-- 消息输入 -->
        <div class="chat-input-area" v-if="isMutual">
          <div class="chat-input-row">
            <input
              v-model="messageText"
              placeholder="输入消息..."
              maxlength="1000"
              @keyup.enter="sendMessage"
              class="chat-input"
            />
            <button class="chat-send-btn" :disabled="!messageText.trim()" @click="sendMessage">
              <el-icon :size="18"><Promotion /></el-icon>
            </button>
          </div>
        </div>
      </template>

      <!-- 空状态 -->
      <div class="chat-empty-state" v-else>
        <div class="empty-icon-wrap">
          <el-icon :size="64"><ChatLineRound /></el-icon>
        </div>
        <p class="empty-title">选择一位用户</p>
        <p class="empty-desc">从左侧列表选择好友或用户查看详情</p>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, watch, nextTick, onMounted, onUnmounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Search, User, Promotion, ChatLineRound } from '@element-plus/icons-vue'

const currentUserId = (() => {
  try {
    const u = JSON.parse(localStorage.getItem('user') || 'null')
    return u?.id || null
  } catch { return null }
})()

const myAvatar = (() => {
  try {
    const u = JSON.parse(localStorage.getItem('user') || 'null')
    return u?.avatar || ''
  } catch { return '' }
})()

// ---- 状态 ----
const searchKeyword = ref('')
const activeTab = ref('friends')
const selectedFriend = ref(null)
const messageText = ref('')
const chatMessagesRef = ref(null)
const loading = ref(false)
const searchTimer = ref(null)

const friends = ref([])
const following = ref([])
const followers = ref([])
const recommendations = ref([])
const chatMessages = ref([])
const friendCount = ref(0)
const followingCount = ref(0)
const followerCount = ref(0)

// ---- 计算属性 ----
const displayList = computed(() => {
  const map = { friends: friends.value, following: following.value, followers: followers.value }
  let list = map[activeTab.value] || []
  if (searchKeyword.value.trim()) {
    const kw = searchKeyword.value.trim().toLowerCase()
    list = list.filter(u =>
      (u.nickname || '').toLowerCase().includes(kw) ||
      String(u.userId || u.id).includes(kw)
    )
  }
  return list
})

const isMutual = computed(() => {
  if (!selectedFriend.value) return false
  const f = selectedFriend.value
  return (f.isFollowing && f.isFollowedBy) || f.relationType === 'friend'
})

// ---- 标签切换 ----
const showTab = (tab) => {
  activeTab.value = tab
  if (tab === 'friends') loadFriends()
  else if (tab === 'following') loadFollowing()
  else if (tab === 'followers') loadFollowers()
}

// ---- 数据加载 ----
const loadFriends = async () => {
  try {
    const res = await window.$axios.get('/friends')
    if (res?.code === 200) friends.value = res.data || []
  } catch (e) { console.error('加载好友失败:', e) }
}

const loadFollowing = async () => {
  try {
    const res = await window.$axios.get(`/friends/following/${currentUserId}`)
    if (res?.code === 200) following.value = res.data || []
  } catch (e) { console.error('加载关注列表失败:', e) }
}

const loadFollowers = async () => {
  try {
    const res = await window.$axios.get(`/friends/followers/${currentUserId}`)
    if (res?.code === 200) followers.value = res.data || []
  } catch (e) { console.error('加载粉丝列表失败:', e) }
}

const loadStats = async () => {
  try {
    const res = await window.$axios.get(`/friends/stats/${currentUserId}`)
    if (res?.code === 200) {
      friendCount.value = res.data.friendCount || 0
      followingCount.value = res.data.followingCount || 0
      followerCount.value = res.data.followerCount || 0
    }
  } catch (e) { console.error('加载统计失败:', e) }
}

const loadRecommendations = async () => {
  try {
    const res = await window.$axios.get('/friends/recommendations')
    if (res?.code === 200) recommendations.value = res.data || []
  } catch (e) {}
}

// ---- 关注/取消关注 ----
const followUser = async (user) => {
  const uid = user.userId || user.id
  try {
    await window.$axios.post(`/friends/follow/${uid}`)
    ElMessage.success(`已关注 ${user.nickname}`)
    // 立即更新本地状态，不等接口刷新
    user.isFollowing = true
    user.isFollowedBy = user.isFollowedBy || false
    updateSelectedFriendState(uid, true)
    refreshCurrentLists()
  } catch (e) {
    const msg = e?.response?.data?.message || '操作失败'
    ElMessage.error(msg)
  }
}

const unfollowUser = async (user) => {
  const uid = user.userId || user.id
  try {
    await ElMessageBox.confirm(`确定取消关注 ${user.nickname}？`, '取消关注', {
      confirmButtonText: '确定', cancelButtonText: '取消', type: 'warning'
    })
    await window.$axios.delete(`/friends/follow/${uid}`)
    ElMessage.info(`已取消关注 ${user.nickname}`)
    // 立即更新本地状态，不等接口刷新
    user.isFollowing = false
    updateSelectedFriendState(uid, false)
    refreshCurrentLists()
  } catch (e) {
    if (e !== 'cancel' && e?.message !== 'cancel') {
      const msg = e?.response?.data?.message || '操作失败'
      ElMessage.error(msg)
    }
  }
}

const updateSelectedFriendState = (uid, following) => {
  if (!selectedFriend.value) return
  const sid = selectedFriend.value.userId || selectedFriend.value.id
  if (sid === uid) {
    selectedFriend.value = { ...selectedFriend.value, isFollowing: following }
  }
}

const refreshCurrentLists = async () => {
  await Promise.all([loadStats(), loadRecommendations()])
  if (activeTab.value === 'friends') await loadFriends()
  else if (activeTab.value === 'following') await loadFollowing()
  else if (activeTab.value === 'followers') await loadFollowers()
}

// ---- 搜索 ----
const onSearch = () => {
  if (searchTimer.value) clearTimeout(searchTimer.value)
  searchTimer.value = setTimeout(async () => {
    const kw = searchKeyword.value.trim()
    if (!kw) {
      showTab(activeTab.value)
      return
    }
    try {
      const res = await window.$axios.get('/friends/search', { params: { keyword: kw } })
      if (res?.code === 200) {
        const results = res.data || []
        if (activeTab.value === 'friends') friends.value = results
        else if (activeTab.value === 'following') following.value = results
        else if (activeTab.value === 'followers') followers.value = results
      }
    } catch (e) { console.error('搜索失败:', e) }
  }, 300)
}

// ---- 选择用户 ----
const selectUser = (user) => {
  const fid = user.userId || user.id
  if (selectedFriend.value && (selectedFriend.value.userId || selectedFriend.value.id) === fid) return
  selectedFriend.value = { ...user, userId: fid }
  if (isMutual.value) loadMessages(fid)
}

const startChat = async (user) => {
  const fid = user.userId || user.id
  selectedFriend.value = { ...user, userId: fid }
  if (isMutual.value) await loadMessages(fid)
}

// ---- 聊天 ----
const loadMessages = async (friendUserId) => {
  try {
    const res = await window.$axios.get(`/friends/${friendUserId}/messages`)
    if (res?.code === 200) {
      chatMessages.value = res.data || []
    }
  } catch (e) {
    chatMessages.value = []
  }
  nextTick(() => scrollChatToBottom())
}

const scrollChatToBottom = () => {
  if (chatMessagesRef.value) {
    chatMessagesRef.value.scrollTop = chatMessagesRef.value.scrollHeight
  }
}

const sendMessage = async () => {
  const text = messageText.value.trim()
  if (!text || !selectedFriend.value) return
  const fid = selectedFriend.value.userId || selectedFriend.value.id
  messageText.value = ''
  try {
    const res = await window.$axios.post(`/friends/${fid}/messages`, { content: text })
    if (res?.code === 201 || res?.code === 200) {
      if (res.data) chatMessages.value.push(res.data)
      nextTick(() => scrollChatToBottom())
    }
  } catch (e) {
    chatMessages.value.push({ senderId: currentUserId, content: text, time: '刚刚' })
    ElMessage.warning('消息发送失败')
  }
}

const viewCapsules = (user) => {
  ElMessage.info(`查看 ${user.nickname} 的时光胶囊（功能开发中）`)
}

// ---- 聊天轮询 ----
let pollTimer = null
const startPolling = () => {
  stopPolling()
  pollTimer = setInterval(async () => {
    if (selectedFriend.value && isMutual.value) {
      const fid = selectedFriend.value.userId || selectedFriend.value.id
      try {
        const res = await window.$axios.get(`/friends/${fid}/messages`)
        if (res?.code === 200) chatMessages.value = res.data || []
      } catch {}
    }
  }, 10000)
}

const stopPolling = () => {
  if (pollTimer) { clearInterval(pollTimer); pollTimer = null }
}

watch(() => selectedFriend.value, (val) => {
  if (val) startPolling()
  else stopPolling()
})

// ---- 生命周期 ----
onMounted(async () => {
  loading.value = true
  await Promise.all([loadFriends(), loadStats(), loadRecommendations()])
  loading.value = false
})

onUnmounted(() => {
  stopPolling()
  if (searchTimer.value) clearTimeout(searchTimer.value)
})
</script>

<style scoped>
/* ==================== 整体布局 ==================== */
.friends-page {
  display: flex;
  height: calc(100vh - 108px);
  background: #ffffff;
  border-radius: 16px;
  overflow: hidden;
  box-shadow: 0 2px 16px rgba(0, 0, 0, 0.06);
}

/* ==================== 左侧栏 ==================== */
.friends-left {
  width: 380px;
  flex-shrink: 0;
  display: flex;
  flex-direction: column;
  border-right: 1px solid #eef1f5;
  background: #fafbfc;
}

.friends-title {
  font-size: 22px;
  font-weight: 700;
  color: #1F2F3D;
  margin: 0;
  padding: 20px 20px 0;
}

/* 搜索框 */
.friends-search {
  padding: 16px 20px;
}

.friends-search :deep(.el-input__wrapper) {
  border-radius: 24px;
  background: #f0f2f5;
  border: none;
  box-shadow: none;
  padding: 4px 16px;
  transition: all 0.2s;
}

.friends-search :deep(.el-input__wrapper:hover),
.friends-search :deep(.el-input__wrapper.is-focus) {
  background: #e8ecf1;
  box-shadow: 0 0 0 1px #4a90d9 inset;
}

.friends-search :deep(.el-input__inner) {
  font-size: 14px;
  color: #1F2F3D;
}

.friends-search :deep(.el-input__inner::placeholder) {
  color: #b0b8c1;
}

/* 统计栏 */
.friends-stats-bar {
  display: flex;
  gap: 4px;
  padding: 0 20px 12px;
}

.stat-item {
  padding: 4px 12px;
  border-radius: 14px;
  font-size: 13px;
  color: #8A9AAA;
  cursor: pointer;
  transition: all 0.2s;
  background: #f0f2f5;
}

.stat-item:hover { color: #5A6A7A; background: #e8ecf1; }

.stat-item.active {
  color: #4a90d9;
  background: #eef4fb;
}

.stat-item strong {
  font-weight: 700;
}

/* 标签页 */
.friends-tabs {
  display: flex;
  padding: 0 20px;
  border-bottom: 1px solid #eef1f5;
  gap: 0;
}

.friends-tab {
  padding: 10px 18px;
  background: transparent;
  border: none;
  border-bottom: 2px solid transparent;
  font-size: 14px;
  color: #8A9AAA;
  cursor: pointer;
  transition: all 0.2s;
  font-weight: 500;
}

.friends-tab:hover { color: #5A6A7A; }

.friends-tab.active {
  color: #4a90d9;
  border-bottom-color: #4a90d9;
}

/* ==================== 好友列表 ==================== */
.friends-list {
  flex: 1;
  overflow-y: auto;
  padding: 8px 0;
}

.friends-list::-webkit-scrollbar { width: 4px; }
.friends-list::-webkit-scrollbar-thumb { background: #d0d5dd; border-radius: 2px; }

.friends-list-end {
  text-align: center;
  padding: 24px 0;
  color: #b0b8c1;
  font-size: 13px;
}

.friend-item {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 10px 20px;
  cursor: pointer;
  transition: background 0.15s;
}

.friend-item:hover { background: #f0f2f5; }
.friend-item.active { background: #eef4fb; }

.friend-avatar-wrap {
  position: relative;
  flex-shrink: 0;
}

.friend-item-info {
  flex: 1;
  min-width: 0;
  display: flex;
  flex-direction: column;
  gap: 3px;
}

.friend-item-name {
  font-size: 15px;
  font-weight: 600;
  color: #1F2F3D;
}

.friend-item-bio {
  font-size: 12px;
  color: #8A9AAA;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.friend-item-actions {
  display: flex;
  gap: 6px;
  flex-shrink: 0;
}

/* 按钮 */
.btn-capsule {
  padding: 4px 12px;
  background: transparent;
  color: #8A9AAA;
  border: 1px solid #e0e5ec;
  border-radius: 12px;
  font-size: 12px;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-capsule:hover { border-color: #4a90d9; color: #4a90d9; }

.btn-chat {
  padding: 4px 12px;
  background: #4a90d9;
  color: #fff;
  border: none;
  border-radius: 12px;
  font-size: 12px;
  cursor: pointer;
  transition: background 0.2s;
}

.btn-chat:hover { background: #3a7bc8; }

.btn-follow {
  padding: 4px 14px;
  background: #4a90d9;
  color: #fff;
  border: none;
  border-radius: 14px;
  font-size: 12px;
  cursor: pointer;
  transition: background 0.2s;
  white-space: nowrap;
}

.btn-follow:hover { background: #3a7bc8; }

.btn-following {
  padding: 4px 14px;
  background: transparent;
  color: #4a90d9;
  border: 1px solid #4a90d9;
  border-radius: 14px;
  font-size: 12px;
  cursor: pointer;
  transition: all 0.2s;
  white-space: nowrap;
}

.btn-following:hover { background: #fef0f0; border-color: #e74c3c; color: #e74c3c; }

.btn-mutual {
  padding: 4px 14px;
  background: #eef4fb;
  color: #4a90d9;
  border: none;
  border-radius: 14px;
  font-size: 12px;
  cursor: default;
  white-space: nowrap;
}

.btn-follow-sm {
  padding: 4px 12px;
  background: #4a90d9;
  color: #fff;
  border: none;
  border-radius: 14px;
  font-size: 12px;
  cursor: pointer;
  transition: background 0.2s;
  white-space: nowrap;
}

.btn-follow-sm:hover { background: #3a7bc8; }

.btn-unfollow-sm {
  width: 22px;
  height: 22px;
  padding: 0;
  background: transparent;
  color: #b0b8c1;
  border: none;
  border-radius: 50%;
  font-size: 16px;
  line-height: 22px;
  cursor: pointer;
  transition: all 0.2s;
  flex-shrink: 0;
}

.btn-unfollow-sm:hover { color: #e74c3c; background: #fef0f0; }

.btn-self {
  padding: 4px 14px;
  background: #f0f2f5;
  color: #b0b8c1;
  border: none;
  border-radius: 14px;
  font-size: 12px;
  cursor: default;
  white-space: nowrap;
}

/* ==================== 发现/推荐 ==================== */
.discover-section {
  padding: 12px 20px;
  border-top: 1px solid #eef1f5;
  flex-shrink: 0;
}

.recommend-card {
  background: linear-gradient(135deg, #eef4fb 0%, #f8f0ff 100%);
  border-radius: 12px;
  padding: 12px;
}

.recommend-header {
  display: flex;
  align-items: center;
  gap: 6px;
  margin-bottom: 8px;
}

.recommend-label {
  font-size: 13px;
  font-weight: 600;
  color: #5A6A7A;
}

.recommend-item {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 6px 0;
}

.recommend-item + .recommend-item {
  border-top: 1px solid rgba(0, 0, 0, 0.05);
}

.recommend-info {
  flex: 1;
  min-width: 0;
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.recommend-name {
  font-size: 14px;
  font-weight: 600;
  color: #1F2F3D;
}

.recommend-bio {
  font-size: 12px;
  color: #8A9AAA;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

/* ==================== 右侧栏 ==================== */
.friends-right {
  flex: 1;
  min-width: 0;
  display: flex;
  flex-direction: column;
  background: #ffffff;
}

.chat-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 16px 24px;
  border-bottom: 1px solid #eef1f5;
  flex-shrink: 0;
}

.chat-header-info {
  display: flex;
  align-items: center;
  gap: 12px;
}

.chat-avatar-wrap {
  position: relative;
}

.chat-header-text {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.chat-friend-name {
  font-size: 16px;
  font-weight: 600;
  color: #1F2F3D;
}

.chat-friend-status {
  font-size: 12px;
  color: #4a90d9;
}

.chat-header-actions {
  display: flex;
  gap: 8px;
}

.chat-messages {
  flex: 1;
  overflow-y: auto;
  padding: 20px 24px;
  display: flex;
  flex-direction: column;
  gap: 16px;
  background: #fafbfc;
}

.chat-messages::-webkit-scrollbar { width: 4px; }
.chat-messages::-webkit-scrollbar-thumb { background: #d0d5dd; border-radius: 2px; }

.chat-empty {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  height: 100%;
  color: #b0b8c1;
  gap: 12px;
}

.chat-empty-icon { font-size: 48px; opacity: 0.6; }
.chat-empty p { margin: 0; font-size: 14px; }

.chat-msg-row {
  display: flex;
  gap: 10px;
  align-items: flex-start;
  max-width: 70%;
}

.chat-msg-row.is-mine {
  flex-direction: row-reverse;
  align-self: flex-end;
}

.chat-msg-avatar { flex-shrink: 0; }

.chat-msg-body {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.chat-msg-row.is-mine .chat-msg-body { align-items: flex-end; }

.chat-msg-bubble {
  padding: 10px 16px;
  border-radius: 18px;
  font-size: 14px;
  line-height: 1.5;
  word-break: break-word;
  background: #ffffff;
  color: #1F2F3D;
  box-shadow: 0 1px 4px rgba(0, 0, 0, 0.06);
}

.chat-msg-row.is-mine .chat-msg-bubble {
  background: #4a90d9;
  color: #ffffff;
}

.chat-msg-time {
  font-size: 11px;
  color: #b0b8c1;
  padding: 0 4px;
}

.chat-input-area {
  flex-shrink: 0;
  padding: 16px 24px;
  border-top: 1px solid #eef1f5;
}

.chat-input-row {
  display: flex;
  align-items: center;
  gap: 10px;
  background: #f5f7fa;
  border-radius: 24px;
  padding: 4px 4px 4px 16px;
  transition: box-shadow 0.2s;
}

.chat-input-row:focus-within { box-shadow: 0 0 0 1px #4a90d9; }

.chat-input {
  flex: 1;
  border: none;
  background: transparent;
  font-size: 14px;
  padding: 8px 0;
  outline: none;
  color: #1F2F3D;
}

.chat-input::placeholder { color: #b0b8c1; }

.chat-send-btn {
  width: 36px;
  height: 36px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: #4a90d9;
  color: #fff;
  border: none;
  border-radius: 50%;
  cursor: pointer;
  transition: background 0.2s;
  flex-shrink: 0;
}

.chat-send-btn:hover:not(:disabled) { background: #3a7bc8; }
.chat-send-btn:disabled { background: #d0d5dd; cursor: not-allowed; }

.chat-empty-state {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 12px;
  color: #b0b8c1;
}

.empty-icon-wrap {
  width: 100px;
  height: 100px;
  border-radius: 50%;
  background: #f5f7fa;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #d0d5dd;
}

.empty-title { font-size: 18px; font-weight: 600; color: #8A9AAA; margin: 0; }
.empty-desc { font-size: 14px; color: #b0b8c1; margin: 0; }

/* ==================== 响应式 ==================== */
@media (max-width: 1024px) {
  .friends-left { width: 320px; }
}

@media (max-width: 768px) {
  .friends-page {
    flex-direction: column;
    height: auto;
    min-height: calc(100vh - 108px);
  }

  .friends-left {
    width: 100%;
    max-height: 50vh;
    border-right: none;
    border-bottom: 1px solid #eef1f5;
  }

  .friends-right { min-height: 50vh; }
  .chat-msg-row { max-width: 85%; }
}

@media (max-width: 480px) {
  .friends-title { font-size: 18px; padding: 16px 16px 0; }
  .friends-search { padding: 12px 16px; }
  .friends-stats-bar { padding: 0 16px 8px; }
  .friends-tabs { padding: 0 16px; }
  .friend-item { padding: 10px 16px; }
  .chat-header { padding: 12px 16px; }
  .chat-messages { padding: 16px; }
  .chat-input-area { padding: 12px 16px; }
}
</style>
