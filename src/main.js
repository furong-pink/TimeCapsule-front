import { createApp } from 'vue'
import App from './App.vue'
import ElementPlus from 'element-plus'
import 'element-plus/dist/index.css'
import api from './api'
import router from './router'

import './assets/main.css'

const app = createApp(App)
app.config.globalProperties.$axios = api // 将axios挂载到Vue实例上
window.$axios = api // 同时挂载到window对象上，方便在组件中使用
app.use(ElementPlus)
app.use(router)
app.mount('#app')
