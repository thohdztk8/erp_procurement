<script setup>
import { ref, onMounted, computed } from 'vue'
import { mdiCashRegister, mdiCheckDecagram, mdiAlertDecagram, mdiRefresh } from '@mdi/js'
import SectionMain from '@/components/SectionMain.vue'
import CardBox from '@/components/CardBox.vue'
import BaseButton from '@/components/BaseButton.vue'
import BaseButtons from '@/components/BaseButtons.vue'
import LayoutAuthenticated from '@/layouts/LayoutAuthenticated.vue'
import SectionTitleLineWithButton from '@/components/SectionTitleLineWithButton.vue'
import { financeService } from '@/services/api'

const activeTab = ref('invoices')
const invoices = ref([])
const payments = ref([])
const currentUser = ref(JSON.parse(localStorage.getItem('user') || '{}'))

const fetchData = async () => {
  try {
    const invRes = await financeService.getInvoices()
    invoices.value = invRes.results || []
    
    const payRes = await financeService.getPayments()
    payments.value = payRes.results || []
  } catch (error) {
    console.error(error)
  }
}

onMounted(() => {
  fetchData()
})

const handleVerify = async (id) => {
  try {
    const res = await financeService.verifyMatching(id)
    alert(`Kết quả đối chiếu: ${res.message || 'Thành công'}`)
    fetchData()
  } catch (error) {
    alert('Đối chiếu thất bại: ' + (error.response?.data?.detail || ''))
  }
}

const handleOverride = async (id) => {
  const reason = prompt('Nhập lý do ghi đè chênh lệch đối chiếu:')
  if (!reason) return
  try {
    await financeService.overrideMatching(id, reason)
    alert('Ghi đè chênh lệch thành công!')
    fetchData()
  } catch (error) {
    alert('Ghi đè thất bại: ' + (error.response?.data?.detail || ''))
  }
}

const handleRequestPayment = async (invoice) => {
  const amountStr = prompt('Nhập số tiền yêu cầu thanh toán:', invoice.total_amount)
  if (!amountStr) return
  try {
    await financeService.createPaymentRequest(invoice.invoice_id, parseFloat(amountStr))
    alert('Đã gửi yêu cầu thanh toán thành công!')
    fetchData()
  } catch (error) {
    alert('Gửi yêu cầu thất bại: ' + (error.response?.data?.detail || ''))
  }
}

const handleProcessPayment = async (payId, action) => {
  const comment = prompt(`Nhập ý kiến phê duyệt ${action === 'APPROVE' ? 'duyệt' : 'từ chối'}:`, 'Duyệt chi thanh toán')
  if (comment === null) return
  try {
    await financeService.approvePayment(payId, action, comment)
    alert('Xử lý yêu cầu thanh toán thành công!')
    fetchData()
  } catch (error) {
    alert('Thao tác thất bại: ' + (error.response?.data?.detail || ''))
  }
}

const formatCurrency = (val) => {
  return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(val || 0)
}
</script>

<template>
  <LayoutAuthenticated>
    <SectionMain>
      <SectionTitleLineWithButton :icon="mdiCashRegister" title="Kế toán & Thanh toán" main />

      <!-- Tabs -->
      <div class="flex space-x-4 mb-4 border-b">
        <button 
          class="pb-2 px-4 text-sm font-semibold transition"
          :class="activeTab === 'invoices' ? 'border-b-2 border-blue-500 text-blue-600' : 'text-gray-500 hover:text-gray-800'"
          @click="activeTab = 'invoices'"
        >
          Hóa đơn từ NCC ({{ invoices.length }})
        </button>
        <button 
          class="pb-2 px-4 text-sm font-semibold transition"
          :class="activeTab === 'payments' ? 'border-b-2 border-blue-500 text-blue-600' : 'text-gray-500 hover:text-gray-800'"
          @click="activeTab = 'payments'"
        >
          Yêu cầu thanh toán ({{ payments.length }})
        </button>
      </div>

      <!-- Tab 1: Hóa đơn -->
      <div v-if="activeTab === 'invoices'">
        <CardBox has-table>
          <table class="w-full text-xs text-left">
            <thead class="bg-gray-100 dark:bg-gray-800">
              <tr>
                <th class="px-6 py-3">Số hóa đơn</th>
                <th class="px-6 py-3">Giá trị hóa đơn</th>
                <th class="px-6 py-3">Đối chiếu 3 bên (PO-GRN-Inv)</th>
                <th class="px-6 py-3">Trạng thái thanh toán</th>
                <th class="px-6 py-3">Ngày nhận</th>
                <th class="px-6 py-3 text-right">Thao tác</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="inv in invoices" :key="inv.invoice_id" class="border-b">
                <td class="px-6 py-3 font-semibold">{{ inv.invoice_number }}</td>
                <td class="px-6 py-3 font-bold text-green-600">{{ formatCurrency(inv.total_amount) }}</td>
                <td class="px-6 py-3">
                  <span 
                    class="rounded-full px-2.5 py-0.5 text-[10px] font-bold"
                    :class="inv.matching_status === 'MATCHED' ? 'bg-green-100 text-green-800' : inv.matching_status === 'MISMATCHED' ? 'bg-red-100 text-red-800' : 'bg-gray-100 text-gray-800'"
                  >
                    {{ inv.matching_status || 'CHƯA ĐỐI CHIẾU' }}
                  </span>
                </td>
                <td class="px-6 py-3 font-semibold">{{ inv.payment_status }}</td>
                <td class="px-6 py-3">{{ new Date(inv.created_at).toLocaleDateString('vi-VN') }}</td>
                <td class="px-6 py-3 text-right">
                  <BaseButtons type="justify-end" no-wrap>
                    <BaseButton color="info" :icon="mdiRefresh" label="Đối chiếu" small @click="handleVerify(inv.invoice_id)" />
                    <BaseButton 
                      v-if="inv.matching_status === 'MISMATCHED'" 
                      color="danger" 
                      :icon="mdiAlertDecagram" 
                      label="Ghi đè lỗi" 
                      small 
                      @click="handleOverride(inv.invoice_id)" 
                    />
                    <BaseButton 
                      v-if="inv.matching_status === 'MATCHED' || inv.matching_status === 'OVERRIDDEN'" 
                      color="success" 
                      :icon="mdiCheckDecagram" 
                      label="Yêu cầu thanh toán" 
                      small 
                      @click="handleRequestPayment(inv)" 
                    />
                  </BaseButtons>
                </td>
              </tr>
              <tr v-if="invoices.length === 0">
                <td colspan="6" class="text-center py-8 text-gray-400">Không tìm thấy hóa đơn nào.</td>
              </tr>
            </tbody>
          </table>
        </CardBox>
      </div>

      <!-- Tab 2: Yêu cầu thanh toán -->
      <div v-else>
        <CardBox has-table>
          <table class="w-full text-xs text-left">
            <thead class="bg-gray-100 dark:bg-gray-800">
              <tr>
                <th class="px-6 py-3">Mã yêu cầu</th>
                <th class="px-6 py-3">Số hóa đơn</th>
                <th class="px-6 py-3">Số tiền yêu cầu</th>
                <th class="px-6 py-3">Trạng thái</th>
                <th class="px-6 py-3">Ngày tạo</th>
                <th class="px-6 py-3 text-right">Thao tác</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="p in payments" :key="p.payment_request_id" class="border-b">
                <td class="px-6 py-3 font-semibold">PAY#{{ p.payment_request_id }}</td>
                <td class="px-6 py-3 font-semibold">{{ p.invoice_number || p.invoice_id }}</td>
                <td class="px-6 py-3 font-bold text-green-600">{{ formatCurrency(p.amount) }}</td>
                <td class="px-6 py-3">
                  <span 
                    class="rounded px-2 py-0.5 text-[10px] font-bold"
                    :class="p.status === 'APPROVED' ? 'bg-green-100 text-green-800' : p.status === 'REJECTED' ? 'bg-red-100 text-red-800' : 'bg-yellow-100 text-yellow-800'"
                  >
                    {{ p.status }}
                  </span>
                </td>
                <td class="px-6 py-3">{{ new Date(p.created_at).toLocaleDateString('vi-VN') }}</td>
                <td class="px-6 py-3 text-right">
                  <BaseButtons v-if="p.status === 'PENDING' && (currentUser.permissions?.includes('PAYMENT_APPROVE') || currentUser.username === 'admin')" type="justify-end" no-wrap>
                    <BaseButton color="success" label="Duyệt chi" small @click="handleProcessPayment(p.payment_request_id, 'APPROVE')" />
                    <BaseButton color="danger" label="Từ chối" small @click="handleProcessPayment(p.payment_request_id, 'REJECT')" />
                  </BaseButtons>
                  <span v-else class="text-gray-400 text-xs">-</span>
                </td>
              </tr>
              <tr v-if="payments.length === 0">
                <td colspan="6" class="text-center py-8 text-gray-400">Không tìm thấy yêu cầu thanh toán nào.</td>
              </tr>
            </tbody>
          </table>
        </CardBox>
      </div>
    </SectionMain>
  </LayoutAuthenticated>
</template>
