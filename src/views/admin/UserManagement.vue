<template>
  <div class="user-management">
    <div class="page-header">
      <div class="header-left">
        <h2>用户管理</h2>
        <p>管理系统用户，包括启用/禁用账号</p>
      </div>
      <div class="header-right">
        <el-button type="primary" @click="showAddModal = true">
          <el-icon><Plus /></el-icon>
          新增用户
        </el-button>
      </div>
    </div>

    <!-- 筛选条件 -->
    <el-card class="filter-card" shadow="never">
      <el-form :inline="true" :model="queryForm" class="filter-form">
        <el-form-item label="账号">
          <el-input 
            v-model="queryForm.account" 
            placeholder="请输入账号" 
            clearable 
            style="width: 200px;"
          />
        </el-form-item>
        <el-form-item label="状态">
          <el-select v-model="queryForm.status" placeholder="全部状态" clearable style="width: 150px;">
            <el-option label="正常" :value="1" />
            <el-option label="禁用" :value="0" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="handleSearch">
            <el-icon><Search /></el-icon>
            查询
          </el-button>
          <el-button @click="handleReset">
            <el-icon><Refresh /></el-icon>
            重置
          </el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <!-- 用户列表表格 -->
    <el-card class="table-card" shadow="never">
      <el-table 
        :data="userList" 
        v-loading="loading"
        border
        stripe
        style="width: 100%;"
      >
        <el-table-column type="index" label="序号" width="60" align="center" />
        <el-table-column label="头像" width="80" align="center">
          <template #default="{ row }">
            <el-avatar :size="40" :src="row.avatar">
              <el-icon><User /></el-icon>
            </el-avatar>
          </template>
        </el-table-column>
        <el-table-column prop="account" label="账号" min-width="120" />
        <el-table-column prop="nickname" label="昵称" min-width="100" />
        <el-table-column label="角色" width="100" align="center">
          <template #default="{ row }">
            <el-tag :type="row.role === 'ADMIN' ? 'warning' : 'info'">
              {{ row.role === 'ADMIN' ? '管理员' : '普通用户' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="状态" width="80" align="center">
          <template #default="{ row }">
            <el-tag :type="row.status ? 'success' : 'danger'">
              {{ row.status ? '正常' : '禁用' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="注册时间" width="160" align="center">
          <template #default="{ row }">
            {{ formatDateTime(row.createdAt) }}
          </template>
        </el-table-column>
        <el-table-column label="最后登录" width="160" align="center">
          <template #default="{ row }">
            {{ formatDateTime(row.lastLoginAt) }}
          </template>
        </el-table-column>
        <el-table-column label="操作" width="120" align="center" fixed="right">
          <template #default="{ row }">
            <el-button
              v-if="row.status && !isCurrentUser(row.id)"
              type="danger"
              size="small"
              @click="handleDisable(row)"
            >
              禁用
            </el-button>
            <el-button
              v-else-if="row.status && isCurrentUser(row.id)"
              type="info"
              size="small"
              disabled
            >
              当前用户
            </el-button>
            <el-button
              v-else
              type="success"
              size="small"
              @click="handleEnable(row)"
            >
              启用
            </el-button>
          </template>
        </el-table-column>
      </el-table>

      <!-- 分页 -->
      <el-pagination
        v-model:current-page="pagination.pageNum"
        v-model:page-size="pagination.pageSize"
        :page-sizes="[10, 20, 50, 100]"
        :total="pagination.total"
        layout="total, sizes, prev, pager, next, jumper"
        @size-change="handleSizeChange"
        @current-change="handlePageChange"
        style="margin-top: 20px; justify-content: flex-end;"
      />
    </el-card>
  </div>

  <!-- 新增用户弹窗 -->
  <el-dialog
    v-model="showAddModal"
    title="新增用户"
    width="450px"
    :close-on-click-modal="false"
  >
    <el-form :model="addForm" ref="addFormRef" label-width="100px" class="add-user-form">
      <el-form-item label="账号" prop="account">
        <el-input 
          v-model="addForm.account" 
          placeholder="请输入账号（邮箱格式）"
          clearable
        />
      </el-form-item>
      <el-form-item label="昵称" prop="nickname">
        <el-input 
          v-model="addForm.nickname" 
          placeholder="请输入昵称"
          clearable
        />
      </el-form-item>
      <el-form-item label="密码" prop="password">
        <el-input 
          v-model="addForm.password" 
          type="password" 
          placeholder="请输入密码"
        />
      </el-form-item>
      <el-form-item label="角色" prop="role">
        <el-select v-model="addForm.role" placeholder="请选择角色">
          <el-option label="普通用户" value="USER" />
          <el-option label="管理员" value="ADMIN" />
        </el-select>
      </el-form-item>
    </el-form>
    <template #footer>
      <el-button @click="showAddModal = false">取消</el-button>
      <el-button type="primary" @click="handleAddUser">确定</el-button>
    </template>
  </el-dialog>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted, computed } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Search, Refresh, User, Plus } from '@element-plus/icons-vue'
import api from '@/api/index.js'

// 查询表单
const queryForm = reactive({
  account: '',
  status: null as number | null
})

// 用户列表
const userList = ref<any[]>([])
const loading = ref(false)

// 新增用户弹窗
const showAddModal = ref(false)
const addFormRef = ref()
const addForm = reactive({
  account: '',
  nickname: '',
  password: '',
  role: 'USER'
})

// 当前登录用户信息
const currentUser = computed(() => {
  const userStr = localStorage.getItem('user')
  if (userStr) {
    try {
      return JSON.parse(userStr)
    } catch (e) {
      return null
    }
  }
  return null
})

// 判断是否是当前登录用户
const isCurrentUser = (userId: number) => {
  return currentUser.value && currentUser.value.id === userId
}

// 分页信息
const pagination = reactive({
  pageNum: 1,
  pageSize: 10,
  total: 0
})

// 格式化日期时间
const formatDateTime = (datetime: string) => {
  if (!datetime) return '-'
  const date = new Date(datetime)
  return date.toLocaleString('zh-CN', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit'
  })
}

// 加载用户列表
const loadUsers = async () => {
  loading.value = true
  try {
    const response = await api.get('/admin/users', {
      params: {
        pageNum: pagination.pageNum,
        pageSize: pagination.pageSize,
        account: queryForm.account,
        status: queryForm.status
      }
    })

    if (response && response.data) {
      userList.value = response.data.list || []
      pagination.total = response.data.total || 0
    }
  } catch (error: any) {
    console.error('加载用户列表失败:', error)
    if (error.response?.status === 403) {
      ElMessage.error('没有权限访问此功能')
    } else if (error.response?.status === 401) {
      ElMessage.error('登录已过期')
    } else {
      ElMessage.error(error.response?.data?.message || '加载用户列表失败')
    }
  } finally {
    loading.value = false
  }
}

// 搜索
const handleSearch = () => {
  pagination.pageNum = 1
  loadUsers()
}

// 重置
const handleReset = () => {
  queryForm.account = ''
  queryForm.status = null
  pagination.pageNum = 1
  loadUsers()
}

// 禁用用户
const handleDisable = (row: any) => {
  ElMessageBox.confirm(
    `确定要禁用用户 "${row.nickname}" 吗？`,
    '提示',
    {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning'
    }
  ).then(async () => {
    try {
      const response = await api.put(`/admin/users/${row.id}/status`, {}, {
        params: {
          status: 0 // 0为禁用
        }
      })
      console.log('禁用用户响应:', response)
      ElMessage.success('用户已禁用')
      loadUsers()
    } catch (error: any) {
      console.error('禁用用户失败:', error)
      ElMessage.error(error.response?.data?.message || '禁用用户失败')
    }
  }).catch(() => {})
}

// 启用用户
const handleEnable = (row: any) => {
  ElMessageBox.confirm(
    `确定要启用用户 "${row.nickname}" 吗？`,
    '提示',
    {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'success'
    }
  ).then(async () => {
    try {
      const response = await api.put(`/admin/users/${row.id}/status`, {}, {
        params: {
          status: 1 // 1为正常
        }
      })
      console.log('启用用户响应:', response)
      ElMessage.success('用户已启用')
      loadUsers()
    } catch (error: any) {
      console.error('启用用户失败:', error)
      ElMessage.error(error.response?.data?.message || '启用用户失败')
    }
  }).catch(() => {})
}

// 新增用户
const handleAddUser = async () => {
  // 表单验证
  if (!addForm.account) {
    ElMessage.error('请输入账号')
    return
  }
  if (!addForm.nickname) {
    ElMessage.error('请输入昵称')
    return
  }
  if (!addForm.password) {
    ElMessage.error('请输入密码')
    return
  }

  try {
    const response = await api.post('/admin/users', {
      account: addForm.account,
      nickname: addForm.nickname,
      password: addForm.password,
      role: addForm.role
    })
    console.log('新增用户响应:', response)
    ElMessage.success('用户新增成功')
    showAddModal.value = false
    // 重置表单
    addForm.account = ''
    addForm.nickname = ''
    addForm.password = ''
    addForm.role = 'USER'
    loadUsers()
  } catch (error: any) {
    console.error('新增用户失败:', error)
    ElMessage.error(error.response?.data?.message || '新增用户失败')
  }
}

// 分页大小改变
const handleSizeChange = (val: number) => {
  pagination.pageSize = val
  loadUsers()
}

// 页码改变
const handlePageChange = (val: number) => {
  pagination.pageNum = val
  loadUsers()
}

// 初始化
onMounted(() => {
  loadUsers()
})
</script>

<style scoped>
.user-management {
  padding: 20px;
}

.page-header {
  margin-bottom: 20px;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.header-left {
  flex: 1;
}

.header-right {
  flex-shrink: 0;
}

.page-header h2 {
  font-size: 24px;
  color: #303133;
  margin-bottom: 8px;
}

.page-header p {
  font-size: 14px;
  color: #909399;
}

.filter-card {
  margin-bottom: 20px;
}

.filter-form {
  display: flex;
  flex-wrap: wrap;
}

.table-card {
  min-height: 500px;
}
</style>
