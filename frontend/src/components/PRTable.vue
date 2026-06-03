<script setup>
import { mdiEye, mdiSend, mdiCheckDecagram } from '@mdi/js'
import BaseButton from '@/components/BaseButton.vue'
import BaseButtons from '@/components/BaseButtons.vue'

defineProps({
  prs: {
    type: Array,
    required: true,
  },
  showApprovalActions: {
    type: Boolean,
    default: false,
  }
})

const emit = defineEmits(['view', 'submit', 'approve'])

const formatCurrency = (val) => {
  return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(val || 0)
}

const formatDate = (dateStr) => {
  if (!dateStr) return '-'
  return new Date(dateStr).toLocaleDateString('vi-VN', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
  })
}

const getStatusColor = (status) => {
  switch (status) {
    case 'DRAFT':
      return 'bg-gray-100 text-gray-800'
    case 'PENDING':
      return 'bg-yellow-100 text-yellow-800'
    case 'APPROVED':
      return 'bg-green-100 text-green-800'
    case 'REJECTED':
      return 'bg-red-100 text-red-800'
    default:
      return 'bg-blue-100 text-blue-800'
  }
}
</script>

<template>
  <div class="overflow-x-auto">
    <table class="w-full text-left text-sm text-gray-500 dark:text-gray-400">
      <thead class="bg-gray-50 text-xs uppercase text-gray-700 dark:bg-gray-700 dark:text-gray-400">
        <tr>
          <th class="px-6 py-3">Mã đơn</th>
          <th class="px-6 py-3">Người yêu cầu</th>
          <th class="px-6 py-3">Chi nhánh / Phòng ban</th>
          <th class="px-6 py-3">Mức độ ưu tiên</th>
          <th class="px-6 py-3">Ước lượng chi phí</th>
          <th class="px-6 py-3">Trạng thái</th>
          <th class="px-6 py-3">Ngày tạo</th>
          <th class="px-6 py-3 text-right">Thao tác</th>
        </tr>
      </thead>
      <tbody>
        <tr 
          v-for="pr in prs" 
          :key="pr.pr_id" 
          class="border-b bg-white hover:bg-gray-50 dark:border-gray-700 dark:bg-gray-800 dark:hover:bg-gray-600"
        >
          <td class="whitespace-nowrap px-6 py-4 font-medium text-gray-900 dark:text-white">
            {{ pr.pr_code }}
          </td>
          <td class="px-6 py-4">{{ pr.requester_name }}</td>
          <td class="px-6 py-4">
            {{ pr.branch_name }} / {{ pr.dept_name }}
          </td>
          <td class="px-6 py-4">
            <span 
              :class="pr.priority_level === 'URGENT' ? 'text-red-600 font-semibold' : 'text-gray-600'"
            >
              {{ pr.priority_level }}
            </span>
          </td>
          <td class="px-6 py-4 font-semibold text-gray-800 dark:text-gray-200">
            {{ formatCurrency(pr.total_estimated_amount) }}
          </td>
          <td class="px-6 py-4">
            <span 
              class="rounded-full px-2.5 py-0.5 text-xs font-medium"
              :class="getStatusColor(pr.pr_status)"
            >
              {{ pr.pr_status }}
            </span>
          </td>
          <td class="px-6 py-4">{{ formatDate(pr.created_at) }}</td>
          <td class="px-6 py-4 text-right">
            <BaseButtons type="justify-end" no-wrap>
              <BaseButton
                color="info"
                :icon="mdiEye"
                small
                label="Xem"
                @click="emit('view', pr.pr_id)"
              />
              <BaseButton
                v-if="pr.pr_status === 'DRAFT'"
                color="success"
                :icon="mdiSend"
                small
                label="Nộp duyệt"
                @click="emit('submit', pr.pr_id)"
              />
              <BaseButton
                v-if="pr.pr_status === 'PENDING' && showApprovalActions"
                color="warning"
                :icon="mdiCheckDecagram"
                small
                label="Duyệt"
                @click="emit('approve', pr.pr_id)"
              />
            </BaseButtons>
          </td>
        </tr>
        <tr v-if="prs.length === 0">
          <td colspan="8" class="text-center py-8 text-gray-400">
            Không tìm thấy yêu cầu mua sắm nào.
          </td>
        </tr>
      </tbody>
    </table>
  </div>
</template>
