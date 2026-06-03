<script setup>
import { ref, onMounted } from 'vue'
import { mdiWarehouse, mdiPlus, mdiHistory } from '@mdi/js'
import SectionMain from '@/components/SectionMain.vue'
import CardBox from '@/components/CardBox.vue'
import BaseButton from '@/components/BaseButton.vue'
import LayoutAuthenticated from '@/layouts/LayoutAuthenticated.vue'
import SectionTitleLineWithButton from '@/components/SectionTitleLineWithButton.vue'
import WarehouseReceiptModal from '@/components/WarehouseReceiptModal.vue'
import { warehouseService } from '@/services/api'

const activeTab = ref('inventory')
const inventory = ref([])
const showReceiptModal = ref(false)
const isLoading = ref(false)

const fetchInventory = async () => {
  isLoading.value = true
  try {
    const res = await warehouseService.getInventory()
    inventory.value = res.results || []
  } catch (error) {
    console.error(error)
  } finally {
    isLoading.value = false
  }
}

onMounted(() => {
  fetchInventory()
})
</script>

<template>
  <LayoutAuthenticated>
    <SectionMain>
      <SectionTitleLineWithButton :icon="mdiWarehouse" title="Kho hàng & Nhập kho (GRN)" main>
        <BaseButton 
          :icon="mdiPlus" 
          label="Lập Phiếu Nhập Kho (GRN)" 
          color="contrast" 
          rounded-full 
          small 
          @click="showReceiptModal = true" 
        />
      </SectionTitleLineWithButton>

      <!-- Tabs -->
      <div class="flex space-x-4 mb-4 border-b">
        <button 
          class="pb-2 px-4 text-sm font-semibold transition"
          :class="activeTab === 'inventory' ? 'border-b-2 border-blue-500 text-blue-600' : 'text-gray-500 hover:text-gray-800'"
          @click="activeTab = 'inventory'"
        >
          Tồn kho hiện tại
        </button>
      </div>

      <!-- Bảng tồn kho -->
      <div v-if="activeTab === 'inventory'">
        <CardBox has-table>
          <div v-if="isLoading" class="text-center py-12 text-sm text-gray-400">Đang tải thông tin tồn kho...</div>
          <table v-else class="w-full text-xs text-left">
            <thead class="bg-gray-100 dark:bg-gray-800">
              <tr>
                <th class="px-6 py-3">Mã vật tư</th>
                <th class="px-6 py-3">Tên vật tư</th>
                <th class="px-6 py-3">Đơn vị tính</th>
                <th class="px-6 py-3 text-right">Số lượng khả dụng</th>
                <th class="px-6 py-3 text-right">Số lượng tạm giữ</th>
                <th class="px-6 py-3">Cập nhật lần cuối</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="inv in inventory" :key="inv.inventory_id" class="border-b">
                <td class="px-6 py-3 font-semibold">{{ inv.material_code }}</td>
                <td class="px-6 py-3 font-medium text-gray-900 dark:text-white">{{ inv.material_name }}</td>
                <td class="px-6 py-3">{{ inv.uom }}</td>
                <td class="px-6 py-3 text-right font-bold text-green-600">{{ parseFloat(inv.qty_available) }}</td>
                <td class="px-6 py-3 text-right font-bold text-yellow-600">{{ parseFloat(inv.qty_quarantine) }}</td>
                <td class="px-6 py-3">{{ new Date(inv.last_updated).toLocaleString('vi-VN') }}</td>
              </tr>
              <tr v-if="inventory.length === 0">
                <td colspan="6" class="text-center py-8 text-gray-400">Không tìm thấy dữ liệu tồn kho.</td>
              </tr>
            </tbody>
          </table>
        </CardBox>
      </div>
    </SectionMain>

    <WarehouseReceiptModal 
      v-if="showReceiptModal" 
      @close="showReceiptModal = false" 
      @saved="fetchInventory" 
    />
  </LayoutAuthenticated>
</template>
