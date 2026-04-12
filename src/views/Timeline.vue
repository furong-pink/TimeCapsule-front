<template>
  <div class="timeline">
    <div class="timeline-header">
      <div>
        <h2>时间轴</h2>
        <p>查看你创建的所有时间胶囊</p>
      </div>
      <el-button type="primary" @click="$router.push('/capsule/create')">
        <el-icon><Plus /></el-icon>
        创建新胶囊
      </el-button>
    </div>

    <!-- 年份筛选 -->
    <div class="year-filter">
      <el-button 
        v-for="year in years" 
        :key="year"
        :type="selectedYear === year ? 'primary' : ''"
        @click="selectedYear = year"
        size="small"
      >
        {{ year }}年
      </el-button>
      <el-button 
        :type="selectedYear === 'all' ? 'primary' : ''"
        @click="selectedYear = 'all'"
        size="small"
      >
        全部
      </el-button>
    </div>

    <!-- 快速导航 -->
    <div class="quick-nav" v-if="filteredActivities.length > 0">
      <span class="nav-label">快速跳转：</span>
      <el-scrollbar>
        <div class="nav-buttons">
          <el-button 
            v-for="year in years" 
            :key="year"
            text
            @click="scrollToYear(year)"
            size="small"
          >
            {{ year }}年 ({{ getYearCount(year) }})
          </el-button>
        </div>
      </el-scrollbar>
    </div>

    <!-- 时间轴内容 -->
    <div class="timeline-container" v-loading="loading">
      <el-empty v-if="!loading && filteredActivities.length === 0" description="还没有时间胶囊">
        <el-button type="primary" @click="$router.push('/capsule/create')">创建第一个胶囊</el-button>
      </el-empty>

      <el-timeline v-else>
        <el-timeline-item
          v-for="(activity, index) in filteredActivities"
          :key="activity.id || index"
          :timestamp="formatTimestamp(activity.timestamp || activity.date)"
          placement="top"
          :icon="getTimelineIcon(activity)"
          :color="getTimelineColor(activity)"
        >
          <el-card class="timeline-card" shadow="hover" @click="viewCapsule(activity)">
            <div class="card-content">
              <div class="card-cover" v-if="activity.cover">
                <img :src="activity.cover" :alt="activity.title" />
              </div>
              <div class="card-info">
                <div class="card-header">
                  <h4>{{ activity.title.length > 12 ? activity.title.substring(0, 12) + '...' : activity.title }}</h4>
                  <el-tag 
                    :type="(activity.privacy || '').toLowerCase() === 'public' ? 'success' : 'info'" 
                    size="small"
                  >
                    {{ (activity.privacy || '').toLowerCase() === 'public' ? '公开' : '私密' }}
                  </el-tag>
                </div>
                <p class="card-description">{{ activity.content || activity.description }}</p>
                <div class="card-footer">
                  <span class="card-date">
                    <el-icon><Calendar /></el-icon>
                    创建于 {{ formatDate(activity.createTime || activity.createdAt || activity.created_at || activity.date) }}
                  </span>
                  <span class="card-open-date" v-if="activity.openDate || activity.open_date">
                    <el-icon><Clock /></el-icon>
                    开启于 {{ formatDate(activity.openDate || activity.open_date) }}
                  </span>
                  <span class="card-status">
                    <el-tag :type="activity.isOpenable ? 'success' : 'warning'" size="small">
                      {{ activity.isOpenable ? '已可开启' : '未开启' }}
                    </el-tag>
                  </span>
                </div>
              </div>
            </div>
          </el-card>
        </el-timeline-item>
      </el-timeline>
    </div>
  </div>
</template>

<script>
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { Plus, Calendar, Clock } from '@element-plus/icons-vue'

export default {
  name: 'Timeline',
  components: {
    Plus,
    Calendar,
    Clock
  },
  setup() {
    const router = useRouter()
    const loading = ref(false)
    const selectedYear = ref('all')
    const activities = ref([])

    // 获取所有年份
    const years = computed(() => {
      const yearSet = new Set()
      activities.value.forEach(activity => {
        const date = activity.timestamp || activity.date
        if (date) {
          const year = new Date(date).getFullYear()
          yearSet.add(year)
        }
      })
      return Array.from(yearSet).sort((a, b) => b - a)
    })

    // 筛选后的活动
    const filteredActivities = computed(() => {
      if (selectedYear.value === 'all') {
        return activities.value.sort((a, b) => {
          const dateA = new Date(a.timestamp || a.date)
          const dateB = new Date(b.timestamp || b.date)
          return dateB - dateA
        })
      }
      return activities.value.filter(activity => {
        const date = activity.timestamp || activity.date
        if (!date) return false
        const year = new Date(date).getFullYear()
        return year === selectedYear.value
      }).sort((a, b) => {
        const dateA = new Date(a.timestamp || a.date)
        const dateB = new Date(b.timestamp || b.date)
        return dateB - dateA
      })
    })

    // 获取年份数量
    const getYearCount = (year) => {
      return activities.value.filter(activity => {
        const date = activity.timestamp || activity.date
        if (!date) return false
        return new Date(date).getFullYear() === year
      }).length
    }

    // 格式化时间戳
    const formatTimestamp = (date) => {
      if (!date) return ''
      const d = new Date(date)
      // 确保月份和日期格式正确
      return `${d.getFullYear()}年${d.getMonth() + 1}月${d.getDate()}日`
    }

    // 格式化日期
    const formatDate = (date) => {
      if (!date) return ''
      // 处理可能的日期格式，避免时区问题
      let year, month, day;
      if (typeof date === 'string' && date.includes('-') && date.length === 10) {
        // 如果是yyyy-MM-dd格式的日期字符串，直接提取年月日
        const parts = date.split('-');
        year = parseInt(parts[0]);
        month = parseInt(parts[1]);
        day = parseInt(parts[2]);
      } else {
        // 其他格式，使用日期对象
        const d = new Date(date);
        // 使用本地时间方法确保日期与用户本地时区一致
        year = d.getFullYear();
        month = d.getMonth() + 1;
        day = d.getDate();
      }
      // 确保日期格式正确
      return `${year}-${String(month).padStart(2, '0')}-${String(day).padStart(2, '0')}`
    }

    // 获取时间轴图标
    const getTimelineIcon = (activity) => {
      if ((activity.privacy || '').toLowerCase() === 'public') {
        return 'Share'
      }
      return 'Document'
    }

    // 获取时间轴颜色
    const getTimelineColor = (activity) => {
      if ((activity.privacy || '').toLowerCase() === 'public') {
        return '#67c23a'
      }
      return '#409eff'
    }

    // 滚动到指定年份
    const scrollToYear = (year) => {
      selectedYear.value = year
      // 可以添加滚动到对应位置的逻辑
    }

    // 查看胶囊详情
    const viewCapsule = (activity) => {
      // 跳转到胶囊详情页
      if (activity.id) {
        // 检查胶囊是否已可开启（基于开启时间判断）
        if (activity.isOpenable) {
          router.push(`/capsule/${activity.id}`);
        } else {
          // 未开启，提示开启时间
          const openDate = activity.openDate || activity.open_date;
          const openDateStr = openDate ? formatDate(openDate) : '未来';
          const message = `此时间胶囊将于 ${openDateStr} 开启`;
          window.$message ? window.$message.info(message) : alert(message);
        }
      } else {
        console.error('时间胶囊ID不存在:', activity);
      }
    }

    // 加载数据
    const loadData = async () => {
      loading.value = true
      try {
        // 尝试从API加载
        if (window.$axios) {
          // 获取时间轴数据
          window.$axios.get('/capsules/timeline').then(response => {
            if (response?.data?.timeline) {
              // 将时间轴数据转换为活动列表
              const timelineActivities = [];
              response.data.timeline.forEach(yearData => {
                yearData.capsules.forEach(capsule => {
                  // 严格区分创建时间和开启时间
                  const createTime = capsule.createdAt || capsule.created_at || capsule.date;
                  const openTime = capsule.openDate || capsule.open_date;
                  
                  // 根据开启时间判断胶囊是否已可开启
                  const now = new Date();
                  const openDate = openTime ? new Date(openTime) : null;
                  const isOpenable = openDate ? openDate <= now : true;
                  
                  // 确保日期字段正确处理
                  const processedCapsule = {
                    ...capsule,
                    timestamp: createTime, // 时间轴按创建时间排序显示
                    createTime: createTime, // 创建时间
                    openDate: openTime, // 开启时间
                    isOpenable: isOpenable, // 是否已可开启
                    type: 'capsule'
                  };
                  timelineActivities.push(processedCapsule);
                });
              });
              activities.value = timelineActivities;
            } else {
              activities.value = [];
            }
          }).catch(error => {
            console.error('API加载失败:', error);
            // 不使用后备数据源，保持空数组
            activities.value = [];
          });
        } else {
          // 如果没有axios，直接返回空数组
          activities.value = [];
        }
      } catch (error) {
        console.error('加载失败:', error)
        // 不使用模拟数据，保持空数组
        activities.value = []
      } finally {
        loading.value = false
      }
    }

    onMounted(() => {
      loadData()
    })

    return {
      loading,
      selectedYear,
      activities,
      years,
      filteredActivities,
      getYearCount,
      formatTimestamp,
      formatDate,
      getTimelineIcon,
      getTimelineColor,
      scrollToYear,
      viewCapsule
    }
  }
}
</script>

<style scoped>
.timeline {
  padding: 0;
  margin: 0;
  width: 100%;
  min-height: calc(100vh - 120px);
}

.timeline-header {
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

/* 年份筛选 */
.year-filter {
  display: flex;
  gap: 10px;
  margin-bottom: 20px;
  flex-wrap: wrap;
}

/* 快速导航 */
.quick-nav {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-bottom: 20px;
  padding: 12px;
  background: #f5f7fa;
  border-radius: 8px;
}

.nav-label {
  font-size: 14px;
  color: #666;
  white-space: nowrap;
}

.nav-buttons {
  display: flex;
  gap: 10px;
}

:deep(.el-scrollbar__wrap) {
  overflow-x: auto;
}

/* 时间轴容器 */
.timeline-container {
  margin-top: 20px;
}

/* 时间轴卡片 */
.timeline-card {
  cursor: pointer;
  transition: transform 0.3s ease, box-shadow 0.3s ease;
  margin-bottom: 10px;
}

.timeline-card:hover {
  transform: translateX(5px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
}

.card-content {
  display: flex;
  gap: 16px;
}

.card-cover {
  width: 120px;
  height: 120px;
  flex-shrink: 0;
  border-radius: 8px;
  overflow: hidden;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
}

.card-cover img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.card-info {
  flex: 1;
  min-width: 0;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 8px;
}

.card-header h4 {
  font-size: 18px;
  font-weight: 600;
  color: #333;
  margin: 0;
  flex: 1;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.card-description {
  color: #666;
  font-size: 14px;
  line-height: 1.6;
  margin: 0 0 12px 0;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.card-footer {
  display: flex;
  gap: 20px;
  font-size: 12px;
  color: #999;
  flex-wrap: wrap;
  align-items: center;
}

.card-status {
  display: flex;
  align-items: center;
  gap: 4px;
}

.card-date,
.card-open-date {
  display: flex;
  align-items: center;
  gap: 4px;
}

/* 响应式 */
@media (max-width: 768px) {
  .card-content {
    flex-direction: column;
  }

  .card-cover {
    width: 100%;
    height: 200px;
  }

  .timeline-header {
    flex-direction: column;
    gap: 16px;
  }
}
</style>