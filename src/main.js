import { createApp } from 'vue'
import App from './App.vue'
import ElementPlus from 'element-plus'
import 'element-plus/dist/index.css'
import axios from 'axios'
import router from './router'

import './assets/main.css'

const app = createApp(App)
app.config.globalProperties.$axios = axios // 将axios挂载到Vue实例上
app.use(ElementPlus)
app.use(router)
app.mount('#app')
