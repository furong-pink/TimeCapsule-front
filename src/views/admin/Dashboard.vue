<template>
  <div class="dashboard-container">
    <!-- 页面头部 -->
    <div class="dashboard-header">
      <h2>数据概览</h2>
      <el-button type="primary" :icon="Download" @click="handleExport">导出数据</el-button>
    </div>

    <!-- 顶部4个数据卡片 -->
    <el-row :gutter="16" class="stats-row">
      <el-col :span="6" v-for="(item, index) in statCards" :key="index">
        <div class="stat-card">
          <div class="card-header-row">
            <span class="card-title">{{ item.title }}</span>
            <span 
              v-if="item.change !== null" 
              :class="['card-change', item.change >= 0 ? 'up' : 'down']"
            >
              {{ item.change >= 0 ? '+' : '' }}{{ item.change }}%
            </span>
          </div>
          <div class="card-body">
            <div class="card-left">
              <div class="card-value">{{ item.value }}</div>
              <div class="card-subtitle">{{ item.subtitle }}</div>
            </div>
            <div class="card-right">
              <div class="mini-chart">
                <div
                  v-for="(h, i) in item.miniChart"
                  :key="i"
                  class="mini-bar"
                  :style="{ height: h + '%' }"
                ></div>
              </div>
            </div>
          </div>
        </div>
      </el-col>
    </el-row>

    <!-- 用户增长趋势图 -->
    <el-row class="chart-row">
      <el-col :span="24">
        <div class="section-card">
          <div class="section-header">
            <h3>用户增长趋势</h3>
            <div class="time-tabs">
              <button
                v-for="tab in timeTabs"
                :key="tab.value"
                :class="['tab-btn', activeTimeTab === tab.value ? 'active' : '']"
                @click="switchTimeTab(tab.value)"
              >
                {{ tab.label }}
              </button>
            </div>
          </div>
          <div ref="growthChartRef" class="growth-chart"></div>
        </div>
      </el-col>
    </el-row>

    <!-- 底部双模块 -->
    <el-row :gutter="16" class="bottom-row">
      <!-- 目标状态分布 -->
      <el-col :span="12">
        <div class="section-card">
          <div class="section-header">
            <h3>目标状态分布</h3>
          </div>
          <div class="status-content">
            <div ref="goalChartRef" class="status-chart"></div>
            <div class="status-legend">
              <div
                v-for="(item, index) in goalStatusData"
                :key="index"
                class="legend-item"
              >
                <span class="legend-dot" :style="{ backgroundColor: item.color }"></span>
                <span class="legend-name">{{ item.name }}</span>
                <span class="legend-percent">{{ item.percent }}%</span>
              </div>
            </div>
          </div>
        </div>
      </el-col>

      <!-- 胶囊状态分布 -->
      <el-col :span="12">
        <div class="section-card">
          <div class="section-header">
            <h3>胶囊状态分布</h3>
          </div>
          <div class="status-content">
            <div ref="statusChartRef" class="status-chart"></div>
            <div class="status-legend">
              <div
                v-for="(item, index) in capsuleStatusData"
                :key="index"
                class="legend-item"
              >
                <span class="legend-dot" :style="{ backgroundColor: item.color }"></span>
                <span class="legend-name">{{ item.name }}</span>
                <span class="legend-percent">{{ item.percent }}%</span>
              </div>
            </div>
          </div>
        </div>
      </el-col>
    </el-row>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted, computed } from 'vue'
import { Download } from '@element-plus/icons-vue'
import * as echarts from 'echarts'
import dayjs from 'dayjs'

// 图表实例
let growthChart = null
let statusChart = null
let goalChart = null
const growthChartRef = ref(null)
const statusChartRef = ref(null)
const goalChartRef = ref(null)

// 时间筛选
const activeTimeTab = ref('day')
const timeTabs = [
  { label: '按日', value: 'day' },
  { label: '按周', value: 'week' },
  { label: '按月', value: 'month' }
]

// 顶部统计数据
const statsData = ref({
  dau: 0,
  dauYesterday: 0,
  dauChange: 0,
  mau: 0,
  mauLastMonth: 0,
  mauChange: 0,
  totalUsers: 0,
  newUsers7d: 0,
  newUsersChange: 0,
  totalCapsules: 0,
  capsulesGrowth: 0,
  storageRatio: 72,
  storageChange: 0,
  dailyTrend: []
})

// 目标状态数据
const goalStatusData = ref([
  { name: '进行中', value: 0, color: '#409EFF', percent: 0 },
  { name: '已完成', value: 0, color: '#67C23A', percent: 0 },
  { name: '已取消', value: 0, color: '#E6A23C', percent: 0 }
])

// 胶囊状态数据
const capsuleStatusData = ref([
  { name: '已开启', value: 0, color: '#409EFF', percent: 0 },
  { name: '待开启', value: 0, color: '#67C23A', percent: 0 },
  { name: '已拒绝', value: 0, color: '#E6A23C', percent: 0 }
])

// 用户增长趋势数据
const growthData = ref({
  dates: [],
  newUsers: [],
  activeUsers: []
})

// 顶部4个统计卡片
const statCards = computed(() => [
  {
    title: '日活跃用户 (DAU)',
    value: formatNumber(statsData.value.dau),
    subtitle: `昨日: ${formatNumber(statsData.value.dauYesterday)}`,
    change: statsData.value.dauChange,
    miniChart: generateMiniChart(statsData.value.dailyTrend)
  },
  {
    title: '月活跃用户 (MAU)',
    value: formatNumber(statsData.value.mau),
    subtitle: `上月: ${formatNumber(statsData.value.mauLastMonth)}`,
    change: statsData.value.mauChange,
    miniChart: generateMiniChart(statsData.value.dailyTrend)
  },
  {
    title: '累积注册用户',
    value: formatNumber(statsData.value.totalUsers),
    subtitle: `近7日新增 +${formatNumber(statsData.value.newUsers7d)}`,
    change: statsData.value.newUsersChange,
    miniChart: generateMiniChart(statsData.value.dailyTrend)
  },
  {
    title: '总胶囊存储量',
    value: formatNumber(statsData.value.totalCapsules),
    subtitle: `较昨日新增: +${statsData.value.capsulesGrowth || 0}`,
    change: statsData.value.storageChange,
    miniChart: generateMiniChart(statsData.value.dailyTrend)
  }
])

// 格式化数字
function formatNumber(num) {
  if (num >= 1000000) {
    return (num / 1000000).toFixed(1) + 'M'
  } else if (num >= 1000) {
    return num.toLocaleString()
  }
  return num.toString()
}

// 生成迷你图表数据
function generateMiniChart(data) {
  if (!data || data.length === 0) {
    return [40, 55, 45, 70, 60, 75, 85, 65, 80, 90]
  }
  
  const max = Math.max(...data)
  const min = Math.min(...data)
  const range = max - min || 1
  
  return data.slice(-10).map(v => ((v - min) / range) * 60 + 30)
}

// 初始化
onMounted(() => {
  initGrowthChart()
  initStatusChart()
  initGoalChart()
  fetchAllData()
  window.addEventListener('resize', handleResize)
})

onUnmounted(() => {
  window.removeEventListener('resize', handleResize)
  growthChart?.dispose()
  statusChart?.dispose()
  goalChart?.dispose()
})

// 切换时间标签
const switchTimeTab = (tab) => {
  activeTimeTab.value = tab
  fetchGrowthData()
}

// 获取所有数据
const fetchAllData = async () => {
  await Promise.all([
    fetchStatsData(),
    fetchGoalStats(),
    fetchCapsuleStatus(),
    fetchGrowthData()
  ])
}

// 获取统计数据
const fetchStatsData = async () => {
  try {
    const res = await window.$axios.get('/admin/dashboard/stats')
    console.log('Dashboard stats response:', res)
    if (res.code === 200) {
      const data = res.data
      console.log('Dashboard stats data:', data)
      
      // 计算同比变化
      const today = dayjs()
      const yesterday = dayjs().subtract(1, 'day')
      const lastMonth = dayjs().subtract(1, 'month')
      
      // 获取昨日DAU
      const yesterdayDau = await fetchDauByDate(yesterday.format('YYYY-MM-DD'))
      // 获取上月MAU
      const lastMonthMau = await fetchMauByMonth(lastMonth.format('YYYY-MM'))
      
      // 获取近7天趋势
      const dailyTrend = await fetchDailyTrend()
      
      // 计算变化率
      const dauChange = yesterdayDau > 0 ? ((data.dau - yesterdayDau) / yesterdayDau * 100).toFixed(1) : 0
      const mauChange = lastMonthMau > 0 ? ((data.mau - lastMonthMau) / lastMonthMau * 100).toFixed(1) : 0
      
      // 获取近7天新增用户
      const growthRes = await window.$axios.get('/admin/dashboard/user-growth', {
        params: { 
          startDate: dayjs().subtract(7, 'day').format('YYYY-MM-DD'),
          endDate: dayjs().format('YYYY-MM-DD')
        }
      })
      const newUsers7d = growthRes.data?.newUsers?.reduce((sum, val) => sum + val, 0) || 0
      
      statsData.value = {
        dau: data.dau || 0,
        dauYesterday: yesterdayDau || 0,
        dauChange: parseFloat(dauChange),
        mau: data.mau || 0,
        mauLastMonth: lastMonthMau || 0,
        mauChange: parseFloat(mauChange),
        totalUsers: data.totalUsers || 0,
        newUsers7d,
        newUsersChange: 2.1, // 暂时使用模拟数据
        totalCapsules: data.totalCapsules || 0,
        capsulesGrowth: data.capsulesGrowth || 0,
        storageRatio: 72,
        storageChange: data.capsuleGrowthRate ? parseFloat(data.capsuleGrowthRate.toFixed(1)) : 0,
        dailyTrend
      }
    }
  } catch (error) {
    console.error('Fetch stats failed', error)
  }
}

// 获取指定日期的DAU
const fetchDauByDate = async (date) => {
  try {
    const res = await window.$axios.get('/admin/dashboard/user-growth', {
      params: { startDate: date, endDate: date }
    })
    return res.data?.newUsers?.[0] || 0
  } catch (error) {
    console.error('Fetch dau failed', error)
    return 0
  }
}

// 获取指定月份的MAU
const fetchMauByMonth = async (month) => {
  try {
    const startDate = dayjs(month + '-01').format('YYYY-MM-DD')
    const endDate = dayjs(month + '-01').endOf('month').format('YYYY-MM-DD')
    const res = await window.$axios.get('/admin/dashboard/user-growth', {
      params: { startDate, endDate }
    })
    // 计算去重后的月活用户（简化处理）
    return res.data?.activeUsers?.reduce((sum, val) => sum + val, 0) || 0
  } catch (error) {
    console.error('Fetch mau failed', error)
    return 0
  }
}

// 获取近7天趋势数据
const fetchDailyTrend = async () => {
  try {
    const res = await window.$axios.get('/admin/dashboard/user-growth', {
      params: { 
        startDate: dayjs().subtract(14, 'day').format('YYYY-MM-DD'),
        endDate: dayjs().format('YYYY-MM-DD')
      }
    })
    return res.data?.activeUsers || []
  } catch (error) {
    console.error('Fetch daily trend failed', error)
    return []
  }
}

// 获取目标状态统计
const fetchGoalStats = async () => {
  try {
    console.log('Fetching goal status from API...')
    const res = await window.$axios.get('/admin/dashboard/goal-status')
    console.log('Goal status API response:', JSON.stringify(res, null, 2))
    
    // 处理不同的响应格式
    let data = null
    if (res && res.data) {
      // 标准响应格式 { code, data }
      if (res.code === 200 || res.code === '200' || !res.code) {
        data = res.data
      } else if (res.data.inProgress !== undefined) {
        data = res.data
      }
    } else if (res && res.inProgress !== undefined) {
      // 直接返回数据
      data = res
    }
    
    if (data) {
      console.log('Updating goal status with data:', data)
      updateGoalStatusData(data)
    } else {
      console.error('Invalid response format:', res)
      throw new Error('Invalid response format')
    }
  } catch (error) {
    console.error('Fetch goal status failed:', error)
    // 使用模拟数据作为后备
    updateGoalStatusData({
      inProgress: 375,
      completed: 875,
      canceled: 150
    })
  }
}

// 更新目标状态数据
const updateGoalStatusData = (data) => {
  console.log('Updating goal status data:', data)
  
  const colors = ['#409EFF', '#67C23A', '#E6A23C']
  
  // 确保数据存在且为数字
  const inProgress = typeof data.inProgress === 'number' ? data.inProgress : 0
  const completed = typeof data.completed === 'number' ? data.completed : 0
  const canceled = typeof data.canceled === 'number' ? data.canceled : 0
  
  // 计算总计
  const total = inProgress + completed + canceled
  console.log('Total goals:', total)
  
  // 计算百分比
  const calcPercent = (value) => {
    if (total === 0) return '0'
    return Math.round((value / total) * 100).toString()
  }
  
  // 更新响应式数据
  goalStatusData.value = [
    { 
      name: '进行中', 
      value: inProgress, 
      color: colors[0], 
      percent: calcPercent(inProgress)
    },
    { 
      name: '已完成', 
      value: completed, 
      color: colors[1], 
      percent: calcPercent(completed)
    },
    { 
      name: '已取消', 
      value: canceled, 
      color: colors[2], 
      percent: calcPercent(canceled)
    }
  ]
  
  console.log('Updated goalStatusData:', goalStatusData.value)
  
  // 延迟更新图表，确保DOM已更新
  setTimeout(() => {
    updateGoalChart()
  }, 50)
}

// 获取胶囊状态
const fetchCapsuleStatus = async () => {
  try {
    const res = await window.$axios.get('/admin/dashboard/capsule-status')
    console.log('Capsule status response:', res)
    if (res.code === 200) {
      console.log('Capsule status data:', res.data)
      updateCapsuleStatusData(res.data)
    }
  } catch (error) {
    console.error('Fetch capsule status failed', error)
  }
}

// 更新胶囊状态数据
const updateCapsuleStatusData = (data) => {
  const colors = ['#409EFF', '#67C23A', '#E6A23C']
  const total = (data.opened || 0) + (data.pending || 0) + (data.rejected || 0)
  
  capsuleStatusData.value = [
    { 
      name: '已开启', 
      value: data.opened || 0, 
      color: colors[0], 
      percent: total > 0 ? ((data.opened || 0) / total * 100).toFixed(0) : '0'
    },
    { 
      name: '待开启', 
      value: data.pending || 0, 
      color: colors[1], 
      percent: total > 0 ? ((data.pending || 0) / total * 100).toFixed(0) : '0'
    },
    { 
      name: '已拒绝', 
      value: data.rejected || 0, 
      color: colors[2], 
      percent: total > 0 ? ((data.rejected || 0) / total * 100).toFixed(0) : '0'
    }
  ]
  
  updateStatusChart()
}

// 获取用户增长数据
const fetchGrowthData = async () => {
  let startDate, endDate = dayjs().format('YYYY-MM-DD')
  
  if (activeTimeTab.value === 'day') {
    startDate = dayjs().subtract(7, 'day').format('YYYY-MM-DD')
  } else if (activeTimeTab.value === 'week') {
    startDate = dayjs().subtract(4, 'week').startOf('week').format('YYYY-MM-DD')
  } else if (activeTimeTab.value === 'month') {
    startDate = dayjs().subtract(6, 'month').startOf('month').format('YYYY-MM-DD')
  }

  try {
    const res = await window.$axios.get('/admin/dashboard/user-growth', {
      params: { startDate, endDate }
    })
    if (res.code === 200) {
      growthData.value = {
        dates: res.data.dates || [],
        newUsers: res.data.newUsers || [],
        activeUsers: res.data.activeUsers || []
      }
      updateGrowthChart()
    }
  } catch (error) {
    console.error('Fetch growth data failed', error)
    // 使用模拟数据
    generateMockGrowthData()
  }
}

// 生成模拟增长数据
const generateMockGrowthData = () => {
  const dates = []
  const newUsers = []
  const activeUsers = []
  const days = activeTimeTab.value === 'day' ? 7 : activeTimeTab.value === 'week' ? 4 : 6
  
  for (let i = days - 1; i >= 0; i--) {
    const date = dayjs().subtract(i, activeTimeTab.value === 'day' ? 'day' : activeTimeTab.value === 'week' ? 'week' : 'month')
    dates.push(date.format(activeTimeTab.value === 'month' ? 'YYYY-MM' : 'MM-DD'))
    const baseValue = Math.floor(Math.random() * 3000) + 2000
    newUsers.push(baseValue)
    activeUsers.push(baseValue * 3 + Math.floor(Math.random() * 2000))
  }
  
  growthData.value = { dates, newUsers, activeUsers }
  updateGrowthChart()
}

// 初始化增长趋势图
const initGrowthChart = () => {
  if (!growthChartRef.value) return
  
  growthChart = echarts.init(growthChartRef.value)
  
  const option = {
    tooltip: {
      trigger: 'axis',
      backgroundColor: 'rgba(255, 255, 255, 0.95)',
      borderColor: '#e4e7ed',
      borderWidth: 1,
      textStyle: { color: '#303133', fontSize: 13 },
      formatter: (params) => {
        let result = `<div style="font-weight:500;margin-bottom:8px">${params[0].name}</div>`
        params.forEach(item => {
          result += `<div style="color:#606266;margin-bottom:4px">${item.seriesName}: <span style="color:${item.color};font-weight:600">${item.value.toLocaleString()}</span></div>`
        })
        return result
      }
    },
    legend: {
      data: ['新增用户', '活跃用户'],
      top: 0,
      right: 0,
      textStyle: { color: '#606266', fontSize: 12 }
    },
    grid: {
      left: '3%',
      right: '4%',
      bottom: '3%',
      top: '15%',
      containLabel: true
    },
    xAxis: {
      type: 'category',
      boundaryGap: false,
      data: [],
      axisLine: { lineStyle: { color: '#e4e7ed' } },
      axisLabel: { color: '#909399', fontSize: 12 },
      axisTick: { show: false }
    },
    yAxis: {
      type: 'value',
      axisLine: { show: false },
      axisTick: { show: false },
      splitLine: { lineStyle: { color: '#f0f0f0' } },
      axisLabel: { color: '#909399', fontSize: 12 }
    },
    series: [
      {
        name: '新增用户',
        type: 'line',
        smooth: true,
        symbol: 'circle',
        symbolSize: 6,
        lineStyle: {
          width: 3,
          color: '#409EFF'
        },
        areaStyle: {
          color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
            { offset: 0, color: 'rgba(64, 158, 255, 0.3)' },
            { offset: 1, color: 'rgba(64, 158, 255, 0.05)' }
          ])
        },
        data: []
      },
      {
        name: '活跃用户',
        type: 'line',
        smooth: true,
        symbol: 'circle',
        symbolSize: 6,
        lineStyle: {
          width: 3,
          color: '#67C23A'
        },
        areaStyle: {
          color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
            { offset: 0, color: 'rgba(103, 194, 58, 0.2)' },
            { offset: 1, color: 'rgba(103, 194, 58, 0.05)' }
          ])
        },
        data: []
      }
    ]
  }
  
  growthChart.setOption(option)
}

// 初始化状态分布图
const initStatusChart = () => {
  if (!statusChartRef.value) return
  
  statusChart = echarts.init(statusChartRef.value)
  
  const option = {
    tooltip: {
      trigger: 'item',
      backgroundColor: 'rgba(255, 255, 255, 0.95)',
      borderColor: '#e4e7ed',
      borderWidth: 1,
      textStyle: { color: '#303133' },
      formatter: '{b}: {c} ({d}%)'
    },
    series: [{
      type: 'pie',
      radius: ['55%', '75%'],
      center: ['40%', '50%'],
      avoidLabelOverlap: false,
      itemStyle: {
        borderRadius: 6,
        borderColor: '#fff',
        borderWidth: 3
      },
      label: {
        show: true,
        position: 'center',
        formatter: () => {
          const total = capsuleStatusData.value.reduce((sum, item) => sum + item.value, 0)
          return `{total|${formatNumber(total)}}\n{name|总计}`
        },
        rich: {
          total: {
            fontSize: 24,
            fontWeight: 'bold',
            color: '#303133',
            lineHeight: 32
          },
          name: {
            fontSize: 12,
            color: '#909399'
          }
        }
      },
      emphasis: {
        label: { show: true }
      },
      labelLine: { show: false },
      data: []
    }]
  }
  
  statusChart.setOption(option)
}

// 更新增长趋势图
const updateGrowthChart = () => {
  if (!growthChart) return
  
  growthChart.setOption({
    xAxis: { data: growthData.value.dates },
    series: [
      { data: growthData.value.newUsers },
      { data: growthData.value.activeUsers }
    ]
  })
}

// 更新状态分布图
const updateStatusChart = () => {
  if (!statusChart) return
  
  const data = capsuleStatusData.value.map(item => ({
    value: item.value,
    name: item.name,
    itemStyle: { color: item.color }
  }))
  
  statusChart.setOption({
    series: [{ data }]
  })
}

// 初始化目标状态分布图
const initGoalChart = () => {
  if (!goalChartRef.value) return
  
  goalChart = echarts.init(goalChartRef.value)
  
  const option = {
    tooltip: {
      trigger: 'item',
      backgroundColor: 'rgba(255, 255, 255, 0.95)',
      borderColor: '#e4e7ed',
      borderWidth: 1,
      textStyle: { color: '#303133' },
      formatter: '{b}: {c} ({d}%)'
    },
    series: [{
      type: 'pie',
      radius: ['55%', '75%'],
      center: ['40%', '50%'],
      avoidLabelOverlap: false,
      itemStyle: {
        borderRadius: 6,
        borderColor: '#fff',
        borderWidth: 3
      },
      label: {
        show: true,
        position: 'center',
        formatter: () => {
          const total = goalStatusData.value.reduce((sum, item) => sum + item.value, 0)
          return `{total|${formatNumber(total)}}\n{name|总计}`
        },
        rich: {
          total: {
            fontSize: 24,
            fontWeight: 'bold',
            color: '#303133',
            lineHeight: 32
          },
          name: {
            fontSize: 12,
            color: '#909399'
          }
        }
      },
      emphasis: {
        label: { show: true }
      },
      labelLine: { show: false },
      data: []
    }]
  }
  
  goalChart.setOption(option)
}

// 更新目标状态分布图
const updateGoalChart = () => {
  console.log('Updating goal chart...')
  
  if (!goalChart) {
    console.warn('Goal chart not initialized')
    // 尝试重新初始化
    if (goalChartRef.value) {
      initGoalChart()
    }
    return
  }
  
  const data = goalStatusData.value.map(item => ({
    value: item.value,
    name: item.name,
    itemStyle: { color: item.color }
  }))
  
  console.log('Chart data:', data)
  
  goalChart.setOption({
    series: [{ data }]
  })
  
  // 强制刷新
  goalChart.resize()
}

// 窗口大小改变
const handleResize = () => {
  growthChart?.resize()
  statusChart?.resize()
  goalChart?.resize()
}

// 导出数据
const handleExport = () => {
  const headers = ['日期', '新增用户', '活跃用户']
  const rows = growthData.value.dates.map((d, i) => [d, growthData.value.newUsers[i], growthData.value.activeUsers[i]])
  const csvContent = 'data:text/csv;charset=utf-8,' 
    + headers.join(',') + '\n'
    + rows.map(e => e.join(',')).join('\n')
  
  const encodedUri = encodeURI(csvContent)
  const link = document.createElement('a')
  link.setAttribute('href', encodedUri)
  link.setAttribute('download', `growth_report_${dayjs().format('YYYYMMDD')}.csv`)
  document.body.appendChild(link)
  link.click()
  document.body.removeChild(link)
}
</script>

<style scoped>
.dashboard-container {
  padding: 24px;
  background-color: #f5f7fa;
  min-height: calc(100vh - 60px);
}

/* 页面头部 */
.dashboard-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 24px;
}

.dashboard-header h2 {
  margin: 0;
  font-size: 20px;
  font-weight: 600;
  color: #1f2329;
}

/* 统计卡片行 */
.stats-row {
  margin-bottom: 16px;
}

/* 统计卡片 */
.stat-card {
  background: #fff;
  border-radius: 12px;
  padding: 20px;
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.06);
  transition: all 0.3s ease;
}

.stat-card:hover {
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.08);
}

.card-header-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;
}

.card-title {
  font-size: 13px;
  color: #606266;
  font-weight: 500;
}

.card-change {
  font-size: 12px;
  font-weight: 600;
  padding: 2px 8px;
  border-radius: 4px;
}

.card-change.up {
  color: #67c23a;
  background: rgba(103, 194, 58, 0.1);
}

.card-change.down {
  color: #f56c6c;
  background: rgba(245, 108, 108, 0.1);
}

.card-body {
  display: flex;
  justify-content: space-between;
  align-items: flex-end;
}

.card-left {
  flex: 1;
}

.card-value {
  font-size: 28px;
  font-weight: 700;
  color: #1f2329;
  line-height: 1.2;
  margin-bottom: 4px;
}

.card-subtitle {
  font-size: 12px;
  color: #909399;
}

.card-right {
  display: flex;
  align-items: flex-end;
}

.mini-chart {
  display: flex;
  align-items: flex-end;
  gap: 3px;
  height: 40px;
}

.mini-bar {
  width: 6px;
  background: linear-gradient(180deg, #a0cfff 0%, #409eff 100%);
  border-radius: 2px;
  transition: all 0.3s ease;
}

/* 区块卡片 */
.section-card {
  background: #fff;
  border-radius: 12px;
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.06);
  overflow: hidden;
}

.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 16px 20px;
  border-bottom: 1px solid #f0f0f0;
}

.section-header h3 {
  margin: 0;
  font-size: 16px;
  font-weight: 600;
  color: #1f2329;
}

/* 时间切换标签 */
.time-tabs {
  display: flex;
  gap: 4px;
  background: #f5f7fa;
  padding: 4px;
  border-radius: 6px;
}

.tab-btn {
  padding: 6px 16px;
  font-size: 13px;
  color: #606266;
  background: transparent;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  transition: all 0.3s ease;
}

.tab-btn:hover {
  color: #409eff;
}

.tab-btn.active {
  background: #fff;
  color: #409eff;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
}

/* 图表区域 */
.chart-row {
  margin-bottom: 16px;
}

.growth-chart {
  width: 100%;
  height: 320px;
  padding: 20px;
  box-sizing: border-box;
}

/* 底部区域 */
.bottom-row {
  margin-bottom: 0;
}

/* 目标达成分析 */
.goal-content {
  padding: 20px;
}

.progress-section {
  margin-bottom: 24px;
}

.progress-item {
  margin-bottom: 20px;
}

.progress-item:last-child {
  margin-bottom: 0;
}

.progress-label {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 8px;
  font-size: 13px;
  color: #606266;
}

.progress-percent {
  font-weight: 600;
  color: #1f2329;
}

:deep(.el-progress-bar__outer) {
  background-color: #f0f2f5;
  border-radius: 4px;
}

:deep(.el-progress-bar__inner) {
  border-radius: 4px;
}

/* 关键指标 */
.key-metrics {
  display: flex;
  justify-content: space-around;
  padding-top: 20px;
  border-top: 1px solid #f0f0f0;
}

.metric-item {
  text-align: center;
}

.metric-label {
  font-size: 12px;
  color: #909399;
  margin-bottom: 8px;
}

.metric-value {
  font-size: 20px;
  font-weight: 700;
  color: #1f2329;
}

/* 胶囊状态分布 */
.status-content {
  display: flex;
  align-items: center;
  padding: 20px;
  min-height: 280px;
}

.status-chart {
  flex: 1;
  height: 240px;
}

.status-legend {
  width: 120px;
  padding-left: 20px;
}

.legend-item {
  display: flex;
  align-items: center;
  margin-bottom: 16px;
}

.legend-item:last-child {
  margin-bottom: 0;
}

.legend-dot {
  width: 10px;
  height: 10px;
  border-radius: 50%;
  margin-right: 10px;
}

.legend-name {
  flex: 1;
  font-size: 13px;
  color: #606266;
}

.legend-percent {
  font-size: 14px;
  font-weight: 600;
  color: #1f2329;
}
</style>
