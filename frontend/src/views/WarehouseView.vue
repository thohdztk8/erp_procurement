<script setup>
import { ref, onMounted } from 'vue'
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
import { warehouseService } from '@/services/api'

const activeTab = ref('inventory')
const inventory = ref([])
const receipts = ref([])
const issues = ref([])
const returns = ref([])
const showReceiptModal = ref(false)
const showIssueModal = ref(false)
const showReturnModal = ref(false)
const showMovementModal = ref(false)
const selectedMaterial = ref(null)

const fetchData = async () => {
  try {
    const invRes = await warehouseService.getInventory()
    inventory.value = invRes.results || []
    const recRes = await warehouseService.getReceipts()
    receipts.value = recRes.results || []
    const issRes = await warehouseService.getIssues()
    issues.value = issRes.results || []
    const retRes = await warehouseService.getReturnOrders()
    returns.value = retRes.results || []
  } catch (error) {
    console.error(error)
  }
}
onMounted(() => fetchData())

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
</script>

<template>
  <LayoutAuthenticated>
    <SectionMain>
      <SectionTitleLineWithButton :icon="mdiWarehouse" title="Kho hàng & Nhập kho (GRN)" main>
        <BaseButton v-if="activeTab === 'inventory'" :icon="mdiPlus" label="Lập Phiếu Nhập Kho (GRN)" color="contrast" small @click="showReceiptModal = true" />
        <BaseButton v-if="activeTab === 'issues'" :icon="mdiPlus" label="Xuất kho cấp phát" color="contrast" small @click="showIssueModal = true" />
        <BaseButton v-slot:default v-if="activeTab === 'returns'" :icon="mdiPlus" label="Yêu cầu hoàn trả NCC" color="contrast" small @click="showReturnModal = true" />
      </SectionTitleLineWithButton>

      <div class="flex space-x-4 mb-4 border-b">
        <button class="pb-2 px-4 text-sm font-semibold transition" :class="activeTab === 'inventory' ? 'border-b-2 border-blue-500 text-blue-600' : 'text-gray-500 hover:text-gray-800'" @click="activeTab = 'inventory'">Tồn kho</button>
        <button class="pb-2 px-4 text-sm font-semibold transition" :class="activeTab === 'receipts' ? 'border-b-2 border-blue-500 text-blue-600' : 'text-gray-500 hover:text-gray-800'" @click="activeTab = 'receipts'">Phiếu nhập (GRN)</button>
        <button class="pb-2 px-4 text-sm font-semibold transition" :class="activeTab === 'issues' ? 'border-b-2 border-blue-500 text-blue-600' : 'text-gray-500 hover:text-gray-800'" @click="activeTab = 'issues'">Xuất kho cấp phát</button>
        <button class="pb-2 px-4 text-sm font-semibold transition" :class="activeTab === 'returns' ? 'border-b-2 border-blue-500 text-blue-600' : 'text-gray-500 hover:text-gray-800'" @click="activeTab = 'returns'">Hoàn trả NCC</button>
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
              <td class="px-6 py-3">{{ new Date(iss.issue_at).toLocaleDateString('vi-VN') }}</td>
              <td class="px-6 py-3 text-right">
                <BaseButton v-if="!iss.is_confirmed" color="success" label="Xác nhận" small @click="handleConfirmIssue(iss.issue_id)" />
                <span v-else class="text-green-600 font-semibold text-xs">Đã nhận</span>
              </td>
            </tr>
          </tbody>
        </table>
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
      </CardBox>
    </SectionMain>

    <WarehouseReceiptModal v-slot:default v-if="showReceiptModal" @close="showReceiptModal = false" @saved="fetchData" />
    <WarehouseIssueModal v-if="showIssueModal" @close="showIssueModal = false" @save="handleSaveIssue" />
    <WarehouseReturnModal v-if="showReturnModal" @close="showReturnModal = false" @save="handleSaveReturn" />
    <StockMovementModal v-if="showMovementModal" :material="selectedMaterial" @close="showMovementModal = false" />
  </LayoutAuthenticated>
</template>
