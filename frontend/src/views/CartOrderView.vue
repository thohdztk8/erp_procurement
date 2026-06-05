<script setup>
import { ref, onMounted } from 'vue'
import { mdiCart, mdiClipboardList, mdiEye, mdiSend } from '@mdi/js'
import SectionMain from '@/components/SectionMain.vue'
import CardBox from '@/components/CardBox.vue'
import BaseButton from '@/components/BaseButton.vue'
import BaseButtons from '@/components/BaseButtons.vue'
import FormField from '@/components/FormField.vue'
import FormControl from '@/components/FormControl.vue'
import LayoutAuthenticated from '@/layouts/LayoutAuthenticated.vue'
import SectionTitleLineWithButton from '@/components/SectionTitleLineWithButton.vue'
import PODetailModal from '@/components/PODetailModal.vue'
import { prService, cartOrderService } from '@/services/api'

const activeTab = ref('create-po')
const approvedPrItems = ref([])
const orders = ref([])
const selectedItems = ref([])
const cartTitle = ref('')

const showDetailModal = ref(false)
const selectedOrderId = ref(null)
const isSubmitting = ref(false)

const fetchData = async () => {
  try {
    // 1. Lấy tất cả PR đã duyệt
    const prRes = await prService.getPRs('APPROVED')
    const prs = prRes.results || []
    
    // Gom tất cả các vật tư ở trạng thái PENDING từ các PR đã duyệt
    const items = []
    for (const pr of prs) {
      // Chi tiết PR
      const detailRes = await prService.getPRDetail(pr.pr_id)
      const prDetail = detailRes.data.pr
      for (const item of prDetail.items) {
        if (item.item_status === 'PENDING') {
          items.push({
            ...item,
            pr_code: prDetail.pr_code,
            requester_name: prDetail.requester_name
          })
        }
      }
    }
    approvedPrItems.value = items

    // 2. Lấy danh sách PO
    const orderRes = await cartOrderService.getOrders()
    orders.value = orderRes.results || []
  } catch (error) {
    console.error(error)
  }
}

onMounted(() => {
  fetchData()
})

const handleCreatePO = async () => {
  if (selectedItems.value.length === 0) {
    alert('Vui lòng chọn ít nhất 1 vật tư để gom vào giỏ hàng.')
    return
  }
  if (!cartTitle.value.trim()) {
    alert('Vui lòng nhập tên/tiêu đề giỏ hàng gom hàng.')
    return
  }

  isSubmitting.value = true
  try {
    // 1. Gom hàng vào giỏ
    const cartRes = await cartOrderService.addItemsToCart({
      cart_title: cartTitle.value,
      pr_item_ids: selectedItems.value
    })
    
    // 2. Chuyển giỏ hàng thành PO ngay lập tức
    const orderRes = await cartOrderService.convertCartToOrder(cartRes.data.cart_id)
    alert(`Đã gom hàng thành công và tạo Đơn mua hàng (PO) số: ${orderRes.data.order_code}`)
    
    cartTitle.value = ''
    selectedItems.value = []
    activeTab.value = 'po-list'
    fetchData()
  } catch (error) {
    alert('Gom hàng tạo PO thất bại. ' + (error.response?.data?.detail || ''))
  } finally {
    isSubmitting.value = false
  }
}

const openPODetail = (id) => {
  selectedOrderId.value = id
  showDetailModal.value = true
}
</script>

<template>
  <LayoutAuthenticated>
    <SectionMain>
      <SectionTitleLineWithButton :icon="mdiCart" title="Giỏ hàng & Đơn mua hàng (PO)" main />

      <!-- Tabs -->
      <div class="flex space-x-4 mb-4 border-b">
        <button 
          class="pb-2 px-4 text-sm font-semibold transition"
          :class="activeTab === 'create-po' ? 'border-b-2 border-blue-500 text-blue-600' : 'text-gray-500 hover:text-gray-800'"
          @click="activeTab = 'create-po'"
        >
          Gom hàng tạo PO ({{ approvedPrItems.length }})
        </button>
        <button 
          class="pb-2 px-4 text-sm font-semibold transition"
          :class="activeTab === 'po-list' ? 'border-b-2 border-blue-500 text-blue-600' : 'text-gray-500 hover:text-gray-800'"
          @click="activeTab = 'po-list'"
        >
          Danh sách Đơn mua (PO) ({{ orders.length }})
        </button>
      </div>

      <!-- Tab 1: Gom hàng tạo PO -->
      <div v-if="activeTab === 'create-po'" class="space-y-4">
        <CardBox class="p-4 bg-gray-50 dark:bg-gray-800">
          <h4 class="text-sm font-bold mb-3">Tạo phiên gom hàng (Procurement Cart)</h4>
          <div class="flex gap-4 items-end">
            <FormField label="Tên tiêu đề giỏ hàng" class="flex-grow">
              <FormControl v-model="cartTitle" placeholder="Ví dụ: Gom mua vật tư chi nhánh HN tháng 6..." />
            </FormField>
            <BaseButton 
              color="success" 
              label="Tạo PO từ mục đã chọn" 
              :disabled="isSubmitting" 
              @click="handleCreatePO" 
            />
          </div>
        </CardBox>

        <CardBox has-table>
          <table class="w-full text-xs text-left">
            <thead class="bg-gray-100 dark:bg-gray-800">
              <tr>
                <th class="px-6 py-3 w-10">Chọn</th>
                <th class="px-6 py-3">Mã PR</th>
                <th class="px-6 py-3">Tên vật tư</th>
                <th class="px-6 py-3 text-right">Số lượng yêu cầu</th>
                <th class="px-6 py-3">Người yêu cầu</th>
                <th class="px-6 py-3">Hạn cần hàng</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="it in approvedPrItems" :key="it.pr_item_id" class="border-b">
                <td class="px-6 py-3">
                  <input type="checkbox" :value="it.pr_item_id" v-model="selectedItems" class="rounded text-blue-600" />
                </td>
                <td class="px-6 py-3 font-semibold">{{ it.pr_code }}</td>
                <td class="px-6 py-3 font-medium text-gray-900 dark:text-white">{{ it.material_name }}</td>
                <td class="px-6 py-3 text-right font-semibold">{{ parseFloat(it.qty_requested) }}</td>
                <td class="px-6 py-3">{{ it.requester_name }}</td>
                <td class="px-6 py-3">{{ new Date(it.required_deadline).toLocaleDateString('vi-VN') }}</td>
              </tr>
              <tr v-if="approvedPrItems.length === 0">
                <td colspan="6" class="text-center py-8 text-gray-400">Không có vật tư nào đã duyệt cần gom mua.</td>
              </tr>
            </tbody>
          </table>
        </CardBox>
      </div>

      <!-- Tab 2: Danh sách Đơn mua (PO) -->
      <div v-else>
        <CardBox has-table>
          <table class="w-full text-xs text-left">
            <thead class="bg-gray-100 dark:bg-gray-800">
              <tr>
                <th class="px-6 py-3">Mã đơn PO</th>
                <th class="px-6 py-3">Người mua hàng (Buyer)</th>
                <th class="px-6 py-3">Số lượng mặt hàng</th>
                <th class="px-6 py-3">Trạng thái</th>
                <th class="px-6 py-3">Ngày lập</th>
                <th class="px-6 py-3 text-right">Thao tác</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="o in orders" :key="o.order_id" class="border-b">
                <td class="px-6 py-3 font-semibold">{{ o.order_code }}</td>
                <td class="px-6 py-3">{{ o.buyer_name }}</td>
                <td class="px-6 py-3 font-bold">{{ o.item_count }}</td>
                <td class="px-6 py-3 font-semibold text-blue-600">{{ o.order_status }}</td>
                <td class="px-6 py-3">{{ new Date(o.created_at).toLocaleDateString('vi-VN') }}</td>
                <td class="px-6 py-3 text-right">
                  <BaseButton color="info" :icon="mdiEye" label="Chi tiết / Mời thầu" small @click="openPODetail(o.order_id)" />
                </td>
              </tr>
              <tr v-if="orders.length === 0">
                <td colspan="6" class="text-center py-8 text-gray-400">Không tìm thấy đơn mua hàng nào.</td>
              </tr>
            </tbody>
          </table>
        </CardBox>
      </div>
    </SectionMain>

    <PODetailModal 
      v-if="showDetailModal" 
      :order-id="selectedOrderId" 
      @close="showDetailModal = false" 
      @updated="fetchData" 
    />
  </LayoutAuthenticated>
</template>
