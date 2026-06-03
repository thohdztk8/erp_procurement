<script setup>
import { ref, onMounted } from 'vue'
import { mdiDatabase, mdiBallotOutline, mdiAccountMultiple } from '@mdi/js'
import SectionMain from '@/components/SectionMain.vue'
import CardBox from '@/components/CardBox.vue'
import LayoutAuthenticated from '@/layouts/LayoutAuthenticated.vue'
import SectionTitleLineWithButton from '@/components/SectionTitleLineWithButton.vue'
import { masterService } from '@/services/api'

const activeTab = ref('materials')
const materials = ref([])
const suppliers = ref([])
const isLoading = ref(false)

const fetchData = async () => {
  isLoading.value = true
  try {
    const matRes = await masterService.getMaterials()
    materials.value = matRes.results || []
    
    const supRes = await masterService.getSuppliers()
    suppliers.value = supRes.results || []
  } catch (error) {
    console.error('Lỗi khi tải dữ liệu gốc:', error)
  } finally {
    isLoading.value = false
  }
}

onMounted(() => {
  fetchData()
})
</script>

<template>
  <LayoutAuthenticated>
    <SectionMain>
      <SectionTitleLineWithButton :icon="mdiDatabase" title="Dữ liệu gốc (Master Data)" main />

      <!-- Tabs chọn phân hệ dữ liệu -->
      <div class="flex space-x-4 mb-4 border-b">
        <button 
          class="pb-2 px-4 text-sm font-semibold transition"
          :class="activeTab === 'materials' ? 'border-b-2 border-blue-500 text-blue-600' : 'text-gray-500 hover:text-gray-800'"
          @click="activeTab = 'materials'"
        >
          <span class="flex items-center gap-1"><BaseIcon :path="mdiBallotOutline" /> Danh mục vật tư ({{ materials.length }})</span>
        </button>
        <button 
          class="pb-2 px-4 text-sm font-semibold transition"
          :class="activeTab === 'suppliers' ? 'border-b-2 border-blue-500 text-blue-600' : 'text-gray-500 hover:text-gray-800'"
          @click="activeTab = 'suppliers'"
        >
          <span class="flex items-center gap-1"><BaseIcon :path="mdiAccountMultiple" /> Nhà cung cấp ({{ suppliers.length }})</span>
        </button>
      </div>

      <!-- Bảng Vật Tư -->
      <CardBox v-if="activeTab === 'materials'" has-table class="mb-6">
        <div class="overflow-x-auto">
          <table class="w-full text-left text-sm text-gray-500 dark:text-gray-400">
            <thead class="bg-gray-50 text-xs uppercase text-gray-700 dark:bg-gray-700 dark:text-gray-400">
              <tr>
                <th class="px-6 py-3">ID</th>
                <th class="px-6 py-3">Mã vật tư</th>
                <th class="px-6 py-3">Tên vật tư</th>
                <th class="px-6 py-3">Trạng thái</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="mat in materials" :key="mat.material_id" class="border-b bg-white dark:bg-gray-800">
                <td class="px-6 py-4 font-bold">{{ mat.material_id }}</td>
                <td class="px-6 py-4">{{ mat.material_code }}</td>
                <td class="px-6 py-4 font-semibold text-gray-900 dark:text-white">{{ mat.material_name }}</td>
                <td class="px-6 py-4">
                  <span class="rounded-full px-2.5 py-0.5 text-xs font-medium bg-green-100 text-green-800">Hoạt động</span>
                </td>
              </tr>
              <tr v-if="materials.length === 0">
                <td colspan="4" class="text-center py-8 text-gray-400">Không tìm thấy vật tư nào.</td>
              </tr>
            </tbody>
          </table>
        </div>
      </CardBox>

      <!-- Bảng Nhà Cung Cấp -->
      <CardBox v-else has-table class="mb-6">
        <div class="overflow-x-auto">
          <table class="w-full text-left text-sm text-gray-500 dark:text-gray-400">
            <thead class="bg-gray-50 text-xs uppercase text-gray-700 dark:bg-gray-700 dark:text-gray-400">
              <tr>
                <th class="px-6 py-3">Mã</th>
                <th class="px-6 py-3">Tên nhà cung cấp</th>
                <th class="px-6 py-3">Email liên hệ</th>
                <th class="px-6 py-3">Số điện thoại</th>
                <th class="px-6 py-3">Trạng thái</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="sup in suppliers" :key="sup.supplier_id" class="border-b bg-white dark:bg-gray-800">
                <td class="px-6 py-4 font-bold">{{ sup.supplier_code }}</td>
                <td class="px-6 py-4 font-semibold text-gray-900 dark:text-white">{{ sup.supplier_name }}</td>
                <td class="px-6 py-4">{{ sup.contact_email }}</td>
                <td class="px-6 py-4">{{ sup.contact_phone || '-' }}</td>
                <td class="px-6 py-4">
                  <span class="rounded-full px-2.5 py-0.5 text-xs font-medium bg-green-100 text-green-800">Hoạt động</span>
                </td>
              </tr>
              <tr v-if="suppliers.length === 0">
                <td colspan="5" class="text-center py-8 text-gray-400">Không tìm thấy nhà cung cấp nào.</td>
              </tr>
            </tbody>
          </table>
        </div>
      </CardBox>
    </SectionMain>
  </LayoutAuthenticated>
</template>
