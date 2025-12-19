<template>
  <div class="login-container">
    <div class="login-box">
      <div class="login-header">
        <h1>时光胶囊</h1>
        <p>记录时光，遇见未来</p>
      </div>

      <!-- 登录表单 -->
      <el-tabs v-model="activeTab" class="login-tabs">
        <el-tab-pane label="登录" name="login">
          <el-form :model="loginForm" :rules="loginRules" ref="loginFormRef" class="login-form">
            <el-form-item prop="account">
              <el-input
                v-model="loginForm.account"
                placeholder="邮箱/手机号"
                prefix-icon="User"
                size="large"
              />
            </el-form-item>
            <el-form-item prop="password">
              <el-input
                v-model="loginForm.password"
                type="password"
                placeholder="密码"
                prefix-icon="Lock"
                size="large"
                show-password
                @keyup.enter="handleLogin"
              />
            </el-form-item>
            <div class="form-options">
              <el-checkbox v-model="loginForm.remember">记住我</el-checkbox>
              <el-link type="primary" :underline="false" @click="showForgotPassword = true">
                忘记密码？
              </el-link>
            </div>
            <el-button type="primary" size="large" class="login-btn" @click="handleLogin" :loading="loading">
              登录
            </el-button>
          </el-form>
        </el-tab-pane>

        <el-tab-pane label="注册" name="register">
          <el-form :model="registerForm" :rules="registerRules" ref="registerFormRef" class="login-form">
            <el-form-item prop="account">
              <el-input
                v-model="registerForm.account"
                placeholder="邮箱/手机号"
                prefix-icon="User"
                size="large"
              />
            </el-form-item>
            <el-form-item prop="password">
              <el-input
                v-model="registerForm.password"
                type="password"
                placeholder="密码（至少6位）"
                prefix-icon="Lock"
                size="large"
                show-password
              />
            </el-form-item>
            <el-form-item prop="confirmPassword">
              <el-input
                v-model="registerForm.confirmPassword"
                type="password"
                placeholder="确认密码"
                prefix-icon="Lock"
                size="large"
                show-password
                @keyup.enter="handleRegister"
              />
            </el-form-item>
            <el-form-item prop="nickname">
              <el-input
                v-model="registerForm.nickname"
                placeholder="昵称"
                prefix-icon="User"
                size="large"
              />
            </el-form-item>
            <el-button type="primary" size="large" class="login-btn" @click="handleRegister" :loading="loading">
              注册
            </el-button>
          </el-form>
        </el-tab-pane>
      </el-tabs>

      <!-- 第三方登录 -->
      <div class="third-party-login">
        <div class="divider">
          <span>或使用第三方账号登录</span>
        </div>
        <div class="social-login">
          <el-button circle class="social-btn wechat" @click="handleSocialLogin('wechat')">
            <el-icon><ChatDotRound /></el-icon>
          </el-button>
          <el-button circle class="social-btn qq" @click="handleSocialLogin('qq')">
            <el-icon><Message /></el-icon>
          </el-button>
          <el-button circle class="social-btn weibo" @click="handleSocialLogin('weibo')">
            <el-icon><Share /></el-icon>
          </el-button>
        </div>
      </div>
    </div>

    <!-- 忘记密码对话框 -->
    <el-dialog v-model="showForgotPassword" title="忘记密码" width="400px">
      <el-form :model="forgotForm" label-width="100px">
        <el-form-item label="邮箱/手机号">
          <el-input v-model="forgotForm.account" placeholder="请输入注册时的邮箱或手机号" />
        </el-form-item>
        <el-form-item label="验证码">
          <div style="display: flex; gap: 10px;">
            <el-input v-model="forgotForm.code" placeholder="请输入验证码" />
            <el-button @click="sendCode">发送验证码</el-button>
          </div>
        </el-form-item>
        <el-form-item label="新密码">
          <el-input v-model="forgotForm.newPassword" type="password" placeholder="请输入新密码" show-password />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="showForgotPassword = false">取消</el-button>
        <el-button type="primary" @click="handleResetPassword">确定</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { User, Lock, ChatDotRound, Message, Share } from '@element-plus/icons-vue'

const router = useRouter()
const activeTab = ref('login')
const loading = ref(false)
const showForgotPassword = ref(false)
const loginFormRef = ref(null)
const registerFormRef = ref(null)

// 登录表单
const loginForm = reactive({
  account: '',
  password: '',
  remember: false
})

// 注册表单
const registerForm = reactive({
  account: '',
  password: '',
  confirmPassword: '',
  nickname: ''
})

// 忘记密码表单
const forgotForm = reactive({
  account: '',
  code: '',
  newPassword: ''
})

// 登录验证规则
const loginRules = {
  account: [
    { required: true, message: '请输入邮箱或手机号', trigger: 'blur' }
  ],
  password: [
    { required: true, message: '请输入密码', trigger: 'blur' },
    { min: 6, message: '密码长度至少6位', trigger: 'blur' }
  ]
}

// 注册验证规则
const registerRules = {
  account: [
    { required: true, message: '请输入邮箱或手机号', trigger: 'blur' }
  ],
  password: [
    { required: true, message: '请输入密码', trigger: 'blur' },
    { min: 6, message: '密码长度至少6位', trigger: 'blur' }
  ],
  confirmPassword: [
    { required: true, message: '请确认密码', trigger: 'blur' },
    {
      validator: (rule, value, callback) => {
        if (value !== registerForm.password) {
          callback(new Error('两次输入的密码不一致'))
        } else {
          callback()
        }
      },
      trigger: 'blur'
    }
  ],
  nickname: [
    { required: true, message: '请输入昵称', trigger: 'blur' },
    { min: 2, message: '昵称长度至少2位', trigger: 'blur' }
  ]
}

// 处理登录
const handleLogin = async () => {
  if (!loginFormRef.value) return
  await loginFormRef.value.validate((valid) => {
    if (valid) {
      loading.value = true
      // 模拟登录请求
      setTimeout(() => {
        loading.value = false
        // 尝试从注册信息中获取昵称
        const registeredUsers = JSON.parse(localStorage.getItem('registeredUsers') || '[]')
        const user = registeredUsers.find(u => u.account === loginForm.account)
        
        // 保存用户信息到本地存储
        localStorage.setItem('user', JSON.stringify({
          account: loginForm.account,
          nickname: user?.nickname || loginForm.account, // 优先使用注册时的昵称
          avatar: user?.avatar || ''
        }))
        ElMessage.success('登录成功')
        router.push('/')
      }, 1000)
    }
  })
}

// 处理注册
const handleRegister = async () => {
  if (!registerFormRef.value) return
  await registerFormRef.value.validate((valid) => {
    if (valid) {
      loading.value = true
      // 模拟注册请求
      setTimeout(() => {
        loading.value = false
        // 保存注册用户信息
        const registeredUsers = JSON.parse(localStorage.getItem('registeredUsers') || '[]')
        registeredUsers.push({
          account: registerForm.account,
          password: registerForm.password, // 实际项目中不应该存储明文密码
          nickname: registerForm.nickname,
          avatar: '',
          registerTime: new Date().toISOString()
        })
        localStorage.setItem('registeredUsers', JSON.stringify(registeredUsers))
        
        // 注册成功后自动登录
        localStorage.setItem('user', JSON.stringify({
          account: registerForm.account,
          nickname: registerForm.nickname,
          avatar: ''
        }))
        
        ElMessage.success('注册成功')
        router.push('/')
      }, 1000)
    }
  })
}

// 第三方登录
const handleSocialLogin = (type) => {
  ElMessage.info(`${type === 'wechat' ? '微信' : type === 'qq' ? 'QQ' : '微博'}登录功能开发中...`)
}

// 发送验证码
const sendCode = () => {
  if (!forgotForm.account) {
    ElMessage.warning('请先输入邮箱或手机号')
    return
  }
  ElMessage.success('验证码已发送')
}

// 重置密码
const handleResetPassword = () => {
  if (!forgotForm.account || !forgotForm.code || !forgotForm.newPassword) {
    ElMessage.warning('请填写完整信息')
    return
  }
  ElMessage.success('密码重置成功，请使用新密码登录')
  showForgotPassword.value = false
}
</script>

<style scoped>
.login-container {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg, #e3f2fd 0%, #bbdefb 25%, #90caf9 50%, #64b5f6 75%, #42a5f5 100%);
  background-size: 400% 400%;
  animation: gradientShift 15s ease infinite;
  padding: 20px;
  position: relative;
  overflow: hidden;
}

/* 添加时间胶囊主题的装饰元素 */
.login-container::before {
  content: '';
  position: absolute;
  top: -50%;
  left: -50%;
  width: 200%;
  height: 200%;
  background: radial-gradient(circle, rgba(255, 255, 255, 0.15) 1px, transparent 1px);
  background-size: 50px 50px;
  animation: float 20s linear infinite;
  pointer-events: none;
}

.login-container::after {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: 
    radial-gradient(ellipse at top left, rgba(100, 181, 246, 0.2) 0%, transparent 50%),
    radial-gradient(ellipse at bottom right, rgba(66, 165, 245, 0.2) 0%, transparent 50%);
  pointer-events: none;
}

@keyframes gradientShift {
  0% { background-position: 0% 50%; }
  50% { background-position: 100% 50%; }
  100% { background-position: 0% 50%; }
}

@keyframes float {
  0% { transform: translate(0, 0) rotate(0deg); }
  100% { transform: translate(-50px, -50px) rotate(360deg); }
}

.login-box {
  width: 100%;
  max-width: 420px;
  background: rgba(255, 255, 255, 0.95);
  backdrop-filter: blur(10px);
  border-radius: 20px;
  padding: 40px;
  box-shadow: 
    0 20px 60px rgba(0, 0, 0, 0.15),
    0 0 0 1px rgba(255, 255, 255, 0.3) inset;
  position: relative;
  z-index: 1;
  border: 1px solid rgba(255, 255, 255, 0.5);
}

.login-header {
  text-align: center;
  margin-bottom: 30px;
}

.login-header h1 {
  font-size: 36px;
  background: linear-gradient(135deg, #1976d2 0%, #42a5f5 50%, #1976d2 100%);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
  margin-bottom: 8px;
  font-weight: 700;
  letter-spacing: 2px;
}

.login-header p {
  color: #1976d2;
  font-size: 15px;
  font-weight: 500;
  opacity: 0.8;
}

.login-tabs {
  margin-bottom: 30px;
}

.login-form {
  margin-top: 20px;
}

.form-options {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
}

.login-btn {
  width: 100%;
  margin-top: 10px;
  background: linear-gradient(135deg, #42a5f5 0%, #1976d2 100%);
  border: none;
  height: 44px;
  font-size: 16px;
  font-weight: 600;
  transition: all 0.3s ease;
}

.login-btn:hover {
  background: linear-gradient(135deg, #1976d2 0%, #42a5f5 100%);
  transform: translateY(-2px);
  box-shadow: 0 8px 20px rgba(25, 118, 210, 0.3);
}

.third-party-login {
  margin-top: 30px;
}

.divider {
  text-align: center;
  margin: 20px 0;
  position: relative;
}

.divider::before,
.divider::after {
  content: '';
  position: absolute;
  top: 50%;
  width: 35%;
  height: 1px;
  background: #e0e0e0;
}

.divider::before {
  left: 0;
}

.divider::after {
  right: 0;
}

.divider span {
  color: #999;
  font-size: 12px;
  background: white;
  padding: 0 10px;
  position: relative;
}

.social-login {
  display: flex;
  justify-content: center;
  gap: 20px;
}

.social-btn {
  width: 50px;
  height: 50px;
  font-size: 24px;
}

.social-btn.wechat {
  background: #07c160;
  color: white;
  border-color: #07c160;
}

.social-btn.qq {
  background: #12b7f5;
  color: white;
  border-color: #12b7f5;
}

.social-btn.weibo {
  background: #e6162d;
  color: white;
  border-color: #e6162d;
}

.social-btn:hover {
  opacity: 0.8;
  transform: translateY(-3px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.2);
}

/* 优化输入框样式 */
:deep(.el-input__wrapper) {
  background-color: rgba(255, 255, 255, 0.9);
  border-radius: 8px;
  box-shadow: 0 2px 8px rgba(25, 118, 210, 0.1);
}

:deep(.el-input__wrapper:hover) {
  box-shadow: 0 4px 12px rgba(25, 118, 210, 0.15);
}

:deep(.el-input.is-focus .el-input__wrapper) {
  box-shadow: 0 4px 12px rgba(25, 118, 210, 0.25);
  border-color: #42a5f5;
}

/* 优化标签页样式 */
:deep(.el-tabs__item) {
  color: #1976d2;
  font-weight: 500;
}

:deep(.el-tabs__item.is-active) {
  color: #1976d2;
  font-weight: 600;
}

:deep(.el-tabs__active-bar) {
  background-color: #1976d2;
}

/* 优化链接样式 */
:deep(.el-link) {
  color: #42a5f5;
}

:deep(.el-link:hover) {
  color: #1976d2;
}

/* 优化复选框样式 */
:deep(.el-checkbox__label) {
  color: #666;
}
</style>

