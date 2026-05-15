<template>
  <div class="requirement-summary">
    <div class="page-header">
      <div class="page-header-left">
        <h1 class="page-title">需求汇总表</h1>
        <span class="page-subtitle">管理任务模块与待办事项</span>
      </div>
      <div class="page-header-right">
        <el-button size="small" :icon="Edit" @click="handleEditModule" :disabled="!currentModuleId">重命名</el-button>
        <el-button size="small" type="primary" :icon="CopyDocument" @click="handleCopyToClipboard" :disabled="!currentModuleId">复制到剪贴板</el-button>
      </div>
    </div>

    <div class="module-bar">
      <div class="module-tabs">
        <div
          v-for="mod in modules"
          :key="mod.id"
          class="module-tab"
          :class="{ active: currentModuleId === mod.id }"
          @click="selectModule(mod.id)"
        >
          <span class="module-tab-name">{{ mod.name }}</span>
          <el-icon class="module-tab-close" @click.stop="handleDeleteModule(mod)"><Close /></el-icon>
        </div>
        <el-button size="small" :icon="Plus" @click="showAddModule = true" text>新增模块</el-button>
      </div>
    </div>

    <div v-if="currentModuleId" class="task-content">
      <div class="task-section">
        <div class="section-header">
          <div class="section-title-group">
            <div class="section-dot today-dot"></div>
            <h3 class="section-title">今日任务</h3>
            <span class="section-count">{{ todayCount }}</span>
          </div>
        </div>
        <TodayTaskList :module-id="currentModuleId" ref="todayTaskRef" @moved-to-todo="onMovedToTodo" />
      </div>
      <div class="task-section">
        <div class="section-header">
          <div class="section-title-group">
            <div class="section-dot todo-dot"></div>
            <h3 class="section-title">待办任务</h3>
            <span class="section-count">{{ todoCount }}</span>
          </div>
        </div>
        <TodoPool :module-id="currentModuleId" ref="todoPoolRef" @moved-to-today="onMovedToToday" />
      </div>
    </div>
    <div v-else class="empty-area">
      <div class="empty-bg"></div>
      <el-empty description="请先创建一个任务模块" />
    </div>

    <el-dialog v-model="showAddModule" title="新增任务模块" width="400px" @close="newModuleName = ''">
      <el-form @submit.prevent="handleAddModule">
        <el-form-item label="模块名称">
          <el-input v-model="newModuleName" placeholder="请输入模块名称" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="showAddModule = false">取消</el-button>
        <el-button type="primary" @click="handleAddModule">确定</el-button>
      </template>
    </el-dialog>

    <el-dialog v-model="showRenameModule" title="重命名任务模块" width="400px">
      <el-form @submit.prevent="handleRenameModule">
        <el-form-item label="模块名称">
          <el-input v-model="renameValue" placeholder="请输入新名称" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="showRenameModule = false">取消</el-button>
        <el-button type="primary" @click="handleRenameModule">确定</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus, Edit, CopyDocument, Close } from '@element-plus/icons-vue'
import TodayTaskList from './TodayTaskList.vue'
import TodoPool from './TodoPool.vue'
import {
  getTaskModules,
  createTaskModule,
  updateTaskModule,
  deleteTaskModule,
  checkPostpone
} from '../api/api.js'

const ROW_HEIGHT = 48
const TOOLBAR_HEIGHT = 44
const TITLE_HEIGHT = 44
const MIN_ROWS = 2

const modules = ref([])
const currentModuleId = ref(null)
const showAddModule = ref(false)
const newModuleName = ref('')
const showRenameModule = ref(false)
const renameValue = ref('')
const todayTaskRef = ref(null)
const todoPoolRef = ref(null)

const todayMinHeight = computed(() => {
  const count = todayTaskRef.value?.taskList?.length || 0
  const rows = Math.max(count, MIN_ROWS)
  return (rows * ROW_HEIGHT + TOOLBAR_HEIGHT + TITLE_HEIGHT) + 'px'
})

const todoMinHeight = computed(() => {
  const count = todoPoolRef.value?.taskList?.length || 0
  const rows = Math.max(count, MIN_ROWS)
  return (rows * ROW_HEIGHT + TOOLBAR_HEIGHT + TITLE_HEIGHT) + 'px'
})

const todayCount = computed(() => todayTaskRef.value?.taskList?.length || 0)
const todoCount = computed(() => todoPoolRef.value?.taskList?.length || 0)

const handleCopyToClipboard = async () => {
  const todayList = todayTaskRef.value?.taskList || []
  const todoList = todoPoolRef.value?.taskList || []
  if (todayList.length === 0 && todoList.length === 0) {
    ElMessage.warning('暂无任务可复制')
    return
  }
  const mod = modules.value.find(m => m.id === currentModuleId.value)
  let text = `【${mod?.name || ''}】\n\n`
  if (todayList.length > 0) {
    text += '=== 今日任务 ===\n'
    todayList.forEach((item, idx) => {
      text += `${idx + 1}. ${item.content}`
      if (item.remarks) text += `（${item.remarks}）`
      text += '\n'
    })
    text += '\n'
  }
  if (todoList.length > 0) {
    text += '=== 待办任务 ===\n'
    todoList.forEach((item, idx) => {
      const postpone = item.postpone_tomorrow ? ' [明天]' : ''
      text += `${idx + 1}. ${item.content}${postpone}`
      if (item.remarks) text += `（${item.remarks}）`
      text += '\n'
    })
  }
  try {
    await navigator.clipboard.writeText(text.trim())
    ElMessage.success('已复制到剪贴板')
  } catch {
    const textarea = document.createElement('textarea')
    textarea.value = text.trim()
    textarea.style.position = 'fixed'
    textarea.style.opacity = '0'
    document.body.appendChild(textarea)
    textarea.select()
    document.execCommand('copy')
    document.body.removeChild(textarea)
    ElMessage.success('已复制到剪贴板')
  }
}

const onMovedToTodo = () => {
  todoPoolRef.value?.loadTasks()
}

const onMovedToToday = () => {
  todayTaskRef.value?.loadTasks()
}

const loadModules = async () => {
  try {
    modules.value = await getTaskModules()
    if (modules.value.length > 0 && !currentModuleId.value) {
      currentModuleId.value = modules.value[0].id
    }
  } catch (e) {
    ElMessage.error('加载任务模块失败')
  }
}

const selectModule = (id) => {
  currentModuleId.value = id
}

const handleAddModule = async () => {
  if (!newModuleName.value.trim()) {
    ElMessage.warning('请输入模块名称')
    return
  }
  try {
    await createTaskModule({ name: newModuleName.value.trim() })
    ElMessage.success('创建成功')
    showAddModule.value = false
    newModuleName.value = ''
    await loadModules()
    if (modules.value.length > 0) {
      currentModuleId.value = modules.value[modules.value.length - 1].id
    }
  } catch (e) {
    ElMessage.error('创建失败')
  }
}

const handleDeleteModule = async (mod) => {
  try {
    await ElMessageBox.confirm(`确定删除任务模块"${mod.name}"？该模块下所有任务将一并删除。`, '删除确认', {
      type: 'warning'
    })
    await deleteTaskModule(mod.id)
    ElMessage.success('删除成功')
    await loadModules()
    if (currentModuleId.value === mod.id) {
      currentModuleId.value = modules.value.length > 0 ? modules.value[0].id : null
    }
  } catch (e) {
    if (e !== 'cancel') {
      ElMessage.error('删除失败')
    }
  }
}

const handleEditModule = () => {
  const mod = modules.value.find(m => m.id === currentModuleId.value)
  if (mod) {
    renameValue.value = mod.name
    showRenameModule.value = true
  }
}

const handleRenameModule = async () => {
  if (!renameValue.value.trim()) {
    ElMessage.warning('请输入新名称')
    return
  }
  try {
    await updateTaskModule(currentModuleId.value, { name: renameValue.value.trim() })
    ElMessage.success('重命名成功')
    showRenameModule.value = false
    await loadModules()
  } catch (e) {
    ElMessage.error('重命名失败')
  }
}

onMounted(async () => {
  try {
    await checkPostpone()
  } catch (e) { /* 忽略 */ }
  await loadModules()
})
</script>

<style scoped>
.requirement-summary {
  height: 100%;
  max-width: 1200px;
}
.page-header {
  display: flex;
  align-items: flex-end;
  justify-content: space-between;
  margin-bottom: 24px;
}
.page-header-left {
  display: flex;
  align-items: baseline;
  gap: 12px;
}
.page-title {
  margin: 0;
  font-size: 24px;
  font-weight: 700;
  color: #0F172A;
  letter-spacing: -0.02em;
}
.page-subtitle {
  font-size: 13px;
  color: #94A3B8;
}
.page-header-right {
  display: flex;
  gap: 8px;
}
.module-bar {
  margin-bottom: 28px;
}
.module-tabs {
  display: flex;
  align-items: center;
  gap: 6px;
  flex-wrap: wrap;
}
.module-tab {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 6px 14px;
  border-radius: 8px;
  background: #FFFFFF;
  border: 1px solid #E2E8F0;
  cursor: pointer;
  transition: all 0.2s ease;
  font-size: 13px;
  color: #475569;
}
.module-tab:hover {
  border-color: #2563EB;
  color: #2563EB;
}
.module-tab.active {
  background: #2563EB;
  border-color: #2563EB;
  color: #FFFFFF;
}
.module-tab.active .module-tab-close {
  color: rgba(255,255,255,0.7);
}
.module-tab-close {
  font-size: 12px;
  color: #CBD5E1;
  transition: color 0.15s;
  cursor: pointer;
}
.module-tab-close:hover {
  color: #EF4444;
}
.task-content {
  display: flex;
  flex-direction: column;
  gap: 24px;
}
.task-section {
  background: #FFFFFF;
  border-radius: 12px;
  border: 1px solid #E2E8F0;
  padding: 20px 24px;
  transition: min-height 0.3s ease, box-shadow 0.2s ease;
}
.task-section:hover {
  box-shadow: 0 1px 3px rgba(0,0,0,0.04);
}
.section-header {
  margin-bottom: 16px;
}
.section-title-group {
  display: flex;
  align-items: center;
  gap: 10px;
}
.section-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  flex-shrink: 0;
}
.today-dot {
  background: #2563EB;
}
.todo-dot {
  background: #F59E0B;
}
.section-title {
  margin: 0;
  font-size: 15px;
  font-weight: 600;
  color: #0F172A;
}
.section-count {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  min-width: 20px;
  height: 20px;
  padding: 0 6px;
  border-radius: 10px;
  background: #F1F5F9;
  font-size: 11px;
  font-weight: 600;
  color: #64748B;
}
.empty-area {
  position: relative;
  display: flex;
  align-items: center;
  justify-content: center;
  min-height: 400px;
  overflow: hidden;
  background: #FFFFFF;
  border-radius: 12px;
  border: 1px solid #E2E8F0;
}
.empty-bg {
  position: absolute;
  inset: 0;
  background: linear-gradient(
    135deg,
    rgba(37, 99, 235, 0.03) 0%,
    rgba(37, 99, 235, 0.01) 25%,
    rgba(5, 150, 105, 0.03) 50%,
    rgba(37, 99, 235, 0.01) 75%,
    rgba(37, 99, 235, 0.03) 100%
  );
  background-size: 400% 400%;
  animation: gradientShift 8s ease infinite;
}
@keyframes gradientShift {
  0% { background-position: 0% 50%; }
  50% { background-position: 100% 50%; }
  100% { background-position: 0% 50%; }
}
</style>
