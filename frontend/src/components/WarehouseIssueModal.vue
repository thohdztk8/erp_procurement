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
  pr_id: '',
  dept_id: '',
  receiver_user_id: '',
  issue_at: new Date().toISOString().split('T')[0],
  items: [],
  note: ''
})

const materials = ref([])
const itemInput = reactive({
  material_id: '',
  qty_issued: 1
})

onMounted(async () => {
  try {
    const res = await masterService.getMaterials()
    materials.value = res.results || []
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
    qty_issued: parseFloat(itemInput.qty_issued)
  })
  itemInput.material_id = ''
  itemInput.qty_issued = 1
}

const removeItem = (idx) => {
  form.items.splice(idx, 1)
}

const submit = () => {
  if (form.items.length === 0) {
    alert('Vui lòng thêm ít nhất 1 vật tư cấp phát.')
    return
  }
  emit('save', {
    pr_id: form.pr_id ? parseInt(form.pr_id) : null,
    dept_id: form.dept_id ? parseInt(form.dept_id) : 1,
    receiver_user_id: form.receiver_user_id ? parseInt(form.receiver_user_id) : 1,
    issue_at: new Date(form.issue_at).toISOString(),
    items: form.items.map(it => ({ material_id: it.material_id, qty_issued: it.qty_issued })),
    note: form.note
  })
}
</script>

<template>
  <div class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
    <div class="bg-white dark:bg-gray-900 rounded-lg shadow-xl max-w-lg w-full">
      <div class="flex justify-between items-center px-6 py-4 border-b">
        <h3 class="text-lg font-bold">Lập Phiếu Xuất Kho Cấp Phát</h3>
        <BaseButton :icon="mdiClose" color="whiteDark" small @click="emit('close')" />
      </div>
      <div class="p-6 space-y-4 max-h-[70vh] overflow-y-auto">
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <FormField label="Mã đơn PR liên kết (nếu có)">
            <FormControl v-model="form.pr_id" type="number" placeholder="Ví dụ: 1024" />
          </FormField>
          <FormField label="Ngày xuất">
            <FormControl v-model="form.issue_at" type="date" />
          </FormField>
          <FormField label="Phòng ban nhận" class="md:col-span-2">
            <FormControl v-model="form.dept_id" placeholder="Phòng Sản xuất..." />
          </FormField>
        </div>

        <div class="bg-gray-50 dark:bg-gray-800 p-3 rounded space-y-3">
          <h4 class="text-xs font-bold text-gray-500">Thêm vật tư cấp phát</h4>
          <div class="grid grid-cols-1 md:grid-cols-3 gap-2 items-end">
            <FormField label="Vật tư" class="md:col-span-2">
              <select v-model="itemInput.material_id" class="w-full bg-white dark:bg-gray-800 border rounded p-2 text-sm">
                <option value="">-- Chọn vật tư --</option>
                <option v-for="mat in materials" :key="mat.material_id" :value="mat.material_id">
                  {{ mat.material_name }}
                </option>
              </select>
            </FormField>
            <FormField label="Số lượng xuất">
              <FormControl v-model="itemInput.qty_issued" type="number" min="0.0001" />
            </FormField>
          </div>
          <BaseButton color="info" label="Thêm" small @click="addItem" />
        </div>

        <table class="w-full text-xs text-left border">
          <thead>
            <tr class="bg-gray-100 dark:bg-gray-800">
              <th class="p-2 border-b">Tên vật tư</th>
              <th class="p-2 border-b text-right">Số lượng</th>
              <th class="p-2 border-b text-right">Xóa</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="(it, idx) in form.items" :key="idx">
              <td class="p-2 border-b">{{ it.material_name }}</td>
              <td class="p-2 border-b text-right font-bold">{{ it.qty_issued }}</td>
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
          <BaseButton color="success" label="Xác nhận xuất kho" @click="submit" />
        </BaseButtons>
      </div>
    </div>
  </div>
</template>
