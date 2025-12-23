// src/router/index.js
import { createRouter, createWebHistory } from 'vue-router'  // 修改：将createWebHashHistory改为createWebHistory

// 导入视图组件
import Login from '@/views/Login.vue'
import Home from '@/views/Home.vue'
import CapsuleCreate from '@/views/CapsuleCreate.vue'
import Timeline from '@/views/Timeline.vue'
import Goals from '@/views/Goals.vue'
import Achievements from '@/views/Achievements.vue'

// 路由配置
const routes = [
  {
    path: '/login',
    name: 'Login',
    component: Login,
    meta: { title: '登录/注册' }
  },
  {
    path: '/',
    name: 'Home',
    component: Home,
    meta: { title: '首页' }
  },
  {
    path: '/capsule/create',
    name: 'CapsuleCreate',
    component: CapsuleCreate,
    meta: { title: '创建时间胶囊' }
  },
  {
    path: '/timeline',
    name: 'Timeline',
    component: Timeline,
    meta: { title: '时间轴' }
  },
  {
    path: '/goals',
    name: 'Goals',
    component: Goals,
    meta: { title: '我的目标' }
  },
  {
    path: '/achievements',
    name: 'Achievements',
    component: Achievements,
    meta: { title: '成就徽章' }
  }
]

// 创建路由器实例
const router = createRouter({
  history: createWebHistory(), // 修改：将createWebHashHistory()改为createWebHistory()
  routes
})

// 路由守卫：检查登录状态
router.beforeEach((to, from, next) => {
  const user = localStorage.getItem('user')
  const isLoginPage = to.path === '/login'
  
  // 如果未登录且不是访问登录页，则跳转到登录页
  if (!user && !isLoginPage) {
    next('/login')
  } 
  // 如果已登录且访问登录页，则跳转到首页
  else if (user && isLoginPage) {
    next('/')
  } 
  // 其他情况正常访问
  else {
    next()
  }
})

export default router