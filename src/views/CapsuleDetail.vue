<template>
  <div class="capsule-detail" v-loading="loading">
    <!-- 顶部返回按钮 -->
    <div class="back-row">
      <el-button @click="$router.go(-1)" :icon="ArrowLeft" text>返回</el-button>
    </div>

    <!-- 主体内容卡片 - 左右两栏布局 -->
    <div class="detail-card" :class="{ 'panel-open': commentPanelVisible }">
      <!-- 左侧内容区 -->
      <div class="main-content">
        <!-- 1. 胶囊标题 -->
        <h1 class="capsule-title">{{ capsule.title || '未命名胶囊' }}</h1>

        <!-- 2. 作者信息行：头像 + 昵称 + 关注按钮 -->
        <div class="author-row">
          <div class="author-info">
            <el-avatar :size="32" :src="capsule.authorAvatar">
              <el-icon :size="16"><User /></el-icon>
            </el-avatar>
            <span class="author-nickname">{{ capsule.author || '未知用户' }}</span>
          </div>
          <el-button
            :type="isFollowed ? 'primary' : 'default'"
            :plain="!isFollowed"
            size="small"
            round
            class="follow-btn"
            @click="toggleFollow"
          >
            {{ isFollowed ? '已关注' : '关注' }}
          </el-button>
        </div>

        <!-- 3. 元信息行：存档时间 -->
        <div class="meta-row">
          <span class="meta-date">
            <el-icon><Calendar /></el-icon>
            存档时间：{{ formatDate(capsule.archiveDate || capsule.createdAt) }}
          </span>
        </div>

        <!-- 4. 图片区域 - 轮播图 -->
        <div class="image-area" v-if="imageUrls.length > 0">
          <!-- 多张图片：轮播图 -->
          <div class="carousel-wrapper" ref="carouselWrapperRef" v-if="imageUrls.length > 1">
            <el-carousel
              ref="carouselRef"
              :key="'carousel-' + imageUrls.length"
              :initial-index="0"
              trigger="click"
              :autoplay="false"
              :loop="false"
              :height="carouselHeight"
              indicator-position="none"
              arrow="always"
              @change="handleCarouselChange"
            >
              <el-carousel-item
                v-for="(url, idx) in imageUrls"
                :key="url"
              >
                <img
                  :src="url"
                  :alt="capsule.title + ' - 图片 ' + (idx + 1)"
                  class="carousel-image"
                  @contextmenu.prevent
                  draggable="false"
                />
              </el-carousel-item>
            </el-carousel>
            <!-- 自定义指示点 -->
            <div class="carousel-dots">
              <span
                v-for="(url, idx) in imageUrls"
                :key="'dot-' + url"
                class="carousel-dot"
                :class="{ 'is-active': idx === carouselIndex }"
                @click="setCarouselIndex(idx)"
              ></span>
            </div>
            <!-- 图片计数器 -->
            <div class="image-count">{{ carouselIndex + 1 }} / {{ imageUrls.length }}</div>
          </div>
          <!-- 单张图片：静态展示 -->
          <div class="single-image-wrapper" ref="singleImageWrapperRef" v-else>
            <img
              :src="imageUrls[0]"
              :alt="capsule.title"
              class="single-cover-image"
              :style="singleImageStyle"
              @contextmenu.prevent
              draggable="false"
            />
          </div>
        </div>

        <!-- 5. 文字内容区域 -->
        <div class="content-area">
          <div class="content-text rich-text-content" v-html="capsule.content || '暂无内容'"></div>
        </div>

        <!-- 6. 操作栏 -->
        <div class="action-bar">
          <button class="action-btn" :class="{ 'is-active': isCapsuleLiked }" @click="toggleCapsuleLike">
            <svg class="action-icon" viewBox="0 0 24 24" :fill="isCapsuleLiked ? 'currentColor' : 'none'" stroke="currentColor" stroke-width="2" width="18" height="18">
              <path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/>
            </svg>
            <span class="action-count" v-if="capsuleLikeCount > 0">{{ capsuleLikeCount }}</span>
          </button>
          <button class="action-btn" :class="{ 'is-active': commentPanelVisible }" @click="toggleCommentPanel">
            <el-icon class="action-icon"><Comment /></el-icon>
            <span class="action-count" v-if="totalCommentCount > 0">{{ totalCommentCount }}</span>
          </button>
          <button class="action-btn" @click="handleShare">
            <el-icon class="action-icon"><Share /></el-icon>
          </button>
        </div>
      </div>

      <!-- 右侧评论区（内联面板，动画展开） -->
      <div class="comment-panel" :class="{ 'is-open': commentPanelVisible }">
        <div class="comment-panel-inner">
          <!-- 面板头部 -->
          <div class="panel-header">
            <span class="panel-title">评论 ({{ totalCommentCount }})</span>
            <button class="panel-close-btn" @click="commentPanelVisible = false">
              <el-icon :size="18"><Close /></el-icon>
            </button>
          </div>

          <!-- 评论列表区域 -->
          <div class="panel-body">
            <!-- 空评论状态 -->
            <div class="comment-empty" v-if="comments.length === 0">
              <div class="empty-icon">🌊</div>
              <p class="empty-title">暂无评论</p>
              <p class="empty-desc">成为第一个留下温暖足迹的人吧</p>
            </div>

            <!-- 评论列表 -->
            <div class="comment-list" v-else>
              <div v-for="comment in comments" :key="comment.id" class="comment-group">
                <!-- 主评论 -->
                <div class="comment-item">
                  <el-avatar :size="32" :src="comment.authorAvatar" class="comment-avatar">
                    <el-icon :size="16"><User /></el-icon>
                  </el-avatar>
                  <div class="comment-body">
                    <div class="comment-header-row">
                      <span class="comment-author">{{ comment.author }}</span>
                      <span class="comment-time">{{ comment.datetime }}</span>
                    </div>
                    <p class="comment-content">{{ comment.content }}</p>
                    <div class="comment-actions">
                      <button
                        class="comment-like-btn"
                        :class="{ 'is-liked': comment.isLiked }"
                        @click="toggleCommentLike(comment)"
                      >
                        <svg viewBox="0 0 24 24" :fill="comment.isLiked ? 'currentColor' : 'none'" stroke="currentColor" stroke-width="2" width="14" height="14">
                          <path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/>
                        </svg>
                        <span v-if="comment.likes > 0" class="like-count">{{ comment.likes }}</span>
                      </button>
                      <button class="comment-reply-btn" @click="startReply(comment)">
                        回复
                      </button>
                      <button
                        v-if="comment.userId === currentUserId"
                        class="comment-delete-btn"
                        @click="deleteComment(comment)"
                      >
                        删除
                      </button>
                    </div>
                  </div>
                </div>

                <!-- 子回复列表 -->
                <div class="replies-list" v-if="comment.replies && comment.replies.length > 0">
                  <div v-for="reply in comment.replies" :key="reply.id" class="reply-item">
                    <el-avatar :size="28" :src="reply.authorAvatar" class="reply-avatar">
                      <el-icon :size="14"><User /></el-icon>
                    </el-avatar>
                    <div class="reply-body">
                      <div class="comment-header-row">
                        <span class="comment-author">{{ reply.author }}</span>
                        <span class="comment-time">{{ reply.datetime }}</span>
                      </div>
                      <p class="comment-content">{{ reply.content }}</p>
                      <div class="comment-actions">
                        <button
                          class="comment-like-btn"
                          :class="{ 'is-liked': reply.isLiked }"
                          @click="toggleCommentLike(reply, 'reply')"
                        >
                          <svg viewBox="0 0 24 24" :fill="reply.isLiked ? 'currentColor' : 'none'" stroke="currentColor" stroke-width="2" width="14" height="14">
                            <path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/>
                          </svg>
                          <span v-if="reply.likes > 0" class="like-count">{{ reply.likes }}</span>
                        </button>
                        <button
                          v-if="reply.userId === currentUserId"
                          class="comment-delete-btn"
                          @click="deleteReply(reply, comment)"
                        >
                          删除
                        </button>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- 评论输入框（固定在底部） -->
          <div class="panel-footer">
            <div class="reply-hint" v-if="replyTo">
              <span>回复 @{{ replyTo.author }}：</span>
              <button class="cancel-reply-btn" @click="cancelReply">取消</button>
            </div>
            <div class="input-wrapper">
              <el-avatar :size="28" class="input-avatar">
                <el-icon :size="14"><User /></el-icon>
              </el-avatar>
              <input
                v-model="newComment"
                type="text"
                :placeholder="replyTo ? '回复 @' + replyTo.author + '：' : '写下你的感受...'"
                maxlength="500"
                class="comment-input"
                @keyup.enter="submitComment"
              />
              <span class="char-count" v-if="newComment.length > 0">{{ 500 - newComment.length }}</span>
              <button
                class="submit-btn"
                :disabled="!newComment.trim() || submitting"
                @click="submitComment"
              >
                {{ submitting ? '发送中...' : '发送' }}
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, computed, watch, onMounted, onUnmounted, nextTick } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { ArrowLeft, User, Calendar, Close, Comment, Share } from '@element-plus/icons-vue'

export default {
  name: 'CapsuleDetail',
  components: {
    ArrowLeft,
    User,
    Calendar,
    Close,
    Comment,
    Share
  },
  setup() {
    const route = useRoute()
    const router = useRouter()
    const capsule = ref({})
    const loading = ref(false)
    const submitting = ref(false)

    // 当前用户ID
    const currentUserId = (() => {
      try {
        const u = JSON.parse(localStorage.getItem('user') || 'null')
        return u?.id || null
      } catch { return null }
    })()

    // ---- 关注 & 收藏 ----
    const isFollowed = ref(false)
    const isCollected = ref(false)

    // ---- 胶囊点赞 ----
    const isCapsuleLiked = ref(false)
    const capsuleLikeCount = ref(0)

    const toggleCapsuleLike = async () => {
      const id = route.params.id
      try {
        if (isCapsuleLiked.value) {
          await window.$axios.delete(`/capsules/${id}/like`)
          isCapsuleLiked.value = false
          capsuleLikeCount.value = Math.max(0, capsuleLikeCount.value - 1)
        } else {
          await window.$axios.post(`/capsules/${id}/like`)
          isCapsuleLiked.value = true
          capsuleLikeCount.value += 1
        }
      } catch (error) {
        console.error('点赞操作失败:', error)
        ElMessage.error('操作失败，请稍后重试')
      }
    }

    // ---- 评论/回复点赞 ----
    const toggleCommentLike = async (item, type = 'comment') => {
      const endpoint = type === 'reply'
        ? `/replies/${item.id}/like`
        : `/comments/${item.id}/like`
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
        console.error('评论点赞失败:', error)
        ElMessage.error('操作失败，请稍后重试')
      }
    }

    // ---- 评论 & 回复状态 ----
    const comments = ref([])
    const totalComments = ref(0)
    const newComment = ref('')
    const replyTo = ref(null)

    const totalCommentCount = computed(() => totalComments.value)

    const startReply = (comment) => {
      replyTo.value = comment
      nextTick(() => {
        const input = document.querySelector('.comment-input')
        if (input) input.focus()
      })
    }

    const cancelReply = () => {
      replyTo.value = null
    }

    // ---- 加载评论列表 ----
    const loadComments = async () => {
      const id = route.params.id
      try {
        const res = await window.$axios.get(`/capsules/${id}/comments`)
        if (res?.code === 200) {
          const list = res.data?.list || res.data || []
          comments.value = list
          totalComments.value = res.data?.total || res.total || 0
          if (totalComments.value === 0 && list.length > 0) {
            totalComments.value = list.reduce((sum, c) => {
              return sum + 1 + (c.replies?.length || 0)
            }, 0)
          }
        } else {
          console.warn('加载评论返回非200:', res)
        }
      } catch (error) {
        console.error('加载评论失败:', error)
        // 如果是 404 说明后端接口不存在（表可能未创建），静默处理
        if (error?.response?.status !== 404) {
          ElMessage.error('加载评论失败，请稍后重试')
        }
      }
    }

    // ---- 发表评论/回复 ----
    const submitComment = async () => {
      const text = newComment.value.trim()
      if (!text || submitting.value) return

      submitting.value = true
      const id = route.params.id

      try {
        if (replyTo.value) {
          await window.$axios.post(`/comments/${replyTo.value.id}/replies`, {
            content: text
          })
          ElMessage.success('回复发表成功')
          cancelReply()
        } else {
          await window.$axios.post(`/capsules/${id}/comments`, {
            content: text
          })
          ElMessage.success('评论发表成功')
        }
        newComment.value = ''
        await loadComments()
      } catch (error) {
        console.error('发表失败:', error)
        const msg = error?.response?.data?.message || '发表失败，请稍后重试'
        ElMessage.error(msg)
      } finally {
        submitting.value = false
      }
    }

    // ---- 删除评论/回复 ----
    const deleteComment = async (comment) => {
      try {
        await window.$axios.delete(`/comments/${comment.id}`)
        ElMessage.success('评论已删除')
        await loadComments()
      } catch (error) {
        console.error('删除评论失败:', error)
        ElMessage.error('删除失败，请稍后重试')
      }
    }

    const deleteReply = async (reply, parentComment) => {
      try {
        await window.$axios.delete(`/replies/${reply.id}`)
        ElMessage.success('回复已删除')
        await loadComments()
      } catch (error) {
        console.error('删除回复失败:', error)
        ElMessage.error('删除失败，请稍后重试')
      }
    }

    // ---- 评论面板 ----
    const commentPanelVisible = ref(false)

    const toggleCommentPanel = () => {
      commentPanelVisible.value = !commentPanelVisible.value
      if (commentPanelVisible.value) {
        loadComments()
      }
    }

    // ---- 分享 ----
    const handleShare = () => {
      const url = window.location.href
      navigator.clipboard.writeText(url).then(() => {
        ElMessage.success('分享链接已复制到剪贴板')
      }).catch(() => {
        ElMessage.info('分享链接已复制到剪贴板')
      })
    }

    // ---- 关注 ----
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
        const msg = error?.response?.data?.message || '操作失败，请稍后重试'
        ElMessage.error(msg)
      }
    }

    // ---- 收藏 ----
    const toggleCollect = async () => {
      const id = route.params.id
      try {
        if (isCollected.value) {
          await window.$axios.delete(`/capsules/${id}/collect`)
          isCollected.value = false
          ElMessage.success('已取消收藏')
        } else {
          await window.$axios.post(`/capsules/${id}/collect`)
          isCollected.value = true
          ElMessage.success('已收藏')
        }
      } catch (error) {
        console.error('收藏操作失败:', error)
        ElMessage.error('操作失败，请稍后重试')
      }
    }

    const isMobile = ref(false)

    const updateMobileState = () => {
      isMobile.value = window.innerWidth <= 768
    }

    // ---- 标签 ----
    const tags = computed(() => {
      const capsuleTags = capsule.value.tags
      if (Array.isArray(capsuleTags) && capsuleTags.length > 0) return capsuleTags
      if (typeof capsuleTags === 'string' && capsuleTags) {
        return capsuleTags.split(',').map(t => t.trim()).filter(Boolean)
      }
      return []
    })

    // ---- 图片列表（须在轮播代码之前定义） ----
    const isImage = (url) => {
      if (!url || typeof url !== 'string') return false
      return /\.(jpg|jpeg|png|gif|webp)$/i.test(url.toLowerCase())
    }

    const formatDate = (date) => {
      if (!date) return ''
      let year, month, day
      if (typeof date === 'string' && date.includes('-') && date.length === 10) {
        const parts = date.split('-')
        year = parseInt(parts[0])
        month = parseInt(parts[1])
        day = parseInt(parts[2])
      } else {
        const d = new Date(date)
        year = d.getFullYear()
        month = d.getMonth() + 1
        day = d.getDate()
      }
      return `${year}.${String(month).padStart(2, '0')}.${String(day).padStart(2, '0')}`
    }

    const getAllImageUrls = () => {
      const urls = []
      if (capsule.value.coverImage) urls.push(capsule.value.coverImage)
      if (capsule.value.mediaFiles && Array.isArray(capsule.value.mediaFiles)) {
        capsule.value.mediaFiles.forEach(media => {
          const url = media.fileUrl || media.url || media.filePath || media.source || null
          if (url && isImage(url)) urls.push(url)
        })
      }
      return urls
    }

    const imageUrls = computed(() => {
      let urls = []
      if (capsule.value.images && Array.isArray(capsule.value.images) && capsule.value.images.length > 0) {
        urls = capsule.value.images
      } else {
        urls = getAllImageUrls()
      }
      return [...new Set(urls.filter(Boolean))]
    })

    // ---- 轮播图相关 ----
    const carouselRef = ref(null)
    const carouselWrapperRef = ref(null)
    const singleImageWrapperRef = ref(null)
    const carouselIndex = ref(0)
    const wrapperWidth = ref(0)

    const handleCarouselChange = (index) => {
      carouselIndex.value = index
    }

    const setCarouselIndex = (idx) => {
      if (carouselRef.value) {
        carouselRef.value.setActiveItem(idx)
      }
    }

    // 图片元数据：URL → { category, displayRatio }
    const imageMetaMap = ref({})

    /** 加载图片并检测宽高比类别 */
    const detectImageMeta = async (url) => {
      if (imageMetaMap.value[url]) return imageMetaMap.value[url]
      try {
        const dims = await new Promise((resolve, reject) => {
          const img = new Image()
          img.onload = () => resolve({ w: img.naturalWidth, h: img.naturalHeight })
          img.onerror = () => reject(new Error('load failed'))
          img.src = url
        })
        const ratio = dims.w / dims.h
        let category, displayRatio
        if (ratio > 1.05) {
          category = 'landscape'
          displayRatio = 4 / 3
        } else if (ratio < 0.95) {
          category = 'portrait'
          displayRatio = 3 / 4
        } else {
          category = 'square'
          displayRatio = 1
        }
        const meta = { category, displayRatio, naturalWidth: dims.w, naturalHeight: dims.h }
        imageMetaMap.value = { ...imageMetaMap.value, [url]: meta }
        return meta
      } catch {
        const fallback = { category: 'landscape', displayRatio: 4 / 3, naturalWidth: 4, naturalHeight: 3 }
        imageMetaMap.value = { ...imageMetaMap.value, [url]: fallback }
        return fallback
      }
    }

    /** 预加载所有图片以获取尺寸信息 */
    const preloadAllImages = async () => {
      const urls = imageUrls.value
      if (!urls.length) return
      await Promise.all(urls.map(url => detectImageMeta(url)))
    }

    /** 更新容器宽度 */
    const updateWrapperWidth = () => {
      const el = carouselWrapperRef.value || singleImageWrapperRef.value
      if (el) {
        wrapperWidth.value = el.clientWidth
      }
    }

    // 动态轮播高度（基于当前图片显示比例）
    const carouselHeight = computed(() => {
      const urls = imageUrls.value
      if (!urls.length || !wrapperWidth.value) return '300px'
      const currentUrl = urls[carouselIndex.value] || urls[0]
      const meta = imageMetaMap.value[currentUrl]
      if (!meta) return '300px'
      const height = wrapperWidth.value / meta.displayRatio
      return Math.round(height) + 'px'
    })

    // 单张图片显示比例
    const singleImageStyle = computed(() => {
      if (!imageUrls.value.length) return {}
      const meta = imageMetaMap.value[imageUrls.value[0]]
      if (!meta) return {}
      return { aspectRatio: String(meta.displayRatio) }
    })

    // 监听图片列表变化，重新检测
    watch(imageUrls, () => {
      preloadAllImages().then(() => {
        nextTick(() => updateWrapperWidth())
      })
    }, { deep: true })

    // 监听面板开关，重新计算宽度
    watch(commentPanelVisible, () => {
      nextTick(() => updateWrapperWidth())
    })

    // ---- 加载胶囊详情 ----
    const loadCapsule = async () => {
      const id = route.params.id
      if (!id) {
        ElMessage.error('时间胶囊ID不存在')
        router.push('/timeline')
        return
      }

      loading.value = true
      try {
        const res = await window.$axios.get(`/capsules/${id}`)
        if (res?.code === 200) {
          const data = res.data
          capsule.value = data
          isCapsuleLiked.value = data.isLiked || false
          capsuleLikeCount.value = data.likes || 0
          isFollowed.value = data.isFollowed || false
          isCollected.value = data.isCollected || false
          // 预加载图片尺寸
          await nextTick()
          await preloadAllImages()
          nextTick(() => updateWrapperWidth())
        } else {
          ElMessage.error(res?.message || '获取时间胶囊详情失败')
        }
      } catch (error) {
        console.error('获取时间胶囊详情失败:', error)
        ElMessage.error('获取时间胶囊详情失败')
        router.push('/timeline')
      } finally {
        loading.value = false
      }
    }

    onMounted(() => {
      updateMobileState()
      window.addEventListener('resize', updateMobileState)
      window.addEventListener('resize', updateWrapperWidth)
      loadCapsule()
    })

    onUnmounted(() => {
      window.removeEventListener('resize', updateMobileState)
      window.removeEventListener('resize', updateWrapperWidth)
    })

    return {
      capsule,
      loading,
      submitting,
      tags,
      isFollowed,
      isCollected,
      isCapsuleLiked,
      capsuleLikeCount,
      totalCommentCount,
      carouselRef,
      carouselWrapperRef,
      singleImageWrapperRef,
      carouselIndex,
      carouselHeight,
      imageUrls,
      singleImageStyle,
      comments,
      newComment,
      replyTo,
      formatDate,
      getAllImageUrls,
      handleCarouselChange,
      setCarouselIndex,
      toggleFollow,
      toggleCollect,
      toggleCapsuleLike,
      toggleCommentLike,
      submitComment,
      commentPanelVisible,
      toggleCommentPanel,
      handleShare,
      startReply,
      cancelReply,
      currentUserId,
      deleteComment,
      deleteReply,
      ArrowLeft,
      User,
      Calendar,
      Close,
      Comment,
      Share
    }
  }
}
</script>

<style scoped>
/* ========== 整体布局 ========== */
.capsule-detail {
  min-height: 100vh;
  background: linear-gradient(180deg, #eef4fb 0%, #f5f7fa 100%);
  padding: 24px 20px 60px;
}

.back-row {
  max-width: 800px;
  margin: 0 auto 16px;
}

/* ========== 主卡片（左右两栏 flex 布局） ========== */
.detail-card {
  max-width: 800px;
  margin: 0 auto;
  background: #ffffff;
  border-radius: 16px;
  box-shadow: 0 4px 24px rgba(31, 47, 61, 0.08), 0 1px 4px rgba(31, 47, 61, 0.04);
  overflow: hidden;
  display: flex;
  align-items: stretch;
  transition: max-width 0.3s ease;
}

/* 面板打开时扩宽以容纳评论区 */
.detail-card.panel-open {
  max-width: 1160px;
}

/* ========== 左侧主内容区 ========== */
.main-content {
  flex: 1;
  min-width: 0;
  padding: 32px;
  transition: padding-right 0.3s ease;
}

/* ========== 1. 标题 ========== */
.capsule-title {
  font-size: 28px;
  font-weight: 700;
  color: #1F2F3D;
  margin: 0 0 20px 0;
  line-height: 1.3;
}

/* ========== 2. 作者行 ========== */
.author-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 12px;
}

.author-info {
  display: flex;
  align-items: center;
  gap: 8px;
}

.author-nickname {
  font-size: 14px;
  color: #5A6A7A;
}

.follow-btn {
  font-size: 12px;
  padding: 4px 14px;
  border-radius: 16px;
}

.follow-btn.el-button--default {
  --el-button-border-color: #4a90d9;
  --el-button-text-color: #4a90d9;
  --el-button-bg-color: transparent;
}

/* ========== 3. 元信息行 ========== */
.meta-row {
  margin-bottom: 20px;
}

.meta-date {
  font-size: 12px;
  color: #8A9AAA;
  display: flex;
  align-items: center;
  gap: 4px;
}

.meta-date .el-icon {
  font-size: 12px;
}

/* ========== 4. 图片区域 ========== */
.image-area {
  margin-bottom: 20px;
}

/* --- 轮播图容器 --- */
.carousel-wrapper {
  position: relative;
  border-radius: 12px;
  overflow: hidden;
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.06);
  background: #f0f2f5;
}

/* --- 轮播图片：按比例完整显示，不裁剪 --- */
.carousel-image {
  width: 100%;
  height: 100%;
  object-fit: contain;
  pointer-events: none;
  user-select: none;
  -webkit-user-drag: none;
}

/* --- 轮播底层 --- */
.carousel-wrapper :deep(.el-carousel) {
  border-radius: 12px;
}

.carousel-wrapper :deep(.el-carousel__container) {
  border-radius: 12px;
}

.carousel-wrapper :deep(.el-carousel__item) {
  display: flex;
  align-items: center;
  justify-content: center;
}

/* --- 左右箭头 --- */
.carousel-wrapper :deep(.el-carousel__arrow) {
  background: rgba(0, 0, 0, 0.35);
  width: 36px;
  height: 36px;
  font-size: 14px;
  border-radius: 50%;
  transition: background 0.2s;
}

.carousel-wrapper :deep(.el-carousel__arrow:hover) {
  background: rgba(0, 0, 0, 0.6);
}

/* --- 自定义指示点 --- */
.carousel-dots {
  position: absolute;
  bottom: 12px;
  left: 50%;
  transform: translateX(-50%);
  display: flex;
  gap: 6px;
  z-index: 10;
}

.carousel-dot {
  width: 6px;
  height: 6px;
  border-radius: 50%;
  background: rgba(255, 255, 255, 0.5);
  cursor: pointer;
  transition: all 0.25s;
}

.carousel-dot.is-active {
  width: 20px;
  border-radius: 3px;
  background: #409eff;
}

/* --- 图片计数器 --- */
.image-count {
  position: absolute;
  bottom: 12px;
  right: 12px;
  background: rgba(0, 0, 0, 0.5);
  color: #fff;
  font-size: 12px;
  padding: 3px 10px;
  border-radius: 20px;
  backdrop-filter: blur(4px);
  letter-spacing: 0.5px;
  z-index: 10;
}

/* --- 单张图片（非轮播） --- */
.single-image-wrapper {
  border-radius: 12px;
  overflow: hidden;
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.06);
}

.single-cover-image {
  width: 100%;
  max-height: 500px;
  object-fit: contain;
  display: block;
  pointer-events: none;
  user-select: none;
  -webkit-user-drag: none;
  border-radius: 12px;
}

/* ========== 5. 文字内容区域 ========== */
.content-area {
  margin-bottom: 24px;
}

.content-text {
  font-size: 16px;
  line-height: 1.8;
  color: #2C3E50;
  word-break: break-word;
  overflow-wrap: break-word;
}

.rich-text-content :deep(p) {
  margin: 10px 0;
}

.rich-text-content :deep(img) {
  max-width: 100%;
  height: auto;
  border-radius: 8px;
  margin: 12px 0;
}

/* ========== 6. 操作栏 ========== */
.action-bar {
  display: flex;
  justify-content: space-around;
  padding-top: 20px;
  border-top: 1px solid #eef1f5;
}

.action-btn {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 8px 20px;
  background: transparent;
  border: none;
  border-radius: 20px;
  cursor: pointer;
  color: #8A9AAA;
  transition: all 0.2s;
}

.action-btn:hover {
  background: #f0f2f5;
  color: #5A6A7A;
}

.action-btn.is-active {
  color: #4a90d9;
}

.action-icon {
  font-size: 18px;
}

.action-count {
  font-size: 13px;
}

/* ========== 右侧评论区（内联面板） ========== */
.comment-panel {
  width: 0;
  overflow: hidden;
  border-left: none;
  transition: width 0.3s ease, border-left 0.3s ease;
  flex-shrink: 0;
  display: flex;
  flex-direction: column;
}

.comment-panel.is-open {
  width: 360px;
  border-left: 1px solid #eef1f5;
}

.comment-panel-inner {
  width: 360px;
  height: 100%;
  display: flex;
  flex-direction: column;
}

/* 面板头部 */
.panel-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 20px 20px 0;
  flex-shrink: 0;
}

.panel-title {
  font-size: 18px;
  font-weight: 600;
  color: #1F2F3D;
}

.panel-close-btn {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 32px;
  height: 32px;
  border: none;
  background: transparent;
  border-radius: 8px;
  cursor: pointer;
  color: #8A9AAA;
  transition: background 0.2s;
}

.panel-close-btn:hover {
  background: #f0f2f5;
  color: #5A6A7A;
}

/* 面板内容区 */
.panel-body {
  flex: 1;
  overflow-y: auto;
  padding: 16px 20px;
}

/* 空评论状态 */
.comment-empty {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 40px 0;
  color: #8A9AAA;
}

.empty-icon {
  font-size: 48px;
  margin-bottom: 12px;
}

.empty-title {
  font-size: 14px;
  font-weight: 500;
  margin: 0 0 4px 0;
  color: #5A6A7A;
}

.empty-desc {
  font-size: 12px;
  margin: 0;
}

/* 评论列表 */
.comment-list {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.comment-item {
  display: flex;
  gap: 10px;
  padding-bottom: 16px;
  border-bottom: 1px solid #eef1f5;
}

.comment-item:last-child {
  border-bottom: none;
  padding-bottom: 0;
}

.comment-avatar {
  flex-shrink: 0;
}

.comment-body {
  flex: 1;
  min-width: 0;
}

.comment-header-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 4px;
}

.comment-author {
  font-size: 14px;
  font-weight: 600;
  color: #1F2F3D;
}

.comment-time {
  font-size: 12px;
  color: #b0b8c1;
}

.comment-content {
  font-size: 14px;
  line-height: 1.6;
  color: #3a4a5c;
  margin: 0;
  word-break: break-word;
}

/* 评论操作：点赞 + 回复 */
.comment-actions {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-top: 6px;
}

.comment-like-btn {
  display: flex;
  align-items: center;
  gap: 2px;
  padding: 2px 6px;
  background: #f0f2f5;
  border: none;
  border-radius: 12px;
  cursor: pointer;
  font-size: 12px;
  color: #8A9AAA;
  transition: all 0.2s;
}

.comment-like-btn:hover {
  background: #e0e5ec;
  color: #5A6A7A;
}

.comment-like-btn.is-liked {
  color: #4a90d9;
  background: #eef4fb;
}

.comment-like-btn .like-count {
  margin-left: 2px;
}

.comment-reply-btn {
  padding: 2px 6px;
  background: transparent;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-size: 12px;
  color: #8A9AAA;
}

.comment-reply-btn:hover {
  color: #4a90d9;
}

.comment-delete-btn {
  padding: 2px 6px;
  background: transparent;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-size: 12px;
  color: #b0b8c1;
  margin-left: auto;
}

.comment-delete-btn:hover {
  color: #e74c3c;
}

/* 子回复列表 */
.replies-list {
  margin-left: 44px;
  margin-top: 10px;
  padding-left: 12px;
  border-left: 2px solid #eef1f5;
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.reply-item {
  display: flex;
  gap: 8px;
}

.reply-avatar {
  flex-shrink: 0;
}

.reply-body {
  flex: 1;
  min-width: 0;
}

/* 回复提示条 */
.reply-hint {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 6px 12px;
  margin-bottom: 8px;
  background: #eef4fb;
  border-radius: 8px;
  font-size: 12px;
  color: #4a90d9;
}

.cancel-reply-btn {
  padding: 2px 8px;
  background: transparent;
  border: 1px solid #b0b8c1;
  border-radius: 12px;
  cursor: pointer;
  font-size: 11px;
  color: #8A9AAA;
}

.cancel-reply-btn:hover {
  border-color: #4a90d9;
  color: #4a90d9;
}

/* 字符计数 */
.char-count {
  font-size: 11px;
  color: #b0b8c1;
  flex-shrink: 0;
  min-width: 24px;
  text-align: center;
}

/* 评论输入框 */
.panel-footer {
  padding: 12px 20px;
  border-top: 1px solid #eef1f5;
  flex-shrink: 0;
}

.input-wrapper {
  display: flex;
  align-items: center;
  gap: 8px;
  background: #f5f7fa;
  border-radius: 20px;
  padding: 4px 4px 4px 8px;
}

.input-avatar {
  flex-shrink: 0;
}

.comment-input {
  flex: 1;
  border: none;
  background: transparent;
  font-size: 14px;
  padding: 8px;
  outline: none;
}

.comment-input::placeholder {
  color: #b0b8c1;
}

.submit-btn {
  padding: 6px 16px;
  font-size: 13px;
  color: #4a90d9;
  background: transparent;
  border: none;
  border-radius: 16px;
  cursor: pointer;
  transition: background-color 0.2s;
}

.submit-btn:hover:not(:disabled) {
  background: #eef4fb;
}

.submit-btn:disabled {
  color: #b0b8c1;
  cursor: not-allowed;
}

/* ========== 响应式 ========== */
@media (max-width: 768px) {
  .capsule-detail {
    padding: 12px 8px 40px;
  }

  .detail-card {
    border-radius: 12px;
    flex-direction: column;
    max-width: 800px;
  }

  .detail-card.panel-open {
    max-width: 800px;
  }

  .main-content {
    padding: 20px;
  }

  .capsule-title {
    font-size: 22px;
  }

  .carousel-wrapper :deep(.el-carousel__arrow) {
    width: 30px;
    height: 30px;
    font-size: 12px;
  }

  .single-cover-image {
    max-height: 350px;
  }

  /* 移动端：评论区变为全宽，从底部滑出效果 */
  .comment-panel {
    width: 100%;
    max-height: 0;
    transition: max-height 0.3s ease;
    border-left: none;
    border-top: none;
  }

  .comment-panel.is-open {
    width: 100%;
    max-height: 70vh;
    border-top: 1px solid #eef1f5;
  }

  .comment-panel-inner {
    width: 100%;
  }
}
</style>
