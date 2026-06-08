<script setup>
import { reactive } from 'vue'
import { mdiClose } from '@mdi/js'
import BaseButton from '@/components/BaseButton.vue'
import BaseButtons from '@/components/BaseButtons.vue'
import FormField from '@/components/FormField.vue'
import FormControl from '@/components/FormControl.vue'

const emit = defineEmits(['close', 'save'])

const form = reactive({
  supplier_code: '',
  supplier_name: '',
  tax_code: '',
  contact_name: '',
  contact_email: '',
  contact_phone: '',
  address: ''
})

const submit = () => {
  if (!form.supplier_code || !form.supplier_name || !form.tax_code) {
    alert('Vui lòng điền mã, tên và mã số thuế nhà cung cấp.')
    return
  }
  emit('save', { ...form })
}
</script>

<template>
  <div class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
    <div class="bg-white dark:bg-gray-900 rounded-lg shadow-xl max-w-lg w-full">
      <div class="flex justify-between items-center px-6 py-4 border-b">
        <h3 class="text-lg font-bold">Thêm Nhà Cung Cấp</h3>
        <BaseButton :icon="mdiClose" color="whiteDark" small @click="emit('close')" />
      </div>
      <div class="p-6 grid grid-cols-1 md:grid-cols-2 gap-4">
        <FormField label="Mã NCC">
          <FormControl v-model="form.supplier_code" placeholder="NCC-HP-001" />
        </FormField>
        <FormField label="Tên nhà cung cấp">
          <FormControl v-model="form.supplier_name" placeholder="Tên công ty..." />
        </FormField>
        <FormField label="Mã số thuế">
          <FormControl v-model="form.tax_code" placeholder="0100123456" />
        </FormField>
        <FormField label="Người liên hệ">
          <FormControl v-model="form.contact_name" placeholder="Tên người liên hệ..." />
        </FormField>
        <FormField label="Email liên hệ">
          <FormControl v-model="form.contact_email" type="email" placeholder="sales@company.com" />
        </FormField>
        <FormField label="Số điện thoại">
          <FormControl v-model="form.contact_phone" placeholder="0241234567" />
        </FormField>
        <FormField label="Địa chỉ" class="md:col-span-2">
          <FormControl v-model="form.address" placeholder="Địa chỉ trụ sở..." />
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
