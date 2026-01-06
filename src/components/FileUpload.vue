<template>
  <div class="file-upload">
    <el-upload
      ref="uploadRef"
      :action="uploadAction"
      :headers="uploadHeaders"
      :data="uploadData"
      :accept="accept"
      :multiple="multiple"
      :limit="limit"
      :on-change="handleFileChange"
      :on-success="handleUploadSuccess"
      :on-error="handleUploadError"
      :on-remove="handleRemove"
      :before-upload="beforeUpload"
      :file-list="fileList"
      :auto-upload="false"
      :list-type="listType"
      :show-file-list="showFileList"
    >
      <slot name="trigger">
        <el-button type="primary" @click="handleClickUpload">
          <el-icon><Upload /></el-icon>
          {{ buttonText }}
        </el-button>
      </slot>
      <template #tip v-if="showTip">
        <div class="el-upload__tip">
          {{ tipText }}
        </div>
      </template>
    </el-upload>
    
    <!-- 上传进度条 -->
    <el-progress 
      v-if="uploading" 
      :percentage="uploadProgress" 
      :status="uploadProgress > 0 && uploadProgress < 100 ? 'success' : ''"
      :stroke-width="2"
    />
  </div>
</template>

<script setup>
import { ref, computed, reactive } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Upload } from '@element-plus/icons-vue'
import { uploadAPI } from '@/api'

// 定义props
const props = defineProps({
  // 上传类型：MEDIA 或 COVER
  uploadType: {
    type: String,
    default: 'MEDIA'
  },
  // 接受的文件类型
  accept: {
    type: String,
    default: 'image/*,video/*'
  },
  // 是否多选
  multiple: {
    type: Boolean,
    default: false
  },
  // 文件数量限制
  limit: {
    type: Number,
    default: 1
  },
  // 按钮文字
  buttonText: {
    type: String,
    default: '选择文件'
  },
  // 是否显示提示
  showTip: {
    type: Boolean,
    default: true
  },
  // 提示文字
  tipText: {
    type: String,
    default: '支持 JPG、PNG、MP4 等格式，单个文件最大10MB'
  },
  // 列表类型
  listType: {
    type: String,
    default: 'text' // text, picture, picture-card
  },
  // 是否显示文件列表
  showFileList: {
    type: Boolean,
    default: true
  },
  // 最大文件大小（MB）
  maxSize: {
    type: Number,
    default: 10
  }
})

// 定义emit
const emit = defineEmits(['upload-success', 'upload-error', 'file-change', 'file-remove'])

// 响应式数据
const fileList = ref([])
const uploading = ref(false)
const uploadProgress = ref(0)
const uploadRef = ref(null)

// 计算属性
const uploadAction = computed(() => '/api/upload') // 实际上传地址

const uploadHeaders = computed(() => {
  const token = localStorage.getItem('token')
  return {
    Authorization: `Bearer ${token}`
  }
})

const uploadData = computed(() => {
  return {
    type: props.uploadType
  }
})

// 方法
const beforeUpload = (file) => {
  // 文件类型验证
  const isImage = file.type.startsWith('image/')
  const isVideo = file.type.startsWith('video/')
  
  if (!isImage && !isVideo) {
    ElMessage.error('只能上传图片或视频文件!')
    return false
  }
  
  // 文件大小验证
  const isLtSize = file.size / 1024 / 1024 < props.maxSize
  if (!isLtSize) {
    ElMessage.error(`文件大小不能超过 ${props.maxSize}MB!`)
    return false
  }
  
  return true
}

const handleFileChange = (file, fileList) => {
  emit('file-change', file, fileList)
}

const handleUploadSuccess = (response, file, fileList) => {
  uploading.value = false
  uploadProgress.value = 0
  
  if (response.code === 200) {
    ElMessage.success(response.message || '上传成功')
    emit('upload-success', response.data, file, fileList)
  } else {
    ElMessage.error(response.message || '上传失败')
    emit('upload-error', response, file, fileList)
  }
}

const handleUploadError = (error, file, fileList) => {
  uploading.value = false
  uploadProgress.value = 0
  ElMessage.error('上传失败: ' + (error.message || '未知错误'))
  emit('upload-error', error, file, fileList)
}

const handleRemove = (file, fileList) => {
  emit('file-remove', file, fileList)
}

const handleClickUpload = () => {
  // 可以在这里添加额外的逻辑
}

// 暴露给父组件的方法
defineExpose({
  uploadFile,
  submitUpload,
  clearFiles
})

// 提交上传
const submitUpload = () => {
  if (fileList.value.length === 0) {
    ElMessage.warning('请选择要上传的文件')
    return
  }
  
  // 使用前端API调用
  const file = fileList.value[0]?.raw || fileList.value[0]
  if (file) {
    uploadFile(file)
  }
}

// 直接上传文件
const uploadFile = async (file) => {
  try {
    uploading.value = true
    uploadProgress.value = 10 // 开始上传
    
    // 模拟上传进度（实际项目中可以移除这个模拟）
    const interval = setInterval(() => {
      if (uploadProgress.value < 90) {
        uploadProgress.value += 10
      }
    }, 200)
    
    // 创建FormData并添加文件和类型
    const formData = new FormData()
    formData.append('file', file)
    formData.append('type', props.uploadType)
    
    const response = await uploadAPI.uploadFile(formData)
    clearInterval(interval)
    uploadProgress.value = 100
    
    handleUploadSuccess(response.data, { raw: file }, [file])
    return response.data
  } catch (error) {
    handleUploadError(error, { raw: file }, [file])
    throw error
  }
}

// 清空文件列表
const clearFiles = () => {
  fileList.value = []
  if (uploadRef.value) {
    uploadRef.value.clearFiles()
  }
}
</script>

<style scoped>
.file-upload {
  width: 100%;
}

.el-upload__tip {
  font-size: 12px;
  color: #909399;
  margin-top: 7px;
}

.el-progress {
  margin-top: 10px;
}
</style>