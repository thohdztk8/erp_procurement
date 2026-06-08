<script setup>
import { reactive, onMounted, ref } from 'vue'
import { mdiClose } from '@mdi/js'
import BaseButton from '@/components/BaseButton.vue'
import BaseButtons from '@/components/BaseButtons.vue'
import FormField from '@/components/FormField.vue'
import FormControl from '@/components/FormControl.vue'
import { masterService, financeService } from '@/services/api'

const props = defineProps({
  noteType: { type: String, default: 'credit' } // 'credit' or 'debit'
})

const emit = defineEmits(['close', 'save'])

const form = reactive({
  supplier_id: '',
  invoice_id: '',
  amount: 0,
  note_number: '',
  reason: ''
})

const suppliers = ref([])
const invoices = ref([])

onMounted(async () => {
  try {
    const supRes = await masterService.getSuppliers()
    suppliers.value = supRes.results || []

    const invRes = await financeService.getInvoices()
    invoices.value = invRes.results || []
  } catch (error) {
    console.error(error)
  }
})

const submit = () => {
  if (!form.supplier_id || !form.invoice_id || form.amount <= 0 || !form.note_number) {
    alert('Vui lòng nhập đầy đủ thông tin.')
    return
  }
  emit('save', {
    supplier_id: parseInt(form.supplier_id),
    invoice_id: parseInt(form.invoice_id),
    amount: parseFloat(form.amount),
    note_number: form.note_number,
    reason: form.reason
  })
}
</script>

<template>
  <div class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
    <div class="bg-white dark:bg-gray-900 rounded-lg shadow-xl max-w-md w-full">
      <div class="flex justify-between items-center px-6 py-4 border-b">
        <h3 class="text-lg font-bold">Lập Phiếu {{ noteType === 'credit' ? 'Credit Note' : 'Debit Note' }}</h3>
        <BaseButton :icon="mdiClose" color="whiteDark" small @click="emit('close')" />
      </div>
      <div class="p-6 space-y-4">
        <FormField label="Nhà cung cấp">
          <select v-model="form.supplier_id" class="w-full bg-white dark:bg-gray-800 border rounded p-2 text-sm">
            <option value="">-- Chọn nhà cung cấp --</option>
            <option v-for="sup in suppliers" :key="sup.supplier_id" :value="sup.supplier_id">
              {{ sup.supplier_name }}
            </option>
          </select>
        </FormField>
        <FormField label="Hóa đơn đối chiếu">
          <select v-model="form.invoice_id" class="w-full bg-white dark:bg-gray-800 border rounded p-2 text-sm">
            <option value="">-- Chọn hóa đơn --</option>
            <option v-for="inv in invoices" :key="inv.invoice_id" :value="inv.invoice_id">
              {{ inv.invoice_number }} ({{ inv.total_amount }} VND)
            </option>
          </select>
        </FormField>
        <FormField label="Số phiếu">
          <FormControl v-model="form.note_number" placeholder="CN-2026-0001" />
        </FormField>
        <FormField label="Số tiền điều chỉnh (VND)">
          <FormControl v-model="form.amount" type="number" min="1" />
        </FormField>
        <FormField label="Lý do điều chỉnh">
          <FormControl v-model="form.reason" placeholder="Ví dụ: Giảm trừ do hàng hỏng..." />
        </FormField>
      </div>
      <div class="flex justify-end px-6 py-4 border-t">
        <BaseButtons>
          <BaseButton color="white" label="Hủy" @click="emit('close')" />
          <BaseButton color="success" label="Lưu phiếu" @click="submit" />
        </BaseButtons>
      </div>
    </div>
  </div>
</template>
