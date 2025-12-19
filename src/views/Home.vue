<!-- src/views/Home.vue -->
<template>
  <div class="home-page">
    <!-- 用户信息卡片 -->
    <el-card class="user-card">
      <div class="user-info">
        <div class="avatar-section">
          <el-avatar :size="80" :src="userInfo.avatar" shape="circle">
            <el-icon><User /></el-icon>
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
          <el-icon><Edit /></el-icon>
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
        <el-progress 
          :percentage="todayGoalProgress" 
          :status="todayGoalProgress >= 100 ? 'success' : ''"
          :stroke-width="12"
        />
        <p class="progress-text">{{ todayGoalProgress }}% 完成</p>
      </div>
    </el-card>

    <!-- 最近的时间胶囊 -->
    <div class="section-header">
      <h3>📅 最近的时间胶囊</h3>
      <el-button type="text" @click="$router.push('/timeline')">查看全部</el-button>
    </div>

    <div v-if="loading" class="loading">
      <el-icon class="is-loading"><Loading /></el-icon>
      <span>正在加载...</span>
    </div>

    <div v-else-if="!capsules || capsules.length === 0" class="empty-capsules">
      <el-empty description="还没有时间胶囊，快去创建一个吧！">
        <el-button type="primary" @click="$router.push('/capsule/create')">创建胶囊</el-button>
      </el-empty>
    </div>

    <div v-else class="capsules-grid">
      <el-card 
        v-for="capsule in recentCapsules" 
        :key="capsule.id"
        class="capsule-card"
        shadow="hover"
        @click="viewCapsule(capsule)"
      >
        <div class="capsule-cover" :style="{ backgroundImage: `url(${capsule.cover || '/default-cover.jpg'})` }">
          <div class="capsule-overlay">
            <el-tag :type="capsule.privacy === 'public' ? 'success' : 'info'" size="small">
              {{ capsule.privacy === 'public' ? '公开' : '私密' }}
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
            <el-upload
              class="avatar-uploader"
              action="#"
              :show-file-list="false"
              :before-upload="handleAvatarUpload"
            >
              <el-avatar v-if="userInfo.avatar" :src="userInfo.avatar" :size="80" shape="circle" />
              <el-icon v-else class="avatar-uploader-icon"><Plus /></el-icon>
            </el-upload>
            <p style="text-align: center; margin-top: 10px; color: #999;">点击头像上传新图片</p>
          </div>
        </el-form-item>
        <el-form-item label="昵称">
          <el-input v-model="editForm.nickname" placeholder="请输入昵称" />
        </el-form-item>
        <el-form-item label="个人简介">
          <el-input 
            v-model="editForm.bio" 
            type="textarea" 
            :rows="4"
            placeholder="介绍一下自己吧..."
            maxlength="100"
            show-word-limit
          />
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
        cover: capsule.cover || '',
        preview: capsule.content?.substring(0, 50) || ''
      }))
    },
    todayGoalProgress() {
      // 计算今日目标完成进度（示例：如果有今日创建的胶囊则100%）
      const today = new Date().toISOString().split('T')[0]
      const todayCapsules = this.capsules.filter(c => c.date === today)
      return todayCapsules.length > 0 ? 100 : 0
    }
  },
  mounted() {
    this.loadUserInfo()
    this.fetchData()
  },
  methods: {
    loadUserInfo() {
      // 从本地存储加载用户信息
      const savedUser = localStorage.getItem('user')
      if (savedUser) {
        try {
          const user = JSON.parse(savedUser)
          this.userInfo = { ...this.userInfo, ...user }
          this.editForm = {
            nickname: this.userInfo.nickname,
            bio: this.userInfo.bio
          }
        } catch (e) {
          console.error('加载用户信息失败', e)
        }
      }
    },
    async fetchData() {
      try {
        this.loading = true
        // 使用真实API调用
        if (this.$axios) {
          const response = await this.$axios.get('/api/capsules.json')
          this.capsules = response.data || []
        } else {
          // 如果没有axios，使用fetch
          const response = await fetch('/api/capsules.json')
          const data = await response.json()
          this.capsules = data || []
        }
        this.loading = false
      } catch (error) {
        console.error('加载失败:', error)
        // 模拟数据
        this.capsules = [
          {
            id: 1,
            title: '致未来的自己',
            content: '希望未来的自己能够保持初心，继续前行...',
            date: new Date().toISOString().split('T')[0],
            privacy: 'private',
            cover: ''
          }
        ]
        this.loading = false
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
    saveProfile() {
      this.userInfo.nickname = this.editForm.nickname
      this.userInfo.bio = this.editForm.bio
      // 保存到本地存储
      localStorage.setItem('user', JSON.stringify(this.userInfo))
      ElMessage.success('资料保存成功')
      this.showEditDialog = false
    },
    handleAvatarUpload(file) {
      // 处理头像上传
      const reader = new FileReader()
      reader.onload = (e) => {
        this.userInfo.avatar = e.target.result
        // 同步到编辑表单，方便后续扩展（如显示预览）
        localStorage.setItem('user', JSON.stringify(this.userInfo))
        ElMessage.success('头像更新成功')
      }
      reader.readAsDataURL(file)
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
  line-height: 80px;
  text-align: center;
}
</style>