<script setup>
import { ref, onMounted } from 'vue'
import { mdiCashRegister, mdiCheckDecagram, mdiAlertDecagram, mdiRefresh, mdiPlus, mdiFileExport, mdiCog } from '@mdi/js'
import SectionMain from '@/components/SectionMain.vue'
import CardBox from '@/components/CardBox.vue'
import BaseButton from '@/components/BaseButton.vue'
import BaseButtons from '@/components/BaseButtons.vue'
import LayoutAuthenticated from '@/layouts/LayoutAuthenticated.vue'
import SectionTitleLineWithButton from '@/components/SectionTitleLineWithButton.vue'
import CreditDebitModal from '@/components/CreditDebitModal.vue'
import AccountingExportModal from '@/components/AccountingExportModal.vue'
import SystemConfigModal from '@/components/SystemConfigModal.vue'
import { financeService } from '@/services/api'

const activeTab = ref('invoices')
const invoices = ref([]), payments = ref([]), creditNotes = ref([]), debitNotes = ref([])
const reportsData = ref({ kpi: {} })
const showCreditModal = ref(false), showDebitModal = ref(false), showExportModal = ref(false), showConfigModal = ref(false)
const currentUser = ref(JSON.parse(localStorage.getItem('user') || '{}'))
const isAdmin = ref(currentUser.value.role_code === 'ADMIN' || currentUser.value.username === 'admin')
const isAccountant = ref(currentUser.value.role_code === 'ACCOUNTANT' || isAdmin.value)

const fetchData = async () => {
  try {
    const invRes = await financeService.getInvoices()
    invoices.value = invRes.results || []
    const payRes = await financeService.getPayments()
    payments.value = payRes.results || []
    const crRes = await financeService.getCreditNotes()
    creditNotes.value = crRes.results || []
    const drRes = await financeService.getDebitNotes()
    debitNotes.value = drRes.results || []
    const repRes = await financeService.getReports('dashboard-summary')
    reportsData.value = repRes.data || { kpi: {} }
  } catch (error) {
    console.error(error)
  }
}
onMounted(() => fetchData())

const handleVerify = async (id) => {
  try {
    const res = await financeService.verifyMatching(id)
    alert(`Kết quả đối chiếu: ${res.message || 'Thành công'}`)
    fetchData()
  } catch (e) {
    alert('Đối chiếu thất bại: ' + (e.response?.data?.detail || ''))
  }
}
const handleOverride = async (id) => {
  const reason = prompt('Nhập lý do ghi đè chênh lệch đối chiếu:')
  if (!reason) return
  try {
    await financeService.overrideMatching(id, reason)
    alert('Ghi đè chênh lệch thành công!')
    fetchData()
  } catch (e) {
    alert('Ghi đè thất bại.')
  }
}
const handleRequestPayment = async (invoice) => {
  const amountStr = prompt('Nhập số tiền yêu cầu thanh toán:', invoice.total_amount)
  if (!amountStr) return
  try {
    await financeService.createPaymentRequest(invoice.invoice_id, parseFloat(amountStr))
    alert('Đã gửi yêu cầu thanh toán thành công!')
    fetchData()
  } catch (e) {
    alert('Gửi yêu cầu thất bại.')
  }
}
const handleProcessPayment = async (payId, action) => {
  const comment = prompt(`Nhập ý kiến phê duyệt:`, 'Duyệt chi thanh toán')
  if (comment === null) return
  try {
    await financeService.approvePayment(payId, action, comment)
    alert('Xử lý yêu cầu thanh toán thành công!')
    fetchData()
  } catch (e) {
    alert('Thao tác thất bại.')
  }
}
const handleSaveNote = async (data) => {
  try {
    if (showCreditModal.value) {
      await financeService.createCreditNote(data)
      showCreditModal.value = false
    } else {
      await financeService.createDebitNote(data)
      showDebitModal.value = false
    }
    fetchData()
  } catch (e) {
    alert('Lưu phiếu thất bại.')
  }
}
const formatCurrency = (val) => new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(val || 0)
</script>

<template>
  <LayoutAuthenticated>
    <SectionMain>
      <SectionTitleLineWithButton :icon="mdiCashRegister" title="Kế toán & Thanh toán" main>
        <BaseButton v-if="activeTab === 'notes' && isAccountant" :icon="mdiPlus" label="Thêm Credit Note" color="contrast" small @click="showCreditModal = true" />
        <BaseButton v-if="activeTab === 'notes' && isAccountant" :icon="mdiPlus" label="Thêm Debit Note" color="info" small @click="showDebitModal = true" />
        <BaseButton v-if="isAccountant" :icon="mdiFileExport" label="Xuất MISA/FAST" color="warning" small @click="showExportModal = true" />
        <BaseButton v-if="isAdmin" :icon="mdiCog" label="Cấu hình" color="white" small @click="showConfigModal = true" />
      </SectionTitleLineWithButton>

      <div class="flex space-x-4 mb-4 border-b">
        <button class="pb-2 px-4 text-sm font-semibold transition" :class="activeTab === 'invoices' ? 'border-b-2 border-blue-500 text-blue-600' : 'text-gray-500 hover:text-gray-800'" @click="activeTab = 'invoices'">Hóa đơn NCC ({{ invoices.length }})</button>
        <button class="pb-2 px-4 text-sm font-semibold transition" :class="activeTab === 'payments' ? 'border-b-2 border-blue-500 text-blue-600' : 'text-gray-500 hover:text-gray-800'" @click="activeTab = 'payments'">Yêu cầu chi ({{ payments.length }})</button>
        <button class="pb-2 px-4 text-sm font-semibold transition" :class="activeTab === 'notes' ? 'border-b-2 border-blue-500 text-blue-600' : 'text-gray-500 hover:text-gray-800'" @click="activeTab = 'notes'">Credit/Debit Notes</button>
        <button class="pb-2 px-4 text-sm font-semibold transition" :class="activeTab === 'reports' ? 'border-b-2 border-blue-500 text-blue-600' : 'text-gray-500 hover:text-gray-800'" @click="activeTab = 'reports'">Thống kê & KPI</button>
      </div>

      <CardBox v-if="activeTab === 'invoices'" has-table>
        <table class="w-full text-xs text-left">
          <thead class="bg-gray-100 dark:bg-gray-800">
            <tr>
              <th class="px-6 py-3">Số hóa đơn</th>
              <th class="px-6 py-3">Giá trị</th>
              <th class="px-6 py-3">Đối chiếu 3 chiều</th>
              <th class="px-6 py-3 text-right">Thao tác</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="inv in invoices" :key="inv.invoice_id" class="border-b">
              <td class="px-6 py-3 font-semibold">{{ inv.invoice_number }}</td>
              <td class="px-6 py-3 font-bold text-green-600">{{ formatCurrency(inv.total_amount) }}</td>
              <td class="px-6 py-3"><span class="rounded px-2 py-0.5 text-[10px] font-bold" :class="inv.matching_status === 'MATCHED' ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'">{{ inv.matching_status || 'CHƯA ĐỐI CHIẾU' }}</span></td>
              <td class="px-6 py-3 text-right">
                <BaseButtons type="justify-end" no-wrap>
                  <BaseButton color="info" :icon="mdiRefresh" label="Đối chiếu" small @click="handleVerify(inv.invoice_id)" />
                  <BaseButton v-if="inv.matching_status === 'MISMATCHED'" color="danger" :icon="mdiAlertDecagram" label="Ghi đè" small @click="handleOverride(inv.invoice_id)" />
                  <BaseButton v-if="inv.matching_status === 'MATCHED' || inv.matching_status === 'OVERRIDDEN'" color="success" :icon="mdiCheckDecagram" label="Yêu cầu chi" small @click="handleRequestPayment(inv)" />
                </BaseButtons>
              </td>
            </tr>
          </tbody>
        </table>
      </CardBox>

      <CardBox v-else-if="activeTab === 'payments'" has-table>
        <table class="w-full text-xs text-left">
          <thead class="bg-gray-100 dark:bg-gray-800">
            <tr>
              <th class="px-6 py-3">Mã yêu cầu</th>
              <th class="px-6 py-3">Số tiền</th>
              <th class="px-6 py-3">Trạng thái</th>
              <th class="px-6 py-3 text-right">Thao tác</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="p in payments" :key="p.payment_request_id" class="border-b">
              <td class="px-6 py-3 font-semibold">PAY#{{ p.payment_request_id }}</td>
              <td class="px-6 py-3 font-bold text-green-600">{{ formatCurrency(p.amount) }}</td>
              <td class="px-6 py-3">{{ p.status }}</td>
              <td class="px-6 py-3 text-right">
                <BaseButtons v-if="p.status === 'PENDING'" type="justify-end" no-wrap>
                  <BaseButton color="success" label="Duyệt" small @click="handleProcessPayment(p.payment_request_id, 'APPROVE')" />
                  <BaseButton color="danger" label="Từ chối" small @click="handleProcessPayment(p.payment_request_id, 'REJECT')" />
                </BaseButtons>
              </td>
            </tr>
          </tbody>
        </table>
      </CardBox>

      <CardBox v-else-if="activeTab === 'notes'" has-table>
        <table class="w-full text-xs text-left">
          <thead class="bg-gray-100 dark:bg-gray-800">
            <tr>
              <th class="px-6 py-3">Số phiếu điều chỉnh</th>
              <th class="px-6 py-3">Giá trị điều chỉnh</th>
              <th class="px-6 py-3">Lý do</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="n in [...creditNotes, ...debitNotes]" :key="n.credit_note_id || n.debit_note_id" class="border-b">
              <td class="px-6 py-3 font-semibold">{{ n.credit_note_number || n.debit_note_number }}</td>
              <td class="px-6 py-3 font-bold" :class="n.credit_amount ? 'text-green-600' : 'text-orange-600'">{{ formatCurrency(n.credit_amount || n.debit_amount) }}</td>
              <td class="px-6 py-3">{{ n.reason }}</td>
            </tr>
          </tbody>
        </table>
      </CardBox>

      <div v-else-if="activeTab === 'reports'" class="grid grid-cols-1 md:grid-cols-3 gap-6">
        <CardBox class="p-6 text-center"><h4 class="text-sm font-bold text-gray-500 mb-2">Đơn mua hàng dở dang</h4><p class="text-3xl font-black text-blue-600">{{ reportsData.kpi?.ipos_in_progress || 0 }}</p></CardBox>
        <CardBox class="p-6 text-center"><h4 class="text-sm font-bold text-gray-500 mb-2">Thanh toán quá hạn</h4><p class="text-3xl font-black text-red-600">{{ reportsData.kpi?.overdue_payments || 0 }}</p></CardBox>
        <CardBox class="p-6 text-center"><h4 class="text-sm font-bold text-gray-500 mb-2">Vật tư tồn kho thấp</h4><p class="text-3xl font-black text-yellow-600">{{ reportsData.kpi?.low_stock_items || 0 }}</p></CardBox>
      </div>
    </SectionMain>

    <CreditDebitModal v-if="showCreditModal" note-type="credit" @close="showCreditModal = false" @save="handleSaveNote" />
    <CreditDebitModal v-if="showDebitModal" note-type="debit" @close="showDebitModal = false" @save="handleSaveNote" />
    <AccountingExportModal v-if="showExportModal" @close="showExportModal = false" />
    <SystemConfigModal v-if="showConfigModal" @close="showConfigModal = false" />
  </LayoutAuthenticated>
</template>
