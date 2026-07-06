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
import CartDetailModal from '@/components/CartDetailModal.vue'
import BasePagination from '@/components/BasePagination.vue'
import { prService, cartOrderService } from '@/services/api'

const activeTab = ref('create-po')
const approvedPrItems = ref([])
const carts = ref([])
const orders = ref([])
const selectedItems = ref([])
const cartTitle = ref('')

const showCartDetailModal = ref(false)
const selectedCartId = ref(null)

const showDetailModal = ref(false)
const selectedOrderId = ref(null)
const isSubmitting = ref(false)

const cartPage = ref(1)
const cartTotalPages = ref(1)
const cartTotalItems = ref(0)

const orderPage = ref(1)
const orderTotalPages = ref(1)
const orderTotalItems = ref(0)

const fetchData = async () => {
  try {
    // 1. Lấy tất cả PR đã duyệt
    const prRes = await prService.getPRs('APPROVED')
    const prs = prRes.data?.items || []

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

    // 2. Lấy danh sách Giỏ hàng
    const cartRes = await cartOrderService.getCarts({ page: cartPage.value })
    carts.value = cartRes.data?.items || []
    cartTotalPages.value = cartRes.data?.pagination?.total_pages || 1
    cartTotalItems.value = cartRes.data?.pagination?.total_items || 0

    // 3. Lấy danh sách PO
    const orderRes = await cartOrderService.getOrders({ page: orderPage.value })
    orders.value = orderRes.data?.items || []
    orderTotalPages.value = orderRes.data?.pagination?.total_pages || 1
    orderTotalItems.value = orderRes.data?.pagination?.total_items || 0
  } catch (error) {
    console.error(error)
  }
}

onMounted(() => {
  fetchData()
})

const changeCartPage = (page) => {
  cartPage.value = page
  fetchData()
}

const changeOrderPage = (page) => {
  orderPage.value = page
  fetchData()
}

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

    alert('Đã gom hàng thành công vào giỏ: ' + cartTitle.value)

    cartTitle.value = ''
    selectedItems.value = []
    activeTab.value = 'cart-list'
    fetchData()
  } catch (error) {
    alert('Gom hàng thất bại. ' + (error.response?.data?.detail || ''))
  } finally {
    isSubmitting.value = false
  }
}

const openPODetail = (id) => {
  selectedOrderId.value = id
  showDetailModal.value = true
}

const openCartDetail = (id) => {
  selectedCartId.value = id
  showCartDetailModal.value = true
}

const handleCartConverted = () => {
  showCartDetailModal.value = false
  activeTab.value = 'po-list'
  fetchData()
}
</script>

<template>
  <SectionMain>
    <SectionTitleLineWithButton :icon="mdiCart" title="Giỏ hàng & Đơn mua hàng (PO)" main />

    <!-- Tabs -->
    <div class="flex space-x-4 mb-4 border-b">
      <button class="pb-2 px-4 text-sm font-semibold transition"
        :class="activeTab === 'create-po' ? 'border-b-2 border-blue-500 text-blue-600' : 'text-gray-500 hover:text-gray-800'"
        @click="activeTab = 'create-po'">
        Gom hàng ({{ approvedPrItems.length }})
      </button>
      <button class="pb-2 px-4 text-sm font-semibold transition"
        :class="activeTab === 'cart-list' ? 'border-b-2 border-blue-500 text-blue-600' : 'text-gray-500 hover:text-gray-800'"
        @click="activeTab = 'cart-list'">
        Giỏ hàng ({{ carts.length }})
      </button>
      <button class="pb-2 px-4 text-sm font-semibold transition"
        :class="activeTab === 'po-list' ? 'border-b-2 border-blue-500 text-blue-600' : 'text-gray-500 hover:text-gray-800'"
        @click="activeTab = 'po-list'">
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
          <BaseButton color="success" label="Tạo Giỏ hàng" :disabled="isSubmitting" @click="handleCreatePO" />
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

    <!-- Tab 2: Danh sách Giỏ hàng -->
    <div v-else-if="activeTab === 'cart-list'">
      <CardBox has-table>
        <table class="w-full text-xs text-left">
          <thead class="bg-gray-100 dark:bg-gray-800">
            <tr>
              <th class="px-6 py-3">ID Giỏ hàng</th>
              <th class="px-6 py-3">Tên tiêu đề</th>
              <th class="px-6 py-3">Người mua (Buyer)</th>
              <th class="px-6 py-3">Ngày lập</th>
              <th class="px-6 py-3 text-right">Thao tác</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="c in carts" :key="c.cart_id" class="border-b">
              <td class="px-6 py-3 font-semibold">{{ c.cart_id }}</td>
              <td class="px-6 py-3">{{ c.cart_title }}</td>
              <td class="px-6 py-3">{{ c.buyer_name }}</td>
              <td class="px-6 py-3">{{ new Date(c.created_at).toLocaleDateString('vi-VN') }}</td>
              <td class="px-6 py-3 text-right">
                <BaseButton color="info" :icon="mdiEye" label="Sửa & Tạo PO" small @click="openCartDetail(c.cart_id)" />
              </td>
            </tr>
            <tr v-if="carts.length === 0">
              <td colspan="5" class="text-center py-8 text-gray-400">Không có giỏ hàng nào.</td>
            </tr>
          </tbody>
        </table>
        <BasePagination :current-page="cartPage" :total-pages="cartTotalPages" :total-items="cartTotalItems"
          @change-page="changeCartPage" />
      </CardBox>
    </div>

    <!-- Tab 3: Danh sách Đơn mua (PO) -->
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
                <BaseButton color="info" :icon="mdiEye" label="Chi tiết / Mời thầu" small
                  @click="openPODetail(o.order_id)" />
              </td>
            </tr>
            <tr v-if="orders.length === 0">
              <td colspan="6" class="text-center py-8 text-gray-400">Không tìm thấy đơn mua hàng nào.</td>
            </tr>
          </tbody>
        </table>
        <BasePagination :current-page="orderPage" :total-pages="orderTotalPages" :total-items="orderTotalItems"
          @change-page="changeOrderPage" />
      </CardBox>
    </div>
  </SectionMain>

  <PODetailModal v-if="showDetailModal" :order-id="selectedOrderId" @close="showDetailModal = false"
    @updated="fetchData" />

  <CartDetailModal v-if="showCartDetailModal" :cart-id="selectedCartId" @close="showCartDetailModal = false"
    @updated="fetchData" @converted="handleCartConverted" />
</template>
