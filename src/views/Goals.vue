<template>
  <div class="goals">
    <div class="container">
      <!-- 顶部标题和按钮 -->
      <div class="goals-header">
        <div class="header-content">
          <h2>我的目标</h2>
          <p>通过时间轴追踪你的个人里程碑。每一刻都在这里被永恒记录。</p>
        </div>
        <el-button type="primary" round @click="showAddDialog = true" class="create-button">
          <el-icon><Plus /></el-icon>
          创建新目标
        </el-button>
      </div>

      <!-- 数据卡片区域 -->
      <el-row :gutter="20" class="stats-row">
        <!-- 总完成度卡片 -->
        <el-col :xs="24" :sm="12" :md="6">
          <el-card class="stat-card">
            <div class="completion-content">
              <div class="progress-ring">
                <svg class="progress-svg" width="120" height="120" viewBox="0 0 120 120">
                  <!-- 背景圆环 -->
                  <circle
                    class="progress-bg"
                    cx="60"
                    cy="60"
                    r="50"
                    stroke="#e5e5e5"
                    stroke-width="8"
                    fill="none"
                  />
                  <!-- 进度圆环 -->
                  <circle
                    class="progress-circle"
                    cx="60"
                    cy="60"
                    r="50"
                    stroke="#409EFF"
                    stroke-width="8"
                    fill="none"
                    :stroke-dasharray="314.16"
                    :stroke-dashoffset="314.16 - (314.16 * totalCompletion / 100)"
                    stroke-linecap="round"
                    transform="rotate(-90 60 60)"
                  />
                  <!-- 中心文字 -->
                  <text x="60" y="55" class="progress-percent" text-anchor="middle">{{ totalCompletion }}%</text>
                  <text x="60" y="75" class="progress-label" text-anchor="middle">总完成度</text>
                </svg>
              </div>
              <h3 class="section-title">已完成进度</h3>
              <p class="section-desc">您已完成 {{ goals.length }} 个目标中的 {{ completedCount }} 个</p>
            </div>
          </el-card>
        </el-col>
        <!-- 目标总数卡片 -->
        <el-col :xs="24" :sm="12" :md="6">
          <el-card class="stat-card">
            <div class="stat-content">
              <div class="stat-header blue-bg">
                <el-icon class="stat-icon"><Folder /></el-icon>
                <span class="stat-tag">总计</span>
              </div>
              <div class="stat-value">{{ goals.length }}</div>
              <div class="stat-label">总目标数量</div>
            </div>
          </el-card>
        </el-col>
        <!-- 已完成卡片 -->
        <el-col :xs="24" :sm="12" :md="6">
          <el-card class="stat-card">
            <div class="stat-content">
              <div class="stat-header green-bg">
                <el-icon class="stat-icon"><Check /></el-icon>
                <span class="stat-tag">已达成</span>
              </div>
              <div class="stat-value">{{ completedCount }}</div>
              <div class="stat-label">已完成目标</div>
            </div>
          </el-card>
        </el-col>
        <!-- 进行中卡片 -->
        <el-col :xs="24" :sm="12" :md="6">
          <el-card class="stat-card">
            <div class="stat-content">
              <div class="stat-header orange-bg">
                <el-icon class="stat-icon"><Timer /></el-icon>
                <span class="stat-tag">进行中</span>
              </div>
              <div class="stat-value">{{ inProgressCount }}</div>
              <div class="stat-label">待办中的目标</div>
            </div>
          </el-card>
        </el-col>
      </el-row>

      <!-- 标签筛选栏 -->
      <div class="filter-bar">
        <el-tag 
          :type="activeFilter === 'all' ? 'primary' : ''" 
          :class="{ active: activeFilter === 'all' }"
          @click="activeFilter = 'all'"
        >
          全部
        </el-tag>
        <el-tag 
          :type="activeFilter === 'inProgress' ? 'primary' : ''" 
          :class="{ active: activeFilter === 'inProgress' }"
          @click="activeFilter = 'inProgress'"
        >
          进行中
        </el-tag>
        <el-tag 
          :type="activeFilter === 'completed' ? 'primary' : ''" 
          :class="{ active: activeFilter === 'completed' }"
          @click="activeFilter = 'completed'"
        >
          已完成
        </el-tag>
      </div>

      <!-- 目标卡片列表 -->
      <div class="goal-list">
        <el-card 
          class="goal-card" 
          v-for="goal in filteredGoals" 
          :key="goal.id"
          shadow="hover"
          :body-style="{ padding: '20px' }"
          :header="false"
        >
          <!-- 标题 -->
          <h3 class="goal-title">{{ goal.title }}</h3>
          
          <!-- 分类标签 -->
          <div class="goal-category">
            {{ getCategoryName(goal.type) }}
          </div>
          
          <!-- 进度条 -->
          <div class="progress-section">
            <div class="progress-header">
              <span>当前进度</span>
              <span :class="['progress-status', getStatusClass(goal)]">{{ getStatusText(goal) }}</span>
            </div>
            <el-progress 
              :percentage="goal.progress" 
              :stroke-width="6"
              :status="''"
            />
          </div>
          
          <!-- 日期信息 -->
          <div class="date-info">
            <el-icon><Calendar /></el-icon>
            <span v-if="goal.status === '已完成'">已完成: {{ formatDate(goal.completedDate || goal.targetDate) }}</span>
            <span v-else-if="goal.targetDate">截止日期: {{ formatDate(goal.targetDate) }}</span>
            <span v-else>待定日期</span>
          </div>
          
          <!-- 操作区 -->
          <div class="goal-actions">
            <a href="#" class="view-detail">查看详情</a>
            <el-button size="small" class="update-plan" @click="updateProgress(goal)">更新计划</el-button>
          </div>
        </el-card>
      </div>
      
      <!-- 空状态 -->
      <div v-if="filteredGoals.length === 0" class="empty-state">
        <el-empty description="暂无目标" />
      </div>
    </div>

    <!-- 悬浮添加按钮 -->
    <el-button type="primary" round class="floating-btn" @click="showAddDialog = true">
      <el-icon><Plus /></el-icon>
    </el-button>

    <!-- 添加/编辑目标对话框 -->
    <el-dialog 
      v-model="showAddDialog" 
      :title="editingGoal ? '编辑目标' : '添加目标'" 
      width="600px"
    >
      <el-form :model="goalForm" :rules="goalRules" ref="goalFormRef" label-width="120px">
        <el-form-item label="目标名称" prop="title">
          <el-input v-model="goalForm.title" placeholder="请输入目标名称" />
        </el-form-item>
        <el-form-item label="目标类型" prop="type">
          <el-radio-group v-model="goalForm.type">
            <el-radio label="SHORT_TERM">短期目标</el-radio>
            <el-radio label="LONG_TERM">长期目标</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="目标描述" prop="description">
          <el-input 
            v-model="goalForm.description" 
            type="textarea" 
            :rows="4"
            placeholder="描述一下你的目标..."
          />
        </el-form-item>
        <el-form-item label="期望完成时间" prop="targetDate">
          <el-date-picker
            v-model="goalForm.targetDate"
            type="date"
            placeholder="选择期望完成日期"
            style="width: 100%;"
            :disabled-date="disabledDate"
          />
        </el-form-item>
        <el-form-item label="当前进度">
          <el-slider v-model="goalForm.progress" :max="100" show-input />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="showAddDialog = false">取消</el-button>
        <el-button type="primary" @click="saveGoal">保存</el-button>
      </template>
    </el-dialog>

    <!-- 更新进度对话框 -->
    <el-dialog v-model="showProgressDialog" title="更新计划" width="500px">
      <el-form :model="progressForm" label-width="100px">
        <el-form-item label="完成进度">
          <el-slider v-model="progressForm.progress" :max="100" show-input />
        </el-form-item>
        <el-form-item label="截止日期">
          <el-date-picker
            v-model="progressForm.targetDate"
            type="date"
            placeholder="选择截止日期"
            :disabled-date="disabledDate"
            style="width: 100%"
          />
        </el-form-item>
        <el-form-item label="此时感悟">
          <el-input
            v-model="progressForm.reflection"
            type="textarea"
            :rows="4"
            placeholder="记录本次更新的感悟..."
          />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="showProgressDialog = false">取消</el-button>
        <el-button type="primary" @click="saveProgress">保存</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script>
import { ref, reactive, computed, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus, CircleCheck, Clock, Trophy, MoreFilled, Calendar, Flag, Folder, Check, Timer, View, Histogram, Edit } from '@element-plus/icons-vue'

export default {
  name: 'Goals',
  components: {
    Plus,
    CircleCheck,
    Clock,
    Trophy,
    Flag,
    MoreFilled,
    Calendar,
    Folder,
    Check,
    Timer,
    View,
    Histogram,
    Edit
  },
  setup() {
    const showAddDialog = ref(false)
    const showProgressDialog = ref(false)
    const editingGoal = ref(null)
    const goalFormRef = ref(null)
    const currentProgressGoal = ref(null)
    const activeFilter = ref('all')

    const goals = ref([])
    
    // 加载数据
    const loadData = async () => {
      try {
        // 检查用户是否已登录
        const token = localStorage.getItem('token');
        if (!token) {
          // 如果用户未登录，直接设置为空数组，不显示默认数据
          goals.value = [];
          return;
        }
        
        if (window.$axios) {
          // 准备认证头信息
          const headers = {};
          if (token) {  // 使用外层作用域的token变量
            headers['Authorization'] = `Bearer ${token}`;
          }
          
          // 从API获取目标列表
          window.$axios.get('/goals', { 
            params: { page: 0, size: 100 },
            headers: headers
          }).then(response => {
            const resData = response?.data;
            
            // 调试：打印响应结构
            console.log('Goals API Response:', resData);
            
            // 尝试多种可能的响应结构
            let goalsData = null;
            
            // 检查标准分页结构 { data: { data: [...] } }
            if (resData?.data?.data && Array.isArray(resData?.data?.data)) {
              goalsData = resData.data.data;
            } 
            // 检查简化结构 { data: [...] }
            else if (resData?.data && Array.isArray(resData?.data)) {
              goalsData = resData.data;
            }
            // 检查包含content的结构 { data: { content: [...] } }
            else if (resData?.data?.content && Array.isArray(resData?.data?.content)) {
              goalsData = resData.data.content;
            }
            // 检查直接包含content的结构 { content: [...] } （当前API返回的结构）
            else if (resData?.content && Array.isArray(resData?.content)) {
              goalsData = resData.content;
            }
            else if (Array.isArray(resData)) {
              goalsData = resData;
            }
            
            console.log('Parsed goalsData:', goalsData);
            
            if (Array.isArray(goalsData)) {
              // 转换API响应数据格式
              goals.value = goalsData.map(goal => {
                // 确定状态：优先使用后端返回的状态，但如果进度达到100%且状态仍为进行中，则应为已完成
                let status = goal.status === 'COMPLETED' || goal.status === 'completed' ? '已完成' : 
                         goal.status === 'IN_PROGRESS' || goal.status === 'in_progress' ? '进行中' : 
                         goal.status === 'CANCELLED' || goal.status === 'cancelled' ? '已取消' : '进行中';
                
                // 补充逻辑：如果进度达到100%，但状态还不是已完成，则更新为已完成
                if (goal.progress >= 100 && status === '进行中') {
                  status = '已完成';
                }
                
                return {
                  id: goal.id,
                  title: goal.title,
                  description: goal.description,
                  progress: goal.progress,
                  status: status,
                  type: goal.type,
                  targetDate: goal.targetDate,
                  completedDate: goal.completedDate,
                  enableReminder: goal.enableReminder
                };
              });
              
              console.log('Mapped goals:', goals.value);
            } else {
              // 如果API调用失败但用户已登录，设置为空数组而不是模拟数据
              goals.value = [];
              console.error('Failed to parse goals data from API response:', resData);
            }
          }).catch(error => {
            console.error('加载目标失败:', error);
            // 如果API调用失败但用户已登录，设置为空数组而不是模拟数据
            goals.value = [];
          });
        } else {
          // 如果没有API且用户已登录，设置为空数组而不是模拟数据
          goals.value = [];
        }
      } catch (error) {
        console.error('加载目标失败:', error);
        // 如果出现异常但用户已登录，设置为空数组而不是模拟数据
        goals.value = [];
      }
    }
    
    // 组件挂载时加载数据
    onMounted(() => {
      loadData();
    })

    const goalForm = reactive({
      title: '',
      description: '',
      type: 'SHORT_TERM',
      targetDate: '',
      progress: 0
    })

    const progressForm = reactive({
      progress: 0,
      targetDate: '',
      reflection: ''
    })

    const goalRules = {
      title: [
        { required: true, message: '请输入目标名称', trigger: 'blur' }
      ],
      description: [
        { required: true, message: '请输入目标描述', trigger: 'blur' }
      ],
      type: [
        { required: true, message: '请选择目标类型', trigger: 'change' }
      ],
      targetDate: [
        { required: true, message: '请选择期望完成时间', trigger: 'change' }
      ]
    }

    const completedCount = computed(() => {
      return goals.value.filter(g => g.status === '已完成').length
    })

    const inProgressCount = computed(() => {
      return goals.value.filter(g => g.status === '进行中').length
    })

    const totalCompletion = computed(() => {
      if (goals.value.length === 0) return 0;
      const totalProgress = goals.value.reduce((sum, goal) => sum + goal.progress, 0);
      return Math.round(totalProgress / goals.value.length);
    })

    const filteredGoals = computed(() => {
      if (activeFilter.value === 'all') {
        return goals.value;
      } else if (activeFilter.value === 'completed') {
        return goals.value.filter(g => g.status === '已完成');
      } else if (activeFilter.value === 'inProgress') {
        return goals.value.filter(g => g.status === '进行中');
      }
      return goals.value;
    })

    const disabledDate = (time) => {
      // 获取当天的0点0分0秒
      const today = new Date();
      today.setHours(0, 0, 0, 0);
      // 禁用当天之前的日期，只允许选择当天及之后的日期
      return time.getTime() < today.getTime();
    }

    const getStatusType = (status) => {
      return status === '已完成' ? 'success' : 'primary'
    }

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

    const getCategoryClass = (type) => {
      switch (type) {
        case 'LONG_TERM': return 'category-career';
        case 'SHORT_TERM': return 'category-health';
        default: return 'category-other';
      }
    }

    const getCategoryName = (type) => {
      switch (type) {
        case 'LONG_TERM': return '长期目标';
        case 'SHORT_TERM': return '短期目标';
        default: return '其他';
      }
    }

    const getGoalImage = (goal) => {
      // 为不同类型的目标返回不同的默认图片，避免包含文字
      switch (goal.type) {
        case 'LONG_TERM':
          return 'https://neeko-copilot.bytedance.net/api/text2image?prompt=abstract%20long%20term%20goals%20vision%20success%20planning%20no%20text&size=800x600&random=' + Math.random();
        case 'SHORT_TERM':
          return 'https://neeko-copilot.bytedance.net/api/text2image?prompt=abstract%20short%20term%20goals%20action%20progress%20no%20text&size=800x600&random=' + Math.random();
        default:
          return 'https://neeko-copilot.bytedance.net/api/text2image?prompt=abstract%20personal%20goals%20achievement%20success%20no%20text&size=800x600&random=' + Math.random();
      }
    }

    const handleCommand = ({ action, goal }) => {
      if (action === 'edit') {
        editingGoal.value = goal
        Object.assign(goalForm, {
          title: goal.title,
          description: goal.description,
          type: goal.type,
          targetDate: goal.targetDate ? new Date(goal.targetDate) : null,
          progress: goal.progress
        })
        showAddDialog.value = true
      } else if (action === 'delete') {
        ElMessageBox.confirm('确定要删除这个目标吗？', '提示', {
          confirmButtonText: '确定',
          cancelButtonText: '取消',
          type: 'warning'
        }).then(async () => {
          try {
            if (window.$axios) {
              // 准备认证头信息
              const token = localStorage.getItem('token');
              const headers = {};
              if (token) {
                headers['Authorization'] = `Bearer ${token}`;
              }
              
              // 调用后端API删除目标
              const response = await window.$axios.delete(`/goals/${goal.id}`, {
                headers: headers
              });
              
              // 根据与更新进度相同的问题，response本身是API响应体
              // response = {code: 200, message: '...', data: {...}, timestamp: '...'}
              
              // 检查响应
              if (response?.code === 200) {
                // 从本地数组中删除目标
                const index = goals.value.findIndex(g => g.id === goal.id);
                if (index > -1) {
                  goals.value.splice(index, 1);
                }
                ElMessage.success('删除成功');
              } else {
                // 删除失败，显示错误信息
                const errorMessage = response?.message || response?.msg || '删除失败';
                ElMessage.error(errorMessage);
              }
            } else {
              // 如果没有API，从本地数组中删除
              const index = goals.value.findIndex(g => g.id === goal.id);
              if (index > -1) {
                goals.value.splice(index, 1);
              }
              ElMessage.success('删除成功');
            }
          } catch (error) {
            console.error('删除目标失败:', error);
            ElMessage.error('删除失败: ' + (error.response?.data?.message || error.message));
          }
        }).catch(() => {
          // 用户取消删除
        })
      }
    }

    const saveGoal = async () => {
      if (!goalFormRef.value) return
      await goalFormRef.value.validate((valid) => {
        if (valid) {
          if (editingGoal.value) {
            // 编辑
            try {
              if (window.$axios) {
                // 使用API更新目标
                const goalData = {
                  title: goalForm.title,
                  description: goalForm.description,
                  type: goalForm.type,
                  targetDate: goalForm.targetDate ? new Date(new Date(goalForm.targetDate).setHours(12, 0, 0, 0)).toISOString().split('T')[0] : null,
                  progress: goalForm.progress
                };
                
                // 准备认证头信息
                const token = localStorage.getItem('token');
                const headers = {};
                if (token) {
                  headers['Authorization'] = `Bearer ${token}`;
                }
                
                window.$axios.put(`/goals/${editingGoal.value.id}`, goalData, {
                  headers: headers
                }).then(response => {
                  // 根据与更新进度相同的问题，response本身是API响应体
                  // response = {code: 200, message: '...', data: {更新后目标对象}, timestamp: '...'}
                  
                  // 检查响应结构
                  const apiResponse = response;
                  
                  // 检查成功状态 - 支持201创建成功和200更新成功
                  const isSuccess = (apiResponse?.code === 200 || apiResponse?.code === 201) && apiResponse?.data !== undefined;
                  
                  if (isSuccess) {
                    // 更新本地数据
                    const updatedGoal = apiResponse?.data;
                    if (updatedGoal && editingGoal.value) {
                      // 确定状态：优先使用后端返回的状态，但如果进度达到100%且状态仍为进行中，则应为已完成
                      let status = updatedGoal.status === 'COMPLETED' || updatedGoal.status === 'completed' ? '已完成' : 
                               updatedGoal.status === 'IN_PROGRESS' || updatedGoal.status === 'in_progress' ? '进行中' : 
                               updatedGoal.status === 'CANCELLED' || updatedGoal.status === 'cancelled' ? '已取消' : '进行中';
                      
                      // 补充逻辑：如果进度达到100%，但状态还不是已完成，则更新为已完成
                      if (updatedGoal.progress >= 100 && status === '进行中') {
                        status = '已完成';
                      }
                      
                      Object.assign(editingGoal.value, {
                        title: updatedGoal.title,
                        description: updatedGoal.description,
                        progress: updatedGoal.progress,
                        status: status,
                        type: updatedGoal.type,
                        targetDate: updatedGoal.targetDate,
                        completedDate: updatedGoal.completedDate
                      });
                    }
                    ElMessage.success('目标更新成功');
                    // 刷新目标列表以确保数据同步
                    loadData();
                  } else {
                    // 尝试从响应中获取错误信息
                    const errorMessage = apiResponse?.message || apiResponse?.msg || response?.statusText || '更新失败';
                    ElMessage.error(errorMessage);
                  }
                  // 无论成功还是失败，都将 editingGoal.value 设置为 null
                  editingGoal.value = null;
                }).catch(error => {
                  console.error('更新目标失败:', error);
                  ElMessage.error('更新失败: ' + (error.response?.data?.message || error.message));
                  // 错误时也将 editingGoal.value 设置为 null
                  editingGoal.value = null;
                });
              } else {
                // 如果没有API，更新本地数据
                if (editingGoal.value) {
                  Object.assign(editingGoal.value, {
                    ...goalForm,
                    status: goalForm.progress >= 100 ? '已完成' : '进行中'
                  });
                }
                ElMessage.success('目标更新成功');
                // 本地更新成功后，将 editingGoal.value 设置为 null
                editingGoal.value = null;
              }
            } catch (error) {
              console.error('更新目标失败:', error);
              ElMessage.error('更新失败: ' + (error.response?.data?.message || error.message));
              // 异常时也将 editingGoal.value 设置为 null
              editingGoal.value = null;
            }
          } else {
            // 新增
            try {
              if (window.$axios) {
                // 使用API创建目标
                // 映射前端类型到后端类型
                let backendType = 'SHORT_TERM';
                if (goalForm.type === 'career') {
                  backendType = 'LONG_TERM';
                }
                
                const goalData = {
                  title: goalForm.title,
                  description: goalForm.description,
                  type: backendType,
                  targetDate: goalForm.targetDate ? new Date(new Date(goalForm.targetDate).setHours(12, 0, 0, 0)).toISOString().split('T')[0] : null,
                  progress: goalForm.progress
                };
                
                // 准备认证头信息
                const token = localStorage.getItem('token');
                const headers = {};
                if (token) {
                  headers['Authorization'] = `Bearer ${token}`;
                }
                
                window.$axios.post('/goals', goalData, {
                  headers: headers
                }).then(response => {
                  // 根据与更新进度相同的问题，response本身是API响应体
                  // response = {code: 201, message: '...', data: {新目标对象}, timestamp: '...'}
                  
                  // 检查响应结构
                  const apiResponse = response;
                  
                  // 检查成功状态 - 支持201创建成功和200更新成功
                  const isSuccess = (apiResponse?.code === 201 || apiResponse?.code === 200) && apiResponse?.data !== undefined;
                  
                  if (isSuccess) {
                    // 添加到本地数据
                    const newGoal = apiResponse?.data;
                    if (newGoal) {
                      // 确定状态：优先使用后端返回的状态，但如果进度达到100%且状态仍为进行中，则应为已完成
                      let status = newGoal.status === 'COMPLETED' || newGoal.status === 'completed' ? '已完成' : 
                               newGoal.status === 'IN_PROGRESS' || newGoal.status === 'in_progress' ? '进行中' : 
                               newGoal.status === 'CANCELLED' || newGoal.status === 'cancelled' ? '已取消' : '进行中';
                      
                      // 补充逻辑：如果进度达到100%，但状态还不是已完成，则更新为已完成
                      if (newGoal.progress >= 100 && status === '进行中') {
                        status = '已完成';
                      }
                      
                      goals.value.push({
                        id: newGoal.id,
                        title: newGoal.title,
                        description: newGoal.description,
                        progress: newGoal.progress,
                        status: status,
                        type: newGoal.type,
                        targetDate: newGoal.targetDate,
                        completedDate: newGoal.completedDate,
                        enableReminder: newGoal.enableReminder
                      });
                    }
                    ElMessage.success('目标添加成功');
                    // 刷新目标列表以确保数据同步
                    loadData();
                  } else {
                    // 尝试从响应中获取错误信息
                    const errorMessage = apiResponse?.message || apiResponse?.msg || response?.statusText || '添加失败';
                    ElMessage.error(errorMessage);
                  }
                  // 无论成功还是失败，都关闭弹窗并重置表单
                  showAddDialog.value = false;
                  resetForm();
                }).catch(error => {
                  console.error('添加目标失败:', error);
                  ElMessage.error('添加失败: ' + (error.response?.data?.message || error.message));
                  // 错误时也关闭弹窗并重置表单
                  showAddDialog.value = false;
                  resetForm();
                });
              } else {
                // 如果没有API，添加到本地数据
                goals.value.push({
                  id: Date.now(),
                  ...goalForm,
                  status: goalForm.progress >= 100 ? '已完成' : '进行中'
                });
                ElMessage.success('目标添加成功');
                // 本地添加成功后，关闭弹窗并重置表单
                showAddDialog.value = false;
                resetForm();
              }
            } catch (error) {
              console.error('添加目标失败:', error);
              ElMessage.error('添加失败: ' + (error.response?.data?.message || error.message));
              // 异常时也关闭弹窗并重置表单
              showAddDialog.value = false;
              resetForm();
            }
          }
        }
      })
    }

    const resetForm = () => {
      Object.assign(goalForm, {
        title: '',
        description: '',
        type: 'career',
        targetDate: '',
        progress: 0,
        enableReminder: true
      })
      editingGoal.value = null
    }

    const updateProgress = (goal) => {
      currentProgressGoal.value = goal
      progressForm.progress = goal.progress
      progressForm.targetDate = goal.targetDate ? new Date(goal.targetDate) : ''
      progressForm.reflection = ''
      showProgressDialog.value = true
    }

    const saveProgress = async () => {
      if (currentProgressGoal.value) {
        try {
          if (window.$axios) {
            console.log('Starting goal update...');
            console.log('Axios instance:', window.$axios);
            
            // 准备认证头信息
            const token = localStorage.getItem('token');
            console.log('Token:', token);
            const headers = {};
            if (token) {
              headers['Authorization'] = `Bearer ${token}`;
            }
            
            console.log('Headers:', headers);
            console.log('Progress form progress:', progressForm.progress);
            console.log('Progress form targetDate:', progressForm.targetDate);
            console.log('Progress form reflection:', progressForm.reflection);
            console.log('Current goal ID:', currentProgressGoal.value.id);
            
            // 将前端显示状态转换为后端期望的英文状态值
            const statusMap = {
              '已完成': 'COMPLETED',
              '进行中': 'IN_PROGRESS',
              '已取消': 'CANCELLED'
            };
            
            // 如果进度达到100%，自动将状态设置为已完成
            let backendStatus = statusMap[currentProgressGoal.value.status] || 'IN_PROGRESS';
            if (progressForm.progress >= 100) {
              backendStatus = 'COMPLETED';
            } else if (backendStatus === 'COMPLETED' && progressForm.progress < 100) {
              // 如果进度低于100%但当前状态是已完成，改为进行中
              backendStatus = 'IN_PROGRESS';
            }
            
            // 构建更新目标对象
            const updateGoalData = {
              title: currentProgressGoal.value.title,
              description: currentProgressGoal.value.description,
              type: currentProgressGoal.value.type,
              targetDate: progressForm.targetDate ? new Date(progressForm.targetDate).toISOString().split('T')[0] : null,
              progress: progressForm.progress,
              status: backendStatus
            };
            
            // 使用API更新目标
            const response = await window.$axios.put(`/goals/${currentProgressGoal.value.id}`, updateGoalData, {
              headers: headers
            });
            
            console.log('Goal update response:', response);

            // 根据控制台输出，响应结构为：
            // response = {code: 200, message: '...', data: {目标对象}, timestamp: '...'}
            // 所以 response.data 是目标对象，response.code 是状态码

            console.log('Full response:', response);

            // 检查是否是 {code, message, data, timestamp} 格式
            if (response && typeof response === 'object' && response.code !== undefined && response.data !== undefined) {
              // 完整的API响应格式
              const isSuccess = (response.code === 200 || response.code === 201);

              console.log('Response code:', response.code);
              console.log('Response data field exists:', response.data !== undefined);
              console.log('Is success:', isSuccess);

              if (isSuccess) {
                const updatedGoal = response.data;
                if (updatedGoal) {
                  // 更新本地目标数据
                  currentProgressGoal.value.progress = updatedGoal.progress;
                  currentProgressGoal.value.targetDate = updatedGoal.targetDate;
                  // 根据后端返回的状态值更新显示状态
                  if (updatedGoal.status === 'COMPLETED' || updatedGoal.status === 'completed') {
                    currentProgressGoal.value.status = '已完成';
                  } else if (updatedGoal.status === 'IN_PROGRESS' || updatedGoal.status === 'in_progress') {
                    currentProgressGoal.value.status = '进行中';
                  } else if (updatedGoal.status === 'CANCELLED' || updatedGoal.status === 'cancelled') {
                    currentProgressGoal.value.status = '已取消';
                  } else {
                    // 默认设置为进行中
                    currentProgressGoal.value.status = '进行中';
                  }
                  // 补充逻辑：如果进度达到100%，但状态还不是已完成，则更新为已完成
                  if (updatedGoal.progress >= 100 && currentProgressGoal.value.status !== '已完成') {
                    currentProgressGoal.value.status = '已完成';
                  } else if (updatedGoal.progress < 100 && currentProgressGoal.value.status === '已完成') {
                    // 如果进度低于100%但状态是已完成，改为进行中
                    currentProgressGoal.value.status = '进行中';
                  }
                }
                console.log('Goal update successful, showing success message');
                ElMessage.success('计划更新成功');
                // 刷新目标列表以确保数据同步
                console.log('Calling loadData to refresh data');
                loadData();
                console.log('Data refresh initiated');
              } else {
                // 尝试从响应中获取错误信息
                const errorMessage = response.message || response.msg || '更新失败';
                console.log('Failed to update goal, showing error:', errorMessage);
                ElMessage.error(errorMessage);
              }
            } else {
              // 不是预期的API响应格式
              console.log('Unexpected response format');
              ElMessage.error('更新失败: 响应格式异常');
            }
          } else {
            // 如果没有API，直接更新本地数据
            currentProgressGoal.value.progress = progressForm.progress;
            currentProgressGoal.value.targetDate = progressForm.targetDate;
            // 更新状态
            if (progressForm.progress >= 100) {
              currentProgressGoal.value.status = '已完成';
            } else if (currentProgressGoal.value.status === '已完成') {
              currentProgressGoal.value.status = '进行中';
            }
            ElMessage.success('计划更新成功');
          }
        } catch (error) {
          console.error('更新计划失败:', error);
          console.error('Error details:', error.response || error.message || error);
              
          // 根据错误类型提供更准确的错误信息
          if (error.response) {
            // 服务器返回了错误响应
            const errorMsg = error.response.data?.message || error.response.statusText || '服务器错误';
            ElMessage.error(`更新失败: ${errorMsg} (${error.response.status})`);
          } else if (error.request) {
            // 请求已发出但没有收到响应（网络错误等）
            ElMessage.error('网络连接失败，请检查网络后重试');
          } else {
            // 其他错误
            ElMessage.error('更新失败: ' + (error.message || '未知错误'));
          }
        } finally {
          showProgressDialog.value = false
        }
      }
    }

    const updateReminder = async (goal) => {
      try {
        if (window.$axios) {
          // 准备认证头信息
          const token = localStorage.getItem('token');
          const headers = {};
          if (token) {
            headers['Authorization'] = `Bearer ${token}`;
          }
          
          // 使用API更新提醒设置
          window.$axios.patch(`/goals/${goal.id}/reminder`, {
            enableReminder: !goal.enableReminder
          }, {
            headers: headers
          }).then(response => {
            // 根据与更新进度相同的问题，response本身是API响应体
            // response = {code: 200, message: '...', data: {更新后目标对象}, timestamp: '...'}
            
            // 检查响应结构
            const apiResponse = response;
            
            // 检查成功状态 - 支持201创建成功和200更新成功
            const isSuccess = (apiResponse?.code === 200 || apiResponse?.code === 201) && apiResponse?.data !== undefined;
            
            if (isSuccess) {
              const updatedGoal = apiResponse?.data;
              if (updatedGoal) {
                goal.enableReminder = updatedGoal.enableReminder;
                // 同时更新状态，以防后端逻辑改变了状态
                if (updatedGoal.status === 'COMPLETED' || updatedGoal.status === 'completed') {
                  goal.status = '已完成';
                } else if (updatedGoal.status === 'IN_PROGRESS' || updatedGoal.status === 'in_progress') {
                  goal.status = '进行中';
                } else if (updatedGoal.status === 'CANCELLED' || updatedGoal.status === 'cancelled') {
                  goal.status = '已取消';
                }
                // 补充逻辑：如果进度达到100%，但状态还不是已完成，则更新为已完成
                else if (updatedGoal.progress >= 100 && goal.status !== '已完成') {
                  goal.status = '已完成';
                }
              }
              ElMessage.success(`提醒已${goal.enableReminder ? '开启' : '关闭'}`);
              // 刷新目标列表以确保数据同步
              loadData();
            } else {
              // 尝试从响应中获取错误信息
              const errorMessage = apiResponse?.message || apiResponse?.msg || response?.statusText || '更新失败';
              ElMessage.error(errorMessage);
            }
          }).catch(error => {
            console.error('更新提醒设置失败:', error);
            ElMessage.error('更新失败: ' + (error.response?.data?.message || error.message));
          });
        } else {
          // 如果没有API，更新本地数据
          goal.enableReminder = !goal.enableReminder;
          ElMessage.success(`提醒已${goal.enableReminder ? '开启' : '关闭'}`);
        }
      } catch (error) {
        console.error('更新提醒设置失败:', error);
        ElMessage.error('更新失败: ' + (error.response?.data?.message || error.message));
      }
    }

    // 获取目标状态文本
    const getStatusText = (goal) => {
      if (goal.progress >= 100) {
        return '已完成';
      }
      
      if (goal.targetDate) {
        const targetDate = new Date(goal.targetDate);
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        
        if (targetDate < today) {
          return '未完成';
        }
      }
      
      return '进行中';
    }

    // 获取目标状态样式类
    const getStatusClass = (goal) => {
      if (goal.progress >= 100) {
        return 'status-completed';
      }
      
      if (goal.targetDate) {
        const targetDate = new Date(goal.targetDate);
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        
        if (targetDate < today) {
          return 'status-unfinished';
        }
      }
      
      return 'status-in-progress';
    }

    return {
      showAddDialog,
      showProgressDialog,
      editingGoal,
      goalFormRef,
      goals,
      goalForm,
      progressForm,
      goalRules,
      completedCount,
      inProgressCount,
      totalCompletion,
      activeFilter,
      filteredGoals,
      disabledDate,
      getStatusType,
      formatDate,
      getCategoryClass,
      getCategoryName,
      getGoalImage,
      handleCommand,
      saveGoal,
      resetForm,
      updateProgress,
      saveProgress,
      updateReminder,
      getStatusText,
      getStatusClass
    }
  }
}
</script>

<style scoped>
.goals {
  padding: 0;
  margin: 0;
  width: 100%;
  min-height: calc(100vh - 120px);
  background: linear-gradient(135deg, #f8f9ff 0%, #eef2ff 100%);
}

/* 状态样式 */
.progress-status {
  font-weight: bold;
}

.status-completed {
  color: #67C23A;
}

.status-in-progress {
  color: #E6A23C;
}

.status-unfinished {
  color: #F56C6C;
}

.container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 40px 20px;
}

/* 顶部标题和按钮 */
.goals-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 30px;
  padding-bottom: 20px;
  border-bottom: 1px solid #f0f0f0;
}

.header-content h2 {
  color: #333;
  font-size: 32px;
  font-weight: 600;
  margin: 0 0 12px 0;
}

.header-content p {
  color: #666;
  font-size: 16px;
  margin: 0;
  line-height: 1.5;
}

.create-button {
  font-size: 14px;
  padding: 10px 20px;
  border-radius: 25px;
  box-shadow: 0 2px 8px rgba(64, 158, 255, 0.3);
  transition: all 0.3s ease;
}

.create-button:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(64, 158, 255, 0.4);
}

/* 数据卡片区域 */
.stats-row {
  margin-bottom: 30px;
}

.stat-card {
  border-radius: 12px;
  border: 1px solid #e8e8e8;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
  transition: all 0.3s ease;
  overflow: hidden;
}

.stat-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.12);
}

/* 总完成度卡片 */
/* 总完成度卡片 */
.completion-content {
  text-align: center;
  padding: 24px 16px;
  height: 240px;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
}

.progress-ring {
  margin-bottom: 20px;
}

.progress-svg {
  transition: all 0.3s ease;
}

.progress-circle {
  transition: stroke-dashoffset 0.5s ease;
}

.progress-percent {
  font-size: 24px;
  font-weight: 700;
  fill: #333;
}

.progress-label {
  font-size: 14px;
  fill: #666;
}

.section-title {
  font-size: 16px;
  font-weight: 600;
  color: #333;
  margin: 0 0 8px 0;
}

.section-desc {
  font-size: 14px;
  color: #666;
  margin: 0;
}

/* 其他统计卡片 */
.stat-content {
  text-align: center;
  padding: 24px 16px;
  height: 240px;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
}

.stat-header {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 6px 12px;
  border-radius: 20px;
  margin-bottom: 20px;
}

.stat-header .stat-icon {
  font-size: 16px;
  color: #fff;
}

.stat-tag {
  font-size: 12px;
  font-weight: 500;
  color: #fff;
}

.blue-bg {
  background: rgba(64, 158, 255, 0.2);
}

.blue-bg .stat-icon,
.blue-bg .stat-tag {
  color: #409EFF;
}

.green-bg {
  background: rgba(103, 194, 58, 0.2);
}

.green-bg .stat-icon,
.green-bg .stat-tag {
  color: #67c23a;
}

.orange-bg {
  background: rgba(230, 162, 60, 0.2);
}

.orange-bg .stat-icon,
.orange-bg .stat-tag {
  color: #e6a23c;
}

.stat-value {
  font-size: 32px;
  font-weight: 700;
  color: #333;
  margin-bottom: 8px;
  line-height: 1;
}

.stat-label {
  font-size: 14px;
  color: #666;
}

/* 标签筛选栏 */
.filter-bar {
  display: flex;
  gap: 12px;
  margin-bottom: 24px;
  padding: 16px;
  background: #ffffff;
  border-radius: 8px;
}

.filter-bar .el-tag {
  padding: 8px 20px;
  border-radius: 20px;
  font-size: 14px;
  cursor: pointer;
  transition: all 0.3s ease;
}

.filter-bar .el-tag.active {
  background: #409EFF;
  color: white;
}

.filter-bar .el-tag:not(.active):hover {
  background: #ecf5ff;
  color: #409EFF;
}

/* 目标卡片列表 */
.goal-list {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 24px;
  margin-bottom: 80px;
}

.goal-card {
  border-radius: 12px;
  border: 1px solid #e8e8e8;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
  transition: all 0.3s ease;
  overflow: hidden;
  position: relative;
}

.goal-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.12);
}

/* 分类标签 */
.goal-category {
  display: inline-block;
  padding: 4px 12px;
  border-radius: 20px;
  font-size: 12px;
  font-weight: 500;
  background: #f0f0f0;
  color: #666;
  margin-bottom: 16px;
}

/* 标题 */
.goal-title {
  font-size: 18px;
  font-weight: 600;
  color: #333;
  margin: 0 0 12px 0;
  line-height: 1.4;
}

/* 进度条 */
.progress-section {
  margin-bottom: 16px;
}

.progress-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 8px;
  font-size: 14px;
  color: #666;
}

.progress-percent {
  font-weight: 600;
  color: #409EFF;
}

/* 日期信息 */
.date-info {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 20px;
  font-size: 14px;
  color: #666;
}

.date-info :deep(.el-icon) {
  font-size: 16px;
  color: #999;
}

/* 操作区 */
.goal-actions {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-top: 12px;
}

.view-detail {
  font-size: 14px;
  color: #409EFF;
  text-decoration: none;
  transition: color 0.3s ease;
}

.view-detail:hover {
  color: #66b1ff;
}

.update-plan {
  font-size: 14px;
  color: #666;
  border: 1px solid #dcdfe6;
  border-radius: 20px;
  padding: 4px 16px;
  background: #ffffff;
  transition: all 0.3s ease;
}

.update-plan:hover {
  border-color: #c6e2ff;
  color: #409EFF;
}

/* 悬浮添加按钮 */
.floating-btn {
  position: fixed;
  bottom: 30px;
  right: 30px;
  width: 60px;
  height: 60px;
  border-radius: 50%;
  font-size: 24px;
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: 0 4px 16px rgba(64, 158, 255, 0.4);
  transition: all 0.3s ease;
  z-index: 100;
}

.floating-btn:hover {
  transform: scale(1.1);
  box-shadow: 0 6px 20px rgba(64, 158, 255, 0.5);
}

/* 空状态 */
.empty-state {
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: 300px;
  background: white;
  border-radius: 12px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
  margin: 20px 0;
}

/* 响应式设计 */
@media (max-width: 768px) {
  .container {
    padding: 20px 16px;
  }
  
  .goals-header {
    flex-direction: column;
    align-items: flex-start;
    gap: 16px;
  }
  
  .create-button {
    align-self: flex-start;
  }
  
  .goal-list {
    grid-template-columns: 1fr;
  }
  
  .filter-bar {
    flex-wrap: wrap;
  }
  
  .floating-btn {
    bottom: 20px;
    right: 20px;
    width: 50px;
    height: 50px;
    font-size: 20px;
  }
}
</style>