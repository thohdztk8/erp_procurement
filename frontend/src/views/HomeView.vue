<script setup>
import { ref, onMounted, computed } from 'vue'
import { mdiChartTimelineVariant, mdiPlus, mdiNotebook, mdiAccountMultiple } from '@mdi/js'
import SectionMain from '@/components/SectionMain.vue'
import CardBoxWidget from '@/components/CardBoxWidget.vue'
import CardBox from '@/components/CardBox.vue'
import BaseButton from '@/components/BaseButton.vue'
import LayoutAuthenticated from '@/layouts/LayoutAuthenticated.vue'
import SectionTitleLineWithButton from '@/components/SectionTitleLineWithButton.vue'
import PRTable from '@/components/PRTable.vue'
import PRDetailModal from '@/components/PRDetailModal.vue'
import PRCreateModal from '@/components/PRCreateModal.vue'
import { prService } from '@/services/api'

const prs = ref([])
const pendingPrs = ref([])
const stats = ref({ total: 0, draft: 0, pending: 0, approved: 0 })
const activeTab = ref('all') // 'all' hoặc 'pending'

const showCreateModal = ref(false)
const showDetailModal = ref(false)
const prDetailData = ref(null)
const currentUser = ref(JSON.parse(localStorage.getItem('user') || '{}'))

const fetchPRs = async () => {
  try {
    const response = await prService.getPRs()
    prs.value = response.results || []
    
    // Tính toán số liệu thống kê
    stats.value.total = prs.value.length
    stats.value.draft = prs.value.filter(p => p.pr_status === 'DRAFT').length
    stats.value.pending = prs.value.filter(p => p.pr_status === 'PENDING').length
    stats.value.approved = prs.value.filter(p => p.pr_status === 'APPROVED').length

    // Nếu user có quyền duyệt, lấy danh sách chờ duyệt
    const isApprover = currentUser.value.permissions?.includes('PR_APPROVE') || currentUser.value.username === 'admin'
    if (isApprover) {
      const pendingRes = await prService.getPendingPRs()
      pendingPrs.value = pendingRes.results || []
    }
  } catch (error) {
    console.error(error)
  }
}

onMounted(() => {
  fetchPRs()
})

const handleView = async (id) => {
  try {
    const res = await prService.getPRDetail(id)
    prDetailData.value = res.data
    showDetailModal.value = true
  } catch (error) {
    alert('Không lấy được chi tiết đơn PR.')
  }
}

const handleSubmit = async (id) => {
  if (confirm('Bạn chắc chắn muốn nộp yêu cầu mua sắm này lên cấp trên phê duyệt chứ?')) {
    try {
      await prService.submitPR(id)
      fetchPRs()
    } catch (e) {
      alert('Nộp duyệt thất bại. ' + (e.response?.data?.detail || ''))
    }
  }
}

const handleApprove = async (payload) => {
  try {
    await prService.approvePR(payload.pr_id, payload.action, payload.comment)
    showDetailModal.value = false
    fetchPRs()
  } catch (e) {
    alert('Phê duyệt thất bại. ' + (e.response?.data?.detail || ''))
  }
}

const handleSavePR = async (formData) => {
  try {
    await prService.createPR(formData)
    showCreateModal.value = false
    fetchPRs()
  } catch (e) {
    alert('Lưu PR thất bại. Vui lòng kiểm tra lại thông tin.')
  }
}

const showApproveForm = computed(() => {
  if (!prDetailData.value) return false
  const pr = prDetailData.value.pr
  return pr.pr_status === 'PENDING' && 
    (currentUser.value.permissions?.includes('PR_APPROVE') || currentUser.value.username === 'admin')
})

const isApproverRole = computed(() => {
  return currentUser.value.permissions?.includes('PR_APPROVE') || currentUser.value.username === 'admin'
})
</script>

<template>
  <LayoutAuthenticated>
    <SectionMain>
      <SectionTitleLineWithButton :icon="mdiChartTimelineVariant" title="Quản lý Mua sắm (Procurement)" main>
        <BaseButton
          :icon="mdiPlus"
          label="Tạo Yêu Cầu Mua Sắm (PR)"
          color="contrast"
          rounded-full
          small
          @click="showCreateModal = true"
        />
      </SectionTitleLineWithButton>

      <!-- Khối thống kê số liệu -->
      <div class="mb-6 grid grid-cols-1 gap-6 lg:grid-cols-4">
        <CardBoxWidget color="text-blue-500" :icon="mdiNotebook" :number="stats.total" label="Tổng số đơn PR" />
        <CardBoxWidget color="text-yellow-500" :icon="mdiNotebook" :number="stats.pending" label="Chờ duyệt" />
        <CardBoxWidget color="text-green-500" :icon="mdiNotebook" :number="stats.approved" label="Đã duyệt" />
        <CardBoxWidget color="text-gray-500" :icon="mdiNotebook" :number="stats.draft" label="Đơn nháp (Draft)" />
      </div>

      <!-- Khối Tab danh sách -->
      <div class="flex space-x-4 mb-4 border-b">
        <button 
          class="pb-2 px-4 text-sm font-semibold transition"
          :class="activeTab === 'all' ? 'border-b-2 border-blue-500 text-blue-600' : 'text-gray-500 hover:text-gray-800'"
          @click="activeTab = 'all'"
        >
          Tất cả yêu cầu
        </button>
        <button 
          v-if="isApproverRole"
          class="pb-2 px-4 text-sm font-semibold transition"
          :class="activeTab === 'pending' ? 'border-b-2 border-blue-500 text-blue-600' : 'text-gray-500 hover:text-gray-800'"
          @click="activeTab = 'pending'"
        >
          Chờ tôi duyệt ({{ pendingPrs.length }})
        </button>
      </div>

      <!-- Bảng danh sách -->
      <CardBox has-table class="mb-6">
        <PRTable 
          v-if="activeTab === 'all'" 
          :prs="prs" 
          :show-approval-actions="isApproverRole"
          @view="handleView" 
          @submit="handleSubmit" 
          @approve="handleView" 
        />
        <PRTable 
          v-else 
          :prs="pendingPrs" 
          :show-approval-actions="true"
          @view="handleView" 
          @submit="handleSubmit" 
          @approve="handleView" 
        />
      </CardBox>
    </SectionMain>

    <!-- Modals -->
    <PRCreateModal 
      v-if="showCreateModal" 
      @close="showCreateModal = false" 
      @save="handleSavePR" 
    />
    
    <PRDetailModal 
      v-if="showDetailModal" 
      :pr-data="prDetailData" 
      :show-approve-form="showApproveForm"
      @close="showDetailModal = false" 
      @approve="handleApprove" 
    />
  </LayoutAuthenticated>
</template>
