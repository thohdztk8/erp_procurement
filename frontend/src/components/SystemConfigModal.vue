<script setup>
import { onMounted, ref } from 'vue'
import { mdiClose } from '@mdi/js'
import BaseButton from '@/components/BaseButton.vue'
import { financeService } from '@/services/api'

const emit = defineEmits(['close'])

const configs = ref([])
const isLoading = ref(false)

const fetchConfigs = async () => {
  isLoading.value = true
  try {
    const res = await financeService.getConfigs()
    configs.value = res.results || []
  } catch (error) {
    console.error(error)
  } finally {
    isLoading.value = false
  }
}

onMounted(() => {
  fetchConfigs()
})

const updateConfigVal = async (key) => {
  const newVal = prompt(`Nhập giá trị mới cho cấu hình ${key}:`)
  if (newVal === null) return
  try {
    await financeService.updateConfig(key, { config_value_json: newVal })
    alert('Cập nhật cấu hình hệ thống thành công!')
    fetchConfigs()
  } catch (e) {
    alert('Cập nhật thất bại.')
  }
}
</script>

<template>
  <div class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
    <div class="bg-white dark:bg-gray-900 rounded-lg shadow-xl max-w-xl w-full">
      <div class="flex justify-between items-center px-6 py-4 border-b">
        <h3 class="text-lg font-bold">Cấu Hình Hệ Thống</h3>
        <BaseButton :icon="mdiClose" color="whiteDark" small @click="emit('close')" />
      </div>
      <div class="p-6 space-y-4 max-h-[60vh] overflow-y-auto">
        <div v-if="isLoading" class="text-center py-6 text-sm text-gray-400">Đang tải cấu hình...</div>
        <table v-else class="w-full text-xs text-left">
          <thead>
            <tr class="bg-gray-100 dark:bg-gray-800">
              <th class="p-2 border-b">Tham số cấu hình</th>
              <th class="p-2 border-b">Giá trị hiện tại</th>
              <th class="p-2 border-b text-right">Thao tác</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="cfg in configs" :key="cfg.config_key" class="border-b">
              <td class="p-2 font-semibold">{{ cfg.config_key }}</td>
              <td class="p-2 truncate max-w-xs">{{ JSON.stringify(cfg.config_value_json) }}</td>
              <td class="p-2 text-right">
                <BaseButton color="info" label="Cập nhật" small @click="updateConfigVal(cfg.config_key)" />
              </td>
            </tr>
            <tr v-if="configs.length === 0">
              <td colspan="3" class="text-center py-6 text-gray-400">Không tìm thấy tham số cấu hình nào.</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>
