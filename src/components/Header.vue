<template>
  <el-header>
    <div class="header-content">
      <img src="@/assets/logo.png" alt="logo" style="height:40px;">
      <span>时光胶囊</span>
    </div>
  </el-header>
</template>

<script>
export default {
  name: "Header"
}
</script>

<style scoped>
.header-content {
  display: flex;
  align-items: center;
  justify-content: start;
  height: 100%;
  background-color: #409EFF;
  color: white;
}
</style>