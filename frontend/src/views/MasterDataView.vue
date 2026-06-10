<script setup>
import { ref, onMounted } from 'vue'
import { mdiDatabase, mdiBallotOutline, mdiAccountMultiple, mdiAccountLock, mdiPlus, mdiCashMarker } from '@mdi/js'
import SectionMain from '@/components/SectionMain.vue'
import CardBox from '@/components/CardBox.vue'
import BaseButton from '@/components/BaseButton.vue'
import BaseButtons from '@/components/BaseButtons.vue'
import LayoutAuthenticated from '@/layouts/LayoutAuthenticated.vue'
import SectionTitleLineWithButton from '@/components/SectionTitleLineWithButton.vue'
import { masterService } from '@/services/api'
import UserManageModal from '@/components/UserManageModal.vue'
import MaterialCreateModal from '@/components/MaterialCreateModal.vue'
import SupplierCreateModal from '@/components/SupplierCreateModal.vue'
import ContractPriceModal from '@/components/ContractPriceModal.vue'
import BaseIcon from '@/components/BaseIcon.vue'

const activeTab = ref('materials')
const materials = ref([])
const suppliers = ref([])
const users = ref([])
const isLoading = ref(false)

const showUserModal = ref(false)
const showMaterialModal = ref(false)
const showSupplierModal = ref(false)
const showPriceModal = ref(false)

const selectedUser = ref(null)
const selectedSupplier = ref(null)

const currentUser = ref(JSON.parse(localStorage.getItem('user') || '{}'))
const isAdmin = ref(currentUser.value.role_code === 'ADMIN' || currentUser.value.username === 'admin')

const fetchData = async () => {
  isLoading.value = true
  try {
    const matRes = await masterService.getMaterials()
    materials.value = matRes.results || []
    
    const supRes = await masterService.getSuppliers()
    suppliers.value = supRes.results || []

    if (isAdmin.value) {
      const userRes = await masterService.getUsers()
      users.value = userRes.results || []
    }
  } catch (error) {
    console.error('Lỗi khi tải dữ liệu gốc:', error)
  } finally {
    isLoading.value = false
  }
}

onMounted(() => {
  fetchData()
})

const handleSaveUser = async (data) => {
  try {
    if (selectedUser.value) {
      await masterService.updateUser(selectedUser.value.user_id, data)
    } else {
      await masterService.createUser(data)
    }
    showUserModal.value = false
    fetchData()
  } catch (e) {
    alert('Không thể lưu thông tin tài khoản.')
  }
}

const handleSaveMaterial = async (data) => {
  try {
    await masterService.createMaterial(data)
    showMaterialModal.value = false
    fetchData()
  } catch (e) {
    alert('Không thể thêm vật tư.')
  }
}

const handleSaveSupplier = async (data) => {
  try {
    await masterService.createSupplier(data)
    showSupplierModal.value = false
    fetchData()
  } catch (e) {
    alert('Không thể thêm nhà cung cấp. Trùng mã số thuế?')
  }
}

const handleSavePrice = async (data) => {
  try {
    await masterService.addContractPrice(selectedSupplier.value.supplier_id, data)
    showPriceModal.value = false
    alert('Thêm bảng giá khung thành công!')
  } catch (e) {
    alert('Không thể lưu bảng giá khung.')
  }
}
</script>

<template>
  <LayoutAuthenticated>
    <SectionMain>
      <SectionTitleLineWithButton :icon="mdiDatabase" title="Dữ liệu gốc (Master Data)" main>
        <BaseButton
          v-if="activeTab === 'materials'"
          :icon="mdiPlus"
          label="Thêm vật tư"
          color="contrast"
          small
          @click="showMaterialModal = true"
        />
        <BaseButton
          v-if="activeTab === 'suppliers'"
          :icon="mdiPlus"
          label="Thêm nhà cung cấp"
          color="contrast"
          small
          @click="showSupplierModal = true"
        />
        <BaseButton
          v-slot:default
          v-if="activeTab === 'users' && isAdmin"
          :icon="mdiPlus"
          label="Thêm tài khoản"
          color="contrast"
          small
          @click="selectedUser = null; showUserModal = true"
        />
      </SectionTitleLineWithButton>

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
        <button 
          v-if="isAdmin"
          class="pb-2 px-4 text-sm font-semibold transition"
          :class="activeTab === 'users' ? 'border-b-2 border-blue-500 text-blue-600' : 'text-gray-500 hover:text-gray-800'"
          @click="activeTab = 'users'"
        >
          <span class="flex items-center gap-1"><BaseIcon :path="mdiAccountLock" /> Quản lý tài khoản & Quyền ({{ users.length }})</span>
        </button>
      </div>

      <!-- Bảng Vật Tư -->
      <CardBox v-if="activeTab === 'materials'" has-table class="mb-6">
        <table class="w-full text-left text-sm text-gray-500 dark:text-gray-400">
          <thead class="bg-gray-50 text-xs uppercase text-gray-700 dark:bg-gray-700 dark:text-gray-400">
            <tr>
              <th class="px-6 py-3">Mã vật tư</th>
              <th class="px-6 py-3">Tên vật tư</th>
              <th class="px-6 py-3">Trạng thái</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="mat in materials" :key="mat.material_id" class="border-b bg-white dark:bg-gray-800">
              <td class="px-6 py-4 font-bold">{{ mat.material_code }}</td>
              <td class="px-6 py-4 font-semibold text-gray-900 dark:text-white">{{ mat.material_name }}</td>
              <td class="px-6 py-4">
                <span class="rounded-full px-2.5 py-0.5 text-xs font-medium bg-green-100 text-green-800">Hoạt động</span>
              </td>
            </tr>
          </tbody>
        </table>
      </CardBox>

      <!-- Bảng Nhà Cung Cấp -->
      <CardBox v-else-if="activeTab === 'suppliers'" has-table class="mb-6">
        <table class="w-full text-left text-sm text-gray-500 dark:text-gray-400">
          <thead class="bg-gray-50 text-xs uppercase text-gray-700 dark:bg-gray-700 dark:text-gray-400">
            <tr>
              <th class="px-6 py-3">Mã</th>
              <th class="px-6 py-3">Tên nhà cung cấp</th>
              <th class="px-6 py-3">Mã số thuế</th>
              <th class="px-6 py-3">Số điện thoại</th>
              <th class="px-6 py-3 text-right">Thao tác</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="sup in suppliers" :key="sup.supplier_id" class="border-b bg-white dark:bg-gray-800">
              <td class="px-6 py-4 font-bold">{{ sup.supplier_code }}</td>
              <td class="px-6 py-4 font-semibold text-gray-900 dark:text-white">{{ sup.supplier_name }}</td>
              <td class="px-6 py-4">{{ sup.tax_code }}</td>
              <td class="px-6 py-4">{{ sup.contact_phone || '-' }}</td>
              <td class="px-6 py-4 text-right">
                <BaseButton color="info" :icon="mdiCashMarker" label="Giá khung" small @click="selectedSupplier = sup; showPriceModal = true" />
              </td>
            </tr>
          </tbody>
        </table>
      </CardBox>

      <!-- Bảng Tài Khoản Người Dùng -->
      <CardBox v-else-if="activeTab === 'users'" has-table class="mb-6">
        <table class="w-full text-left text-sm text-gray-500 dark:text-gray-400">
          <thead class="bg-gray-50 text-xs uppercase text-gray-700 dark:bg-gray-700 dark:text-gray-400">
            <tr>
              <th class="px-6 py-3">Tên đăng nhập</th>
              <th class="px-6 py-3">Họ tên</th>
              <th class="px-6 py-3">Email</th>
              <th class="px-6 py-3">Vai trò</th>
              <th class="px-6 py-3">Trạng thái</th>
              <th class="px-6 py-3 text-right">Thao tác</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="usr in users" :key="usr.user_id" class="border-b bg-white dark:bg-gray-800">
              <td class="px-6 py-4 font-bold text-blue-600">{{ usr.username }}</td>
              <td class="px-6 py-4 font-semibold text-gray-900 dark:text-white">{{ usr.full_name }}</td>
              <td class="px-6 py-4">{{ usr.email }}</td>
              <td class="px-6 py-4 text-xs font-semibold">{{ usr.role_name || usr.role_code }}</td>
              <td class="px-6 py-4">
                <span class="rounded px-2.5 py-0.5 text-xs font-medium" :class="usr.is_active ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'">
                  {{ usr.is_active ? 'Hoạt động' : 'Bị khóa' }}
                </span>
              </td>
              <td class="px-6 py-4 text-right">
                <BaseButton color="info" label="Sửa" small @click="selectedUser = usr; showUserModal = true" />
              </td>
            </tr>
          </tbody>
        </table>
      </CardBox>
    </SectionMain>

    <!-- Modals -->
    <UserManageModal v-if="showUserModal" :user="selectedUser" @close="showUserModal = false" @save="handleSaveUser" />
    <MaterialCreateModal v-if="showMaterialModal" @close="showMaterialModal = false" @save="handleSaveMaterial" />
    <SupplierCreateModal v-if="showSupplierModal" @close="showSupplierModal = false" @save="handleSaveSupplier" />
    <ContractPriceModal v-if="showPriceModal" :supplier="selectedSupplier" :materials="materials" @close="showPriceModal = false" @save="handleSavePrice" />
  </LayoutAuthenticated>
</template>
