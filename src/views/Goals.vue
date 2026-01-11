<template>
  <div class="goals">
    <div class="goals-header">
      <div>
        <h2>我的目标</h2>
        <p>设定和追踪你的个人目标</p>
      </div>
      <el-button type="primary" @click="showAddDialog = true">
        <el-icon><Plus /></el-icon>
        添加目标
      </el-button>
    </div>

    <!-- 目标统计图表 -->
    <el-row :gutter="20" class="stats-row">
      <el-col :xs="24" :sm="12" :md="8">
        <el-card class="stat-card">
          <div class="stat-content">
            <div class="stat-icon total">
              <el-icon><Trophy /></el-icon>
            </div>
            <div class="stat-info">
              <div class="stat-value">{{ goals.length }}</div>
              <div class="stat-label">总目标数</div>
            </div>
          </div>
        </el-card>
      </el-col>
      <el-col :xs="24" :sm="12" :md="8">
        <el-card class="stat-card">
          <div class="stat-content">
            <div class="stat-icon completed">
              <el-icon><CircleCheck /></el-icon>
            </div>
            <div class="stat-info">
              <div class="stat-value">{{ completedCount }}</div>
              <div class="stat-label">已完成</div>
            </div>
          </div>
        </el-card>
      </el-col>
      <el-col :xs="24" :sm="12" :md="8">
        <el-card class="stat-card">
          <div class="stat-content">
            <div class="stat-icon progress">
              <el-icon><Clock /></el-icon>
            </div>
            <div class="stat-info">
              <div class="stat-value">{{ inProgressCount }}</div>
              <div class="stat-label">进行中</div>
            </div>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 进度图表 -->
    <el-card class="chart-card" v-if="goals.length > 0">
      <template #header>
        <span>目标完成情况</span>
      </template>
      <div class="chart-container">
        <div class="chart-item" v-for="goal in goals" :key="goal.id">
          <div class="chart-label">{{ goal.title }}</div>
          <el-progress 
            :percentage="goal.progress" 
            :status="goal.status === '已完成' ? 'success' : ''"
            :stroke-width="20"
            :format="() => `${goal.progress}%`"
          />
        </div>
      </div>
    </el-card>
    
    <!-- 目标列表 -->
    <div class="goal-list">
      <el-card 
        class="goal-card" 
        v-for="goal in goals" 
        :key="goal.id"
        shadow="hover"
      >
        <template #header>
          <div class="goal-header">
            <div class="goal-title-section">
              <el-icon class="goal-icon" :class="goal.type">
                <Trophy v-if="goal.type === 'long-term'" />
                <Flag v-else />
              </el-icon>
              <span class="goal-title">{{ goal.title }}</span>
            </div>
            <div class="goal-actions">
              <el-tag :type="getStatusType(goal.status)" size="small">
                {{ goal.status }}
              </el-tag>
              <el-dropdown @command="handleCommand">
                <el-button type="text" size="small">
                  <el-icon><MoreFilled /></el-icon>
                </el-button>
                <template #dropdown>
                  <el-dropdown-menu>
                    <el-dropdown-item :command="{action: 'edit', goal}">编辑</el-dropdown-item>
                    <el-dropdown-item :command="{action: 'delete', goal}">删除</el-dropdown-item>
                  </el-dropdown-menu>
                </template>
              </el-dropdown>
            </div>
          </div>
        </template>
        <div class="goal-content">
          <p class="goal-description">{{ goal.description }}</p>
          <div class="goal-meta">
            <span class="goal-type">
              <el-tag size="small" :type="goal.type === 'long-term' ? 'warning' : 'success'">
                {{ goal.type === 'long-term' ? '长期目标' : '短期目标' }}
              </el-tag>
            </span>
            <span class="goal-date">
              <el-icon><Calendar /></el-icon>
              期望完成：{{ formatDate(goal.targetDate) }}
            </span>
          </div>
          <div class="progress-section">
            <div class="progress-header">
              <span>完成进度</span>
              <span class="progress-percent">{{ goal.progress }}%</span>
            </div>
            <el-progress 
              :percentage="goal.progress" 
              :status="goal.status === '已完成' ? 'success' : ''"
              :stroke-width="12"
            />
          </div>
          <div class="goal-footer">
            <el-switch
              v-model="goal.enableReminder"
              active-text="开启提醒"
              inactive-text="关闭提醒"
              @change="updateReminder(goal)"
            />
            <el-button 
              type="text" 
              size="small" 
              @click="updateProgress(goal)"
              v-if="goal.status === '进行中'"
            >
              更新进度
            </el-button>
          </div>
        </div>
      </el-card>
    </div>

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
            <el-radio label="short-term">短期目标</el-radio>
            <el-radio label="long-term">长期目标</el-radio>
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
        <el-form-item label="开启提醒">
          <el-switch v-model="goalForm.enableReminder" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="showAddDialog = false">取消</el-button>
        <el-button type="primary" @click="saveGoal">保存</el-button>
      </template>
    </el-dialog>

    <!-- 更新进度对话框 -->
    <el-dialog v-model="showProgressDialog" title="更新进度" width="400px">
      <el-form :model="progressForm" label-width="80px">
        <el-form-item label="完成进度">
          <el-slider v-model="progressForm.progress" :max="100" show-input />
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
import { Plus, CircleCheck, Clock, Trophy, MoreFilled, Calendar, Flag } from '@element-plus/icons-vue'

export default {
  name: 'Goals',
  components: {
    Plus,
    CircleCheck,
    Clock,
    Trophy,
    Flag,
    MoreFilled,
    Calendar
  },
  setup() {
    const showAddDialog = ref(false)
    const showProgressDialog = ref(false)
    const editingGoal = ref(null)
    const goalFormRef = ref(null)
    const currentProgressGoal = ref(null)

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
                  type: goal.type === 'LONG_TERM' ? 'long-term' : 'short-term',
                  targetDate: goal.targetDate,
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
      type: 'short-term',
      targetDate: '',
      progress: 0,
      enableReminder: true
    })

    const progressForm = reactive({
      progress: 0
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

    const disabledDate = (time) => {
      return time.getTime() < Date.now() - 8.64e7
    }

    const getStatusType = (status) => {
      return status === '已完成' ? 'success' : 'primary'
    }

    const formatDate = (date) => {
      if (!date) return ''
      const d = new Date(date)
      return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`
    }

    const handleCommand = ({ action, goal }) => {
      if (action === 'edit') {
        editingGoal.value = goal
        Object.assign(goalForm, {
          title: goal.title,
          description: goal.description,
          type: goal.type,
          targetDate: goal.targetDate,
          progress: goal.progress,
          enableReminder: goal.enableReminder
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
                  type: goalForm.type === 'long-term' ? 'LONG_TERM' : 'SHORT_TERM',
                  targetDate: goalForm.targetDate,
                  progress: goalForm.progress,
                  enableReminder: goalForm.enableReminder
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
                    if (updatedGoal) {
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
                        type: updatedGoal.type === 'LONG_TERM' ? 'long-term' : 'short-term',
                        targetDate: updatedGoal.targetDate,
                        enableReminder: updatedGoal.enableReminder
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
                }).catch(error => {
                  console.error('更新目标失败:', error);
                  ElMessage.error('更新失败: ' + (error.response?.data?.message || error.message));
                });
              } else {
                // 如果没有API，更新本地数据
                Object.assign(editingGoal.value, {
                  ...goalForm,
                  status: goalForm.progress >= 100 ? '已完成' : '进行中'
                });
                ElMessage.success('目标更新成功');
              }
            } catch (error) {
              console.error('更新目标失败:', error);
              ElMessage.error('更新失败: ' + (error.response?.data?.message || error.message));
            }
            editingGoal.value = null
          } else {
            // 新增
            try {
              if (window.$axios) {
                // 使用API创建目标
                const goalData = {
                  title: goalForm.title,
                  description: goalForm.description,
                  type: goalForm.type === 'long-term' ? 'LONG_TERM' : 'SHORT_TERM',
                  targetDate: goalForm.targetDate,
                  progress: goalForm.progress,
                  enableReminder: goalForm.enableReminder
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
                        type: newGoal.type === 'LONG_TERM' ? 'long-term' : 'short-term',
                        targetDate: newGoal.targetDate,
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
                }).catch(error => {
                  console.error('添加目标失败:', error);
                  ElMessage.error('添加失败: ' + (error.response?.data?.message || error.message));
                });
              } else {
                // 如果没有API，添加到本地数据
                goals.value.push({
                  id: Date.now(),
                  ...goalForm,
                  status: goalForm.progress >= 100 ? '已完成' : '进行中'
                });
                ElMessage.success('目标添加成功');
              }
            } catch (error) {
              console.error('添加目标失败:', error);
              ElMessage.error('添加失败: ' + (error.response?.data?.message || error.message));
            }
          }
          showAddDialog.value = false
          resetForm()
        }
      })
    }

    const resetForm = () => {
      Object.assign(goalForm, {
        title: '',
        description: '',
        type: 'short-term',
        targetDate: '',
        progress: 0,
        enableReminder: true
      })
      editingGoal.value = null
    }

    const updateProgress = (goal) => {
      currentProgressGoal.value = goal
      progressForm.progress = goal.progress
      showProgressDialog.value = true
    }

    const saveProgress = async () => {
      if (currentProgressGoal.value) {
        try {
          if (window.$axios) {
            console.log('Starting progress update...');
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
            console.log('Current goal ID:', currentProgressGoal.value.id);
            
            // 使用API更新目标进度
            const response = await window.$axios.patch(`/goals/${currentProgressGoal.value.id}/progress`, {
              progress: progressForm.progress
            }, {
              headers: headers
            });
            
            console.log('Progress update response:', response);

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
                  currentProgressGoal.value.progress = updatedGoal.progress;
                  // 根据后端返回的状态值更新显示状态
                  if (updatedGoal.status === 'COMPLETED' || updatedGoal.status === 'completed') {
                    currentProgressGoal.value.status = '已完成';
                  } else if (updatedGoal.status === 'IN_PROGRESS' || updatedGoal.status === 'in_progress') {
                    currentProgressGoal.value.status = '进行中';
                  } else if (updatedGoal.status === 'CANCELLED' || updatedGoal.status === 'cancelled') {
                    currentProgressGoal.value.status = '已取消';
                  }
                  // 补充逻辑：如果进度达到100%，但状态还不是已完成，则更新为已完成
                  else if (updatedGoal.progress >= 100 && currentProgressGoal.value.status !== '已完成') {
                    currentProgressGoal.value.status = '已完成';
                  }
                }
                console.log('Progress update successful, showing success message');
                ElMessage.success('进度更新成功');
                // 刷新目标列表以确保数据同步
                console.log('Calling loadData to refresh data');
                loadData();
                console.log('Data refresh initiated');
              } else {
                // 尝试从响应中获取错误信息
                const errorMessage = response.message || response.msg || '更新失败';
                console.log('Failed to update progress, showing error:', errorMessage);
                ElMessage.error(errorMessage);
              }
            } else {
              // 不是预期的API响应格式
              console.log('Unexpected response format');
              ElMessage.error('更新失败: 响应格式异常');
            }
          }
        } catch (error) {
          console.error('更新进度失败:', error);
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
      disabledDate,
      getStatusType,
      formatDate,
      handleCommand,
      saveGoal,
      resetForm,
      updateProgress,
      saveProgress,
      updateReminder
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
}

.goals-header {
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

/* 统计卡片 */
.stats-row {
  margin-bottom: 20px;
}

.stat-card {
  border-radius: 8px;
}

.stat-content {
  display: flex;
  align-items: center;
  gap: 16px;
}

.stat-icon {
  width: 60px;
  height: 60px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 28px;
  color: white;
}

.stat-icon.total {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
}

.stat-icon.completed {
  background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
}

.stat-icon.progress {
  background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%);
}

.stat-info {
  flex: 1;
}

.stat-value {
  font-size: 28px;
  font-weight: 600;
  color: #333;
  line-height: 1;
  margin-bottom: 4px;
}

.stat-label {
  font-size: 14px;
  color: #999;
}

/* 图表卡片 */
.chart-card {
  margin-bottom: 20px;
}

.chart-container {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.chart-item {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.chart-label {
  font-size: 14px;
  color: #666;
  margin-bottom: 4px;
}

/* 目标列表 */
.goal-list {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.goal-card {
  border-radius: 8px;
  transition: transform 0.3s ease;
}

.goal-card:hover {
  transform: translateY(-2px);
}

.goal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.goal-title-section {
  display: flex;
  align-items: center;
  gap: 8px;
  flex: 1;
  min-width: 0;
}

.goal-icon {
  font-size: 20px;
  color: #409EFF;
}

.goal-icon.long-term {
  color: #E6A23C;
}

.goal-title {
  font-size: 16px;
  font-weight: 600;
  color: #333;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.goal-actions {
  display: flex;
  align-items: center;
  gap: 8px;
}

.goal-content {
  padding-top: 0;
}

.goal-description {
  color: #666;
  font-size: 14px;
  line-height: 1.6;
  margin: 0 0 12px 0;
}

.goal-meta {
  display: flex;
  gap: 16px;
  margin-bottom: 16px;
  flex-wrap: wrap;
}

.goal-date {
  display: flex;
  align-items: center;
  gap: 4px;
  font-size: 12px;
  color: #999;
}

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

.goal-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding-top: 12px;
  border-top: 1px solid #f0f0f0;
}
</style>