<script setup>
import { ref, reactive } from 'vue'
import { mdiClose, mdiPlus, mdiTrashCan } from '@mdi/js'
import BaseButton from '@/components/BaseButton.vue'
import BaseButtons from '@/components/BaseButtons.vue'
import FormField from '@/components/FormField.vue'
import FormControl from '@/components/FormControl.vue'

const emit = defineEmits(['close', 'save'])

const prForm = reactive({
  priority_level: 'NORMAL',
  urgent_reason: '',
  urgency_impact: '',
  items: []
})

const itemInput = reactive({
  material_name_other: '',
  qty_requested: 1,
  estimated_unit_price: 100000,
  required_deadline: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString().split('T')[0]
})

const addItem = () => {
  if (!itemInput.material_name_other.trim()) {
    alert('Vui lòng điền tên vật tư.')
    return
  }
  prForm.items.push({
    material_name_other: itemInput.material_name_other,
    qty_requested: parseFloat(itemInput.qty_requested),
    estimated_unit_price: parseFloat(itemInput.estimated_unit_price),
    required_deadline: new Date(itemInput.required_deadline).toISOString()
  })
  
  itemInput.material_name_other = ''
  itemInput.qty_requested = 1
}

const removeItem = (idx) => {
  prForm.items.splice(idx, 1)
}

const handleSubmit = () => {
  if (prForm.items.length === 0) {
    alert('Vui lòng thêm ít nhất 1 vật tư vào danh sách yêu cầu.')
    return
  }
  
  if (prForm.priority_level === 'URGENT' && !prForm.urgent_reason.trim()) {
    alert('Vui lòng điền lý do khẩn cấp và mức độ ảnh hưởng.')
    return
  }

  emit('save', { ...prForm })
}

const formatCurrency = (val) => {
  return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(val || 0)
}
</script>

<template>
  <div class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4 overflow-y-auto">
    <div class="bg-white dark:bg-gray-900 rounded-lg shadow-xl max-w-4xl w-full max-h-[90vh] overflow-y-auto">
      <!-- Header -->
      <div class="flex justify-between items-center px-6 py-4 border-b border-gray-200 dark:border-gray-800">
        <h3 class="text-xl font-bold text-gray-800 dark:text-white">Tạo Yêu Cầu Mua Sắm Mới</h3>
        <BaseButton :icon="mdiClose" color="whiteDark" small @click="emit('close')" />
      </div>

      <!-- Body -->
      <div class="p-6 space-y-5">
        <!-- Thông tin chung -->
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <FormField label="Độ ưu tiên">
            <FormControl 
              v-model="prForm.priority_level" 
              type="select" 
              :options="[{ id: 'NORMAL', label: 'Bình thường (NORMAL)' }, { id: 'URGENT', label: 'Khẩn cấp (URGENT)' }]" 
            />
          </FormField>
        </div>

        <div v-if="prForm.priority_level === 'URGENT'" class="grid grid-cols-1 md:grid-cols-2 gap-4 border-l-4 border-red-500 pl-4">
          <FormField label="Lý do khẩn cấp">
            <FormControl v-model="prForm.urgent_reason" placeholder="Ví dụ: Hỏng máy sản xuất chính..." required />
          </FormField>
          <FormField label="Ảnh hưởng nếu chậm trễ">
            <FormControl v-model="prForm.urgency_impact" placeholder="Ví dụ: Đình trệ toàn bộ dây chuyền đóng gói..." required />
          </FormField>
        </div>

        <!-- Khối thêm vật tư -->
        <div class="bg-gray-50 dark:bg-gray-800 p-4 rounded-lg">
          <h4 class="text-sm font-bold text-gray-700 dark:text-gray-300 mb-3">Thêm vật tư vào yêu cầu</h4>
          <div class="grid grid-cols-1 md:grid-cols-4 gap-3 items-end">
            <FormField label="Tên vật tư" class="md:col-span-2">
              <FormControl v-model="itemInput.material_name_other" placeholder="Nhập tên vật tư..." />
            </FormField>
            <FormField label="Số lượng">
              <FormControl v-model="itemInput.qty_requested" type="number" min="0.0001" />
            </FormField>
            <FormField label="Giá dự kiến (VNĐ)">
              <FormControl v-model="itemInput.estimated_unit_price" type="number" min="0" />
            </FormField>
            <FormField label="Hạn cần hàng" class="md:col-span-2">
              <FormControl v-model="itemInput.required_deadline" type="date" />
            </FormField>
            <div class="flex justify-end md:col-span-2">
              <BaseButton color="info" :icon="mdiPlus" label="Thêm vào danh sách" @click="addItem" class="w-full" />
            </div>
          </div>
        </div>

        <!-- Bảng danh sách vật tư đã thêm -->
        <div>
          <h4 class="text-sm font-bold text-gray-700 dark:text-gray-300 mb-2">Vật tư đã chọn</h4>
          <table class="w-full text-xs text-left text-gray-500 dark:text-gray-400 border">
            <thead class="bg-gray-100 dark:bg-gray-800">
              <tr>
                <th class="px-4 py-2 border-b">Tên vật tư</th>
                <th class="px-4 py-2 border-b">Hạn cần</th>
                <th class="px-4 py-2 border-b text-right">Số lượng</th>
                <th class="px-4 py-2 border-b text-right">Giá ước lượng</th>
                <th class="px-4 py-2 border-b text-right">Thành tiền</th>
                <th class="px-4 py-2 border-b text-right">Xóa</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="(it, index) in prForm.items" :key="index" class="border-b">
                <td class="px-4 py-2 border-r">{{ it.material_name_other }}</td>
                <td class="px-4 py-2 border-r">{{ new Date(it.required_deadline).toLocaleDateString('vi-VN') }}</td>
                <td class="px-4 py-2 text-right border-r font-semibold">{{ it.qty_requested }}</td>
                <td class="px-4 py-2 text-right border-r">{{ formatCurrency(it.estimated_unit_price) }}</td>
                <td class="px-4 py-2 text-right border-r font-bold text-gray-800 dark:text-gray-200">
                  {{ formatCurrency(it.qty_requested * it.estimated_unit_price) }}
                </td>
                <td class="px-4 py-2 text-right">
                  <BaseButton color="danger" :icon="mdiTrashCan" small @click="removeItem(index)" />
                </td>
              </tr>
              <tr v-if="prForm.items.length === 0">
                <td colspan="6" class="text-center py-4 text-gray-400">Chưa có vật tư nào được chọn.</td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      <!-- Footer -->
      <div class="flex justify-end px-6 py-4 border-t border-gray-200 dark:border-gray-800">
        <BaseButtons>
          <BaseButton color="white" label="Hủy" @click="emit('close')" />
          <BaseButton color="success" label="Lưu nháp (Tạo PR)" @click="handleSubmit" />
        </BaseButtons>
      </div>
    </div>
  </div>
</template>
