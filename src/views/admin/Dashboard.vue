<template>
  <div class="dashboard-container">
    <div class="dashboard-header">
      <h2>{{ '数据看板' }}</h2>
      <el-button type="primary" :icon="Download" @click="handleExport">{{ '导出数据' }}</el-button>
    </div>

    <!-- 顶部核心指标 -->
    <el-row :gutter="20" class="stats-row">
      <el-col :xs="12" :sm="8" :md="4" v-for="(item, index) in coreStats" :key="index">
        <el-skeleton :loading="loading" animated>
          <template #template>
            <el-skeleton-item variant="rect" style="height: 100px" />
          </template>
          <template #default>
            <el-card shadow="hover" class="stat-card">
              <div class="stat-label">{{ item.label }}</div>
              <div class="stat-value">{{ item.value }}</div>
              <div class="stat-footer" v-if="item.growth !== undefined">
                <span :class="item.growth >= 0 ? 'trend-up' : 'trend-down'">
                  {{ item.growth >= 0 ? '↑' : '↓' }} {{ Math.abs(item.growth).toFixed(1) }}%
                </span>
                <span class="footer-label">{{ '同比增长' }}</span>
              </div>
            </el-card>
          </template>
        </el-skeleton>
      </el-col>
    </el-row>

    <!-- 中部：用户增长趋势 -->
    <el-row :gutter="20" class="chart-row">
      <el-col :span="24">
        <el-card shadow="hover">
          <template #header>
            <div class="card-header">
              <span>{{ '用户增长趋势' }}</span>
              <div class="header-actions">
                <el-radio-group v-model="dateRangeType" size="small" @change="handleDateRangeChange">
                  <el-radio-button label="today">{{ '今日' }}</el-radio-button>
                  <el-radio-button label="7days">{{ '近 7 天' }}</el-radio-button>
                  <el-radio-button label="30days">{{ '近 30 天' }}</el-radio-button>
                </el-radio-group>
                <el-date-picker
                  v-model="customDateRange"
                  type="daterange"
                  size="small"
                  style="margin-left: 10px; width: 240px"
                  :start-placeholder="'自定义时间'"
                  @change="handleCustomDateChange"
                />
              </div>
            </div>
          </template>
          <div ref="growthChartRef" class="chart-box"></div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 底部：胶囊数据统计 -->
    <el-row :gutter="20" class="chart-row">
      <!-- 解锁周期分布 -->
      <el-col :xs="24" :md="12">
        <el-card shadow="hover">
          <template #header>
            <div class="card-header">
              <span>{{ '胶囊分布统计' }}</span>
              <span class="avg-unlock">
                {{ '平均解锁天数' }}: 
                <strong>{{ capsuleStats.avgUnlockDays?.toFixed(1) }}</strong> {{ '天' }}
              </span>
            </div>
          </template>
          <div ref="distributionChartRef" class="chart-box"></div>
        </el-card>
      </el-col>
      <!-- 热门主题词云 -->
      <el-col :xs="24" :md="12">
        <el-card shadow="hover">
          <template #header>
            <span>{{ '热门主题' }}</span>
          </template>
          <div ref="wordCloudChartRef" class="chart-box"></div>
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted, watch, computed } from 'vue'
// import { useI18n } from 'vue-i18n'
import { Download } from '@element-plus/icons-vue'
import * as echarts from 'echarts'
import 'echarts-wordcloud'
import dayjs from 'dayjs'

// const { t, locale } = useI18n()
const loading = ref(true)

// 图表实例
let growthChart = null
let distributionChart = null
let wordCloudChart = null

const growthChartRef = ref(null)
const distributionChartRef = ref(null)
const wordCloudChartRef = ref(null)

// 数据
const statsData = ref({
  dau: 0,
  mau: 0,
  totalUsers: 0,
  totalCapsules: 0,
  capsulesToday: 0,
  capsuleGrowthRate: 0
})

const growthData = ref({
  dates: [],
  newUsers: [],
  activeUsers: []
})

const capsuleStats = ref({
  avgUnlockDays: 0,
  unlockDistribution: [],
  hotKeywords: []
})

const coreStats = computed(() => [
  { label: '日活跃用户', value: statsData.value.dau },
  { label: '月活跃用户', value: statsData.value.mau },
  { label: '总用户数', value: statsData.value.totalUsers },
  { label: '胶囊总数', value: statsData.value.totalCapsules },
  { label: '今日胶囊', value: statsData.value.capsulesToday, growth: statsData.value.capsuleGrowthRate }
])

// 筛选
const dateRangeType = ref('7days')
const customDateRange = ref([])

// 初始化
onMounted(async () => {
  await fetchData()
  initCharts()
  window.addEventListener('resize', handleResize)
})

onUnmounted(() => {
  window.removeEventListener('resize', handleResize)
  growthChart?.dispose()
  distributionChart?.dispose()
  wordCloudChart?.dispose()
})

const fetchData = async () => {
  loading.value = true
  try {
    const [statsRes, growthRes, capsuleRes] = await Promise.all([
      window.$axios.get('/admin/dashboard/stats'),
      fetchGrowthData(),
      window.$axios.get('/admin/dashboard/capsule-stats')
    ])

    if (statsRes.code === 200) statsData.value = statsRes.data
    if (capsuleRes.code === 200) capsuleStats.value = capsuleRes.data
  } catch (error) {
    console.error('Fetch dashboard data failed', error)
  } finally {
    loading.value = false
  }
}

const fetchGrowthData = async () => {
  let start, end = dayjs().format('YYYY-MM-DD')
  if (dateRangeType.value === 'today') {
    start = end
  } else if (dateRangeType.value === '7days') {
    start = dayjs().subtract(7, 'day').format('YYYY-MM-DD')
  } else if (dateRangeType.value === '30days') {
    start = dayjs().subtract(30, 'day').format('YYYY-MM-DD')
  } else if (customDateRange.value?.length === 2) {
    start = dayjs(customDateRange.value[0]).format('YYYY-MM-DD')
    end = dayjs(customDateRange.value[1]).format('YYYY-MM-DD')
  }

  const res = await window.$axios.get('/admin/dashboard/user-growth', {
    params: { startDate: start, endDate: end }
  })
  if (res.code === 200) {
    growthData.value = res.data
    updateGrowthChart()
  }
}

const initCharts = () => {
  if (growthChartRef.value) {
    growthChart = echarts.init(growthChartRef.value)
    updateGrowthChart()
  }
  if (distributionChartRef.value) {
    distributionChart = echarts.init(distributionChartRef.value)
    updateDistributionChart()
  }
  if (wordCloudChartRef.value) {
    wordCloudChart = echarts.init(wordCloudChartRef.value)
    updateWordCloudChart()
  }
}

const updateGrowthChart = () => {
  if (!growthChart) return
  growthChart.setOption({
    tooltip: { trigger: 'axis' },
    legend: { data: ['新增用户', '活跃用户'] },
    grid: { left: '3%', right: '4%', bottom: '3%', containLabel: true },
    xAxis: { type: 'category', boundaryGap: false, data: growthData.value.dates },
    yAxis: { type: 'value' },
    series: [
      {
        name: '新增用户',
        type: 'line',
        smooth: true,
        data: growthData.value.newUsers,
        areaStyle: { opacity: 0.1 },
        itemStyle: { color: '#409EFF' }
      },
      {
        name: '活跃用户',
        type: 'line',
        smooth: true,
        data: growthData.value.activeUsers,
        areaStyle: { opacity: 0.1 },
        itemStyle: { color: '#67C23A' }
      }
    ]
  })
}

const updateDistributionChart = () => {
  if (!distributionChart) return
  const data = capsuleStats.value.unlockDistribution || []
  distributionChart.setOption({
    tooltip: { trigger: 'item', formatter: '{b}: {c} ({d}%)' },
    series: [
      {
        type: 'pie',
        radius: ['40%', '70%'],
        avoidLabelOverlap: false,
        itemStyle: { borderRadius: 10, borderColor: '#fff', borderWidth: 2 },
        label: { show: true, formatter: '{b}' },
        data: data.map(item => ({ value: item.count, name: item.interval }))
      }
    ]
  })
}

const updateWordCloudChart = () => {
  if (!wordCloudChart) return
  const data = capsuleStats.value.hotKeywords || []
  wordCloudChart.setOption({
    series: [{
      type: 'wordCloud',
      shape: 'circle',
      left: 'center',
      top: 'center',
      width: '90%',
      height: '90%',
      right: null,
      bottom: null,
      sizeRange: [12, 60],
      rotationRange: [-90, 90],
      rotationStep: 45,
      gridSize: 8,
      drawOutOfBound: false,
      textStyle: {
        fontFamily: 'sans-serif',
        fontWeight: 'bold',
        color: function () {
          return 'rgb(' + [
            Math.round(Math.random() * 160),
            Math.round(Math.random() * 160),
            Math.round(Math.random() * 160)
          ].join(',') + ')';
        }
      },
      emphasis: { focus: 'self', textStyle: { shadowBlur: 10, shadowColor: '#333' } },
      data: data
    }]
  })
}

const handleResize = () => {
  growthChart?.resize()
  distributionChart?.resize()
  wordCloudChart?.resize()
}

const handleDateRangeChange = () => {
  customDateRange.value = []
  fetchGrowthData()
}

const handleCustomDateChange = () => {
  if (customDateRange.value?.length === 2) {
    dateRangeType.value = ''
    fetchGrowthData()
  }
}

const handleExport = () => {
  // 模拟导出
  const headers = ['Date', 'New Users', 'Active Users']
  const rows = growthData.value.dates.map((d, i) => [d, growthData.value.newUsers[i], growthData.value.activeUsers[i]])
  const csvContent = "data:text/csv;charset=utf-8," 
    + headers.join(",") + "\n"
    + rows.map(e => e.join(",")).join("\n");
  
  const encodedUri = encodeURI(csvContent);
  const link = document.createElement("a");
  link.setAttribute("href", encodedUri);
  link.setAttribute("download", `growth_report_${dayjs().format('YYYYMMDD')}.csv`);
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
}

// 监听语言切换，刷新图表文案（已禁用）
// watch(locale, () => {
//   updateGrowthChart()
//   updateDistributionChart()
//   updateWordCloudChart()
// })
</script>

<style scoped>
.dashboard-container {
  padding: 20px;
  background-color: #f0f2f5;
  min-height: calc(100vh - 100px);
}

.dashboard-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
}

.dashboard-header h2 {
  margin: 0;
  font-weight: 600;
  color: #303133;
}

.stats-row {
  margin-bottom: 20px;
}

.stat-card {
  text-align: center;
}

.stat-label {
  font-size: 14px;
  color: #909399;
  margin-bottom: 10px;
}

.stat-value {
  font-size: 28px;
  font-weight: bold;
  color: #303133;
}

.stat-footer {
  margin-top: 10px;
  font-size: 12px;
}

.trend-up { color: #67C23A; font-weight: bold; }
.trend-down { color: #F56C6C; font-weight: bold; }
.footer-label { color: #909399; margin-left: 5px; }

.chart-row {
  margin-bottom: 20px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.header-actions {
  display: flex;
  align-items: center;
}

.chart-box {
  height: 350px;
  width: 100%;
}

.avg-unlock {
  font-size: 14px;
  color: #606266;
}

.avg-unlock strong {
  color: #409EFF;
  font-size: 18px;
}
</style>
