import axios from 'axios';
import API_BASE_URL from './config';

// 创建axios实例
const api = axios.create({
  baseURL: API_BASE_URL,
  timeout: 10000,
  headers: {
    'Content-Type': 'application/json'
  }
});

// 请求拦截器
api.interceptors.request.use(
  config => {
    // 添加JWT token到请求头
    const token = localStorage.getItem('token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  error => {
    return Promise.reject(error);
  }
);

// 导入Element Plus组件
import { ElMessageBox, ElMessage } from 'element-plus';

// 响应拦截器
api.interceptors.response.use(
  response => {
    // 处理API响应格式
    return response.data;
  },
  error => {
    // 处理错误响应
    if (error.response?.status === 401) {
      // Token过期，显示提示并跳转到登录页
      localStorage.removeItem('token');
      localStorage.removeItem('user');
      
      // 显示确认对话框，只提供确定选项
      ElMessageBox.alert('登录已过期，请重新登录', '提示', {
        confirmButtonText: '确定',
        callback: () => {
          window.location.href = '/login';
        }
      }).catch(() => {
        // 捕获取消操作，但仍跳转到登录页
        window.location.href = '/login';
      });
    }
    return Promise.reject(error);
  }
);

// 用户认证API
export const authAPI = {
  // 用户注册
  register: (data) => api.post('/register', data),
  
  // 用户登录
  login: (data) => api.post('/login', data),
  
  // 刷新Token
  refresh: () => api.post('/refresh'),
  
  // 忘记密码
  forgotPassword: (data) => api.post('/forgot-password', data),
  
  // 发送验证码
  sendCode: (data) => api.post('/send-code', data)
};

// 时间胶囊API
export const capsuleAPI = {
  // 获取时间胶囊列表
  getCapsules: (params) => api.get('/capsules', { params }),
  
  // 获取时间胶囊详情
  getCapsule: (id) => api.get(`/capsules/${id}`),
  
  // 创建时间胶囊
  createCapsule: (data) => api.post('/capsules', data),
  
  // 更新时间胶囊
  updateCapsule: (id, data) => api.put(`/capsules/${id}`, data),
  
  // 删除时间胶囊
  deleteCapsule: (id) => api.delete(`/capsules/${id}`),
  
  // 开启时间胶囊
  openCapsule: (id) => api.post(`/capsules/${id}/open`),
  
  // 获取时间轴数据
  getTimeline: (params) => api.get('/capsules/timeline', { params }),
  
  // 保存草稿
  saveDraft: (data) => api.post('/capsules/drafts', data),
  
  // 获取草稿列表
  getDrafts: (params) => api.get('/capsules/drafts', { params })
};

// 目标API
export const goalAPI = {
  // 获取目标列表
  getGoals: (params) => api.get('/goals', { params }),
  
  // 获取目标详情
  getGoal: (id) => api.get(`/goals/${id}`),
  
  // 创建目标
  createGoal: (data) => api.post('/goals', data),
  
  // 更新目标
  updateGoal: (id, data) => api.put(`/goals/${id}`, data),
  
  // 更新目标进度
  updateProgress: (id, data) => api.patch(`/goals/${id}/progress`, data),
  
  // 删除目标
  deleteGoal: (id) => api.delete(`/goals/${id}`),
  
  // 切换提醒开关
  toggleReminder: (id, data) => api.patch(`/goals/${id}/reminder`, data)
};

// 成就API
export const achievementAPI = {
  // 获取成就列表
  getAchievements: (params) => api.get('/achievements', { params }),
  
  // 获取成就详情
  getAchievement: (id) => api.get(`/achievements/${id}`),
  
  // 标记成就已读
  markAchievementRead: (id) => api.patch(`/achievements/${id}/read`),
  
  // 检查并解锁成就
  checkAchievements: () => api.post('/achievements/check')
};

// 用户API
export const userAPI = {
  // 获取当前用户信息
  getCurrentUser: () => api.get('/users/profile'),
  
  // 更新用户信息
  updateUserProfile: (data) => api.put('/users/profile', data),
  
  // 修改密码
  updatePassword: (data) => api.put('/users/password', data)
};

// 统计API
export const statisticsAPI = {
  // 获取首页统计数据
  getHomeStats: () => api.get('/statistics/home')
};

// 文件上传API
export const uploadAPI = {
  // 上传文件
  uploadFile: (formData) => {
    return api.post('/upload', formData, {
      headers: {
        'Content-Type': 'multipart/form-data'
      }
    });
  }
};

export default api;