<script setup>
import { computed, ref } from 'vue'
import { useUserStore } from '@/stores/user'
import { mdiCheckDecagram } from '@mdi/js'
import BaseLevel from '@/components/BaseLevel.vue'
import UserAvatar from '@/components/UserAvatar.vue'
import CardBox from '@/components/CardBox.vue'
import FormCheckRadio from '@/components/FormCheckRadio.vue'
import PillTag from '@/components/PillTag.vue'
import { storeToRefs } from 'pinia'

const userStore = useUserStore()
const { userProfileData } = storeToRefs(userStore)

const userName = computed(() => userProfileData.value.full_name || 'User')

const userSwitchVal = ref(false)
</script>

<template>
  <CardBox>
    <div class="grid grid-cols-1 items-center gap-6 md:grid-cols-3">
      <div class="col-span-1 flex justify-center md:block">
        <UserAvatar class="h-48 w-48 lg:mx-12" />
      </div>
      <div class="col-span-1 md:col-span-2">
        <div class="space-y-3 text-center md:text-left lg:mx-12">
          <div class="flex justify-center md:block">
            <FormCheckRadio v-model="userSwitchVal" name="notifications-switch" type="switch" label="Notifications"
              :input-value="true" />
          </div>
          <h1 class="text-2xl">
            Hello, <b>{{ userName }}</b>!
          </h1>
          <p>Last login <b>12 mins ago</b> from <b>127.0.0.1</b></p>
          <div class="flex justify-center md:block">
            <PillTag label="Verified" color="info" :icon="mdiCheckDecagram" />
          </div>
        </div>
      </div>
    </div>
  </CardBox>
</template>
