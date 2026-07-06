<script setup>
import { useUserStore } from '@/stores/user'
import { mdiAccount, mdiMail, mdiAsterisk, mdiFormTextboxPassword } from '@mdi/js'
import SectionMain from '@/components/SectionMain.vue'
import CardBox from '@/components/CardBox.vue'
import BaseDivider from '@/components/BaseDivider.vue'
import FormField from '@/components/FormField.vue'
import FormControl from '@/components/FormControl.vue'
import BaseButton from '@/components/BaseButton.vue'
import BaseButtons from '@/components/BaseButtons.vue'
import UserCard from '@/components/UserCard.vue'
import SectionTitleLineWithButton from '@/components/SectionTitleLineWithButton.vue'
import { storeToRefs } from 'pinia'
import { ref } from 'vue'

const userStore = useUserStore()

const {
  editUserProfileData,
  editPasswordData,
  editUserProfileSchema,
  editPasswordSchema,
} = storeToRefs(userStore)

const {
  handleEditUserProfile,
  handleEditPassword
} = userStore

const isSubmittingProfile = ref(false)
const isSubmittingPassword = ref(false)
const errorsEditUserProfile = ref({})
const errorsEditPassword = ref({})

const submitEditUserProfile = async () => {
  try {
    await editUserProfileSchema.value.validate(editUserProfileData.value, { abortEarly: false })
    isSubmittingProfile.value = true
    await handleEditUserProfile()
  } catch (error) {
    errorsEditUserProfile.value = {}
    error.inner.forEach(error => {
      errorsEditUserProfile.value[error.path] = error.message
    })
  } finally {
    isSubmittingProfile.value = false
  }
}

const submitEditPassword = async () => {
  try {
    await editPasswordSchema.value.validate(editPasswordData.value, { abortEarly: false })
    isSubmittingPassword.value = true
    await handleEditPassword()
  } catch (error) {
    errorsEditPassword.value = {}
    error.inner.forEach(error => {
      errorsEditPassword.value[error.path] = error.message
    })
  } finally {
    isSubmittingPassword.value = false
  }
}
</script>

<template>
  <SectionMain>
    <SectionTitleLineWithButton :icon="mdiAccount" title="Profile" main>
    </SectionTitleLineWithButton>

    <UserCard class="mb-6" />

    <div class="grid grid-cols-1 gap-6 lg:grid-cols-2">
      <CardBox is-form @submit.prevent="submitEditUserProfile()">
        <FormField label="Avatar" help="Max 500kb">
          <FormFilePicker label="Upload" />
        </FormField>

        <FormField label="Full name" help="Required. Your name" :error="errorsEditUserProfile.full_name ?? null">
          <FormControl v-model="editUserProfileData.full_name" :icon="mdiAccount" name="full_name" required
            autocomplete="full_name" />
        </FormField>
        <FormField label="E-mail" help="Required. Your e-mail" :error="errorsEditUserProfile.email ?? null">
          <FormControl v-model="editUserProfileData.email" :icon="mdiMail" type="email" name="email" required
            autocomplete="email" />
        </FormField>
        <FormField label="Phone" help="Required. Your phone number" :error="errorsEditUserProfile.phone ?? null">
          <FormControl v-model="editUserProfileData.phone" :icon="mdiPhone" type="tel" name="phone" required
            autocomplete="tel" />
        </FormField>

        <template #footer>
          <BaseButtons>
            <BaseButton color="info" type="submit" label="Lưu thông tin" :disabled="isSubmittingProfile" />
          </BaseButtons>
        </template>
      </CardBox>

      <CardBox is-form @submit.prevent="submitEditPassword()">
        <FormField label="Current password" help="Required. Your current password"
          :error="errorsEditPassword.password_current ?? null">
          <FormControl v-model="editPasswordData.password_current" :icon="mdiAsterisk" name="password_current"
            type="password" required autocomplete="current-password" />
        </FormField>

        <BaseDivider />

        <FormField label="New password" help="Required. New password" :error="errorsEditPassword.password ?? null">
          <FormControl v-model="editPasswordData.password" :icon="mdiFormTextboxPassword" name="password"
            type="password" required autocomplete="new-password" />
        </FormField>

        <FormField label="Confirm password" help="Required. New password one more time"
          :error="errorsEditPassword.password_confirmation ?? null">
          <FormControl v-model="editPasswordData.password_confirmation" :icon="mdiFormTextboxPassword"
            name="password_confirmation" type="password" required autocomplete="new-password" />
        </FormField>

        <BaseButtons>
          <BaseButton type="submit" color="info" label="Thay đổi mật khẩu" :disabled="isSubmittingPassword" />
        </BaseButtons>
      </CardBox>
    </div>
  </SectionMain>
</template>
