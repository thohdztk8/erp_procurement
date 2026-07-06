<script setup>
import { reactive, ref, onMounted } from 'vue'
import { useMainStore } from '@/stores/main'
import { mdiAccount, mdiMail, mdiAsterisk, mdiFormTextboxPassword, mdiPhone } from '@mdi/js'
import SectionMain from '@/components/SectionMain.vue'
import CardBox from '@/components/CardBox.vue'
import BaseDivider from '@/components/BaseDivider.vue'
import FormField from '@/components/FormField.vue'
import FormControl from '@/components/FormControl.vue'
import BaseButton from '@/components/BaseButton.vue'
import BaseButtons from '@/components/BaseButtons.vue'
import UserCard from '@/components/UserCard.vue'
import LayoutAuthenticated from '@/layouts/LayoutAuthenticated.vue'
import SectionTitleLineWithButton from '@/components/SectionTitleLineWithButton.vue'
import { authService } from '@/services/api.js'

const mainStore = useMainStore()

const profileForm = reactive({
  full_name: mainStore.userName,
  email: mainStore.userEmail,
  phone: mainStore.userPhone,
})

const passwordForm = reactive({
  password_current: '',
  password: '',
  password_confirmation: '',
})

const isSubmittingProfile = ref(false)
const isSubmittingPass = ref(false)

onMounted(async () => {
  try {
    const response = await authService.getProfile()
    if (response && response.data) {
      mainStore.setUser(response.data)
      profileForm.full_name = response.data.full_name || ''
      profileForm.email = response.data.email || ''
      profileForm.phone = response.data.phone || ''
    }
  } catch (error) {
    console.error('Không thể tải thông tin profile từ DB:', error)
  }
})

const submitProfile = async () => {
  if (isSubmittingProfile.value) return

  const name = (profileForm.full_name || '').trim()
  if (name.length < 2) {
    alert('Họ và tên phải có độ dài tối thiểu 2 ký tự.')
    return
  }

  const emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
  if (!emailPattern.test(profileForm.email)) {
    alert('Địa chỉ e-mail không hợp lệ.')
    return
  }

  if (profileForm.phone) {
    const phonePattern = /^(0|\+84)(3|5|7|8|9|1[2689])([0-9]{8})$/
    if (!phonePattern.test(profileForm.phone.trim())) {
      alert('Số điện thoại không đúng định dạng Việt Nam.')
      return
    }
  }

  isSubmittingProfile.value = true
  try {
    const response = await authService.updateProfile({
      full_name: profileForm.full_name,
      email: profileForm.email,
      phone: profileForm.phone,
    })
    mainStore.setUser(response.data)
    alert(response.message || 'Cập nhật thông tin cá nhân thành công!')
  } catch (error) {
    console.error(error)
  } finally {
    isSubmittingProfile.value = false
  }
}

const submitPass = async () => {
  if (isSubmittingPass.value) return

  if (passwordForm.password !== passwordForm.password_confirmation) {
    alert('Xác nhận mật khẩu mới không khớp.')
    return
  }

  if (passwordForm.password.length < 8) {
    alert('Mật khẩu mới phải dài tối thiểu 8 ký tự.')
    return
  }

  if (!/[A-Z]/.test(passwordForm.password)) {
    alert('Mật khẩu mới phải chứa ít nhất một chữ viết hoa.')
    return
  }

  if (!/[a-z]/.test(passwordForm.password)) {
    alert('Mật khẩu mới phải chứa ít nhất một chữ viết thường.')
    return
  }

  if (!/[0-9]/.test(passwordForm.password)) {
    alert('Mật khẩu mới phải chứa ít nhất một số.')
    return
  }

  isSubmittingPass.value = true
  try {
    const response = await authService.changePassword({
      password_current: passwordForm.password_current,
      password: passwordForm.password,
      password_confirmation: passwordForm.password_confirmation,
    })
    alert(response.message || 'Thay đổi mật khẩu thành công!')
    passwordForm.password_current = ''
    passwordForm.password = ''
    passwordForm.password_confirmation = ''
  } catch (error) {
    console.error(error)
  } finally {
    isSubmittingPass.value = false
  }
}
</script>

<template>
  <LayoutAuthenticated>
    <SectionMain>
      <SectionTitleLineWithButton :icon="mdiAccount" title="Profile" main>
      </SectionTitleLineWithButton>

      <UserCard class="mb-6" />

      <div class="grid grid-cols-1 gap-6 lg:grid-cols-2">
        <CardBox is-form @submit.prevent="submitProfile">
          <FormField label="Họ và tên" help="Bắt buộc. Tên đầy đủ của bạn">
            <FormControl
              v-model="profileForm.full_name"
              :icon="mdiAccount"
              name="fullname"
              required
              autocomplete="name"
            />
          </FormField>
          <FormField label="E-mail" help="Bắt buộc. Địa chỉ e-mail">
            <FormControl
              v-model="profileForm.email"
              :icon="mdiMail"
              type="email"
              name="email"
              required
              autocomplete="email"
            />
          </FormField>
          <FormField label="Số điện thoại" help="Số điện thoại liên lạc">
            <FormControl
              v-model="profileForm.phone"
              :icon="mdiPhone"
              type="tel"
              name="phone"
              autocomplete="tel"
            />
          </FormField>

          <template #footer>
            <BaseButtons>
              <BaseButton color="info" type="submit" label="Lưu thông tin" :disabled="isSubmittingProfile" />
            </BaseButtons>
          </template>
        </CardBox>

        <CardBox is-form @submit.prevent="submitPass">
          <FormField label="Mật khẩu hiện tại" help="Bắt buộc. Mật khẩu hiện tại của bạn">
            <FormControl
              v-model="passwordForm.password_current"
              :icon="mdiAsterisk"
              name="password_current"
              type="password"
              required
              autocomplete="current-password"
            />
          </FormField>

          <BaseDivider />

          <FormField label="Mật khẩu mới" help="Bắt buộc. Mật khẩu mới">
            <FormControl
              v-model="passwordForm.password"
              :icon="mdiFormTextboxPassword"
              name="password"
              type="password"
              required
              autocomplete="new-password"
            />
          </FormField>

          <FormField label="Xác nhận mật khẩu mới" help="Bắt buộc. Nhập lại mật khẩu mới">
            <FormControl
              v-model="passwordForm.password_confirmation"
              :icon="mdiFormTextboxPassword"
              name="password_confirmation"
              type="password"
              required
              autocomplete="new-password"
            />
          </FormField>

          <template #footer>
            <BaseButtons>
              <BaseButton type="submit" color="info" label="Đổi mật khẩu" :disabled="isSubmittingPass" />
            </BaseButtons>
          </template>
        </CardBox>
      </div>
    </SectionMain>
  </LayoutAuthenticated>
</template>

