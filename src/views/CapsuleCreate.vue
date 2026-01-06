<template>
  <div class="capsule-create">
    <h2>创建时间胶囊</h2>
    <p>记录此刻的想法，设定开启时间，让未来的自己看到</p>
    
    <el-form 
      :model="form" 
      :rules="rules" 
      ref="formRef"
      label-width="120px" 
      class="create-form"
    >
      <!-- 标题 -->
      <el-form-item label="标题" prop="title">
        <el-input 
          v-model="form.title"
          placeholder="给你的时间胶囊起个名字"
          maxlength="50"
          show-word-limit
        />
      </el-form-item>
      
      <!-- 开启时间 -->
      <el-form-item label="开启时间" prop="openDate">
        <el-date-picker
          v-model="form.openDate"
          type="date"
          placeholder="选择胶囊开启的日期"
          style="width: 100%;"
          :disabled-date="disabledDate"
        />
        <p class="form-tip">选择未来的某个日期，到时才能打开这个胶囊</p>
      </el-form-item>
      
      <!-- 多媒体上传 -->
      <el-form-item label="封面图片">
        <el-upload
          class="cover-uploader"
          action="#"
          :show-file-list="false"
          :before-upload="handleCoverUpload"
          :on-remove="removeCover"
        >
          <img v-if="form.cover" :src="form.cover" class="cover-image" />
          <el-icon v-else class="cover-uploader-icon"><Plus /></el-icon>
        </el-upload>
        <p class="form-tip">上传一张封面图片，让胶囊更美观（可选）</p>
      </el-form-item>

      <el-form-item label="视频/图片">
        <el-upload
          v-model:file-list="form.mediaFiles"
          action="#"
          list-type="picture-card"
          :before-upload="handleMediaUpload"
          :on-remove="handleMediaRemove"
          :limit="9"
        >
          <el-icon><Plus /></el-icon>
        </el-upload>
        <p class="form-tip">可以上传多张图片或视频（最多9个）</p>
      </el-form-item>
      
      <!-- 文本内容 -->
      <el-form-item label="内容" prop="content">
        <el-input
          v-model="form.content"
          type="textarea"
          :rows="8"
          placeholder="写下你想对未来的自己说的话..."
          maxlength="2000"
          show-word-limit
        />
      </el-form-item>

      <!-- 隐私设置 -->
      <el-form-item label="隐私设置">
        <div class="form-item-wrapper">
          <el-radio-group v-model="form.privacy">
            <el-radio label="private">
              <el-icon><Lock /></el-icon>
              仅自己可见
            </el-radio>
            <el-radio label="public">
              <el-icon><Unlock /></el-icon>
              公开分享
            </el-radio>
          </el-radio-group>
          <p class="form-tip">选择公开后，其他用户可以看到你的时间胶囊</p>
        </div>
      </el-form-item>

      <!-- 提醒设置 -->
      <el-form-item label="开启提醒">
        <div class="form-item-wrapper">
          <el-switch 
            v-model="form.enableReminder"
            active-text="开启"
            inactive-text="关闭"
          />
          <p class="form-tip">开启后，在胶囊开启日期会收到提醒通知</p>
        </div>
      </el-form-item>
      
      <!-- 操作按钮 -->
      <el-form-item>
        <el-button type="primary" size="large" @click="handleSubmit" :loading="submitting">
          <el-icon><Check /></el-icon>
          保存胶囊
        </el-button>
        <el-button size="large" @click="handleCancel">取消</el-button>
        <el-button size="large" @click="handleSaveDraft" v-if="form.id">保存草稿</el-button>
      </el-form-item>
    </el-form>
  </div>
</template>

<script>
import { ref, reactive } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus, Lock, Unlock, Check } from '@element-plus/icons-vue'

export default {
  name: 'CapsuleCreate',
  components: {
    Plus,
    Lock,
    Unlock,
    Check
  },
  setup() {
    const router = useRouter()
    const formRef = ref(null)
    const submitting = ref(false)
    
    const form = reactive({
      title: '',
      openDate: '',
      content: '',
      cover: '',
      privacy: 'private',
      enableReminder: true,
      mediaFiles: []
    })

    const rules = {
      title: [
        { required: true, message: '请输入标题', trigger: 'blur' },
        { min: 2, max: 50, message: '标题长度在 2 到 50 个字符', trigger: 'blur' }
      ],
      openDate: [
        { required: true, message: '请选择开启时间', trigger: 'change' }
      ],
      content: [
        { required: true, message: '请输入内容', trigger: 'blur' },
        { min: 10, message: '内容至少10个字符', trigger: 'blur' }
      ]
    }

    // 禁用过去的日期
    const disabledDate = (time) => {
      return time.getTime() < Date.now() - 8.64e7 // 不能选择今天之前的日期
    }

    // 处理封面图片上传
    const handleCoverUpload = async (file) => {
      // 检查文件类型
      const isImage = file.type.startsWith('image/')
      if (!isImage) {
        ElMessage.error('请上传图片文件')
        return false
      }
      
      // 检查文件大小 (10MB)
      const isLt10M = file.size / 1024 / 1024 < 10
      if (!isLt10M) {
        ElMessage.error('图片大小不能超过10MB')
        return false
      }
      
      try {
        // 上传到服务器
        const formData = new FormData()
        formData.append('file', file)
        
        const response = await window.$axios.post('/upload', formData, {
          headers: {
            'Content-Type': 'multipart/form-data'
          }
        })
        
        if (response?.code === 200) {
          // 上传成功，更新封面URL
          form.cover = response.data.fileUrl
          ElMessage.success('封面上传成功')
        } else {
          ElMessage.error(response?.message || '封面上传失败')
          return false
        }
      } catch (error) {
        console.error('封面上传失败:', error)
        ElMessage.error('封面上传失败: ' + (error.response?.data?.message || error.message))
        return false
      }
      
      return false // 阻止自动上传
    }

    const removeCover = () => {
      form.cover = ''
    }

    // 处理媒体文件上传
    const handleMediaUpload = async (file) => {
      // 检查文件类型
      const isImage = file.type.startsWith('image/')
      const isVideo = file.type.startsWith('video/')
      if (!isImage && !isVideo) {
        ElMessage.error('请上传图片或视频文件')
        return false
      }
      
      // 检查文件大小 (10MB)
      const isLt10M = file.size / 1024 / 1024 < 10
      if (!isLt10M) {
        ElMessage.error('文件大小不能超过10MB')
        return false
      }
      
      try {
        // 上传到服务器
        const formData = new FormData()
        formData.append('file', file)
        
        const response = await window.$axios.post('/upload', formData, {
          headers: {
            'Content-Type': 'multipart/form-data'
          }
        })
        
        if (response?.code === 200) {
          // 上传成功，添加到媒体文件列表
          form.mediaFiles.push({
            uid: Date.now(),
            name: file.name,
            url: response.data.fileUrl,
            type: file.type,
            size: file.size
          })
          ElMessage.success('媒体文件上传成功')
        } else {
          ElMessage.error(response?.message || '媒体文件上传失败')
          return false
        }
      } catch (error) {
        console.error('媒体文件上传失败:', error)
        ElMessage.error('媒体文件上传失败: ' + (error.response?.data?.message || error.message))
        return false
      }
      
      return false
    }

    const handleMediaRemove = (file) => {
      const index = form.mediaFiles.findIndex(item => item.uid === file.uid)
      if (index > -1) {
        form.mediaFiles.splice(index, 1)
      }
    }

    // 提交表单
    const handleSubmit = async () => {
      if (!formRef.value) return
      
      await formRef.value.validate((valid) => {
        if (valid) {
          submitting.value = true
          try {
            // 使用API调用创建时间胶囊
            if (window.$axios) {
              const capsuleData = {
                title: form.title,
                content: form.content,
                coverImage: form.cover,
                openDate: form.openDate ? new Date(new Date(form.openDate).setHours(0, 0, 0, 0)).toISOString().split('T')[0] : null,
                privacy: form.privacy.toUpperCase(),
                enableReminder: form.enableReminder,
                mediaFiles: form.mediaFiles.map(file => ({
                  fileUrl: file.url,
                  fileName: file.name,
                  fileType: file.type?.startsWith('image/') ? 'IMAGE' : 'VIDEO', // 根据文件类型确定
                  mimeType: file.type,
                  fileSize: file.size
                }))
              };
              
              window.$axios.post('/capsules', capsuleData).then(response => {
                if (response?.code === 201) {
                  ElMessage.success('时间胶囊创建成功！');
                  // 设置一个标记，通知主页数据已更新
                  localStorage.setItem('capsuleCreated', Date.now().toString());
                  // 跳转到主页
                  router.push('/');
                } else {
                  ElMessage.error(response?.message || '创建失败');
                }
              }).catch(error => {
                console.error('创建时间胶囊失败:', error);
                ElMessage.error('创建失败: ' + (error.response?.data?.message || error.message));
              });
            } else {
              // 如果没有API，回退到本地存储
              const capsules = JSON.parse(localStorage.getItem('capsules') || '[]');
              capsules.push({
                id: Date.now(),
                ...form,
                date: new Date().toISOString().split('T')[0],
                openDate: form.openDate ? new Date(form.openDate).toISOString().split('T')[0] : ''
              });
              localStorage.setItem('capsules', JSON.stringify(capsules));
              ElMessage.success('时间胶囊创建成功！');
              router.push('/');
            }
          } catch (error) {
            console.error('创建时间胶囊失败:', error);
            ElMessage.error('创建失败: ' + (error.response?.data?.message || error.message));
          } finally {
            submitting.value = false;
          }
        } else {
          ElMessage.warning('请填写完整信息');
        }
      })
    }

    // 取消
    const handleCancel = () => {
      ElMessageBox.confirm('确定要取消吗？未保存的内容将丢失。', '提示', {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }).then(() => {
        router.push('/')
      }).catch(() => {})
    }

    // 保存草稿
    const handleSaveDraft = () => {
      const drafts = JSON.parse(localStorage.getItem('drafts') || '[]')
      drafts.push({
        id: Date.now(),
        ...form,
        savedAt: new Date().toISOString()
      })
      localStorage.setItem('drafts', JSON.stringify(drafts))
      ElMessage.success('草稿已保存')
    }

    return {
      formRef,
      form,
      rules,
      submitting,
      disabledDate,
      handleCoverUpload,
      removeCover,
      handleMediaUpload,
      handleMediaRemove,
      handleSubmit,
      handleCancel,
      handleSaveDraft
    }
  }
}
</script>

<style scoped>
.capsule-create {
  padding: 0;
  margin: 0;
  width: 100%;
  min-height: calc(100vh - 120px);
}

h2 {
  color: #333;
  font-size: 24px;
  font-weight: 600;
  margin-bottom: 8px;
}

p {
  color: #666;
  font-size: 14px;
  margin-bottom: 30px;
}

.create-form {
  max-width: 800px;
}

.form-tip {
  font-size: 12px;
  color: #999;
  margin: 8px 0 0 0;
  line-height: 1.5;
}

.form-item-wrapper {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

/* 特殊处理隐私设置和提醒设置的提示文字 */
.form-item-wrapper .form-tip {
  margin: 0;
  font-size: 12px;
  color: #999;
  line-height: 1.5;
}

/* 封面图片上传 */
.cover-uploader {
  width: 200px;
}

.cover-image {
  width: 200px;
  height: 200px;
  object-fit: cover;
  border-radius: 8px;
  display: block;
}

.cover-uploader-icon {
  font-size: 28px;
  color: #8c939d;
  width: 200px;
  height: 200px;
  line-height: 200px;
  text-align: center;
  border: 2px dashed #d9d9d9;
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.3s;
}

.cover-uploader-icon:hover {
  border-color: #409EFF;
}

/* 媒体文件上传 */
:deep(.el-upload--picture-card) {
  width: 100px;
  height: 100px;
  line-height: 100px;
}

:deep(.el-upload-list--picture-card .el-upload-list__item) {
  width: 100px;
  height: 100px;
}

/* 单选框样式 */
:deep(.el-radio) {
  margin-right: 20px;
}

:deep(.el-radio__label) {
  display: flex;
  align-items: center;
  gap: 5px;
}
</style>