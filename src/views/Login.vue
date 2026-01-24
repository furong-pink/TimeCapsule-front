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
              <el-checkbox v-model="loginForm.remember">3天内自动登录</el-checkbox>
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
                placeholder="昵称（可选）"
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
import { User, Lock } from '@element-plus/icons-vue'

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
    { required: true, message: '请输入邮箱或手机号', trigger: 'blur' },
    {
      validator: (rule, value, callback) => {
        // 验证邮箱格式
        const emailRegex = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;
        // 验证手机号格式
        const phoneRegex = /^1[3-9]\d{9}$/;
        
        if (value === '') {
          callback(); // 如果为空，让required规则处理
        } else if (emailRegex.test(value)) {
          callback();
        } else if (phoneRegex.test(value)) {
          callback();
        } else {
          // 判断是邮箱格式还是手机号格式
          if (value.includes('@')) {
            callback(new Error('邮箱格式不正确，请检查邮箱地址'));
          } else {
            callback(new Error('手机号格式不正确，请检查手机号码'));
          }
        }
      },
      trigger: 'blur'
    }
  ],
  password: [
    { required: true, message: '请输入密码', trigger: 'blur' },
    { min: 6, message: '密码长度至少6位', trigger: 'blur' }
  ]
}

// 注册验证规则
const registerRules = {
  account: [
    { required: true, message: '请输入邮箱或手机号', trigger: 'blur' },
    {
      validator: (rule, value, callback) => {
        // 验证邮箱格式
        const emailRegex = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;
        // 验证手机号格式
        const phoneRegex = /^1[3-9]\d{9}$/;
        
        if (emailRegex.test(value)) {
          callback();
        } else if (phoneRegex.test(value)) {
          callback();
        } else {
          // 判断是邮箱格式还是手机号格式
          if (value.includes('@')) {
            callback(new Error('邮箱格式不正确，请检查邮箱地址'));
          } else {
            callback(new Error('手机号格式不正确，请检查手机号码'));
          }
        }
      },
      trigger: 'blur'
    }
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
    { min: 2, message: '昵称长度至少2位', trigger: 'blur' }
  ]
}

// 处理登录
const handleLogin = async () => {
  if (!loginFormRef.value) return
  await loginFormRef.value.validate((valid) => {
    if (valid) {
      loading.value = true
      try {
        if (window.$axios) {
          // 使用API登录
          const loginData = {
            account: loginForm.account,
            password: loginForm.password,
            remember: loginForm.remember
          };
          
          window.$axios.post('/login', loginData).then(response => {
            if (response?.code === 200 && response?.data) {
              // 保存用户信息和token到本地存储
              const userData = response.data.user;
              const token = response.data.token;
              
              localStorage.setItem('user', JSON.stringify({
                account: userData.account,
                nickname: userData.nickname,
                avatar: userData.avatar
              }));
              
              // 保存token
              localStorage.setItem('token', token);
              
              // 触发自定义事件通知App.vue更新用户信息
              window.dispatchEvent(new CustomEvent('user-login'));
              
              ElMessage.success('登录成功');
              router.push('/');
            } else {
              // 优化登录错误处理，根据不同的错误类型显示不同的提示
              const message = response?.message || response?.msg || '登录失败';
              
              if (response?.code === 404 || message.includes('账号不存在') || message.includes('用户不存在') || message.includes('incorrect') || message.includes('invalid')) {
                ElMessage.error('账号不存在，请检查账号是否正确');
              } else if (message.includes('密码') || message.includes('password')) {
                ElMessage.error('密码错误，请重新输入');
              } else if (message.includes('格式') || message.includes('format')) {
                ElMessage.error('账号格式错误，请检查邮箱或手机号格式');
              } else if (message.includes('禁用') || message.includes('disabled')) {
                ElMessage.error('账号已被禁用，请联系管理员');
              } else {
                ElMessage.error(message || '登录失败，请检查账号和密码');
              }
            }
          }).catch(error => {
            console.error('登录失败:', error);
            // 优化登录错误处理，根据不同的错误类型显示不同的提示
            if (error.response) {
              // 服务器响应了错误状态
              const status = error.response.status;
              const message = error.response.data?.message || error.response.data?.msg || '登录失败';
              
              if (status === 404 || message.includes('账号不存在') || message.includes('用户不存在') || message.includes('incorrect') || message.includes('invalid')) {
                ElMessage.error('账号不存在，请检查账号是否正确');
              } else if (status === 401 || message.includes('未授权') || message.includes('unauthorized')) {
                ElMessage.error('登录已过期，请重新登录');
              } else if (status === 400 || message.includes('格式') || message.includes('format')) {
                ElMessage.error('账号格式错误，请检查邮箱或手机号格式');
              } else if (status === 403 || message.includes('禁用') || message.includes('disabled')) {
                ElMessage.error('账号已被禁用，请联系管理员');
              } else if (status === 429 || message.includes('频繁') || message.includes('rate limit')) {
                ElMessage.error('登录尝试过于频繁，请稍后再试');
              } else {
                // 尝试从错误信息中提取更具体的错误原因
                if (message.includes('password') || message.includes('密码')) {
                  ElMessage.error('密码错误，请重新输入');
                } else if (message.includes('email')) {
                  ElMessage.error('邮箱格式错误，请检查邮箱地址');
                } else if (message.includes('phone')) {
                  ElMessage.error('手机号格式错误，请检查手机号码');
                } else {
                  ElMessage.error(message || '登录失败，请检查账号和密码');
                }
              }
            } else if (error.request) {
              // 请求已发出但没有收到响应
              ElMessage.error('网络连接失败，请检查网络后重试');
            } else {
              // 其他错误
              ElMessage.error('发生未知错误，请稍后再试');
            }
          });
        } else {
          ElMessage.error('API服务不可用');
        }
      } catch (error) {
        console.error('登录失败:', error);
        ElMessage.error('登录失败: ' + (error.response?.data?.message || error.message));
      } finally {
        loading.value = false;
      }
    }
  })
}

// 保存用户数据并跳转到首页
const saveUserDataAndRedirect = (userData, token) => {
  localStorage.setItem('user', JSON.stringify({
    account: userData.account || registerForm.account,
    nickname: userData.nickname || (registerForm.nickname || registerForm.account),
    avatar: userData.avatar || ''
  }));
  
  // 保存token
  localStorage.setItem('token', token);
  
  // 触发自定义事件通知App.vue更新用户信息
  window.dispatchEvent(new CustomEvent('user-login'));
  
  ElMessage.success('注册成功');
  router.push('/');
};

// 处理注册
const handleRegister = async () => {
  if (!registerFormRef.value) return
  await registerFormRef.value.validate((valid) => {
    if (valid) {
      loading.value = true
      try {
        if (window.$axios) {
          // 使用API注册
          // 如果用户未填写昵称，使用账号（手机号或邮箱）作为昵称
          const nickname = registerForm.nickname || registerForm.account;
          
          const registerData = {
            account: registerForm.account,
            password: registerForm.password,
            nickname: nickname
          };
          
          window.$axios.post('/register', registerData).then(response => {
            console.log('注册响应:', response);
            if (response?.code === 201 && response?.data) {
              // 保存用户信息和token到本地存储
              const userData = response.data;
              // 从响应中直接获取token，可能在顶级或嵌套在data中
              const token = response.data.token || response.data?.data?.token;
              
              if (userData) {
                // 如果有token，直接使用；否则尝试自动登录获取token
                if (token) {
                  // 直接使用返回的token
                  saveUserDataAndRedirect(userData, token);
                } else {
                  // 尝试使用刚注册的账号和密码进行登录以获取token
                  window.$axios.post('/login', {
                    account: registerForm.account,
                    password: registerForm.password,
                    remember: false
                  }).then(loginResponse => {
                    if (loginResponse?.code === 200 && loginResponse?.data?.token) {
                      // 使用登录获取的token
                      saveUserDataAndRedirect(loginResponse.data.user, loginResponse.data.token);
                    } else {
                      ElMessage.error('注册成功，但自动登录失败，请手动登录');
                      router.push('/login');
                    }
                  }).catch(loginError => {
                    console.error('自动登录失败:', loginError);
                    ElMessage.error('注册成功，但自动登录失败，请手动登录');
                    router.push('/login');
                  });
                }
              } else {
                ElMessage.error('注册返回数据不完整');
              }
            } else {
              // 检查是否为账号已存在错误
              const message = response?.message || response?.msg || '注册失败';
              
              if (response?.code === 409 || message.includes('已存在') || message.includes('exist') || message.includes('duplicate')) {
                ElMessage.error('账号已存在');
              } else if (response?.code === 400 || message.includes('格式') || message.includes('format')) {
                ElMessage.error('账号格式错误，请检查邮箱或手机号格式');
              } else if (response?.code === 422 || message.includes('密码') || message.includes('password')) {
                ElMessage.error('密码强度不足，请确保密码至少6位');
              } else if (response?.code === 401) {
                ElMessage.error('未授权，请稍后再试');
              } else if (response?.code === 403) {
                ElMessage.error('禁止访问，请联系管理员');
              } else {
                // 尝试从错误信息中提取更具体的错误原因
                if (message.includes('username') || message.includes('account')) {
                  ElMessage.error('账号格式错误，请检查输入');
                } else if (message.includes('nickname')) {
                  ElMessage.error('昵称格式错误，请检查输入');
                } else if (message.includes('email')) {
                  ElMessage.error('邮箱格式错误，请检查邮箱地址');
                } else if (message.includes('phone')) {
                  ElMessage.error('手机号格式错误，请检查手机号码');
                } else {
                  ElMessage.error(message || '注册失败，请稍后再试');
                }
              }
            }
          }).catch(error => {
            console.error('注册失败:', error);
            // 更详细的错误处理，根据不同的错误类型显示不同的提示
            if (error.response) {
              // 服务器响应了错误状态
              const status = error.response.status;
              const message = error.response.data?.message || error.response.data?.msg || '注册失败';
              
              if (status === 409 || message.includes('已存在') || message.includes('exist') || message.includes('duplicate')) {
                ElMessage.error('账号已存在');
              } else if (status === 400 || message.includes('格式') || message.includes('format')) {
                ElMessage.error('账号格式错误，请检查邮箱或手机号格式');
              } else if (status === 422 || message.includes('密码') || message.includes('password')) {
                ElMessage.error('密码强度不足，请确保密码至少6位');
              } else if (status === 401) {
                ElMessage.error('未授权，请稍后再试');
              } else if (status === 403) {
                ElMessage.error('禁止访问，请联系管理员');
              } else {
                // 尝试从错误信息中提取更具体的错误原因
                if (message.includes('username') || message.includes('account')) {
                  ElMessage.error('账号格式错误，请检查输入');
                } else if (message.includes('nickname')) {
                  ElMessage.error('昵称格式错误，请检查输入');
                } else if (message.includes('email')) {
                  ElMessage.error('邮箱格式错误，请检查邮箱地址');
                } else if (message.includes('phone')) {
                  ElMessage.error('手机号格式错误，请检查手机号码');
                } else {
                  ElMessage.error(message || '注册失败，请稍后再试');
                }
              }
            } else if (error.request) {
              // 请求已发出但没有收到响应
              ElMessage.error('网络连接失败，请检查网络后重试');
            } else {
              // 其他错误
              ElMessage.error('发生未知错误，请稍后再试');
            }
          });
        } else {
          ElMessage.error('API服务不可用');
        }
      } catch (error) {
        console.error('注册失败:', error);
        ElMessage.error('注册失败: ' + (error.response?.data?.message || error.message));
      } finally {
        loading.value = false;
      }
    }
  })
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

