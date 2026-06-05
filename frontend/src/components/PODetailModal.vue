<script setup>
import { ref, onMounted } from 'vue'
import { mdiClose, mdiPlus } from '@mdi/js'
import BaseButton from '@/components/BaseButton.vue'
import BaseButtons from '@/components/BaseButtons.vue'
import FormField from '@/components/FormField.vue'
import FormControl from '@/components/FormControl.vue'
import { cartOrderService, masterService } from '@/services/api'

const props = defineProps({
  orderId: {
    type: Number,
    required: true,
  }
})

const emit = defineEmits(['close', 'updated'])

const order = ref(null)
const suppliersList = ref([])
const selectedSupplier = ref(null)
const isSubmitting = ref(false)

const fetchOrderDetail = async () => {
  try {
    const res = await cartOrderService.getOrderDetail(props.orderId)
    order.value = res.data
  } catch (error) {
    console.error(error)
  }
}

const fetchSuppliers = async () => {
  try {
    const res = await masterService.getSuppliers()
    suppliersList.value = res.results || []
  } catch (error) {
    console.error(error)
  }
}

onMounted(() => {
  fetchOrderDetail()
  fetchSuppliers()
})

const handleAddSupplier = async () => {
  if (!selectedSupplier.value) return
  isSubmitting.value = true
  try {
    // API expects a list of supplier ids
    await cartOrderService.addSuppliersToOrder(props.orderId, [selectedSupplier.value])
    fetchOrderDetail()
    emit('updated')
  } catch (e) {
    alert('Thêm nhà cung cấp thất bại.')
  } finally {
    isSubmitting.value = false
  }
}

const formatCurrency = (val) => {
  return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(val || 0)
}
</script>

<template>
  <div class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4 overflow-y-auto">
    <div v-if="order" class="bg-white dark:bg-gray-900 rounded-lg shadow-xl max-w-3xl w-full max-h-[85vh] overflow-y-auto">
      <!-- Header -->
      <div class="flex justify-between items-center px-6 py-4 border-b border-gray-200 dark:border-gray-800">
        <h3 class="text-xl font-bold text-gray-800 dark:text-white">
          Đơn mua hàng: {{ order.order_code }}
        </h3>
        <BaseButton :icon="mdiClose" color="whiteDark" small @click="emit('close')" />
      </div>

      <!-- Body -->
      <div class="p-6 space-y-6 text-sm">
        <div class="grid grid-cols-2 gap-4 bg-gray-50 dark:bg-gray-800 p-4 rounded">
          <div><span class="text-gray-400">Trạng thái:</span> <b class="text-blue-600">{{ order.order_status }}</b></div>
          <div><span class="text-gray-400">Người mua hàng (Buyer):</span> {{ order.buyer_name }}</div>
          <div><span class="text-gray-400">Ngày lập đơn:</span> {{ new Date(order.created_at).toLocaleDateString('vi-VN') }}</div>
        </div>

        <!-- Items -->
        <div>
          <h4 class="text-sm font-bold text-gray-700 dark:text-gray-300 mb-2">Chi tiết mặt hàng</h4>
          <table class="w-full text-xs text-left border">
            <thead class="bg-gray-50 dark:bg-gray-800">
              <tr>
                <th class="px-4 py-2 border-b">Tên vật tư</th>
                <th class="px-4 py-2 border-b text-right">Số lượng đặt hàng</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="it in order.items" :key="it.order_item_id" class="border-b">
                <td class="px-4 py-2 border-r font-medium text-gray-900 dark:text-white">
                  {{ it.material_name }}
                </td>
                <td class="px-4 py-2 text-right font-bold">{{ parseFloat(it.qty_total_ordered) }}</td>
              </tr>
            </tbody>
          </table>
        </div>

        <!-- Bidding Suppliers -->
        <div>
          <h4 class="text-sm font-bold text-gray-700 dark:text-gray-300 mb-2">Nhà cung cấp tham gia báo giá</h4>
          <ul class="space-y-1.5 mb-4">
            <li 
              v-for="s in order.suppliers" 
              :key="s.supplier__supplier_id" 
              class="flex justify-between bg-gray-50 dark:bg-gray-800 p-2 rounded text-xs"
            >
              <span>{{ s.supplier__supplier_name }}</span>
              <span class="text-gray-400">Mời lúc: {{ new Date(s.assigned_at).toLocaleDateString('vi-VN') }}</span>
            </li>
            <li v-if="order.suppliers.length === 0" class="text-gray-400 text-center py-2 text-xs">
              Chưa có nhà cung cấp nào được mời báo giá cho đơn này.
            </li>
          </ul>

          <!-- Thêm NCC -->
          <div v-if="order.order_status === 'DRAFT' || order.order_status === 'BIDDING'" class="flex gap-2 items-end border-t pt-4">
            <FormField label="Mời thêm nhà cung cấp" class="flex-grow">
              <FormControl 
                v-model="selectedSupplier" 
                type="select" 
                :options="suppliersList.map(s => ({ id: s.supplier_id, label: `${s.supplier_code} - ${s.supplier_name}` }))" 
              />
            </FormField>
            <BaseButton 
              color="info" 
              :icon="mdiPlus" 
              label="Mời" 
              :disabled="isSubmitting || !selectedSupplier" 
              @click="handleAddSupplier" 
            />
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
