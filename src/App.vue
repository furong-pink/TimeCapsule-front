<!-- src/App.vue -->
<template>
  <el-config-provider>
    <div class="app-wrapper">
      <!-- 登录页面：不显示导航栏 -->
      <div v-if="isLoginPage" class="login-page-wrapper">
        <router-view />
      </div>
      
      <!-- 主应用页面：显示完整布局 -->
      <el-container v-else class="app-container">
        <!-- 顶部栏 -->
        <el-header class="app-header">
          <div class="header-title">时光胶囊</div>
          <div class="header-right" v-if="isLoggedIn">
            <!-- 消息通知 -->
            <el-dropdown trigger="click" @command="handleNotificationCommand" style="margin-right: 20px;">
              <span class="notification-icon">
                <el-badge :value="unreadCount > 0 ? 1 : 0" :hidden="unreadCount === 0" class="item" :is-dot="true">
                  <el-icon :size="20"><Message /></el-icon>
                </el-badge>
              </span>
              <template #dropdown>
                <el-dropdown-menu class="notification-dropdown">
                  <div class="notification-header">
                    <span>{{ '消息通知' }}</span>
                    <el-button link type="primary" size="small" @click="markAllRead">{{ '全部标记为已读' }}</el-button>
                  </div>
                  <div v-if="notifications.length === 0" class="no-notifications">
                    {{ '暂无消息' }}
                  </div>
                  <div class="notification-list">
                    <el-dropdown-item v-for="item in notifications" :key="item.id" :command="item" class="notification-item">
                      <div class="notification-content">
                        <div class="notification-header-row">
                          <el-tag size="small" :type="item.type === 'APPROVAL' ? 'success' : 'danger'" class="notification-tag">
                            {{ item.type === 'APPROVAL' ? '审核通过' : '审核拒绝' }}
                          </el-tag>
                          <span class="capsule-title" :title="'您的胶囊《' + item.content + '》'">您的胶囊《{{ item.content.length > 12 ? item.content.substring(0, 12) + '...' : item.content }}》</span>
                        </div>
                        <div class="notification-body">
                          {{ item.type === 'APPROVAL' ? '恭喜您，您的胶囊审核通过' : '拒绝理由：' + item.reason }}
                        </div>
                        <div class="notification-time">{{ formatDate(item.createdAt) }}</div>
                      </div>
                    </el-dropdown-item>
                  </div>
                </el-dropdown-menu>
              </template>
            </el-dropdown>
            
            <el-dropdown @command="handleCommand" trigger="click" @visible-change="handleDropdownVisibleChange">
              <span class="user-info" :class="{ 'dropdown-open': userMenuOpen }">
                <el-avatar :size="32" :src="userInfo.avatar" style="margin-right: 8px;">
                  <el-icon><User /></el-icon>
                </el-avatar>
                <span class="username">{{ userInfo.nickname || '用户' }}</span>
                <el-icon class="dropdown-icon"><ArrowDown /></el-icon>
              </span>
              <template #dropdown>
                <el-dropdown-menu>
                  <el-dropdown-item command="logout">
                    <el-icon><SwitchButton /></el-icon>
                    退出登录
                  </el-dropdown-item>
                </el-dropdown-menu>
              </template>
            </el-dropdown>
          </div>
        </el-header>

        <el-container class="main-layout">
          <!-- 左侧导航菜单 -->
          <el-aside class="app-aside" width="200px">
            <el-menu
              :default-active="route.path"
              router
              background-color="#f5f7fa"
              text-color="#333"
              active-text-color="#409EFF"
              :unique-opened="true"
              class="sidebar-menu"
            >
              <el-menu-item v-if="userInfo.role !== 'ADMIN'" index="/">
                <el-icon><House /></el-icon>
                <span>{{ '首页' }}</span>
              </el-menu-item>
              <el-menu-item v-if="userInfo.role !== 'ADMIN'" index="/capsule/create">
                <el-icon><Edit /></el-icon>
                <span>{{ '创建胶囊' }}</span>
              </el-menu-item>
              <el-menu-item v-if="userInfo.role !== 'ADMIN'" index="/timeline">
                <el-icon><Timer /></el-icon>
                <span>{{ '时间轴' }}</span>
              </el-menu-item>
              <el-menu-item v-if="userInfo.role !== 'ADMIN'" index="/goals">
                <el-icon><Trophy /></el-icon>
                <span>{{ '我的目标' }}</span>
              </el-menu-item>
              <el-menu-item v-if="userInfo.role !== 'ADMIN'" index="/achievements">
                <el-icon><Medal /></el-icon>
                <span>{{ '成就徽章' }}</span>
              </el-menu-item>
              <el-menu-item v-if="userInfo.role !== 'ADMIN'" index="/ai-assistant">
                <el-icon><ChatLineRound /></el-icon>
                <span>{{ '成长助手' }}</span>
              </el-menu-item>
              <el-menu-item v-if="userInfo.role === 'ADMIN'" index="/admin/users">
                <el-icon><Setting /></el-icon>
                <span>{{ '用户管理' }}</span>
              </el-menu-item>
              <el-menu-item v-if="userInfo.role === 'ADMIN'" index="/admin/dashboard">
                <el-icon><DataLine /></el-icon>
                <span>{{ '数据看板' }}</span>
              </el-menu-item>
              <el-menu-item v-if="userInfo.role === 'ADMIN'" index="/admin/capsules">
                <el-icon><Collection /></el-icon>
                <span>{{ '胶囊管理' }}</span>
              </el-menu-item>
            </el-menu>
          </el-aside>

          <!-- 主内容区域 -->
          <el-main class="app-main">
            <router-view :key="route.fullPath" />
          </el-main>
        </el-container>
      </el-container>

      <!-- 全局加载遮罩：不卸载 DOM，只做视觉遮盖 -->
      <div v-if="appLoading" class="app-loading-wrapper">
        <div class="loading-spinner"></div>
      </div>
    </div>

    <!-- 全局拒绝通知对话框 -->
    <el-dialog
      v-model="rejectionDialogVisible"
      :title="'时光胶囊审核未通过'"
      width="400px"
      :close-on-click-modal="false"
      :close-on-press-escape="false"
      :show-close="true"
      @close="onCloseRejectionModal"
    >
      <div class="rejection-dialog-content">
        <el-result icon="error" :title="rejectionTitle" :sub-title="rejectionReason">
          <template #extra>
            <el-button type="primary" @click="goToCapsuleDetail">{{ '查看详情' }}</el-button>
          </template>
        </el-result>
      </div>
    </el-dialog>
  </el-config-provider>
</template>

<script setup>
import { ref, computed, onMounted, watch, onUnmounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
// import { useI18n } from 'vue-i18n'
import { ElMessage, ElMessageBox } from 'element-plus'
import { House, Edit, Timer, Trophy, Medal, User, ArrowDown, SwitchButton, ChatLineRound, Setting, Menu, DataLine, Collection, Message } from '@element-plus/icons-vue'
import wsService from '@/utils/websocket'
import dayjs from 'dayjs'

const router = useRouter()
const route = useRoute()
// const { t, locale } = useI18n()

// --- 用户状态相关 ---
const userInfo = ref({
  id: null,
  nickname: '',
  avatar: '',
  bio: '',
  role: 'USER'
})

const loggedIn = ref(false)
const userMenuOpen = ref(false)
const appLoading = ref(true) // 新增：全局加载状态

const isLoginPage = computed(() => {
  return route && (route.path === '/login' || route.name === 'Login')
})

const isLoggedIn = computed(() => {
  return loggedIn.value
})

// --- 消息通知相关 ---
const notifications = ref([])
const unreadCount = ref(0)
const rejectionDialogVisible = ref(false)
const currentRejection = ref(null)

const rejectionTitle = computed(() => {
  if (currentRejection.value) {
    return `你有 ${unreadCount.value} 个胶囊被拒绝了`
  }
  return ''
})

const rejectionReason = computed(() => {
  return currentRejection.value ? `最新原因: ${currentRejection.value.reason}` : ''
})

// --- 方法定义 ---

// 初始化 WebSocket 连接
const initWebSocket = () => {
  if (isLoggedIn.value && userInfo.value?.id) {
    console.log('初始化 WebSocket 连接，用户ID:', userInfo.value.id)
    wsService.connect(userInfo.value.id)
    wsService.onMessage((data) => {
      console.log('收到 WebSocket 消息:', data)
      if (data.type === 'REJECTION' || data.type === 'APPROVAL') {
        // 只调用fetchNotifications，因为它会同时更新计数和列表
        fetchNotifications()
        if (data.type === 'REJECTION') {
          currentRejection.value = data
          rejectionDialogVisible.value = true
        }
      }
    })
  }
}

// 获取未读消息数量
const fetchUnreadCount = async () => {
  if (!isLoggedIn.value || !window.$axios) return
  try {
    const res = await window.$axios.get('/notifications/unread/count')
    if (res.code === 200) {
      unreadCount.value = res.data
    }
  } catch (e) {
    console.error('获取未读消息数量失败:', e)
  }
}

// 获取消息列表
const fetchNotifications = async () => {
  if (!isLoggedIn.value || !window.$axios) return
  console.log('开始获取通知列表')
  try {
    // 先尝试获取所有通知（最多5条）
    const res = await window.$axios.get('/notifications')
    console.log('获取所有通知响应:', res)
    if (res.code === 200) {
      // 后端返回的是直接的通知列表，不是分页格式
      notifications.value = res.data.slice(0, 5) // 限制最多5条
      console.log('通知列表:', notifications.value)
      // 同时获取未读计数以保持一致
      const countRes = await window.$axios.get('/notifications/unread/count')
      console.log('获取未读计数响应:', countRes)
      if (countRes.code === 200) {
        unreadCount.value = countRes.data
        console.log('未读计数:', unreadCount.value)
      }
    }
  } catch (e) {
    console.error('获取消息列表失败:', e)
    // 尝试获取未读通知
    try {
      const res = await window.$axios.get('/notifications/unread')
      console.log('获取未读通知响应:', res)
      if (res.code === 200) {
        notifications.value = res.data
        unreadCount.value = res.data.length
        console.log('未读通知列表:', notifications.value)
      }
    } catch (e) {
      console.error('获取未读消息失败:', e)
    }
  }
}

// 标记所有为已读
const markAllRead = async () => {
  if (!window.$axios) return
  try {
    const res = await window.$axios.put('/notifications/read-all')
    if (res.code === 200) {
      unreadCount.value = 0
      notifications.value = []
    }
  } catch (e) {
    console.error('标记已读失败:', e)
  }
}

// 处理消息点击
const handleNotificationCommand = async (item) => {
  if (!window.$axios) return
  try {
    await window.$axios.put(`/notifications/${item.id}/read`)
    fetchUnreadCount()
    fetchNotifications()
    router.push(`/capsule/${item.capsuleId}`)
  } catch (e) {
    console.error('操作失败:', e)
  }
}

const onCloseRejectionModal = () => {
  rejectionDialogVisible.value = false
}

const goToCapsuleDetail = async () => {
  if (currentRejection.value) {
    await handleNotificationCommand(currentRejection.value)
    rejectionDialogVisible.value = false
  }
}

const formatDate = (date) => {
  return dayjs(date).format('MM-DD HH:mm')
}

const loadUserInfo = async () => {
  const token = localStorage.getItem('token')
  
  // 如果没有 token，直接设为未登录
  if (!token) {
    loggedIn.value = false
    userInfo.value = { id: null, nickname: '', avatar: '', role: 'USER' }
    appLoading.value = false
    return
  }

  appLoading.value = true
  if (window.$axios) {
    try {
      const response = await window.$axios.get('/users/profile')
      if (response?.code === 200 && response?.data) {
        const userData = response.data
        userInfo.value = {
          id: userData.id,
          nickname: userData.nickname || '',
          avatar: userData.avatar || '',
          bio: userData.bio || '',
          role: userData.role || 'USER'
        }
        localStorage.setItem('user', JSON.stringify(userInfo.value))
        loggedIn.value = true
      } else {
        // API 响应异常，清除状态
        handleLogoutLocally()
      }
    } catch (e) {
      console.error('API 获取用户信息失败', e)
      // 如果是 401 错误，拦截器会处理跳转，这里只需要确保状态正确
      if (e.response?.status === 401) {
        handleLogoutLocally()
      } else {
        // 其他错误（如网络问题），尝试使用缓存
        const user = localStorage.getItem('user')
        if (user) {
          try {
            userInfo.value = JSON.parse(user)
            loggedIn.value = true
          } catch (err) {
            handleLogoutLocally()
          }
        } else {
          handleLogoutLocally()
        }
      }
    }
  }
  
  appLoading.value = false
}

// 本地清除登录状态，不触发额外的重定向（由拦截器或路由守卫处理）
const handleLogoutLocally = () => {
  localStorage.removeItem('user')
  localStorage.removeItem('token')
  userInfo.value = { id: null, nickname: '', avatar: '', role: 'USER' }
  loggedIn.value = false
}

const handleCommand = (command) => {
  if (command === 'logout') {
    ElMessageBox.confirm('确定要退出登录吗？', '提示', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning'
    }).then(() => {
      localStorage.removeItem('user')
      localStorage.removeItem('token')
      userInfo.value = { id: null, nickname: '', avatar: '', role: 'USER' }
      loggedIn.value = false
      wsService.disconnect()
      ElMessage.success('已退出登录')
      router.push('/login')
    }).catch(() => {})
  }
}

const handleDropdownVisibleChange = (visible) => {
  userMenuOpen.value = visible
}

const handleStorageChange = async (e) => {
  if (e.key === 'user' || e.key === 'token') {
    await loadUserInfo()
  }
}

const handleUserLogin = async () => {
  await loadUserInfo()
}

// --- 监听与生命周期 ---

watch(isLoggedIn, (newVal) => {
  if (newVal) {
    initWebSocket()
    // 只调用fetchNotifications，因为它会同时更新计数和列表
    fetchNotifications()
  } else {
    wsService.disconnect()
  }
})

watch(() => route.path, async (newPath) => {
  if (newPath !== '/login') {
    await loadUserInfo()
  } else {
    userInfo.value = { id: null, nickname: '', avatar: '', role: 'USER' }
    loggedIn.value = false
    appLoading.value = false // 确保登录页不显示加载中
  }
}, { immediate: true })

onMounted(async () => {
  // 移除 loadUserInfo()，交给 watch 处理
  window.addEventListener('storage', handleStorageChange)
  window.addEventListener('user-login', handleUserLogin)
})

onUnmounted(() => {
  wsService.disconnect()
  window.removeEventListener('storage', handleStorageChange)
  window.removeEventListener('user-login', handleUserLogin)
})
</script>

<style scoped>
/* 整体容器：铺满视口 */
.app-container {
  height: 100vh;
  display: flex;
  flex-direction: column;
  margin: 0;
  padding: 0;
}

/* 全局加载遮罩 */
.app-loading-wrapper {
  position: fixed;
  top: 0;
  left: 0;
  width: 100vw;
  height: 100vh;
  background-color: #ffffff;
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 9999;
}

.loading-spinner {
  width: 40px;
  height: 40px;
  border: 4px solid #f3f3f3;
  border-top: 4px solid #409eff;
  border-radius: 50%;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

/* 顶部栏样式 */
.app-header {
  background-color: #409eff;
  color: white;
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 20px;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
  z-index: 100;
  margin: 0;
}

.header-title {
  font-size: 20px;
  font-weight: bold;
}

.header-right {
  display: flex;
  align-items: center;
}

.user-info {
  display: flex;
  align-items: center;
  cursor: pointer;
  padding: 4px 12px;
  border-radius: 4px;
  transition: background-color 0.3s;
}

.user-info:hover {
  background-color: rgba(255, 255, 255, 0.1);
}

.username {
  margin-right: 8px;
  font-size: 14px;
}

.dropdown-icon {
  font-size: 12px;
  transition: transform 0.3s;
}

.user-info.dropdown-open .dropdown-icon {
  transform: rotate(180deg);
}

/* 消息通知相关样式 */
.notification-icon {
  cursor: pointer;
  display: flex;
  align-items: center;
  padding: 0 10px;
  height: 40px;
  border-radius: 4px;
  transition: background-color 0.3s;
}

.notification-icon:hover {
  background-color: rgba(255, 255, 255, 0.1);
}

.notification-dropdown {
  width: 350px;
  padding: 0;
}

.notification-header {
  padding: 10px 15px;
  border-bottom: 1px solid #f0f0f0;
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-weight: bold;
}

.notification-list {
  max-height: 300px;
  overflow-y: auto;
}

.no-notifications {
  padding: 30px;
  text-align: center;
  color: #909399;
}

.notification-item {
  padding: 12px 15px !important;
  border-bottom: 1px solid #f9f9f9;
}

.notification-content {
  display: flex;
  flex-direction: column;
  gap: 5px;
}

.notification-header-row {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-bottom: 5px;
}

.capsule-title {
  font-weight: bold;
  color: #303133;
  font-size: 14px;
  flex: 1;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.notification-tag {
  flex-shrink: 0;
}

.notification-body {
  font-size: 13px;
  color: #606266;
  white-space: normal;
  line-height: 1.4;
  margin-top: 2px;
}

.notification-time {
  font-size: 12px;
  color: #909399;
  margin-top: 2px;
}

.rejection-dialog-content {
  padding: 10px 0;
}

/* 登录页面包装器 */
.login-page-wrapper {
  width: 100%;
  height: 100vh;
  overflow: hidden;
}

/* 主布局：除去 header 后剩余空间 */
.main-layout {
  flex: 1;
  display: flex;
  overflow: hidden;
  margin: 0;
  padding: 0;
}

/* 侧边栏样式 */
.app-aside {
  background-color: #f5f7fa;
  border-right: 1px solid #e6e6e6;
  width: 200px;
  flex-shrink: 0;
  margin: 0;
  padding: 0;
}

.sidebar-menu {
  border-right: none;
  height: 100%;
  margin: 0;
  padding: 0;
}

/* 主内容区 */
.app-main {
  flex: 1;
  background-color: #ffffff;
  margin: 0;
  padding: 20px;
  overflow-y: auto;
  height: 100%;
}
</style>

<style>
/* 全局样式修复 */
html, body, #app {
  height: 100%;
  margin: 0;
  padding: 0;
  width: 100%;
}

/* 确保Element Plus容器铺满全屏 */
.el-container {
  height: 100%;
  margin: 0;
  padding: 0;
  width: 100%;
}

.el-aside {
  height: 100%;
  margin: 0;
  padding: 0;
}

.el-main {
  margin: 0;
  padding: 20px;
}

/* 移除可能存在的最大宽度限制 */
#app .app-container {
  max-width: none;
}
</style>