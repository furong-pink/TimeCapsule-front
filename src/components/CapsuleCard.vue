<template>
  <div class="capsule-card">
    <!-- 其他内容 -->
    <div class="status-tag">
      <!-- 删除: <span class="tag">私密</span> -->
      <span class="tag" v-text="statusText"></span>
    </div>
  </div>
</template>

<script>
export default {
  props: {
    capsule: {
      type: Object,
      required: true
    }
  },
  computed: {
    statusText() {
      // 检查capsule.privacy字段，如果不存在则回退到isPublic字段
      if (this.capsule.privacy !== undefined) {
        return this.capsule.privacy === 'PUBLIC' ? '公开' : '私密';
      }
      return this.capsule.isPublic ? '公开' : '私密';
    }
  }
}
</script>

<style scoped>
.status-tag {
  display: flex;
  align-items: center;
  justify-content: center;
  /* 使用 Flexbox 居中 */
}
.tag {
  padding: 4px 8px;
  background-color: #f0f0f0;
  border-radius: 4px;
  font-size: 12px;
  color: #666;
}
</style>

