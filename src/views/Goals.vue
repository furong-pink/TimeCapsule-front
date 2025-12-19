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
import { ref, reactive, computed } from 'vue'
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

    const goals = ref([
      {
        id: 1,
        title: '学习新技术',
        description: '掌握Vue 3和Element Plus的使用',
        progress: 70,
        status: '进行中',
        type: 'short-term',
        targetDate: '2025-06-30',
        enableReminder: true
      },
      {
        id: 2,
        title: '健身计划',
        description: '每周锻炼3次，持续3个月',
        progress: 100,
        status: '已完成',
        type: 'short-term',
        targetDate: '2025-03-31',
        enableReminder: false
      },
      {
        id: 3,
        title: '阅读目标',
        description: '今年读完12本书',
        progress: 30,
        status: '进行中',
        type: 'long-term',
        targetDate: '2025-12-31',
        enableReminder: true
      }
    ])

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
        }).then(() => {
          const index = goals.value.findIndex(g => g.id === goal.id)
          if (index > -1) {
            goals.value.splice(index, 1)
            ElMessage.success('删除成功')
          }
        }).catch(() => {})
      }
    }

    const saveGoal = async () => {
      if (!goalFormRef.value) return
      await goalFormRef.value.validate((valid) => {
        if (valid) {
          if (editingGoal.value) {
            // 编辑
            Object.assign(editingGoal.value, {
              ...goalForm,
              status: goalForm.progress >= 100 ? '已完成' : '进行中'
            })
            ElMessage.success('目标更新成功')
            editingGoal.value = null
          } else {
            // 新增
            goals.value.push({
              id: Date.now(),
              ...goalForm,
              status: goalForm.progress >= 100 ? '已完成' : '进行中'
            })
            ElMessage.success('目标添加成功')
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

    const saveProgress = () => {
      if (currentProgressGoal.value) {
        currentProgressGoal.value.progress = progressForm.progress
        if (progressForm.progress >= 100) {
          currentProgressGoal.value.status = '已完成'
        }
        ElMessage.success('进度更新成功')
        showProgressDialog.value = false
      }
    }

    const updateReminder = (goal) => {
      ElMessage.success(`提醒已${goal.enableReminder ? '开启' : '关闭'}`)
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