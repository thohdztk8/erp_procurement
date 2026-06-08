<script setup>
import { reactive } from 'vue'
import { mdiClose } from '@mdi/js'
import BaseButton from '@/components/BaseButton.vue'
import BaseButtons from '@/components/BaseButtons.vue'
import FormField from '@/components/FormField.vue'
import FormControl from '@/components/FormControl.vue'

const props = defineProps({
  supplier: { type: Object, required: true },
  materials: { type: Array, required: true }
})

const emit = defineEmits(['close', 'save'])

const form = reactive({
  material_id: '',
  contract_unit_price: 0,
  valid_from: new Date().toISOString().split('T')[0],
  valid_to: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000).toISOString().split('T')[0]
})

const submit = () => {
  if (!form.material_id || form.contract_unit_price <= 0) {
    alert('Vui lòng chọn vật tư và nhập đơn giá hợp đồng.')
    return
  }
  emit('save', {
    material_id: parseInt(form.material_id),
    contract_unit_price: parseFloat(form.contract_unit_price),
    valid_from: form.valid_from,
    valid_to: form.valid_to
  })
}
</script>

<template>
  <div class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
    <div class="bg-white dark:bg-gray-900 rounded-lg shadow-xl max-w-md w-full">
      <div class="flex justify-between items-center px-6 py-4 border-b">
        <h3 class="text-lg font-bold">Thêm Thỏa Thuận Giá: {{ supplier.supplier_name }}</h3>
        <BaseButton :icon="mdiClose" color="whiteDark" small @click="emit('close')" />
      </div>
      <div class="p-6 space-y-4">
        <FormField label="Vật tư">
          <select v-model="form.material_id" class="w-full bg-white dark:bg-gray-800 border rounded p-2 text-sm">
            <option value="">-- Chọn vật tư --</option>
            <option v-for="mat in materials" :key="mat.material_id" :value="mat.material_id">
              {{ mat.material_code }} - {{ mat.material_name }}
            </option>
          </select>
        </FormField>
        <FormField label="Giá thỏa thuận khung (VND)">
          <FormControl v-model="form.contract_unit_price" type="number" min="1" />
        </FormField>
        <FormField label="Hiệu lực từ">
          <FormControl v-model="form.valid_from" type="date" />
        </FormField>
        <FormField label="Hiệu lực đến">
          <FormControl v-model="form.valid_to" type="date" />
        </FormField>
      </div>
      <div class="flex justify-end px-6 py-4 border-t">
        <BaseButtons>
          <BaseButton color="white" label="Hủy" @click="emit('close')" />
          <BaseButton color="success" label="Lưu" @click="submit" />
        </BaseButtons>
      </div>
    </div>
  </div>
</template>
