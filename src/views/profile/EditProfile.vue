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
  
  // 只做本地预览，不调用上传接口
  const reader = new FileReader()
  reader.onload = (e) => {
    form.avatar = e.target.result
    form.avatarFile = file
  }
  reader.readAsDataURL(file)
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
</style>