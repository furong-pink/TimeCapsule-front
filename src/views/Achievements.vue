<template>
  <div class="achievements">
    <div class="achievements-header">
      <div>
        <h2>成就徽章</h2>
        <p>查看你获得的成就和奖励</p>
      </div>
      <div class="achievement-stats">
        <div class="stat-item">
          <span class="stat-value">{{ achievedCount }}</span>
          <span class="stat-label">已获得</span>
        </div>
        <div class="stat-item">
          <span class="stat-value">{{ totalCount }}</span>
          <span class="stat-label">总成就</span>
        </div>
      </div>
    </div>

    <!-- 新成就通知 -->
    <el-alert
      v-if="newAchievements.length > 0"
      type="success"
      :closable="false"
      show-icon
      class="new-achievement-alert"
    >
      <template #title>
        <span>🎉 恭喜！你获得了 {{ newAchievements.length }} 个新成就</span>
      </template>
    </el-alert>

    <!-- 成就筛选 -->
    <div class="achievement-filter">
      <el-button 
        :type="filterType === 'all' ? 'primary' : ''"
        @click="filterType = 'all'"
        size="small"
      >
        全部
      </el-button>
      <el-button 
        :type="filterType === 'achieved' ? 'primary' : ''"
        @click="filterType = 'achieved'"
        size="small"
      >
        已获得
      </el-button>
      <el-button 
        :type="filterType === 'locked' ? 'primary' : ''"
        @click="filterType = 'locked'"
        size="small"
      >
        未解锁
      </el-button>
    </div>

    <!-- 成就网格 -->
    <div class="achievement-grid">
      <el-card 
        class="achievement-card" 
        v-for="achievement in filteredAchievements" 
        :key="achievement.id"
        :class="{ 
          'achieved': achievement.achieved,
          'new-achievement': achievement.isNew
        }"
        shadow="hover"
        @click="showAchievementDetail(achievement)"
      >
        <div class="badge-container">
          <div class="badge" :class="{ 'locked': !achievement.achieved }">
            <el-icon :size="48">
              <component :is="achievement.icon" />
            </el-icon>
          </div>
          <div class="new-badge" v-if="achievement.isNew">
            <el-icon><Star /></el-icon>
          </div>
        </div>
        <h3>{{ achievement.title }}</h3>
        <p class="achievement-description">{{ achievement.description }}</p>
        <div class="achievement-footer">
          <el-tag :type="achievement.achieved ? 'success' : 'info'" size="small">
            {{ achievement.achieved ? '已获得' : '未解锁' }}
          </el-tag>
          <span class="unlock-condition" v-if="!achievement.achieved">
            {{ achievement.condition }}
          </span>
          <span class="achieved-date" v-else>
            {{ formatDate(achievement.achievedDate) }}
          </span>
        </div>
      </el-card>
    </div>

    <!-- 成就详情对话框 -->
    <el-dialog v-model="showDetailDialog" :title="selectedAchievement?.title" width="500px">
      <div class="achievement-detail">
        <div class="detail-badge">
          <el-icon :size="80">
            <component :is="selectedAchievement?.icon" />
          </el-icon>
        </div>
        <h3>{{ selectedAchievement?.title }}</h3>
        <p class="detail-description">{{ selectedAchievement?.description }}</p>
        <div class="detail-info">
          <el-divider />
          <div class="info-item">
            <span class="info-label">解锁条件：</span>
            <span class="info-value">{{ selectedAchievement?.condition }}</span>
          </div>
          <div class="info-item" v-if="selectedAchievement?.achieved">
            <span class="info-label">获得时间：</span>
            <span class="info-value">{{ formatDate(selectedAchievement?.achievedDate) }}</span>
          </div>
        </div>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import { ref, computed } from 'vue'
import { 
  Star, 
  Document, 
  Clock, 
  Trophy, 
  Medal,
  User,
  Calendar,
  Share,
  CircleCheck
} from '@element-plus/icons-vue'

export default {
  name: 'Achievements',
  components: {
    Star,
    Document,
    Clock,
    Trophy,
    Medal,
    User,
    Calendar,
    Share,
    CircleCheck
  },
  setup() {
    const filterType = ref('all')
    const showDetailDialog = ref(false)
    const selectedAchievement = ref(null)

    const achievements = ref([
      {
        id: 1,
        title: '初学者',
        description: '创建第一个时间胶囊',
        icon: 'Star',
        achieved: true,
        condition: '创建第一个时间胶囊',
        achievedDate: '2025-01-15',
        isNew: false
      },
      {
        id: 2,
        title: '记录者',
        description: '创建5个时间胶囊',
        icon: 'Document',
        achieved: false,
        condition: '创建5个时间胶囊',
        progress: 2,
        total: 5
      },
      {
        id: 3,
        title: '时间旅行者',
        description: '打开一个过去的时间胶囊',
        icon: 'Clock',
        achieved: true,
        condition: '打开一个过去的时间胶囊',
        achievedDate: '2025-02-20',
        isNew: true
      },
      {
        id: 4,
        title: '目标达人',
        description: '完成3个个人目标',
        icon: 'Trophy',
        achieved: false,
        condition: '完成3个个人目标',
        progress: 1,
        total: 3
      },
      {
        id: 5,
        title: '分享者',
        description: '分享5个公开的时间胶囊',
        icon: 'Share',
        achieved: false,
        condition: '分享5个公开的时间胶囊',
        progress: 0,
        total: 5
      },
      {
        id: 6,
        title: '坚持者',
        description: '连续30天创建时间胶囊',
        icon: 'Calendar',
        achieved: false,
        condition: '连续30天创建时间胶囊',
        progress: 5,
        total: 30
      },
      {
        id: 7,
        title: '成就收集家',
        description: '获得10个成就徽章',
        icon: 'Medal',
        achieved: false,
        condition: '获得10个成就徽章',
        progress: 2,
        total: 10
      },
      {
        id: 8,
        title: '完美主义者',
        description: '完成所有目标',
        icon: 'CircleCheck',
        achieved: false,
        condition: '完成所有设定的目标'
      }
    ])

    const achievedCount = computed(() => {
      return achievements.value.filter(a => a.achieved).length
    })

    const totalCount = computed(() => {
      return achievements.value.length
    })

    const newAchievements = computed(() => {
      return achievements.value.filter(a => a.isNew && a.achieved)
    })

    const filteredAchievements = computed(() => {
      if (filterType.value === 'all') {
        return achievements.value
      } else if (filterType.value === 'achieved') {
        return achievements.value.filter(a => a.achieved)
      } else {
        return achievements.value.filter(a => !a.achieved)
      }
    })

    const formatDate = (date) => {
      if (!date) return ''
      const d = new Date(date)
      return `${d.getFullYear()}年${d.getMonth() + 1}月${d.getDate()}日`
    }

    const showAchievementDetail = (achievement) => {
      selectedAchievement.value = achievement
      showDetailDialog.value = true
      // 标记为已查看
      if (achievement.isNew) {
        achievement.isNew = false
      }
    }

    return {
      filterType,
      showDetailDialog,
      selectedAchievement,
      achievements,
      achievedCount,
      totalCount,
      newAchievements,
      filteredAchievements,
      formatDate,
      showAchievementDetail
    }
  }
}
</script>

<style scoped>
.achievements {
  padding: 0;
  margin: 0;
  width: 100%;
  min-height: calc(100vh - 120px);
}

.achievements-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 20px;
}

h2 {
  color: #333;
  font-size: 24px;
  font-weight: 600;
  margin: 0 0 8px 0;
}

p {
  color: #666;
  font-size: 14px;
  margin: 0;
}

.achievement-stats {
  display: flex;
  gap: 30px;
}

.stat-item {
  text-align: center;
}

.stat-value {
  display: block;
  font-size: 28px;
  font-weight: 600;
  color: #409EFF;
  line-height: 1;
  margin-bottom: 4px;
}

.stat-label {
  font-size: 12px;
  color: #999;
}

/* 新成就通知 */
.new-achievement-alert {
  margin-bottom: 20px;
}

/* 筛选按钮 */
.achievement-filter {
  display: flex;
  gap: 10px;
  margin-bottom: 20px;
}

/* 成就网格 */
.achievement-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(240px, 1fr));
  gap: 20px;
}

.achievement-card {
  text-align: center;
  border-radius: 8px;
  transition: all 0.3s ease;
  cursor: pointer;
  position: relative;
  overflow: visible;
}

.achievement-card:hover {
  transform: translateY(-5px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
}

.achievement-card.achieved {
  border: 2px solid #67c23a;
  background: linear-gradient(135deg, rgba(103, 194, 58, 0.05) 0%, rgba(103, 194, 58, 0.02) 100%);
}

.achievement-card.new-achievement {
  animation: pulse 2s infinite;
}

@keyframes pulse {
  0%, 100% {
    box-shadow: 0 0 0 0 rgba(103, 194, 58, 0.4);
  }
  50% {
    box-shadow: 0 0 0 10px rgba(103, 194, 58, 0);
  }
}

.badge-container {
  position: relative;
  display: inline-block;
  margin: 20px 0;
}

.badge {
  width: 80px;
  height: 80px;
  border-radius: 50%;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
  margin: 0 auto;
  transition: all 0.3s ease;
}

.badge.locked {
  background: #e0e0e0;
  color: #999;
  filter: grayscale(100%);
}

.achievement-card.achieved .badge {
  background: linear-gradient(135deg, #67c23a 0%, #85ce61 100%);
}

.new-badge {
  position: absolute;
  top: -5px;
  right: -5px;
  width: 24px;
  height: 24px;
  background: #f56c6c;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
  font-size: 12px;
  border: 2px solid white;
}

h3 {
  margin: 0 0 10px 0;
  color: #333;
  font-size: 16px;
  font-weight: 600;
}

.achievement-description {
  margin: 0 0 12px 0;
  font-size: 14px;
  color: #666;
  min-height: 40px;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.achievement-footer {
  display: flex;
  flex-direction: column;
  gap: 8px;
  align-items: center;
}

.unlock-condition,
.achieved-date {
  font-size: 12px;
  color: #999;
}

.achieved-date {
  color: #67c23a;
}

/* 成就详情 */
.achievement-detail {
  text-align: center;
}

.detail-badge {
  margin-bottom: 20px;
}

.detail-badge .el-icon {
  color: #409EFF;
}

.detail-description {
  font-size: 16px;
  color: #666;
  margin: 16px 0;
  line-height: 1.6;
}

.detail-info {
  text-align: left;
}

.info-item {
  display: flex;
  justify-content: space-between;
  padding: 12px 0;
}

.info-label {
  color: #999;
  font-size: 14px;
}

.info-value {
  color: #333;
  font-size: 14px;
  font-weight: 500;
}
</style>