<template>
  <el-aside width="200px">
    <el-menu :default-openeds="['1']">
      <el-submenu index="1">
        <template slot="title"><i class="el-icon-time"></i>时间轴</template>
        <el-menu-item-group>
          <el-menu-item index="1-1" @click="$router.push({name: 'Home'})">首页</el-menu-item>
          <el-menu-item index="1-2" @click="$router.push({name: 'CapsuleCreate'})">创建胶囊</el-menu-item>
          <el-menu-item index="1-3" @click="$router.push({name: 'Timeline'})">我的时间轴</el-menu-item>
        </el-menu-item-group>
      </el-submenu>
      <el-submenu index="2">
        <template slot="title"><i class="el-icon-star-off"></i>目标设定</template>
        <el-menu-item index="2-1" @click="$router.push({name: 'Goals'})">我的目标</el-menu-item>
      </el-submenu>
      <el-submenu index="3">
        <template slot="title"><i class="el-icon-medal"></i>成就徽章</template>
        <el-menu-item index="3-1" @click="$router.push({name: 'Achievements'})">查看成就</el-menu-item>
      </el-submenu>
    </el-menu>
  </el-aside>
</template>

<script>
export default {
  name: "Sidebar"
}
</script>

<style scoped>
.el-aside {
  background-color: #D3DCE6;
  color: #333;
  text-align: left;
  line-height: 200px;
}

.el-menu {
  border-right: none;
}
</style>