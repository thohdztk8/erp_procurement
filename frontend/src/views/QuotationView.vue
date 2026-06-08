<script setup>
import { ref, onMounted } from 'vue'
import { mdiCompare, mdiBriefcaseCheck, mdiEye, mdiStar } from '@mdi/js'
import SectionMain from '@/components/SectionMain.vue'
import CardBox from '@/components/CardBox.vue'
import BaseButton from '@/components/BaseButton.vue'
import BaseButtons from '@/components/BaseButtons.vue'
import LayoutAuthenticated from '@/layouts/LayoutAuthenticated.vue'
import SectionTitleLineWithButton from '@/components/SectionTitleLineWithButton.vue'
import BaseIcon from '@/components/BaseIcon.vue'
import { cartOrderService, quotationService } from '@/services/api'

const orders = ref([])
const selectedOrderId = ref(null)
const selectedOrderCode = ref('')
const quotations = ref([])
const isLoading = ref(false)

const fetchOrders = async () => {
  try {
    const res = await cartOrderService.getOrders()
    orders.value = res.results || []
  } catch (error) {
    console.error(error)
  }
}

onMounted(() => {
  fetchOrders()
})

const selectOrder = async (order) => {
  selectedOrderId.value = order.order_id
  selectedOrderCode.value = order.order_code
  isLoading.value = true
  try {
    const res = await quotationService.compareQuotations(order.order_id)
    quotations.value = res.data || []
  } catch (error) {
    console.error(error)
    quotations.value = []
  } finally {
    isLoading.value = false
  }
}

const handleSelectWinner = async (quotationId) => {
  if (!confirm('Bạn chắc chắn chọn báo giá này làm phương án tối ưu để lập hợp đồng chứ?')) {
    return
  }
  try {
    await quotationService.selectQuotation(quotationId, 'Chọn thầu giá tối ưu')
    alert('Đã phê duyệt lựa chọn nhà cung cấp thành công!')
    // Tải lại dữ liệu
    const currentOrder = orders.value.find(o => o.order_id === selectedOrderId.value)
    if (currentOrder) selectOrder(currentOrder)
    fetchOrders()
  } catch (error) {
    alert('Lựa chọn thất bại. ' + (error.response?.data?.detail || ''))
  }
}

const formatCurrency = (val) => {
  return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(val || 0)
}
</script>

<template>
  <LayoutAuthenticated>
    <SectionMain>
      <SectionTitleLineWithButton :icon="mdiCompare" title="Đấu thầu & So sánh báo giá" main />

      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <!-- Danh sách PO bên trái -->
        <CardBox class="lg:col-span-1 p-4">
          <h4 class="font-bold text-sm mb-3">Đơn mua hàng đang đấu thầu</h4>
          <ul class="space-y-2">
            <li 
              v-for="o in orders" 
              :key="o.order_id" 
              class="p-3 rounded border cursor-pointer transition hover:bg-blue-50 dark:hover:bg-gray-800"
              :class="selectedOrderId === o.order_id ? 'border-blue-500 bg-blue-50/50 dark:bg-blue-950/20' : 'border-gray-200'"
              @click="selectOrder(o)"
            >
              <div class="flex justify-between font-semibold text-xs">
                <span>{{ o.order_code }}</span>
                <span class="text-blue-600">{{ o.order_status }}</span>
              </div>
              <p class="text-[11px] text-gray-400 mt-1">
                {{ o.item_count }} dòng hàng • {{ new Date(o.created_at).toLocaleDateString('vi-VN') }}
              </p>
            </li>
            <li v-if="orders.length === 0" class="text-gray-400 text-center py-4 text-xs">
              Chưa có đơn hàng nào.
            </li>
          </ul>
        </CardBox>

        <!-- Bảng so sánh báo giá bên phải -->
        <div class="lg:col-span-2 space-y-4">
          <CardBox v-if="!selectedOrderId" class="p-8 text-center text-gray-400 text-sm">
            Vui lòng chọn một đơn mua hàng ở danh sách bên trái để so sánh báo giá của các nhà cung cấp.
          </CardBox>

          <div v-else-if="isLoading" class="text-center py-12 text-sm text-gray-500">
            Đang tải dữ liệu báo giá so sánh...
          </div>

          <div v-else class="space-y-6">
            <div class="flex justify-between items-center bg-gray-50 dark:bg-gray-800 p-4 rounded-lg">
              <h3 class="font-bold text-md text-gray-800 dark:text-white">
                Báo giá cho đơn: {{ selectedOrderCode }}
              </h3>
              <span class="text-xs text-gray-500">Số lượng báo giá nhận được: {{ quotations.length }}</span>
            </div>

            <!-- List Báo giá -->
            <div v-for="q in quotations" :key="q.quotation_id" class="bg-white dark:bg-gray-800 border rounded-lg shadow-sm p-5 space-y-4">
              <div class="flex justify-between items-start border-b pb-3">
                <div>
                  <h4 class="font-bold text-md text-blue-600 dark:text-blue-400">
                    {{ q.supplier?.supplier_name || 'Nhà cung cấp #' + q.supplier_id }}
                  </h4>
                  <span class="text-xs text-gray-400">Mã nhà cung cấp: {{ q.supplier?.supplier_code }}</span>
                </div>
                <div class="text-right">
                  <span class="text-[10px] uppercase font-bold text-gray-400">Tổng giá trị chào thầu:</span>
                  <p class="text-lg font-black text-green-600 dark:text-green-400">{{ formatCurrency(q.total_amount) }}</p>
                </div>
              </div>

              <!-- Chi tiết vật tư báo giá -->
              <div>
                <table class="w-full text-xs text-left border">
                  <thead class="bg-gray-50 dark:bg-gray-700">
                    <tr>
                      <th class="px-3 py-1.5 border-b">Tên vật tư</th>
                      <th class="px-3 py-1.5 border-b text-right">Số lượng thầu</th>
                      <th class="px-3 py-1.5 border-b text-right">Đơn giá chào</th>
                      <th class="px-3 py-1.5 border-b text-right">Thành tiền</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr v-for="it in q.items" :key="it.quotation_item_id" class="border-b">
                      <td class="px-3 py-1.5 font-medium border-r">{{ it.order_item?.material?.material_name || it.order_item?.material_name_other }}</td>
                      <td class="px-3 py-1.5 text-right border-r font-semibold">{{ parseFloat(it.qty_offered) }}</td>
                      <td class="px-3 py-1.5 text-right border-r">{{ formatCurrency(it.unit_price_offered) }}</td>
                      <td class="px-3 py-1.5 text-right font-semibold">{{ formatCurrency(it.qty_offered * it.unit_price_offered) }}</td>
                    </tr>
                  </tbody>
                </table>
              </div>

              <!-- Button Chọn thắng thầu -->
              <div class="flex justify-end pt-2">
                <span 
                  v-if="q.is_selected" 
                  class="flex items-center gap-1 text-xs font-bold text-green-600 bg-green-50 px-3 py-1 rounded"
                >
                  <BaseIcon :path="mdiStar" /> Đã chọn thắng thầu
                </span>
                <BaseButton 
                  v-else
                  color="success" 
                  :icon="mdiBriefcaseCheck"
                  label="Chọn thắng thầu" 
                  small
                  @click="handleSelectWinner(q.quotation_id)" 
                />
              </div>
            </div>

            <div v-if="quotations.length === 0" class="text-center py-12 text-gray-400 text-sm border-2 border-dashed">
              Chưa có nhà cung cấp nào gửi nộp báo giá cho đơn hàng này.
            </div>
          </div>
        </div>
      </div>
    </SectionMain>
  </LayoutAuthenticated>
</template>
