<script setup>
import { ref, onMounted } from 'vue'
import { mdiClose, mdiTrashCan, mdiSend } from '@mdi/js'
import BaseButton from '@/components/BaseButton.vue'
import BaseButtons from '@/components/BaseButtons.vue'
import { cartOrderService } from '@/services/api'

const props = defineProps({
  cartId: {
    type: [Number, String],
    required: true
  }
})

const emit = defineEmits(['close', 'updated', 'converted'])

const cart = ref(null)
const isLoading = ref(true)

const fetchCart = async () => {
  isLoading.value = true
  try {
    const res = await cartOrderService.getCart(props.cartId)
    cart.value = res.data
  } catch (e) {
    alert('Không thể tải chi tiết giỏ hàng.')
  } finally {
    isLoading.value = false
  }
}

onMounted(() => {
  fetchCart()
})

const handleUpdateQty = async (prItemId, newQty) => {
  try {
    await cartOrderService.updateCartItem(props.cartId, prItemId, newQty)
    fetchCart()
    emit('updated')
  } catch (e) {
    alert('Cập nhật thất bại: ' + (e.response?.data?.detail || ''))
    fetchCart() // Reset to old val
  }
}

const handleRemoveItem = async (prItemId) => {
  if (confirm('Bạn muốn xóa vật tư này khỏi giỏ hàng?')) {
    try {
      await cartOrderService.removeCartItem(props.cartId, prItemId)
      fetchCart()
      emit('updated')
    } catch (e) {
      alert('Xóa thất bại.')
    }
  }
}

const handleConvertToPO = async () => {
  if (cart.value.items.length === 0) {
    alert('Giỏ hàng trống, không thể tạo PO.')
    return
  }
  if (confirm('Bạn chắc chắn muốn chuyển giỏ hàng này thành Đơn mua hàng (PO)?')) {
    try {
      const res = await cartOrderService.convertCartToOrder(props.cartId)
      alert(`Đã tạo Đơn mua hàng (PO) số: ${res.data.order_code}`)
      emit('converted')
    } catch (e) {
      alert('Tạo PO thất bại: ' + (e.response?.data?.detail || ''))
    }
  }
}
</script>

<template>
  <div class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4 overflow-y-auto">
    <div class="bg-white dark:bg-gray-900 rounded-lg shadow-xl max-w-4xl w-full max-h-[90vh] overflow-y-auto">
      <div class="flex justify-between items-center px-6 py-4 border-b border-gray-200 dark:border-gray-800">
        <h3 class="text-xl font-bold text-gray-800 dark:text-white">
          Chi tiết Giỏ hàng: {{ cart?.cart_title || 'Đang tải...' }}
        </h3>
        <BaseButton :icon="mdiClose" color="whiteDark" small @click="emit('close')" />
      </div>

      <div class="p-6">
        <div v-if="isLoading" class="text-center py-8">Đang tải dữ liệu...</div>
        <div v-else>
          <table class="w-full text-xs text-left border mb-6">
            <thead class="bg-gray-100 dark:bg-gray-800">
              <tr>
                <th class="px-4 py-2 border-b">Tên vật tư</th>
                <th class="px-4 py-2 border-b text-right">SL Yêu cầu</th>
                <th class="px-4 py-2 border-b text-right">SL trong giỏ</th>
                <th class="px-4 py-2 border-b text-center">Xóa</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="it in cart.items" :key="it.pr_item_id" class="border-b">
                <td class="px-4 py-2 border-r font-medium">{{ it.material_name }}</td>
                <td class="px-4 py-2 border-r text-right">{{ parseFloat(it.qty_requested) }}</td>
                <td class="px-4 py-2 border-r text-right">
                  <input 
                    type="number" 
                    class="w-20 px-2 py-1 border rounded text-right dark:bg-gray-800 dark:border-gray-600"
                    v-model.lazy="it.qty_in_cart"
                    @change="handleUpdateQty(it.pr_item_id, it.qty_in_cart)"
                    min="0.0001"
                    step="1"
                  />
                </td>
                <td class="px-4 py-2 text-center">
                  <BaseButton color="danger" :icon="mdiTrashCan" small @click="handleRemoveItem(it.pr_item_id)" />
                </td>
              </tr>
              <tr v-if="cart.items.length === 0">
                <td colspan="4" class="text-center py-4 text-gray-400">Giỏ hàng này chưa có mặt hàng nào.</td>
              </tr>
            </tbody>
          </table>

          <div class="flex justify-end gap-3 mt-4">
            <BaseButton color="white" label="Đóng" @click="emit('close')" />
            <BaseButton 
              color="success" 
              :icon="mdiSend" 
              label="Tạo Đơn mua hàng (PO)" 
              @click="handleConvertToPO" 
            />
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
