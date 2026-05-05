<!-- src/views/Home.vue -->
<template>
  <div class="home">
    <!-- 欢迎区域 -->
    <div class="welcome-section">
      <div class="welcome-content">
        <div class="welcome-left">
          <div class="welcome-back">欢迎回来，{{ userInfo.nickname || '用户' }}</div>
          <h1>
            封存此刻，<br>
            <span class="welcome-blue">写给未来的自己</span>
          </h1>
        </div>
      </div>
    </div>

    <!-- 加载状态 -->
    <div v-if="loading" class="loading-overlay">
      <el-spinner type="primary" size="large" />
      <p>加载中...</p>
    </div>

    <!-- 卡片区域容器 -->
    <el-container v-else>
      <el-main>
        <!-- 统计卡片 -->
        <el-row :gutter="20" class="stats-row">
          <el-col :xs="24" :sm="12" :md="8">
            <el-card class="stat-card">
              <div class="stat-content">
                <div class="stat-icon total">
                  <el-icon><Collection /></el-icon>
                </div>
                <div class="stat-info">
                  <div class="stat-label">胶囊总数</div>
                  <div class="stat-value">{{ capsuleCount }}</div>
                </div>
              </div>
            </el-card>
          </el-col>
          <el-col :xs="24" :sm="12" :md="8">
            <el-card class="stat-card upcoming-card">
              <div class="stat-content">
                <div class="upcoming-header">即将解锁</div>
                <div class="countdown">{{ countdown }}</div>
                <div v-if="upcomingCapsule" class="upcoming-details">
                  <div class="upcoming-title">"{{ upcomingCapsule.title }}"</div>
                  <div class="upcoming-info">
                    <div class="upcoming-date">计划于 {{ formatDate(upcomingCapsule.openDate || upcomingCapsule.open_date) }} 解锁</div>
                    <div class="upcoming-type" v-if="upcomingCapsule.privacy">
                      类型：{{ (upcomingCapsule.privacy || '').toLowerCase() === 'public' ? '公开' : '私密' }}
                    </div>

                  </div>
                </div>
                <div v-else class="upcoming-description">暂无即将解锁的胶囊</div>
              </div>
            </el-card>
          </el-col>
          <el-col :xs="24" :sm="12" :md="8">
            <el-card class="stat-card">
              <div class="stat-content">
                <div class="stat-icon completed">
                  <el-icon><Trophy /></el-icon>
                </div>
                <div class="stat-info">
                  <div class="stat-label">已完成目标</div>
                  <div class="stat-value">{{ completedGoals }}</div>
                </div>
              </div>
            </el-card>
          </el-col>
        </el-row>

        <!-- 内容区域 -->
        <el-row :gutter="20" class="content-row">
          <!-- 最近活动列表 -->
          <el-col :xs="24" :md="16">
            <div class="recent-activities-section">
              <div class="section-header">
                <h2 class="section-title">最近活动</h2>
              </div>
              <div class="activities-list">
                <div class="activity-card" v-for="(activity, index) in recentActivities" :key="index">
                  <div class="activity-icon">
                    <el-icon v-if="activity.type === 'capsule' && activity.action === 'create'" class="create-icon"><Plus /></el-icon>
                    <el-icon v-else-if="activity.type === 'capsule' && activity.action === 'open'" class="open-icon">🔓</el-icon>
                    <el-icon v-else-if="activity.type === 'goal' && (activity.action === 'update' || activity.action === 'complete')" class="complete-icon">✅</el-icon>
                  </div>
                  <div class="activity-content">
                    <div class="activity-title">
                      <span class="action-type">{{ getActionTypeText(activity.action) }}</span>
                      <span class="activity-name">{{ activity.title || activity.content || '未命名内容' }}</span>
                    </div>
                    <div class="activity-description">{{ activity.description || '暂无活动描述' }}</div>
                  </div>
                  <div class="activity-time">{{ activity.time || getTimeAgo(activity.date || activity.createdAt || new Date().toISOString()) }}</div>
                </div>
                <div v-if="recentActivities.length === 0" class="empty-activities">
                  <el-empty description="暂无活动" />
                </div>
              </div>
            </div>
          </el-col>

          <!-- 右侧小卡片 -->
          <el-col :xs="24" :md="8">
            <!-- 时光闪回 -->
            <el-card class="side-card">
              <template #header>
                <div class="card-header">
                  <span>时光闪回</span>
                </div>
              </template>
              <div class="memory-flashback">
                <div v-if="flashbackData" class="flashback-content">
                  <div class="flashback-date-badge">{{ getYearAgoLabel(flashbackData.date) }}</div>
                  <div class="flashback-image-placeholder"></div>
                  <h3 class="flashback-title">{{ flashbackData.title }}</h3>
                  <p class="flashback-description">{{ flashbackData.description || flashbackData.content }}</p>
                  <el-button type="primary" class="relive-button" @click="reliveMoment(flashbackData.id)">重温此刻</el-button>
                </div>
                <div v-else class="flashback-empty">
                  <p>暂无闪回记录</p>
                </div>
              </div>
            </el-card>

            <!-- 记忆提醒 -->
            <el-card class="side-card" style="margin-top: 20px">
              <template #header>
                <div class="card-header">
                  <span>记忆提醒</span>
                </div>
              </template>
              <div class="memory-prompt">
                <p class="prompt-text">"今天你学到了什么，是你10年后不想忘记的？"</p>
                <el-button type="primary" class="record-button">记录想法</el-button>
              </div>
            </el-card>
          </el-col>
        </el-row>
      </el-main>
    </el-container>
  </div>
</template>

<script>
import { User, Camera, Edit, Loading, Plus, Collection, Trophy, Cloudy, Timer } from '@element-plus/icons-vue'
import { ElMessage } from 'element-plus'

export default {
  name: 'Home',
  components: {
    User,
    Camera,
    Edit,
    Loading,
    Plus,
    Collection,
    Trophy,
    Cloudy,
    Timer
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
      completedGoals: 0,
      achievements: 0,
      capsuleCount: 0,
      // 最近活动数据
      recentActivities: [],
      // 所有活动数据
      allActivities: [],

      // 时光闪回数据
      flashbackData: null,
      // 胶囊数量增长率
      capsuleGrowthRate: null,
      // 即将解锁的胶囊数据
      upcomingCapsule: null,
      countdown: '',
      // 日历相关数据
      currentDate: new Date(),
      weekdays: ['日', '一', '二', '三', '四', '五', '六'],
      // 悬浮提示相关数据
      tooltipVisible: false,
      tooltipDate: null,
      tooltipStyle: {},
      showEventDetails: null,
      isTooltipHovered: false,
      hideTooltipTimer: null,
      // 日期选择相关数据
      selectedDate: null,
      // 是否正在查询即将解锁的胶囊
      isCheckingUpcoming: false,
      // 上次查询API的时间戳
      lastApiCheckTime: 0,
      // 监控指标
      monitoring: {
        apiCalls: 0,
        apiErrors: 0,
        averageResponseTime: 0,
        lastApiCallTime: 0
      },
      // 内存监控
      memoryMonitor: {
        currentUsage: 0,
        peakUsage: 0,
        warningThreshold: 80, // 内存使用警告阈值（百分比）
        memoryCheckInterval: null
      }
    }
  },

  
  computed: {
    recentCapsules() {
      // 返回最近6个时间胶囊，排除目标事件
      const capsuleItems = this.capsules.filter(item => {
        // 只包含非目标类型的项目（即时间胶囊）
        return !item.type || item.type === undefined || item.type === 'capsule';
      });
      
      return capsuleItems.slice(0, 6).map(capsule => ({
        ...capsule,
        cover: capsule.coverImage || capsule.cover || '',
        preview: capsule.content?.substring(0, 50) || ''
      }))
    },
    todayGoalProgress() {
      // 计算今日目标完成进度（示例：如果有今日创建的胶囊则100%）
      const today = this.formatDateWithoutTime(new Date())
      const todayCapsules = this.capsules.filter(c => {
        // 检查多种可能的日期字段
        const capsuleDate = c.date || c.createdAt || c.created_at || c.openDate || c.open_date;
        if (!capsuleDate) return false;
        // 提取日期部分进行比较
        const dateStr = this.formatDateWithoutTime(new Date(capsuleDate));
        return dateStr === today;
      });
      return todayCapsules.length > 0 ? 100 : 0
    },
    // 日历相关计算属性
    currentMonthYear() {
      return `${this.currentDate.getFullYear()}年${this.currentDate.getMonth() + 1}月`;
    },
    days() {
      const year = this.currentDate.getFullYear();
      const month = this.currentDate.getMonth();
      
      // 获取当月第一天和最后一天
      const firstDay = new Date(year, month, 1);
      const lastDay = new Date(year, month + 1, 0);
      
      // 获取当月第一天是星期几
      const firstDayOfWeek = firstDay.getDay();
      
      // 获取当月总天数
      const daysInMonth = lastDay.getDate();
      
      // 生成日历天数数组
      const days = [];
      
      // 添加上个月的日期
      const prevMonthLastDay = new Date(year, month, 0).getDate();
      for (let i = firstDayOfWeek - 1; i >= 0; i--) {
        const date = new Date(year, month - 1, prevMonthLastDay - i);
        days.push({
          date,
          isOtherMonth: true,
          isToday: false,
          hasEvent: this.hasEventOnDate(date),
          hasCapsuleEvent: this.hasCapsuleEventOnDate(date),
          hasGoalEvent: this.hasGoalEventOnDate(date),
          hasGoalCompletedEvent: this.hasGoalCompletedEventOnDate(date)
        });
      }
      
      // 添加当月的日期
      const today = new Date();
      for (let day = 1; day <= daysInMonth; day++) {
        const date = new Date(year, month, day);
        days.push({
          date,
          isOtherMonth: false,
          isToday: date.toDateString() === today.toDateString(),
          hasEvent: this.hasEventOnDate(date),
          hasCapsuleEvent: this.hasCapsuleEventOnDate(date),
          hasGoalEvent: this.hasGoalEventOnDate(date),
          hasGoalCompletedEvent: this.hasGoalCompletedEventOnDate(date)
        });
      }
      
      // 添加下个月的日期
      const remainingDays = 42 - days.length; // 6行7列共42个格子
      for (let day = 1; day <= remainingDays; day++) {
        const date = new Date(year, month + 1, day);
        days.push({
          date,
          isOtherMonth: true,
          isToday: false,
          hasEvent: this.hasEventOnDate(date),
          hasCapsuleEvent: this.hasCapsuleEventOnDate(date),
          hasGoalEvent: this.hasGoalEventOnDate(date),
          hasGoalCompletedEvent: this.hasGoalCompletedEventOnDate(date)
        });
      }
      
      return days;
    }
  },
  
  async mounted() {
    if (process.env.NODE_ENV === 'development') {
      console.log('Home组件挂载');
    }
    await this.loadUserInfo()
    this.fetchData()
    await this.fetchFlashbackData()
    
    // 监听localStorage变化，用于接收胶囊创建通知
    window.addEventListener('storage', this.handleStorageChange);
    
    // 设置定时器，每1分钟检查一次即将解锁的胶囊
    this.checkUpcomingInterval = setInterval(() => {
      this.findUpcomingCapsule();
    }, 60000); // 60秒
    
    // 初始化内存监控
    this.initMemoryMonitor();
  },
  
  beforeUnmount() {
    // 移除事件监听
    window.removeEventListener('storage', this.handleStorageChange);
    // 清除定时器
    if (this.hideTooltipTimer) {
      clearTimeout(this.hideTooltipTimer);
    }
    // 清除检查即将解锁胶囊的定时器
    if (this.checkUpcomingInterval) {
      clearInterval(this.checkUpcomingInterval);
    }
    // 停止内存监控
    this.stopMemoryMonitor();
  },
  
  methods: {
    normalizeRecordList(responseData) {
      if (!responseData) return [];
      if (Array.isArray(responseData)) return responseData;
      if (Array.isArray(responseData.records)) return responseData.records;
      if (Array.isArray(responseData.list)) return responseData.list;
      return [];
    },
    getCurrentUserId() {
      const directUserId = localStorage.getItem('userId');
      if (directUserId !== null && directUserId !== undefined && directUserId !== '') {
        return String(directUserId);
      }
      try {
        const userRaw = localStorage.getItem('user');
        if (!userRaw) return null;
        const user = JSON.parse(userRaw);
        const userId = user?.id ?? user?.userId;
        return userId === null || userId === undefined ? null : String(userId);
      } catch (error) {
        return null;
      }
    },
    isCurrentUserCapsule(capsule, currentUserId) {
      if (!capsule) return false;
      if (currentUserId === null || currentUserId === undefined) return false;
      const ownerId = capsule.userId ?? capsule.user_id ?? capsule.creatorId ?? capsule.creator_id;
      // 对于已登录且接口天然按当前用户返回的场景，兼容后端未返回 owner 字段
      if (ownerId === null || ownerId === undefined) return true;
      return String(ownerId) === String(currentUserId);
    },
    isCurrentUserGoal(goal, currentUserId) {
      if (!goal) return false;
      if (currentUserId === null || currentUserId === undefined) return false;
      const ownerId = goal.userId ?? goal.user_id ?? goal.creatorId ?? goal.creator_id ?? goal.ownerId ?? goal.owner_id;
      // 对于 /goals 这类用户级接口，兼容无 owner 字段返回
      if (ownerId === null || ownerId === undefined) return true;
      return String(ownerId) === String(currentUserId);
    },
    normalizeActivityItem(activity) {
      const rawType = String(activity?.type || '').toLowerCase();
      const normalizedType = rawType.includes('goal') ? 'goal' : 'capsule';
      const rawAction = String(activity?.action || '').toLowerCase();
      const normalizedAction = rawType.includes('complete') || rawAction.includes('complete')
        ? 'complete'
        : (rawType.includes('open') || rawAction.includes('open') ? 'open' : 'create');
      const itemTitle = activity?.content || activity?.title || activity?.name || '';
      const actionText = normalizedType === 'goal'
        ? (normalizedAction === 'complete' ? '完成了目标' : '创建了目标')
        : (normalizedAction === 'open' ? '开启了胶囊' : '创建了胶囊');
      const date = activity?.createdAt || activity?.date || activity?.time || new Date().toISOString();
      return {
        ...activity,
        type: normalizedType,
        action: normalizedAction,
        title: itemTitle,
        description: `${actionText}${itemTitle ? `：${itemTitle}` : ''}`,
        date,
        time: this.getTimeAgo(date)
      };
    },
    // 处理日期鼠标进入事件
    handleDayMouseEnter(event, day) {
      // 清除之前的定时器
      if (this.hideTooltipTimer) {
        clearTimeout(this.hideTooltipTimer);
      }
      
      // 立即显示弹窗
      this.tooltipVisible = true;
      this.tooltipDate = day.date;
      
      // 计算工具提示的位置
      const rect = event.target.getBoundingClientRect();
      const isSelected = this.selectedDate && this.formatDateWithoutTime(this.selectedDate) === this.formatDateWithoutTime(day.date);
      const tooltipWidth = isSelected ? 300 : 240;
      
      let left = rect.left + rect.width / 2 - tooltipWidth / 2;
      
      // 防止超出视口左侧
      if (left < 10) left = 10;
      // 防止超出视口右侧
      const maxLeft = window.innerWidth - tooltipWidth - 10;
      if (left > maxLeft) left = maxLeft;
      
      // 调整弹窗位置，确保不覆盖日期元素但保持足够接近
      this.tooltipStyle = {
        top: rect.bottom + 2 + 'px',
        left: left + 'px'
      };
    },
    
    // 处理日期鼠标离开事件
    handleDayMouseLeave() {
      // 只有当鼠标也不在弹窗上时才关闭
      if (!this.isTooltipHovered) {
        this.hideTooltip();
      }
    },
    
    // 处理弹窗鼠标进入事件
    handleTooltipMouseEnter() {
      this.isTooltipHovered = true;
    },
    
    // 处理弹窗鼠标离开事件
    handleTooltipMouseLeave() {
      this.isTooltipHovered = false;
      // 立即关闭弹窗
      this.hideTooltip();
    },
    
    // 隐藏弹窗
    hideTooltip() {
      this.tooltipVisible = false;
      this.isTooltipHovered = false;
    },
    
    hasEventsOnDate(date) {
      const dateStr = this.formatDateWithoutTime(date);
      return this.capsules.some(c => {
        const capsuleDate = c.date || c.createdAt || c.created_at || c.openDate || c.open_date;
        if (!capsuleDate) return false;
        const capsuleDateStr = this.formatDateWithoutTime(new Date(capsuleDate));
        return capsuleDateStr === dateStr;
      });
    },
    
    // 获取聚合后的事件数据（按开启时间/完成时间归类）
    getAggregatedEventsOnDate(date) {
      const dateStr = this.formatDateWithoutTime(date);
      const events = this.capsules.filter(item => {
        // 处理胶囊事件
        if (!item.type || item.type === undefined || item.type === 'capsule') {
          // 严格使用 openDate/open_date（开启时间），如果没有则使用创建时间
          const capsuleDate = item.openDate || item.open_date || item.date || item.createdAt || item.created_at;
          if (!capsuleDate) return false;
          const capsuleDateStr = this.formatDateWithoutTime(new Date(capsuleDate));
          return capsuleDateStr === dateStr;
        }
        // 处理目标事件
        else if (item.type === 'goal') {
          // 根据子类型决定日期字段
          let eventDate;
          if (item.subtype === 'completed') {
            // 目标完成事件使用完成日期
            eventDate = item.date;
          } else {
            // 默认使用创建日期
            eventDate = item.date || item.createdAt || item.createTime || item.created_at;
          }
          if (!eventDate) return false;
          const eventDateStr = this.formatDateWithoutTime(new Date(eventDate));
          return eventDateStr === dateStr;
        }
        return false;
      });
      
      // 按类型聚合事件
      const aggregated = {
        capsules: [],
        goals: []
      };
      
      events.forEach(event => {
        if (!event.type || event.type === undefined || event.type === 'capsule') {
          aggregated.capsules.push(event);
        } else if (event.type === 'goal') {
          aggregated.goals.push(event);
        }
      });
      
      return aggregated;
    },
    
    // 获取指定类型的事件列表
    getEventsByType(date, type) {
      const aggregated = this.getAggregatedEventsOnDate(date);
      return type === 'capsule' ? aggregated.capsules : aggregated.goals;
    },
    
    // 日历相关方法
    prevMonth() {
      this.currentDate = new Date(this.currentDate.getFullYear(), this.currentDate.getMonth() - 1, 1);
    },
    
    nextMonth() {
      this.currentDate = new Date(this.currentDate.getFullYear(), this.currentDate.getMonth() + 1, 1);
    },
    
    selectDate(date) {
      // 存储选中的日期
      this.selectedDate = date;
      console.log('选中日期:', date);
    },
    
    hasEventOnDate(date) {
      // 检查指定日期是否有事件（例如：创建了时间胶囊或完成目标）
      // 这里可以根据实际业务需求实现
      const dateStr = this.formatDateWithoutTime(date);
      
      // 检查当天是否有胶囊创建
      const capsulesOnDate = this.capsules.filter(c => {
        const capsuleDate = c.date || c.createdAt || c.created_at || c.openDate || c.open_date;
        if (!capsuleDate) return false;
        const capsuleDateStr = this.formatDateWithoutTime(new Date(capsuleDate));
        return capsuleDateStr === dateStr;
      });
      
      // 检查当天是否有目标完成（可以根据实际业务逻辑调整）
      
      return capsulesOnDate.length > 0;
    },
    
    // 辅助方法：格式化日期为 YYYY-MM-DD 格式，不考虑时间
    formatDateWithoutTime(date) {
      // 确保输入是日期对象
      if (typeof date === 'string') {
        if (date.includes('-') && date.length === 10) {
          // 如果是yyyy-MM-dd格式的日期字符串，直接返回
          return date;
        }
        date = new Date(date);
      }
      // 使用本地时间方法确保日期与用户本地时区一致
      const year = date.getFullYear();
      const month = String(date.getMonth() + 1).padStart(2, '0');
      const day = String(date.getDate()).padStart(2, '0');
      return `${year}-${month}-${day}`;
    },
    
    // 辅助方法：格式化事件时间
    formatEventTime(event) {
      const dateField = event.date || event.createdAt || event.created_at || event.openDate || event.open_date;
      if (!dateField) return '';
      
      const date = new Date(dateField);
      const hours = String(date.getHours()).padStart(2, '0');
      const minutes = String(date.getMinutes()).padStart(2, '0');
      return `${hours}:${minutes}`;
    },
    
    // 检查指定日期是否有胶囊事件（按开启时间）
    hasCapsuleEventOnDate(date) {
      const dateStr = this.formatDateWithoutTime(date);
      return this.capsules.some(item => {
        // 检查是否是胶囊类型
        if (!item.type || item.type === undefined || item.type === 'capsule') {
          // 优先使用 openDate/open_date（开启时间），如果没有则使用创建时间
          const capsuleDate = item.openDate || item.open_date || item.date || item.createdAt || item.created_at;
          if (!capsuleDate) return false;
          const capsuleDateStr = this.formatDateWithoutTime(new Date(capsuleDate));
          return capsuleDateStr === dateStr;
        }
        return false;
      });
    },
    
    // 检查指定日期是否有目标事件
    hasGoalEventOnDate(date) {
      const dateStr = this.formatDateWithoutTime(date);
      return this.capsules.some(item => {
        // 检查是否是目标类型
        if (item.type === 'goal') {
          const goalDate = item.createdAt || item.createTime || item.created_at || item.date;
          if (!goalDate) return false;
          const goalDateStr = this.formatDateWithoutTime(new Date(goalDate));
          return goalDateStr === dateStr;
        }
        return false;
      });
    },
    
    // 检查指定日期是否有目标完成事件
    hasGoalCompletedEventOnDate(date) {
      const dateStr = this.formatDateWithoutTime(date);
      return this.capsules.some(item => {
        // 检查是否是目标完成类型
        if (item.type === 'goal' && item.subtype === 'completed') {
          const goalDate = item.date;
          if (!goalDate) return false;
          const goalDateStr = this.formatDateWithoutTime(new Date(goalDate));
          return goalDateStr === dateStr;
        }
        return false;
      });
    },
    
    // 计算目标完成所用天数
    calculateGoalDuration(startDateStr, endDateStr) {
      const startDate = new Date(startDateStr);
      const endDate = new Date(endDateStr);
      
      // 计算相差的天数，加1是因为包含开始和结束的当天
      const timeDiff = endDate.getTime() - startDate.getTime();
      const daysDiff = Math.ceil(timeDiff / (1000 * 3600 * 24)) + 1;
      
      return Math.max(1, daysDiff); // 至少返回1天
    },
    
    handleStorageChange(e) {
      if (e.key === 'capsuleCreated' && e.newValue) {
        // 当检测到胶囊创建事件时，重新获取数据
        this.fetchData();
      } else if (e.key === 'goalCreated' && e.newValue) {
        // 当检测到目标创建事件时，重新获取数据
        this.fetchData();
      } else if (e.key === 'goalCompleted' && e.newValue) {
        // 当检测到目标完成事件时，重新获取数据
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
    // 获取时光闪回数据
    async fetchFlashbackData() {
      try {
        const axios = window.$axios || this.$axios;
        if (axios) {
          // 尝试从API获取最新的想法/胶囊数据
          try {
            // 暂时注释掉这个API调用，因为后端还没有实现
            // const response = await axios.get('/api/capsules/latest');
            // if (response?.data) {
            //   this.flashbackData = response.data;
            //   console.log('获取到时光闪回数据:', this.flashbackData);
            // } else {
            //   // 如果没有API，尝试从本地胶囊数据中获取最新的一条
            //   this.getLocalFlashbackData();
            // }
            // 直接从本地数据获取
            this.getLocalFlashbackData();
          } catch (error) {
            console.error('获取时光闪回数据失败:', error);
            // 失败时尝试从本地数据获取
            this.getLocalFlashbackData();
          }
        } else {
          // 如果没有axios，尝试从本地胶囊数据中获取
          this.getLocalFlashbackData();
        }
      } catch (error) {
        console.error('获取时光闪回数据失败:', error);
        // 失败时尝试从本地数据获取
        this.getLocalFlashbackData();
      }
    },

    // 从本地胶囊数据中获取最新的一条作为时光闪回
    getLocalFlashbackData() {
      // 过滤出胶囊类型的数据
      const capsules = this.capsules.filter(item => {
        return !item.type || item.type === 'capsule';
      });
      
      if (capsules.length > 0) {
        // 按日期排序，取最新的一条
        capsules.sort((a, b) => {
          const dateA = new Date(a.createdAt || a.created_at || a.date || 0);
          const dateB = new Date(b.createdAt || b.created_at || b.date || 0);
          return dateB - dateA;
        });
        this.flashbackData = capsules[0];
        console.log('从本地数据获取时光闪回:', this.flashbackData);
      } else {
        this.flashbackData = null;
      }
    },

    // 计算X年前的今天标签
    getYearAgoLabel(dateString) {
      if (!dateString) return '';
      
      const date = new Date(dateString);
      const now = new Date();
      
      const yearDiff = now.getFullYear() - date.getFullYear();
      const monthDiff = now.getMonth() - date.getMonth();
      const dayDiff = now.getDate() - date.getDate();
      
      // 检查是否是X年前的今天
      if (monthDiff === 0 && dayDiff === 0) {
        return `${yearDiff}年前的今天`;
      } else {
        return '';
      }
    },

    // 重温此刻，跳转到胶囊详情页
    reliveMoment(capsuleId) {
      // 这里可以实现跳转到胶囊详情页的逻辑
      console.log('跳转到胶囊详情页:', capsuleId);
      // 示例：window.location.href = `/capsule/${capsuleId}`;
    },

    async loadUserInfo() {
      // 优先从服务器获取最新的用户信息
      if (window.$axios) {
        try {
          const response = await window.$axios.get('/users/profile');
          if (response?.code === 200 && response?.data) {
            const userData = response.data;
            if (userData.id !== null && userData.id !== undefined) {
              localStorage.setItem('userId', String(userData.id));
            }
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
        // 确保axios可用
        const axios = window.$axios || this.$axios;
        const currentUserId = this.getCurrentUserId();
        if (axios) {
          // 直接获取完整的时间胶囊列表
          try {
            const capsulesResponse = await axios.get('/capsules');
            const capsuleRecords = this.normalizeRecordList(capsulesResponse?.data);
            if (capsulesResponse?.code === 200 && capsuleRecords.length > 0) {
              this.capsules = capsuleRecords.filter(item => this.isCurrentUserCapsule(item, currentUserId));
              // 计算真正的胶囊数量（不包括目标数据）
              this.capsuleCount = this.capsules.filter(item => {
                return !item.type || item.type === 'capsule';
              }).length;
              console.log('使用capsules API数据（当前用户）:', this.capsules);
              console.log('胶囊总数:', this.capsuleCount);
            } else {
              this.capsules = [];
              this.capsuleCount = 0;
            }
          } catch (error) {
            console.error('获取胶囊列表失败:', error);
            this.capsules = [];
            this.capsuleCount = 0;
          }
          
          // 单独获取统计信息
          try {
            const statsResponse = await axios.get('/statistics/home');
            if (statsResponse?.code === 200 && statsResponse?.data) {
              this.completedGoals = statsResponse.data.completedGoals || 0;
              this.achievements = statsResponse.data.achievements || 0;
              // 如果统计数据中有胶囊数量，使用它
              if (statsResponse.data.capsuleCount !== undefined) {
                this.capsuleCount = statsResponse.data.capsuleCount;
                console.log('从统计API获取胶囊总数:', this.capsuleCount);
              }
              // 获取胶囊数量增长率
              if (statsResponse.data.capsuleGrowthRate !== undefined) {
                this.capsuleGrowthRate = statsResponse.data.capsuleGrowthRate;
                console.log('从统计API获取胶囊增长率:', this.capsuleGrowthRate);
              } else {
                // 尝试计算增长率
                this.calculateCapsuleGrowthRate();
              }
            }
          } catch (statsError) {
            console.error('获取统计数据失败:', statsError);
            // 尝试从胶囊和目标数据中计算统计信息
            this.calculateStats();
            // 尝试计算增长率
            this.calculateCapsuleGrowthRate();
          }
          
          // 参考时间轴组件，使用timeline API获取胶囊数据
          try {
            const timelineResponse = await axios.get('/capsules/timeline');
            if (timelineResponse?.code === 200 && timelineResponse?.data?.timeline) {
              // 从时间轴数据中提取胶囊
              const timelineCapsules = [];
              timelineResponse.data.timeline.forEach(yearData => {
                yearData.capsules.forEach(capsule => {
                  timelineCapsules.push({
                    ...capsule,
                    type: 'capsule'
                  });
                });
              });
              
              // 过滤出当前用户的胶囊（首页只能看到自己的胶囊）
              const userTimelineCapsules = timelineCapsules.filter(capsule =>
                this.isCurrentUserCapsule(capsule, currentUserId)
              );
              
              // 如果从capsules接口获取的数据为空，使用过滤后的时间轴API的数据
              if (this.capsules.length === 0 && userTimelineCapsules.length > 0) {
                this.capsules = userTimelineCapsules;
                console.log('使用过滤后的timeline API的胶囊数据:', userTimelineCapsules);
              }
              
              // 计算过滤后的胶囊数量
              if (userTimelineCapsules.length > 0) {
                this.capsuleCount = userTimelineCapsules.length;
                console.log('从过滤后的timeline API获取胶囊总数:', this.capsuleCount);
              }
            }
          } catch (timelineError) {
            console.error('获取时间轴数据失败:', timelineError);
            // 继续使用之前的胶囊数量
          }
          
          // 生成最近活动
          this.generateRecentActivities();
          
          // 获取最近活动
          try {
            const activitiesResponse = await axios.get('/activities/recent', { params: { limit: 3 } });
            const activityRecords = this.normalizeRecordList(activitiesResponse?.data);
            const currentUserActivities = (currentUserId === null || currentUserId === undefined)
              ? activityRecords
              : activityRecords.filter(item =>
                this.isCurrentUserCapsule(item, currentUserId) || this.isCurrentUserGoal(item, currentUserId)
              );
            if (activitiesResponse?.code === 200 && currentUserActivities.length > 0) {
              // 先保存接口活动，最终会与本地生成活动合并，避免只显示目标/只显示胶囊
              this.allActivities = currentUserActivities.map(item => this.normalizeActivityItem(item));
              console.log('从API获取最近活动（当前用户）:', currentUserActivities);
            }
          } catch (activitiesError) {
            console.error('获取最近活动失败:', activitiesError);
          }
          
          // 再次生成最近活动，确保合并API活动和本地活动
          this.generateRecentActivities();
          
          // 获取存档健康度 - 暂时注释掉，因为后端还没有实现
          /*
          try {
            const storageResponse = await axios.get('/api/storage/usage');
            if (storageResponse?.data) {
              this.storageUsage = storageResponse.data.usagePercentage || 0;
              this.lastSyncTime = storageResponse.data.lastSyncTime || '';
            }
          } catch (storageError) {
            console.error('获取存档健康度失败:', storageError);
            this.storageUsage = 0;
            this.lastSyncTime = '';
          }
          */
          // 直接设置默认值
          this.storageUsage = 0;
          this.lastSyncTime = '';
          
          // 获取即将解锁的胶囊
          try {
            const upcomingResponse = await axios.get('/capsules/upcoming');
            if (upcomingResponse?.code === 200 && upcomingResponse?.data && this.isCurrentUserCapsule(upcomingResponse.data, currentUserId)) {
              this.upcomingCapsule = upcomingResponse.data;
              // 计算倒计时
              if (this.upcomingCapsule?.openDate || this.upcomingCapsule?.open_date) {
                this.calculateCountdown(this.upcomingCapsule.openDate || this.upcomingCapsule.open_date);
              }
              console.log('即将解锁的胶囊:', this.upcomingCapsule);
            } else {
              // 如果API失败，从本地数据查找即将解锁的胶囊
              this.findUpcomingCapsule();
            }
          } catch (upcomingError) {
            console.error('获取即将解锁的胶囊失败:', upcomingError);
            // 从本地数据查找即将解锁的胶囊
            this.findUpcomingCapsule();
          }
          
          // 获取目标数据用于日历显示
          try {
            // 取较大分页，并优先使用后端返回的全量统计值
            const goalsResponse = await axios.get('/goals', { params: { page: 0, size: 1000 } });
            const normalizedGoalRecords = this.normalizeRecordList(goalsResponse?.data);
            const goalRecords = normalizedGoalRecords.length > 0
              ? normalizedGoalRecords
              : (Array.isArray(goalsResponse?.data?.goals) ? goalsResponse.data.goals : []);
            const apiCompletedGoalCount = Number(goalsResponse?.data?.statistics?.completed);
            if (Number.isFinite(apiCompletedGoalCount) && apiCompletedGoalCount >= 0) {
              this.completedGoals = apiCompletedGoalCount;
            }
            if (Array.isArray(goalRecords)) {
              // 将目标数据添加到capsules数组中，以便在日历上显示
              const goals = (currentUserId === null || currentUserId === undefined)
                ? goalRecords
                : goalRecords.filter(goal => this.isCurrentUserGoal(goal, currentUserId));
              const completedGoalCount = goals.filter(goal => {
                const status = (goal.status || '').toString().toUpperCase();
                return status === 'COMPLETED';
              }).length;
              
              // 创建目标事件数组
              let goalEvents = [];
              
              // 为目标创建和完成创建单独的事件
              goals.forEach(goal => {
                // 添加目标创建事件
                goalEvents.push({
                  ...goal,
                  id: `${goal.id}-created`,
                  type: 'goal',
                  subtype: 'created',
                  title: `创建: ${goal.title}`,
                  description: `创建了新目标: ${goal.title}`,
                  action: 'create',
                  time: this.getTimeAgo(goal.createdAt || goal.createTime || goal.created_at || new Date().toISOString()),
                  date: goal.createdAt || goal.createTime || goal.created_at || new Date().toISOString(),
                  originalId: goal.id
                });
                
                // 如果目标已完成，添加目标完成事件
                const completedAt = goal.completedAt || goal.completed_at;
                if (goal.status === 'COMPLETED' || goal.status === 'completed') {
                  const completedDate = completedAt || goal.updatedAt || goal.updated_at || goal.date || goal.createdAt || goal.created_at || new Date().toISOString();
                  goalEvents.push({
                    ...goal,
                    id: `${goal.id}-completed`,
                    type: 'goal',
                    subtype: 'completed',
                    title: `完成: ${goal.title}`,
                    description: `完成了目标: ${goal.title}`,
                    action: 'complete',
                    time: this.getTimeAgo(completedDate),
                    date: completedDate,
                    createdAt: goal.createdAt || goal.createTime || goal.created_at || new Date().toISOString(),
                    completedAt: completedDate,
                    originalId: goal.id
                  });
                }
              });
              
              // 保存原始胶囊数据，用于后续计算
              const originalCapsules = [...this.capsules];
              
              // 将目标事件合并到capsules数组中
              this.capsules = [...this.capsules, ...goalEvents];
              
              console.log('加载的目标数据:', goals);
              
              // 重新计算所有统计数据，确保数据同步
              // 计算已完成目标数
              if (!(Number.isFinite(apiCompletedGoalCount) && apiCompletedGoalCount >= 0)) {
                this.completedGoals = completedGoalCount;
              }
              
              // 重新查找即将解锁的胶囊
              this.findUpcomingCapsule();
              
              // 重新生成最近活动，包含胶囊和目标，并与接口活动合并去重
              this.generateRecentActivities();
              
              console.log('重新计算后已完成目标数:', this.completedGoals);
              console.log('合并目标数据后的capsules数组:', this.capsules);
              console.log('重新生成的最近活动:', this.recentActivities);
            }
          } catch (goalsError) {
            console.error('获取目标数据失败:', goalsError);
          }
          // 首页统计统一以当前用户过滤后的本地数据为准，避免展示到其他用户口径
          this.capsuleCount = this.capsules.filter(item => !item.type || item.type === 'capsule').length;
          const localCompletedGoalCount = this.capsules.filter(item => {
            if (item.type !== 'goal') return false;
            const status = (item.status || '').toString().toUpperCase();
            return item.subtype === 'completed' || status === 'COMPLETED';
          }).length;
          // 仅在还没有可信统计时才使用本地重算，避免覆盖后端全量统计
          if (!Number.isFinite(this.completedGoals) || this.completedGoals < 0) {
            this.completedGoals = Math.max(0, localCompletedGoalCount);
          }
        } else {
          // 如果没有axios，使用fetch
          try {
            const response = await fetch('/api/capsules.json')
            const data = await response.json()
            this.capsules = data || []
            this.capsuleCount = this.capsules.length;
            // 生成最近活动
            this.generateRecentActivities();
            // 查找即将解锁的胶囊
            this.findUpcomingCapsule();
            // 计算统计信息
            this.calculateStats();
          } catch (fetchError) {
            console.error('使用fetch获取数据失败:', fetchError);
            this.capsules = [];
            this.capsuleCount = 0;
            this.recentActivities = [];
          }
        }
        console.log('最终胶囊总数:', this.capsuleCount);
        console.log('API返回的胶囊数据:', this.capsules);
        console.log('最近活动数据:', this.recentActivities);
        this.loading = false
      } catch (error) {
        console.error('加载失败:', error)
        // 不使用模拟数据，保持空数组
        this.capsules = []
        this.recentActivities = []
        this.storageUsage = 0
        this.lastSyncTime = ''
        this.upcomingCapsule = null
        this.countdown = ''
        this.loading = false
        // 显示错误提示
        ElMessage.error('数据加载失败，请稍后重试')
        console.log('API加载失败，数据设置为空')
      }
    },
    
    // 计算统计信息
    calculateStats() {
      // 从capsules数组中计算已完成目标数
      const completedGoals = this.capsules.filter(item => {
        return item.type === 'goal' && item.subtype === 'completed';
      }).length;
      
      // 重新计算胶囊总数（不包括目标数据）
      this.capsuleCount = this.capsules.filter(item => {
        return !item.type || item.type === 'capsule';
      }).length;
      
      this.completedGoals = completedGoals;
      // 简单计算成就数（可以根据实际业务逻辑调整）
      this.achievements = this.capsuleCount + completedGoals;
    },

    // 计算胶囊数量增长率
    async calculateCapsuleGrowthRate() {
      try {
        const axios = window.$axios || this.$axios;
        if (axios) {
          // 尝试从API获取上月胶囊数量 - 暂时注释掉，因为后端还没有实现
          /*
          try {
            const lastMonthResponse = await axios.get('/api/statistics/last-month');
            if (lastMonthResponse?.data?.capsuleCount) {
              const lastMonthCount = lastMonthResponse.data.capsuleCount;
              if (lastMonthCount > 0) {
                // 计算增长率
                const growthRate = Math.round(((this.capsuleCount - lastMonthCount) / lastMonthCount) * 100);
                this.capsuleGrowthRate = growthRate;
                console.log('计算胶囊增长率:', growthRate);
              } else {
                this.capsuleGrowthRate = this.capsuleCount > 0 ? 100 : 0;
              }
            } else {
              // 如果API失败，尝试从本地数据计算
              this.estimateCapsuleGrowthRate();
            }
          } catch (error) {
            console.error('计算胶囊增长率失败:', error);
            // 尝试从本地数据估算
            this.estimateCapsuleGrowthRate();
          }
          */
          // 直接从本地数据估算
          this.estimateCapsuleGrowthRate();
        } else {
          // 如果没有axios，尝试从本地数据估算
          this.estimateCapsuleGrowthRate();
        }
      } catch (error) {
        console.error('计算胶囊增长率失败:', error);
        // 尝试从本地数据估算
        this.estimateCapsuleGrowthRate();
      }
    },

    // 估算胶囊增长率（基于本地数据）
    estimateCapsuleGrowthRate() {
      // 简单估算：如果有胶囊，假设增长率为10-20%，否则为0
      if (this.capsuleCount > 0) {
        // 生成一个10-20%之间的随机增长率作为估算
        this.capsuleGrowthRate = Math.floor(Math.random() * 11) + 10;
      } else {
        this.capsuleGrowthRate = 0;
      }
      console.log('估算胶囊增长率:', this.capsuleGrowthRate);
    },
    
    // 获取操作类型文本
    getActionTypeText(action) {
      switch (action) {
        case 'create':
          return '创建';
        case 'open':
          return '开启';
        case 'update':
        case 'complete':
          return '完成';
        default:
          return '活动';
      }
    },
    
    // 生成最近活动
    generateRecentActivities() {
      // 从capsules数组中提取最近活动
      const activities = [];
      
      // 添加胶囊创建活动
      this.capsules.forEach(capsule => {
        if (!capsule.type || capsule.type === 'capsule') {
          // 添加胶囊创建活动
          activities.push({
            id: `capsule-${capsule.id}`,
            type: 'capsule',
            action: 'create',
            title: capsule.title,
            description: `创建了一个新胶囊: ${capsule.title}`,
            time: this.getTimeAgo(capsule.createdAt || capsule.created_at || capsule.date || new Date().toISOString()),
            date: capsule.createdAt || capsule.created_at || capsule.date || new Date().toISOString()
          });
          
          // 添加胶囊开启活动（如果胶囊已开启）
          if (capsule.isOpened || capsule.status === 'OPENED') {
            activities.push({
              id: `capsule-${capsule.id}-opened`,
              type: 'capsule',
              action: 'open',
              title: capsule.title,
              description: `开启了胶囊: ${capsule.title}`,
              time: this.getTimeAgo(capsule.openedAt || capsule.opened_at || capsule.createdAt || capsule.created_at || capsule.date || new Date().toISOString()),
              date: capsule.openedAt || capsule.opened_at || capsule.createdAt || capsule.created_at || capsule.date || new Date().toISOString()
            });
          }
        }
      });
      
      // 添加目标活动
      this.capsules.forEach(goal => {
        if (goal.type === 'goal') {
          if (goal.subtype === 'created') {
            activities.push({
              id: goal.id,
              type: 'goal',
              action: 'create',
              title: goal.title,
              description: `创建了新目标: ${goal.title}`,
              time: goal.time || this.getTimeAgo(goal.date || goal.createdAt || goal.created_at || new Date().toISOString()),
              date: goal.date || goal.createdAt || goal.created_at || new Date().toISOString()
            });
          } else if (goal.subtype === 'completed') {
            activities.push({
              id: goal.id,
              type: 'goal',
              action: 'complete',
              title: goal.title,
              description: `完成了目标: ${goal.title}`,
              time: goal.time || this.getTimeAgo(goal.date || goal.completedAt || new Date().toISOString()),
              date: goal.date || goal.completedAt || new Date().toISOString()
            });
          }
        }
      });
      
      // 如果没有活动，添加一些默认活动
      if (activities.length === 0 && this.capsules.length === 0) {
        const defaultActivities = [
          {
            id: 'default-1',
            type: 'capsule',
            action: 'create',
            title: '欢迎使用时光胶囊',
            description: '创建了第一个时光胶囊',
            time: '刚刚',
            date: new Date().toISOString()
          },
          {
            id: 'default-2',
            type: 'goal',
            action: 'create',
            title: '开始记录生活',
            description: '创建了第一个目标',
            time: '5分钟前',
            date: new Date(Date.now() - 5 * 60 * 1000).toISOString()
          }
        ];
        defaultActivities.forEach(activity => {
          activities.push(activity);
        });
      }
      
      // 按时间排序（最新的在前面）
      activities.sort((a, b) => {
        return new Date(b.date) - new Date(a.date);
      });
      
      // 过滤出半年内的活动
      const sixMonthsAgo = new Date();
      sixMonthsAgo.setMonth(sixMonthsAgo.getMonth() - 6);
      
      const filteredActivities = activities.filter(activity => {
        const activityDate = new Date(activity.date);
        return activityDate >= sixMonthsAgo;
      });
      
      // 只显示最近5个活动
      this.recentActivities = filteredActivities.slice(0, 5);
    },
    
    // 查找即将解锁的胶囊
    findUpcomingCapsule() {
      // 如果正在查询，直接返回，避免重复请求
      if (this.isCheckingUpcoming) {
        return;
      }
      
      // 检查是否在1分钟内已经查询过，避免频繁请求
      const now = Date.now();
      const oneMinute = 60 * 1000;
      if (now - this.lastApiCheckTime < oneMinute) {
        if (process.env.NODE_ENV === 'development') {
          console.log('API查询过于频繁，跳过此次查询');
        }
        return;
      }
      
      // 设置查询标志
      this.isCheckingUpcoming = true;
      // 更新上次查询时间
      this.lastApiCheckTime = now;
      
      const currentUserId = this.getCurrentUserId();
      
      // 筛选条件：未开启、属于当前登录用户的胶囊
      const eligibleCapsules = this.capsules.filter(capsule => {
        // 只处理胶囊类型
        if (!capsule.type || capsule.type === 'capsule') {
          // 检查是否属于当前用户
          if (this.isCurrentUserCapsule(capsule, currentUserId)) {
            // 检查是否未开启
            const isOpened = capsule.isOpened || capsule.status === 'OPENED';
            if (!isOpened) {
              // 检查是否有开放日期
              const openDate = capsule.openDate || capsule.open_date;
              if (openDate) {
                try {
                  const openDateTime = new Date(openDate);
                  // 确保日期是有效的
                  if (!isNaN(openDateTime.getTime())) {
                    return true;
                  }
                } catch (e) {
                  if (process.env.NODE_ENV === 'development') {
                    console.error('日期格式错误:', e);
                  }
                }
              }
            }
          }
        }
        return false;
      });
      
      if (process.env.NODE_ENV === 'development') {
        console.log('符合条件的胶囊列表:', eligibleCapsules);
      }
      
      // 按创建时间倒序排序（最新创建的排在最前面）
      eligibleCapsules.sort((a, b) => {
        const createDateA = new Date(a.createdAt || a.created_at || a.date || new Date(0));
        const createDateB = new Date(b.createdAt || b.created_at || b.date || new Date(0));
        return createDateB - createDateA; // 降序排序，最新的在前面
      });
      
      if (eligibleCapsules.length > 0) {
        // 只展示最新创建的1条记录
        this.upcomingCapsule = eligibleCapsules[0];
        if (process.env.NODE_ENV === 'development') {
          console.log('找到即将解锁的胶囊:', this.upcomingCapsule);
        }
        if (this.upcomingCapsule?.openDate || this.upcomingCapsule?.open_date) {
          this.calculateCountdown(this.upcomingCapsule.openDate || this.upcomingCapsule.open_date);
        }
        // 重置查询标志
        this.isCheckingUpcoming = false;
      } else {
        // 尝试从timeline API数据中查找
        try {
          const axios = window.$axios || this.$axios;
          if (axios) {
            axios.get('/capsules/timeline').then(response => {
              if (response?.data?.timeline) {
                const timelineCapsules = [];
                response.data.timeline.forEach(yearData => {
                  yearData.capsules.forEach(capsule => {
                    // 检查是否属于当前用户
                    if (this.isCurrentUserCapsule(capsule, currentUserId)) {
                      // 检查是否未开启
                      const isOpened = capsule.isOpened || capsule.status === 'OPENED';
                      if (!isOpened) {
                        // 检查是否有开放日期
                        const openDate = capsule.openDate || capsule.open_date;
                        if (openDate) {
                          try {
                            const openDateTime = new Date(openDate);
                            if (!isNaN(openDateTime.getTime())) {
                              timelineCapsules.push(capsule);
                            }
                          } catch (e) {
                            if (process.env.NODE_ENV === 'development') {
                              console.error('日期格式错误:', e);
                            }
                          }
                        }
                      }
                    }
                  });
                });
                
                // 按创建时间倒序排序（最新创建的排在最前面）
                timelineCapsules.sort((a, b) => {
                  const createDateA = new Date(a.createdAt || a.created_at || a.date || new Date(0));
                  const createDateB = new Date(b.createdAt || b.created_at || b.date || new Date(0));
                  return createDateB - createDateA; // 降序排序，最新的在前面
                });
                
                if (timelineCapsules.length > 0) {
                  // 只展示最新创建的1条记录
                  this.upcomingCapsule = timelineCapsules[0];
                  if (process.env.NODE_ENV === 'development') {
                    console.log('从timeline API找到即将解锁的胶囊:', this.upcomingCapsule);
                  }
                  if (this.upcomingCapsule?.openDate || this.upcomingCapsule?.open_date) {
                    this.calculateCountdown(this.upcomingCapsule.openDate || this.upcomingCapsule.open_date);
                  }
                } else {
                  this.upcomingCapsule = null;
                  this.countdown = '暂无即将解锁的胶囊';
                  if (process.env.NODE_ENV === 'development') {
                    console.log('暂无即将解锁的胶囊');
                  }
                }
              }
            }).catch(error => {
              if (process.env.NODE_ENV === 'development') {
                console.error('获取timeline数据失败:', error);
              }
              this.upcomingCapsule = null;
              this.countdown = '暂无即将解锁的胶囊';
            }).finally(() => {
              // 重置查询标志
              this.isCheckingUpcoming = false;
            });
          } else {
            this.upcomingCapsule = null;
            this.countdown = '暂无即将解锁的胶囊';
            if (process.env.NODE_ENV === 'development') {
              console.log('暂无即将解锁的胶囊');
            }
            // 重置查询标志
            this.isCheckingUpcoming = false;
          }
        } catch (error) {
          if (process.env.NODE_ENV === 'development') {
            console.error('查找即将解锁的胶囊失败:', error);
          }
          this.upcomingCapsule = null;
          this.countdown = '暂无即将解锁的胶囊';
          // 重置查询标志
          this.isCheckingUpcoming = false;
        }
      }
    },
    
    // 获取相对时间
    getTimeAgo(dateString) {
      const date = new Date(dateString);
      const now = new Date();
      const diffInSeconds = Math.floor((now - date) / 1000);
      
      if (diffInSeconds < 60) {
        return '刚刚';
      } else if (diffInSeconds < 3600) {
        const minutes = Math.floor(diffInSeconds / 60);
        return `${minutes}分钟前`;
      } else if (diffInSeconds < 86400) {
        const hours = Math.floor(diffInSeconds / 3600);
        return `${hours}小时前`;
      } else if (diffInSeconds < 604800) {
        const days = Math.floor(diffInSeconds / 86400);
        return `${days}天前`;
      } else {
        return this.formatDate(date);
      }
    },
    
    // 计算倒计时
    calculateCountdown(targetDate) {
      // 获取当前时间
      const now = new Date();
      
      // 获取目标日期，设置为凌晨0点0分0秒
      const target = new Date(targetDate);
      target.setHours(0, 0, 0, 0);
      
      const diff = target - now;
      
      if (diff <= 0) {
        this.countdown = '已解锁';
        // 当胶囊解锁时，延迟重新查找即将解锁的胶囊，避免循环调用
        setTimeout(() => {
          this.findUpcomingCapsule();
        }, 1000);
        return;
      }
      
      const days = Math.floor(diff / (1000 * 60 * 60 * 24));
      const hours = Math.floor((diff % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
      const minutes = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60));
      
      // 格式化为两位数
      const formattedDays = days.toString().padStart(2, '0');
      const formattedHours = hours.toString().padStart(2, '0');
      const formattedMinutes = minutes.toString().padStart(2, '0');
      
      this.countdown = `${formattedDays}天 ${formattedHours}时 ${formattedMinutes}分`;
    },
    formatDate(date) {
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
      return `${year}年${month}月${day}日`
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
        if (process.env.NODE_ENV === 'development') {
          console.error('头像上传失败:', error)
        }
        ElMessage.error('头像上传失败: ' + (error.response?.data?.message || error.message))
        return false
      }
      
      return false // 阻止自动上传
    },
    
    // 初始化内存监控
    initMemoryMonitor() {
      // 检查是否支持performance API
      if (typeof performance !== 'undefined' && performance.memory) {
        // 每30秒检查一次内存使用情况
        this.memoryMonitor.memoryCheckInterval = setInterval(() => {
          this.checkMemoryUsage();
        }, 30000);
        
        if (process.env.NODE_ENV === 'development') {
          console.log('内存监控已初始化');
        }
      } else {
        if (process.env.NODE_ENV === 'development') {
          console.log('当前环境不支持内存监控');
        }
      }
    },
    
    // 停止内存监控
    stopMemoryMonitor() {
      if (this.memoryMonitor.memoryCheckInterval) {
        clearInterval(this.memoryMonitor.memoryCheckInterval);
        this.memoryMonitor.memoryCheckInterval = null;
        if (process.env.NODE_ENV === 'development') {
          console.log('内存监控已停止');
        }
      }
    },
    
    // 检查内存使用情况
    checkMemoryUsage() {
      if (typeof performance !== 'undefined' && performance.memory) {
        const memory = performance.memory;
        const usedMemory = memory.usedJSHeapSize;
        const totalMemory = memory.totalJSHeapSize;
        const memoryUsagePercent = (usedMemory / totalMemory) * 100;
        
        this.memoryMonitor.currentUsage = memoryUsagePercent;
        
        // 更新峰值内存使用
        if (memoryUsagePercent > this.memoryMonitor.peakUsage) {
          this.memoryMonitor.peakUsage = memoryUsagePercent;
        }
        
        // 内存使用警告
        if (memoryUsagePercent > this.memoryMonitor.warningThreshold) {
          if (process.env.NODE_ENV === 'development') {
            console.warn(`内存使用警告: ${memoryUsagePercent.toFixed(2)}%`);
            console.log(`已用内存: ${(usedMemory / 1024 / 1024).toFixed(2)}MB, 总内存: ${(totalMemory / 1024 / 1024).toFixed(2)}MB`);
          }
          // 可以在这里添加更多的处理逻辑，比如清理缓存等
        }
        
        if (process.env.NODE_ENV === 'development') {
          console.log(`内存使用: ${memoryUsagePercent.toFixed(2)}%, 已用: ${(usedMemory / 1024 / 1024).toFixed(2)}MB, 总: ${(totalMemory / 1024 / 1024).toFixed(2)}MB`);
        }
      }
    }
  }
}
</script>

<style scoped>
/* 全局样式 */
.home {
  padding: 0;
  margin: 0;
  width: 100%;
  min-height: calc(100vh - 120px);
  background: linear-gradient(135deg, #f8f9ff 0%, #eef2ff 100%);
  overflow: hidden;
}

/* 加载状态 */
.loading-overlay {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  height: 100vh;
  width: 100vw;
  background: rgba(255, 255, 255, 0.8);
  position: fixed;
  top: 0;
  left: 0;
  z-index: 1000;
}

.loading-overlay p {
  margin-top: 20px;
  color: #409EFF;
  font-size: 16px;
}

/* 隐藏滚动条 */
:global(body) {
  overflow: hidden;
  margin: 0;
  padding: 0;
}

/* 隐藏滚动条但保留滚动功能的跨浏览器兼容样式 */
:global(::-webkit-scrollbar) {
  display: none;
}

:global(*) {
  -ms-overflow-style: none;
  scrollbar-width: none;
}

/* Element Plus 布局组件样式 */
:deep(.el-container) {
  width: 100%;
  max-width: 1200px;
  margin: 0 auto;
  padding: 0 20px;
}

:deep(.el-main) {
  padding: 0;
  min-height: auto;
}

/* 欢迎区域 */
.welcome-section {
  padding: 30px 0;
  background: linear-gradient(135deg, #f8f9ff 0%, #eef2ff 100%);
  margin-bottom: 20px;
  border: none;
}

.welcome-content {
  max-width: 1200px;
  margin: 0 auto;
  padding: 0 20px;
}

.welcome-left {
  text-align: left;
}

.welcome-back {
  font-size: 14px;
  color: #999;
  margin-bottom: 12px;
  font-family: 'PingFang SC', 'Microsoft YaHei', sans-serif;
}

.welcome-content h1 {
  font-size: 36px;
  font-weight: 700;
  color: #333;
  margin: 0 0 16px 0;
  line-height: 1.2;
  font-family: 'PingFang SC', 'Microsoft YaHei', sans-serif;
}

.welcome-blue {
  color: #409EFF;
}



/* 统计卡片 */
.stats-row {
  max-width: 1200px;
  margin: 0 auto 20px auto;
  padding: 0 20px;
}

.stat-card {
  border-radius: 12px;
  overflow: hidden;
  box-shadow: 0 4px 16px rgba(92, 142, 255, 0.1);
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  border: none;
  height: 100%;
}

.stat-card:hover {
  box-shadow: 0 6px 20px rgba(92, 142, 255, 0.15);
}

.stat-card :deep(.el-card__body) {
  padding: 16px;
}

.upcoming-card {
  background: linear-gradient(135deg, #409EFF 0%, #1890ff 100%);
  color: white;
}

.stat-content {
  display: flex;
  flex-direction: column;
  height: 100%;
}

.stat-icon {
  font-size: 24px;
  margin-bottom: 12px;
  color: #409EFF;
}

.stat-info {
  flex: 1;
}

.stat-label {
  font-size: 14px;
  color: #666;
  margin-bottom: 8px;
  font-family: 'PingFang SC', 'Microsoft YaHei', sans-serif;
}

.upcoming-header {
  font-size: 14px;
  margin-bottom: 12px;
  font-family: 'PingFang SC', 'Microsoft YaHei', sans-serif;
}

.stat-value {
  font-size: 32px;
  font-weight: 700;
  color: #333;
  margin-bottom: 4px;
  font-family: 'PingFang SC', 'Microsoft YaHei', sans-serif;
}

.upcoming-card .stat-value {
  color: white;
}

.countdown {
  font-size: 24px;
  font-weight: 700;
  margin-bottom: 12px;
  font-family: 'PingFang SC', 'Microsoft YaHei', sans-serif;
}

.stat-change {
  font-size: 12px;
  color: #67C23A;
  font-weight: 500;
  font-family: 'PingFang SC', 'Microsoft YaHei', sans-serif;
}

.upcoming-description {
  font-size: 14px;
  line-height: 1.4;
  opacity: 0.9;
  font-family: 'PingFang SC', 'Microsoft YaHei', sans-serif;
}

.upcoming-details {
  margin-top: 12px;
  text-align: left;
}

.upcoming-title {
  font-size: 18px;
  font-weight: 600;
  margin-bottom: 8px;
  line-height: 1.4;
  font-family: 'PingFang SC', 'Microsoft YaHei', sans-serif;
}

.upcoming-info {
  font-size: 14px;
  opacity: 0.9;
  line-height: 1.5;
  font-family: 'PingFang SC', 'Microsoft YaHei', sans-serif;
}

.upcoming-date {
  margin-bottom: 4px;
}

.upcoming-type {
  margin-bottom: 4px;
}

/* 内容区域 */
.content-row {
  max-width: 1200px;
  margin: 0 auto 20px auto;
  padding: 0 20px;
}

/* 最近活动列表 */
.recent-activities-section {
  background: white;
  border-radius: 12px;
  box-shadow: 0 4px 16px rgba(92, 142, 255, 0.1);
  padding: 20px;
}

.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
}

.section-title {
  font-size: 24px;
  font-weight: 700;
  color: #333;
  margin: 0;
  font-family: 'PingFang SC', 'Microsoft YaHei', sans-serif;
}

.view-all-activities :deep(.el-button) {
  font-size: 14px;
  font-family: 'PingFang SC', 'Microsoft YaHei', sans-serif;
}

.activities-list {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.activity-card {
  display: flex;
  align-items: flex-start;
  gap: 16px;
  padding: 16px;
  background: white;
  border: 1px solid #e8e8e8;
  border-radius: 8px;
  transition: all 0.3s ease;
}

.activity-card:hover {
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.08);
  border-color: #409EFF;
}

.activity-icon {
  width: 40px;
  height: 40px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 50%;
  background: #f0f9ff;
  flex-shrink: 0;
}

.create-icon {
  font-size: 20px;
  color: #409EFF;
}

.open-icon {
  font-size: 20px;
  color: #67C23A;
}

.complete-icon {
  font-size: 20px;
  color: #E6A23C;
}

.activity-content {
  flex: 1;
}

.activity-title {
  font-size: 16px;
  font-weight: 600;
  color: #333;
  margin-bottom: 4px;
  font-family: 'PingFang SC', 'Microsoft YaHei', sans-serif;
  display: flex;
  align-items: center;
  gap: 8px;
}

.action-type {
  font-weight: 700;
}

.activity-name {
  font-weight: 700;
}

.activity-description {
  font-size: 12px;
  color: #999;
  line-height: 1.4;
  font-family: 'PingFang SC', 'Microsoft YaHei', sans-serif;
}

.activity-time {
  font-size: 12px;
  color: #999;
  white-space: nowrap;
  margin-top: 2px;
  font-family: 'PingFang SC', 'Microsoft YaHei', sans-serif;
  align-self: flex-start;
}

.empty-activities {
  padding: 40px 0;
  text-align: center;
}

/* 右侧小卡片 */
.side-card {
  border-radius: 12px;
  overflow: hidden;
  box-shadow: 0 4px 16px rgba(92, 142, 255, 0.1);
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  border: none;
}

.side-card:hover {
  box-shadow: 0 6px 20px rgba(92, 142, 255, 0.15);
}

.side-card :deep(.el-card__body) {
  padding: 20px;
}

.card-header {
  font-size: 16px;
  font-weight: 600;
  color: #333;
  font-family: 'PingFang SC', 'Microsoft YaHei', sans-serif;
}

/* 存档健康度 */
.archive-health {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.storage-usage {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.usage-label {
  font-size: 14px;
  color: #666;
  font-family: 'PingFang SC', 'Microsoft YaHei', sans-serif;
}

.usage-percent {
  font-size: 14px;
  font-weight: 600;
  color: #409EFF;
  font-family: 'PingFang SC', 'Microsoft YaHei', sans-serif;
}

.backup-status {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 12px;
  background: #f0f9ff;
  border-radius: 8px;
  font-size: 14px;
  color: #409EFF;
  font-family: 'PingFang SC', 'Microsoft YaHei', sans-serif;
}

.backup-time {
  font-size: 12px;
  color: #999;
  margin-left: auto;
  font-family: 'PingFang SC', 'Microsoft YaHei', sans-serif;
}

/* 记忆提醒 */
.memory-prompt {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.prompt-text {
  font-size: 16px;
  line-height: 1.4;
  color: #333;
  font-style: italic;
  margin: 0;
  font-family: 'PingFang SC', 'Microsoft YaHei', sans-serif;
}

.record-button {
  width: 100%;
  border-radius: 8px;
  padding: 10px 0;
  font-size: 14px;
  font-weight: 500;
  font-family: 'PingFang SC', 'Microsoft YaHei', sans-serif;
  background: #333;
  border-color: #333;
}

.record-button:hover {
  background: #444;
  border-color: #444;
}

/* 时光闪回 */
.memory-flashback {
  padding: 10px 0;
}

.flashback-content {
  position: relative;
}

.flashback-date-badge {
  position: absolute;
  top: 10px;
  left: 10px;
  background: rgba(0, 0, 0, 0.7);
  color: white;
  padding: 4px 12px;
  border-radius: 4px;
  font-size: 12px;
  z-index: 1;
  font-family: 'PingFang SC', 'Microsoft YaHei', sans-serif;
}

.flashback-image-placeholder {
  width: 100%;
  height: 150px;
  background: #1a1a1a;
  border-radius: 8px;
  margin-bottom: 16px;
  overflow: hidden;
}

.flashback-title {
  font-size: 18px;
  font-weight: 700;
  color: #333;
  margin: 0 0 12px 0;
  font-family: 'PingFang SC', 'Microsoft YaHei', sans-serif;
}

.flashback-description {
  font-size: 14px;
  line-height: 1.5;
  color: #666;
  margin: 0 0 20px 0;
  font-family: 'PingFang SC', 'Microsoft YaHei', sans-serif;
}

.relive-button {
  width: 100%;
  font-size: 14px;
  border-color: #409EFF;
  color: #409EFF;
  font-family: 'PingFang SC', 'Microsoft YaHei', sans-serif;
}

.relive-button:hover {
  background-color: #ecf5ff;
  border-color: #66b1ff;
  color: #409EFF;
}

.flashback-empty {
  text-align: center;
  padding: 40px 20px;
  color: #999;
  font-family: 'PingFang SC', 'Microsoft YaHei', sans-serif;
}

/* 响应式布局 */
@media (max-width: 768px) {
  .welcome-content h1 {
    font-size: 32px;
  }
  
  .stats-row {
    padding: 0 16px;
  }
  
  .content-row {
    padding: 0 16px;
  }
  
  .recent-activities-section {
    padding: 20px;
  }
  
  .activity-item {
    padding: 12px;
  }
  
  .side-card :deep(.el-card__body) {
    padding: 16px;
  }
}

@media (max-width: 480px) {
  .welcome-section {
    padding: 30px 0;
  }
  
  .welcome-content {
    padding: 0 16px;
  }
  
  .welcome-content h1 {
    font-size: 28px;
  }
  
  .stat-card :deep(.el-card__body) {
    padding: 16px;
  }
  
  .countdown {
    font-size: 20px;
  }
  
  .section-header h2 {
    font-size: 18px;
  }
  
  .activity-title {
    font-size: 14px;
  }
  
  .activity-description {
    font-size: 13px;
  }
}

/* 今日目标进度和日历容器 */
.goal-calendar-container {
  display: flex;
  gap: 24px;
  margin-bottom: 32px;
  flex-wrap: wrap;
}

/* 今日目标进度卡片 */
.goal-progress-card {
  flex: 1;
  min-width: 280px;
  margin-bottom: 0;
  border-radius: 12px;
  overflow: hidden;
  box-shadow: 0 4px 16px rgba(92, 142, 255, 0.1);
  border: none;
  transition: all 0.3s ease;
}

.goal-progress-card:hover {
  box-shadow: 0 6px 20px rgba(92, 142, 255, 0.15);
  transform: translateY(-1px);
}

.goal-progress-card :deep(.el-card__header) {
  background: linear-gradient(135deg, #5c8eff 0%, #4a7bff 100%);
  color: white;
  border-radius: 12px 12px 0 0;
  padding: 16px 20px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 16px;
  font-weight: 600;
}

.progress-content {
  padding: 20px 20px;
}

.goal-text {
  font-size: 16px;
  font-weight: 600;
  color: #333;
  margin: 0 0 16px 0;
  text-align: center;
}

.goal-progress-card :deep(.el-progress) {
  margin: 12px 0;
}

.goal-progress-card :deep(.el-progress-bar__outer) {
  border-radius: 4px;
  background: #f0f5ff;
  height: 8px;
}

.goal-progress-card :deep(.el-progress-bar__inner) {
  border-radius: 4px;
  background: linear-gradient(90deg, #5c8eff 0%, #4a7bff 100%);
  transition: width 1s ease-in-out;
}

.progress-text {
  font-size: 14px;
  color: #5c8eff;
  font-weight: 600;
  text-align: center;
  margin: 0;
}

/* 日历卡片 */
.calendar-card {
  flex: 1.2;
  min-width: 300px;
  margin-bottom: 0;
  border-radius: 12px;
  overflow: visible;
  box-shadow: 0 4px 16px rgba(92, 142, 255, 0.1);
  border: none;
  transition: all 0.3s ease;
}

.calendar-card:hover {
  box-shadow: 0 6px 20px rgba(92, 142, 255, 0.15);
  transform: translateY(-1px);
}

.calendar-card :deep(.el-card__header) {
  background: linear-gradient(135deg, #5c8eff 0%, #4a7bff 100%);
  color: white;
  border-radius: 12px 12px 0 0;
  padding: 16px 20px;
}

.calendar-content {
  padding: 20px;
  overflow: visible;
}

/* 隐藏日历区域的滚动条 */
.calendar-card :deep(.el-card__body) {
  overflow: visible;
}

.calendar-card ::-webkit-scrollbar {
  display: none;
}

.calendar-card {
  -ms-overflow-style: none;
  scrollbar-width: none;
}

.calendar-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;
  padding-bottom: 12px;
  border-bottom: 1px solid #e6e9f0;
}

.nav-btn {
  background: white;
  border: 1px solid #e6e9f0;
  border-radius: 50%;
  width: 32px;
  height: 32px;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  font-size: 14px;
  color: #666;
  transition: all 0.3s ease;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.05);
}

.nav-btn:hover {
  background: #5c8eff;
  color: white;
  border-color: #5c8eff;
  box-shadow: 0 4px 8px rgba(92, 142, 255, 0.2);
  transform: scale(1.05);
}

.month-year {
  font-weight: 600;
  color: #333;
  font-size: 14px;
}

.weekdays {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  gap: 2px;
  margin-bottom: 8px;
}

.weekday {
  text-align: center;
  font-size: 12px;
  color: #666;
  padding: 8px 0;
  font-weight: 600;
  border-radius: 6px;
  background: #f8f9ff;
}

.days-grid {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  gap: 2px;
  overflow: visible;
}

.day {
  text-align: center;
  padding: 12px 4px;
  border-radius: 8px;
  cursor: pointer;
  font-size: 13px;
  color: #333;
  transition: all 0.3s ease;
  position: relative;
  background: white;
  border: 1px solid #e6e9f0;
  min-height: 48px;
  display: flex;
  align-items: center;
  justify-content: center;
  overflow: visible;
  margin: 2px;
  transition: all 0.2s ease;
}

.day:hover {
  background: #f0f5ff;
  border-color: #5c8eff;
  transform: translateY(-1px);
  box-shadow: 0 2px 8px rgba(92, 142, 255, 0.15);
}

.day.selected {
  background: #5c8eff;
  color: white;
  border-color: #5c8eff;
  box-shadow: 0 4px 12px rgba(92, 142, 255, 0.3);
  font-weight: 600;
}

.day.selected:hover {
  background: #4a7cff;
  border-color: #4a7cff;
  transform: translateY(-1px);
  box-shadow: 0 4px 16px rgba(92, 142, 255, 0.4);
}

/* 响应式布局 */
@media (max-width: 768px) {
  .goal-calendar-container {
    flex-direction: column;
    gap: 16px;
    margin-bottom: 24px;
  }
  
  .goal-progress-card,
  .calendar-card {
    min-width: unset;
    flex: none;
  }
  
  .progress-content {
    padding: 16px 16px;
  }
  
  .calendar-content {
    padding: 16px;
  }
  
  .day {
    min-height: 40px;
    padding: 6px 2px;
    font-size: 12px;
  }
  
  .weekday {
    padding: 6px 0;
    font-size: 11px;
  }
}

@media (max-width: 480px) {
  .goal-progress-card :deep(.el-card__header),
  .calendar-card :deep(.el-card__header) {
    padding: 14px 16px;
  }
  
  .card-header {
    font-size: 14px;
  }
  
  .progress-content {
    padding: 14px 14px;
  }
  
  .goal-text {
    font-size: 14px;
    margin-bottom: 12px;
  }
  
  .progress-text {
    font-size: 12px;
  }
  
  .calendar-content {
    padding: 14px;
  }
  
  .nav-btn {
    width: 28px;
    height: 28px;
    font-size: 12px;
  }
  
  .month-year {
    font-size: 12px;
  }
  
  .day {
    min-height: 36px;
    padding: 4px 2px;
    font-size: 11px;
  }
  
  .weekday {
    padding: 4px 0;
    font-size: 10px;
  }
}

.day.other-month {
  color: #ccc;
  background: #f8f9ff;
  border-color: #f0f2f5;
}

.day.today {
  background: linear-gradient(135deg, #5c8eff 0%, #4a7bff 100%);
  color: white;
  font-weight: 700;
  border-color: #5c8eff;
  box-shadow: 0 4px 12px rgba(92, 142, 255, 0.3);
}

.day.has-event::after {
  content: '';
  position: absolute;
  bottom: 6px;
  left: 50%;
  transform: translateX(-50%);
  width: 6px;
  height: 6px;
  background: #5c8eff;
  border-radius: 50%;
  box-shadow: 0 2px 4px rgba(92, 142, 255, 0.3);
}

.day.has-capsule-event:not(.has-goal-event)::after,
.day.has-goal-event:not(.has-capsule-event)::after {
  width: 8px;
  height: 8px;
  border-radius: 50%;
}

.day.has-capsule-event:not(.has-goal-event)::after {
  background: #5c8eff; /* 蓝色 - 仅胶囊事件 */
}

.day.has-goal-event:not(.has-capsule-event)::after {
  background: #f7ba2a; /* 橙色 - 仅目标事件 */
}

/* 当同一天既有胶囊事件又有目标事件时，显示两个分开的小点 */
.day.has-capsule-event.has-goal-event:not(.has-goal-completed-event)::after {
  content: '';
  position: absolute;
  bottom: 6px;
  left: 40%;
  width: 6px;
  height: 6px;
  background: #5c8eff; /* 蓝色 - 胶囊 */
  border-radius: 50%;
  box-shadow: 0 2px 4px rgba(92, 142, 255, 0.3);
}

.day.has-capsule-event.has-goal-event:not(.has-goal-completed-event)::before {
  content: '';
  position: absolute;
  bottom: 6px;
  left: 60%;
  width: 6px;
  height: 6px;
  background: #f7ba2a; /* 橙色 - 目标 */
  border-radius: 50%;
  box-shadow: 0 2px 4px rgba(247, 186, 42, 0.3);
}

/* 目标完成事件 */
.day.has-goal-completed-event:not(.has-capsule-event):not(.has-goal-event)::after {
  content: '';
  position: absolute;
  bottom: 6px;
  left: 50%;
  width: 8px;
  height: 8px;
  background: #67c23a; /* 绿色 - 目标完成 */
  border-radius: 50%;
  box-shadow: 0 2px 4px rgba(103, 194, 58, 0.3);
}

/* 当同一天有目标完成事件和胶囊事件时 */
.day.has-goal-completed-event.has-capsule-event:not(.has-goal-event)::after {
  content: '';
  position: absolute;
  bottom: 6px;
  left: 35%;
  width: 6px;
  height: 6px;
  background: #5c8eff; /* 蓝色 - 胶囊 */
  border-radius: 50%;
  box-shadow: 0 2px 4px rgba(92, 142, 255, 0.3);
}

.day.has-goal-completed-event.has-capsule-event:not(.has-goal-event)::before {
  content: '';
  position: absolute;
  bottom: 6px;
  left: 65%;
  width: 6px;
  height: 6px;
  background: #67c23a; /* 绿色 - 目标完成 */
  border-radius: 50%;
  box-shadow: 0 2px 4px rgba(103, 194, 58, 0.3);
}

/* 当同一天有目标完成事件和目标创建事件时 */
.day.has-goal-completed-event.has-goal-event:not(.has-capsule-event)::after {
  content: '';
  position: absolute;
  bottom: 6px;
  left: 35%;
  width: 6px;
  height: 6px;
  background: #f7ba2a; /* 橙色 - 目标创建 */
  border-radius: 50%;
  box-shadow: 0 2px 4px rgba(247, 186, 42, 0.3);
}

.day.has-goal-completed-event.has-goal-event:not(.has-capsule-event)::before {
  content: '';
  position: absolute;
  bottom: 6px;
  left: 65%;
  width: 6px;
  height: 6px;
  background: #67c23a; /* 绿色 - 目标完成 */
  border-radius: 50%;
  box-shadow: 0 2px 4px rgba(103, 194, 58, 0.3);
}

/* 当一天有三个事件时 */
.day.has-goal-completed-event.has-goal-event.has-capsule-event::after {
  content: '';
  position: absolute;
  bottom: 6px;
  left: 30%;
  width: 6px;
  height: 6px;
  background: #5c8eff; /* 蓝色 - 胶囊 */
  border-radius: 50%;
  box-shadow: 0 2px 4px rgba(92, 142, 255, 0.3);
}

.day.has-goal-completed-event.has-goal-event.has-capsule-event::before {
  content: '';
  position: absolute;
  bottom: 6px;
  left: 50%;
  transform: translateX(-50%);
  width: 6px;
  height: 6px;
  background: #f7ba2a; /* 橙色 - 目标创建 */
  border-radius: 50%;
  box-shadow: 0 2px 4px rgba(247, 186, 42, 0.3);
}

.day.has-goal-completed-event.has-goal-event.has-capsule-event::after {
  content: '';
  position: absolute;
  bottom: 6px;
  left: 70%;
  width: 6px;
  height: 6px;
  background: #67c23a; /* 绿色 - 目标完成 */
  border-radius: 50%;
  box-shadow: 0 2px 4px rgba(103, 194, 58, 0.3);
}

/* 工具提示样式 */
.tooltip {
  position: fixed;
  background: white;
  border: 1px solid #e6e9f0;
  border-radius: 8px;
  padding: 12px;
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.15);
  z-index: 99999;
  min-width: 200px;
  max-width: 300px;
  font-size: 14px;
  line-height: 1.4;
  pointer-events: none;
  overflow: hidden;
}

/* 日历工具提示样式 */
.calendar-tooltip {
  position: fixed;
  z-index: 999999;
  pointer-events: auto;
  margin-top: 8px;
  pointer-events: auto;
}

.tooltip-content {
  background: white;
  border-radius: 12px;
  padding: 16px;
  box-shadow: 0 8px 24px rgba(92, 142, 255, 0.25), 0 2px 8px rgba(92, 142, 255, 0.15);
  min-width: 240px;
  max-width: 300px;
  backdrop-filter: blur(12px);
  background: linear-gradient(135deg, #ffffff 0%, #f8faff 100%);
  color: #333;
  transition: all 0.3s ease;
  border-top: 3px solid #5c8eff;
  pointer-events: auto;
  transform: translateY(-2px);
  border: 1px solid rgba(92, 142, 255, 0.2);
}

.tooltip-content strong {
  display: block;
  margin-bottom: 16px;
  color: #333;
  font-size: 15px;
  font-weight: 600;
  font-family: 'PingFang SC', 'Microsoft YaHei', sans-serif;
  padding-bottom: 8px;
  border-bottom: 1px solid #f0f2f5;
}

.events-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
  margin-top: 0;
}

/* 事件分组样式 */
.event-group {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.event-group-item {
  display: flex;
  align-items: center;
  gap: 10px;
  font-size: 14px;
  color: #666;
  padding: 8px 12px;
  border-radius: 8px;
  background: #f8f9ff;
  border: 1px solid #e6e9f0;
  cursor: pointer;
  transition: all 0.3s ease;
  position: relative;
  pointer-events: auto;
}

.event-group-item:hover {
  background: #e6eeff;
  border-color: #5c8eff;
  box-shadow: 0 4px 12px rgba(92, 142, 255, 0.25);
  transform: translateY(-1px);
  border-left: 4px solid #5c8eff;
}

.event-group-item span:first-child {
  font-size: 16px;
  flex-shrink: 0;
}

/* 二级悬浮提示样式 */
.event-details-tooltip {
  position: absolute;
  left: 100%;
  top: 50%;
  transform: translateY(-50%);
  margin-left: 8px;
  background: white;
  border: 1px solid #e6e9f0;
  border-radius: 10px;
  padding: 12px;
  box-shadow: 0 4px 16px rgba(92, 142, 255, 0.15);
  min-width: 200px;
  max-width: 280px;
  z-index: 100000;
  backdrop-filter: blur(10px);
  background: linear-gradient(135deg, #ffffff 0%, #f8faff 100%);
  pointer-events: auto;
}

.event-details-tooltip::before {
  content: '';
  position: absolute;
  right: 100%;
  top: 50%;
  transform: translateY(-50%);
  border-width: 6px;
  border-style: solid;
  border-color: transparent white transparent transparent;
}

.event-detail-item {
  display: flex;
  align-items: flex-start;
  gap: 8px;
  font-size: 13px;
  color: #666;
  padding: 6px 0;
  line-height: 1.4;
}

.event-detail-item span:first-child {
  font-size: 14px;
  flex-shrink: 0;
  margin-top: 1px;
}

.event-detail-status {
  font-size: 11px;
  color: #999;
  margin-left: 8px;
  flex-shrink: 0;
}

/* 选中日期的详细事件列表样式 */
.selected-date-events {
  margin-top: 12px;
}

.detailed-events-list {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.event-category h4 {
  margin: 0 0 8px 0;
  font-size: 14px;
  font-weight: 600;
  color: #333;
  display: flex;
  align-items: center;
  gap: 6px;
}

.detailed-event-item {
  background: #f8faff;
  border: 1px solid #e6e9f0;
  border-radius: 8px;
  padding: 12px;
  transition: all 0.2s ease;
}

.detailed-event-item:hover {
  background: #e6eeff;
  border-color: #5c8eff;
  box-shadow: 0 4px 12px rgba(92, 142, 255, 0.25);
  transform: translateX(4px);
  transition: all 0.2s ease;
}

.event-title {
  font-size: 14px;
  font-weight: 500;
  color: #333;
  margin-bottom: 4px;
  line-height: 1.4;
}

.event-meta {
  font-size: 12px;
  color: #666;
  font-weight: 400;
}

.no-events {
  color: #999;
  font-size: 13px;
  text-align: center;
  padding: 12px 0;
  font-family: 'PingFang SC', 'Microsoft YaHei', sans-serif;
}

/* 最近的时间胶囊 */
.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 24px;
  padding-bottom: 16px;
  border-bottom: 2px solid #f0f5ff;
}

.section-header h3 {
  font-size: 20px;
  font-weight: 700;
  color: #333;
  margin: 0;
  font-family: 'PingFang SC', 'Microsoft YaHei', sans-serif;
}

.section-header :deep(.el-button) {
  color: #5c8eff;
  border-color: #5c8eff;
  transition: all 0.3s ease;
  border-radius: 8px;
}

.section-header :deep(.el-button:hover) {
  background: #5c8eff;
  color: white;
  box-shadow: 0 4px 12px rgba(92, 142, 255, 0.3);
  transform: translateY(-2px);
}

/* 加载状态 */
.loading {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 60px 0;
  color: #666;
}

.loading :deep(.el-icon) {
  font-size: 32px;
  margin-bottom: 16px;
  color: #5c8eff;
}

/* 空状态 */
.empty-capsules {
  padding: 60px 0;
  text-align: center;
}

.empty-capsules :deep(.el-empty) {
  color: #999;
}

.empty-capsules :deep(.el-button) {
  background: #5c8eff;
  border-color: #5c8eff;
  border-radius: 8px;
  transition: all 0.3s ease;
}

.empty-capsules :deep(.el-button:hover) {
  background: #4a7bff;
  box-shadow: 0 4px 12px rgba(92, 142, 255, 0.3);
  transform: translateY(-2px);
}

/* 胶囊网格 */
.capsules-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
  gap: 24px;
  margin-bottom: 40px;
}

/* 胶囊卡片 */
.capsule-card {
  border-radius: 16px;
  overflow: hidden;
  box-shadow: 0 6px 20px rgba(92, 142, 255, 0.1);
  border: none;
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  cursor: pointer;
  background: white;
}

.capsule-card:hover {
  box-shadow: 0 12px 32px rgba(92, 142, 255, 0.15);
  transform: translateY(-4px);
}

.capsule-cover {
  height: 180px;
  background-size: cover;
  background-position: center;
  position: relative;
  overflow: hidden;
}

.capsule-cover::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: linear-gradient(135deg, rgba(92, 142, 255, 0.3) 0%, rgba(74, 123, 255, 0.1) 100%);
  z-index: 1;
}

.capsule-overlay {
  position: absolute;
  top: 16px;
  right: 16px;
  z-index: 2;
}

.capsule-overlay :deep(.el-tag) {
  border-radius: 20px;
  padding: 4px 12px;
  font-size: 12px;
  font-weight: 600;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.2);
}

.capsule-content {
  padding: 20px;
}

.capsule-title {
  font-size: 18px;
  font-weight: 600;
  color: #333;
  margin: 0 0 12px 0;
  line-height: 1.4;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  font-family: 'PingFang SC', 'Microsoft YaHei', sans-serif;
}

.capsule-date {
  font-size: 14px;
  color: #999;
  margin: 0 0 12px 0;
}

.capsule-preview {
  font-size: 14px;
  color: #666;
  margin: 0;
  line-height: 1.5;
  display: -webkit-box;
  -webkit-line-clamp: 3;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

/* 编辑资料对话框 */
:deep(.el-dialog) {
  border-radius: 16px;
  overflow: hidden;
  box-shadow: 0 12px 40px rgba(0, 0, 0, 0.15);
}

:deep(.el-dialog__header) {
  background: linear-gradient(135deg, #5c8eff 0%, #4a7bff 100%);
  color: white;
  padding: 20px 24px;
}

:deep(.el-dialog__title) {
  font-size: 18px;
  font-weight: 600;
}

:deep(.el-dialog__body) {
  padding: 24px;
}

:deep(.el-form-item) {
  margin-bottom: 20px;
}

:deep(.el-form-item__label) {
  font-weight: 500;
  color: #333;
}

:deep(.el-input),
:deep(.el-textarea) {
  border-radius: 8px;
  border: 1px solid #e6e9f0;
  transition: all 0.3s ease;
}

:deep(.el-input:focus-within),
:deep(.el-textarea:focus-within) {
  border-color: #5c8eff;
  box-shadow: 0 0 0 2px rgba(92, 142, 255, 0.1);
}

:deep(.el-dialog__footer) {
  padding: 20px 24px;
  border-top: 1px solid #f0f2f5;
}

:deep(.el-button) {
  border-radius: 8px;
  transition: all 0.3s ease;
}

:deep(.el-button--primary) {
  background: #5c8eff;
  border-color: #5c8eff;
}

:deep(.el-button--primary:hover) {
  background: #4a7bff;
  box-shadow: 0 4px 12px rgba(92, 142, 255, 0.3);
  transform: translateY(-2px);
}

/* 头像上传 */
.avatar-upload {
  display: flex;
  flex-direction: column;
  align-items: center;
}

.avatar-uploader {
  margin-bottom: 16px;
}

.avatar-uploader :deep(.el-avatar) {
  border: 3px solid rgba(92, 142, 255, 0.2);
  transition: all 0.3s ease;
}

.avatar-uploader :deep(.el-avatar:hover) {
  transform: scale(1.05);
  box-shadow: 0 4px 12px rgba(92, 142, 255, 0.3);
}

/* 响应式设计 */
@media (max-width: 768px) {
  .user-info {
    flex-direction: column;
    text-align: center;
    padding: 24px;
  }
  
  .user-stats {
    justify-content: center;
    gap: 24px;
  }
  
  .stat-item {
    padding: 12px 16px;
  }
  
  .goal-calendar-container {
    flex-direction: column;
  }
  
  .goal-progress-card,
  .calendar-card {
    min-width: 100%;
  }
  
  .capsules-grid {
    grid-template-columns: 1fr;
  }
  
  .capsule-cover {
    height: 160px;
  }
}

@media (max-width: 480px) {
  .user-card {
    margin-bottom: 16px;
  }
  
  .user-info {
    padding: 20px;
  }
  
  .nickname {
    font-size: 24px;
  }
  
  .bio {
    font-size: 14px;
  }
  
  .user-stats {
    flex-wrap: wrap;
    gap: 16px;
  }
  
  .stat-item {
    flex: 1;
    min-width: 100px;
  }
  
  .section-header h3 {
    font-size: 18px;
  }
  
  .capsule-content {
    padding: 16px;
  }
  
  .capsule-title {
    font-size: 16px;
  }
}

/* 滚动条样式 */
.home-page::-webkit-scrollbar {
  width: 6px;
  height: 6px;
}

.home-page::-webkit-scrollbar-track {
  background: #f8f9ff;
  border-radius: 3px;
}

.home-page::-webkit-scrollbar-thumb {
  background: #c0c4cc;
  border-radius: 3px;
  transition: all 0.3s ease;
}

.home-page::-webkit-scrollbar-thumb:hover {
  background: #a6aab3;
}

/* 平滑滚动 */
html {
  scroll-behavior: smooth;
}

/* 响应式布局 */
@media (max-width: 768px) {
  .goal-calendar-container {
    flex-direction: column;
  }
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