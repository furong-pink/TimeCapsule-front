<template>
  <div class="ai-assistant-page">
    <div class="page-header">
      <h2>成长助手</h2>
      <p>与 AI 对话，获取个人成长建议和目标管理指导</p>
    </div>
    
    <div class="chat-container">
      <AiChatAssistant />
    </div>
  </div>
</template>

<script setup lang="ts">
import AiChatAssistant from '@/components/AiChatAssistant.vue'
</script>

<style scoped>
.ai-assistant-page {
  padding: 20px;
  max-width: 900px;
  margin: 0 auto;
}

.page-header {
  text-align: center;
  margin-bottom: 30px;
}

.page-header h2 {
  font-size: 28px;
  color: #303133;
  margin-bottom: 10px;
}

.page-header p {
  font-size: 14px;
  color: #606266;
}

.chat-container {
  background-color: #fff;
  border-radius: 8px;
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.1);
  padding: 20px;
}
</style>
