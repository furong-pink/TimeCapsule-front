<template>
  <div class="timeline">
    <div class="timeline-header">
      <div>
        <h2>时间轴</h2>
        <p>在这里，翻阅时光里的故事与未拆封的期待。</p>
      </div>
      <div class="filter-buttons">
        <el-select v-model="selectedCategory" placeholder="所有类别" size="default">
          <template #prefix>
            <el-icon><Filter /></el-icon>
          </template>
          <el-option label="所有类别" value="all"></el-option>
          <el-option label="公开胶囊" value="public"></el-option>
          <el-option label="私密胶囊" value="private"></el-option>
        </el-select>
        <el-select v-model="selectedYearRange" placeholder="时间范围" size="default">
          <template #prefix>
            <el-icon><Calendar /></el-icon>
          </template>
          <el-option label="近7天" value="7d"></el-option>
          <el-option label="近30天" value="30d"></el-option>
          <el-option label="近1年" value="1y"></el-option>
          <el-option label="近5年" value="5"></el-option>
          <el-option label="近10年" value="10"></el-option>
          <el-option label="全部" value="all"></el-option>
        </el-select>
      </div>
    </div>

    <!-- 时间轴内容 -->
    <div class="timeline-container" v-loading="loading">
      <el-empty v-if="!loading && filteredActivities.length === 0" description="还没有时间胶囊">
        <el-button type="primary" @click="$router.push('/capsule/create')">创建第一个胶囊</el-button>
      </el-empty>

      <div class="custom-timeline" v-else>
        <div class="timeline-line"></div>
        <div 
          v-for="(activity, index) in filteredActivities" 
          :key="activity.id || index"
          class="timeline-item"
          :class="{ 'left': index % 2 === 0, 'right': index % 2 === 1 }"
        >
          <!-- 时间节点 -->
          <div class="timeline-node" :class="{ 'opened': activity.isOpened }">
            <el-icon v-if="activity.isOpened"><Unlock /></el-icon>
            <el-icon v-else><Lock /></el-icon>
          </div>
          
          <!-- 时间标签 -->
          <div class="timeline-timestamp">{{ formatTimestamp(activity.timestamp || activity.date) }}</div>
          
          <!-- 内容卡片 -->
          <div class="timeline-card" @click="viewCapsule(activity)">
            <!-- 图片/占位区域 -->
            <div class="card-image-container">
              <!-- 已解锁且有图片 -->
              <div v-if="activity.isOpened && activity.coverImage" class="card-image-wrapper">
                <img 
                  :src="activity.coverImage" 
                  :alt="activity.title" 
                  class="card-image"
                  @error="handleImageError"
                />
              </div>
              <!-- 未解锁或已解锁但无图片 -->
              <div v-else class="card-placeholder">
                <svg v-if="!activity.isOpened" xmlns="http://www.w3.org/2000/svg" width="48" height="48" fill="currentColor" class="hourglass-icon" viewBox="0 0 16 16">
                  <path d="M2 1.5a.5.5 0 0 1 .5-.5h11a.5.5 0 0 1 0 1h-1v1a4.5 4.5 0 0 1-2.557 4.06c-.29.139-.443.377-.443.59v.7c0 .213.154.451.443.59A4.5 4.5 0 0 1 12.5 13v1h1a.5.5 0 0 1 0 1h-11a.5.5 0 1 1 0-1h1v-1a4.5 4.5 0 0 1 2.557-4.06c.29-.139.443-.377.443-.59v-.7c0-.213-.154-.451-.443-.59A4.5 4.5 0 0 1 3.5 3V2h-1a.5.5 0 0 1-.5-.5z"/>
                </svg>
                <div v-if="!activity.isOpened" class="placeholder-text">
                  {{ getTimeUntilOpen(activity.openDate || activity.open_date) }}
                </div>
              </div>
            </div>
            
            <!-- 卡片内容 -->
            <div class="card-content">
              <div class="card-header">
                <h4>{{ activity.title }}</h4>
                <div class="card-tags">
                  <el-tag size="small" v-for="tag in getTags(activity)" :key="tag" :type="getTagType(tag)">
                    {{ tag }}
                  </el-tag>
                </div>
              </div>
              <p class="card-description">{{ activity.content || activity.description }}</p>
              <!-- 按钮区域 -->
              <div class="card-actions">
                <el-button 
                  v-if="activity.isOpened"
                  type="primary" 
                  size="small" 
                  @click.stop="viewCapsule(activity)"
                >
                  查看胶囊
                </el-button>
                <el-button 
                  v-else
                  type="info" 
                  size="small" 
                  disabled
                >
                  {{ getTimeUntilOpen(activity.openDate || activity.open_date) }}
                </el-button>
                <!-- 开启按钮（仅在胶囊未开启且已到达开启日期时显示） -->
                <el-button 
                  v-if="isDueToOpen(activity.openDate || activity.open_date) && !activity.isOpened"
                  type="success" 
                  size="small" 
                  @click.stop="openCapsule(activity.id)"
                  :loading="openingCapsules[activity.id]"
                >
                  开启胶囊
                </el-button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    
    <!-- 加载更多 -->
    <div class="load-more" v-if="filteredActivities.length > 0">
      <el-button @click="loadMore" :loading="loadingMore">加载更多记忆</el-button>
    </div>
  </div>
</template>

<script>
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { Plus, Calendar, Clock, Unlock, Lock, Timer, Filter } from '@element-plus/icons-vue'

export default {
  name: 'Timeline',
  components: {
    Plus,
    Calendar,
    Clock,
    Unlock,
    Lock,
    Timer
  },
  setup() {
    const router = useRouter()
    const loading = ref(false)
    const loadingMore = ref(false)
    const selectedCategory = ref('all')
    const selectedYearRange = ref('5')
    const activities = ref([])
    const openingCapsules = ref({}) // 用于跟踪正在开启的胶囊

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
      let filtered = activities.value.filter(activity => {
        // 分类筛选
        if (selectedCategory.value !== 'all') {
          const privacy = (activity.privacy || '').toLowerCase()
          if (selectedCategory.value === 'public' && privacy !== 'public') {
            return false
          }
          if (selectedCategory.value === 'private' && privacy !== 'private') {
            return false
          }
        }
        
        // 年份范围筛选
        if (selectedYearRange.value !== 'all') {
          const date = activity.timestamp || activity.date
          if (date) {
            const year = new Date(date).getFullYear()
            const currentYear = new Date().getFullYear()
            const yearsAgo = parseInt(selectedYearRange.value)
            if (year < currentYear - yearsAgo) {
              return false
            }
          }
        }
        
        return true
      })
      
      // 按时间倒序排序
      return filtered.sort((a, b) => {
        const dateA = new Date(a.timestamp || a.date)
        const dateB = new Date(b.timestamp || b.date)
        return dateB - dateA
      })
    })

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

    // 检查是否到达开启日期
    const isDueToOpen = (openDate) => {
      if (!openDate) return false
      const openDateObj = new Date(openDate)
      const today = new Date()
      // 设置今天的时间为00:00:00，以便比较日期部分
      today.setHours(0, 0, 0, 0)
      return openDateObj <= today
    }

    // 计算距离开启时间还有多久
    const getTimeUntilOpen = (openDate) => {
      if (!openDate) return '未知开启时间'
      
      const openDateObj = new Date(openDate)
      const today = new Date()
      today.setHours(0, 0, 0, 0)
      
      if (openDateObj <= today) {
        return '已可开启'
      }
      
      const diffTime = openDateObj - today
      const diffYears = Math.floor(diffTime / (1000 * 60 * 60 * 24 * 365))
      const diffMonths = Math.floor((diffTime % (1000 * 60 * 60 * 24 * 365)) / (1000 * 60 * 60 * 24 * 30))
      
      if (diffYears > 0) {
        return `${diffYears}年${diffMonths}个月后开启`
      } else if (diffMonths > 0) {
        return `${diffMonths}个月后开启`
      } else {
        const diffDays = Math.floor(diffTime / (1000 * 60 * 60 * 24))
        return `${diffDays}天后开启`
      }
    }
    
    // 处理图片加载错误
    const handleImageError = (event) => {
      console.error('图片加载失败:', event.target.src);
      // 可以设置默认图片
      event.target.src = 'data:image/svg+xml;charset=utf-8,%3Csvg xmlns=%22http://www.w3.org/2000/svg%22 width=%22400%22 height=%22240%22 viewBox=%220 0 400 240%22%3E%3Crect width=%22400%22 height=%22240%22 fill=%22%23f0f0f0%22/%3E%3Ctext x=%22200%22 y=%22130%22 font-size=%2216%22 text-anchor=%22middle%22 fill=%22%23999%22%3E图片加载失败%3C/text%3E%3C/svg%3E';
    }

    // 获取胶囊标签
    const getTags = (activity) => {
      const tags = []
      if ((activity.privacy || '').toLowerCase() === 'public') {
        tags.push('公开')
      } else {
        tags.push('私密')
      }
      return tags
    }

    // 获取标签类型
    const getTagType = (tag) => {
      if (tag === '公开') {
        return 'success'
      }
      return 'info'
    }

    // 查看胶囊详情
    const viewCapsule = (activity) => {
      // 跳转到胶囊详情页
      if (activity.id) {
        // 检查胶囊是否已可开启（基于开启时间判断）
        if (isDueToOpen(activity.openDate || activity.open_date)) {
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

    // 开启时间胶囊
    const openCapsule = async (id) => {
      if (!id) return

      openingCapsules.value[id] = true
      try {
        if (window.$axios) {
          // 确保 ID 格式正确
          const capsuleId = typeof id === 'string' ? id.trim() : id
          
          const response = await window.$axios.post(`/capsules/${capsuleId}/open`)
          
          // 检查响应格式，支持多种格式
          const isSuccess = response?.code === 200 || response?.status === 200 || response?.data?.code === 200
          const message = response?.message || response?.data?.message || '开启成功'
          
          if (isSuccess) {
            window.$message ? window.$message.success('时间胶囊开启成功！') : alert('时间胶囊开启成功！')
            // 直接更新胶囊状态为已开启
            const capsule = activities.value.find(a => a.id === id)
            if (capsule) {
              capsule.isOpened = true
            }
            
            // 检查并更新成就
            try {
              const achievementResponse = await window.$axios.post('/achievements/check');
              if (achievementResponse?.code === 200 && achievementResponse?.data && achievementResponse.data.length > 0) {
                window.$message ? window.$message.success(`恭喜！获得了 ${achievementResponse.data.length} 个新成就`) : alert(`恭喜！获得了 ${achievementResponse.data.length} 个新成就`);
              }
            } catch (achievementError) {
              console.error('检查成就失败:', achievementError);
            }
          } else {
            console.error('开启失败，响应信息:', response)
            window.$message ? window.$message.error(message || '开启失败') : alert(message || '开启失败')
          }
        } else {
          window.$message ? window.$message.error('API不可用') : alert('API不可用')
        }
      } catch (error) {
        console.error('开启时间胶囊失败:', error)
        console.error('错误详情:', error?.response)
        // 提供更详细的错误信息
        if (error?.response?.status === 404) {
          window.$message ? window.$message.error('时间胶囊不存在或已被删除') : alert('时间胶囊不存在或已被删除')
        } else if (error?.response?.status === 403) {
          window.$message ? window.$message.error('无权限操作此时间胶囊') : alert('无权限操作此时间胶囊')
        } else {
          window.$message ? window.$message.error('开启时间胶囊失败') : alert('开启时间胶囊失败')
        }
      } finally {
        openingCapsules.value[id] = false
      }
    }

    // 加载数据
    const loadData = async () => {
      loading.value = true
      try {
        // 尝试从API加载
        if (window.$axios) {
          // 获取时间轴数据
          const response = await window.$axios.get('/capsules/timeline');
          
          // 调试：打印完整响应
          console.log('API响应:', response);
          
          if (response?.code === 200 && response?.data?.timeline) {
            // 调试：打印时间轴数据
            console.log('时间轴数据:', response.data.timeline);
            
            // 将时间轴数据转换为活动列表
            const timelineActivities = [];
            response.data.timeline.forEach(yearData => {
              console.log('年份数据:', yearData);
              yearData.capsules.forEach(capsule => {
                // 严格区分创建时间和开启时间
                const createTime = capsule.createdAt || capsule.created_at || capsule.date;
                const openTime = capsule.openDate || capsule.open_date;
                
                // 确保日期字段正确处理
                const processedCapsule = {
                  ...capsule,
                  timestamp: createTime, // 时间轴按创建时间排序显示
                  createTime: createTime, // 创建时间
                  openDate: openTime, // 开启时间
                  isOpened: capsule.isOpened || (capsule.status === 'OPENED'), // 开启状态，同时检查status字段
                  coverImage: capsule.coverImage || capsule.cover_image || '', // 确保coverImage字段存在
                  type: 'capsule'
                };
                
                // 调试：打印胶囊数据
                console.log('胶囊数据:', processedCapsule);
                timelineActivities.push(processedCapsule);
              });
            });
            activities.value = timelineActivities;
          } else {
            console.log('响应格式不正确:', response);
            activities.value = [];
          }
        } else {
          // 如果没有axios，直接返回空数组
          console.log('axios不可用');
          activities.value = [];
        }
      } catch (error) {
        console.error('加载失败:', error);
        console.error('错误详情:', error.response);
        // 不使用模拟数据，保持空数组
        activities.value = [];
      } finally {
        loading.value = false;
      }
    }

    // 加载更多
    const loadMore = async () => {
      // 这里可以实现分页加载逻辑
      loadingMore.value = true
      try {
        // 模拟加载更多
        await new Promise(resolve => setTimeout(resolve, 1000))
        // 实际项目中，这里应该调用API获取更多数据
      } catch (error) {
        console.error('加载更多失败:', error)
      } finally {
        loadingMore.value = false
      }
    }

    onMounted(() => {
      loadData()
    })

    return {
      loading,
      loadingMore,
      selectedCategory,
      selectedYearRange,
      activities,
      years,
      filteredActivities,
      formatTimestamp,
      formatDate,
      isDueToOpen,
      getTimeUntilOpen,
      getTags,
      getTagType,
      viewCapsule,
      openCapsule,
      openingCapsules,
      loadMore
    }
  }
}
</script>

<style scoped>
.timeline {
  padding: 0 20px;
  margin: 0 auto;
  width: 100%;
  max-width: 1200px;
  min-height: calc(100vh - 120px);
  background: linear-gradient(135deg, #f8f9ff 0%, #eef2ff 100%);
  overflow: hidden;
}

.timeline-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 40px;
  padding-top: 40px;
}

.timeline-header h2 {
  color: #333;
  font-size: 32px;
  font-weight: 700;
  margin: 0 0 12px 0;
  font-family: 'Arial', sans-serif;
}

.timeline-header p {
  color: #666;
  font-size: 16px;
  margin: 0;
  max-width: 600px;
}

/* 筛选按钮 */
.filter-buttons {
  display: flex;
  gap: 16px;
  align-items: center;
  padding: 12px 16px;
  background: transparent;
  border: none;
  border-radius: 12px;
  box-shadow: none;
}

/* 统一下拉选择器样式 */
.filter-buttons .el-select {
  --el-select-border-color-hover: #409eff;
  --el-select-input-focus-border-color: #409eff;
  min-width: 140px;
}

.filter-buttons .el-input__wrapper {
  border-radius: 12px;
  border-color: #dcdfe6;
  height: 36px;
  padding: 0 16px;
}

.filter-buttons .el-input__inner {
  line-height: 36px;
  height: 36px;
  color: #303133;
}

.filter-buttons .el-input__inner::placeholder {
  color: #909399;
  opacity: 1;
}

.filter-buttons .el-select__prefix {
  margin-right: 8px;
}

/* 时间轴容器 */
.timeline-container {
  margin-top: 60px;
  position: relative;
}

/* 自定义时间轴 */
.custom-timeline {
  position: relative;
  padding: 0;
}

/* 时间轴线 */
.timeline-line {
  position: absolute;
  left: 50%;
  top: 0;
  bottom: 0;
  width: 2px;
  background-color: #e4e7ed;
  transform: translateX(-50%);
}

/* 时间轴项目 */
.timeline-item {
  position: relative;
  margin-bottom: 60px;
  display: flex;
  align-items: flex-start;
}

/* 左侧项目 */
.timeline-item.left {
  flex-direction: row;
}

/* 右侧项目 */
.timeline-item.right {
  flex-direction: row-reverse;
}

/* 时间节点 */
.timeline-node {
  position: absolute;
  left: 50%;
  top: 20px;
  width: 24px;
  height: 24px;
  border-radius: 50%;
  background-color: #c0c4cc;
  display: flex;
  align-items: center;
  justify-content: center;
  transform: translateX(-50%);
  z-index: 1;
  transition: all 0.3s ease;
  box-shadow: 0 0 0 4px #fff;
}

/* 已开启的节点 */
.timeline-node.opened {
  background-color: #409eff;
  box-shadow: 0 0 0 4px rgba(64, 158, 255, 0.2);
}

/* 时间戳 */
.timeline-timestamp {
  position: absolute;
  left: 50%;
  top: 0;
  transform: translateX(-50%);
  font-size: 14px;
  font-weight: 600;
  color: #333;
  white-space: nowrap;
  background-color: #fff;
  padding: 0 16px;
  z-index: 2;
}

/* 时间轴卡片 */
.timeline-card {
  width: calc(50% - 60px);
  border-radius: 12px;
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.1);
  overflow: hidden;
  transition: all 0.3s ease;
  cursor: pointer;
  background-color: #fff;
  margin: 0 40px;
}

.timeline-card:hover {
  transform: translateY(-5px);
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.15);
}

/* 卡片图片容器 */
.card-image-container {
  width: 100%;
  height: 240px;
  position: relative;
  overflow: hidden;
  background-color: #f5f7fa;
}

/* 卡片图片包装器 */
.card-image-wrapper {
  width: 100%;
  height: 100%;
  position: relative;
  overflow: hidden;
  border-radius: 8px 8px 0 0;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}

/* 卡片图片 */
.card-image {
  width: 100%;
  height: 100%;
  object-fit: cover;
  transition: transform 0.3s ease, filter 0.3s ease;
  border-radius: 8px 8px 0 0;
}

.timeline-card:hover .card-image {
  transform: scale(1.05);
  filter: brightness(1.05) saturate(1.1);
}

/* 卡片占位图 */
.card-placeholder {
  width: 100%;
  height: 100%;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  background-color: #f0f0f0;
  color: #909399;
  position: relative;
  border-radius: 8px 8px 0 0;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}

.card-placeholder::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: linear-gradient(135deg, #f0f0f0 0%, #e0e0e0 100%);
  border-radius: 8px 8px 0 0;
}

/* 沙漏图标样式 */
.hourglass-icon {
  margin-bottom: 10px;
  color: #909399;
  width: 48px;
  height: 48px;
  z-index: 1;
  position: relative;
}

.card-placeholder .el-icon {
  font-size: 64px;
  margin-bottom: 16px;
  opacity: 0.4;
  z-index: 1;
  position: relative;
}

.placeholder-text {
  font-size: 16px;
  font-weight: 500;
  z-index: 1;
  position: relative;
  color: #666;
}

/* 卡片内容 */
.card-content {
  padding: 24px;
  display: flex;
  flex-direction: column;
  gap: 12px;
}

/* 卡片头部 */
.card-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  flex-wrap: wrap;
  gap: 12px;
}

.card-header h4 {
  font-size: 20px;
  font-weight: 600;
  color: #333;
  margin: 0;
  flex: 1;
  min-width: 0;
}

/* 卡片标签 */
.card-tags {
  display: flex;
  gap: 8px;
  flex-shrink: 0;
}

.card-tags .el-tag {
  border-radius: 4px;
  font-size: 12px;
  padding: 2px 8px;
}

/* 卡片描述 */
.card-description {
  color: #666;
  font-size: 16px;
  line-height: 1.6;
  margin: 0;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
  min-height: 0;
}

/* 卡片按钮 */
.card-actions {
  display: flex;
  gap: 8px;
  margin-top: 4px;
  padding-top: 16px;
  border-top: 1px solid #f0f0f0;
}

.card-actions .el-button {
  flex: 1;
  border-radius: 8px;
  font-size: 14px;
  padding: 10px 0;
}

/* 加载更多 */
.load-more {
  text-align: center;
  margin-top: 60px;
  margin-bottom: 40px;
}

.load-more .el-button {
  border-radius: 8px;
  padding: 12px 32px;
  font-size: 16px;
}

/* 响应式 */
@media (max-width: 768px) {
  .timeline {
    padding: 0 16px;
  }
  
  .timeline-header {
    flex-direction: column;
    gap: 20px;
    padding-top: 20px;
  }
  
  .timeline-header h2 {
    font-size: 24px;
  }
  
  .filter-buttons {
    width: 100%;
    justify-content: space-between;
  }
  
  .filter-buttons .el-select {
    flex: 1;
    min-width: 0;
  }
  
  .timeline-line {
    left: 30px;
  }
  
  .timeline-node {
    left: 30px;
  }
  
  .timeline-timestamp {
    left: 30px;
    transform: none;
    margin-left: 50px;
  }
  
  .timeline-item {
    flex-direction: row !important;
  }
  
  .timeline-card {
    width: calc(100% - 80px);
    margin-left: 60px;
    margin-right: 0;
  }
  
  .card-image-container {
    height: 180px;
  }
  
  .card-content {
    padding: 16px;
  }
  
  .card-header h4 {
    font-size: 18px;
  }
  
  .card-description {
    font-size: 14px;
  }
}

@media (max-width: 480px) {
  .timeline-card {
    width: calc(100% - 60px);
    margin-left: 40px;
  }
  
  .card-image-container {
    height: 150px;
  }
  
  .timeline-header h2 {
    font-size: 20px;
  }
  
  .timeline-header p {
    font-size: 14px;
  }
}
</style>