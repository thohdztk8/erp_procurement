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
import BasePagination from '@/components/BasePagination.vue'
import { prService } from '@/services/api'

const prs = ref([])
const pendingPrs = ref([])
const stats = ref({ total: 0, draft: 0, pending: 0, approved: 0 })
const activeTab = ref('all') // 'all' hoặc 'pending'

const currentPage = ref(1)
const totalPages = ref(1)
const totalItems = ref(0)

const pendingPage = ref(1)
const pendingTotalPages = ref(1)
const pendingTotalItems = ref(0)

const showCreateModal = ref(false)
const showDetailModal = ref(false)
const isEditMode = ref(false)
const prDetailData = ref(null)
const currentUser = ref(JSON.parse(localStorage.getItem('user') || '{}'))

const fetchPRs = async () => {
  try {
    const response = await prService.getPRs({ page: currentPage.value })
    prs.value = response.data.items || []
    totalPages.value = response.data.pagination?.total_pages || 1
    totalItems.value = response.data.pagination?.total_items || 0
    
    // Tính toán số liệu thống kê bằng cách fetch danh sách lớn hơn hoặc ước lượng từ pagination
    const statsRes = await prService.getPRs({ page_size: 1000 })
    const allPrs = statsRes.data.items || []
    stats.value.total = statsRes.data.pagination?.total_items || allPrs.length
    stats.value.draft = allPrs.filter(p => p.pr_status === 'DRAFT').length
    stats.value.pending = allPrs.filter(p => p.pr_status === 'PENDING').length
    stats.value.approved = allPrs.filter(p => p.pr_status === 'APPROVED').length

    // Nếu user có quyền duyệt, lấy danh sách chờ duyệt
    const isApprover = currentUser.value.permissions?.includes('PR_APPROVE') || currentUser.value.username === 'admin' || currentUser.value.role_code === 'ADMIN'
    if (isApprover) {
      const pendingRes = await prService.getPendingPRs({ page: pendingPage.value })
      pendingPrs.value = pendingRes.data.items || []
      pendingTotalPages.value = pendingRes.data.pagination?.total_pages || 1
      pendingTotalItems.value = pendingRes.data.pagination?.total_items || 0
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

const handleEdit = async (id) => {
  try {
    const res = await prService.getPRDetail(id)
    prDetailData.value = res.data.pr
    isEditMode.value = true
    showCreateModal.value = true
  } catch (error) {
    alert('Không lấy được chi tiết đơn PR để sửa.')
  }
}

const handleCancel = async (id) => {
  if (confirm('Bạn chắc chắn muốn hủy đơn PR này?')) {
    try {
      await prService.cancelPR(id)
      fetchPRs()
    } catch (e) {
      alert('Hủy đơn PR thất bại.')
    }
  }
}

const handleSavePR = async (formData) => {
  try {
    if (isEditMode.value && prDetailData.value) {
      await prService.updatePR(prDetailData.value.pr_id, formData)
    } else {
      await prService.createPR(formData)
    }
    showCreateModal.value = false
    isEditMode.value = false
    prDetailData.value = null
    fetchPRs()
  } catch (e) {
    alert('Lưu PR thất bại. Vui lòng kiểm tra lại thông tin.')
  }
}

const changeAllPage = (page) => {
  currentPage.value = page
  fetchPRs()
}

const changePendingPage = (page) => {
  pendingPage.value = page
  fetchPRs()
}

const showApproveForm = computed(() => {
  if (!prDetailData.value) return false
  const pr = prDetailData.value.pr
  return pr.pr_status === 'PENDING' && 
    (currentUser.value.permissions?.includes('PR_APPROVE') || currentUser.value.username === 'admin' || currentUser.value.role_code === 'ADMIN')
})

const isApproverRole = computed(() => {
  return currentUser.value.permissions?.includes('PR_APPROVE') || currentUser.value.username === 'admin' || currentUser.value.role_code === 'ADMIN'
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
          @click="showCreateModal = true; isEditMode = false; prDetailData = null"
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
          Chờ tôi duyệt ({{ pendingTotalItems }})
        </button>
      </div>

      <!-- Bảng danh sách -->
      <CardBox has-table class="mb-6">
        <div v-if="activeTab === 'all'">
          <PRTable 
            :prs="prs" 
            :show-approval-actions="isApproverRole"
            @view="handleView" 
            @submit="handleSubmit" 
            @approve="handleView" 
            @edit="handleEdit"
            @cancel="handleCancel"
          />
          <BasePagination
            :current-page="currentPage"
            :total-pages="totalPages"
            :total-items="totalItems"
            @change-page="changeAllPage"
          />
        </div>
        <div v-else>
          <PRTable 
            :prs="pendingPrs" 
            :show-approval-actions="true"
            @view="handleView" 
            @submit="handleSubmit" 
            @approve="handleView" 
            @edit="handleEdit"
            @cancel="handleCancel"
          />
          <BasePagination
            :current-page="pendingPage"
            :total-pages="pendingTotalPages"
            :total-items="pendingTotalItems"
            @change-page="changePendingPage"
          />
        </div>
      </CardBox>
    </SectionMain>

    <!-- Modals -->
    <PRCreateModal 
      v-if="showCreateModal" 
      :edit-mode="isEditMode"
      :pr-data="prDetailData"
      @close="showCreateModal = false; isEditMode = false; prDetailData = null" 
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
