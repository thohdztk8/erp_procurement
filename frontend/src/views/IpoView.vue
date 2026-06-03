<script setup>
import { ref, onMounted, computed } from 'vue'
import { mdiFileDocument, mdiEye, mdiSend } from '@mdi/js'
import SectionMain from '@/components/SectionMain.vue'
import CardBox from '@/components/CardBox.vue'
import BaseButton from '@/components/BaseButton.vue'
import BaseButtons from '@/components/BaseButtons.vue'
import LayoutAuthenticated from '@/layouts/LayoutAuthenticated.vue'
import SectionTitleLineWithButton from '@/components/SectionTitleLineWithButton.vue'
import IPODetailModal from '@/components/IPODetailModal.vue'
import { ipoService } from '@/services/api'

const ipos = ref([])
const activeTab = ref('all') // 'all' or 'pending'
const showDetailModal = ref(false)
const selectedIpoId = ref(null)
const showApproveForm = ref(false)
const currentUser = ref(JSON.parse(localStorage.getItem('user') || '{}'))

const fetchIPOs = async () => {
  try {
    const res = await ipoService.getIPOs()
    ipos.value = res.results || []
  } catch (error) {
    console.error(error)
  }
}

onMounted(() => {
  fetchIPOs()
})

const handleView = (id, approveMode = false) => {
  selectedIpoId.value = id
  showApproveForm.value = approveMode
  showDetailModal.value = true
}

const handleSubmit = async (id) => {
  if (!confirm('Bạn chắc chắn nộp phê duyệt hợp đồng này chứ?')) return
  try {
    await ipoService.submitIPO(id)
    alert('Nộp phê duyệt hợp đồng thành công!')
    fetchIPOs()
  } catch (e) {
    alert('Nộp duyệt thất bại. ' + (e.response?.data?.detail || ''))
  }
}

const isApproverRole = computed(() => {
  return currentUser.value.permissions?.includes('IPO_APPROVE') || currentUser.value.username === 'admin'
})

const filteredIPOs = computed(() => {
  if (activeTab.value === 'all') {
    return ipos.value
  }
  return ipos.value.filter(i => i.ipo_status === 'PENDING')
})

const formatCurrency = (val) => {
  return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(val || 0)
}
</script>

<template>
  <LayoutAuthenticated>
    <SectionMain>
      <SectionTitleLineWithButton :icon="mdiFileDocument" title="Hợp đồng mua sắm (IPO)" main />

      <!-- Tabs -->
      <div class="flex space-x-4 mb-4 border-b">
        <button 
          class="pb-2 px-4 text-sm font-semibold transition"
          :class="activeTab === 'all' ? 'border-b-2 border-blue-500 text-blue-600' : 'text-gray-500 hover:text-gray-800'"
          @click="activeTab = 'all'"
        >
          Tất cả hợp đồng ({{ ipos.length }})
        </button>
        <button 
          v-if="isApproverRole"
          class="pb-2 px-4 text-sm font-semibold transition"
          :class="activeTab === 'pending' ? 'border-b-2 border-blue-500 text-blue-600' : 'text-gray-500 hover:text-gray-800'"
          @click="activeTab = 'pending'"
        >
          Chờ phê duyệt ({{ ipos.filter(i => i.ipo_status === 'PENDING').length }})
        </button>
      </div>

      <!-- Bảng danh sách hợp đồng IPO -->
      <CardBox has-table>
        <table class="w-full text-xs text-left">
          <thead class="bg-gray-100 dark:bg-gray-800">
            <tr>
              <th class="px-6 py-3">Mã hợp đồng</th>
              <th class="px-6 py-3">Giá trị hợp đồng</th>
              <th class="px-6 py-3">Trạng thái</th>
              <th class="px-6 py-3">Ngày lập</th>
              <th class="px-6 py-3 text-right">Thao tác</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="i in filteredIPOs" :key="i.ipo_id" class="border-b">
              <td class="px-6 py-3 font-semibold">{{ i.ipo_code }}</td>
              <td class="px-6 py-3 font-bold text-green-600">{{ formatCurrency(i.total_amount) }}</td>
              <td class="px-6 py-3 font-semibold text-blue-600">{{ i.ipo_status }}</td>
              <td class="px-6 py-3">{{ new Date(i.created_at).toLocaleDateString('vi-VN') }}</td>
              <td class="px-6 py-3 text-right">
                <BaseButtons type="justify-end" no-wrap>
                  <BaseButton color="info" :icon="mdiEye" label="Chi tiết" small @click="handleView(i.ipo_id, false)" />
                  <BaseButton 
                    v-if="i.ipo_status === 'DRAFT'" 
                    color="success" 
                    :icon="mdiSend" 
                    label="Nộp duyệt" 
                    small 
                    @click="handleSubmit(i.ipo_id)" 
                  />
                  <BaseButton 
                    v-if="i.ipo_status === 'PENDING' && isApproverRole" 
                    color="warning" 
                    label="Phê duyệt" 
                    small 
                    @click="handleView(i.ipo_id, true)" 
                  />
                </BaseButtons>
              </td>
            </tr>
            <tr v-if="filteredIPOs.length === 0">
              <td colspan="5" class="text-center py-8 text-gray-400">Không tìm thấy hợp đồng nào.</td>
            </tr>
          </tbody>
        </table>
      </CardBox>
    </SectionMain>

    <IPODetailModal 
      v-if="showDetailModal" 
      :ipo-id="selectedIpoId" 
      :show-approve-form="showApproveForm"
      @close="showDetailModal = false" 
      @updated="fetchIPOs" 
    />
  </LayoutAuthenticated>
</template>
