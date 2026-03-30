import { createApp } from 'vue'
import App from './App.vue'
import ElementPlus from 'element-plus'
import 'element-plus/dist/index.css'
import api from './api'
import router from './router'
// import i18n from './i18n'

import './assets/main.css'

// 先挂载 axios 到 window 对象，确保组件 setup 时可用
window.$axios = api

const app = createApp(App)
app.config.globalProperties.$axios = api // 将 axios 挂载到 Vue 实例上
app.use(ElementPlus)
app.use(router)
// app.use(i18n)
app.mount('#app')