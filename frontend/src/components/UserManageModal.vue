<script setup>
import { reactive, onMounted, ref } from 'vue'
import { mdiClose } from '@mdi/js'
import BaseButton from '@/components/BaseButton.vue'
import BaseButtons from '@/components/BaseButtons.vue'
import FormField from '@/components/FormField.vue'
import FormControl from '@/components/FormControl.vue'
import { masterService } from '@/services/api'

const props = defineProps({
  user: { type: Object, default: null } // If null, create mode
})

const emit = defineEmits(['close', 'save'])

const form = reactive({
  username: '',
  email: '',
  full_name: '',
  phone: '',
  branch_id: 1,
  dept_id: 1,
  role_id: 1,
  is_active: true
})

const roles = ref([])

onMounted(async () => {
  try {
    const res = await masterService.getRoles()
    roles.value = res.results || []
  } catch (error) {
    console.error(error)
  }

  if (props.user) {
    Object.assign(form, props.user)
  }
})

const submit = () => {
  if (!form.username || !form.email || !form.full_name) {
    alert('Vui lòng điền tên đăng nhập, email và họ tên.')
    return
  }
  emit('save', { ...form })
}
</script>

<template>
  <div class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
    <div class="bg-white dark:bg-gray-900 rounded-lg shadow-xl max-w-lg w-full">
      <div class="flex justify-between items-center px-6 py-4 border-b">
        <h3 class="text-lg font-bold">{{ user ? 'Cập nhật tài khoản' : 'Thêm tài khoản mới' }}</h3>
        <BaseButton :icon="mdiClose" color="whiteDark" small @click="emit('close')" />
      </div>
      <div class="p-6 grid grid-cols-1 md:grid-cols-2 gap-4">
        <FormField label="Tên đăng nhập">
          <FormControl v-model="form.username" :disabled="!!user" placeholder="username" />
        </FormField>
        <FormField label="Họ tên">
          <FormControl v-model="form.full_name" placeholder="Nguyễn Văn A" />
        </FormField>
        <FormField label="Email">
          <FormControl v-model="form.email" type="email" placeholder="email@company.com" />
        </FormField>
        <FormField label="Điện thoại">
          <FormControl v-model="form.phone" placeholder="0901234567" />
        </FormField>
        <FormField label="Vai trò">
          <select v-model="form.role_id" class="w-full bg-white dark:bg-gray-800 border rounded p-2 text-sm">
            <option v-for="role in roles" :key="role.role_id" :value="role.role_id">
              {{ role.role_name }} ({{ role.role_code }})
            </option>
          </select>
        </FormField>
        <FormField label="Trạng thái" v-if="user">
          <select v-model="form.is_active" class="w-full bg-white dark:bg-gray-800 border rounded p-2 text-sm">
            <option :value="true">Hoạt động</option>
            <option :value="false">Khóa</option>
          </select>
        </FormField>
      </div>
      <div class="flex justify-end px-6 py-4 border-t">
        <BaseButtons>
          <BaseButton color="white" label="Hủy" @click="emit('close')" />
          <BaseButton color="success" label="Lưu" @click="submit" />
        </BaseButtons>
      </div>
    </div>
  </div>
</template>
