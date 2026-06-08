<script setup>
import { reactive } from 'vue'
import { mdiClose } from '@mdi/js'
import BaseButton from '@/components/BaseButton.vue'
import BaseButtons from '@/components/BaseButtons.vue'
import FormField from '@/components/FormField.vue'
import FormControl from '@/components/FormControl.vue'

const emit = defineEmits(['close', 'save'])

const form = reactive({
  material_code: '',
  material_name: '',
  category_id: 1,
  uom: 'Thanh',
  min_stock_level: 10
})

const submit = () => {
  if (!form.material_code || !form.material_name) {
    alert('Vui lòng nhập đầy đủ mã và tên vật tư.')
    return
  }
  emit('save', { ...form })
}
</script>

<template>
  <div class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
    <div class="bg-white dark:bg-gray-900 rounded-lg shadow-xl max-w-md w-full">
      <div class="flex justify-between items-center px-6 py-4 border-b">
        <h3 class="text-lg font-bold">Thêm Vật Tư Mới</h3>
        <BaseButton :icon="mdiClose" color="whiteDark" small @click="emit('close')" />
      </div>
      <div class="p-6 space-y-4">
        <FormField label="Mã vật tư">
          <FormControl v-model="form.material_code" placeholder="Ví dụ: STEEL-HP-014" />
        </FormField>
        <FormField label="Tên vật tư">
          <FormControl v-model="form.material_name" placeholder="Tên vật tư..." />
        </FormField>
        <FormField label="Đơn vị tính">
          <FormControl v-model="form.uom" placeholder="Ví dụ: Thanh, Cuộn, Viên..." />
        </FormField>
        <FormField label="Định mức tồn kho tối thiểu">
          <FormControl v-model="form.min_stock_level" type="number" />
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
