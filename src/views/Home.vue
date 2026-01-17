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
              <span class="stat-value">{{ capsuleCount }}</span>
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

    <!-- 今日目标进度和日历板块容器 -->
    <div class="goal-calendar-container">
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
      
      <!-- 日历板块 -->
      <el-card class="calendar-card">
        <template #header>
          <div class="card-header">
            <span>📅 本月日历</span>
          </div>
        </template>
        <div class="calendar-content">
          <div class="calendar-header">
            <button @click="prevMonth" class="nav-btn">&lt;</button>
            <span class="month-year">{{ currentMonthYear }}</span>
            <button @click="nextMonth" class="nav-btn">&gt;</button>
          </div>
          <div class="weekdays">
            <span v-for="day in weekdays" :key="day" class="weekday">{{ day }}</span>
          </div>
          <div class="days-grid">
            <div 
              v-for="day in days" 
              :key="day.date" 
              :class="[
                'day',
                { 'other-month': day.isOtherMonth },
                { 'today': day.isToday },
                { 'has-event': day.hasEvent },
                { 'has-capsule-event': day.hasCapsuleEvent },
                { 'has-goal-event': day.hasGoalEvent },
                { 'has-goal-completed-event': day.hasGoalCompletedEvent }
              ]"
              @click="selectDate(day.date)"
              @mouseenter="showTooltip($event, day)"
              @mouseleave="hideTooltip"
            >
              {{ day.date.getDate() }}
              <div v-show="tooltipVisible && tooltipDate.getTime() === day.date.getTime()" 
                   class="tooltip" 
                   :style="tooltipStyle">
                <div class="tooltip-content">
                  <strong>{{ day.date.getFullYear() }}年{{ day.date.getMonth() + 1 }}月{{ day.date.getDate() }}日</strong>
                  <div v-if="hasEventsOnDate(day.date)" class="events-list">
                    <div v-for="event in getEventsOnDate(day.date)" :key="event.id" class="event-item">
                      <span v-if="event.type === 'goal' && event.subtype === 'completed'">✅</span>
                      <span v-else-if="event.type === 'goal' && event.subtype === 'created'">🎯</span>
                      <span v-else-if="event.type !== 'goal'">胶囊</span>
                      {{ event.title }}
                      <span v-if="event.subtype === 'completed' && event.createdAt" class="event-status">
                        (耗时 {{ calculateGoalDuration(event.createdAt, event.date) }} 天)
                      </span>
                    </div>
                  </div>
                  <div v-else class="no-events">
                    无活动
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </el-card>
    </div>

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
      completedGoals: 0,
      achievements: 0,
      capsuleCount: 0,
      // 日历相关数据
      currentDate: new Date(),
      weekdays: ['日', '一', '二', '三', '四', '五', '六'],
      // 悬浮提示相关数据
      tooltipVisible: false,
      tooltipDate: null,
      tooltipStyle: {}
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
    // 悬停提示相关方法
    showTooltip(event, day) {
      this.tooltipVisible = true;
      this.tooltipDate = day.date;
      
      // 计算工具提示的位置
      const rect = event.target.getBoundingClientRect();
      this.tooltipStyle = {
        top: rect.bottom + window.scrollY + 5 + 'px',
        left: rect.left + window.scrollX + 'px',
        position: 'fixed',
        zIndex: 1000
      };
    },
    
    hideTooltip() {
      this.tooltipVisible = false;
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
    
    getEventsOnDate(date) {
      const dateStr = this.formatDateWithoutTime(date);
      return this.capsules.filter(item => {
        // 处理胶囊事件
        if (!item.type || item.type === undefined || item.type === 'capsule') {
          const capsuleDate = item.date || item.createdAt || item.created_at || item.openDate || item.open_date;
          if (!capsuleDate) return false;
          const capsuleDateStr = this.formatDateWithoutTime(new Date(capsuleDate));
          return capsuleDateStr === dateStr;
        }
        // 处理目标事件
        else if (item.type === 'goal') {
          // 根据子类型决定日期字段
          let eventDate;
          if (item.subtype === 'created') {
            // 目标创建事件使用创建日期
            eventDate = item.date;
          } else if (item.subtype === 'completed') {
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
      }).slice(0, 3); // 限制最多显示3个事件
    },
    
    // 日历相关方法
    prevMonth() {
      this.currentDate = new Date(this.currentDate.getFullYear(), this.currentDate.getMonth() - 1, 1);
    },
    
    nextMonth() {
      this.currentDate = new Date(this.currentDate.getFullYear(), this.currentDate.getMonth() + 1, 1);
    },
    
    selectDate(date) {
      // 这里可以添加选中日期的处理逻辑
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
      const year = date.getFullYear();
      const month = String(date.getMonth() + 1).padStart(2, '0');
      const day = String(date.getDate()).padStart(2, '0');
      return `${year}-${month}-${day}`;
    },
    
    // 检查指定日期是否有胶囊事件
    hasCapsuleEventOnDate(date) {
      const dateStr = this.formatDateWithoutTime(date);
      return this.capsules.some(item => {
        // 检查是否是胶囊类型
        if (!item.type || item.type === undefined || item.type === 'capsule') {
          const capsuleDate = item.date || item.createdAt || item.created_at || item.openDate || item.open_date;
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
        if (window.$axios) {
          // 获取首页统计数据
          const statsResponse = await window.$axios.get('/statistics/home');
          if (statsResponse?.data) {
            // 更新统计数据
            if (statsResponse.data.recentCapsules) {
              this.capsules = statsResponse.data.recentCapsules;
            } else {
              // 如果API调用失败，获取时间胶囊列表
              const capsulesResponse = await window.$axios.get('/capsules');
              if (capsulesResponse?.data?.content) {
                this.capsules = capsulesResponse.data.content;
              } else {
                this.capsules = [];
              }
            }
            
            // 更新统计数值，但保留实际胶囊列表
            this.capsuleCount = statsResponse.data.capsuleCount || 0;
            this.completedGoals = statsResponse.data.completedGoals || 0;
            this.achievements = statsResponse.data.achievements || 0;
            
            console.log('使用statistics/home API数据:', statsResponse.data);
          } else {
            // 如果统计API调用失败，获取时间胶囊列表
            const capsulesResponse = await window.$axios.get('/capsules');
            if (capsulesResponse?.data?.content) {
              this.capsules = capsulesResponse.data.content;
              // 设置胶囊总数为列表长度
              this.capsuleCount = capsulesResponse.data.content.length;
              console.log('使用capsules API数据:', capsulesResponse.data.content);
            } else {
              this.capsules = [];
              this.capsuleCount = 0;
            }
            
            // 单独获取统计信息
            try {
              const statsResponse = await window.$axios.get('/statistics');
              if (statsResponse?.data) {
                this.completedGoals = statsResponse.data.completedGoals || 0;
                this.achievements = statsResponse.data.achievements || 0;
              }
            } catch (statsError) {
              console.error('获取统计数据失败:', statsError);
            }
          }
          
          // 获取目标数据用于日历显示
          try {
            const goalsResponse = await window.$axios.get('/goals', { params: { page: 0, size: 100 } });
            if (goalsResponse?.data?.content) {
              // 将目标数据添加到capsules数组中，以便在日历上显示
              const goals = Array.isArray(goalsResponse.data.content) ? goalsResponse.data.content : [];
              
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
                  date: goal.createdAt || goal.createTime || goal.created_at || new Date().toISOString(),
                  originalId: goal.id
                });
                
                // 如果目标已完成，添加目标完成事件
                if ((goal.status === 'COMPLETED' || goal.status === 'completed') && goal.completedAt) {
                  goalEvents.push({
                    ...goal,
                    id: `${goal.id}-completed`,
                    type: 'goal',
                    subtype: 'completed',
                    title: `完成: ${goal.title}`,
                    date: goal.completedAt,
                    createdAt: goal.createdAt || goal.createTime || goal.created_at || new Date().toISOString(),
                    completedAt: goal.completedAt,
                    originalId: goal.id
                  });
                }
              });
              
              // 将目标事件合并到capsules数组中
              this.capsules = [...this.capsules, ...goalEvents];
              
              console.log('加载的目标数据:', goals);
            }
          } catch (goalsError) {
            console.error('获取目标数据失败:', goalsError);
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

/* 今日目标进度和日历容器 */
.goal-calendar-container {
  display: flex;
  gap: 20px;
  margin-bottom: 30px;
}

/* 今日目标进度卡片 */
.goal-progress-card {
  flex: 1;
  min-width: 300px;
  margin-bottom: 0;
}

/* 日历卡片 */
.calendar-card {
  flex: 1;
  min-width: 300px;
  margin-bottom: 0;
}

.calendar-content {
  padding: 10px 0;
}

.calendar-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 10px;
}

.nav-btn {
  background: #f5f7fa;
  border: 1px solid #dcdfe6;
  border-radius: 4px;
  padding: 5px 10px;
  cursor: pointer;
  font-size: 14px;
}

.nav-btn:hover {
  background: #ecf5ff;
  color: #409eff;
}

.month-year {
  font-weight: 600;
  color: #333;
}

.weekdays {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  gap: 2px;
  margin-bottom: 5px;
}

.weekday {
  text-align: center;
  font-size: 12px;
  color: #666;
  padding: 5px 0;
}

.days-grid {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  gap: 2px;
}

.day {
  text-align: center;
  padding: 8px 0;
  border-radius: 4px;
  cursor: pointer;
  font-size: 14px;
  color: #333;
  transition: all 0.3s;
  position: relative;
}

.day:hover {
  background: #f5f7fa;
}

.day.other-month {
  color: #ccc;
}

.day.today {
  background: #409eff;
  color: white;
  font-weight: bold;
}

.day.has-event::after {
  content: '';
  position: absolute;
  bottom: 4px;
  left: 50%;
  transform: translateX(-50%);
  width: 4px;
  height: 4px;
  background: #409eff;
  border-radius: 50%;
}

.day.has-capsule-event:not(.has-goal-event)::after,
.day.has-goal-event:not(.has-capsule-event)::after {
  width: 6px;
  height: 6px;
  border-radius: 50%;
}

.day.has-capsule-event:not(.has-goal-event)::after {
  background: #409eff; /* 蓝色 - 仅胶囊事件 */
}

.day.has-goal-event:not(.has-capsule-event)::after {
  background: #e6a23c; /* 橙色 - 仅目标事件 */
}

/* 当同一天既有胶囊事件又有目标事件时，显示两个分开的小点 */
.day.has-capsule-event.has-goal-event:not(.has-goal-completed-event)::after {
  content: '';
  position: absolute;
  bottom: 4px;
  left: 40%;
  width: 4px;
  height: 4px;
  background: #409eff; /* 蓝色 - 胶囊 */
  border-radius: 50%;
}

.day.has-capsule-event.has-goal-event:not(.has-goal-completed-event)::before {
  content: '';
  position: absolute;
  bottom: 4px;
  left: 60%;
  width: 4px;
  height: 4px;
  background: #e6a23c; /* 橙色 - 目标 */
  border-radius: 50%;
}

/* 目标完成事件 */
.day.has-goal-completed-event:not(.has-capsule-event):not(.has-goal-event)::after {
  content: '';
  position: absolute;
  bottom: 4px;
  left: 50%;
  width: 6px;
  height: 6px;
  background: #67c23a; /* 绿色 - 目标完成 */
  border-radius: 50%;
}

/* 当同一天有目标完成事件和胶囊事件时 */
.day.has-goal-completed-event.has-capsule-event:not(.has-goal-event)::after {
  content: '';
  position: absolute;
  bottom: 4px;
  left: 35%;
  width: 4px;
  height: 4px;
  background: #409eff; /* 蓝色 - 胶囊 */
  border-radius: 50%;
}

.day.has-goal-completed-event.has-capsule-event:not(.has-goal-event)::before {
  content: '';
  position: absolute;
  bottom: 4px;
  left: 65%;
  width: 4px;
  height: 4px;
  background: #67c23a; /* 绿色 - 目标完成 */
  border-radius: 50%;
}

/* 当同一天有目标完成事件和目标创建事件时 */
.day.has-goal-completed-event.has-goal-event:not(.has-capsule-event)::after {
  content: '';
  position: absolute;
  bottom: 4px;
  left: 35%;
  width: 4px;
  height: 4px;
  background: #e6a23c; /* 橙色 - 目标创建 */
  border-radius: 50%;
}

.day.has-goal-completed-event.has-goal-event:not(.has-capsule-event)::before {
  content: '';
  position: absolute;
  bottom: 4px;
  left: 65%;
  width: 4px;
  height: 4px;
  background: #67c23a; /* 绿色 - 目标完成 */
  border-radius: 50%;
}

/* 当一天有三个事件时 */
.day.has-goal-completed-event.has-goal-event.has-capsule-event::after {
  content: '';
  position: absolute;
  bottom: 4px;
  left: 30%;
  width: 4px;
  height: 4px;
  background: #409eff; /* 蓝色 - 胶囊 */
  border-radius: 50%;
}

.day.has-goal-completed-event.has-goal-event.has-capsule-event::before {
  content: '';
  position: absolute;
  bottom: 4px;
  left: 50%;
  width: 4px;
  height: 4px;
  background: #e6a23c; /* 橙色 - 目标创建 */
  border-radius: 50%;
}

.day.has-goal-completed-event.has-goal-event.has-capsule-event::after {
  content: '';
  position: absolute;
  bottom: 4px;
  left: 70%;
  width: 4px;
  height: 4px;
  background: #67c23a; /* 绿色 - 目标完成 */
  border-radius: 50%;
}

.tooltip {
  background: rgba(0, 0, 0, 0.8);
  color: white;
  border-radius: 4px;
  padding: 10px;
  font-size: 14px;
  min-width: 200px;
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.3);
}

.tooltip-content strong {
  display: block;
  margin-bottom: 8px;
  color: #fff;
}

.events-list {
  margin-top: 5px;
}

.event-item {
  padding: 4px 0;
  border-bottom: 1px solid rgba(255, 255, 255, 0.2);
}

.event-item:last-child {
  border-bottom: none;
}

.no-events {
  color: #aaa;
  font-style: italic;
  padding: 4px 0;
}

.event-status {
  color: #67c23a;
  font-size: 12px;
  margin-left: 4px;
}

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