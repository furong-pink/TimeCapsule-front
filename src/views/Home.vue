<!-- src/views/Home.vue -->
<template>
  <div class="home-page">
    <!-- 用户信息卡片 -->
    <el-card class="user-card">
      <div class="user-info">
        <div class="avatar-section">
          <el-avatar :size="80" :src="userInfo.avatar" shape="circle">
            <el-icon>
              <User />
            </el-icon>
          </el-avatar>
        </div>
        <div class="user-details">
          <h2 class="nickname">{{ userInfo.nickname || '时光旅行者' }}</h2>
          <p class="bio">{{ userInfo.bio || '记录生活点滴，遇见更好的自己' }}</p>
          <div class="user-stats">
            <div class="stat-item">
              <span class="stat-value">{{ capsules.length }}</span>
              <span class="stat-label">时间胶囊</span>
            </div>
            <div class="stat-item">
              <span class="stat-value">{{ completedGoals }}</span>
              <span class="stat-label">完成目标</span>
            </div>
            <div class="stat-item">
              <span class="stat-value">{{ achievements }}</span>
              <span class="stat-label">获得成就</span>
            </div>
          </div>
        </div>
        <el-button type="primary" plain @click="showEditDialog = true">
          <el-icon>
            <Edit />
          </el-icon>
          编辑资料
        </el-button>
      </div>
    </el-card>

    <!-- 今日目标进度 -->
    <el-card class="goal-progress-card">
      <template #header>
        <div class="card-header">
          <span>📝 今日目标</span>
          <el-tag type="success" v-if="todayGoalProgress >= 100">已完成</el-tag>
        </div>
      </template>
      <div class="progress-content">
        <p class="goal-text">完成 1 封时间胶囊</p>
        <el-progress :percentage="todayGoalProgress" :status="todayGoalProgress >= 100 ? 'success' : ''"
          :stroke-width="12" />
        <p class="progress-text">{{ todayGoalProgress }}% 完成</p>
      </div>
    </el-card>

    <!-- 最近的时间胶囊 -->
    <div class="section-header">
      <h3>📅 最近的时间胶囊</h3>
      <el-button type="text" @click="$router.push('/timeline')">查看全部</el-button>
    </div>

    <div v-if="loading" class="loading">
      <el-icon class="is-loading">
        <Loading />
      </el-icon>
      <span>正在加载...</span>
    </div>

    <div v-else-if="!capsules || capsules.length === 0" class="empty-capsules">
      <el-empty description="还没有时间胶囊，快去创建一个吧！">
        <el-button type="primary" @click="$router.push('/capsule/create')">创建胶囊</el-button>
      </el-empty>
    </div>

    <div v-else class="capsules-grid">
      <el-card v-for="capsule in recentCapsules" :key="capsule.id" class="capsule-card" shadow="hover"
        @click="viewCapsule(capsule)">
        <div class="capsule-cover" :style="{ backgroundImage: `url(${capsule.cover || '/default-cover.svg'})` }">
          <div class="capsule-overlay">
            <el-tag :type="getTagType(capsule.privacy)" size="small">
              {{ getTagText(capsule.privacy) }}
            </el-tag>
          </div>
        </div>
        <div class="capsule-content">
          <h4 class="capsule-title">{{ capsule.title }}</h4>
          <p class="capsule-date">{{ formatDate(capsule.date) }}</p>
          <p class="capsule-preview">{{ capsule.preview || capsule.content?.substring(0, 50) + '...' }}</p>
        </div>
      </el-card>
    </div>

    <!-- 编辑资料对话框（包含头像更换） -->
    <el-dialog v-model="showEditDialog" title="编辑资料" width="500px">
      <el-form :model="editForm" label-width="80px">
        <el-form-item label="头像">
          <div class="avatar-upload">
            <el-upload class="avatar-uploader" action="#" :show-file-list="false" :before-upload="handleAvatarUpload">
              <el-avatar v-if="userInfo.avatar" :src="userInfo.avatar" :size="80" shape="circle" />
              <el-icon v-else class="avatar-uploader-icon">
                <Plus />
              </el-icon>
            </el-upload>
            <p style="text-align: center; margin-top: 10px; color: #999;">点击头像上传新图片</p>
          </div>
        </el-form-item>
        <el-form-item label="昵称">
          <el-input v-model="editForm.nickname" placeholder="请输入昵称" />
        </el-form-item>
        <el-form-item label="个人简介">
          <el-input v-model="editForm.bio" type="textarea" :rows="4" placeholder="介绍一下自己吧..." maxlength="100"
            show-word-limit />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="showEditDialog = false">取消</el-button>
        <el-button type="primary" @click="saveProfile">保存</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script>
import { User, Camera, Edit, Loading, Plus } from '@element-plus/icons-vue'
import { ElMessage } from 'element-plus'

export default {
  name: 'Home',
  components: {
    User,
    Camera,
    Edit,
    Loading,
    Plus
  },
  data() {
    return {
      loading: false,
      capsules: [],
      showEditDialog: false,
      userInfo: {
        nickname: '时光旅行者',
        bio: '记录生活点滴，遇见更好的自己',
        avatar: ''
      },
      editForm: {
        nickname: '',
        bio: ''
      },
      completedGoals: 2,
      achievements: 3
    }
  },
  computed: {
    recentCapsules() {
      // 返回最近6个胶囊
      return this.capsules.slice(0, 6).map(capsule => ({
        ...capsule,
        cover: capsule.coverImage || capsule.cover || '',
        preview: capsule.content?.substring(0, 50) || ''
      }))
    },
    todayGoalProgress() {
      // 计算今日目标完成进度（示例：如果有今日创建的胶囊则100%）
      const today = new Date().toISOString().split('T')[0]
      const todayCapsules = this.capsules.filter(c => {
        // 检查多种可能的日期字段
        const capsuleDate = c.date || c.createdAt || c.created_at || c.openDate || c.open_date;
        if (!capsuleDate) return false;
        // 提取日期部分进行比较
        const dateStr = new Date(capsuleDate).toISOString().split('T')[0];
        return dateStr === today;
      });
      return todayCapsules.length > 0 ? 100 : 0
    }
  },
  async mounted() {
    console.log('Home组件挂载');
    await this.loadUserInfo()
    this.fetchData()
    
    // 监听localStorage变化，用于接收胶囊创建通知
    window.addEventListener('storage', this.handleStorageChange);
  },
  
  beforeUnmount() {
    // 移除事件监听
    window.removeEventListener('storage', this.handleStorageChange);
  },
  
  methods: {
    handleStorageChange(e) {
      if (e.key === 'capsuleCreated' && e.newValue) {
        // 当检测到胶囊创建事件时，重新获取数据
        this.fetchData();
      }
    },
    
    isPublic(privacy) {
      // 检查隐私设置是否为公开
      if (!privacy) return false;
      return privacy.toUpperCase() === 'PUBLIC';
    },
    getTagType(privacy) {
      console.log('getTagType被调用，privacy值:', privacy);
      const isPublic = privacy && privacy.toString().toUpperCase() === 'PUBLIC';
      return isPublic ? 'success' : 'info';
    },
    getTagText(privacy) {
      console.log('getTagText被调用，privacy值:', privacy);
      const isPublic = privacy && privacy.toString().toUpperCase() === 'PUBLIC';
      return isPublic ? '公开' : '私密';
    },
    async loadUserInfo() {
      // 优先从服务器获取最新的用户信息
      if (window.$axios) {
        try {
          const response = await window.$axios.get('/users/profile');
          if (response?.code === 200 && response?.data) {
            const userData = response.data;
            this.userInfo = {
              nickname: userData.nickname || '时光旅行者',
              bio: userData.bio || '记录生活点滴，遇见更好的自己',
              avatar: userData.avatar || ''
            };
            this.editForm = {
              nickname: this.userInfo.nickname,
              bio: this.userInfo.bio
            };
            // 更新本地存储
            localStorage.setItem('user', JSON.stringify({
              nickname: userData.nickname,
              bio: userData.bio,
              avatar: userData.avatar
            }));
          } else {
            // 如果服务器获取失败，从本地存储加载
            const savedUser = localStorage.getItem('user');
            if (savedUser) {
              const user = JSON.parse(savedUser);
              this.userInfo = { ...this.userInfo, ...user };
              this.editForm = {
                nickname: this.userInfo.nickname,
                bio: this.userInfo.bio
              };
            }
          }
        } catch (e) {
          // 如果服务器获取失败，从本地存储加载
          const savedUser = localStorage.getItem('user');
          if (savedUser) {
            try {
              const user = JSON.parse(savedUser);
              this.userInfo = { ...this.userInfo, ...user };
              this.editForm = {
                nickname: this.userInfo.nickname,
                bio: this.userInfo.bio
              };
            } catch (parseError) {
              console.error('加载用户信息失败', parseError);
            }
          }
        }
      } else {
        // 如果没有axios，从本地存储加载
        const savedUser = localStorage.getItem('user');
        if (savedUser) {
          try {
            const user = JSON.parse(savedUser);
            this.userInfo = { ...this.userInfo, ...user };
            this.editForm = {
              nickname: this.userInfo.nickname,
              bio: this.userInfo.bio
            };
          } catch (e) {
            console.error('加载用户信息失败', e);
          }
        }
      }
    },
    async fetchData() {
      try {
        this.loading = true
        // 使用真实API调用
        if (this.$axios) {
          // 获取首页统计数据
          const statsResponse = await this.$axios.get('/statistics/home');
          if (statsResponse?.data?.recentCapsules) {
            this.capsules = statsResponse.data.recentCapsules;
            console.log('使用statistics/home API数据:', statsResponse.data.recentCapsules);
          } else {
            // 如果API调用失败，获取时间胶囊列表
            const capsulesResponse = await this.$axios.get('/capsules');
            if (capsulesResponse?.data?.content) {
              this.capsules = capsulesResponse.data.content;
              console.log('使用capsules API数据:', capsulesResponse.data.content);
            } else {
              this.capsules = [];
            }
          }
        } else {
          // 如果没有axios，使用fetch
          const response = await fetch('/api/capsules.json')
          const data = await response.json()
          this.capsules = data || []
        }
        console.log('API返回的胶囊数据:', this.capsules);
        this.loading = false
      } catch (error) {
        console.error('加载失败:', error)
        // 不使用模拟数据，保持空数组
        this.capsules = []
        this.loading = false
        console.log('API加载失败，capsules设置为空数组')
      }
    },
    formatDate(date) {
      if (!date) return ''
      const d = new Date(date)
      return `${d.getFullYear()}年${d.getMonth() + 1}月${d.getDate()}日`
    },
    viewCapsule(capsule) {
      // 跳转到胶囊详情或时间轴
      this.$router.push(`/timeline`)
    },
    async saveProfile() {
      try {
        if (this.$axios) {
          // 使用API更新用户信息
          const updateData = {
            nickname: this.editForm.nickname,
            bio: this.editForm.bio,
            avatar: this.userInfo.avatar
          };

          const response = await this.$axios.put('/users/profile', updateData);

          if (response?.code === 200) {
            // 更新本地存储
            this.userInfo.nickname = this.editForm.nickname
            this.userInfo.bio = this.editForm.bio
            localStorage.setItem('user', JSON.stringify(this.userInfo));
            ElMessage.success('资料保存成功');
          } else {
            ElMessage.error(response?.message || '更新失败');
          }
        } else {
          // 如果没有API，使用本地存储
          this.userInfo.nickname = this.editForm.nickname
          this.userInfo.bio = this.editForm.bio
          // 保存到本地存储
          localStorage.setItem('user', JSON.stringify(this.userInfo));
          ElMessage.success('资料保存成功');
        }
      } catch (error) {
        console.error('更新用户信息失败:', error);
        ElMessage.error('更新失败: ' + (error.response?.data?.message || error.message));
      } finally {
        this.showEditDialog = false;
      }
    },
    async handleAvatarUpload(file) {
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
        
        const response = await this.$axios.post('/upload', formData, {
          headers: {
            'Content-Type': 'multipart/form-data'
          }
        })
        
        if (response?.code === 200) {
          // 上传成功，更新头像URL
          this.userInfo.avatar = response.data.fileUrl
          
          // 更新本地存储
          localStorage.setItem('user', JSON.stringify(this.userInfo))
          
          // 同时更新编辑表单
          this.editForm.avatar = response.data.fileUrl
          
          // 触发全局用户信息更新
          const event = new CustomEvent('user-login', { detail: this.userInfo });
          window.dispatchEvent(event);
          
          ElMessage.success('头像上传成功')
        } else {
          ElMessage.error(response?.message || '头像上传失败')
          return false
        }
      } catch (error) {
        console.error('头像上传失败:', error)
        ElMessage.error('头像上传失败: ' + (error.response?.data?.message || error.message))
        return false
      }
      
      return false // 阻止自动上传
    }
  }
}
</script>

<style scoped>
.home-page {
  padding: 0;
  margin: 0;
  width: 100%;
  min-height: calc(100vh - 120px);
}

/* 用户信息卡片 */
.user-card {
  margin-bottom: 20px;
}

.user-info {
  display: flex;
  align-items: flex-start;
  gap: 20px;
}

.avatar-section {
  position: relative;
}

.avatar-section :deep(.el-avatar) {
  border-radius: 50% !important;
  overflow: hidden;
}

.edit-avatar-btn {
  position: absolute;
  bottom: 0;
  right: 0;
  background: white;
  border-radius: 50%;
  padding: 4px;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}

.user-details {
  flex: 1;
}

.nickname {
  font-size: 24px;
  font-weight: 600;
  color: #333;
  margin: 0 0 8px 0;
}

.bio {
  color: #666;
  font-size: 14px;
  margin: 0 0 16px 0;
}

.user-stats {
  display: flex;
  gap: 30px;
}

.stat-item {
  display: flex;
  flex-direction: column;
}

.stat-value {
  font-size: 20px;
  font-weight: 600;
  color: #409EFF;
}

.stat-label {
  font-size: 12px;
  color: #999;
  margin-top: 4px;
}

/* 今日目标进度卡片 */
.goal-progress-card {
  margin-bottom: 30px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.progress-content {
  padding: 10px 0;
}

.goal-text {
  font-size: 16px;
  color: #333;
  margin-bottom: 15px;
}

.progress-text {
  text-align: right;
  color: #999;
  font-size: 12px;
  margin-top: 8px;
}

/* 章节标题 */
.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
}

.section-header h3 {
  font-size: 20px;
  font-weight: 600;
  color: #333;
  margin: 0;
}

/* 加载和空状态 */
.loading {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 60px 20px;
  color: #999;
  gap: 10px;
}

.empty-capsules {
  padding: 40px 20px;
}

/* 胶囊网格 */
.capsules-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
  gap: 20px;
}

.capsule-card {
  cursor: pointer;
  transition: transform 0.3s ease;
  overflow: hidden;
}

.capsule-card:hover {
  transform: translateY(-5px);
}

.capsule-cover {
  width: 100%;
  height: 180px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  background-size: cover;
  background-position: center;
  position: relative;
  display: flex;
  align-items: flex-start;
  justify-content: flex-end;
  padding: 10px;
}

.capsule-overlay {
  display: flex;
  gap: 8px;
}

.capsule-content {
  padding: 16px;
}

.capsule-title {
  font-size: 16px;
  font-weight: 600;
  color: #333;
  margin: 0 0 8px 0;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.capsule-date {
  font-size: 12px;
  color: #999;
  margin: 0 0 8px 0;
}

.capsule-preview {
  font-size: 14px;
  color: #666;
  margin: 0;
  line-height: 1.5;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

/* 头像上传 */
.avatar-upload {
  display: flex;
  flex-direction: column;
  align-items: center;
}

.avatar-uploader {
  border: 2px dashed #d9d9d9;
  border-radius: 50%;
  cursor: pointer;
  position: relative;
  overflow: hidden;
  transition: all 0.3s;
  width: 80px;
  height: 80px;
}

.avatar-uploader:hover {
  border-color: #409EFF;
}

.avatar-uploader-icon {
  font-size: 28px;
  color: #8c939d;
  width: 80px;
  height: 80px;
  display: flex;
  align-items: center;
  justify-content: center;
}
</style>