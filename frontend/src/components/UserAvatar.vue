<script setup>
import { useUserStore } from '@/stores/user'
import { storeToRefs } from 'pinia'

const userStore = useUserStore()
const { userProfileData } = storeToRefs(userStore)

</script>

<template>
  <div>
    <img :src="userProfileData?.avatar ||
      `https://ui-avatars.com/api/?name=${userProfileData?.name || 'User'}&background=random&size=128`
      " :alt="userProfileData?.name || 'User'"
      class="block h-auto w-full max-w-full rounded-full bg-gray-100 dark:bg-slate-800" />
  </div>
</template>
