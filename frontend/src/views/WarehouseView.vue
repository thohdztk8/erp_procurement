<script setup>
import { ref, onMounted, computed } from 'vue'
import { mdiWarehouse, mdiPlus, mdiHistory } from '@mdi/js'
import SectionMain from '@/components/SectionMain.vue'
import CardBox from '@/components/CardBox.vue'
import BaseButton from '@/components/BaseButton.vue'
import LayoutAuthenticated from '@/layouts/LayoutAuthenticated.vue'
import SectionTitleLineWithButton from '@/components/SectionTitleLineWithButton.vue'
import WarehouseReceiptModal from '@/components/WarehouseReceiptModal.vue'
import WarehouseIssueModal from '@/components/WarehouseIssueModal.vue'
import WarehouseReturnModal from '@/components/WarehouseReturnModal.vue'
import StockMovementModal from '@/components/StockMovementModal.vue'
import BasePagination from '@/components/BasePagination.vue'
import { warehouseService } from '@/services/api'
import { useMainStore } from '@/stores/main'

const mainStore = useMainStore()

const hasInventoryPermission = computed(() => {
  if (mainStore.userRole === 'ADMIN') return true
  return mainStore.userPermissions.includes('WH_INVENTORY_VIEW')
})
const hasReceiptPermission = computed(() => {
  if (mainStore.userRole === 'ADMIN') return true
  return mainStore.userPermissions.includes('WH_RECEIPT_CREATE')
})
const hasIssuePermission = computed(() => {
  if (mainStore.userRole === 'ADMIN') return true
  return mainStore.userPermissions.includes('WH_ISSUE_CREATE')
})
const hasReturnPermission = computed(() => {
  if (mainStore.userRole === 'ADMIN') return true
  return mainStore.userPermissions.includes('WH_RETURN_CREATE')
})

const activeTab = ref('inventory')
const inventory = ref([])
const receipts = ref([])
const issues = ref([])
const returns = ref([])

const inventoryPage = ref(1)
const inventoryTotalPages = ref(1)
const inventoryTotalItems = ref(0)

const receiptPage = ref(1)
const receiptTotalPages = ref(1)
const receiptTotalItems = ref(0)

const issuePage = ref(1)
const issueTotalPages = ref(1)
const issueTotalItems = ref(0)

const returnPage = ref(1)
const returnTotalPages = ref(1)
const returnTotalItems = ref(0)

const showReceiptModal = ref(false)
const showIssueModal = ref(false)
const showReturnModal = ref(false)
const showMovementModal = ref(false)
const selectedMaterial = ref(null)

const fetchData = async () => {
  if (hasInventoryPermission.value) {
    try {
      const invRes = await warehouseService.getInventory({ page: inventoryPage.value })
      inventory.value = invRes.data.items || []
      inventoryTotalPages.value = invRes.data.pagination?.total_pages || 1
      inventoryTotalItems.value = invRes.data.pagination?.total_items || 0
    } catch (error) {
      console.error('Error fetching inventory:', error)
    }
  }

  if (hasReceiptPermission.value) {
    try {
      const recRes = await warehouseService.getReceipts({ page: receiptPage.value })
      receipts.value = recRes.data.items || []
      receiptTotalPages.value = recRes.data.pagination?.total_pages || 1
      receiptTotalItems.value = recRes.data.pagination?.total_items || 0
    } catch (error) {
      console.error('Error fetching receipts:', error)
    }
  }

  if (hasIssuePermission.value) {
    try {
      const issRes = await warehouseService.getIssues({ page: issuePage.value })
      issues.value = issRes.data.items || []
      issueTotalPages.value = issRes.data.pagination?.total_pages || 1
      issueTotalItems.value = issRes.data.pagination?.total_items || 0
    } catch (error) {
      console.error('Error fetching issues:', error)
    }
  }

  if (hasReturnPermission.value) {
    try {
      const retRes = await warehouseService.getReturnOrders({ page: returnPage.value })
      returns.value = retRes.data.items || []
      returnTotalPages.value = retRes.data.pagination?.total_pages || 1
      returnTotalItems.value = retRes.data.pagination?.total_items || 0
    } catch (error) {
      console.error('Error fetching returns:', error)
    }
  }
}

onMounted(() => {
  if (hasInventoryPermission.value) {
    activeTab.value = 'inventory'
  } else if (hasReceiptPermission.value) {
    activeTab.value = 'receipts'
  } else if (hasIssuePermission.value) {
    activeTab.value = 'issues'
  } else if (hasReturnPermission.value) {
    activeTab.value = 'returns'
  }
  fetchData()
})

const handleSaveIssue = async (data) => {
  try {
    await warehouseService.createIssue(data)
    showIssueModal.value = false
    fetchData()
  } catch (e) {
    alert('Không thể xuất kho. Kiểm tra số lượng tồn kho khả dụng!')
  }
}
const handleSaveReturn = async (data) => {
  try {
    await warehouseService.createReturnOrder(data)
    showReturnModal.value = false
    fetchData()
  } catch (e) {
    alert('Không thể tạo phiếu hoàn trả nhà cung cấp.')
  }
}
const handleConfirmIssue = async (issueId) => {
  const ratingStr = prompt('Đánh giá chất lượng cấp phát (1-5 sao):', '5')
  if (!ratingStr) return
  const comment = prompt('Nhập ý kiến phản hồi:')
  try {
    await warehouseService.confirmIssueReceipt(issueId, {
      items_quality_rating: [{ quality_rating: parseInt(ratingStr), comment }],
      overall_status: 'ACCEPTED'
    })
    alert('Đã xác nhận nhận hàng cấp phát thành công!')
    fetchData()
  } catch (e) {
    alert('Xác nhận thất bại.')
  }
}
const handleUpdateReturnStatus = async (returnId) => {
  try {
    await warehouseService.updateReturnStatus(returnId, { new_status: 'SENT', note: 'Đã hoàn trả thành công' })
    alert('Đã cập nhật trạng thái hoàn trả!')
    fetchData()
  } catch (e) {
    alert('Cập nhật trạng thái thất bại.')
  }
}

const changeInventoryPage = (page) => {
  inventoryPage.value = page
  fetchData()
}
const changeReceiptPage = (page) => {
  receiptPage.value = page
  fetchData()
}
const changeIssuePage = (page) => {
  issuePage.value = page
  fetchData()
}
const changeReturnPage = (page) => {
  returnPage.value = page
  fetchData()
}
</script>

<template>
  <LayoutAuthenticated>
    <SectionMain>
      <SectionTitleLineWithButton :icon="mdiWarehouse" title="Kho hàng & Nhập kho (GRN)" main>
        <BaseButton v-if="activeTab === 'inventory' && hasReceiptPermission" :icon="mdiPlus" label="Lập Phiếu Nhập Kho (GRN)" color="contrast" small @click="showReceiptModal = true" />
        <BaseButton v-if="activeTab === 'issues' && hasIssuePermission" :icon="mdiPlus" label="Xuất kho cấp phát" color="contrast" small @click="showIssueModal = true" />
        <BaseButton v-slot:default v-if="activeTab === 'returns' && hasReturnPermission" :icon="mdiPlus" label="Yêu cầu hoàn trả NCC" color="contrast" small @click="showReturnModal = true" />
      </SectionTitleLineWithButton>

      <div class="flex space-x-4 mb-4 border-b">
        <button v-if="hasInventoryPermission" class="pb-2 px-4 text-sm font-semibold transition" :class="activeTab === 'inventory' ? 'border-b-2 border-blue-500 text-blue-600' : 'text-gray-500 hover:text-gray-800'" @click="activeTab = 'inventory'">Tồn kho</button>
        <button v-if="hasReceiptPermission" class="pb-2 px-4 text-sm font-semibold transition" :class="activeTab === 'receipts' ? 'border-b-2 border-blue-500 text-blue-600' : 'text-gray-500 hover:text-gray-800'" @click="activeTab = 'receipts'">Phiếu nhập (GRN)</button>
        <button v-if="hasIssuePermission" class="pb-2 px-4 text-sm font-semibold transition" :class="activeTab === 'issues' ? 'border-b-2 border-blue-500 text-blue-600' : 'text-gray-500 hover:text-gray-800'" @click="activeTab = 'issues'">Xuất kho cấp phát</button>
        <button v-if="hasReturnPermission" class="pb-2 px-4 text-sm font-semibold transition" :class="activeTab === 'returns' ? 'border-b-2 border-blue-500 text-blue-600' : 'text-gray-500 hover:text-gray-800'" @click="activeTab = 'returns'">Hoàn trả NCC</button>
      </div>

      <CardBox v-if="activeTab === 'inventory'" has-table class="mb-6">
        <table class="w-full text-xs text-left">
          <thead class="bg-gray-100 dark:bg-gray-800">
            <tr>
              <th class="px-6 py-3">Mã vật tư</th>
              <th class="px-6 py-3">Tên vật tư</th>
              <th class="px-6 py-3 text-right">Khả dụng</th>
              <th class="px-6 py-3 text-right">Tạm giữ</th>
              <th class="px-6 py-3 text-right">Thao tác</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="inv in inventory" :key="inv.inventory_id" class="border-b">
              <td class="px-6 py-3 font-semibold">{{ inv.material_code }}</td>
              <td class="px-6 py-3 font-medium">{{ inv.material_name }}</td>
              <td class="px-6 py-3 text-right font-bold text-green-600">{{ parseFloat(inv.qty_available) }}</td>
              <td class="px-6 py-3 text-right font-bold text-yellow-600">{{ parseFloat(inv.qty_quarantine) }}</td>
              <td class="px-6 py-3 text-right">
                <BaseButton :icon="mdiHistory" color="info" label="Thẻ kho" small @click="selectedMaterial = inv; showMovementModal = true" />
              </td>
            </tr>
          </tbody>
        </table>
        <BasePagination
          :current-page="inventoryPage"
          :total-pages="inventoryTotalPages"
          :total-items="inventoryTotalItems"
          @change-page="changeInventoryPage"
        />
      </CardBox>

      <CardBox v-else-if="activeTab === 'receipts'" has-table class="mb-6">
        <table class="w-full text-xs text-left">
          <thead class="bg-gray-100 dark:bg-gray-800">
            <tr>
              <th class="px-6 py-3">Mã phiếu</th>
              <th class="px-6 py-3">Hợp đồng (IPO)</th>
              <th class="px-6 py-3">Biên bản nhận</th>
              <th class="px-6 py-3">Ngày nhận</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="rec in receipts" :key="rec.receipt_id" class="border-b">
              <td class="px-6 py-3 font-bold text-blue-600">{{ rec.receipt_code }}</td>
              <td class="px-6 py-3">{{ rec.associated_ipo_code || rec.ipo_id }}</td>
              <td class="px-6 py-3">{{ rec.delivery_note_ref }}</td>
              <td class="px-6 py-3">{{ new Date(rec.received_at).toLocaleDateString('vi-VN') }}</td>
            </tr>
          </tbody>
        </table>
        <BasePagination
          :current-page="receiptPage"
          :total-pages="receiptTotalPages"
          :total-items="receiptTotalItems"
          @change-page="changeReceiptPage"
        />
      </CardBox>

      <CardBox v-else-if="activeTab === 'issues'" has-table class="mb-6">
        <table class="w-full text-xs text-left">
          <thead class="bg-gray-100 dark:bg-gray-800">
            <tr>
              <th class="px-6 py-3">Mã phiếu</th>
              <th class="px-6 py-3">PR liên kết</th>
              <th class="px-6 py-3">Ngày xuất</th>
              <th class="px-6 py-3 text-right">Thao tác</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="iss in issues" :key="iss.issue_id" class="border-b">
              <td class="px-6 py-3 font-bold text-blue-600">{{ iss.issue_code }}</td>
              <td class="px-6 py-3">PR#{{ iss.pr_id || '-' }}</td>
              <td class="px-6 py-3">{{ new Date(iss.issued_at).toLocaleDateString('vi-VN') }}</td>
              <td class="px-6 py-3 text-right">
                <BaseButton v-if="!iss.is_confirmed" color="success" label="Xác nhận" small @click="handleConfirmIssue(iss.issue_id)" />
                <span v-else class="text-gray-500 font-semibold text-xs">Đã nhận</span>
              </td>
            </tr>
          </tbody>
        </table>
        <BasePagination
          :current-page="issuePage"
          :total-pages="issueTotalPages"
          :total-items="issueTotalItems"
          @change-page="changeIssuePage"
        />
      </CardBox>

      <CardBox v-else-if="activeTab === 'returns'" has-table class="mb-6">
        <table class="w-full text-xs text-left">
          <thead class="bg-gray-100 dark:bg-gray-800">
            <tr>
              <th class="px-6 py-3">Mã phiếu</th>
              <th class="px-6 py-3">Lý do</th>
              <th class="px-6 py-3">Trạng thái</th>
              <th class="px-6 py-3 text-right">Thao tác</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="ret in returns" :key="ret.return_id" class="border-b">
              <td class="px-6 py-3 font-bold text-blue-600">{{ ret.return_code }}</td>
              <td class="px-6 py-3 font-semibold text-red-500">{{ ret.reason_category }}</td>
              <td class="px-6 py-3">{{ ret.return_status }}</td>
              <td class="px-6 py-3 text-right">
                <BaseButton v-if="ret.return_status === 'DRAFT'" color="warning" label="Xác nhận gửi" small @click="handleUpdateReturnStatus(ret.return_id)" />
                <span v-else class="text-gray-400">-</span>
              </td>
            </tr>
          </tbody>
        </table>
        <BasePagination
          :current-page="returnPage"
          :total-pages="returnTotalPages"
          :total-items="returnTotalItems"
          @change-page="changeReturnPage"
        />
      </CardBox>
    </SectionMain>

    <WarehouseReceiptModal v-slot:default v-if="showReceiptModal" @close="showReceiptModal = false" @saved="fetchData" />
    <WarehouseIssueModal v-if="showIssueModal" @close="showIssueModal = false" @save="handleSaveIssue" />
    <WarehouseReturnModal v-if="showReturnModal" @close="showReturnModal = false" @save="handleSaveReturn" />
    <StockMovementModal v-if="showMovementModal" :material="selectedMaterial" @close="showMovementModal = false" />
  </LayoutAuthenticated>
</template>
