<template>
  <div class="capsule-mgmt-container">
    <el-card shadow="never" class="filter-card">
      <el-form :inline="true" :model="queryForm" class="demo-form-inline">
        <el-form-item label="标题">
          <el-input v-model="queryForm.title" placeholder="关键词搜索" clearable />
        </el-form-item>
        <el-form-item label="发布人">
          <el-input v-model="queryForm.nickname" placeholder="昵称模糊搜索" clearable />
        </el-form-item>
        <el-form-item label="状态">
          <el-select v-model="queryForm.status" placeholder="全部状态" clearable style="width: 120px">
            <el-option label="待审核" value="PENDING" />
            <el-option label="已发布" value="PUBLISHED" />
            <el-option label="已开启" value="OPENED" />
            <el-option label="已拒绝" value="REJECTED" />
            <el-option label="已删除" value="DELETED" />
          </el-select>
        </el-form-item>
        <el-form-item label="发布时间">
          <el-date-picker
            v-model="createDateRange"
            type="daterange"
            range-separator="至"
            start-placeholder="开始日期"
            end-placeholder="结束日期"
            value-format="YYYY-MM-DD"
            style="width: 240px"
          />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="handleSearch">查询</el-button>
          <el-button @click="resetQuery">重置</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <el-card shadow="never" class="table-card">
      <template #header>
        <div class="table-header">
          <span class="title">胶囊列表</span>
          <div class="actions">
            <el-button 
              type="danger" 
              :disabled="selectedIds.length === 0"
              @click="handleBatchDelete"
            >
              批量删除 ({{ selectedIds.length }})
            </el-button>
          </div>
        </div>
      </template>

      <el-table 
        v-loading="loading"
        :data="tableData" 
        style="width: 100%"
        @selection-change="handleSelectionChange"
      >
        <el-table-column type="selection" width="55" />
        <el-table-column prop="title" label="胶囊标题" min-width="150" show-overflow-tooltip />
        <el-table-column prop="contentSummary" label="内容摘要" min-width="200" show-overflow-tooltip />
        <el-table-column prop="nickname" label="发布人" width="120" />
        <el-table-column prop="createdAt" label="发布时间" width="160">
          <template #default="{ row }">
            {{ formatDate(row.createdAt) }}
          </template>
        </el-table-column>
        <el-table-column prop="openDate" label="计划解锁时间" width="160">
          <template #default="{ row }">
            {{ formatDate(row.openDate) }}
          </template>
        </el-table-column>
        <el-table-column prop="status" label="状态" width="100">
          <template #default="{ row }">
            <el-tag :type="getStatusTag(row.status)">{{ getStatusLabel(row.status) }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="280" fixed="right">
          <template #default="{ row }">
            <el-button link type="primary" @click="viewDetail(row)">详情</el-button>
            <el-button 
              v-if="row.status === 'PENDING'" 
              link type="success" 
              @click="handleApprove(row)"
            >通过</el-button>
            <el-button 
              v-if="row.status === 'PENDING'" 
              link type="warning" 
              @click="openRejectDialog(row)"
            >拒绝</el-button>
            <el-button 
              v-if="row.status === 'PUBLISHED'" 
              link type="danger" 
              @click="openForceOpenDialog(row)"
            >强制开启</el-button>
            <el-button 
              v-if="row.status !== 'DELETED'" 
              link type="danger" 
              @click="handleDelete(row)"
            >删除</el-button>
          </template>
        </el-table-column>
      </el-table>

      <div class="pagination-container">
        <el-pagination
          v-model:current-page="queryForm.pageNum"
          v-model:page-size="queryForm.pageSize"
          :page-sizes="[10, 20, 50, 100]"
          layout="total, sizes, prev, pager, next, jumper"
          :total="total"
          @size-change="fetchData"
          @current-change="fetchData"
        />
      </div>
    </el-card>

    <!-- 详情弹窗 -->
    <el-dialog v-model="detailVisible" title="胶囊详情" width="60%">
      <div v-if="currentCapsule" class="capsule-detail">
        <h3>{{ currentCapsule.title }}</h3>
        <div class="detail-info">
          <span>发布人: {{ currentCapsule.nickname }}</span>
          <span>发布时间: {{ formatDate(currentCapsule.createdAt) }}</span>
          <span>状态: <el-tag :type="getStatusTag(currentCapsule.status)">{{ getStatusLabel(currentCapsule.status) }}</el-tag></span>
        </div>
        <el-divider />
        <div class="content-preview" v-html="currentCapsule.content"></div>
        <div v-if="currentCapsule.coverImage" class="image-preview">
          <el-image :src="currentCapsule.coverImage" :preview-src-list="[currentCapsule.coverImage]" />
        </div>
      </div>
    </el-dialog>

    <!-- 拒绝原因弹窗 -->
    <el-dialog v-model="rejectVisible" title="审核拒绝" width="400px">
      <el-form :model="rejectForm" ref="rejectFormRef" :rules="rejectRules">
        <el-form-item label="拒绝理由" prop="reason">
          <el-input 
            v-model="rejectForm.reason" 
            type="textarea" 
            placeholder="请输入拒绝理由 (不少于10个字)" 
            :rows="4" 
          />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="rejectVisible = false">取消</el-button>
        <el-button type="primary" @click="submitReject">确定</el-button>
      </template>
    </el-dialog>

    <!-- 强制开启弹窗 -->
    <el-dialog v-model="forceOpenVisible" title="强制开启胶囊" width="400px">
      <el-alert title="强制开启将立即对所有人公开该胶囊内容，请谨慎操作。" type="warning" show-icon :closable="false" />
      <el-form :model="forceOpenForm" ref="forceOpenFormRef" :rules="forceOpenRules" style="margin-top: 20px">
        <el-form-item label="开启原因" prop="reason">
          <el-input v-model="forceOpenForm.reason" type="textarea" placeholder="请输入强制开启的原因" :rows="3" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="forceOpenVisible = false">取消</el-button>
        <el-button type="danger" @click="submitForceOpen">确认开启</el-button>
      </template>
    </el-dialog>

    <!-- 批量删除弹窗 -->
    <el-dialog v-model="batchDeleteVisible" title="批量删除胶囊" width="450px">
      <el-form :model="batchDeleteForm" ref="batchDeleteFormRef" :rules="batchDeleteRules">
        <el-form-item label="违规类型" prop="type">
          <el-select v-model="batchDeleteForm.type" placeholder="请选择违规类型" style="width: 100%">
            <el-option label="色情" value="色情" />
            <el-option label="暴力" value="暴力" />
            <el-option label="政治敏感" value="政治敏感" />
            <el-option label="广告" value="广告" />
            <el-option label="其他" value="其他" />
          </el-select>
        </el-form-item>
        <el-form-item label="详细说明" prop="reason">
          <el-input v-model="batchDeleteForm.reason" type="textarea" placeholder="请输入删除的详细原因" :rows="3" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="batchDeleteVisible = false">取消</el-button>
        <el-button type="danger" @click="submitBatchDelete">确定删除</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import dayjs from 'dayjs'

const loading = ref(false)
const tableData = ref([])
const total = ref(0)
const selectedIds = ref([])

const queryForm = reactive({
  pageNum: 1,
  pageSize: 20,
  title: '',
  nickname: '',
  status: '',
  createStart: null,
  createEnd: null
})
const createDateRange = ref([])

const detailVisible = ref(false)
const currentCapsule = ref(null)

const rejectVisible = ref(false)
const rejectForm = reactive({ id: null, reason: '' })
const rejectRules = {
  reason: [
    { required: true, message: '请输入拒绝理由', trigger: 'blur' },
    { min: 10, message: '拒绝理由不能少于10个字', trigger: 'blur' }
  ]
}

const forceOpenVisible = ref(false)
const forceOpenForm = reactive({ id: null, reason: '' })
const forceOpenRules = {
  reason: [{ required: true, message: '请输入开启原因', trigger: 'blur' }]
}

const batchDeleteVisible = ref(false)
const batchDeleteForm = reactive({ type: '', reason: '' })
const batchDeleteRules = {
  type: [{ required: true, message: '请选择违规类型', trigger: 'change' }],
  reason: [{ required: true, message: '请输入详细原因', trigger: 'blur' }]
}

onMounted(() => {
  fetchData()
})

const fetchData = async () => {
  loading.value = true
  if (createDateRange.value?.length === 2) {
    queryForm.createStart = createDateRange.value[0]
    queryForm.createEnd = createDateRange.value[1]
  } else {
    queryForm.createStart = null
    queryForm.createEnd = null
  }

  try {
    const res = await window.$axios.get('/admin/capsules', { params: queryForm })
    if (res.code === 200) {
      tableData.value = res.data.list
      total.value = res.data.total
    }
  } catch (error) {
    console.error('Fetch capsules failed', error)
  } finally {
    loading.value = false
  }
}

const handleSearch = () => {
  queryForm.pageNum = 1
  fetchData()
}

const resetQuery = () => {
  Object.assign(queryForm, {
    pageNum: 1,
    pageSize: 20,
    title: '',
    nickname: '',
    status: '',
    createStart: null,
    createEnd: null
  })
  createDateRange.value = []
  fetchData()
}

const handleSelectionChange = (selection) => {
  selectedIds.value = selection.map(item => item.id)
}

const viewDetail = async (row) => {
  try {
    const res = await window.$axios.get(`/admin/capsules/${row.id}`)
    if (res.code === 200) {
      currentCapsule.value = res.data
      detailVisible.value = true
    }
  } catch (error) {
    ElMessage.error('加载详情失败')
  }
}

const handleApprove = (row) => {
  ElMessageBox.confirm('确定审核通过该胶囊吗？', '审核确认', {
    type: 'success'
  }).then(async () => {
    const res = await window.$axios.put(`/admin/capsules/${row.id}/status`, { action: 'APPROVE' })
    if (res.code === 200) {
      ElMessage.success('审核已通过')
      fetchData()
    }
  })
}

const openRejectDialog = (row) => {
  rejectForm.id = row.id
  rejectForm.reason = ''
  rejectVisible.value = true
}

const submitReject = async () => {
  if (rejectForm.reason.length < 10) {
    return ElMessage.warning('拒绝理由不能少于10个字')
  }
  const res = await window.$axios.put(`/admin/capsules/${rejectForm.id}/status`, { 
    action: 'REJECT', 
    reason: rejectForm.reason 
  })
  if (res.code === 200) {
    ElMessage.success('已拒绝审核')
    rejectVisible.value = false
    fetchData()
  }
}

const openForceOpenDialog = (row) => {
  forceOpenForm.id = row.id
  forceOpenForm.reason = ''
  forceOpenVisible.value = true
}

const submitForceOpen = async () => {
  if (!forceOpenForm.reason) return
  const res = await window.$axios.post(`/admin/capsules/${forceOpenForm.id}/force-open`, { 
    reason: forceOpenForm.reason 
  })
  if (res.code === 200) {
    ElMessage.success('胶囊已强制开启')
    forceOpenVisible.value = false
    fetchData()
  }
}

const handleDelete = (row) => {
  ElMessageBox.confirm('确定软删除该胶囊吗？', '删除确认', {
    type: 'error'
  }).then(async () => {
    const res = await window.$axios.delete('/admin/capsules/batch', { 
      data: { ids: [row.id], type: '其他', reason: '管理员单项删除' } 
    })
    if (res.code === 200) {
      ElMessage.success('删除成功')
      fetchData()
    }
  })
}

const handleBatchDelete = () => {
  batchDeleteForm.type = ''
  batchDeleteForm.reason = ''
  batchDeleteVisible.value = true
}

const submitBatchDelete = async () => {
  if (!batchDeleteForm.type || !batchDeleteForm.reason) return
  const res = await window.$axios.delete('/admin/capsules/batch', { 
    data: { ids: selectedIds.value, ...batchDeleteForm } 
  })
  if (res.code === 200) {
    ElMessage.success('批量删除成功')
    batchDeleteVisible.value = false
    fetchData()
  }
}

const getStatusTag = (status) => {
  const map = {
    PENDING: 'warning',
    PUBLISHED: 'success',
    OPENED: '',
    REJECTED: 'danger',
    DELETED: 'info'
  }
  return map[status] || 'info'
}

const getStatusLabel = (status) => {
  const map = {
    PENDING: '待审核',
    PUBLISHED: '已发布',
    OPENED: '已开启',
    REJECTED: '已拒绝',
    DELETED: '已删除'
  }
  return map[status] || status
}

const formatDate = (date) => {
  return date ? dayjs(date).format('YYYY-MM-DD HH:mm') : '-'
}
</script>

<style scoped>
.capsule-mgmt-container {
  padding: 20px;
}
.filter-card {
  margin-bottom: 20px;
}
.table-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}
.table-header .title {
  font-weight: bold;
}
.pagination-container {
  margin-top: 20px;
  display: flex;
  justify-content: flex-end;
}
.detail-info {
  margin-bottom: 15px;
  color: #666;
  font-size: 14px;
}
.detail-info span {
  margin-right: 20px;
}
.content-preview {
  background: #f9f9f9;
  padding: 15px;
  border-radius: 4px;
  line-height: 1.6;
  max-height: 400px;
  overflow-y: auto;
}
.image-preview {
  margin-top: 20px;
  text-align: center;
}
.image-preview .el-image {
  max-width: 100%;
  max-height: 300px;
}
</style>
