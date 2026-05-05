<template>
  <div class="capsule-create">
    <!-- 全屏加载覆盖层 -->
    <div v-if="submitting" class="loading-overlay">
      <div class="loading-content">
        <div class="loading-spinner"></div>
        <p>加载中...</p>
      </div>
    </div>
    <div class="container">
      <div class="header">
        <h1>封存此刻的记忆</h1>
        <p>在时光的河流中投下一枚种子，静待未来的你亲手开启。</p>
      </div>
      
      <div class="content">
        <!-- 左侧表单区域 -->
        <div class="form-section">
          <el-form 
            :model="form" 
            :rules="rules" 
            ref="formRef"
            class="create-form"
          >
            <!-- 标题 -->
            <el-form-item prop="title">
              <div class="form-label">胶囊标题</div>
              <el-input 
                v-model="form.title"
                placeholder="给这封未来的信起个名字..."
                maxlength="50"
              />
            </el-form-item>
            
            <!-- 开启时间和隐私设置 -->
            <div class="form-row">
              <el-form-item prop="openDate" class="form-item-half">
                <div class="form-label">开启时间</div>
                <el-date-picker
                  v-model="form.openDate"
                  type="date"
                  placeholder="年/月/日"
                  format="YYYY/MM/DD"
                  value-format="YYYY-MM-DD"
                  style="width: 100%;"
                  :disabled-date="disabledDate"
                />
              </el-form-item>
              
              <el-form-item class="form-item-half">
                <div class="form-label">隐私设置</div>
                <div class="privacy-buttons">
                  <el-button 
                    :type="form.privacy === 'private' ? 'primary' : 'default'"
                    :class="{ 'privacy-button-active': form.privacy === 'private' }"
                    @click="form.privacy = 'private'"
                    class="privacy-button"
                  >
                    <el-icon><Lock /></el-icon>
                    私密
                  </el-button>
                  <el-button 
                    :type="form.privacy === 'public' ? 'primary' : 'default'"
                    :class="{ 'privacy-button-active': form.privacy === 'public' }"
                    @click="form.privacy = 'public'"
                    class="privacy-button"
                  >
                    <el-icon><Unlock /></el-icon>
                    公开
                  </el-button>
                </div>
              </el-form-item>
            </div>
            
            <!-- 记忆详情 -->
            <el-form-item prop="content">
              <div class="form-label">记忆详情</div>
              <div class="editor-container">
                <div 
                  contenteditable="true"
                  class="editor-textarea"
                  placeholder="在这里写下你的心情、故事或愿望..."
                  @input="updateContent"
                ></div>
                <div class="editor-toolbar">
                  <el-button type="text" size="small" @click="insertFormat('bold')" title="加粗"><b>B</b></el-button>
                  <el-button type="text" size="small" @click="insertFormat('italic')" title="斜体"><i>I</i></el-button>
                  <el-button type="text" size="small" @click="insertLink" title="插入链接"><el-icon><Link /></el-icon></el-button>
                  <el-button type="text" size="small" @click="insertEmoji" title="插入表情">😊</el-button>
                  <el-button type="text" size="small" @click="insertList('ordered')" title="有序列表">1.</el-button>
                  <el-button type="text" size="small" @click="insertList('unordered')" title="无序列表">•</el-button>
                </div>
              </div>
            </el-form-item>
            
            <!-- 上传图片 -->
            <el-form-item>
              <div class="form-label">上传图片</div>
              <div class="upload-container">
                <div class="upload-area" @click="triggerFileInput" @dragover.prevent @drop.prevent="handleDrop">
                  <input type="file" ref="fileInput" style="display: none" accept="image/*" @change="handleFileChange" multiple>
                  <div v-if="form.coverImages.length > 0" class="upload-preview">
                    <div class="image-grid">
                      <div v-for="(image, index) in form.coverImages" :key="index" class="image-item">
                        <img :src="image.url" alt="预览" class="preview-image">
                        <el-button 
                          type="text" 
                          size="small" 
                          class="delete-button" 
                          @click.stop="deleteImage(index)" 
                          @mousedown.stop.prevent 
                          @mouseup.stop.prevent
                          @touchstart.stop.prevent
                          @touchend.stop.prevent
                        >
                          <el-icon><Close /></el-icon>
                        </el-button>
                      </div>
                      <div v-if="form.coverImages.length < 3" class="upload-placeholder small">
                        <el-icon class="upload-icon"><Plus /></el-icon>
                        <p>添加图片</p>
                      </div>
                    </div>
                  </div>
                  <div v-else class="upload-placeholder">
                    <el-icon class="upload-icon"><Plus /></el-icon>
                    <p>点击或拖拽图片到此处，单张最大支持2MB</p>
                    <p class="upload-hint">最多上传3张图片</p>
                  </div>
                </div>
              </div>
            </el-form-item>
            
            <!-- 操作按钮 -->
            <el-form-item>
              <el-button type="primary" size="large" @click="handleSubmit" :loading="submitting" class="submit-button">
                <el-icon><Check /></el-icon>
                封存胶囊
              </el-button>
            </el-form-item>
          </el-form>
        </div>
        
        <!-- 右侧预览和辅助信息区域 -->
        <div class="preview-section">
          <!-- 档案员建议 -->
          <el-card class="suggestion-card">
            <template #header>
              <div class="card-header">
                <el-icon><InfoFilled /></el-icon>
                <span>小提示</span>
              </div>
            </template>
            <ul class="suggestion-list">
              <li>写下一些具体的细节，比如今天的天气、你听的歌或是此时此刻的一个小领悟。</li>
              <li>设置一个具有仪式感的开启时间，比如你的下一个生日，或者三年后的今天。</li>
            </ul>
          </el-card>
          
          <!-- 胶囊预览 -->
          <el-card class="preview-card">
            <div class="preview-content">
              <!-- 顶部标题 -->
              <div class="preview-header">
                <el-icon class="eye-icon"><View /></el-icon>
                <h3>实时预览</h3>
              </div>
              
              <!-- 封面预览区域 -->
              <div class="cover-preview">
                <div class="cover-placeholder" v-if="form.coverImages.length === 0">
                  <el-icon class="cover-icon"><Picture /></el-icon>
                  <p>封面预览</p>
                </div>
                <img v-else :src="form.coverImages[0].url" alt="封面预览" class="cover-image">
              </div>
              
              <!-- 标题与内容区 -->
              <div class="content-section">
                <div class="title-container">
                  <el-icon class="star-icon"><Star /></el-icon>
                  <div class="preview-title">{{ form.title || '此处将显示你的标题' }}</div>
                  <div class="divider-line"></div>
                </div>
                <div class="content-box">
                  <div class="preview-description">{{ form.content ? (form.content.length > 100 ? form.content.substring(0, 100) + '......' : form.content) : '在这里预览你的记忆内容，胶囊一旦封存，在开启时间到来之前将无法再次查看。' }}</div>
                </div>
              </div>
              
              <!-- 底部信息栏 -->
              <div class="info-bar">
                <div class="info-item">
                  <el-icon class="info-icon"><Lock /></el-icon>
                  <span>封存状态：{{ form.privacy === 'private' ? '私密' : '公开' }}</span>
                </div>
                <div class="info-item">
                  <el-icon class="info-icon"><Calendar /></el-icon>
                  <span>{{ form.openDate ? formatDate(form.openDate) : '待定开启日期' }}</span>
                </div>
              </div>
              
              <!-- 底部蓝线 -->
              <div class="bottom-line"></div>
            </div>
          </el-card>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, reactive, onMounted, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage, ElMessageBox, ElInput, ElColorPicker } from 'element-plus'
import { Plus, Lock, Unlock, Check, InfoFilled, Link, Close, View, Picture, Star, Calendar } from '@element-plus/icons-vue'
import { capsuleAPI } from '@/api'

export default {
  name: 'CapsuleCreate',
  components: {
    Plus,
    Lock,
    Unlock,
    Check,
    InfoFilled,
    Link,
    Close,
    View,
    Picture,
    Star,
    Calendar,
    ElColorPicker
  },
  setup() {
    const router = useRouter()
    const formRef = ref(null)
    const fileInput = ref(null)
    const submitting = ref(false)
    
    const form = reactive({
      title: '',
      openDate: '',
      content: '',
      contentHtml: '',
      privacy: 'private',
      coverImages: []
    })
    
    // 同步contenteditable内容到form
    const updateContent = (event) => {
      const editor = event.target
      form.content = editor.textContent
      form.contentHtml = editor.innerHTML
      console.log('Content updated:', form.content)
    }
    
    // 监听富文本编辑器的输入事件，确保内容能够实时同步
    const editorRef = ref(null)
    onMounted(() => {
      const editor = document.querySelector('.editor-textarea[contenteditable="true"]')
      if (editor) {
        editor.addEventListener('input', updateContent)
        editor.addEventListener('blur', updateContent)
        // 阻止粘贴图片和清理文本格式
        editor.addEventListener('paste', (e) => {
          const clipboardData = e.clipboardData || window.clipboardData
          const items = clipboardData.items
          
          // 检查是否有图片
          for (let i = 0; i < items.length; i++) {
            if (items[i].type.indexOf('image') !== -1) {
              e.preventDefault()
              return
            }
          }
          
          // 清理文本格式，只保留纯文本
          e.preventDefault()
          const text = clipboardData.getData('text/plain')
          const selection = window.getSelection()
          if (selection && text) {
            if (selection.rangeCount > 0) {
              const range = selection.getRangeAt(0)
              range.deleteContents()
              range.insertNode(document.createTextNode(text))
              // 移动光标到文本后面
              range.setStartAfter(range.endContainer)
              range.collapse(true)
              selection.removeAllRanges()
              selection.addRange(range)
            }
          }
          // 同步内容
          form.content = editor.textContent
          form.contentHtml = editor.innerHTML
        })
        // 阻止拖放图片
        editor.addEventListener('dragover', (e) => {
          e.preventDefault()
        })
        editor.addEventListener('drop', (e) => {
          e.preventDefault()
        })
      }
    })
    
    onUnmounted(() => {
      const editor = document.querySelector('.editor-textarea[contenteditable="true"]')
      if (editor) {
        editor.removeEventListener('input', updateContent)
        editor.removeEventListener('blur', updateContent)
        // 移除事件监听器
        editor.removeEventListener('paste', () => {})
        editor.removeEventListener('dragover', () => {})
        editor.removeEventListener('drop', () => {})
      }
    })
    
    // 插入格式化文本
    const insertFormat = (command) => {
      const editor = document.querySelector('.editor-textarea[contenteditable="true"]')
      if (!editor) return
      
      // 聚焦编辑器
      editor.focus()
      
      // 使用document.execCommand实现富文本效果
      document.execCommand(command, false, null)
      
      // 同步内容
      form.content = editor.textContent
      form.contentHtml = editor.innerHTML
    }
    
    // 插入链接
    const insertLink = () => {
      ElMessageBox.prompt('请输入链接地址', '插入链接', {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        inputPlaceholder: 'https://example.com'
      }).then(({ value }) => {
        if (value) {
          const editor = document.querySelector('.editor-textarea[contenteditable="true"]')
          if (editor) {
            // 聚焦编辑器
            editor.focus()
            
            // 使用document.execCommand插入链接
            document.execCommand('createLink', false, value)
            
            // 同步内容
            form.content = editor.textContent
            form.contentHtml = editor.innerHTML
          }
        }
      }).catch(() => {})
    }
    
    // 插入表情
    const insertEmoji = () => {
      const emojis = ['😊', '🎉', '❤️', '🌟', '🤔', '😢', '✨', '👍']
      let emojiButtons = ''
      emojis.forEach(emoji => {
        emojiButtons += `<button type="button" style="margin: 5px; padding: 10px; border: 1px solid #ddd; border-radius: 4px; background: #f9f9f9; cursor: pointer;">${emoji}</button>`
      })
      
      ElMessageBox.alert(`<div style="display: flex; flex-wrap: wrap; justify-content: center;">${emojiButtons}</div>`, '选择表情', {
        dangerouslyUseHTMLString: true,
        confirmButtonText: '取消',
        showClose: false,
        beforeClose: (action, instance, done) => {
          if (action === 'confirm') {
            done()
          }
        }
      })
      
      // 绑定表情点击事件
      setTimeout(() => {
        const emojiBtns = document.querySelectorAll('.el-message-box__content button')
        emojiBtns.forEach(btn => {
          btn.addEventListener('click', () => {
            const emoji = btn.textContent
            const editor = document.querySelector('.editor-textarea[contenteditable="true"]')
            if (editor) {
              // 聚焦编辑器
              editor.focus()
              
              // 获取当前选区
              const selection = window.getSelection()
              if (selection) {
                // 创建表情文本节点
                const textNode = document.createTextNode(emoji)
                
                // 在光标位置插入表情
                if (selection.rangeCount > 0) {
                  const range = selection.getRangeAt(0)
                  range.deleteContents()
                  range.insertNode(textNode)
                  
                  // 移动光标到表情后面
                  range.setStartAfter(textNode)
                  range.collapse(true)
                  selection.removeAllRanges()
                  selection.addRange(range)
                }
                
                // 同步内容
                form.content = editor.textContent
                form.contentHtml = editor.innerHTML
              }
            }
          })
        })
      }, 100)
    }
    
    // 插入列表
    const insertList = (type) => {
      const editor = document.querySelector('.editor-textarea[contenteditable="true"]')
      if (!editor) return
      
      // 聚焦编辑器
      editor.focus()
      
      // 使用document.execCommand插入列表
      document.execCommand(type === 'ordered' ? 'insertOrderedList' : 'insertUnorderedList', false, null)
      
      // 同步内容
      form.content = editor.textContent
      form.contentHtml = editor.innerHTML
    }

    const rules = {
      title: [
        { required: true, message: '请输入标题', trigger: 'blur' },
        { min: 2, max: 50, message: '标题长度在 2 到 50 个字符', trigger: 'blur' }
      ],
      openDate: [
        { required: true, message: '请选择开启时间', trigger: 'change' }
      ],
      content: [
        { required: true, message: '请输入内容', trigger: 'input' },
        { min: 8, max: 400, message: '内容长度在 8 到 400 个字符', trigger: 'input' }
      ]
    }

    // 禁用今天及过去的日期
    const disabledDate = (time) => {
      // 获取今天的日期，将时间设置为00:00:00
      const today = new Date()
      today.setHours(0, 0, 0, 0)
      
      // 明天的日期
      const tomorrow = new Date(today)
      tomorrow.setDate(tomorrow.getDate() + 1)
      
      // 禁止选择今天及今天之前的日期
      return time.getTime() < tomorrow.getTime()
    }

    // 格式化日期
    const formatDate = (dateString) => {
      if (!dateString) return ''
      const date = new Date(dateString)
      return date.toLocaleString('zh-CN', {
        year: 'numeric',
        month: '2-digit',
        day: '2-digit'
      })
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
        Array.from(files).forEach(file => {
          if (form.coverImages.length < 3) {
            handleFileUpload(file)
          }
        })
      }
      // 重置文件输入框的值，确保被删除的图片可以再次添加
      if (event.target) {
        event.target.value = ''
      }
    }

    // 处理文件拖拽
    const handleDrop = (event) => {
      const files = event.dataTransfer.files
      if (files.length > 0) {
        Array.from(files).forEach(file => {
          if (form.coverImages.length < 3) {
            handleFileUpload(file)
          }
        })
      }
    }

    // 删除图片
    const deleteImage = (index) => {
      form.coverImages.splice(index, 1)
    }

    // 处理文件上传
    const handleFileUpload = (file) => {
      // 检查文件类型
      if (!file.type.startsWith('image/')) {
        ElMessage.error('请上传图片文件')
        return
      }

      // 检查单张图片大小 (2MB)
      if (file.size / 1024 / 1024 > 2) {
        ElMessage.error('上传失败，单张图片大小不能超过 2MB，请重新选择')
        return
      }

      // 检查上传数量
      if (form.coverImages.length >= 3) {
        ElMessage.error('最多只能上传3张图片')
        return
      }

      // 只做本地预览，不调用上传接口
      const reader = new FileReader()
      reader.onload = (e) => {
        form.coverImages.push({
          url: e.target.result,
          file: file
        })
      }
      reader.readAsDataURL(file)
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
              // 创建FormData对象
              const formData = new FormData();
              
              // 添加胶囊数据
              formData.append('title', form.title);
              formData.append('content', form.content);
              formData.append('contentHtml', form.contentHtml);
              // 发送只包含日期部分的字符串
              formData.append('openDate', form.openDate);
              formData.append('privacy', form.privacy.toUpperCase());
              
              // 添加图片文件
              console.log('Uploading images:', form.coverImages);
              form.coverImages.forEach((image, index) => {
                if (image.file) {
                  console.log('Adding image to FormData:', image.file);
                  formData.append(`coverImages`, image.file, `image_${index}_${Date.now()}.png`);
                }
              });
              
              // 检查FormData内容
              console.log('FormData entries:', Array.from(formData.entries()));
              
              // 提交表单数据和图片
              capsuleAPI.createCapsule(formData).then(response => {
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
              const today = new Date();
              const dateStr = `${today.getFullYear()}-${String(today.getMonth() + 1).padStart(2, '0')}-${String(today.getDate()).padStart(2, '0')}`;
              
              // 准备胶囊数据，只存储图片的url部分
              const capsuleData = {
                id: Date.now(),
                ...form,
                coverImages: form.coverImages.map(image => image.url), // 只存储url
                date: dateStr,
                openDate: form.openDate // 只存储日期部分
              };
              
              capsules.push(capsuleData);
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

    return {
      formRef,
      fileInput,
      form,
      rules,
      submitting,
      disabledDate,
      formatDate,
      insertFormat,
      insertLink,
      insertEmoji,
      insertList,
      triggerFileInput,
      handleFileChange,
      handleDrop,
      deleteImage,
      handleSubmit
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
  background: linear-gradient(135deg, #f8f9ff 0%, #eef2ff 100%);
  position: relative;
}

.container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 40px 20px;
}

.header {
  margin-bottom: 40px;
}

h1 {
  color: #333;
  font-size: 32px;
  font-weight: 700;
  margin-bottom: 12px;
  font-family: 'PingFang SC', 'Microsoft YaHei', sans-serif;
}

.header p {
  color: #666;
  font-size: 16px;
  margin: 0;
  font-family: 'PingFang SC', 'Microsoft YaHei', sans-serif;
}

.content {
  display: flex;
  gap: 40px;
  align-items: flex-start;
}

.form-section {
  flex: 1;
  background: white;
  border-radius: 16px;
  box-shadow: 0 8px 32px rgba(92, 142, 255, 0.15);
  padding: 36px;
}

.preview-section {
  width: 350px;
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.create-form {
  width: 100%;
}

/* 表单标签 */
.form-label {
  font-size: 16px;
  font-weight: 600;
  color: #333;
  margin-bottom: 12px;
  font-family: 'PingFang SC', 'Microsoft YaHei', sans-serif;
}

/* 表单项样式 */
:deep(.el-form-item) {
  margin-bottom: 28px;
}

/* 其他文本框样式 */
:deep(.el-input__wrapper) {
  border-radius: 12px;
  border: 1px solid #e8e8e8;
  background-color: #fff;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.05);
  transition: all 0.3s ease;
}

:deep(.el-input__wrapper:hover) {
  border-color: #409EFF;
  box-shadow: 0 4px 16px rgba(92, 142, 255, 0.15);
}

:deep(.el-input__wrapper.is-focus) {
  border-color: #409EFF;
  box-shadow: 0 0 0 3px rgba(64, 158, 255, 0.2);
}

:deep(.el-input__inner) {
  font-size: 16px;
  color: #333;
  font-family: 'PingFang SC', 'Microsoft YaHei', sans-serif;
  line-height: 1.5;
}

:deep(.el-input__inner::placeholder) {
  color: #999;
  font-size: 16px;
  font-family: 'PingFang SC', 'Microsoft YaHei', sans-serif;
}

/* 日期选择器样式 */
:deep(.el-date-editor .el-input__wrapper) {
  border-radius: 12px;
  border: 1px solid #e8e8e8;
  background-color: #fff;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.05);
  transition: all 0.3s ease;
}

:deep(.el-date-editor .el-input__wrapper:hover) {
  border-color: #409EFF;
  box-shadow: 0 4px 16px rgba(92, 142, 255, 0.15);
}

:deep(.el-date-editor .el-input__wrapper.is-focus) {
  border-color: #409EFF;
  box-shadow: 0 0 0 3px rgba(64, 158, 255, 0.2);
}

/* 表单行 */
.form-row {
  display: flex;
  gap: 24px;
  align-items: flex-start;
}

.form-item-half {
  flex: 1;
}

/* 隐私设置按钮 */
.privacy-buttons {
  display: flex;
  gap: 12px;
  width: 100%;
}

.privacy-button {
  flex: 1;
  border-radius: 12px;
  font-size: 16px;
  padding: 12px 0;
  transition: all 0.3s ease;
  font-weight: 500;
  font-family: 'PingFang SC', 'Microsoft YaHei', sans-serif;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.05);
}

.privacy-button:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 16px rgba(92, 142, 255, 0.2);
}

.privacy-button-active {
  box-shadow: 0 4px 16px rgba(92, 142, 255, 0.3);
  transform: translateY(-1px);
}

/* 编辑器容器 */
.editor-container {
  position: relative;
  border-radius: 12px;
  overflow: hidden !important;
  min-height: 200px;
  background-color: #f5f5f5;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.05);
  width: 100% !important;
  max-width: 100% !important;
  box-sizing: border-box !important;
}

/* 编辑器文本域 */
.editor-textarea {
  background-color: #f5f5f5;
  border: none;
  border-radius: 12px;
  resize: none;
  padding: 20px 20px 50px 20px;
  font-size: 16px;
  line-height: 1.6;
  min-height: 200px;
  width: 100% !important;
  max-width: 100% !important;
  color: #333;
  font-family: 'PingFang SC', 'Microsoft YaHei', sans-serif;
  outline: none;
  white-space: pre-wrap !important;
  word-wrap: break-word;
  overflow-wrap: break-word;
  word-break: break-all !important;
  box-sizing: border-box !important;
  display: block;
  overflow-y: auto !important;
  overflow-x: hidden !important;
}

/* 隐形滚动条 */
.editor-textarea::-webkit-scrollbar {
  width: 6px;
}

.editor-textarea::-webkit-scrollbar-track {
  background: transparent;
}

.editor-textarea::-webkit-scrollbar-thumb {
  background: rgba(0, 0, 0, 0.1);
  border-radius: 3px;
}

.editor-textarea::-webkit-scrollbar-thumb:hover {
  background: rgba(0, 0, 0, 0.2);
}

.editor-textarea[contenteditable="true"]:empty::before {
  content: attr(placeholder);
  color: #999;
  pointer-events: none;
}

.editor-textarea:focus {
  box-shadow: none !important;
  outline: none !important;
}

.privacy-button {
  flex: 1;
  border-radius: 12px;
  font-size: 14px;
  padding: 10px 0;
  transition: all 0.3s ease;
  font-weight: 500;
}

.privacy-button:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(92, 142, 255, 0.2);
}

.privacy-button-active {
  box-shadow: 0 2px 8px rgba(92, 142, 255, 0.3);
}

/* 提交按钮 */
.submit-button {
  width: 100%;
  padding: 16px 0;
  font-size: 18px;
  font-weight: 600;
  border-radius: 12px;
  transition: all 0.3s ease;
  font-family: 'PingFang SC', 'Microsoft YaHei', sans-serif;
  box-shadow: 0 4px 16px rgba(92, 142, 255, 0.2);
}

.submit-button:hover {
  transform: translateY(-2px);
  box-shadow: 0 8px 24px rgba(92, 142, 255, 0.3);
}

/* 富文本编辑器 */
.editor-wrapper {
  border: 1px solid #e8e8e8;
  border-radius: 8px;
  overflow: hidden;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.05);
}

:deep(.w-e-toolbar) {
  border-bottom: 1px solid #e8e8e8;
  background-color: #f9f9f9;
  border-radius: 8px 8px 0 0;
}

:deep(.w-e-text-container) {
  border-radius: 0 0 8px 8px;
}

:deep(.w-e-toolbar .w-e-menu) {
  margin: 0 4px;
}

:deep(.w-e-toolbar .w-e-menu:hover) {
  background-color: #e6f7ff;
}

:deep(.w-e-text-container .w-e-scroll) {
  padding: 16px;
  font-size: 14px;
  line-height: 1.6;
}



/* 编辑器工具栏 */
.editor-toolbar {
  position: absolute;
  bottom: 16px;
  left: 20px;
  display: flex;
  gap: 24px;
  padding: 0;
  background-color: transparent;
  z-index: 10;
  pointer-events: auto;
  width: calc(100% - 40px) !important;
  max-width: calc(100% - 40px) !important;
  box-sizing: border-box !important;
  overflow-x: hidden !important;
}

.editor-toolbar :deep(.el-button) {
  padding: 4px 8px;
  font-size: 16px;
  min-width: auto;
  height: auto;
  color: #999;
  background: transparent;
  border: none;
  box-shadow: none;
  font-family: 'PingFang SC', 'Microsoft YaHei', sans-serif;
  transition: all 0.3s ease;
}

.editor-toolbar :deep(.el-button:hover) {
  color: #409EFF;
  background: transparent;
  border: none;
  box-shadow: none;
  transform: translateY(-1px);
}

/* 上传图片标题 */
.upload-title {
  font-size: 16px;
  font-weight: 600;
  color: #333;
  margin-bottom: 16px;
  font-family: 'PingFang SC', 'Microsoft YaHei', sans-serif;
}

/* 上传容器 */
.upload-container {
  width: 100%;
}

/* 上传区域 */
.upload-area {
  border: 2px dashed #d9d9d9;
  border-radius: 12px;
  padding: 48px 24px;
  text-align: center;
  cursor: pointer;
  transition: all 0.3s ease;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.05);
  min-height: 200px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.upload-area:hover {
  border-color: #409EFF;
  background-color: #f0f9ff;
  box-shadow: 0 4px 16px rgba(92, 142, 255, 0.15);
}

.upload-icon {
  font-size: 32px;
  color: #999;
  margin-bottom: 16px;
  transition: all 0.3s ease;
}

.upload-area:hover .upload-icon {
  color: #409EFF;
  transform: scale(1.1);
}

.upload-area p {
  margin: 0;
  color: #999;
  font-size: 16px;
  font-family: 'PingFang SC', 'Microsoft YaHei', sans-serif;
  line-height: 1.5;
}

.upload-hint {
  font-size: 14px !important;
  margin-top: 8px !important;
  color: #666 !important;
}

/* 上传占位符 */
.upload-placeholder {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  width: 100%;
}

.upload-placeholder.small {
  width: 100%;
  height: 120px;
  border: 2px dashed #d9d9d9;
  border-radius: 8px;
  transition: all 0.3s ease;
}

.upload-placeholder.small:hover {
  border-color: #409EFF;
  background-color: #f0f9ff;
}

.upload-placeholder.small .upload-icon {
  font-size: 24px;
  margin-bottom: 8px;
}

.upload-placeholder.small p {
  font-size: 14px;
}

/* 上传预览 */
.upload-preview {
  position: relative;
  width: 100%;
  padding: 20px;
}

/* 图片网格 */
.image-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(120px, 1fr));
  gap: 16px;
  width: 100%;
}

/* 图片项 */
.image-item {
  position: relative;
  width: 100%;
  aspect-ratio: 1;
  border-radius: 8px;
  overflow: hidden;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
  transition: all 0.3s ease;
}

.image-item:hover {
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.2);
  transform: translateY(-2px);
}

.preview-image {
  width: 100%;
  height: 100%;
  object-fit: cover;
  border-radius: 8px;
  transition: all 0.3s ease;
}

/* 删除按钮 */
.delete-button {
  position: absolute;
  top: 8px;
  right: 8px;
  background-color: rgba(255, 255, 255, 0.9);
  border-radius: 50%;
  width: 28px;
  height: 28px;
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
  transition: all 0.3s ease;
  opacity: 0;
  visibility: hidden;
  z-index: 10;
}

.image-item:hover .delete-button {
  opacity: 1;
  visibility: visible;
}

.delete-button:hover {
  background-color: #ff4d4f;
  color: white;
  transform: scale(1.1);
  box-shadow: 0 4px 12px rgba(255, 77, 79, 0.4);
}

/* 提交按钮 */
.submit-button {
  width: 100%;
  padding: 14px 0;
  font-size: 16px;
  font-weight: 600;
  border-radius: 8px;
}

/* 档案员建议卡片 */
.suggestion-card {
  border-radius: 12px;
  box-shadow: 0 4px 16px rgba(92, 142, 255, 0.1);
  border: none;
}

.card-header {
  display: flex;
  align-items: center;
  gap: 8px;
  font-weight: 600;
  font-size: 14px;
  color: #333;
}

.suggestion-list {
  padding-left: 20px;
  margin: 16px 0 0 0;
}

.suggestion-list li {
  color: #666;
  font-size: 14px;
  line-height: 1.6;
  margin-bottom: 10px;
}

/* 胶囊预览卡片 */
.preview-card {
  border-radius: 16px;
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.08);
  border: 1px solid #e8e8e8;
  overflow: hidden;
  background: white;
}

.preview-content {
  padding: 24px;
  min-height: auto;
}

.preview-header {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 20px;
}

.eye-icon {
  font-size: 18px;
  color: #409EFF;
}

.preview-header h3 {
  margin: 0;
  font-size: 16px;
  font-weight: 600;
  color: #333;
}

.cover-preview {
  width: 100%;
  height: 160px;
  background: #f5f5f5;
  border-radius: 12px;
  margin-bottom: 20px;
  display: flex;
  align-items: center;
  justify-content: center;
  overflow: hidden;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.06);
}

.cover-placeholder {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 8px;
  color: #999;
}

.cover-icon {
  font-size: 32px;
  color: #ccc;
}

.cover-placeholder p {
  margin: 0;
  font-size: 14px;
  color: #999;
}

.cover-image {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.content-section {
  margin-bottom: 20px;
}

.title-container {
  display: flex;
  flex-direction: column;
  align-items: center;
  margin-bottom: 16px;
}

.star-icon {
  font-size: 16px;
  color: #FFD700;
  margin-bottom: 8px;
}

.preview-title {
  font-size: 16px;
  font-weight: 600;
  color: #333;
  margin-bottom: 12px;
  text-align: center;
}

.divider-line {
  width: 60px;
  height: 2px;
  background: #409EFF;
  border-radius: 1px;
}

.content-box {
  background: #f9f9f9;
  border: 2px dashed #e0e0e0;
  border-radius: 8px;
  padding: 16px;
  min-height: 80px;
}

.preview-description {
  font-size: 14px;
  line-height: 1.6;
  color: #666;
  text-align: left;
  word-break: break-word;
}

.info-bar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;
  padding: 12px;
  background: #f5f5f5;
  border-radius: 8px;
}

.info-item {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 13px;
  color: #666;
}

.info-icon {
  font-size: 14px;
  color: #409EFF;
}

.bottom-line {
  width: 100%;
  height: 3px;
  background: linear-gradient(90deg, #409EFF 0%, #66b1ff 100%);
  border-radius: 0 0 16px 16px;
}

/* 响应式布局 */
@media (max-width: 768px) {
  .content {
    flex-direction: column;
  }
  
  .preview-section {
    width: 100%;
  }
  
  .form-row {
    flex-direction: column;
    align-items: stretch;
  }
  
  .form-item-half {
    width: 100%;
  }
  
  .container {
    padding: 20px 16px;
  }
  
  .form-section {
    padding: 20px;
  }
  
  h1 {
    font-size: 24px;
  }
}

/* 全屏加载覆盖层 */
.loading-overlay {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background-color: rgba(255, 255, 255, 0.9);
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 9999;
}

.loading-content {
  text-align: center;
  color: #409EFF;
}

.loading-spinner {
  width: 50px;
  height: 50px;
  border: 5px solid #f3f3f3;
  border-top: 5px solid #409EFF;
  border-radius: 50%;
  animation: spin 1s linear infinite;
  margin: 0 auto 20px;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}
</style>