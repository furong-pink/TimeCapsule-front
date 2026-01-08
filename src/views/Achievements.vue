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

    <!-- 加载状态 -->
    <div v-if="loading" class="loading-container">
      <el-spin size="large">
        <template #default>
          <div>正在加载成就数据...</div>
        </template>
      </el-spin>
    </div>

    <!-- 成就筛选 -->
    <div class="achievement-filter">
      <el-button 
        :type="filterType === 'all' ? 'primary' : ''"
        @click="onFilterChange('all')"
        size="small"
      >
        全部
      </el-button>
      <el-button 
        :type="filterType === 'achieved' ? 'primary' : ''"
        @click="onFilterChange('achieved')"
        size="small"
      >
        已获得
      </el-button>
      <el-button 
        :type="filterType === 'locked' ? 'primary' : ''"
        @click="onFilterChange('locked')"
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
            进度: {{ achievement.progress }}/{{ achievement.total }}
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
            <span class="info-value">{{ selectedAchievement?.conditionType }}: {{ selectedAchievement?.conditionValue }}</span>
          </div>
          <div class="info-item" v-if="selectedAchievement?.achieved">
            <span class="info-label">获得时间：</span>
            <span class="info-value">{{ formatDate(selectedAchievement?.achievedDate) }}</span>
          </div>
          <div class="info-item" v-if="!selectedAchievement?.achieved">
            <span class="info-label">当前进度：</span>
            <span class="info-value">{{ selectedAchievement?.progress }}/{{ selectedAchievement?.total }} ({{ Math.round((selectedAchievement?.progress / selectedAchievement?.total) * 100) }}%)</span>
          </div>
        </div>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import { ref, computed, onMounted } from 'vue'
import { 
  Star, 
  Document, 
  Clock, 
  Trophy, 
  Medal,
  User,
  Calendar,
  Share,
  CircleCheck,
  Loading
} from '@element-plus/icons-vue'
import { ElMessage } from 'element-plus'

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
    CircleCheck,
    Loading
  },
  setup() {
    const filterType = ref('all')
    const showDetailDialog = ref(false)
    const selectedAchievement = ref(null)
    const loading = ref(false)
    
    // 存储从后端获取的成就数据
    const achievements = ref([])
    
    // 统计信息
    const statistics = ref({
      total: 0,
      achieved: 0,
      locked: 0
    })
    
    // 新解锁的成就
    const newAchievements = ref([])
    
    // 根据API文档中的数据结构映射成就数据
    const mapAchievementData = (achievement) => {
      // 计算进度，如果已达成则设为100%
      let calculatedProgress = achievement.progress || achievement.currentProgress || 0;
      
      if (achievement.achieved) {
        // 如果成就已达成，进度应该等于条件值（即100%）
        calculatedProgress = achievement.conditionValue || 100;
      }
      
      return {
        id: achievement.id,
        title: achievement.title,
        description: achievement.description,
        icon: achievement.icon || 'Star', // 默认图标
        achieved: achievement.achieved,
        isNew: achievement.isNew,
        achievedDate: achievement.achievedAt,
        condition: `${achievement.conditionType}: ${achievement.conditionValue}`,
        progress: calculatedProgress,
        total: achievement.conditionValue,
        conditionType: achievement.conditionType,
        conditionValue: achievement.conditionValue
      }
    }
    
    // 加载成就数据
    const loadAchievements = async (filter = 'ALL') => {
      loading.value = true
      try {
        if (window.$axios) {
          const response = await window.$axios.get(`/achievements?filter=${filter}`)
          if (response?.code === 200 && response.data) {
            // 映射成就列表数据
            const newAchievementsData = response.data.list.map(mapAchievementData);
            
            // 强制更新数组以确保Vue响应式更新
            achievements.value = [];
            // 使用nextTick确保DOM更新后再设置新值
            await new Promise(resolve => setTimeout(resolve, 0));
            achievements.value = newAchievementsData;
            
            // 更新统计信息
            if (response.data.statistics) {
              statistics.value = response.data.statistics
            }
            
            // 更新新解锁的成就
            newAchievements.value = achievements.value.filter(a => a.isNew && a.achieved)
            
            console.log('获取成就数据成功:', response.data)
          } else {
            console.error('获取成就数据失败:', response)
            ElMessage.error(response?.message || '获取成就数据失败')
          }
        } else {
          console.error('window.$axios 未定义')
          ElMessage.error('网络连接异常')
        }
      } catch (error) {
        console.error('获取成就数据时发生错误:', error)
        ElMessage.error('获取成就数据失败')
      } finally {
        loading.value = false
      }
    }
    
    // 检查并解锁成就
    const checkAchievements = async () => {
      try {
        if (window.$axios) {
          const response = await window.$axios.post('/achievements/check')
          if (response?.code === 200 && response.data) {
            if (response.data.newAchievements && response.data.newAchievements.length > 0) {
              ElMessage.success(`恭喜！获得了 ${response.data.newAchievements.length} 个新成就`)
              // 重新加载成就数据以更新显示状态
              await loadAchievements(filterType.value.toUpperCase())
            }
          } else {
            console.error('检查成就失败:', response)
            ElMessage.error(response?.message || '检查成就失败')
          }
        }
      } catch (error) {
        console.error('检查成就时发生错误:', error)
        ElMessage.error('检查成就失败')
      }
    }
    
    // 标记成就已读
    const markAchievementAsRead = async (id) => {
      try {
        if (window.$axios) {
          const response = await window.$axios.patch(`/achievements/${id}/read`)
          if (response?.code === 200) {
            console.log(`成就 ${id} 已标记为已读`)
            // 更新本地数据
            const achievement = achievements.value.find(a => a.id === id)
            if (achievement) {
              // 创建新对象以触发响应式更新
              const index = achievements.value.indexOf(achievement);
              if (index !== -1) {
                achievement.isNew = false;
                // 替换整个对象以确保响应式更新
                achievements.value[index] = {...achievement};
              }
            }
          }
        }
      } catch (error) {
        console.error('标记成就已读失败:', error)
      }
    }
    
    // 计算属性
    const achievedCount = computed(() => {
      return statistics.value.achieved
    })

    const totalCount = computed(() => {
      return statistics.value.total
    })
    
    const filteredAchievements = computed(() => {
      // 创建一个新的数组以确保Vue响应式更新
      const allAchievements = [...achievements.value];
      
      if (filterType.value === 'all') {
        return allAchievements;
      } else if (filterType.value === 'achieved') {
        return allAchievements.filter(a => a.achieved);
      } else {
        return allAchievements.filter(a => !a.achieved);
      }
    })

    const formatDate = (date) => {
      if (!date) return ''
      // 处理不同格式的日期字符串
      if (typeof date === 'string') {
        if (date.includes('T')) {
          // ISO 8601 格式: 2025-01-15T10:30:00Z
          const d = new Date(date)
          return `${d.getFullYear()}年${d.getMonth() + 1}月${d.getDate()}日`
        } else {
          // 简单格式: 2025-01-15
          const parts = date.split('-')
          if (parts.length === 3) {
            return `${parts[0]}年${parseInt(parts[1])}月${parseInt(parts[2])}日`
          }
        }
      }
      return ''
    }

    const showAchievementDetail = (achievement) => {
      selectedAchievement.value = achievement
      showDetailDialog.value = true
      // 标记为已查看（如果它是新的）
      if (achievement.isNew) {
        markAchievementAsRead(achievement.id)
      }
    }
    
    // 监听筛选类型变化
    const onFilterChange = (newFilter) => {
      filterType.value = newFilter
      loadAchievements(newFilter.toUpperCase())
    }
    
    // 初始化数据
    onMounted(async () => {
      await loadAchievements('ALL')
      // 检查是否有新成就
      await checkAchievements()
    })

    return {
      filterType,
      showDetailDialog,
      selectedAchievement,
      loading,
      achievements,
      statistics,
      newAchievements: computed(() => achievements.value.filter(a => a.isNew && a.achieved)),
      achievedCount,
      totalCount,
      filteredAchievements,
      formatDate,
      showAchievementDetail,
      loadAchievements,
      onFilterChange,
      checkAchievements
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

/* 加载状态 */
.loading-container {
  display: flex;
  justify-content: center;
  align-items: center;
  padding: 40px 0;
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