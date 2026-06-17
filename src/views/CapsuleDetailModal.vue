<template>
  <teleport to="body">
    <div class="capsule-modal-overlay" v-if="modelValue" @click.self="closeModal">
      <div class="capsule-modal-card" :class="{ 'panel-open': commentOpen }" v-loading="loading">
        <!-- 顶部返回按钮 -->
        <div class="modal-back-row">
          <button class="modal-back-btn" @click="closeModal">
            <el-icon><ArrowLeft /></el-icon>
            <span>返回</span>
          </button>
        </div>

        <template v-if="!loading && capsule">
          <div class="modal-card-body">
            <!-- 左侧：胶囊内容区 -->
            <div class="modal-main-content">
              <!-- 胶囊标题 -->
              <h1 class="modal-capsule-title">{{ capsule.title || '未命名胶囊' }}</h1>

              <!-- 作者信息行 + 关注按钮 -->
              <div class="modal-author-row">
                <div class="modal-author-info">
                  <el-avatar :size="32" :src="capsule.authorAvatar">
                    <el-icon :size="16"><User /></el-icon>
                  </el-avatar>
                  <span class="modal-author-name">{{ capsule.author || '未知用户' }}</span>
                </div>
                <el-button
                  :type="isFollowed ? 'primary' : 'default'"
                  :plain="!isFollowed"
                  size="small"
                  round
                  class="modal-follow-btn"
                  @click="toggleFollow"
                >
                  {{ isFollowed ? '已关注' : '关注' }}
                </el-button>
              </div>

              <!-- 存档时间 -->
              <div class="modal-meta-row">
                <span class="modal-meta-date">
                  <el-icon><Calendar /></el-icon>
                  存档时间：{{ formatDate(capsule.archiveDate || capsule.createdAt) }}
                </span>
              </div>

              <!-- 图片区域 -->
              <div class="modal-image-area" v-if="imageUrls.length > 0">
                <div class="modal-carousel-wrapper" v-if="imageUrls.length > 1">
                  <el-carousel
                    :initial-index="0"
                    trigger="click"
                    :autoplay="false"
                    :loop="false"
                    height="250px"
                    indicator-position="none"
                    arrow="always"
                  >
                    <el-carousel-item v-for="(url, idx) in imageUrls" :key="url">
                      <img
                        :src="url"
                        :alt="'图片 ' + (idx + 1)"
                        class="modal-carousel-image"
                        @contextmenu.prevent
                        draggable="false"
                      />
                    </el-carousel-item>
                  </el-carousel>
                </div>
                <div class="modal-single-image-wrapper" v-else>
                  <img
                    :src="imageUrls[0]"
                    alt="封面图片"
                    class="modal-single-image"
                    @contextmenu.prevent
                    draggable="false"
                  />
                </div>
              </div>

              <!-- 文字内容 -->
              <div class="modal-content-area">
                <div class="modal-content-text" v-html="capsule.content || '暂无内容'"></div>
              </div>

              <!-- 操作栏 -->
              <div class="modal-action-bar">
                <button class="modal-action-btn" :class="{ 'is-active': isLiked }" @click="toggleCapsuleLike">
                  <svg viewBox="0 0 24 24" :fill="isLiked ? 'currentColor' : 'none'" stroke="currentColor" stroke-width="2" width="18" height="18">
                    <path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/>
                  </svg>
                  <span class="modal-action-count" v-if="likeCount > 0">{{ likeCount }}</span>
                </button>
                <button class="modal-action-btn" :class="{ 'is-active': commentOpen }" @click="toggleComments">
                  <el-icon class="modal-action-icon"><Comment /></el-icon>
                  <span class="modal-action-count" v-if="totalComments > 0">{{ totalComments }}</span>
                </button>
                <button class="modal-action-btn" @click="handleShare">
                  <el-icon class="modal-action-icon"><Share /></el-icon>
                </button>
              </div>
            </div>

            <!-- 右侧：评论区（动画展开） -->
            <div class="modal-comment-panel" :class="{ 'is-open': commentOpen }">
              <div class="modal-comment-panel-inner">
                <!-- 面板头部 -->
                <div class="modal-panel-header">
                  <span class="modal-panel-title">评论 ({{ totalComments }})</span>
                  <button class="modal-panel-close-btn" @click="commentOpen = false">
                    <el-icon :size="16"><Close /></el-icon>
                  </button>
                </div>

                <!-- 评论列表 -->
                <div class="modal-comment-list">
                  <div class="modal-comment-empty" v-if="comments.length === 0">
                    <p class="modal-empty-text">暂无评论，成为第一个留下温暖足迹的人吧</p>
                  </div>
                  <div v-for="comment in comments" :key="comment.id" class="modal-comment-group">
                    <div class="modal-comment-item">
                      <el-avatar :size="28" :src="comment.authorAvatar" class="modal-comment-avatar">
                        <el-icon :size="14"><User /></el-icon>
                      </el-avatar>
                      <div class="modal-comment-body">
                        <div class="modal-comment-header">
                          <span class="modal-comment-author">{{ comment.author }}</span>
                          <span class="modal-comment-time">{{ comment.datetime }}</span>
                        </div>
                        <p class="modal-comment-content">{{ comment.content }}</p>
                        <div class="modal-comment-actions">
                          <button
                            class="modal-comment-like-btn"
                            :class="{ 'is-liked': comment.isLiked }"
                            @click="toggleCommentLike(comment)"
                          >
                            <svg viewBox="0 0 24 24" :fill="comment.isLiked ? 'currentColor' : 'none'" stroke="currentColor" stroke-width="2" width="12" height="12">
                              <path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/>
                            </svg>
                            <span v-if="comment.likes > 0">{{ comment.likes }}</span>
                          </button>
                          <button class="modal-comment-reply-btn" @click="startReply(comment)">回复</button>
                          <button
                            v-if="comment.userId === currentUserId"
                            class="modal-comment-delete-btn"
                            @click="deleteComment(comment)"
                          >删除</button>
                        </div>
                      </div>
                    </div>

                    <!-- 子回复 -->
                    <div class="modal-replies-list" v-if="comment.replies && comment.replies.length > 0">
                      <div v-for="reply in comment.replies" :key="reply.id" class="modal-reply-item">
                        <el-avatar :size="24" :src="reply.authorAvatar" class="modal-reply-avatar">
                          <el-icon :size="12"><User /></el-icon>
                        </el-avatar>
                        <div class="modal-reply-body">
                          <div class="modal-comment-header">
                            <span class="modal-comment-author">{{ reply.author }}</span>
                            <span class="modal-comment-time">{{ reply.datetime }}</span>
                          </div>
                          <p class="modal-comment-content">{{ reply.content }}</p>
                          <div class="modal-comment-actions">
                            <button
                              class="modal-comment-like-btn"
                              :class="{ 'is-liked': reply.isLiked }"
                              @click="toggleCommentLike(reply, 'reply')"
                            >
                              <svg viewBox="0 0 24 24" :fill="reply.isLiked ? 'currentColor' : 'none'" stroke="currentColor" stroke-width="2" width="12" height="12">
                                <path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/>
                              </svg>
                              <span v-if="reply.likes > 0">{{ reply.likes }}</span>
                            </button>
                            <button
                              v-if="reply.userId === currentUserId"
                              class="modal-comment-delete-btn"
                              @click="deleteReply(reply, comment)"
                            >删除</button>
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>

                <!-- 评论输入框 -->
                <div class="modal-comment-input-area">
                  <div class="modal-reply-hint" v-if="replyTo">
                    <span>回复 @{{ replyTo.author }}：</span>
                    <button class="modal-cancel-reply-btn" @click="cancelReply">取消</button>
                  </div>
                  <div class="modal-input-wrapper">
                    <input
                      v-model="newComment"
                      type="text"
                      :placeholder="replyTo ? '回复 @' + replyTo.author + '：' : '写下你的感受...'"
                      maxlength="500"
                      class="modal-comment-input"
                      @keyup.enter="submitComment"
                    />
                    <button
                      class="modal-submit-btn"
                      :disabled="!newComment.trim() || submitting"
                      @click="submitComment"
                    >
                      {{ submitting ? '...' : '发送' }}
                    </button>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </template>
      </div>
    </div>
  </teleport>
</template>

<script>
import { ref, computed, watch, nextTick } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { ArrowLeft, User, Calendar, Comment, Share, Close } from '@element-plus/icons-vue'

export default {
  name: 'CapsuleDetailModal',
  components: { ArrowLeft, User, Calendar, Comment, Share, Close },
  props: {
    modelValue: { type: Boolean, default: false },
    capsuleId: { type: [Number, String], default: null }
  },
  emits: ['update:modelValue'],
  setup(props, { emit }) {
    const capsule = ref(null)
    const loading = ref(false)
    const submitting = ref(false)

    const currentUserId = (() => {
      try {
        const u = JSON.parse(localStorage.getItem('user') || 'null')
        return u?.id || null
      } catch { return null }
    })()

    // ---- 点赞 ----
    const isLiked = ref(false)
    const likeCount = ref(0)

    const toggleCapsuleLike = async () => {
      if (!capsule.value?.id) return
      try {
        if (isLiked.value) {
          await window.$axios.delete(`/capsules/${capsule.value.id}/like`)
          isLiked.value = false
          likeCount.value = Math.max(0, likeCount.value - 1)
        } else {
          await window.$axios.post(`/capsules/${capsule.value.id}/like`)
          isLiked.value = true
          likeCount.value += 1
        }
      } catch (error) {
        console.error('点赞失败:', error)
      }
    }

    // ---- 关注 ----
    const isFollowed = ref(false)

    const toggleFollow = async () => {
      const authorId = capsule.value?.userId
      if (!authorId) {
        ElMessage.error('无法获取作者信息')
        return
      }
      if (authorId === currentUserId) {
        ElMessage.warning('不能关注自己')
        return
      }
      try {
        if (isFollowed.value) {
          await window.$axios.delete(`/friends/follow/${authorId}`)
          isFollowed.value = false
          ElMessage.success('已取消关注')
        } else {
          await window.$axios.post(`/friends/follow/${authorId}`)
          isFollowed.value = true
          ElMessage.success('已关注')
        }
      } catch (error) {
        console.error('关注操作失败:', error)
        const msg = error?.response?.data?.message || '操作失败'
        ElMessage.error(msg)
      }
    }

    // ---- 评论 ----
    const comments = ref([])
    const totalComments = ref(0)
    const newComment = ref('')
    const commentOpen = ref(false)
    const replyTo = ref(null)

    const toggleComments = () => {
      commentOpen.value = !commentOpen.value
      if (commentOpen.value) loadComments()
    }

    const loadComments = async () => {
      if (!capsule.value?.id) return
      try {
        const res = await window.$axios.get(`/capsules/${capsule.value.id}/comments`)
        if (res?.code === 200) {
          const list = res.data?.list || res.data || []
          comments.value = list
          totalComments.value = res.data?.total || res.total || 0
          if (totalComments.value === 0 && list.length > 0) {
            totalComments.value = list.reduce((sum, c) => sum + 1 + (c.replies?.length || 0), 0)
          }
        }
      } catch (error) {
        console.error('加载评论失败:', error)
      }
    }

    const startReply = (comment) => {
      replyTo.value = comment
      nextTick(() => {
        const input = document.querySelector('.modal-comment-input')
        if (input) input.focus()
      })
    }

    const cancelReply = () => { replyTo.value = null }

    const submitComment = async () => {
      const text = newComment.value.trim()
      if (!text || submitting.value || !capsule.value?.id) return
      submitting.value = true
      try {
        if (replyTo.value) {
          await window.$axios.post(`/comments/${replyTo.value.id}/replies`, { content: text })
          ElMessage.success('回复发表成功')
        } else {
          await window.$axios.post(`/capsules/${capsule.value.id}/comments`, { content: text })
          ElMessage.success('评论发表成功')
        }
        newComment.value = ''
        cancelReply()
        await loadComments()
      } catch (error) {
        const msg = error?.response?.data?.message || '发表失败'
        ElMessage.error(msg)
      } finally {
        submitting.value = false
      }
    }

    const toggleCommentLike = async (item, type = 'comment') => {
      const endpoint = type === 'reply' ? `/replies/${item.id}/like` : `/comments/${item.id}/like`
      try {
        if (item.isLiked) {
          await window.$axios.delete(endpoint)
          item.isLiked = false
          item.likes = Math.max(0, (item.likes || 0) - 1)
        } else {
          await window.$axios.post(endpoint)
          item.isLiked = true
          item.likes = (item.likes || 0) + 1
        }
      } catch (error) {
        console.error('点赞失败:', error)
      }
    }

    // ---- 删除 ----
    const deleteComment = async (comment) => {
      try {
        await ElMessageBox.confirm('确定删除这条评论吗？回复也会一并删除。', '确认删除', {
          confirmButtonText: '删除',
          cancelButtonText: '取消',
          type: 'warning'
        })
        await window.$axios.delete(`/comments/${comment.id}`)
        ElMessage.success('评论已删除')
        await loadComments()
      } catch (error) {
        if (error !== 'cancel' && error?.message !== 'cancel') {
          console.error('删除评论失败:', error)
        }
      }
    }

    const deleteReply = async (reply, parentComment) => {
      try {
        await ElMessageBox.confirm('确定删除这条回复吗？', '确认删除', {
          confirmButtonText: '删除',
          cancelButtonText: '取消',
          type: 'warning'
        })
        await window.$axios.delete(`/replies/${reply.id}`)
        ElMessage.success('回复已删除')
        await loadComments()
      } catch (error) {
        if (error !== 'cancel' && error?.message !== 'cancel') {
          console.error('删除回复失败:', error)
        }
      }
    }

    // ---- 分享 ----
    const handleShare = () => {
      const url = window.location.origin + '/capsule/' + (capsule.value?.id || '')
      const title = capsule.value?.title || '时间胶囊'
      if (navigator.share) {
        navigator.share({ title, url }).catch(() => {})
      } else {
        navigator.clipboard.writeText(`${title}\n${url}`).then(() => {
          ElMessage.success('链接已复制到剪贴板')
        }).catch(() => {})
      }
    }

    // ---- 工具 ----
    const formatDate = (date) => {
      if (!date) return ''
      let year, month, day
      if (typeof date === 'string' && date.includes('-') && date.length === 10) {
        const parts = date.split('-')
        year = parseInt(parts[0]); month = parseInt(parts[1]); day = parseInt(parts[2])
      } else {
        const d = new Date(date)
        year = d.getFullYear(); month = d.getMonth() + 1; day = d.getDate()
      }
      return `${year}.${String(month).padStart(2, '0')}.${String(day).padStart(2, '0')}`
    }

    const isImage = (url) => {
      if (!url || typeof url !== 'string') return false
      return /\.(jpg|jpeg|png|gif|webp)$/i.test(url.toLowerCase())
    }

    const imageUrls = computed(() => {
      if (!capsule.value) return []
      const urls = []
      if (capsule.value.images && Array.isArray(capsule.value.images)) {
        urls.push(...capsule.value.images)
      } else {
        if (capsule.value.coverImage) urls.push(capsule.value.coverImage)
        if (capsule.value.mediaFiles && Array.isArray(capsule.value.mediaFiles)) {
          capsule.value.mediaFiles.forEach(media => {
            const url = media.fileUrl || media.url || media.filePath || media.source || null
            if (url && isImage(url)) urls.push(url)
          })
        }
      }
      return [...new Set(urls.filter(Boolean))]
    })

    // ---- 加载胶囊数据 ----
    const loadCapsule = async () => {
      if (!props.capsuleId) return
      loading.value = true
      try {
        const res = await window.$axios.get(`/capsules/${props.capsuleId}`)
        if (res?.code === 200) {
          capsule.value = res.data
          isLiked.value = res.data.isLiked || false
          likeCount.value = res.data.likes || 0
          isFollowed.value = res.data.isFollowed || false
        }
      } catch (error) {
        console.error('加载胶囊失败:', error)
        ElMessage.error('加载胶囊详情失败')
        emit('update:modelValue', false)
      } finally {
        loading.value = false
      }
    }

    const closeModal = () => {
      emit('update:modelValue', false)
      commentOpen.value = false
      comments.value = []
      newComment.value = ''
      replyTo.value = null
      document.body.style.overflow = ''
    }

    // 监听打开状态
    watch(() => props.modelValue, (val) => {
      if (val && props.capsuleId) {
        document.body.style.overflow = 'hidden'
        loadCapsule()
      }
    })

    return {
      capsule, loading, submitting, currentUserId,
      isLiked, likeCount, toggleCapsuleLike,
      isFollowed, toggleFollow,
      comments, totalComments, newComment, commentOpen, replyTo,
      toggleComments, startReply, cancelReply, submitComment,
      toggleCommentLike, deleteComment, deleteReply,
      handleShare, formatDate, imageUrls, closeModal,
      ArrowLeft, User, Calendar, Comment, Share, Close
    }
  }
}
</script>

<style scoped>
/* ========== 遮罩层 ========== */
.capsule-modal-overlay {
  position: fixed;
  inset: 0;
  z-index: 2000;
  display: flex;
  align-items: center;
  justify-content: center;
  background: rgba(0, 0, 0, 0.3);
  backdrop-filter: blur(8px);
  -webkit-backdrop-filter: blur(8px);
  padding: 20px;
  animation: modalFadeIn 0.25s ease;
}

@keyframes modalFadeIn {
  from { opacity: 0; }
  to { opacity: 1; }
}

/* ========== 卡片 ========== */
.capsule-modal-card {
  position: relative;
  width: 100%;
  max-width: 500px;
  max-height: 80vh;
  background: #ffffff;
  border-radius: 32px;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.15);
  padding: 28px 28px 32px;
  animation: modalSlideUp 0.3s ease;
  overflow: hidden;
  transition: max-width 0.3s ease;
  display: flex;
  flex-direction: column;
}

/* 面板打开时扩宽 */
.capsule-modal-card.panel-open {
  max-width: 860px;
}

@keyframes modalSlideUp {
  from { transform: translateY(30px); opacity: 0; }
  to { transform: translateY(0); opacity: 1; }
}

/* 返回按钮 */
.modal-back-row { margin-bottom: 16px; flex-shrink: 0; }

.modal-back-btn {
  display: flex; align-items: center; gap: 4px;
  padding: 6px 12px; background: #f5f7fa; border: none;
  border-radius: 20px; cursor: pointer; font-size: 14px;
  color: #5A6A7A; transition: background 0.2s;
}
.modal-back-btn:hover { background: #e8ecf1; }

/* ========== 两栏布局体 ========== */
.modal-card-body {
  display: flex;
  flex: 1;
  min-height: 0;
  overflow: hidden;
}

/* ========== 左侧内容区 ========== */
.modal-main-content {
  flex: 1;
  min-width: 0;
  overflow-y: auto;
  padding-right: 0;
}

.modal-main-content::-webkit-scrollbar { width: 4px; }
.modal-main-content::-webkit-scrollbar-thumb { background: #d0d5dd; border-radius: 2px; }

/* 标题 */
.modal-capsule-title {
  font-size: 22px; font-weight: 700; color: #1F2F3D;
  margin: 0 0 16px 0; line-height: 1.3;
}

/* 作者行 */
.modal-author-row { display: flex; align-items: center; justify-content: space-between; margin-bottom: 10px; }
.modal-author-info { display: flex; align-items: center; gap: 8px; }
.modal-author-name { font-size: 14px; color: #5A6A7A; }
.modal-follow-btn { font-size: 12px; padding: 4px 14px; border-radius: 16px; flex-shrink: 0; }

/* 元信息 */
.modal-meta-row { margin-bottom: 18px; }
.modal-meta-date { font-size: 12px; color: #8A9AAA; display: flex; align-items: center; gap: 4px; }

/* 图片 */
.modal-image-area { margin-bottom: 18px; }
.modal-carousel-wrapper { border-radius: 16px; overflow: hidden; background: #f0f2f5; }
.modal-carousel-image { width: 100%; height: 100%; object-fit: contain; pointer-events: none; user-select: none; -webkit-user-drag: none; }
.modal-single-image-wrapper { border-radius: 16px; overflow: hidden; }
.modal-single-image { width: 100%; max-height: 280px; object-fit: contain; display: block; pointer-events: none; user-select: none; -webkit-user-drag: none; border-radius: 16px; }

/* 内容 */
.modal-content-area { margin-bottom: 20px; }
.modal-content-text { font-size: 15px; line-height: 1.8; color: #2C3E50; word-break: break-word; overflow-wrap: break-word; }

/* 操作栏 */
.modal-action-bar { display: flex; justify-content: space-around; padding-top: 16px; border-top: 1px solid #eef1f5; }
.modal-action-btn { display: flex; align-items: center; gap: 6px; padding: 8px 24px; background: transparent; border: none; border-radius: 20px; cursor: pointer; color: #8A9AAA; transition: all 0.2s; }
.modal-action-btn:hover { background: #f0f2f5; color: #5A6A7A; }
.modal-action-btn.is-active { color: #4a90d9; }
.modal-action-icon { font-size: 18px; }
.modal-action-count { font-size: 13px; }

/* ========== 右侧评论区（动画宽度展开） ========== */
.modal-comment-panel {
  width: 0;
  overflow: hidden;
  border-left: none;
  transition: width 0.3s ease;
  flex-shrink: 0;
  display: flex;
  flex-direction: column;
}

.modal-comment-panel.is-open {
  width: 340px;
  border-left: 1px solid #eef1f5;
}

.modal-comment-panel-inner {
  width: 340px;
  height: 100%;
  display: flex;
  flex-direction: column;
  padding: 0 0 0 20px;
}

/* 面板头部 */
.modal-panel-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding-bottom: 12px;
  flex-shrink: 0;
}

.modal-panel-title {
  font-size: 16px;
  font-weight: 600;
  color: #1F2F3D;
}

.modal-panel-close-btn {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 28px;
  height: 28px;
  border: none;
  background: transparent;
  border-radius: 6px;
  cursor: pointer;
  color: #8A9AAA;
  transition: background 0.2s;
}

.modal-panel-close-btn:hover { background: #f0f2f5; color: #5A6A7A; }

/* 评论列表 */
.modal-comment-list {
  flex: 1;
  overflow-y: auto;
  min-height: 0;
  padding-right: 4px;
}

.modal-comment-list::-webkit-scrollbar { width: 3px; }
.modal-comment-list::-webkit-scrollbar-thumb { background: #d0d5dd; border-radius: 2px; }

.modal-comment-empty { text-align: center; padding: 24px 0; }
.modal-empty-text { font-size: 13px; color: #8A9AAA; margin: 0; }

.modal-comment-group { margin-bottom: 4px; }

.modal-comment-item { display: flex; gap: 8px; padding: 10px 0; border-bottom: 1px solid #f5f6f8; }
.modal-comment-item:last-child { border-bottom: none; }
.modal-comment-avatar { flex-shrink: 0; }
.modal-comment-body { flex: 1; min-width: 0; }

.modal-comment-header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 2px; }
.modal-comment-author { font-size: 13px; font-weight: 600; color: #1F2F3D; }
.modal-comment-time { font-size: 11px; color: #b0b8c1; }
.modal-comment-content { font-size: 13px; line-height: 1.5; color: #3a4a5c; margin: 0; word-break: break-word; }

.modal-comment-actions { display: flex; align-items: center; gap: 8px; margin-top: 4px; }

.modal-comment-like-btn {
  display: flex; align-items: center; gap: 2px; padding: 1px 6px;
  background: #f0f2f5; border: none; border-radius: 10px;
  cursor: pointer; font-size: 11px; color: #8A9AAA; transition: all 0.2s;
}
.modal-comment-like-btn:hover { background: #e0e5ec; color: #5A6A7A; }
.modal-comment-like-btn.is-liked { color: #4a90d9; background: #eef4fb; }

.modal-comment-reply-btn {
  padding: 1px 6px; background: transparent; border: none;
  border-radius: 4px; cursor: pointer; font-size: 11px; color: #8A9AAA;
}
.modal-comment-reply-btn:hover { color: #4a90d9; }

.modal-comment-delete-btn {
  padding: 1px 6px; background: transparent; border: none;
  border-radius: 4px; cursor: pointer; font-size: 11px; color: #b0b8c1;
  margin-left: auto;
}
.modal-comment-delete-btn:hover { color: #e74c3c; }

/* 子回复 */
.modal-replies-list {
  margin-left: 36px; padding-left: 10px;
  border-left: 2px solid #eef1f5;
  display: flex; flex-direction: column; gap: 8px;
  margin-top: 6px; margin-bottom: 6px;
}

.modal-reply-item { display: flex; gap: 6px; }
.modal-reply-avatar { flex-shrink: 0; }
.modal-reply-body { flex: 1; min-width: 0; }

/* 回复提示 */
.modal-reply-hint {
  display: flex; align-items: center; justify-content: space-between;
  padding: 4px 12px; margin-bottom: 8px; background: #eef4fb;
  border-radius: 8px; font-size: 12px; color: #4a90d9;
}
.modal-cancel-reply-btn {
  padding: 2px 8px; background: transparent; border: 1px solid #b0b8c1;
  border-radius: 12px; cursor: pointer; font-size: 11px; color: #8A9AAA;
}
.modal-cancel-reply-btn:hover { border-color: #4a90d9; color: #4a90d9; }

/* 输入框 */
.modal-comment-input-area {
  flex-shrink: 0;
  padding-top: 12px;
  border-top: 1px solid #f5f6f8;
  margin-top: 8px;
}
.modal-input-wrapper { display: flex; align-items: center; gap: 8px; background: #f5f7fa; border-radius: 20px; padding: 4px 4px 4px 12px; }
.modal-comment-input { flex: 1; border: none; background: transparent; font-size: 13px; padding: 6px 0; outline: none; }
.modal-comment-input::placeholder { color: #b0b8c1; }
.modal-submit-btn { padding: 5px 14px; font-size: 12px; color: #4a90d9; background: transparent; border: none; border-radius: 16px; cursor: pointer; transition: background-color 0.2s; white-space: nowrap; }
.modal-submit-btn:hover:not(:disabled) { background: #eef4fb; }
.modal-submit-btn:disabled { color: #b0b8c1; cursor: not-allowed; }

/* ========== 响应式 ========== */
@media (max-width: 768px) {
  .capsule-modal-overlay { padding: 0; align-items: flex-end; }
  .capsule-modal-card {
    max-width: 100% !important;
    max-height: 90vh;
    border-radius: 24px 24px 0 0;
    padding: 20px 20px 28px;
  }
  .capsule-modal-card.panel-open { max-width: 100% !important; }

  .modal-card-body { flex-direction: column; }

  /* 移动端评论区回退到下方展开 */
  .modal-comment-panel {
    width: 100% !important;
    max-height: 0;
    border-left: none !important;
    transition: max-height 0.3s ease;
  }
  .modal-comment-panel.is-open {
    width: 100% !important;
    max-height: 50vh;
    border-top: 1px solid #eef1f5;
    margin-top: 12px;
    padding-top: 12px;
  }
  .modal-comment-panel-inner { width: 100%; padding-left: 0; }
  .modal-comment-list { max-height: 200px; }

  .modal-capsule-title { font-size: 20px; }
}

@media (max-width: 480px) {
  .capsule-modal-card { padding: 16px 16px 24px; }
}
</style>
