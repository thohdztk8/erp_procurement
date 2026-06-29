<script setup>
import { ref, onMounted, reactive } from 'vue'
import { mdiClose } from '@mdi/js'
import BaseButton from '@/components/BaseButton.vue'
import BaseButtons from '@/components/BaseButtons.vue'
import FormField from '@/components/FormField.vue'
import FormControl from '@/components/FormControl.vue'
import { ipoService, warehouseService } from '@/services/api'
import api from '@/services/client'

const emit = defineEmits(['close', 'saved'])

const approvedIpos = ref([])
const selectedIpoId = ref(null)
const selectedIpo = ref(null)
const notes = ref('')
const isSubmitting = ref(false)

const formItems = ref([])

const fetchApprovedIpos = async () => {
  try {
    const res = await ipoService.getIPOs()
    approvedIpos.value = (res.data.items || []).filter(i => i.ipo_status === 'APPROVED')
  } catch (error) {
    console.error(error)
  }
}

const branches = ref([])
const selectedBranchId = ref(null)

const fetchBranches = async () => {
  try {
    const res = await api.get('/auth/branches')
    branches.value = res.data || []
  } catch (error) {
    console.error(error)
  }
}

onMounted(() => {
  fetchApprovedIpos()
  fetchBranches()
})

const handleIpoChange = async () => {
  if (!selectedIpoId.value) {
    selectedIpo.value = null
    formItems.value = []
    return
  }
  try {
    const res = await ipoService.getIPODetail(selectedIpoId.value)
    selectedIpo.value = res.data?.ipo || res.data || null
    
    if (selectedIpo.value) {
      formItems.value = selectedIpo.value.items.map(it => ({
        ipo_item_id: it.ipo_item_id,
        material_id: it.order_item?.material_id || it.material_id,
        material_name_other: it.order_item?.material_name_other || it.material_name_other,
        material_name: it.material_name || it.material?.material_name || it.order_item?.material?.material_name || 'Khác',
        qty_max: parseFloat(it.qty_final),
        qty_received: parseFloat(it.qty_final),
        qty_passed: parseFloat(it.qty_final),
        qty_failed: 0,
        photo_paths: []
      }))
    }
  } catch (error) {
    console.error(error)
  }
}

const handleQtyChange = (item, field) => {
  const qty_received = Math.floor(parseFloat(item.qty_received) || 0)
  const qty_passed = Math.floor(parseFloat(item.qty_passed) || 0)
  const qty_failed = Math.floor(parseFloat(item.qty_failed) || 0)

  item.qty_received = qty_received

  if (field === 'received') {
    let new_passed = qty_received - qty_failed
    if (new_passed < 0) {
      new_passed = 0
      item.qty_failed = qty_received
    }
    item.qty_passed = new_passed
  } else if (field === 'passed') {
    let new_failed = qty_received - qty_passed
    if (new_failed < 0) {
      new_failed = 0
      item.qty_passed = qty_received
    }
    item.qty_failed = new_failed
  } else if (field === 'failed') {
    let new_passed = qty_received - qty_failed
    if (new_passed < 0) {
      new_passed = 0
      item.qty_failed = qty_received
    }
    item.qty_passed = new_passed
  }
}

const handleSubmit = async () => {
  if (formItems.value.length === 0) return
  isSubmitting.value = true
  
  try {
    const payload = {
      ipo_id: selectedIpoId.value,
      branch_id: selectedBranchId.value,
      notes: notes.value,
      items: formItems.value.map(it => ({
        material_id: it.material_id || null,
        material_name_other: it.material_name_other || '',
        qty_ordered: it.qty_max,
        qty_received: it.qty_received,
        qty_passed: it.qty_passed,
        qty_failed: it.qty_failed,
        photo_paths: it.photo_paths
      }))
    }
    
    await warehouseService.createReceipt(payload)
    alert('Tạo phiếu nhập kho (GRN) thành công!')
    emit('saved')
    emit('close')
  } catch (error) {
    alert('Nhập kho thất bại. ' + (error.response?.data?.detail || ''))
  } finally {
    isSubmitting.value = false
  }
}
</script>

<template>
  <div class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4 overflow-y-auto">
    <div class="bg-white dark:bg-gray-900 rounded-lg shadow-xl max-w-4xl w-full max-h-[85vh] overflow-y-auto">
      <!-- Header -->
      <div class="flex justify-between items-center px-6 py-4 border-b border-gray-200 dark:border-gray-800">
        <h3 class="text-xl font-bold text-gray-800 dark:text-white">Lập Phiếu Nhập Kho (GRN)</h3>
        <BaseButton :icon="mdiClose" color="whiteDark" small @click="emit('close')" />
      </div>

      <!-- Body -->
      <div class="p-6 space-y-6 text-sm">
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <FormField label="Chọn Hợp đồng (IPO) đã duyệt">
            <FormControl 
              v-model="selectedIpoId" 
              type="select" 
              :options="approvedIpos.map(i => ({ id: i.ipo_id, label: `${i.ipo_code} (Trị giá thầu: ${i.total_amount})` }))"
              @change="handleIpoChange"
            />
          </FormField>
          <FormField label="Chọn Chi nhánh nhập kho">
            <FormControl 
              v-model="selectedBranchId" 
              type="select" 
              :options="branches.map(b => ({ id: b.branch_id, label: b.branch_name }))"
            />
          </FormField>
          <FormField label="Ghi chú phiếu nhập">
            <FormControl v-model="notes" placeholder="Nhập ghi chú kho..." />
          </FormField>
        </div>

        <!-- Bảng dòng hàng cần nhập -->
        <div v-if="formItems.length > 0">
          <h4 class="text-sm font-bold text-gray-700 dark:text-gray-300 mb-2">Thông tin nhận hàng từ hợp đồng</h4>
          <table class="w-full text-xs text-left border">
            <thead class="bg-gray-100 dark:bg-gray-800">
              <tr>
                <th class="px-4 py-2 border-b">Tên vật tư</th>
                <th class="px-4 py-2 border-b text-right">Số lượng đặt</th>
                <th class="px-4 py-2 border-b text-right w-28">Số lượng thực nhận</th>
                <th class="px-4 py-2 border-b text-right w-24">Đạt (Passed)</th>
                <th class="px-4 py-2 border-b text-right w-24">Lỗi (Failed)</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="it in formItems" :key="it.ipo_item_id" class="border-b">
                <td class="px-4 py-2 border-r font-medium">{{ it.material_name }}</td>
                <td class="px-4 py-2 text-right border-r font-bold">{{ it.qty_max }}</td>
                <td class="px-4 py-2 text-right border-r">
                  <input type="number" v-model.number="it.qty_received" class="w-full text-right p-1 border rounded" @input="handleQtyChange(it, 'received')" min="0" step="1" />
                </td>
                <td class="px-4 py-2 text-right border-r">
                  <input type="number" v-model.number="it.qty_passed" class="w-full text-right p-1 border rounded" @input="handleQtyChange(it, 'passed')" min="0" step="1" />
                </td>
                <td class="px-4 py-2 text-right">
                  <input type="number" v-model.number="it.qty_failed" class="w-full text-right p-1 border rounded" @input="handleQtyChange(it, 'failed')" min="0" step="1" />
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      <!-- Footer -->
      <div class="flex justify-end px-6 py-4 border-t border-gray-200 dark:border-gray-800">
        <BaseButtons>
          <BaseButton color="white" label="Hủy" @click="emit('close')" />
          <BaseButton color="success" label="Xác nhận Nhập kho" :disabled="isSubmitting || formItems.length === 0 || !selectedBranchId" @click="handleSubmit" />
        </BaseButtons>
      </div>
    </div>
  </div>
</template>
