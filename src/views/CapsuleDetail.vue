<template>
  <div class="capsule-detail" v-loading="loading">
    <div class="detail-header">
      <el-button @click="$router.go(-1)" icon="ArrowLeft" plain>返回</el-button>
      <div class="header-content">
        <h2>{{ capsule.title }}</h2>
      </div>
    </div>

    <div class="detail-content">
      <div class="cover-section" v-if="capsule.coverImage">
        <el-image
          :src="capsule.coverImage"
          :alt="capsule.title"
          class="cover-image"
          fit="cover"
          @click="previewImage(capsule.coverImage)"
        />
      </div>
      
      <!-- 图片预览对话框 -->
      <el-dialog
        v-model="previewVisible"
        title="图片预览"
        width="80%"
        append-to-body
      >
        <el-image
          :src="previewImageUrl"
          fit="contain"
          style="width: 100%; height: 70vh;"
        />
      </el-dialog>

      <div class="info-section">
        <h3>胶囊信息</h3>
        <el-descriptions :column="2" border>
          <el-descriptions-item label="创建者">
            <div class="creator-info" v-if="capsule.user">
              <img v-if="capsule.user.avatar" :src="capsule.user.avatar" :alt="capsule.user.nickname" class="creator-avatar" />
              <span>{{ capsule.user.nickname || '未知用户' }}</span>
            </div>
            <span v-else>未知用户</span>
          </el-descriptions-item>
          <el-descriptions-item label="创建时间">
            {{ formatDate(capsule.createdAt || capsule.created_at || capsule.date) }}
          </el-descriptions-item>
          <el-descriptions-item label="开启时间">
            {{ formatDate(capsule.openDate || capsule.open_date) }}
          </el-descriptions-item>
          <el-descriptions-item label="开启状态">
            <el-tag :type="getCapsuleStatus().type">
              {{ getCapsuleStatus().text }}
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
        <div class="content-text rich-text-content" v-html="capsule.content">
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
            <!-- 提取媒体文件URL，兼容不同的字段名 -->
            <el-image
              v-if="media && isImage(getSafeMediaUrl(media))"
              :src="getSafeMediaUrl(media)"
              :alt="getSafeMediaFileName(media) || '媒体文件'"
              class="media-preview"
              fit="cover"
              @click="previewImage(getSafeMediaUrl(media))"
            />
            <video 
              v-else-if="media && isVideo(getSafeMediaUrl(media))" 
              :src="getSafeMediaUrl(media)" 
              controls 
              class="media-preview"
            />
            <div v-else class="media-placeholder">
              <el-icon><Document /></el-icon>
              <span>{{ getSafeMediaFileName(media) }}</span>
            </div>
          </div>
        </div>
      </div>

      <!-- 开启按钮（仅在胶囊未开启且已到达开启日期时显示） -->
      <div class="action-section" v-if="!capsule.isOpened && isDueToOpen(capsule.openDate || capsule.open_date)">
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
    const previewVisible = ref(false)
    const previewImageUrl = ref('')
    
    // 安全获取媒体文件URL的辅助函数
    const getSafeMediaUrl = (media) => {
      if (!media || typeof media !== 'object') {
        return null;
      }
      return media.fileUrl || media.url || media.filePath || media.source || null;
    };
    
    // 安全获取媒体文件名的辅助函数
    const getSafeMediaFileName = (media) => {
      if (!media || typeof media !== 'object') {
        return '未知文件';
      }
      return media.fileName || media.name || media.title || '未知文件';
    };

    // 格式化日期
    const formatDate = (date) => {
      if (!date) return ''
      // 处理可能的日期格式，避免时区问题
      let year, month, day;
      if (typeof date === 'string' && date.includes('-') && date.length === 10) {
        // 如果是yyyy-MM-dd格式的日期字符串，直接提取年月日
        const parts = date.split('-');
        year = parseInt(parts[0]);
        month = parseInt(parts[1]);
        day = parseInt(parts[2]);
      } else {
        // 其他格式，使用日期对象
        const d = new Date(date);
        // 使用本地时间方法确保日期与用户本地时区一致
        year = d.getFullYear();
        month = d.getMonth() + 1;
        day = d.getDate();
      }
      // 确保日期格式正确
      return `${year}-${String(month).padStart(2, '0')}-${String(day).padStart(2, '0')}`
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

    // 计算胶囊状态
    const getCapsuleStatus = () => {
      if (capsule.value.isOpened) {
        return {
          type: 'success',
          text: '已开启'
        }
      } else if (isDueToOpen(capsule.value.openDate || capsule.value.open_date)) {
        return {
          type: 'success',
          text: '已可开启'
        }
      } else {
        return {
          type: 'warning',
          text: '未开启'
        }
      }
    }

    // 检查是否为图片
    const isImage = (url) => {
      console.log('检查是否为图片:', url); // 调试日志
      if (!url || typeof url !== 'string') {
        console.log('URL为空或不是字符串');
        return false;
      }
      // 支持多种图片格式
      const result = /\.(jpg|jpeg|png|gif|webp)$/i.test(url.toLowerCase());
      console.log('图片检测结果:', result);
      return result;
    }

    // 检查是否为视频
    const isVideo = (url) => {
      console.log('检查是否为视频:', url); // 调试日志
      if (!url || typeof url !== 'string') {
        console.log('URL为空或不是字符串');
        return false;
      }
      // 支持多种视频格式
      const result = /\.(mp4|avi|mov|wmv|flv|mkv)$/i.test(url.toLowerCase());
      console.log('视频检测结果:', result);
      return result;
    }



    // 预览图片
    const previewImage = (url) => {
      if (url) {
        previewImageUrl.value = url
        previewVisible.value = true
      }
    }
    
    // 重新加载胶囊详情（包含媒体文件）
    const reloadCapsuleWithMedia = async (capsuleId) => {
      try {
        if (window.$axios) {
          console.log('重新加载胶囊详情（含媒体文件），胶囊ID:', capsuleId);
          // 重新获取胶囊详情，期望包含媒体文件
          const response = await window.$axios.get(`/capsules/${capsuleId}`)
          console.log('重新加载胶囊详情API响应:', response);
          if (response?.code === 200 && response.data) {
            // 用新的数据更新当前胶囊，保留媒体文件信息
            Object.assign(capsule.value, response.data)
            console.log('已更新胶囊数据（含媒体文件）:', capsule.value.mediaFiles);
          }
        }
      } catch (error) {
        console.error('重新加载胶囊详情失败:', error);
      }
    }
    
    // 单独加载媒体文件（备用方法）
    const loadMediaFiles = async (capsuleId) => {
      // 尝试重新加载整个胶囊详情
      await reloadCapsuleWithMedia(capsuleId);
      
      // 如果仍然没有媒体文件，尝试从其他可能的API获取
      if (!capsule.value.mediaFiles || capsule.value.mediaFiles.length === 0) {
        try {
          // 尝试获取所有胶囊（可能在列表API中包含媒体文件）
          const listResponse = await window.$axios.get('/capsules?page=0&size=100')
          if (listResponse?.code === 200 && listResponse.data?.data) {
            const capsuleInList = listResponse.data.data.find(c => c.id === Number(capsuleId))
            if (capsuleInList && capsuleInList.mediaFiles && capsuleInList.mediaFiles.length > 0) {
              capsule.value.mediaFiles = capsuleInList.mediaFiles
              console.log('从胶囊列表API获取到媒体文件:', capsule.value.mediaFiles);
            }
          }
        } catch (listError) {
          console.log('从胶囊列表API获取媒体文件失败:', listError.message);
        }
        
        // 如果以上方法都失败，尝试检查响应中是否存在其他可能包含媒体文件的字段
        if (!capsule.value.mediaFiles || capsule.value.mediaFiles.length === 0) {
          // 检查是否在其他字段中存在媒体文件数据
          if (capsule.value.media_files) {
            capsule.value.mediaFiles = capsule.value.media_files;
            console.log('从 media_files 字段获取到媒体文件');
          } else if (capsule.value.files) {
            capsule.value.mediaFiles = capsule.value.files;
            console.log('从 files 字段获取到媒体文件');
          } else if (capsule.value.attachments) {
            capsule.value.mediaFiles = capsule.value.attachments;
            console.log('从 attachments 字段获取到媒体文件');
          }
        }
      }
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
          // 确保 ID 格式正确
          const capsuleId = typeof id === 'string' ? id.trim() : id
          console.log('加载胶囊详情，ID:', capsuleId)
          
          const response = await window.$axios.get(`/capsules/${capsuleId}`)
          console.log('时间胶囊详情API响应:', response); // 调试日志
          if (response?.code === 200) {
            capsule.value = response.data
            console.log('胶囊数据:', capsule.value); // 调试日志
            
            // 检查是否需要单独获取媒体文件
            if (!capsule.value.mediaFiles || !Array.isArray(capsule.value.mediaFiles) || capsule.value.mediaFiles.length === 0) {
              console.log('媒体文件为空或不是数组，尝试单独加载');
              await loadMediaFiles(capsuleId);
            } else {
              // 确保媒体文件数组中的每个元素都是有效的对象
              const validMediaFiles = capsule.value.mediaFiles.filter(media => media && typeof media === 'object');
              capsule.value.mediaFiles = validMediaFiles;
              console.log('已从主API获取媒体文件:', capsule.value.mediaFiles.length, '个文件');
            }
          } else {
            ElMessage.error(response?.message || '获取时间胶囊详情失败')
            // 不跳转到时间轴页面，保持在当前页面
          }
        } else {
          // 没有API时的后备处理
          ElMessage.error('API不可用')
          // 不跳转到时间轴页面，保持在当前页面
        }
      } catch (error) {
        console.error('获取时间胶囊详情失败:', error)
        // 检查是否是JSON解析错误
        if (error?.response?.status === 500 && error?.response?.data?.message?.includes('nesting depth')) {
          ElMessage.error('服务器返回数据格式错误，请联系管理员')
          console.error('检测到JSON序列化循环引用错误，后端需要修复关联查询')
        } else if (error?.response?.status === 404) {
          ElMessage.error('时间胶囊不存在或已被删除')
        } else if (error?.response?.status === 403) {
          ElMessage.error('无权限访问此时间胶囊')
        } else {
          ElMessage.error('获取时间胶囊详情失败')
        }
        // 不跳转到时间轴页面，保持在当前页面
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
          // 确保 ID 格式正确
          const capsuleId = typeof id === 'string' ? id.trim() : id
          console.log('开启胶囊，ID:', capsuleId)
          console.log('调用API:', `/capsules/${capsuleId}/open`)
          
          const response = await window.$axios.post(`/capsules/${capsuleId}/open`)
          console.log('开启胶囊API响应完整信息:', response)
          console.log('响应状态码:', response?.status)
          console.log('响应数据:', response?.data)
          console.log('响应code:', response?.code)
          console.log('响应message:', response?.message)
          
          // 检查响应格式，支持多种格式
          const isSuccess = response?.code === 200 || response?.status === 200 || response?.data?.code === 200
          const message = response?.message || response?.data?.message || '开启成功'
          
          if (isSuccess) {
            ElMessage.success('时间胶囊开启成功！')
            // 直接更新胶囊状态为已开启
            capsule.value.isOpened = true
            // 重新加载详情，但不跳转到时间轴页面
            try {
              await loadCapsule()
            } catch (loadError) {
              console.error('重新加载胶囊详情失败:', loadError)
              // 不跳转到时间轴页面，保持在当前页面
            }
            
            // 检查并更新成就
            try {
              const achievementResponse = await window.$axios.post('/achievements/check');
              if (achievementResponse?.code === 200 && achievementResponse?.data && achievementResponse.data.length > 0) {
                ElMessage.success(`恭喜！获得了 ${achievementResponse.data.length} 个新成就`);
              }
            } catch (achievementError) {
              console.error('检查成就失败:', achievementError);
            }
          } else {
            console.error('开启失败，响应信息:', response)
            ElMessage.error(message || '开启失败')
          }
        } else {
          ElMessage.error('API不可用')
        }
      } catch (error) {
        console.error('开启时间胶囊失败:', error)
        console.error('错误详情:', error?.response)
        // 提供更详细的错误信息
        if (error?.response?.status === 404) {
          ElMessage.error('时间胶囊不存在或已被删除')
        } else if (error?.response?.status === 403) {
          ElMessage.error('无权限操作此时间胶囊')
        } else {
          ElMessage.error('开启时间胶囊失败')
        }
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
      previewVisible,
      previewImageUrl,
      formatDate,
      isDueToOpen,
      getCapsuleStatus,
      isImage,
      isVideo,
      previewImage,
      openCapsule,
      getSafeMediaUrl,
      getSafeMediaFileName
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
  width: 100%;
  aspect-ratio: 16 / 9;
  object-fit: cover;
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
  color: #333;
}

/* 富文本内容样式 */
.rich-text-content :deep(p) {
  margin: 10px 0;
}

.rich-text-content :deep(img) {
  max-width: 100%;
  height: auto;
  border-radius: 4px;
}

.rich-text-content :deep(ul), .rich-text-content :deep(ol) {
  padding-left: 20px;
  margin: 10px 0;
}

.rich-text-content :deep(blockquote) {
  border-left: 4px solid #ccc;
  padding-left: 10px;
  margin: 10px 0;
  color: #666;
}

.rich-text-content :deep(table) {
  border-collapse: collapse;
  width: 100%;
}

.rich-text-content :deep(table td), .rich-text-content :deep(table th) {
  border: 1px solid #ccc;
  padding: 5px;
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

.creator-info {
  display: flex;
  align-items: center;
  gap: 8px;
}

.creator-avatar {
  width: 24px;
  height: 24px;
  border-radius: 50%;
  object-fit: cover;
}
</style>