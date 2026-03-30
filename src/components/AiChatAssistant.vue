<template>
  <div class="ai-chat-container">
    <!-- 消息列表区域 -->
    <div class="messages-container" ref="messagesContainerRef">
      <div
        v-for="(message, index) in messages"
        :key="index"
        :class="['message', message.role]"
      >
        <div class="message-content">
          {{ message.content }}
        </div>
      </div>
      <div v-if="loading" class="message ai">
        <div class="message-content">AI 思考中...</div>
      </div>
    </div>

    <!-- 底部输入栏 -->
    <div class="input-container">
      <el-input
        v-model="inputText"
        type="textarea"
        :rows="3"
        placeholder="输入你的问题，按回车发送..."
        :disabled="loading"
        @keydown.enter.exact.prevent="sendMessage"
        resize="none"
      />
      <el-button
        type="primary"
        :loading="loading"
        :disabled="!inputText.trim() || loading"
        @click="sendMessage"
        style="margin-top: 10px; width: 100%;"
      >
        发送
      </el-button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, nextTick } from 'vue'
import { ElMessage } from 'element-plus'
import axios from 'axios'

// 状态管理
interface Message {
  role: 'user' | 'ai'
  content: string
}

const messages = ref<Message[]>([])
const inputText = ref<string>('')
const loading = ref<boolean>(false)
const messagesContainerRef = ref<HTMLElement | null>(null)

// 发送消息
const sendMessage = async () => {
  const trimmedText = inputText.value.trim()
  if (!trimmedText || loading.value) return

  // 添加用户消息
  messages.value.push({
    role: 'user',
    content: trimmedText
  })

  // 清空输入框并禁用
  inputText.value = ''
  loading.value = true

  // 滚动到底部
  await nextTick()
  scrollToBottom()

  try {
    // 调用后端 AI 接口
    const response = await axios.post('/api/ai/chat', {
      message: trimmedText
    })

    // 添加 AI 回复
    if (response.data && response.data.reply) {
      messages.value.push({
        role: 'ai',
        content: response.data.reply
      })
    } else {
      throw new Error('响应格式错误')
    }
  } catch (error) {
    console.error('AI 请求失败:', error)
    ElMessage.error('AI 暂时无法回复，请稍后再试')
  } finally {
    loading.value = false
    await nextTick()
    scrollToBottom()
  }
}

// 滚动到底部
const scrollToBottom = () => {
  if (messagesContainerRef.value) {
    messagesContainerRef.value.scrollTop = messagesContainerRef.value.scrollHeight
  }
}
</script>

<style scoped>
.ai-chat-container {
  display: flex;
  flex-direction: column;
  height: 500px;
  border: 1px solid #e4e7ed;
  border-radius: 8px;
  overflow: hidden;
  background-color: #fff;
}

.messages-container {
  flex: 1;
  overflow-y: auto;
  padding: 20px;
  background-color: #fafafa;
}

.message {
  margin-bottom: 16px;
  display: flex;
}

.message.user {
  justify-content: flex-end;
}

.message.ai {
  justify-content: flex-start;
}

.message-content {
  max-width: 70%;
  padding: 12px 16px;
  border-radius: 8px;
  word-wrap: break-word;
  line-height: 1.5;
}

.message.user .message-content {
  background-color: #d9ecff;
  color: #333;
}

.message.ai .message-content {
  background-color: #f5f5f5;
  color: #333;
}

.input-container {
  padding: 16px;
  border-top: 1px solid #e4e7ed;
  background-color: #fff;
}
</style>
