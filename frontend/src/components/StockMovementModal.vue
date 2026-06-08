<script setup>
import { onMounted, ref } from 'vue'
import { mdiClose } from '@mdi/js'
import BaseButton from '@/components/BaseButton.vue'
import { warehouseService } from '@/services/api'

const props = defineProps({
  material: { type: Object, required: true }
})

const emit = defineEmits(['close'])

const history = ref([])
const isLoading = ref(false)

onMounted(async () => {
  isLoading.value = true
  try {
    const res = await warehouseService.getMovementHistory(props.material.material_id)
    history.value = res.data || []
  } catch (error) {
    console.error(error)
  } finally {
    isLoading.value = false
  }
})
</script>

<template>
  <div class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
    <div class="bg-white dark:bg-gray-900 rounded-lg shadow-xl max-w-2xl w-full">
      <div class="flex justify-between items-center px-6 py-4 border-b">
        <h3 class="text-lg font-bold">Lịch Sử Biến Động: {{ material.material_name }}</h3>
        <BaseButton :icon="mdiClose" color="whiteDark" small @click="emit('close')" />
      </div>
      <div class="p-6 space-y-4 max-h-[60vh] overflow-y-auto">
        <div v-if="isLoading" class="text-center py-6 text-sm text-gray-400">Đang tải lịch sử...</div>
        <div v-else-if="history.length === 0" class="text-center py-6 text-sm text-gray-400">Không có biến động thẻ kho nào gần đây.</div>
        <table v-else class="w-full text-xs text-left">
          <thead>
            <tr class="bg-gray-100 dark:bg-gray-800">
              <th class="p-2 border-b">Thời gian</th>
              <th class="p-2 border-b">Loại giao dịch</th>
              <th class="p-2 border-b text-right">Số lượng biến động</th>
              <th class="p-2 border-b text-right">Tồn khả dụng sau giao dịch</th>
              <th class="p-2 border-b">Ghi chú</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="m in history" :key="m.movement_id" class="border-b">
              <td class="p-2">{{ new Date(m.created_at).toLocaleString('vi-VN') }}</td>
              <td class="p-2 font-semibold text-blue-600">{{ m.transaction_type }}</td>
              <td class="p-2 text-right font-bold" :class="m.qty_change > 0 ? 'text-green-600' : 'text-red-600'">
                {{ m.qty_change > 0 ? '+' : '' }}{{ m.qty_change }}
              </td>
              <td class="p-2 text-right font-bold text-gray-700 dark:text-gray-200">{{ m.new_available_qty }}</td>
              <td class="p-2 text-gray-500 text-[10px]">{{ m.note || '-' }}</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>
