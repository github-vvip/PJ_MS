<template>
  <div class="project-page">
    <div class="page-header">
      <h1 class="page-title">项目配置表</h1>
    </div>

    <div class="filter-card">
      <div class="search-bar">
        <div class="search-input-box">
          <el-icon class="search-icon"><Search /></el-icon>
          <input
            v-model="searchText"
            type="text"
            placeholder="搜索项目名称 / 厂商 / 型号"
            class="search-input"
            @keyup.enter="loadProjects"
          />
          <span v-if="searchText" class="search-clear" @click="clearSearch">×</span>
        </div>
        <button class="search-btn" @click="loadProjects">搜索</button>
      </div>
      <div class="filter-row">
        <el-select v-model="filterHardware" placeholder="硬件版型" clearable multiple collapse-tags class="filter-select" size="small" @change="loadProjects">
          <el-option v-for="v in filterOptions.hardware_versions" :key="v" :label="v" :value="v" />
        </el-select>
        <el-select v-model="filterAndroid" placeholder="Android版本" clearable multiple collapse-tags class="filter-select" size="small" @change="loadProjects">
          <el-option v-for="v in filterOptions.android_versions" :key="v" :label="v" :value="v" />
        </el-select>
        <el-select v-model="filterWifi" placeholder="WiFi" clearable class="filter-select filter-select-wifi" size="small" @change="loadProjects">
          <el-option label="2.4G" value="2.4G" />
          <el-option label="5G" value="5G" />
        </el-select>
        <button class="reset-btn" @click="resetFilters">
          <el-icon class="reset-icon"><RefreshLeft /></el-icon>
          <span>重置</span>
        </button>
      </div>
    </div>

    <div class="customer-cards-wrapper">
      <div class="customer-cards" ref="tabsRef" @wheel.prevent="onTabsWheel">
        <div
          v-for="(c, idx) in customers"
          :key="c.id"
          class="customer-card"
          :class="{ active: currentCustomerId === c.id }"
          @click="selectCustomer(c.id)"
          @contextmenu.prevent="showContextMenu($event, c)"
        >
          <div class="card-icon" :style="{ background: cardColors[idx % cardColors.length] }">
            <span v-if="editingCustomerId !== c.id">{{ c.name.charAt(0) }}</span>
            <input
              v-else
              class="card-edit-input"
              v-model="editingCustomerName"
              @blur="confirmEditCustomer"
              @keyup.enter="confirmEditCustomer"
              @keyup.escape="cancelEditCustomer"
              ref="editInputRef"
            />
          </div>
          <div class="card-info">
            <span class="card-label" v-if="editingCustomerId !== c.id">{{ c.name }}</span>
            <span class="card-number">{{ c.project_count }}</span>
          </div>
        </div>
        <div class="customer-card card-add" @click="handleAddCustomer">
          <div class="card-icon card-icon-add">
            <el-icon :size="20"><Plus /></el-icon>
          </div>
          <div class="card-info">
            <span class="card-number">+</span>
            <span class="card-label">新增客户</span>
          </div>
        </div>
      </div>
    </div>

    <div class="table-section">
      <div class="table-toolbar">
        <span class="table-customer-label">{{ currentCustomerName || '全部项目' }}</span>
        <div class="table-actions">
          <el-button v-if="currentCustomerId" type="primary" :icon="Plus" size="small" @click="handleAddProject">新建项目</el-button>
          <el-button :icon="Download" size="small" @click="handleExport">导出 Excel</el-button>
          <el-button :icon="Setting" size="small" @click="showColumnSettings = true">展示设置</el-button>
        </div>
      </div>

      <div class="table-card">
        <el-table
          :data="pagedData"
          border
          style="width: 100%"
          row-key="id"
          @row-dblclick="handleViewDetail"
          :header-cell-style="{ background: '#F8FAFC', color: '#475569', fontWeight: 600, fontSize: '13px' }"
          :cell-style="{ fontSize: '13px', color: '#334155' }"
        >
          <el-table-column type="expand">
            <template #default="{ row }">
              <div class="expand-content">
                <el-descriptions :column="3" border size="small">
                  <el-descriptions-item label="客户">{{ row.customer_name || '-' }}</el-descriptions-item>
                  <el-descriptions-item label="Launcher">{{ row.launcher || '-' }}</el-descriptions-item>
                  <el-descriptions-item label="PIR">
                    <el-tag :type="row.pir ? 'success' : 'info'" size="small" effect="plain">{{ row.pir ? '有' : '无' }}</el-tag>
                  </el-descriptions-item>
                  <el-descriptions-item label="LED">
                    <el-tag :type="row.led ? 'success' : 'info'" size="small" effect="plain">{{ row.led ? '有' : '无' }}</el-tag>
                  </el-descriptions-item>
                  <el-descriptions-item label="光感">{{ row.light_sensor }}</el-descriptions-item>
                  <el-descriptions-item label="WiFi">{{ row.wifi }}</el-descriptions-item>
                  <el-descriptions-item label="屏幕尺寸">{{ row.screen_size || '-' }}</el-descriptions-item>
                  <el-descriptions-item label="屏幕型号">{{ row.screen_model || '-' }}</el-descriptions-item>
                  <el-descriptions-item label="TP">{{ row.tp || '-' }}</el-descriptions-item>
                  <el-descriptions-item label="壳">{{ row.shell || '-' }}</el-descriptions-item>
                  <el-descriptions-item label="备注" :span="3">{{ row.remarks || '-' }}</el-descriptions-item>
                </el-descriptions>
              </div>
            </template>
          </el-table-column>
          <el-table-column v-if="visibleColumns.serial_number" prop="serial_number" label="序号" width="70" align="center" />
          <el-table-column v-if="!currentCustomerId && visibleColumns.customer_name" prop="customer_name" label="客户" width="100" align="center" show-overflow-tooltip />
          <el-table-column v-if="visibleColumns.project_name" prop="project_name" label="项目名称" min-width="120" align="center" show-overflow-tooltip />
          <el-table-column v-if="visibleColumns.hardware_version" prop="hardware_version" label="硬件版型" width="110" align="center" show-overflow-tooltip />
          <el-table-column v-if="visibleColumns.brand" prop="brand" label="厂商" width="90" align="center" show-overflow-tooltip />
          <el-table-column v-if="visibleColumns.model" prop="model" label="型号" width="90" align="center" show-overflow-tooltip />
          <el-table-column v-if="visibleColumns.android_version" prop="android_version" label="Android版本" width="110" align="center" show-overflow-tooltip />
          <el-table-column v-if="visibleColumns.launcher" prop="launcher" label="Launcher" width="100" align="center" show-overflow-tooltip />
          <el-table-column v-if="visibleColumns.pir" prop="pir" label="PIR" width="70" align="center">
            <template #default="{ row }">
              <el-tag :type="row.pir ? 'success' : 'info'" size="small" effect="plain">{{ row.pir ? '有' : '无' }}</el-tag>
            </template>
          </el-table-column>
          <el-table-column v-if="visibleColumns.led" prop="led" label="LED" width="70" align="center">
            <template #default="{ row }">
              <el-tag :type="row.led ? 'success' : 'info'" size="small" effect="plain">{{ row.led ? '有' : '无' }}</el-tag>
            </template>
          </el-table-column>
          <el-table-column v-if="visibleColumns.light_sensor" prop="light_sensor" label="光感" width="80" align="center" />
          <el-table-column v-if="visibleColumns.wifi" prop="wifi" label="WiFi" width="80" align="center" />
          <el-table-column v-if="visibleColumns.screen_size" prop="screen_size" label="屏幕尺寸" width="100" align="center" show-overflow-tooltip />
          <el-table-column v-if="visibleColumns.screen_model" prop="screen_model" label="屏幕型号" width="120" align="center" show-overflow-tooltip />
          <el-table-column v-if="visibleColumns.tp" prop="tp" label="TP" width="100" align="center" show-overflow-tooltip />
          <el-table-column v-if="visibleColumns.shell" prop="shell" label="壳" width="100" align="center" show-overflow-tooltip />
          <el-table-column v-if="visibleColumns.project_establish_date" prop="project_establish_date" label="立项时间" width="110" align="center">
            <template #default="{ row }">{{ row.project_establish_date || '-' }}</template>
          </el-table-column>
          <el-table-column v-if="visibleColumns.remarks" prop="remarks" label="备注" min-width="120" align="center" show-overflow-tooltip />
          <el-table-column label="操作" width="150" fixed="right" align="center">
            <template #default="{ row }">
              <el-button size="small" type="primary" link @click="handleViewDetail(row)">详情</el-button>
              <el-button size="small" type="primary" link @click="handleEdit(row)">编辑</el-button>
              <el-button size="small" type="danger" link @click="handleDelete(row)">删除</el-button>
            </template>
          </el-table-column>
        </el-table>
        <div class="pagination-area">
          <el-pagination
            v-model:current-page="currentPage"
            v-model:page-size="pageSize"
            :page-sizes="[10, 15, 20, 50]"
            :total="projectList.length"
            layout="total, sizes, prev, pager, next, jumper"
            background
            small
          />
        </div>
      </div>
    </div>

    <ProjectForm
      v-if="showForm"
      :visible="showForm"
      :edit-data="editData"
      :customer-id="currentCustomerId"
      @close="showForm = false"
      @saved="onFormSaved"
    />

    <ProjectDetail
      v-if="showDetail"
      :visible="showDetail"
      :detail-data="detailData"
      @close="showDetail = false"
    />

    <el-dialog v-model="showAddCustomerDialog" title="新增客户" width="400px" @close="newCustomerName = ''">
      <el-form @submit.prevent="confirmAddCustomer">
        <el-form-item label="客户名称">
          <el-input v-model="newCustomerName" placeholder="请输入客户名称" @keyup.enter="confirmAddCustomer" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="showAddCustomerDialog = false">取消</el-button>
        <el-button type="primary" @click="confirmAddCustomer">确定</el-button>
      </template>
    </el-dialog>

    <el-dialog v-model="showColumnSettings" title="展示设置" width="480px">
      <div class="column-settings-body">
        <div class="column-settings-tip">点击字段可切换显示/隐藏</div>
        <div class="column-settings-grid">
          <div
            v-for="col in allColumns"
            :key="col.key"
            class="column-chip"
            :class="{ active: visibleColumns[col.key] }"
            @click="toggleColumn(col.key)"
          >
            <el-icon v-if="visibleColumns[col.key]" class="chip-check"><Check /></el-icon>
            <span>{{ col.label }}</span>
          </div>
        </div>
      </div>
      <template #footer>
        <el-button @click="resetColumnSettings">恢复默认</el-button>
        <el-button type="primary" @click="showColumnSettings = false">确定</el-button>
      </template>
    </el-dialog>

    <div v-if="contextMenuVisible" class="context-menu" :style="{ left: contextMenuX + 'px', top: contextMenuY + 'px' }">
      <div class="context-menu-item" @click="handleEditCustomerFromMenu">重命名</div>
      <div class="context-menu-item danger" @click="handleDeleteCustomer">删除</div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted, nextTick, onBeforeUnmount, watch } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus, Download, Search, Setting, Check, RefreshLeft } from '@element-plus/icons-vue'
import {
  getCustomers, createCustomer, updateCustomer, deleteCustomer,
  getProjects, deleteProject, getProjectFilterOptions
} from '../api/api.js'
import ProjectForm from './ProjectForm.vue'
import ProjectDetail from './ProjectDetail.vue'
import * as XLSX from 'xlsx'

const STORAGE_KEY = 'project_column_settings'

const allColumns = [
  { key: 'serial_number', label: '序号' },
  { key: 'customer_name', label: '客户' },
  { key: 'project_name', label: '项目名称' },
  { key: 'hardware_version', label: '硬件版型' },
  { key: 'brand', label: '厂商' },
  { key: 'model', label: '型号' },
  { key: 'android_version', label: 'Android版本' },
  { key: 'launcher', label: 'Launcher' },
  { key: 'pir', label: 'PIR' },
  { key: 'led', label: 'LED' },
  { key: 'light_sensor', label: '光感' },
  { key: 'wifi', label: 'WiFi' },
  { key: 'screen_size', label: '屏幕尺寸' },
  { key: 'screen_model', label: '屏幕型号' },
  { key: 'tp', label: 'TP' },
  { key: 'shell', label: '壳' },
  { key: 'project_establish_date', label: '立项时间' },
  { key: 'remarks', label: '备注' },
]

const defaultVisible = {
  customer_name: false,
  serial_number: true,
  project_name: true,
  hardware_version: true,
  brand: false,
  model: false,
  android_version: true,
  launcher: false,
  pir: false,
  led: false,
  light_sensor: false,
  wifi: false,
  screen_size: true,
  screen_model: true,
  tp: true,
  shell: false,
  project_establish_date: false,
  remarks: false,
}

const loadColumnSettings = () => {
  try {
    const saved = localStorage.getItem(STORAGE_KEY)
    if (saved) return JSON.parse(saved)
  } catch (e) { /* 忽略 */ }
  return { ...defaultVisible }
}

const visibleColumns = reactive(loadColumnSettings())
const showColumnSettings = ref(false)

watch(visibleColumns, (val) => {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(val))
}, { deep: true })

const toggleColumn = (key) => {
  visibleColumns[key] = !visibleColumns[key]
}

const resetColumnSettings = () => {
  Object.assign(visibleColumns, defaultVisible)
}

const customers = ref([])
const currentCustomerId = ref(null)
const projectList = ref([])
const filterOptions = ref({ hardware_versions: [], android_versions: [], brands: [] })
const searchText = ref('')
const filterHardware = ref([])
const filterAndroid = ref([])
const filterWifi = ref('')
const currentPage = ref(1)
const pageSize = ref(15)
const showForm = ref(false)
const editData = ref(null)
const showDetail = ref(false)
const detailData = ref(null)

const showAddCustomerDialog = ref(false)
const newCustomerName = ref('')
const editingCustomerId = ref(null)
const editingCustomerName = ref('')
const editInputRef = ref(null)
const tabsRef = ref(null)

const contextMenuVisible = ref(false)
const contextMenuX = ref(0)
const contextMenuY = ref(0)
const contextMenuCustomer = ref(null)

const cardColors = [
  'linear-gradient(135deg, #667eea, #764ba2)',
  'linear-gradient(135deg, #f093fb, #f5576c)',
  'linear-gradient(135deg, #4facfe, #00f2fe)',
  'linear-gradient(135deg, #43e97b, #38f9d7)',
  'linear-gradient(135deg, #fa709a, #fee140)',
  'linear-gradient(135deg, #a18cd1, #fbc2eb)',
  'linear-gradient(135deg, #fccb90, #d57eeb)',
  'linear-gradient(135deg, #e0c3fc, #8ec5fc)',
]

const currentCustomerName = computed(() => {
  const c = customers.value.find(c => c.id === currentCustomerId.value)
  return c ? c.name : ''
})

const pagedData = computed(() => {
  const start = (currentPage.value - 1) * pageSize.value
  return projectList.value.slice(start, start + pageSize.value)
})

const onTabsWheel = (e) => {
  if (!tabsRef.value) return
  tabsRef.value.scrollLeft += e.deltaY > 0 ? 120 : -120
}

const clearSearch = () => {
  searchText.value = ''
}

const loadCustomers = async () => {
  try {
    customers.value = await getCustomers()
  } catch (e) {
    ElMessage.error('加载客户列表失败')
  }
}

const selectCustomer = (id) => {
  if (editingCustomerId.value) return
  if (currentCustomerId.value === id) {
    currentCustomerId.value = null
  } else {
    currentCustomerId.value = id
  }
  currentPage.value = 1
  loadProjects()
  loadFilterOptions()
}

const loadProjects = async () => {
  try {
    const params = {}
    if (currentCustomerId.value) params.customer = currentCustomerId.value
    if (searchText.value) params.search = searchText.value
    if (filterHardware.value.length > 0) params.hardware_version = filterHardware.value.join(',')
    if (filterAndroid.value.length > 0) params.android_version = filterAndroid.value.join(',')
    if (filterWifi.value) params.wifi = filterWifi.value
    projectList.value = await getProjects(params)
  } catch (e) {
    ElMessage.error('加载项目列表失败')
  }
}

const loadFilterOptions = async () => {
  try {
    const params = {}
    if (currentCustomerId.value) params.customer = currentCustomerId.value
    filterOptions.value = await getProjectFilterOptions(params)
  } catch (e) { /* 忽略 */ }
}

const resetFilters = () => {
  searchText.value = ''
  filterHardware.value = []
  filterAndroid.value = []
  filterWifi.value = ''
  currentCustomerId.value = null
  currentPage.value = 1
  loadProjects()
  loadFilterOptions()
}

const handleAddCustomer = () => {
  showAddCustomerDialog.value = true
}

const confirmAddCustomer = async () => {
  if (!newCustomerName.value.trim()) {
    ElMessage.warning('请输入客户名称')
    return
  }
  try {
    await createCustomer({ name: newCustomerName.value.trim() })
    ElMessage.success('创建成功')
    showAddCustomerDialog.value = false
    newCustomerName.value = ''
    await loadCustomers()
  } catch (e) {
    ElMessage.error('创建失败')
  }
}

const startEditCustomer = (c) => {
  editingCustomerId.value = c.id
  editingCustomerName.value = c.name
  nextTick(() => {
    if (editInputRef.value) {
      const inputs = Array.isArray(editInputRef.value) ? editInputRef.value : [editInputRef.value]
      inputs[0]?.focus()
    }
  })
}

const confirmEditCustomer = async () => {
  if (!editingCustomerName.value.trim()) {
    cancelEditCustomer()
    return
  }
  try {
    await updateCustomer(editingCustomerId.value, { name: editingCustomerName.value.trim() })
    ElMessage.success('重命名成功')
    editingCustomerId.value = null
    await loadCustomers()
    await loadProjects()
  } catch (e) {
    ElMessage.error('重命名失败')
  }
}

const cancelEditCustomer = () => {
  editingCustomerId.value = null
}

const showContextMenu = (event, c) => {
  contextMenuCustomer.value = c
  contextMenuX.value = event.clientX
  contextMenuY.value = event.clientY
  contextMenuVisible.value = true
}

const hideContextMenu = () => {
  contextMenuVisible.value = false
  contextMenuCustomer.value = null
}

const handleEditCustomerFromMenu = () => {
  if (contextMenuCustomer.value) {
    startEditCustomer(contextMenuCustomer.value)
  }
  hideContextMenu()
}

const handleDeleteCustomer = async () => {
  const c = contextMenuCustomer.value
  hideContextMenu()
  if (!c) return
  try {
    await ElMessageBox.confirm(
      `确定删除客户"${c.name}"？该客户下所有项目将一并删除。`,
      '删除确认',
      { type: 'warning' }
    )
    await deleteCustomer(c.id)
    ElMessage.success('删除成功')
    if (currentCustomerId.value === c.id) {
      currentCustomerId.value = null
    }
    await loadCustomers()
    await loadProjects()
    await loadFilterOptions()
  } catch (e) {
    if (e !== 'cancel') ElMessage.error('删除失败')
  }
}

const handleAddProject = () => {
  editData.value = null
  showForm.value = true
}

const handleEdit = (row) => {
  editData.value = { ...row }
  showForm.value = true
}

const handleDelete = async (row) => {
  try {
    await ElMessageBox.confirm(
      `确定删除项目"${row.project_name}"（序号${row.serial_number}）？删除后序号将自动重新编号。`,
      '删除确认',
      { type: 'warning' }
    )
    await deleteProject(row.id)
    ElMessage.success('删除成功')
    await loadProjects()
    await loadFilterOptions()
    await loadCustomers()
  } catch (e) {
    if (e !== 'cancel') ElMessage.error('删除失败')
  }
}

const handleViewDetail = (row) => {
  detailData.value = row
  showDetail.value = true
}

const onFormSaved = async () => {
  showForm.value = false
  await loadProjects()
  await loadFilterOptions()
  await loadCustomers()
}

const handleExport = () => {
  if (projectList.value.length === 0) {
    ElMessage.warning('暂无数据可导出')
    return
  }
  const headers = [
    '客户', '序号', '硬件版型', '项目名称', 'Android版本', '厂商', '型号',
    'Launcher', 'PIR', 'LED', '光感', 'WiFi',
    '屏幕尺寸', '屏幕型号', 'TP', '壳', '立项时间', '备注'
  ]
  const data = projectList.value.map(p => [
    p.customer_name, p.serial_number, p.hardware_version, p.project_name, p.android_version,
    p.brand, p.model, p.launcher, p.pir ? '有' : '无', p.led ? '有' : '无',
    p.light_sensor, p.wifi,
    p.screen_size, p.screen_model, p.tp, p.shell, p.project_establish_date, p.remarks
  ])
  const ws = XLSX.utils.aoa_to_sheet([headers, ...data])
  const wb = XLSX.utils.book_new()
  XLSX.utils.book_append_sheet(wb, ws, '项目配置表')
  const fileName = currentCustomerName.value
    ? `${currentCustomerName.value}_项目配置表`
    : `全部项目配置表`
  XLSX.writeFile(wb, `${fileName}_${new Date().toISOString().slice(0, 10)}.xlsx`)
  ElMessage.success('导出成功')
}

onMounted(async () => {
  await loadCustomers()
  await loadProjects()
  await loadFilterOptions()
  document.addEventListener('click', hideContextMenu)
})

onBeforeUnmount(() => {
  document.removeEventListener('click', hideContextMenu)
})
</script>

<style scoped>
.project-page {
  height: 100%;
  max-width: 1400px;
}
.page-header {
  margin-bottom: 20px;
}
.page-title {
  margin: 0;
  font-size: 24px;
  font-weight: 700;
  color: #0F172A;
  letter-spacing: -0.02em;
}
.filter-card {
  padding: 24px;
  margin-bottom: 12px;
}

.search-bar {
  display: flex;
  align-items: center;
}

.search-input-box {
  position: relative;
  width: 85%;
  display: flex;
  align-items: center;
}

.search-icon {
  position: absolute;
  left: 12px;
  width: 14px;
  height: 14px;
  color: #666;
  z-index: 1;
}

.search-input {
  width: 100%;
  height: 40px;
  padding: 0 32px 0 38px;
  border: 2px solid #C4C7CE;
  border-right: none;
  border-radius: 10px 0 0 10px;
  font-size: 14px;
  color: #333;
  background: #FFFFFF;
  transition: border-color 0.2s ease;
  outline: none;
}

.search-input::placeholder {
  color: #999;
}

.search-input:hover {
  border-color: #9195A3;
}

.search-input:focus {
  border-color: #3385FF;
}

.search-clear {
  position: absolute;
  right: 8px;
  width: 20px;
  height: 20px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 16px;
  color: #999;
  cursor: pointer;
  border-radius: 50%;
  transition: background 0.15s;
}

.search-clear:hover {
  background: #F5F5F5;
  color: #666;
}

.search-btn {
  width: 15%;
  height: 40px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg, #3385FF 0%, #2A75FF 100%);
  color: #FFFFFF;
  border: none;
  border-radius: 0 10px 10px 0;
  font-size: 16px;
  font-weight: 700;
  font-family: "Source Han Sans", "Noto Sans SC", "Microsoft YaHei", sans-serif;
  cursor: pointer;
  transition: all 0.2s ease;
  letter-spacing: 2px;
}

.search-btn:hover {
  transform: scale(1.02);
  box-shadow: 0 4px 12px rgba(51, 133, 255, 0.4);
}

.search-btn:active {
  transform: scale(0.98);
}

.filter-row {
  display: flex;
  align-items: center;
  gap: 4px;
  margin-top: 8px;
  justify-content: flex-end;
}

.filter-select {
  width: 100px;
}

.filter-select-wifi {
  width: 80px;
}

.filter-select :deep(.el-input__wrapper) {
  border-radius: 4px;
  border: 1px solid #E0E0E0;
  box-shadow: none !important;
  height: 28px;
}

.filter-select :deep(.el-input__wrapper:hover) {
  border-color: #3385FF;
}

.filter-select :deep(.el-input__wrapper.is-focus) {
  border-color: #3385FF;
  box-shadow: 0 0 0 1px #3385FF inset !important;
}

.filter-select :deep(.el-input__inner) {
  font-size: 12px;
  height: 26px;
  line-height: 26px;
}

.filter-select :deep(.el-select__tags) {
  max-height: 24px;
}

.filter-select :deep(.el-tag) {
  max-height: 18px;
  font-size: 11px;
}

.filter-select :deep(.el-select__placeholder) {
  font-size: 12px;
}

.filter-select :deep(.el-input__suffix) {
  font-size: 12px;
}

.filter-select :deep(.el-select__icon) {
  font-size: 12px;
  width: 14px;
}

.reset-btn {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 2px;
  width: 60px;
  height: 28px;
  background: #F5F5F5;
  color: #FF4D4F;
  border: 1px solid #E0E0E0;
  border-radius: 4px;
  font-size: 12px;
  cursor: pointer;
  transition: all 0.15s ease;
}

.reset-btn:hover {
  background: #FFF1F0;
  border-color: #FFCCC7;
}

.reset-icon {
  font-size: 12px;
}
.customer-cards-wrapper {
  margin-bottom: 20px;
  background: linear-gradient(135deg, #e0f2fe 0%, #dbeafe 50%, #e0e7ff 100%);
  border-radius: 12px;
  padding: 16px;
  overflow: hidden;
}
.customer-cards {
  display: flex;
  gap: 12px;
  overflow-x: auto;
  padding-bottom: 4px;
  scrollbar-width: none;
}
.customer-cards::-webkit-scrollbar {
  display: none;
}
.customer-card {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 14px 18px;
  background: #FFFFFF;
  border-radius: 12px;
  cursor: pointer;
  transition: all 0.2s ease;
  flex-shrink: 0;
  min-width: 160px;
  box-shadow: 0 1px 3px rgba(0,0,0,0.06);
  border: 2px solid transparent;
  user-select: none;
}
.customer-card:hover {
  box-shadow: 0 4px 12px rgba(0,0,0,0.1);
  transform: translateY(-1px);
}
.customer-card.active {
  border-color: #2563EB;
  box-shadow: 0 4px 16px rgba(37,99,235,0.2);
}
.card-icon {
  width: 42px;
  height: 42px;
  border-radius: 10px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #FFFFFF;
  font-size: 18px;
  font-weight: 700;
  flex-shrink: 0;
}
.card-icon-add {
  background: linear-gradient(135deg, #94a3b8, #64748b) !important;
}
.card-edit-input {
  border: none;
  outline: none;
  background: transparent;
  color: #FFFFFF;
  font-size: 16px;
  font-weight: 700;
  width: 24px;
  text-align: center;
}
.card-info {
  display: flex;
  flex-direction: column;
  gap: 2px;
  min-width: 0;
}
.card-label {
  font-size: 20px;
  font-weight: 700;
  color: #0F172A;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  line-height: 1.2;
}
.card-number {
  font-size: 12px;
  color: #94A3B8;
}
.card-add {
  border: 2px dashed #CBD5E1;
  background: rgba(255,255,255,0.6);
}
.card-add:hover {
  border-color: #2563EB;
  background: rgba(255,255,255,0.9);
}
.table-section {
  flex: 1;
}
.table-toolbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 12px;
}
.table-customer-label {
  font-size: 15px;
  font-weight: 600;
  color: #0F172A;
}
.table-actions {
  display: flex;
  gap: 8px;
}
.table-card {
  background: #FFFFFF;
  border-radius: 12px;
  border: 1px solid #E2E8F0;
  padding: 20px;
}
.pagination-area {
  margin-top: 16px;
  display: flex;
  justify-content: flex-end;
}
.expand-content {
  padding: 12px 20px;
}
.column-settings-body {
  padding: 4px 0;
}
.column-settings-tip {
  font-size: 12px;
  color: #94A3B8;
  margin-bottom: 16px;
}
.column-settings-grid {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
}
.column-chip {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  padding: 6px 14px;
  border-radius: 8px;
  border: 1px solid #E2E8F0;
  background: #F8FAFC;
  cursor: pointer;
  transition: all 0.15s ease;
  font-size: 13px;
  color: #64748B;
  user-select: none;
}
.column-chip:hover {
  border-color: #93C5FD;
  background: #EFF6FF;
}
.column-chip.active {
  background: #2563EB;
  border-color: #2563EB;
  color: #FFFFFF;
}
.chip-check {
  font-size: 12px;
}
.context-menu {
  position: fixed;
  background: #FFFFFF;
  border: 1px solid #E2E8F0;
  border-radius: 8px;
  box-shadow: 0 4px 12px rgba(0,0,0,0.1);
  padding: 4px;
  z-index: 9999;
}
.context-menu-item {
  padding: 8px 16px;
  font-size: 13px;
  color: #334155;
  cursor: pointer;
  border-radius: 4px;
  transition: background 0.1s;
}
.context-menu-item:hover {
  background: #F8FAFC;
}
.context-menu-item.danger {
  color: #EF4444;
}
.context-menu-item.danger:hover {
  background: #FEF2F2;
}
</style>
