<template>
  <el-container class="layout-container">
    <el-aside width="220px" class="layout-aside">
      <div class="logo-area">
        <div class="logo-icon">P</div>
        <span class="logo-text">项目配置管理</span>
      </div>
      <el-menu
        :default-active="activeMenu"
        class="layout-menu"
        @select="handleMenuSelect"
      >
        <el-menu-item index="/requirement">
          <el-icon><List /></el-icon>
          <span>需求汇总表</span>
        </el-menu-item>
        <el-menu-item index="/project">
          <el-icon><Setting /></el-icon>
          <span>项目配置表</span>
        </el-menu-item>
      </el-menu>
      <div class="aside-footer">
        <span class="version-text">v1.0.0</span>
      </div>
    </el-aside>
    <el-main class="layout-main">
      <router-view />
    </el-main>
  </el-container>
</template>

<script setup>
import { computed } from 'vue'
import { useRouter, useRoute } from 'vue-router'

const router = useRouter()
const route = useRoute()

const activeMenu = computed(() => route.path)

const handleMenuSelect = (index) => {
  router.push(index)
}
</script>

<style scoped>
.layout-container {
  height: 100vh;
  background: #F8FAFC;
}
.layout-aside {
  background: #0F172A;
  display: flex;
  flex-direction: column;
  border-right: none;
  overflow: hidden;
}
.logo-area {
  height: 64px;
  display: flex;
  align-items: center;
  padding: 0 20px;
  gap: 12px;
  border-bottom: 1px solid rgba(255,255,255,0.06);
}
.logo-icon {
  width: 32px;
  height: 32px;
  border-radius: 8px;
  background: #2563EB;
  color: #fff;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 700;
  font-size: 16px;
  flex-shrink: 0;
}
.logo-text {
  color: #F8FAFC;
  font-size: 15px;
  font-weight: 600;
  letter-spacing: 0.02em;
}
.layout-menu {
  border-right: none;
  background: transparent;
  padding: 8px;
  flex: 1;
}
.layout-menu .el-menu-item {
  color: #94A3B8;
  border-radius: 8px;
  margin-bottom: 2px;
  height: 44px;
  line-height: 44px;
  font-size: 14px;
  transition: all 0.2s ease;
}
.layout-menu .el-menu-item:hover {
  background: rgba(255,255,255,0.06);
  color: #E2E8F0;
}
.layout-menu .el-menu-item.is-active {
  background: #2563EB;
  color: #FFFFFF;
}
.layout-menu .el-menu-item .el-icon {
  font-size: 18px;
}
.aside-footer {
  padding: 16px 20px;
  border-top: 1px solid rgba(255,255,255,0.06);
}
.version-text {
  color: #475569;
  font-size: 12px;
}
.layout-main {
  background: #F8FAFC;
  padding: 32px;
  overflow-y: auto;
}
</style>
