<script setup>
import { ref, onMounted } from 'vue'
import { mdiClose, mdiPlus, mdiPencil, mdiContentSave, mdiTrashCan } from '@mdi/js'
import BaseButton from '@/components/BaseButton.vue'
import BaseButtons from '@/components/BaseButtons.vue'
import FormField from '@/components/FormField.vue'
import FormControl from '@/components/FormControl.vue'
import { cartOrderService, masterService, quotationService } from '@/services/api'

const props = defineProps({
  orderId: {
    type: Number,
    required: true,
  }
})

const emit = defineEmits(['close', 'updated'])

const order = ref(null)
const suppliersList = ref([])
const selectedSupplier = ref(null)
const isSubmitting = ref(false)

const isEditing = ref(false)
const editedItems = ref([])
const editedSuppliers = ref([])

const showQuotationModal = ref(false)
const deadline = ref('')
const overrideRule = ref(false)

const availableStatuses = [
  'DRAFT', 'QUOTING', 'QUOTE_CLOSED', 
  'WAITING_DELIVERY', 'PARTIAL_DELIVERED', 'DELIVERED', 
  'CANCELLED'
]

const updateStatus = async (newStatus) => {
  if (!confirm(`Bạn muốn đổi trạng thái đơn mua hàng thành ${newStatus}?`)) return
  try {
    await cartOrderService.updateOrderStatus(props.orderId, newStatus)
    alert('Cập nhật trạng thái thành công.')
    fetchOrderDetail()
    emit('updated')
  } catch (e) {
    alert('Cập nhật thất bại: ' + (e.response?.data?.detail || ''))
  }
}

const fetchOrderDetail = async () => {
  try {
    const res = await cartOrderService.getOrderDetail(props.orderId)
    order.value = res.data
  } catch (error) {
    console.error(error)
  }
}

const fetchSuppliers = async () => {
  try {
    const res = await masterService.getSuppliers()
    suppliersList.value = res.results || []
  } catch (error) {
    console.error(error)
  }
}

onMounted(() => {
  fetchOrderDetail()
  fetchSuppliers()
})

const handleAddSupplier = () => {
  if (!selectedSupplier.value) return
  // Find in suppliersList
  const found = suppliersList.value.find(s => s.supplier_id === parseInt(selectedSupplier.value))
  if (found) {
    // Check if already in editedSuppliers
    const exists = editedSuppliers.value.find(s => s.supplier_id === found.supplier_id)
    if (!exists) {
      editedSuppliers.value.push({
        supplier_id: found.supplier_id,
        supplier__supplier_name: found.supplier_name,
        custom_contact_name: '',
        custom_contact_email: '',
        custom_contact_phone: ''
      })
    }
  }
  selectedSupplier.value = null
}

const startEdit = () => {
  isEditing.value = true
  editedItems.value = JSON.parse(JSON.stringify(order.value.items))
  editedSuppliers.value = JSON.parse(JSON.stringify(order.value.suppliers)).map(s => ({
    supplier_id: s.supplier__supplier_id,
    supplier__supplier_name: s.supplier__supplier_name,
    custom_contact_name: s.custom_contact_name || '',
    custom_contact_email: s.custom_contact_email || '',
    custom_contact_phone: s.custom_contact_phone || ''
  }))
}

const saveEdit = async () => {
  isSubmitting.value = true
  try {
    await cartOrderService.updateOrder(props.orderId, {
      items: editedItems.value.map(i => ({ order_item_id: i.order_item_id, qty_total_ordered: i.qty_total_ordered })),
      suppliers: editedSuppliers.value.map(s => ({
        supplier_id: s.supplier_id,
        custom_contact_name: s.custom_contact_name,
        custom_contact_email: s.custom_contact_email,
        custom_contact_phone: s.custom_contact_phone
      }))
    })
    isEditing.value = false
    fetchOrderDetail()
    emit('updated')
  } catch (e) {
    alert('Lưu thay đổi thất bại: ' + (e.response?.data?.detail || ''))
  } finally {
    isSubmitting.value = false
  }
}

const removeSupplier = (id) => {
  editedSuppliers.value = editedSuppliers.value.filter(s => s.supplier_id !== id)
}

const sendQuotation = async () => {
  if (!deadline.value) {
    alert('Vui lòng chọn hạn chót nộp báo giá.')
    return
  }
  isSubmitting.value = true
  try {
    const sIds = order.value.suppliers.map(s => s.supplier__supplier_id)
    await quotationService.inviteSuppliers(props.orderId, sIds, new Date(deadline.value).toISOString(), overrideRule.value)
    alert('Gửi yêu cầu báo giá thành công.')
    showQuotationModal.value = false
    fetchOrderDetail()
    emit('updated')
  } catch (e) {
    if (e.response?.data?.detail?.includes('Vượt quá quy định') && !overrideRule.value) {
      if (confirm(e.response.data.detail + ' Bạn có muốn ghi đè quy tắc để tiếp tục gửi?')) {
        overrideRule.value = true
        sendQuotation()
      }
    } else {
      alert('Gửi thất bại: ' + (e.response?.data?.detail || ''))
    }
  } finally {
    isSubmitting.value = false
  }
}
</script>

<template>
  <div class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4 overflow-y-auto">
    <div v-if="order" class="bg-white dark:bg-gray-900 rounded-lg shadow-xl max-w-4xl w-full max-h-[85vh] overflow-y-auto">
      <!-- Header -->
      <div class="flex justify-between items-center px-6 py-4 border-b border-gray-200 dark:border-gray-800">
        <h3 class="text-xl font-bold text-gray-800 dark:text-white flex items-center gap-3">
          Đơn mua hàng: {{ order.order_code }}
          <span v-if="isEditing" class="text-xs bg-yellow-100 text-yellow-800 px-2 py-1 rounded">Đang chỉnh sửa</span>
        </h3>
        <BaseButton :icon="mdiClose" color="whiteDark" small @click="emit('close')" />
      </div>

      <!-- Body -->
      <div class="p-6 space-y-6 text-sm">
        <div class="flex justify-between items-start">
          <div class="grid grid-cols-2 gap-4 bg-gray-50 dark:bg-gray-800 p-4 rounded w-2/3">
            <div class="flex items-center gap-2">
              <span class="text-gray-400">Trạng thái:</span> 
              <b class="text-blue-600">{{ order.order_status }}</b>
              <!-- Quick status change -->
              <select 
                class="ml-2 border rounded p-1 text-xs dark:bg-gray-700" 
                @change="(e) => { if(e.target.value) { updateStatus(e.target.value); e.target.value = ''; } }"
              >
                <option value="">-- Đổi --</option>
                <option v-for="st in availableStatuses" :key="st" :value="st">{{ st }}</option>
              </select>
            </div>
            <div><span class="text-gray-400">Người mua:</span> {{ order.buyer_name }}</div>
            <div><span class="text-gray-400">Ngày lập:</span> {{ new Date(order.created_at).toLocaleDateString('vi-VN') }}</div>
          </div>
          
          <div class="flex flex-col gap-2 items-end">
            <div v-if="order.order_status === 'DRAFT' || order.order_status === 'QUOTING'">
              <BaseButton v-if="!isEditing" color="info" :icon="mdiPencil" label="Sửa đơn" @click="startEdit" />
              <BaseButton v-else color="success" :icon="mdiContentSave" label="Lưu thay đổi" :disabled="isSubmitting" @click="saveEdit" />
            </div>
            <BaseButton 
              v-if="order.order_status === 'DRAFT' || order.order_status === 'QUOTING'"
              color="warning" 
              label="Gửi yêu cầu báo giá" 
              @click="showQuotationModal = true" 
            />
          </div>
        </div>

        <!-- Items -->
        <div>
          <h4 class="text-sm font-bold text-gray-700 dark:text-gray-300 mb-2">Chi tiết mặt hàng</h4>
          <table class="w-full text-xs text-left border">
            <thead class="bg-gray-50 dark:bg-gray-800">
              <tr>
                <th class="px-4 py-2 border-b">Tên vật tư</th>
                <th class="px-4 py-2 border-b text-right">Số lượng đặt hàng</th>
              </tr>
            </thead>
            <tbody v-if="!isEditing">
              <tr v-for="it in order.items" :key="it.order_item_id" class="border-b">
                <td class="px-4 py-2 border-r font-medium text-gray-900 dark:text-white">
                  {{ it.material_name }}
                </td>
                <td class="px-4 py-2 text-right font-bold">{{ parseFloat(it.qty_total_ordered) }}</td>
              </tr>
            </tbody>
            <tbody v-else>
              <tr v-for="it in editedItems" :key="it.order_item_id" class="border-b">
                <td class="px-4 py-2 border-r font-medium text-gray-900 dark:text-white">
                  {{ it.material_name }}
                </td>
                <td class="px-4 py-2 text-right">
                  <input type="number" v-model.lazy="it.qty_total_ordered" class="w-24 text-right border p-1 rounded" min="0.001" step="1"/>
                </td>
              </tr>
            </tbody>
          </table>
          <p v-if="isEditing" class="text-xs text-orange-500 mt-1 italic">* Lưu ý: Việc thay đổi số lượng ở đây sẽ tự động cập nhật ngược lại số lượng đã đặt của các Yêu cầu mua sắm (PR) liên quan.</p>
        </div>

        <!-- Bidding Suppliers -->
        <div>
          <h4 class="text-sm font-bold text-gray-700 dark:text-gray-300 mb-2">Nhà cung cấp tham gia báo giá</h4>
          
          <table class="w-full text-xs text-left border mb-4">
            <thead class="bg-gray-50 dark:bg-gray-800">
              <tr>
                <th class="px-4 py-2 border-b">Tên NCC</th>
                <th class="px-4 py-2 border-b">Người liên hệ</th>
                <th class="px-4 py-2 border-b">Email</th>
                <th class="px-4 py-2 border-b">SĐT</th>
                <th v-if="isEditing" class="px-4 py-2 border-b w-10 text-center">Xóa</th>
              </tr>
            </thead>
            <tbody v-if="!isEditing">
              <tr v-for="s in order.suppliers" :key="s.supplier__supplier_id" class="border-b">
                <td class="px-4 py-2 border-r font-medium">{{ s.supplier__supplier_name }}</td>
                <td class="px-4 py-2 border-r">{{ s.custom_contact_name || '-' }}</td>
                <td class="px-4 py-2 border-r">{{ s.custom_contact_email || '-' }}</td>
                <td class="px-4 py-2 border-r">{{ s.custom_contact_phone || '-' }}</td>
              </tr>
              <tr v-if="order.suppliers.length === 0">
                <td colspan="4" class="px-4 py-2 text-center text-gray-500">Chưa có NCC nào.</td>
              </tr>
            </tbody>
            <tbody v-else>
              <tr v-for="s in editedSuppliers" :key="s.supplier_id" class="border-b bg-yellow-50 dark:bg-yellow-900/10">
                <td class="px-4 py-2 border-r font-medium">{{ s.supplier__supplier_name }}</td>
                <td class="px-4 py-2 border-r"><input type="text" v-model="s.custom_contact_name" class="w-full border p-1 rounded" placeholder="Tên" /></td>
                <td class="px-4 py-2 border-r"><input type="email" v-model="s.custom_contact_email" class="w-full border p-1 rounded" placeholder="Email" /></td>
                <td class="px-4 py-2 border-r"><input type="text" v-model="s.custom_contact_phone" class="w-full border p-1 rounded" placeholder="SĐT" /></td>
                <td class="px-4 py-2 text-center">
                  <BaseButton color="danger" :icon="mdiTrashCan" small @click="removeSupplier(s.supplier_id)" />
                </td>
              </tr>
              <tr v-if="editedSuppliers.length === 0">
                <td colspan="5" class="px-4 py-2 text-center text-gray-500">Chưa chọn NCC nào.</td>
              </tr>
            </tbody>
          </table>

          <!-- Thêm NCC -->
          <div v-if="isEditing" class="flex gap-2 items-end">
            <FormField label="Thêm nhà cung cấp" class="flex-grow">
              <FormControl 
                v-model="selectedSupplier" 
                type="select" 
                :options="suppliersList.map(s => ({ id: s.supplier_id, label: `${s.supplier_code} - ${s.supplier_name}` }))" 
              />
            </FormField>
            <BaseButton 
              color="info" 
              :icon="mdiPlus" 
              label="Thêm" 
              :disabled="!selectedSupplier" 
              @click="handleAddSupplier" 
            />
          </div>
        </div>
      </div>
    </div>

    <!-- Quotation Modal -->
    <div v-if="showQuotationModal" class="fixed inset-0 z-[60] flex items-center justify-center bg-black/60 p-4">
      <div class="bg-white dark:bg-gray-800 p-6 rounded shadow-xl w-96">
        <h3 class="font-bold mb-4">Gửi yêu cầu báo giá</h3>
        <FormField label="Hạn chót nộp báo giá">
          <FormControl type="datetime-local" v-model="deadline" />
        </FormField>
        <div class="flex justify-end gap-2 mt-6">
          <BaseButton label="Hủy" color="white" @click="showQuotationModal = false" />
          <BaseButton label="Gửi" color="success" :disabled="isSubmitting" @click="sendQuotation" />
        </div>
      </div>
    </div>
  </div>
</template>
