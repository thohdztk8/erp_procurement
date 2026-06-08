<script setup>
import { reactive, onMounted, ref } from 'vue'
import { mdiClose } from '@mdi/js'
import BaseButton from '@/components/BaseButton.vue'
import BaseButtons from '@/components/BaseButtons.vue'
import FormField from '@/components/FormField.vue'
import FormControl from '@/components/FormControl.vue'
import { masterService } from '@/services/api'

const emit = defineEmits(['close', 'save'])

const form = reactive({
  supplier_id: '',
  receipt_id: '',
  reason_category: 'QUALITY_DEFECT',
  items: [],
  notify_supplier_email: true
})

const suppliers = ref([])
const materials = ref([])
const itemInput = reactive({
  material_id: '',
  qty_returned: 1,
  reason: ''
})

onMounted(async () => {
  try {
    const supRes = await masterService.getSuppliers()
    suppliers.value = supRes.results || []

    const matRes = await masterService.getMaterials()
    materials.value = matRes.results || []
  } catch (error) {
    console.error(error)
  }
})

const addItem = () => {
  if (!itemInput.material_id) {
    alert('Vui lòng chọn vật tư.')
    return
  }
  const mat = materials.value.find(m => m.material_id === parseInt(itemInput.material_id))
  form.items.push({
    material_id: mat.material_id,
    material_name: mat.material_name,
    qty_returned: parseFloat(itemInput.qty_returned),
    reason: itemInput.reason
  })
  itemInput.material_id = ''
  itemInput.qty_returned = 1
  itemInput.reason = ''
}

const removeItem = (idx) => {
  form.items.splice(idx, 1)
}

const submit = () => {
  if (!form.supplier_id) {
    alert('Vui lòng chọn nhà cung cấp.')
    return
  }
  if (form.items.length === 0) {
    alert('Vui lòng thêm ít nhất 1 dòng hàng hoàn trả.')
    return
  }
  emit('save', {
    supplier_id: parseInt(form.supplier_id),
    receipt_id: form.receipt_id ? parseInt(form.receipt_id) : null,
    reason_category: form.reason_category,
    items: form.items.map(it => ({ material_id: it.material_id, qty_returned: it.qty_returned, reason: it.reason })),
    notify_supplier_email: form.notify_supplier_email
  })
}
</script>

<template>
  <div class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
    <div class="bg-white dark:bg-gray-900 rounded-lg shadow-xl max-w-lg w-full">
      <div class="flex justify-between items-center px-6 py-4 border-b">
        <h3 class="text-lg font-bold">Lập Phiếu Hoàn Trả Nhà Cung Cấp</h3>
        <BaseButton :icon="mdiClose" color="whiteDark" small @click="emit('close')" />
      </div>
      <div class="p-6 space-y-4 max-h-[70vh] overflow-y-auto">
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <FormField label="Nhà cung cấp">
            <select v-model="form.supplier_id" class="w-full bg-white dark:bg-gray-800 border rounded p-2 text-sm">
              <option value="">-- Chọn nhà cung cấp --</option>
              <option v-for="sup in suppliers" :key="sup.supplier_id" :value="sup.supplier_id">
                {{ sup.supplier_name }}
              </option>
            </select>
          </FormField>
          <FormField label="Mã phiếu nhập IQC liên kết (nếu có)">
            <FormControl v-model="form.receipt_id" type="number" placeholder="Ví dụ: 844" />
          </FormField>
          <FormField label="Lý do hoàn trả">
            <select v-model="form.reason_category" class="w-full bg-white dark:bg-gray-800 border rounded p-2 text-sm">
              <option value="QUALITY_DEFECT">Lỗi chất lượng (QUALITY_DEFECT)</option>
              <option value="WRONG_SPEC">Sai quy cách (WRONG_SPEC)</option>
              <option value="EXCESS_QUANTITY">Giao thừa số lượng (EXCESS_QUANTITY)</option>
              <option value="OTHER">Lý do khác (OTHER)</option>
            </select>
          </FormField>
        </div>

        <div class="bg-gray-50 dark:bg-gray-800 p-3 rounded space-y-3">
          <h4 class="text-xs font-bold text-gray-500">Thêm dòng vật tư trả lại</h4>
          <div class="grid grid-cols-1 md:grid-cols-3 gap-2 items-end">
            <FormField label="Vật tư" class="md:col-span-2">
              <select v-model="itemInput.material_id" class="w-full bg-white dark:bg-gray-800 border rounded p-2 text-sm">
                <option value="">-- Chọn vật tư --</option>
                <option v-for="mat in materials" :key="mat.material_id" :value="mat.material_id">
                  {{ mat.material_name }}
                </option>
              </select>
            </FormField>
            <FormField label="Số lượng trả">
              <FormControl v-model="itemInput.qty_returned" type="number" min="0.0001" />
            </FormField>
            <FormField label="Mô tả lỗi" class="md:col-span-3">
              <FormControl v-model="itemInput.reason" placeholder="Ví dụ: Móp méo, cong vênh..." />
            </FormField>
          </div>
          <BaseButton color="info" label="Thêm" small @click="addItem" />
        </div>

        <table class="w-full text-xs text-left border">
          <thead>
            <tr class="bg-gray-100 dark:bg-gray-800">
              <th class="p-2 border-b">Tên vật tư</th>
              <th class="p-2 border-b text-right">Số lượng</th>
              <th class="p-2 border-b">Mô tả</th>
              <th class="p-2 border-b text-right">Xóa</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="(it, idx) in form.items" :key="idx">
              <td class="p-2 border-b">{{ it.material_name }}</td>
              <td class="p-2 border-b text-right font-bold">{{ it.qty_returned }}</td>
              <td class="p-2 border-b text-gray-500">{{ it.reason || '-' }}</td>
              <td class="p-2 border-b text-right">
                <BaseButton color="danger" label="Xóa" small @click="removeItem(idx)" />
              </td>
            </tr>
          </tbody>
        </table>
      </div>
      <div class="flex justify-end px-6 py-4 border-t">
        <BaseButtons>
          <BaseButton color="white" label="Hủy" @click="emit('close')" />
          <BaseButton color="success" label="Xác nhận hoàn trả" @click="submit" />
        </BaseButtons>
      </div>
    </div>
  </div>
</template>
