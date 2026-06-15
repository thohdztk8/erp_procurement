<script setup>
import { ref, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { quotationService } from '@/services/api'
import BaseButton from '@/components/BaseButton.vue'
import FormField from '@/components/FormField.vue'
import FormControl from '@/components/FormControl.vue'

const route = useRoute()
const router = useRouter()

const token = route.query.token
const isLoading = ref(true)
const isSubmitting = ref(false)
const errorMsg = ref('')

const detail = ref(null)

const leadTime = ref(7)
const paymentTerms = ref('')
const bidItems = ref([])

onMounted(async () => {
  if (!token) {
    errorMsg.value = 'Không tìm thấy token hợp lệ.'
    isLoading.value = false
    return
  }

  try {
    const res = await quotationService.getVendorPortalDetail(token)
    detail.value = res.data
    
    // Khởi tạo form bidItems
    bidItems.value = detail.value.items.map(it => ({
      order_item_id: it.order_item_id,
      material_name: it.material_name,
      qty_requested: it.qty_requested,
      quoted_unit_price: 0,
      supplier_note: ''
    }))
  } catch (err) {
    errorMsg.value = err.response?.data?.detail || 'Lỗi khi tải thông tin yêu cầu báo giá.'
  } finally {
    isLoading.value = false
  }
})

const handleSubmit = async () => {
  if (leadTime.value < 1) {
    alert('Thời gian giao hàng (ngày) không hợp lệ.')
    return
  }
  
  for (let it of bidItems.value) {
    if (it.quoted_unit_price <= 0) {
      alert(`Vui lòng nhập đơn giá hợp lệ cho mặt hàng: ${it.material_name}`)
      return
    }
  }

  if (!confirm('Bạn chắc chắn muốn nộp báo giá này? Báo giá sau khi nộp sẽ không thể chỉnh sửa trừ khi được yêu cầu (IPO versioning).')) {
    return
  }

  isSubmitting.value = true
  try {
    await quotationService.submitVendorBid({
      token,
      delivery_lead_time_days: leadTime.value,
      payment_terms_note: paymentTerms.value,
      items: bidItems.value.map(it => ({
        order_item_id: it.order_item_id,
        quoted_unit_price: it.quoted_unit_price,
        supplier_note: it.supplier_note
      }))
    })
    alert('Nộp báo giá thành công!')
    detail.value = null // ẩn form
    errorMsg.value = 'Cảm ơn bạn đã nộp báo giá. Bạn có thể đóng trang này.'
  } catch (err) {
    alert('Lỗi nộp báo giá: ' + (err.response?.data?.detail || ''))
  } finally {
    isSubmitting.value = false
  }
}

const formatCurrency = (val) => {
  return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(val || 0)
}
</script>

<template>
  <div class="min-h-screen bg-gray-50 dark:bg-slate-900 py-12 px-4 sm:px-6 lg:px-8">
    <div class="max-w-4xl mx-auto bg-white dark:bg-slate-800 rounded-xl shadow-md overflow-hidden">
      
      <!-- Header -->
      <div class="bg-blue-600 px-6 py-4">
        <h2 class="text-2xl font-bold text-white">Cổng nộp Báo Giá Nhà Cung Cấp (Vendor Portal)</h2>
      </div>

      <div class="p-6">
        <div v-if="isLoading" class="text-center py-10">Đang tải dữ liệu...</div>

        <div v-else-if="errorMsg" class="bg-red-50 text-red-600 p-4 rounded text-center">
          {{ errorMsg }}
        </div>

        <div v-else-if="detail">
          <div class="grid grid-cols-2 gap-4 mb-6 text-sm bg-blue-50 dark:bg-blue-900/20 p-4 rounded">
            <div><span class="font-semibold text-gray-500">Mã đơn yêu cầu:</span> {{ detail.order_code }}</div>
            <div><span class="font-semibold text-gray-500">Nhà cung cấp:</span> {{ detail.supplier_name }}</div>
            <div class="col-span-2 text-red-600 font-bold">
              <span class="text-gray-500 font-semibold mr-1">Hạn chót nộp:</span> 
              {{ new Date(detail.deadline).toLocaleString('vi-VN') }}
            </div>
          </div>

          <h3 class="font-bold text-lg mb-4 text-gray-800 dark:text-gray-200">Chi tiết mặt hàng & Nhập đơn giá</h3>
          <table class="w-full text-sm text-left border mb-6">
            <thead class="bg-gray-100 dark:bg-slate-700">
              <tr>
                <th class="p-3 border-b w-1/3">Tên vật tư</th>
                <th class="p-3 border-b text-right">SL yêu cầu</th>
                <th class="p-3 border-b w-32">Đơn giá (VNĐ)</th>
                <th class="p-3 border-b">Ghi chú (Tùy chọn)</th>
                <th class="p-3 border-b text-right">Thành tiền</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="it in bidItems" :key="it.order_item_id" class="border-b">
                <td class="p-3 border-r font-medium">{{ it.material_name }}</td>
                <td class="p-3 border-r text-right font-bold text-blue-600">{{ it.qty_requested }}</td>
                <td class="p-3 border-r">
                  <input type="number" class="w-full border p-1.5 rounded text-right dark:bg-slate-700" v-model.number="it.quoted_unit_price" min="0" step="1000" />
                </td>
                <td class="p-3 border-r">
                  <input type="text" class="w-full border p-1.5 rounded dark:bg-slate-700" v-model="it.supplier_note" placeholder="Ví dụ: SP thay thế tương đương..." />
                </td>
                <td class="p-3 text-right font-semibold text-green-600">
                  {{ formatCurrency(it.qty_requested * (it.quoted_unit_price || 0)) }}
                </td>
              </tr>
              <tr class="bg-gray-50 dark:bg-slate-800 font-bold">
                <td colspan="4" class="p-3 text-right">Tổng cộng (Dự kiến):</td>
                <td class="p-3 text-right text-green-700">
                  {{ formatCurrency(bidItems.reduce((acc, it) => acc + (it.qty_requested * (it.quoted_unit_price || 0)), 0)) }}
                </td>
              </tr>
            </tbody>
          </table>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-6 mb-8">
            <FormField label="Thời gian giao hàng cam kết (Số ngày)">
              <FormControl type="number" v-model="leadTime" min="1" />
            </FormField>
            <FormField label="Điều khoản thanh toán & Ghi chú thêm">
              <FormControl type="textarea" v-model="paymentTerms" placeholder="Ví dụ: Công nợ 30 ngày..." />
            </FormField>
          </div>

          <div class="flex justify-center mt-6">
            <BaseButton 
              color="success" 
              label="Nộp Báo Giá" 
              class="w-full md:w-1/3 py-3 text-lg font-bold"
              :disabled="isSubmitting"
              @click="handleSubmit" 
            />
          </div>
        </div>
      </div>
      
    </div>
  </div>
</template>
