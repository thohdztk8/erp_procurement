<script setup>
import { reactive, onMounted, ref } from 'vue'
import { mdiClose } from '@mdi/js'
import BaseButton from '@/components/BaseButton.vue'
import BaseButtons from '@/components/BaseButtons.vue'
import FormField from '@/components/FormField.vue'
import FormControl from '@/components/FormControl.vue'
import { financeService } from '@/services/api'

const emit = defineEmits(['close'])

const form = reactive({
  template_code: 'MISA_SME_2025',
  data_type: 'INVOICES_AND_PAYMENTS',
  date_from: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
  date_to: new Date().toISOString().split('T')[0]
})

const templates = ref([])

onMounted(async () => {
  try {
    const res = await financeService.getExportTemplates()
    templates.value = res.data || ['MISA_SME_2025', 'FAST_ACCOUNTING_11', 'EXCEL_STANDARD']
  } catch (error) {
    templates.value = ['MISA_SME_2025', 'FAST_ACCOUNTING_11', 'EXCEL_STANDARD']
  }
})

const submit = async () => {
  try {
    const res = await financeService.createExport({
      template_code: form.template_code,
      data_type: form.data_type,
      date_from: form.date_from,
      date_to: form.date_to
    })
    alert(`Đã xuất file thành công! Số dòng: ${res.data?.rows_exported || 0}`)
    if (res.data?.file_url) {
      window.open(res.data.file_url, '_blank')
    }
    emit('close')
  } catch (e) {
    alert('Xuất dữ liệu kế toán thất bại.')
  }
}
</script>

<template>
  <div class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
    <div class="bg-white dark:bg-gray-900 rounded-lg shadow-xl max-w-md w-full">
      <div class="flex justify-between items-center px-6 py-4 border-b">
        <h3 class="text-lg font-bold">Xuất Dữ Liệu Kế Toán</h3>
        <BaseButton :icon="mdiClose" color="whiteDark" small @click="emit('close')" />
      </div>
      <div class="p-6 space-y-4">
        <FormField label="Định dạng phần mềm đích">
          <select v-model="form.template_code" class="w-full bg-white dark:bg-gray-800 border rounded p-2 text-sm">
            <option v-for="t in templates" :key="t" :value="t">{{ t }}</option>
          </select>
        </FormField>
        <FormField label="Loại dữ liệu">
          <select v-model="form.data_type" class="w-full bg-white dark:bg-gray-800 border rounded p-2 text-sm">
            <option value="INVOICES_ONLY">Hóa đơn bán hàng (INVOICES_ONLY)</option>
            <option value="PAYMENTS_ONLY">Phiếu chi thanh toán (PAYMENTS_ONLY)</option>
            <option value="INVOICES_AND_PAYMENTS">Tất cả hóa đơn & thanh toán</option>
          </select>
        </FormField>
        <FormField label="Từ ngày">
          <FormControl v-model="form.date_from" type="date" />
        </FormField>
        <FormField label="Đến ngày">
          <FormControl v-model="form.date_to" type="date" />
        </FormField>
      </div>
      <div class="flex justify-end px-6 py-4 border-t">
        <BaseButtons>
          <BaseButton color="white" label="Hủy" @click="emit('close')" />
          <BaseButton color="success" label="Xuất File Excel" @click="submit" />
        </BaseButtons>
      </div>
    </div>
  </div>
</template>
