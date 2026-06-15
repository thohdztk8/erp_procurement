<script setup>
import { ref, onMounted } from 'vue'
import { mdiClose, mdiPencil, mdiContentSave } from '@mdi/js'
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

const isEditing = ref(false)
const editedItems = ref([])

const fetchDetail = async () => {
  try {
    const res = await ipoService.getIPODetail(props.ipoId)
    ipo.value = res.data?.ipo || res.data || null
  } catch (error) {
    console.error(error)
  }
}

onMounted(() => {
  fetchDetail()
})

const startEdit = () => {
  isEditing.value = true
  editedItems.value = JSON.parse(JSON.stringify(ipo.value.items))
}

const saveEdit = async () => {
  isSubmitting.value = true
  try {
    const payload = {
      order_id: ipo.value.order_id,
      supplier_id: ipo.value.supplier_id,
      items: editedItems.value.map(it => ({
        order_item_id: it.order_item_id,
        qty_final: parseFloat(it.qty_final),
        unit_price: parseFloat(it.unit_price)
      }))
    }
    await ipoService.createIPOVersion(payload)
    alert('Đã tạo phiên bản IPO mới do thay đổi thông tin thành công.')
    isEditing.value = false
    emit('updated')
    emit('close')
  } catch (e) {
    alert('Tạo phiên bản mới thất bại: ' + (e.response?.data?.detail || ''))
  } finally {
    isSubmitting.value = false
  }
}

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
        <h3 class="text-xl font-bold text-gray-800 dark:text-white flex items-center gap-3">
          Hợp đồng mua sắm (IPO): {{ ipo.ipo_code }}
          <span class="text-xs bg-gray-200 text-gray-800 px-2 py-1 rounded">v{{ ipo.version }}</span>
          <span v-if="isEditing" class="text-xs bg-yellow-100 text-yellow-800 px-2 py-1 rounded">Đang cập nhật (sẽ tạo version mới)</span>
        </h3>
        <BaseButton :icon="mdiClose" color="whiteDark" small @click="emit('close')" />
      </div>

      <!-- Body -->
      <div class="p-6 space-y-6 text-sm">
        <div class="flex justify-between items-start">
          <div class="grid grid-cols-2 gap-4 bg-gray-50 dark:bg-gray-800 p-4 rounded w-3/4">
            <div><span class="text-gray-400">Trạng thái:</span> <b class="text-blue-600">{{ ipo.ipo_status }}</b></div>
            <div><span class="text-gray-400">Nhà cung cấp:</span> {{ ipo.supplier_name || ipo.supplier?.supplier_name }}</div>
            <div><span class="text-gray-400">Tổng giá trị hợp đồng:</span> <b class="text-green-600">{{ formatCurrency(ipo.total_amount) }}</b></div>
            <div><span class="text-gray-400">Ngày lập:</span> {{ new Date(ipo.created_at).toLocaleDateString('vi-VN') }}</div>
          </div>

          <div v-if="ipo.ipo_status === 'DRAFT' && !showApproveForm">
            <BaseButton v-if="!isEditing" color="info" :icon="mdiPencil" label="Sửa IPO" @click="startEdit" />
            <BaseButton v-else color="success" :icon="mdiContentSave" label="Lưu & Tạo bản mới" :disabled="isSubmitting" @click="saveEdit" />
          </div>
        </div>

        <!-- Items -->
        <div>
          <h4 class="text-sm font-bold text-gray-700 dark:text-gray-300 mb-2">Chi tiết sản phẩm thầu</h4>
          <table class="w-full text-xs text-left border">
            <thead class="bg-gray-50 dark:bg-gray-800">
              <tr>
                <th class="px-4 py-2 border-b">Tên vật tư</th>
                <th class="px-4 py-2 border-b text-right">Số lượng chốt</th>
                <th class="px-4 py-2 border-b text-right">Đơn giá thầu</th>
                <th class="px-4 py-2 border-b text-right">Thành tiền</th>
              </tr>
            </thead>
            <tbody v-if="!isEditing">
              <tr v-for="it in ipo.items" :key="it.ipo_item_id" class="border-b">
                <td class="px-4 py-2 border-r font-medium text-gray-900 dark:text-white">
                  {{ it.material_name || it.material?.material_name }}
                </td>
                <td class="px-4 py-2 text-right border-r">{{ parseFloat(it.qty_final) }}</td>
                <td class="px-4 py-2 text-right border-r">{{ formatCurrency(it.unit_price) }}</td>
                <td class="px-4 py-2 text-right font-bold">{{ formatCurrency(it.qty_final * it.unit_price) }}</td>
              </tr>
            </tbody>
            <tbody v-else>
              <tr v-for="it in editedItems" :key="it.ipo_item_id" class="border-b bg-yellow-50 dark:bg-yellow-900/10">
                <td class="px-4 py-2 border-r font-medium text-gray-900 dark:text-white">
                  {{ it.material_name || it.material?.material_name }}
                </td>
                <td class="px-4 py-2 text-right border-r">
                  <input type="number" v-model.number="it.qty_final" class="w-20 text-right border p-1 rounded" min="0.001" step="1"/>
                </td>
                <td class="px-4 py-2 text-right border-r">
                  <input type="number" v-model.number="it.unit_price" class="w-28 text-right border p-1 rounded" min="0" step="1000"/>
                </td>
                <td class="px-4 py-2 text-right font-bold">{{ formatCurrency(it.qty_final * it.unit_price) }}</td>
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
