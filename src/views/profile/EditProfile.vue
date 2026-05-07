<template>
  <div class="profile-container">
    <h2 class="page-title">编辑资料</h2>
    <div class="profile-edit">
      <el-form :model="form" :rules="rules" ref="formRef" label-width="100px">
        <el-form-item label="昵称" prop="nickname">
          <el-input v-model="form.nickname" placeholder="请输入昵称" />
        </el-form-item>
        <el-form-item label="头像">
          <div class="avatar-upload-container">
            <input type="file" ref="fileInput" style="display: none" accept="image/*" @change="handleFileChange">
            <div 
              :class="['avatar-uploader', { 'has-avatar': form.avatar }]"
              @click="triggerFileInput"
            >
              <img v-if="form.avatar" :src="form.avatar" class="avatar" />
              <el-icon v-else class="avatar-uploader-icon"><Plus /></el-icon>
              <div v-if="!form.avatar" class="upload-hint">点击上传头像</div>
            </div>
          </div>
        </el-form-item>
        <el-form-item label="个人简介" prop="bio">
          <el-input
            v-model="form.bio"
            type="textarea"
            placeholder="请输入个人简介"
            :rows="4"
          />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="submitForm">保存修改</el-button>
          <el-button @click="resetForm">重置</el-button>
        </el-form-item>
      </el-form>
    </div>
  </div>

  <!-- 头像裁剪弹窗 -->
  <el-dialog
    v-model="showCropper"
    title="裁剪头像"
    width="600px"
    :close-on-click-modal="false"
    :before-close="closeCropper"
  >
    <div class="cropper-container">
      <div class="cropper-wrapper">
        <canvas 
          ref="cropperCanvas" 
          class="cropper-canvas"
          :width="canvasWidth"
          :height="canvasHeight"
          @mousedown="startCrop"
          @mousemove="onCropMove"
          @mouseup="endCrop"
          @mouseleave="endCrop"
        ></canvas>
        <div 
          v-if="cropArea"
          class="crop-area"
          :style="{
            left: cropArea.x + 'px',
            top: cropArea.y + 'px',
            width: cropArea.size + 'px',
            height: cropArea.size + 'px'
          }"
          @mousedown.stop="startCrop"
          @mousemove.stop="onCropMove"
          @mouseup.stop="endCrop"
          @mouseleave.stop="endCrop"
        >
          <div class="crop-grid"></div>
          <div class="crop-handle top-left"></div>
          <div class="crop-handle top-right"></div>
          <div class="crop-handle bottom-left"></div>
          <div class="crop-handle bottom-right"></div>
        </div>
        <div v-if="!cropArea" class="crop-hint">拖动鼠标选择裁剪区域（1:1）</div>
      </div>
      <div class="cropper-preview">
        <div class="preview-title">预览</div>
        <div class="preview-box">
          <canvas ref="previewCanvas" class="preview-canvas"></canvas>
        </div>
      </div>
    </div>
    <template #footer>
      <el-button @click="closeCropper">取消</el-button>
      <el-button type="primary" @click="confirmCrop">确认裁剪</el-button>
    </template>
  </el-dialog>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import { Plus } from '@element-plus/icons-vue'

const formRef = ref(null)
const fileInput = ref(null)
const form = reactive({
  nickname: '',
  avatar: '',
  bio: '',
  avatarFile: null
})

// 头像裁剪相关
const showCropper = ref(false)
const cropperCanvas = ref(null)
const previewCanvas = ref(null)
const originalImage = ref(null)
const canvasWidth = ref(400)
const canvasHeight = ref(300)

const cropArea = reactive({
  x: 0,
  y: 0,
  size: 150
})

const isDragging = ref(false)
const dragStart = reactive({ x: 0, y: 0 })
const dragType = ref('') // 'move', 'resize', ''

const rules = {
  nickname: [
    { required: true, message: '请输入昵称', trigger: 'blur' },
    { min: 2, max: 20, message: '昵称长度在 2 到 20 个字符', trigger: 'blur' }
  ]
}

// 加载用户信息
const loadUserInfo = async () => {
  if (window.$axios) {
    try {
      const response = await window.$axios.get('/users/profile')
      if (response?.code === 200 && response?.data) {
        const userData = response.data
        form.nickname = userData.nickname || ''
        form.avatar = userData.avatar || ''
        form.bio = userData.bio || ''
      }
    } catch (e) {
      console.error('获取用户信息失败:', e)
      ElMessage.error('获取用户信息失败')
    }
  }
}

// 提交表单
const submitForm = async () => {
  if (!formRef.value) return
  
  await formRef.value.validate(async (valid) => {
    if (valid) {
      if (window.$axios) {
        try {
          // 如果有头像文件，先上传头像
          if (form.avatarFile) {
            const formData = new FormData()
            formData.append('file', form.avatarFile)
            formData.append('type', 'COVER')
            
            const token = localStorage.getItem('token')
            const headers = token ? { Authorization: 'Bearer ' + token } : {}
            
            const uploadResponse = await window.$axios.post('/upload', formData, {
              headers: {
                ...headers,
                'Content-Type': 'multipart/form-data'
              }
            })
            
            if (uploadResponse?.code === 200 && uploadResponse?.data) {
              form.avatar = uploadResponse.data.fileUrl
            } else {
              ElMessage.error('头像上传失败')
              return
            }
          }
          
          // 提交用户资料
          const response = await window.$axios.put('/users/profile', {
            nickname: form.nickname,
            avatar: form.avatar,
            bio: form.bio
          })
          
          if (response?.code === 200) {
            ElMessage.success('修改成功')
            // 更新本地存储的用户信息
            const user = localStorage.getItem('user')
            if (user) {
              const userObj = JSON.parse(user)
              userObj.nickname = form.nickname
              userObj.avatar = form.avatar
              userObj.bio = form.bio
              localStorage.setItem('user', JSON.stringify(userObj))
              // 触发user-login事件，通知其他组件更新
              window.dispatchEvent(new Event('user-login'))
            }
          } else {
            ElMessage.error('修改失败')
          }
        } catch (e) {
          console.error('修改失败:', e)
          ElMessage.error('修改失败: ' + (e.response?.data?.message || e.message))
        }
      }
    } else {
      console.log('表单验证失败')
      return false
    }
  })
}

// 重置表单
const resetForm = () => {
  if (formRef.value) {
    formRef.value.resetFields()
  }
  form.avatarFile = null
}

// 触发文件输入
const triggerFileInput = () => {
  if (fileInput.value) {
    fileInput.value.click()
  }
}

// 处理文件选择
const handleFileChange = (event) => {
  const files = event.target.files
  if (files.length > 0) {
    const file = files[0]
    handleFileUpload(file)
  }
  // 重置文件输入框的值，确保被删除的图片可以再次添加
  if (event.target) {
    event.target.value = ''
  }
}

// 处理文件上传（本地预览）
const handleFileUpload = (file) => {
  // 检查文件类型
  if (!file.type.startsWith('image/')) {
    ElMessage.error('请上传图片文件')
    return
  }
  
  // 检查文件大小 (2MB)
  if (file.size / 1024 / 1024 > 2) {
    ElMessage.error('图片大小不能超过2MB')
    return
  }
  
  // 读取图片并打开裁剪弹窗
  const reader = new FileReader()
  reader.onload = (e) => {
    form.avatarFile = file
    openCropper(e.target.result)
  }
  reader.readAsDataURL(file)
}

// 打开裁剪弹窗
const openCropper = (imageSrc) => {
  const img = new Image()
  img.onload = () => {
    originalImage.value = img
    // 计算画布尺寸，保持图片比例，确保完整显示
    const maxWidth = 520
    const maxHeight = 400
    let width = img.width
    let height = img.height
    
    // 保持图片比例，缩小到最大尺寸以内
    const scale = Math.min(maxWidth / width, maxHeight / height, 1)
    width = width * scale
    height = height * scale
    
    canvasWidth.value = width
    canvasHeight.value = height
    
    // 初始化裁剪区域（默认大小为图片较小边的80%）
    const defaultSize = Math.min(width, height) * 0.8
    cropArea.x = (width - defaultSize) / 2
    cropArea.y = (height - defaultSize) / 2
    cropArea.size = defaultSize
    
    showCropper.value = true
    
    // 等待DOM更新后绘制画布
    setTimeout(() => {
      drawCanvas()
      updatePreview()
    }, 100)
  }
  img.src = imageSrc
}

// 绘制画布
const drawCanvas = () => {
  const canvas = cropperCanvas.value
  if (!canvas || !originalImage.value) return
  
  const ctx = canvas.getContext('2d')
  ctx.clearRect(0, 0, canvas.width, canvas.height)
  ctx.drawImage(originalImage.value, 0, 0, canvasWidth.value, canvasHeight.value)
  
  // 绘制遮罩
  ctx.fillStyle = 'rgba(0, 0, 0, 0.5)'
  ctx.fillRect(0, 0, canvas.width, canvas.height)
  
  // 清除裁剪区域的遮罩
  ctx.clearRect(cropArea.x, cropArea.y, cropArea.size, cropArea.size)
  
  // 重新绘制裁剪区域内的图像
  ctx.drawImage(
    originalImage.value,
    (cropArea.x / canvasWidth.value) * originalImage.value.width,
    (cropArea.y / canvasHeight.value) * originalImage.value.height,
    (cropArea.size / canvasWidth.value) * originalImage.value.width,
    (cropArea.size / canvasHeight.value) * originalImage.value.height,
    cropArea.x,
    cropArea.y,
    cropArea.size,
    cropArea.size
  )
}

// 更新预览
const updatePreview = () => {
  const preview = previewCanvas.value
  if (!preview || !originalImage.value) return
  
  const ctx = preview.getContext('2d')
  ctx.clearRect(0, 0, preview.width, preview.height)
  
  // 从原图裁剪并绘制到预览
  ctx.drawImage(
    originalImage.value,
    (cropArea.x / canvasWidth.value) * originalImage.value.width,
    (cropArea.y / canvasHeight.value) * originalImage.value.height,
    (cropArea.size / canvasWidth.value) * originalImage.value.width,
    (cropArea.size / canvasHeight.value) * originalImage.value.height,
    0,
    0,
    preview.width,
    preview.height
  )
}

// 开始裁剪
const startCrop = (e) => {
  const rect = cropperCanvas.value.getBoundingClientRect()
  const x = e.clientX - rect.left
  const y = e.clientY - rect.top
  
  // 判断是否点击在裁剪区域内
  if (x >= cropArea.x && x <= cropArea.x + cropArea.size &&
      y >= cropArea.y && y <= cropArea.y + cropArea.size) {
    
    // 判断是否点击在边角（调整大小）
    const handleSize = 10
    const distX = Math.min(x - cropArea.x, cropArea.size - (x - cropArea.x))
    const distY = Math.min(y - cropArea.y, cropArea.size - (y - cropArea.y))
    
    if (distX < handleSize && distY < handleSize) {
      // 右下角
      dragType.value = 'resize-br'
    } else if (distX < handleSize && (y - cropArea.y) < handleSize) {
      // 左上角
      dragType.value = 'resize-tl'
    } else if ((x - cropArea.x) < handleSize && distY < handleSize) {
      // 左下角
      dragType.value = 'resize-bl'
    } else if (distY < handleSize) {
      // 右上角
      dragType.value = 'resize-tr'
    } else {
      // 移动
      dragType.value = 'move'
    }
    
    dragStart.x = x
    dragStart.y = y
    isDragging.value = true
    
    // 添加全局鼠标事件监听，确保在整个页面上都能响应拖动
    document.addEventListener('mousemove', globalCropMove)
    document.addEventListener('mouseup', globalCropEnd)
  }
}

// 裁剪移动（局部事件处理）
const onCropMove = (e) => {
  globalCropMove(e)
}

// 全局裁剪移动处理
const globalCropMove = (e) => {
  if (!isDragging.value || !cropperCanvas.value) return
  
  const rect = cropperCanvas.value.getBoundingClientRect()
  const x = e.clientX - rect.left
  const y = e.clientY - rect.top
  
  const dx = x - dragStart.x
  const dy = y - dragStart.y
  
  if (dragType.value === 'move') {
    // 移动裁剪区域
    let newX = cropArea.x + dx
    let newY = cropArea.y + dy
    
    // 边界限制
    newX = Math.max(0, Math.min(newX, canvasWidth.value - cropArea.size))
    newY = Math.max(0, Math.min(newY, canvasHeight.value - cropArea.size))
    
    cropArea.x = newX
    cropArea.y = newY
  } else {
    // 调整大小
    let newSize = cropArea.size
    let newX = cropArea.x
    let newY = cropArea.y
    
    if (dragType.value.includes('br')) {
      newSize = cropArea.size + dx
    } else if (dragType.value.includes('tl')) {
      newSize = cropArea.size - dx
      newX = cropArea.x + dx
      newY = cropArea.y + dy
    } else if (dragType.value.includes('bl')) {
      newSize = cropArea.size + dx
      newY = cropArea.y - dy
    } else if (dragType.value.includes('tr')) {
      newSize = cropArea.size - dx
      newX = cropArea.x + dx
    }
    
    // 限制最小尺寸
    newSize = Math.max(50, Math.min(newSize, Math.min(canvasWidth.value, canvasHeight.value)))
    
    // 调整位置防止溢出
    newX = Math.max(0, Math.min(newX, canvasWidth.value - newSize))
    newY = Math.max(0, Math.min(newY, canvasHeight.value - newSize))
    
    cropArea.size = newSize
    cropArea.x = newX
    cropArea.y = newY
  }
  
  dragStart.x = x
  dragStart.y = y
  
  drawCanvas()
  updatePreview()
}

// 结束裁剪（局部事件处理）
const endCrop = () => {
  globalCropEnd()
}

// 全局裁剪结束处理
const globalCropEnd = () => {
  isDragging.value = false
  dragType.value = ''
  
  // 移除全局鼠标事件监听
  document.removeEventListener('mousemove', globalCropMove)
  document.removeEventListener('mouseup', globalCropEnd)
}

// 关闭裁剪弹窗
const closeCropper = () => {
  showCropper.value = false
  originalImage.value = null
}

// 确认裁剪
const confirmCrop = () => {
  if (!originalImage.value) {
    ElMessage.error('请选择图片')
    return
  }
  
  // 创建最终头像（200x200）
  const finalCanvas = document.createElement('canvas')
  finalCanvas.width = 200
  finalCanvas.height = 200
  
  const ctx = finalCanvas.getContext('2d')
  ctx.drawImage(
    originalImage.value,
    (cropArea.x / canvasWidth.value) * originalImage.value.width,
    (cropArea.y / canvasHeight.value) * originalImage.value.height,
    (cropArea.size / canvasWidth.value) * originalImage.value.width,
    (cropArea.size / canvasHeight.value) * originalImage.value.height,
    0,
    0,
    200,
    200
  )
  
  // 转换为base64
  form.avatar = finalCanvas.toDataURL('image/png')
  
  // 关闭弹窗
  showCropper.value = false
  originalImage.value = null
  
  ElMessage.success('头像裁剪成功')
}

onMounted(() => {
  loadUserInfo()
})
</script>

<style scoped>
.profile-container {
  max-width: 800px;
  margin: 0 auto;
  padding: 30px 20px;
}

.page-title {
  font-size: 24px;
  font-weight: 600;
  color: #303133;
  margin-bottom: 24px;
  text-align: center;
}

.profile-edit {
  padding: 30px;
  background-color: #fff;
  border-radius: 16px;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.08);
  transition: all 0.3s ease;
}

.profile-edit:hover {
  box-shadow: 0 6px 24px rgba(0, 0, 0, 0.12);
}

/* 表单样式 */
:deep(.el-form-item) {
  margin-bottom: 20px;
}

:deep(.el-form-item__label) {
  font-weight: 500;
  color: #303133;
}

:deep(.el-input__wrapper) {
  border-radius: 8px;
  transition: all 0.3s ease;
}

:deep(.el-input__wrapper:hover) {
  box-shadow: 0 0 0 2px rgba(64, 158, 255, 0.1);
}

:deep(.el-textarea__inner) {
  border-radius: 8px;
  resize: none;
}

/* 按钮样式 */
:deep(.el-button) {
  border-radius: 8px;
  padding: 10px 20px;
  font-weight: 500;
  transition: all 0.3s ease;
}

:deep(.el-button--primary) {
  background-color: #409eff;
  border-color: #409eff;
}

:deep(.el-button--primary:hover) {
  background-color: #66b1ff;
  border-color: #66b1ff;
}

/* 头像上传样式 */
.avatar-uploader {
  border: 2px dashed #d9d9d9;
  border-radius: 12px;
  cursor: pointer;
  position: relative;
  overflow: hidden;
  transition: all 0.3s ease;
  background-color: #fafafa;
  display: inline-block;
}

.avatar-uploader:hover {
  border-color: #409eff;
  background-color: #f0f9ff;
}

.avatar-uploader-icon {
  font-size: 32px;
  color: #8c939d;
  width: 150px;
  height: 150px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.avatar {
  width: 150px;
  height: 150px;
  display: block;
  border-radius: 12px;
  object-fit: cover;
  border: none;
}

/* 移除头像显示时的边框 */
.avatar-uploader.has-avatar {
  border: none;
  background-color: transparent;
  cursor: default;
}

.avatar-uploader.has-avatar:hover {
  border: none;
  background-color: transparent;
}

/* 头像上传容器 */
.avatar-upload-container {
  position: relative;
  display: inline-block;
}

/* 上传提示 */
.upload-hint {
  position: absolute;
  bottom: 0;
  left: 0;
  right: 0;
  background-color: rgba(0, 0, 0, 0.6);
  color: white;
  text-align: center;
  padding: 8px 0;
  border-bottom-left-radius: 12px;
  border-bottom-right-radius: 12px;
  font-size: 14px;
  opacity: 0;
  transition: opacity 0.3s ease;
}

.avatar-uploader:hover .upload-hint {
  opacity: 1;
}

/* 响应式设计 */
@media (max-width: 768px) {
  .profile-container {
    padding: 20px 15px;
  }
  
  .profile-edit {
    padding: 20px;
  }
  
  .page-title {
    font-size: 20px;
  }
  
  :deep(.el-form-item) {
    margin-bottom: 16px;
  }
  
  .avatar-uploader-icon {
    width: 120px;
    height: 120px;
    font-size: 28px;
  }
  
  .avatar {
    width: 120px;
    height: 120px;
  }
}

@media (max-width: 480px) {
  .profile-edit {
    padding: 16px;
  }
  
  :deep(.el-form) {
    label-width: 80px !important;
  }
}

/* 头像裁剪器样式 */
.cropper-container {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 20px;
}

.cropper-wrapper {
  position: relative;
  overflow: hidden;
  border-radius: 8px;
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.1);
}

.cropper-canvas {
  cursor: crosshair;
  display: block;
  max-width: 100%;
}

.crop-area {
  position: absolute;
  border: 2px solid #409eff;
  box-sizing: border-box;
  cursor: move;
}

.crop-grid {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background-image: 
    linear-gradient(rgba(64, 158, 255, 0.3) 1px, transparent 1px),
    linear-gradient(90deg, rgba(64, 158, 255, 0.3) 1px, transparent 1px);
  background-size: 20px 20px;
}

.crop-handle {
  position: absolute;
  width: 10px;
  height: 10px;
  background-color: #409eff;
  border-radius: 50%;
  border: 2px solid #fff;
  cursor: nwse-resize;
}

.crop-handle.top-left {
  top: -5px;
  left: -5px;
}

.crop-handle.top-right {
  top: -5px;
  right: -5px;
}

.crop-handle.bottom-left {
  bottom: -5px;
  left: -5px;
}

.crop-handle.bottom-right {
  bottom: -5px;
  right: -5px;
  cursor: nesw-resize;
}

.crop-hint {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  background-color: rgba(0, 0, 0, 0.6);
  color: #fff;
  padding: 10px 20px;
  border-radius: 8px;
  font-size: 14px;
  pointer-events: none;
}

.cropper-preview {
  display: flex;
  flex-direction: column;
  align-items: center;
}

.preview-title {
  font-size: 14px;
  color: #606266;
  margin-bottom: 10px;
}

.preview-box {
  width: 100px;
  height: 100px;
  border-radius: 50%;
  overflow: hidden;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}

.preview-canvas {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

:deep(.el-dialog__body) {
  padding: 20px;
}

:deep(.el-dialog__footer) {
  padding: 10px 20px;
}
</style>