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
import LayoutAuthenticated from '@/layouts/LayoutAuthenticated.vue'
import SectionTitleLineWithButton from '@/components/SectionTitleLineWithButton.vue'
import { storeToRefs } from 'pinia'

const userStore = useUserStore()

const {
  editUserProfileData,
  editPasswordData
} = storeToRefs(userStore)

const {
  hanldeEditUserProfile,
  handleEditPassword
} = userStore

</script>

<template>
  <SectionMain>
    <SectionTitleLineWithButton :icon="mdiAccount" title="Profile" main>
    </SectionTitleLineWithButton>

    <UserCard class="mb-6" />

    <div class="grid grid-cols-1 gap-6 lg:grid-cols-2">
      <CardBox is-form @submit.prevent="hanldeEditUserProfile()">
        <FormField label="Avatar" help="Max 500kb">
          <FormFilePicker label="Upload" />
        </FormField>

        <FormField label="Full name" help="Required. Your name">
          <FormControl v-model="editUserProfileData.full_name" :icon="mdiAccount" name="full_name" required
            autocomplete="full_name" />
        </FormField>
        <FormField label="E-mail" help="Required. Your e-mail">
          <FormControl v-model="editUserProfileData.email" :icon="mdiMail" type="email" name="email" required
            autocomplete="email" />
        </FormField>
        <FormField label="Phone" help="Required. Your phone number">
          <FormControl v-model="editUserProfileData.phone" :icon="mdiPhone" type="tel" name="phone" required
            autocomplete="tel" />
        </FormField>

        <template #footer>
          <BaseButtons>
            <BaseButton color="info" type="submit" label="Lưu thông tin" :disabled="isSubmittingProfile" />
          </BaseButtons>
        </template>
      </CardBox>

      <CardBox is-form @submit.prevent="handleEditPassword()">
        <FormField label="Current password" help="Required. Your current password">
          <FormControl v-model="editPasswordData.currentPassword" :icon="mdiAsterisk" name="password_current"
            type="password" required autocomplete="current-password" />
        </FormField>

        <BaseDivider />

        <FormField label="New password" help="Required. New password">
          <FormControl v-model="editPasswordData.newPassword" :icon="mdiFormTextboxPassword" name="password"
            type="password" required autocomplete="new-password" />
        </FormField>

        <FormField label="Confirm password" help="Required. New password one more time">
          <FormControl v-model="editPasswordData.confirmPassword" :icon="mdiFormTextboxPassword"
            name="password_confirmation" type="password" required autocomplete="new-password" />
        </FormField>

        <BaseButtons>
          <BaseButton type="submit" color="info" label="Submit" />
          <BaseButton color="info" label="Options" outline />
        </BaseButtons>
      </CardBox>
    </div>
  </SectionMain>
</template>
