import { fileURLToPath, URL } from 'node:url'

import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [vue()],
  resolve: {
    alias: {
      '@': fileURLToPath(new URL('./src', import.meta.url)),
      'vue': 'vue/dist/vue.esm-bundler.js',
      '@wangeditor/editor-for-vue': '@wangeditor/editor-for-vue/dist/index.js'
    }
  },
  optimizeDeps: {
    include: ['@wangeditor/editor', '@wangeditor/editor-for-vue']
  },
  server: {
    proxy: {
      '/api': {
        target: 'http://localhost:8080', 
        changeOrigin: true,
        ws: true
      }
    }
  }
})
