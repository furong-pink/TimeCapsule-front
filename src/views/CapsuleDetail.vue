<template>
  <div class="capsule-detail" v-loading="loading">
    <div class="detail-header">
      <el-button @click="$router.go(-1)" icon="ArrowLeft" plain>返回</el-button>
      <div class="header-content">
        <h2>{{ capsule.title }}</h2>
        <div class="capsule-meta">
          <el-tag :type="capsule.isOpened ? 'success' : 'warning'" size="small">
            {{ capsule.isOpened ? '已开启' : '未开启' }}
          </el-tag>
          <el-tag 
            :type="capsule.privacy === 'PUBLIC' ? 'success' : 'info'" 
            size="small"
            style="margin-left: 8px;"
          >
            {{ capsule.privacy === 'PUBLIC' ? '公开' : '私密' }}
          </el-tag>
        </div>
      </div>
    </div>

    <div class="detail-content">
      <div class="cover-section" v-if="capsule.coverImage">
        <img :src="capsule.coverImage" :alt="capsule.title" class="cover-image" />
      </div>

      <div class="info-section">
        <h3>胶囊信息</h3>
        <el-descriptions :column="2" border>
          <el-descriptions-item label="创建时间">
            {{ formatDate(capsule.createdAt) }}
          </el-descriptions-item>
          <el-descriptions-item label="开启时间">
            {{ formatDate(capsule.openDate) }}
          </el-descriptions-item>
          <el-descriptions-item label="开启状态">
            <el-tag :type="capsule.isOpened ? 'success' : 'warning'">
              {{ capsule.isOpened ? '已开启' : '未开启' }}
            </el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="隐私设置">
            <el-tag :type="capsule.privacy === 'PUBLIC' ? 'success' : 'info'">
              {{ capsule.privacy === 'PUBLIC' ? '公开' : '私密' }}
            </el-tag>
          </el-descriptions-item>
        </el-descriptions>
      </div>

      <div class="content-section">
        <h3>胶囊内容</h3>
        <div class="content-text">
          <p>{{ capsule.content }}</p>
        </div>
      </div>

      <div class="media-section" v-if="capsule.mediaFiles && capsule.mediaFiles.length > 0">
        <h3>媒体文件</h3>
        <div class="media-grid">
          <div 
            v-for="(media, index) in capsule.mediaFiles" 
            :key="index" 
            class="media-item"
          >
            <img 
              v-if="isImage(media.url)" 
              :src="media.url" 
              :alt="media.name || '媒体文件'"
              @click="previewImage(media.url)"
              class="media-preview"
            />
            <video 
              v-else-if="isVideo(media.url)" 
              :src="media.url" 
              controls 
              class="media-preview"
            />
            <div v-else class="media-placeholder">
              <el-icon><Document /></el-icon>
              <span>{{ media.name }}</span>
            </div>
          </div>
        </div>
      </div>

      <!-- 开启按钮（仅在胶囊未开启且已到达开启日期时显示） -->
      <div class="action-section" v-if="!capsule.isOpened && isDueToOpen(capsule.openDate)">
        <el-button 
          type="primary" 
          size="large" 
          @click="openCapsule"
          :loading="opening"
        >
          开启时间胶囊
        </el-button>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { ArrowLeft, Document } from '@element-plus/icons-vue'

export default {
  name: 'CapsuleDetail',
  components: {
    ArrowLeft,
    Document
  },
  setup() {
    const route = useRoute()
    const router = useRouter()
    const capsule = ref({})
    const loading = ref(false)
    const opening = ref(false)

    // 格式化日期
    const formatDate = (date) => {
      if (!date) return ''
      let d
      if (typeof date === 'string' && date.includes('T')) {
        d = new Date(date)
      } else if (typeof date === 'string' && date.includes('-') && date.length === 10) {
        d = new Date(date + 'T00:00:00')
      } else {
        d = new Date(date)
      }
      const year = d.getFullYear()
      const month = String(d.getMonth() + 1).padStart(2, '0')
      const day = String(d.getDate()).padStart(2, '0')
      return `${year}-${month}-${day}`
    }

    // 检查是否到达开启日期
    const isDueToOpen = (openDate) => {
      if (!openDate) return false
      const openDateObj = new Date(openDate)
      const today = new Date()
      // 设置今天的时间为00:00:00，以便比较日期部分
      today.setHours(0, 0, 0, 0)
      return openDateObj <= today
    }

    // 检查是否为图片
    const isImage = (url) => {
      return /\.(jpg|jpeg|png|gif|webp)$/i.test(url)
    }

    // 检查是否为视频
    const isVideo = (url) => {
      return /\.(mp4|avi|mov|wmv|flv|mkv)$/i.test(url)
    }

    // 预览图片
    const previewImage = (url) => {
      // 这里可以实现图片预览功能
      console.log('预览图片:', url)
    }

    // 加载胶囊详情
    const loadCapsule = async () => {
      const id = route.params.id
      if (!id) {
        ElMessage.error('时间胶囊ID不存在')
        router.push('/timeline')
        return
      }

      loading.value = true
      try {
        if (window.$axios) {
          const response = await window.$axios.get(`/capsules/${id}`)
          if (response?.code === 200) {
            capsule.value = response.data
          } else {
            ElMessage.error(response?.message || '获取时间胶囊详情失败')
            router.push('/timeline')
          }
        } else {
          // 没有API时的后备处理
          ElMessage.error('API不可用')
          router.push('/timeline')
        }
      } catch (error) {
        console.error('获取时间胶囊详情失败:', error)
        ElMessage.error('获取时间胶囊详情失败')
        router.push('/timeline')
      } finally {
        loading.value = false
      }
    }

    // 开启时间胶囊
    const openCapsule = async () => {
      const id = route.params.id
      if (!id) return

      opening.value = true
      try {
        if (window.$axios) {
          const response = await window.$axios.post(`/capsules/${id}/open`)
          if (response?.code === 200) {
            ElMessage.success('时间胶囊开启成功！')
            // 重新加载详情
            await loadCapsule()
          } else {
            ElMessage.error(response?.message || '开启失败')
          }
        } else {
          ElMessage.error('API不可用')
        }
      } catch (error) {
        console.error('开启时间胶囊失败:', error)
        ElMessage.error('开启时间胶囊失败')
      } finally {
        opening.value = false
      }
    }

    onMounted(() => {
      loadCapsule()
    })

    return {
      capsule,
      loading,
      opening,
      formatDate,
      isDueToOpen,
      isImage,
      isVideo,
      previewImage,
      openCapsule
    }
  }
}
</script>

<style scoped>
.capsule-detail {
  padding: 20px;
  max-width: 800px;
  margin: 0 auto;
}

.detail-header {
  display: flex;
  align-items: center;
  margin-bottom: 24px;
  gap: 16px;
}

.header-content {
  flex: 1;
}

.header-content h2 {
  margin: 0 0 8px 0;
  color: #333;
  font-size: 24px;
}

.capsule-meta {
  display: flex;
  gap: 8px;
}

.detail-content {
  background: #fff;
  border-radius: 8px;
  padding: 24px;
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.1);
}

.cover-section {
  margin-bottom: 24px;
  text-align: center;
}

.cover-image {
  max-width: 100%;
  height: auto;
  border-radius: 8px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}

.info-section,
.content-section,
.media-section {
  margin-bottom: 24px;
}

.info-section h3,
.content-section h3,
.media-section h3 {
  margin: 0 0 16px 0;
  color: #333;
  font-size: 18px;
  border-bottom: 1px solid #eee;
  padding-bottom: 8px;
}

.content-text {
  line-height: 1.8;
  color: #666;
  white-space: pre-wrap;
}

.media-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(150px, 1fr));
  gap: 12px;
}

.media-item {
  text-align: center;
}

.media-preview {
  width: 100%;
  max-height: 150px;
  object-fit: cover;
  border-radius: 4px;
  cursor: pointer;
  transition: transform 0.2s;
}

.media-preview:hover {
  transform: scale(1.05);
}

.media-placeholder {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 16px;
  border: 1px dashed #d9d9d9;
  border-radius: 4px;
  color: #999;
}

.action-section {
  text-align: center;
  margin-top: 24px;
}
</style>