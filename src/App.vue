<!-- src/App.vue -->
<template>
  <el-config-provider>
    <!-- 登录页面：不显示导航栏 -->
    <div v-if="isLoginPage" class="login-page-wrapper">
      <router-view />
    </div>
    
    <!-- 主应用页面：显示完整布局 -->
    <el-container v-else class="app-container">
      <!-- 顶部栏 -->
      <el-header class="app-header">
        <div class="header-title">时光胶囊</div>
        <div class="header-right" v-if="isLoggedIn">
          <el-dropdown @command="handleCommand" trigger="click" @visible-change="handleDropdownVisibleChange">
            <span class="user-info" :class="{ 'dropdown-open': userMenuOpen }">
              <el-avatar :size="32" :src="userInfo.avatar" style="margin-right: 8px;">
                <el-icon><User /></el-icon>
              </el-avatar>
              <span class="username">{{ userInfo.nickname || '用户' }}</span>
              <el-icon class="dropdown-icon"><ArrowDown /></el-icon>
            </span>
            <template #dropdown>
              <el-dropdown-menu>
                <el-dropdown-item command="logout">
                  <el-icon><SwitchButton /></el-icon>
                  退出登录
                </el-dropdown-item>
              </el-dropdown-menu>
            </template>
          </el-dropdown>
        </div>
      </el-header>

      <el-container class="main-layout">
        <!-- 左侧导航菜单 -->
        <el-aside class="app-aside" width="200px">
          <el-menu
            :default-active="$route.path"
            router
            background-color="#f5f7fa"
            text-color="#333"
            active-text-color="#409EFF"
            :unique-opened="true"
            class="sidebar-menu"
          >
            <el-menu-item index="/">
              <el-icon><House /></el-icon>
              <span>首页</span>
            </el-menu-item>
            <el-menu-item index="/capsule/create">
              <el-icon><Edit /></el-icon>
              <span>创建胶囊</span>
            </el-menu-item>
            <el-menu-item index="/timeline">
              <el-icon><Timer /></el-icon>
              <span>时间轴</span>
            </el-menu-item>
            <el-menu-item index="/goals">
              <el-icon><Trophy /></el-icon>
              <span>我的目标</span>
            </el-menu-item>
            <el-menu-item index="/achievements">
              <el-icon><Medal /></el-icon>
              <span>成就徽章</span>
            </el-menu-item>
          </el-menu>
        </el-aside>

        <!-- 主内容区域 -->
        <el-main class="app-main">
          <router-view :key="$route.fullPath" />
        </el-main>
      </el-container>
    </el-container>
  </el-config-provider>
</template>

<script setup>
import { ref, computed, onMounted, watch } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import { House, Edit, Timer, Trophy, Medal, User, ArrowDown, SwitchButton } from '@element-plus/icons-vue'

const router = useRouter()
const route = useRoute()

// 用户信息
const userInfo = ref({
  nickname: '',
  avatar: ''
})

// 用户下拉菜单是否展开
const userMenuOpen = ref(false)

// 检查是否为登录页面
const isLoginPage = computed(() => {
  return route.path === '/login'
})

// 检查登录状态
const isLoggedIn = computed(() => {
  const user = localStorage.getItem('user')
  return !!user
})

// 加载用户信息
const loadUserInfo = () => {
  const user = localStorage.getItem('user')
  if (user) {
    try {
      userInfo.value = JSON.parse(user)
    } catch (e) {
      console.error('加载用户信息失败', e)
    }
  }
}

// 处理下拉菜单命令
const handleCommand = (command) => {
  if (command === 'logout') {
    ElMessageBox.confirm('确定要退出登录吗？', '提示', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning'
    }).then(() => {
      // 清除用户信息
      localStorage.removeItem('user')
      userInfo.value = { nickname: '', avatar: '' }
      ElMessage.success('已退出登录')
      // 跳转到登录页
      router.push('/login')
    }).catch(() => {})
  }
}

// 处理下拉菜单显示/隐藏，控制箭头动画
const handleDropdownVisibleChange = (visible) => {
  userMenuOpen.value = visible
}

// 监听路由变化
watch(() => route.path, (newPath) => {
  if (newPath !== '/login') {
    loadUserInfo()
  } else {
    // 如果已经在登录页，清除用户信息
    userInfo.value = { nickname: '', avatar: '' }
  }
}, { immediate: true })

// 组件挂载时加载用户信息
onMounted(() => {
  loadUserInfo()
})
</script>

<style scoped>
/* 整体容器：铺满视口 */
.app-container {
  height: 100vh;
  display: flex;
  flex-direction: column;
  margin: 0;
  padding: 0;
}

/* 顶部栏样式 */
.app-header {
  background-color: #409eff;
  color: white;
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 20px;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
  z-index: 100;
  margin: 0;
}

.header-title {
  font-size: 20px;
  font-weight: bold;
}

.header-right {
  display: flex;
  align-items: center;
}

.user-info {
  display: flex;
  align-items: center;
  cursor: pointer;
  padding: 4px 12px;
  border-radius: 4px;
  transition: background-color 0.3s;
}

.user-info:hover {
  background-color: rgba(255, 255, 255, 0.1);
}

.username {
  margin-right: 8px;
  font-size: 14px;
}

.dropdown-icon {
  font-size: 12px;
  transition: transform 0.3s;
}

.user-info.dropdown-open .dropdown-icon {
  transform: rotate(180deg);
}

/* 登录页面包装器 */
.login-page-wrapper {
  width: 100%;
  height: 100vh;
  overflow: hidden;
}

/* 主布局：除去 header 后剩余空间 */
.main-layout {
  flex: 1;
  display: flex;
  overflow: hidden;
  margin: 0;
  padding: 0;
}

/* 侧边栏样式 */
.app-aside {
  background-color: #f5f7fa;
  border-right: 1px solid #e6e6e6;
  width: 200px;
  flex-shrink: 0;
  margin: 0;
  padding: 0;
}

.sidebar-menu {
  border-right: none;
  height: 100%;
  margin: 0;
  padding: 0;
}

/* 主内容区 */
.app-main {
  flex: 1;
  background-color: #ffffff;
  margin: 0;
  padding: 20px;
  overflow-y: auto;
  height: 100%;
}
</style>

<style>
/* 全局样式修复 */
html, body, #app {
  height: 100%;
  margin: 0;
  padding: 0;
  width: 100%;
}

/* 确保Element Plus容器铺满全屏 */
.el-container {
  height: 100%;
  margin: 0;
  padding: 0;
  width: 100%;
}

.el-aside {
  height: 100%;
  margin: 0;
  padding: 0;
}

.el-main {
  margin: 0;
  padding: 20px;
}

/* 移除可能存在的最大宽度限制 */
#app .app-container {
  max-width: none;
}
</style>