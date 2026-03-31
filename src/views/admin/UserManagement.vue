<template>
  <div class="user-management">
    <div class="page-header">
      <h2>用户管理</h2>
      <p>管理系统用户，包括启用/禁用账号</p>
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
        <el-table-column prop="id" label="ID" width="80" align="center" />
        <el-table-column prop="account" label="账号" min-width="150" />
        <el-table-column prop="nickname" label="昵称" min-width="120" />
        <el-table-column prop="email" label="邮箱" min-width="180" />
        <el-table-column prop="phone" label="手机号" min-width="130" />
        <el-table-column label="头像" width="80" align="center">
          <template #default="{ row }">
            <el-avatar :size="40" :src="row.avatar">
              <el-icon><User /></el-icon>
            </el-avatar>
          </template>
        </el-table-column>
        <el-table-column label="状态" width="100" align="center">
          <template #default="{ row }">
            <el-tag :type="row.status ? 'success' : 'danger'">
              {{ row.status ? '正常' : '禁用' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="注册时间" width="180" align="center">
          <template #default="{ row }">
            {{ formatDateTime(row.createdAt) }}
          </template>
        </el-table-column>
        <el-table-column label="最后登录" width="180" align="center">
          <template #default="{ row }">
            {{ formatDateTime(row.lastLoginAt) }}
          </template>
        </el-table-column>
        <el-table-column label="操作" width="150" align="center" fixed="right">
          <template #default="{ row }">
            <el-button
              v-if="row.status"
              type="danger"
              size="small"
              @click="handleDisable(row)"
            >
              禁用
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
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Search, Refresh, User } from '@element-plus/icons-vue'
import api from '@/api/index.js'

// 查询表单
const queryForm = reactive({
  account: '',
  status: null as number | null
})

// 用户列表
const userList = ref<any[]>([])
const loading = ref(false)

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
