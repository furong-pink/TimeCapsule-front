<template>
  <div class="achievements">
    <div class="container">
      <div class="achievements-header">
        <div class="header-left">
          <div class="subtitle"></div>
          <h1>成就勋章</h1>
          <p>每一次坚持都值得被看见！解锁勋章，成为更酷的自己，和时光一起闪闪发光。</p>
        </div>
        <div class="header-right">
          <div class="stats-card">
            <div class="stats-ratio">{{ achievedCount }} / {{ totalCount }}</div>
            <div class="stats-label">已获得的勋章</div>
            <div class="stats-progress">
              <div class="progress-bar">
                <div class="progress-fill" :style="{ width: achievementProgress + '%' }"></div>
              </div>
            </div>
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
            'locked': !achievement.achieved
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
            <div class="lock-icon" v-if="!achievement.achieved">
              <el-icon :size="16"><Lock /></el-icon>
            </div>
            <div class="achieved-badge" v-if="achievement.achieved">
              已获得
            </div>
          </div>
          <h3>{{ achievement.title }}</h3>
          <p class="achievement-description">{{ achievement.description }}</p>

          <!-- 进度条区域 -->
          <div class="progress-section">
            <div class="progress-bar-container">
              <div class="progress-bar">
                <div
                  class="progress-fill"
                  :class="{ 'achieved': achievement.achieved }"
                  :style="{ width: getProgressPercent(achievement) + '%' }"
                ></div>
              </div>
            </div>
            <div class="progress-text">
              <span v-if="!achievement.achieved">进度</span>
              <span v-else>获得日期</span>
              <span class="progress-value">
                {{ achievement.achieved ? formatDate(achievement.achievedDate) : achievement.progress + '/' + achievement.total }}
              </span>
            </div>
          </div>
        </el-card>
      </div>
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
  Loading,
  Lock
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
    Loading,
    Lock
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

    // 用户业务数据统计（用于计算徽章进度）
    const userStats = ref({
      capsuleCount: 0,           // 创建的胶囊总数
      completedGoalCount: 0,     // 已完成的目标数量
      totalGoalCount: 0,         // 目标总数
      sharedCapsuleCount: 0,     // 公开分享的胶囊数量
      recordDayCount: 0,         // 连续记录天数
      achievementCount: 0        // 获得的成就数量
    })

    // 新解锁的成就
    const newAchievements = ref([])

    // 根据徽章标题获取对应的用户业务数据
    const getProgressFromUserStats = (title) => {
      switch (title) {
        case '记录者':
          return userStats.value.capsuleCount;
        case '目标达人':
          return userStats.value.completedGoalCount;
        case '分享者':
          return userStats.value.sharedCapsuleCount;
        case '坚持者':
          return userStats.value.recordDayCount;
        case '成就收集家':
          return userStats.value.achievementCount;
        case '时间旅行者':
          // 时间旅行者需要特殊处理（已开启的胶囊）
          return 0;
        case '初学者':
          // 初学者：创建第一个时间胶囊（已创建则完成）
          return userStats.value.capsuleCount >= 1 ? 1 : 0;
        case '完美主义者':
          // 完美主义者：完成所有目标（需要知道目标总数）
          return 0;
        default:
          return 0;
      }
    }

    // 根据API文档中的数据结构映射成就数据
    const mapAchievementData = (achievement) => {
      // 从用户真实业务数据中计算进度
      const userProgress = getProgressFromUserStats(achievement.title);
      const conditionValue = achievement.conditionValue || 0;
      
      // 判断是否达成：进度 >= 目标值
      const isAchieved = userProgress >= conditionValue;
      
      // 计算显示的进度值（不超过目标值）
      const calculatedProgress = Math.min(userProgress, conditionValue);

      return {
        id: achievement.id,
        title: achievement.title,
        description: achievement.description,
        icon: achievement.icon || 'Star', // 默认图标
        achieved: isAchieved,
        isNew: achievement.isNew,
        achievedDate: isAchieved ? achievement.achievedAt || new Date().toISOString() : null,
        condition: `${achievement.conditionType}: ${conditionValue}`,
        progress: calculatedProgress,
        total: conditionValue,
        conditionType: achievement.conditionType,
        conditionValue: conditionValue
      }
    }

    // 获取用户业务数据统计
    const getUserStats = async () => {
      try {
        if (window.$axios) {
          // 获取胶囊数量和创建日期（用于计算连续记录天数）
          const capsuleResponse = await window.$axios.get('/capsules?page=1&size=100');
          if (capsuleResponse?.code === 200 && capsuleResponse.data) {
            userStats.value.capsuleCount = capsuleResponse.data.total || 0;
            
            // 计算连续记录天数
            let recordDayCount = 0;
            if (capsuleResponse.data.content && Array.isArray(capsuleResponse.data.content)) {
              // 获取所有胶囊的创建日期（去重）
              const createDatesSet = new Set();
              capsuleResponse.data.content.forEach(capsule => {
                // 兼容多种日期字段名
                const createTime = capsule.createdAt || capsule.created_at || capsule.date || capsule.createTime || capsule.create_time;
                if (createTime) {
                  // 转换为日期字符串（YYYY-MM-DD）
                  const date = new Date(createTime);
                  if (!isNaN(date.getTime())) {
                    createDatesSet.add(date.toISOString().split('T')[0]);
                  }
                }
              });
              
              // 如果没有任何创建日期，连续天数为0
              if (createDatesSet.size === 0) {
                recordDayCount = 0;
              } else {
                // 获取今天的日期字符串
                const today = new Date();
                today.setHours(0, 0, 0, 0);
                const todayStr = today.toISOString().split('T')[0];
                
                // 找到最新的创建日期
                const sortedDates = Array.from(createDatesSet).sort((a, b) => new Date(b) - new Date(a));
                const latestDate = sortedDates[0];
                
                // 确定从哪一天开始计算连续天数
                let startDate;
                if (createDatesSet.has(todayStr)) {
                  // 今天有创建胶囊，从今天开始
                  startDate = new Date(today);
                  recordDayCount = 1;
                } else {
                  // 今天没有创建，从最新的创建日期开始
                  startDate = new Date(latestDate);
                  recordDayCount = 1;
                }
                
                // 向前计算连续天数
                let checkDate = new Date(startDate);
                checkDate.setDate(checkDate.getDate() - 1);
                
                while (createDatesSet.has(checkDate.toISOString().split('T')[0])) {
                  recordDayCount++;
                  checkDate.setDate(checkDate.getDate() - 1);
                }
              }
            }
            
            userStats.value.recordDayCount = recordDayCount;
            console.log('连续记录天数:', recordDayCount);
          }

          // 获取目标总数（查询所有目标）
          const allGoalsResponse = await window.$axios.get('/goals?status=ALL');
          if (allGoalsResponse?.code === 200 && allGoalsResponse.data) {
            const allResponseData = allGoalsResponse.data;
            let totalCount = 0;
            
            // 后端API返回结构：{ content: [...], statistics: { total, completed, ... } }
            if (allResponseData.statistics && allResponseData.statistics.total !== undefined) {
              totalCount = allResponseData.statistics.total;
            } else if (allResponseData.content && Array.isArray(allResponseData.content)) {
              totalCount = allResponseData.content.length;
            } else if (allResponseData.total !== undefined) {
              totalCount = allResponseData.total;
            }
            
            userStats.value.totalGoalCount = totalCount;
            console.log('目标总数:', totalCount);
          }

          // 获取已完成的目标数量
          const completedGoalsResponse = await window.$axios.get('/goals?status=COMPLETED');
          if (completedGoalsResponse?.code === 200 && completedGoalsResponse.data) {
            const responseData = completedGoalsResponse.data;
            let completedCount = 0;
            
            // 优先从statistics获取已完成数量
            if (responseData.statistics && responseData.statistics.completed !== undefined) {
              completedCount = responseData.statistics.completed;
            }
            // 其次从列表长度获取（当status=COMPLETED过滤时，列表长度就是已完成数量）
            else if (responseData.content && Array.isArray(responseData.content)) {
              completedCount = responseData.content.length;
            }
            
            userStats.value.completedGoalCount = completedCount;
            console.log('已完成目标数量:', completedCount);
          }

          // 获取公开分享的胶囊数量（需要后端支持）
          // 暂时设为0，如果后端有接口可以取消注释
          // const sharedResponse = await window.$axios.get('/capsules?shared=true');
          // if (sharedResponse?.code === 200 && sharedResponse.data) {
          //   userStats.value.sharedCapsuleCount = sharedResponse.data.total || 0;
          // }

          // 获取用户成就数量
          userStats.value.achievementCount = statistics.value.achieved || 0;

          console.log('获取用户统计数据成功:', userStats.value);
        }
      } catch (error) {
        console.error('获取用户统计数据失败:', error);
      }
    }

    // 加载成就数据
    const loadAchievements = async (filter = 'ALL') => {
      loading.value = true
      try {
        if (window.$axios) {
          const response = await window.$axios.get(`/achievements?filter=${filter}`)
          if (response?.code === 200 && response.data) {
            // 更新统计信息（先更新，以便getUserStats可以使用）
            if (response.data.statistics) {
              statistics.value = response.data.statistics
            }

            // 获取用户业务数据统计
            await getUserStats();

            // 映射成就列表数据（此时userStats已更新，可以计算真实进度）
            const newAchievementsData = response.data.list.map(mapAchievementData);

            // 强制更新数组以确保Vue响应式更新
            achievements.value = [];
            // 使用nextTick确保DOM更新后再设置新值
            await new Promise(resolve => setTimeout(resolve, 0));
            achievements.value = newAchievementsData;

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

    const achievementProgress = computed(() => {
      if (totalCount.value === 0) return 0
      return Math.round((achievedCount.value / totalCount.value) * 100)
    })

    const getProgressPercent = (achievement) => {
      if (!achievement || achievement.total === 0) return 0
      return Math.round((achievement.progress / achievement.total) * 100)
    }

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
      achievementProgress,
      filteredAchievements,
      formatDate,
      showAchievementDetail,
      loadAchievements,
      onFilterChange,
      checkAchievements,
      getProgressPercent
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
  background-color: #f5f7fa;
}

.container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 40px 20px;
}

.achievements-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 32px;
  padding: 24px;
  background-color: #ffffff;
  border-radius: 12px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.04);
}

.header-left {
  flex: 1;
}

.header-left .subtitle {
  font-size: 12px;
  font-weight: 600;
  color: #8a8a8a;
  letter-spacing: 2px;
  margin-bottom: 8px;
}

.header-left h1 {
  font-size: 32px;
  font-weight: 700;
  color: #1a1a1a;
  margin: 0 0 12px 0;
}

.header-left p {
  font-size: 14px;
  color: #666666;
  line-height: 1.6;
  margin: 0;
  max-width: 500px;
}

.header-right {
  flex-shrink: 0;
}

.stats-card {
  background: linear-gradient(135deg, #ffffff 0%, #f8f9fa 100%);
  border-radius: 12px;
  padding: 20px 32px;
  min-width: 180px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.06);
}

.stats-ratio {
  font-size: 48px;
  font-weight: 700;
  color: #409EFF;
  line-height: 1;
  margin-bottom: 8px;
}

.stats-label {
  font-size: 14px;
  color: #999999;
  margin-bottom: 12px;
  display: block;
}

.stats-progress {
  width: 100%;
}

.stats-progress .progress-bar {
  height: 6px;
  background-color: #e8e8e8;
  border-radius: 3px;
  overflow: hidden;
}

.stats-progress .progress-fill {
  height: 100%;
  background-color: #409EFF;
  border-radius: 3px;
  transition: width 0.3s ease;
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
  grid-template-columns: repeat(4, 1fr);
  gap: 20px;
}

.achievement-card {
  text-align: center;
  border-radius: 12px;
  transition: all 0.3s ease;
  cursor: pointer;
  position: relative;
  overflow: visible;
  border: 1px solid #e8e8e8;
  background-color: #ffffff;
}

.achievement-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.08);
}

.achievement-card.achieved {
  border-color: #e8f5e9;
  background: linear-gradient(135deg, #ffffff 0%, #f1f8e9 100%);
}

.achievement-card.locked {
  opacity: 0.6;
}

.badge-container {
  position: relative;
  display: inline-block;
  margin: 24px 0 16px 0;
}

.badge {
  width: 80px;
  height: 80px;
  border-radius: 50%;
  background: linear-gradient(135deg, #409EFF 0%, #67b8f7 100%);
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
  margin: 0 auto;
  transition: all 0.3s ease;
  box-shadow: 0 4px 12px rgba(64, 158, 255, 0.3);
}

.badge.locked {
  background: #e8e8e8;
  color: #999;
  filter: grayscale(100%);
  box-shadow: none;
}

.achievement-card.achieved .badge {
  background: linear-gradient(135deg, #67c23a 0%, #85ce61 100%);
  box-shadow: 0 4px 12px rgba(103, 194, 58, 0.3);
}

.lock-icon {
  position: absolute;
  top: -8px;
  right: -8px;
  width: 28px;
  height: 28px;
  background-color: #cccccc;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #ffffff;
  font-size: 12px;
}

.achieved-badge {
  position: absolute;
  top: -10px;
  right: -10px;
  background-color: #67c23a;
  color: #ffffff;
  font-size: 11px;
  font-weight: 600;
  padding: 4px 10px;
  border-radius: 12px;
  box-shadow: 0 2px 8px rgba(103, 194, 58, 0.3);
}

h3 {
  margin: 0 0 12px 0;
  color: #1a1a1a;
  font-size: 16px;
  font-weight: 600;
}

.achievement-description {
  margin: 0 0 16px 0;
  font-size: 13px;
  color: #666666;
  line-height: 1.5;
  min-height: 48px;
  display: -webkit-box;
  -webkit-line-clamp: 3;
  -webkit-box-orient: vertical;
  overflow: hidden;
  padding: 0 16px;
}

/* 进度条区域 */
.progress-section {
  padding: 0 16px 16px;
}

.progress-bar-container {
  margin-bottom: 8px;
}

.progress-bar-container .progress-bar {
  height: 6px;
  background-color: #e8e8e8;
  border-radius: 3px;
  overflow: hidden;
}

.progress-bar-container .progress-fill {
  height: 100%;
  background-color: #409EFF;
  border-radius: 3px;
  transition: width 0.3s ease;
}

.progress-bar-container .progress-fill.achieved {
  background-color: #67c23a;
}

.progress-text {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 12px;
  color: #999999;
}

.progress-text .progress-value {
  font-weight: 600;
  color: #666666;
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
