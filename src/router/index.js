// src/router/index.js
import { createRouter, createWebHistory } from 'vue-router'

// 导入视图组件
import Login from '@/views/Login.vue'
import Home from '@/views/Home.vue'
import CapsuleCreate from '@/views/CapsuleCreate.vue'
import Timeline from '@/views/Timeline.vue'
import Goals from '@/views/Goals.vue'
import Achievements from '@/views/Achievements.vue'
import CapsuleDetail from '@/views/CapsuleDetail.vue'
import AiAssistant from '@/views/AiAssistant.vue'
import UserManagement from '@/views/admin/UserManagement.vue'
import Dashboard from '@/views/admin/Dashboard.vue'
import CapsuleManagement from '@/views/admin/CapsuleManagement.vue'

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
  },
  {
    path: '/ai-assistant',
    name: 'AiAssistant',
    component: AiAssistant,
    meta: { title: '成长助手' }
  },
  {
    path: '/admin/users',
    name: 'UserManagement',
    component: UserManagement,
    meta: { title: '用户管理', role: 'ADMIN' }
  },
  {
    path: '/admin/dashboard',
    name: 'Dashboard',
    component: Dashboard,
    meta: { title: '数据看板', role: 'ADMIN' }
  },
  {
    path: '/admin/capsules',
    name: 'CapsuleManagement',
    component: CapsuleManagement,
    meta: { title: '胶囊管理', role: 'ADMIN' }
  },
  {
    path: '/capsule/:id',
    name: 'CapsuleDetail',
    component: CapsuleDetail,
    meta: { title: '时间胶囊详情' },
    props: true
  }
]

// 创建路由器实例
const router = createRouter({
  history: createWebHistory(),
  routes
})

// 路由守卫：检查登录状态和权限
router.beforeEach((to, from, next) => {
  const token = localStorage.getItem('token')
  let user = null
  try {
    const userStr = localStorage.getItem('user')
    user = userStr ? JSON.parse(userStr) : null
  } catch (e) {
    console.error('解析用户信息失败', e)
    localStorage.removeItem('user')
  }
  
  const isLoginPage = to.path === '/login'
  
  // 如果没有 token 或没有用户信息，且不是访问登录页，则跳转到登录页
  if ((!token || !user) && !isLoginPage) {
    next('/login')
  } 
  // 如果已登录且访问登录页
  else if (token && user && isLoginPage) {
    // 根据角色跳转到对应的首页
    if (user.role === 'ADMIN') {
      next('/admin/users')
    } else {
      next('/')
    }
  } 
  // 权限控制：如果路由配置了角色要求
  else if (token && user && to.meta.role) {
    if (user.role === to.meta.role) {
      next()
    } else {
      // 角色不匹配，跳转到对应的合法首页
      if (user.role === 'ADMIN') {
        next('/admin/users')
      } else {
        next('/')
      }
    }
  }
  // 其他情况正常访问
  else {
    next()
  }
})

export default router