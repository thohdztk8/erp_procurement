<script setup>
import { ref, onMounted } from 'vue'
import { mdiClose } from '@mdi/js'
import BaseButton from '@/components/BaseButton.vue'
import BaseButtons from '@/components/BaseButtons.vue'
import FormField from '@/components/FormField.vue'
import FormControl from '@/components/FormControl.vue'
import { ipoService } from '@/services/api'

const props = defineProps({
  ipoId: {
    type: Number,
    required: true,
  },
  showApproveForm: {
    type: Boolean,
    default: false,
  }
})

const emit = defineEmits(['close', 'updated'])

const ipo = ref(null)
const comment = ref('')
const isSubmitting = ref(false)

const fetchDetail = async () => {
  try {
    const res = await ipoService.getIPODetail(props.ipoId)
    // Backend Detail structure might vary, let's assume it returns data
    ipo.value = res.data?.ipo || res.data || null
  } catch (error) {
    console.error(error)
  }
}

onMounted(() => {
  fetchDetail()
})

const handleApprove = async (action) => {
  if (action === 'REJECT' && !comment.value.trim()) {
    alert('Vui lòng nhập lý do từ chối.')
    return
  }
  isSubmitting.value = true
  try {
    await ipoService.approveIPO(props.ipoId, action, comment.value)
    alert('Xử lý phê duyệt thành công!')
    emit('updated')
    emit('close')
  } catch (e) {
    alert('Phê duyệt thất bại. ' + (e.response?.data?.detail || ''))
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
    <div v-if="ipo" class="bg-white dark:bg-gray-900 rounded-lg shadow-xl max-w-3xl w-full max-h-[85vh] overflow-y-auto">
      <!-- Header -->
      <div class="flex justify-between items-center px-6 py-4 border-b border-gray-200 dark:border-gray-800">
        <h3 class="text-xl font-bold text-gray-800 dark:text-white">
          Hợp đồng mua sắm (IPO): {{ ipo.ipo_code }}
        </h3>
        <BaseButton :icon="mdiClose" color="whiteDark" small @click="emit('close')" />
      </div>

      <!-- Body -->
      <div class="p-6 space-y-6 text-sm">
        <div class="grid grid-cols-2 gap-4 bg-gray-50 dark:bg-gray-800 p-4 rounded">
          <div><span class="text-gray-400">Trạng thái:</span> <b class="text-blue-600">{{ ipo.ipo_status }}</b></div>
          <div><span class="text-gray-400">Nhà cung cấp:</span> {{ ipo.supplier_name || ipo.supplier?.supplier_name }}</div>
          <div><span class="text-gray-400">Tổng giá trị hợp đồng:</span> <b class="text-green-600">{{ formatCurrency(ipo.total_amount) }}</b></div>
          <div><span class="text-gray-400">Ngày lập:</span> {{ new Date(ipo.created_at).toLocaleDateString('vi-VN') }}</div>
        </div>

        <!-- Items -->
        <div>
          <h4 class="text-sm font-bold text-gray-700 dark:text-gray-300 mb-2">Chi tiết sản phẩm thầu</h4>
          <table class="w-full text-xs text-left border">
            <thead class="bg-gray-50 dark:bg-gray-800">
              <tr>
                <th class="px-4 py-2 border-b">Tên vật tư</th>
                <th class="px-4 py-2 border-b text-right">Số lượng</th>
                <th class="px-4 py-2 border-b text-right">Đơn giá thầu</th>
                <th class="px-4 py-2 border-b text-right">Thành tiền</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="it in ipo.items" :key="it.ipo_item_id" class="border-b">
                <td class="px-4 py-2 border-r font-medium text-gray-900 dark:text-white">
                  {{ it.material_name || it.material?.material_name }}
                </td>
                <td class="px-4 py-2 text-right border-r">{{ parseFloat(it.qty) }}</td>
                <td class="px-4 py-2 text-right border-r">{{ formatCurrency(it.unit_price) }}</td>
                <td class="px-4 py-2 text-right font-bold">{{ formatCurrency(it.qty * it.unit_price) }}</td>
              </tr>
            </tbody>
          </table>
        </div>

        <!-- Duyệt IPO -->
        <div v-if="showApproveForm" class="border-t pt-4 bg-yellow-50/30 dark:bg-yellow-950/10 p-4 rounded-lg">
          <h4 class="text-sm font-bold text-yellow-800 dark:text-yellow-400 mb-2">Phê duyệt Hợp đồng IPO</h4>
          <FormField label="Ý kiến phê duyệt" help="Bắt buộc nếu từ chối.">
            <FormControl v-model="comment" type="textarea" placeholder="Ý kiến của bạn..." />
          </FormField>
          <BaseButtons class="mt-3">
            <BaseButton color="success" label="Phê duyệt" :disabled="isSubmitting" @click="handleApprove('APPROVE')" />
            <BaseButton color="danger" label="Từ chối" :disabled="isSubmitting" @click="handleApprove('REJECT')" />
          </BaseButtons>
        </div>
      </div>
    </div>
  </div>
</template>
