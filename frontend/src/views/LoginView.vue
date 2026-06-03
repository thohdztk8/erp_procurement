<script setup>
import { ref, reactive } from 'vue'
import { useRouter } from 'vue-router'
import { mdiAccount, mdiAsterisk } from '@mdi/js'
import SectionFullScreen from '@/components/SectionFullScreen.vue'
import CardBox from '@/components/CardBox.vue'
import FormField from '@/components/FormField.vue'
import FormControl from '@/components/FormControl.vue'
import BaseButton from '@/components/BaseButton.vue'
import BaseButtons from '@/components/BaseButtons.vue'
import LayoutGuest from '@/layouts/LayoutGuest.vue'
import { authService } from '@/services/api'

const form = reactive({
  login: 'admin',
  pass: 'Admin@Password123',
})

const errorMessage = ref('')
const isLoading = ref(false)
const router = useRouter()

const submit = async () => {
  try {
    errorMessage.value = ''
    isLoading.value = true
    await authService.login(form.login, form.pass)
    router.push('/dashboard')
  } catch (error) {
    console.error(error)
    errorMessage.value = error.response?.data?.detail || error.response?.data?.message || 'Đăng nhập thất bại. Vui lòng kiểm tra lại tài khoản và mật khẩu.'
  } finally {
    isLoading.value = false
  }
}
</script>

<template>
  <LayoutGuest>
    <SectionFullScreen v-slot="{ cardClass }" bg="purplePink">
      <CardBox :class="cardClass" is-form @submit.prevent="submit">
        <h2 class="text-2xl font-bold text-center mb-6 text-gray-800 dark:text-white">
          ERP Procurement
        </h2>
        
        <!-- Hộp thông báo lỗi -->
        <div v-if="errorMessage" class="mb-4 p-3 bg-red-100 border border-red-400 text-red-700 rounded text-sm text-center">
          {{ errorMessage }}
        </div>

        <FormField label="Tài khoản" help="Mặc định: admin">
          <FormControl
            v-model="form.login"
            :icon="mdiAccount"
            name="login"
            autocomplete="username"
            required
          />
        </FormField>

        <FormField label="Mật khẩu" help="Mặc định: Admin@Password123">
          <FormControl
            v-model="form.pass"
            :icon="mdiAsterisk"
            type="password"
            name="password"
            autocomplete="current-password"
            required
          />
        </FormField>

        <template #footer>
          <BaseButtons class="flex justify-center mt-4">
            <BaseButton 
              type="submit" 
              color="info" 
              :label="isLoading ? 'Đang đăng nhập...' : 'Đăng nhập'" 
              :disabled="isLoading" 
            />
          </BaseButtons>
        </template>
      </CardBox>
    </SectionFullScreen>
  </LayoutGuest>
</template>
