<script setup>
import { ref, reactive } from 'vue'
import { mdiClose } from '@mdi/js'
import CardBox from '@/components/CardBox.vue'
import BaseButton from '@/components/BaseButton.vue'
import BaseButtons from '@/components/BaseButtons.vue'
import FormField from '@/components/FormField.vue'
import FormControl from '@/components/FormControl.vue'

const props = defineProps({
  prData: {
    type: Object,
    required: true,
  },
  showApproveForm: {
    type: Boolean,
    default: false,
  }
})

const emit = defineEmits(['close', 'approve'])

const comment = ref('')
const isSubmitting = ref(false)

const handleApprove = async (action) => {
  if (action === 'REJECT' && !comment.value.trim()) {
    alert('Vui lòng nhập lý do từ chối vào ô ý kiến phê duyệt.')
    return
  }
  
  isSubmitting.value = true
  try {
    emit('approve', {
      pr_id: props.prData.pr.pr_id,
      action,
      comment: comment.value
    })
    comment.value = ''
  } finally {
    isSubmitting.value = false
  }
}

const formatCurrency = (val) => {
  return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(val || 0)
}
</script>

<template>
  <div class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4 overflow-y-auto">
    <div class="bg-white dark:bg-gray-900 rounded-lg shadow-xl max-w-4xl w-full max-h-[90vh] overflow-y-auto">
      <!-- Header -->
      <div class="flex justify-between items-center px-6 py-4 border-b border-gray-200 dark:border-gray-800">
        <h3 class="text-xl font-bold text-gray-800 dark:text-white">
          Chi tiết Yêu cầu: {{ prData.pr.pr_code }}
        </h3>
        <BaseButton :icon="mdiClose" color="whiteDark" small @click="emit('close')" />
      </div>

      <!-- Content -->
      <div class="p-6 space-y-6">
        <!-- Thông tin chung -->
        <div class="grid grid-cols-1 md:grid-cols-3 gap-4 bg-gray-50 dark:bg-gray-800 p-4 rounded-lg text-sm">
          <div><span class="text-gray-400">Người yêu cầu:</span> {{ prData.pr.requester_name }}</div>
          <div><span class="text-gray-400">Đơn vị:</span> {{ prData.pr.branch_name }} / {{ prData.pr.dept_name }}</div>
          <div><span class="text-gray-400">Ngày tạo:</span> {{ new Date(prData.pr.created_at).toLocaleDateString('vi-VN') }}</div>
          <div><span class="text-gray-400">Trạng thái:</span> <b class="text-blue-600">{{ prData.pr.pr_status }}</b></div>
          <div><span class="text-gray-400">Độ ưu tiên:</span> <b :class="prData.pr.priority_level === 'URGENT' ? 'text-red-500' : 'text-gray-600'">{{ prData.pr.priority_level }}</b></div>
          <div><span class="text-gray-400">Tổng tiền dự kiến:</span> <b class="text-green-600">{{ formatCurrency(prData.pr.total_estimated_amount) }}</b></div>
        </div>

        <div v-if="prData.pr.urgent_reason" class="text-sm bg-red-50 dark:bg-red-950/20 border-l-4 border-red-500 p-3 rounded">
          <p class="font-semibold text-red-700 dark:text-red-400">Lý do khẩn cấp:</p>
          <p class="text-gray-600 dark:text-gray-300">{{ prData.pr.urgent_reason }}</p>
          <p class="font-semibold text-red-700 dark:text-red-400 mt-2">Ảnh hưởng nếu chậm trễ:</p>
          <p class="text-gray-600 dark:text-gray-300">{{ prData.pr.urgency_impact }}</p>
        </div>

        <!-- Danh sách vật tư yêu cầu -->
        <div>
          <h4 class="text-md font-bold text-gray-700 dark:text-gray-300 mb-3">Danh sách vật tư</h4>
          <table class="w-full text-left text-xs text-gray-500 dark:text-gray-400 border border-gray-200 dark:border-gray-800">
            <thead class="bg-gray-100 dark:bg-gray-800">
              <tr>
                <th class="px-4 py-2 border-b">Tên vật tư</th>
                <th class="px-4 py-2 border-b">Hạn cần</th>
                <th class="px-4 py-2 border-b text-right">Số lượng</th>
                <th class="px-4 py-2 border-b text-right">Đơn giá dự kiến</th>
                <th class="px-4 py-2 border-b text-right">Thành tiền</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="item in prData.pr.items" :key="item.pr_item_id" class="border-b">
                <td class="px-4 py-2 font-medium text-gray-900 dark:text-white border-r">
                  {{ item.material_name }}
                </td>
                <td class="px-4 py-2 border-r">{{ new Date(item.required_deadline).toLocaleDateString('vi-VN') }}</td>
                <td class="px-4 py-2 text-right border-r font-semibold">{{ parseFloat(item.qty_requested) }}</td>
                <td class="px-4 py-2 text-right border-r">{{ formatCurrency(item.estimated_unit_price) }}</td>
                <td class="px-4 py-2 text-right font-bold text-gray-800 dark:text-gray-200">
                  {{ formatCurrency(item.qty_requested * item.estimated_unit_price) }}
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <!-- Tiến trình phê duyệt -->
        <div>
          <h4 class="text-md font-bold text-gray-700 dark:text-gray-300 mb-3">Tiến trình phê duyệt</h4>
          <div class="space-y-3">
            <div 
              v-for="step in prData.approval_progress" 
              :key="step.progress_id" 
              class="flex justify-between items-start text-xs border border-gray-100 dark:border-gray-800 p-2.5 rounded bg-gray-50/50"
            >
              <div>
                <span class="font-bold">Bước {{ step.step_sequence }}: {{ step.approver_name }}</span>
                <p v-if="step.comment" class="text-gray-500 italic mt-0.5">Ý kiến: "{{ step.comment }}"</p>
              </div>
              <div class="text-right">
                <span 
                  class="rounded-full px-2 py-0.5 font-bold"
                  :class="step.approval_status === 'APPROVED' ? 'bg-green-100 text-green-700' : step.approval_status === 'REJECTED' ? 'bg-red-100 text-red-700' : 'bg-yellow-100 text-yellow-700'"
                >
                  {{ step.approval_status }}
                </span>
                <p v-if="step.action_date" class="text-[10px] text-gray-400 mt-1">
                  {{ new Date(step.action_date).toLocaleString('vi-VN') }}
                </p>
              </div>
            </div>
          </div>
        </div>

        <!-- Khối phê duyệt (Dành cho cấp trên) -->
        <div v-if="showApproveForm" class="border-t pt-4 bg-yellow-50/30 dark:bg-yellow-950/10 p-4 rounded-lg">
          <h4 class="text-sm font-bold text-yellow-800 dark:text-yellow-400 mb-2">Thực hiện Phê duyệt / Từ chối</h4>
          <FormField label="Ý kiến phê duyệt" help="Bắt buộc nhập nếu từ chối đơn hàng này.">
            <FormControl v-model="comment" type="textarea" placeholder="Nhập ý kiến hoặc lý do tại đây..." />
          </FormField>
          <BaseButtons class="mt-3">
            <BaseButton 
              color="success" 
              label="Phê duyệt" 
              :disabled="isSubmitting" 
              @click="handleApprove('APPROVE')" 
            />
            <BaseButton 
              color="danger" 
              label="Từ chối" 
              :disabled="isSubmitting" 
              @click="handleApprove('REJECT')" 
            />
          </BaseButtons>
        </div>
      </div>
    </div>
  </div>
</template>
