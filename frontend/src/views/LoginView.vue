<script setup>
import { ref, reactive } from 'vue'
import { useRouter } from 'vue-router'
import { mdiAccount, mdiLock, mdiEye, mdiEyeOff } from '@mdi/js'
import BaseIcon from '@/components/BaseIcon.vue'
import LayoutGuest from '@/layouts/LayoutGuest.vue'
import { authService } from '@/services/api'

const form = reactive({
  login: '',
  pass: '',
})

const errorMessage = ref('')
const isLoading = ref(false)
const showPassword = ref(false)
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
    <div class="min-h-screen flex bg-slate-100 dark:bg-slate-950">
      <!-- Left side: Visual & Branding (visible on desktop) -->
      <div class="hidden lg:flex lg:w-7/12 bg-slate-900 text-white p-16 flex-col justify-between relative overflow-hidden select-none">
        <!-- Abstract background pattern -->
        <div class="absolute inset-0 opacity-20 pointer-events-none" style="background-image: radial-gradient(rgba(255, 255, 255, 0.15) 1.5px, transparent 0); background-size: 32px 32px;"></div>
        <div class="absolute -top-40 -left-40 w-96 h-96 rounded-full bg-blue-600 opacity-20 blur-3xl pointer-events-none"></div>
        <div class="absolute -bottom-40 -right-40 w-96 h-96 rounded-full bg-indigo-600 opacity-25 blur-3xl pointer-events-none"></div>
        
        <!-- Logo/Header -->
        <div class="z-10 flex items-center gap-3">
          <div class="w-10 h-10 rounded-xl bg-gradient-to-tr from-blue-500 to-indigo-600 flex items-center justify-center font-bold text-xl shadow-lg shadow-blue-500/20">
            E
          </div>
          <span class="text-xl font-bold tracking-wider bg-clip-text text-transparent bg-gradient-to-r from-white to-gray-300">
            ERP Procurement
          </span>
        </div>

        <!-- Middle Content -->
        <div class="z-10 max-w-xl my-auto">
          <h1 class="text-4xl font-extrabold leading-tight mb-4 tracking-tight">
            Hệ thống Quản lý Mua sắm & Chuỗi cung ứng Doanh nghiệp
          </h1>
          <p class="text-gray-400 text-lg leading-relaxed">
            Giải pháp số hóa toàn diện quy trình mua sắm từ lập yêu cầu (PR), chào hàng cạnh tranh, quản lý hợp đồng đến đối đối chiếu thanh toán 3 bên.
          </p>
        </div>

        <!-- Footer -->
        <div class="z-10 text-gray-500 text-sm flex justify-between items-center border-t border-slate-800 pt-6">
          <span>&copy; 2026 ERP Procurement. All rights reserved.</span>
          <span class="flex gap-4">
            <a href="#" class="hover:text-gray-300 transition">Bảo mật</a>
            <a href="#" class="hover:text-gray-300 transition">Hỗ trợ</a>
          </span>
        </div>
      </div>

      <!-- Right side: Login Form -->
      <div class="w-full lg:w-5/12 flex flex-col justify-center px-8 sm:px-16 lg:px-12 xl:px-20 py-12 relative">
        <div class="max-w-md w-full mx-auto">
          <!-- Logo for mobile screen -->
          <div class="flex lg:hidden items-center gap-2 mb-8 justify-center">
            <div class="w-8 h-8 rounded-lg bg-blue-600 flex items-center justify-center font-bold text-white">
              E
            </div>
            <span class="text-lg font-bold text-slate-800 dark:text-white">ERP Procurement</span>
          </div>

          <!-- Title -->
          <div class="mb-8 text-center lg:text-left">
            <h2 class="text-3xl font-bold text-slate-800 dark:text-white mb-2">Đăng nhập</h2>
            <p class="text-slate-500 dark:text-slate-400">Vui lòng nhập tài khoản để truy cập hệ thống</p>
          </div>

          <!-- Error Alert Box -->
          <div v-if="errorMessage" class="mb-6 p-4 bg-rose-50 dark:bg-rose-950/30 border border-rose-200 dark:border-rose-800 text-rose-700 dark:text-rose-400 rounded-xl text-sm flex items-center gap-2">
            <span class="font-medium">{{ errorMessage }}</span>
          </div>

          <!-- Form -->
          <form @submit.prevent="submit" class="space-y-6">
            <div>
              <label class="block text-sm font-semibold text-slate-700 dark:text-slate-300 mb-2">Tài khoản</label>
              <div class="relative">
                <span class="absolute inset-y-0 left-0 pl-3 flex items-center text-slate-400">
                  <BaseIcon :path="mdiAccount" w="w-5" h="h-5" />
                </span>
                <input 
                  v-model="form.login" 
                  type="text" 
                  required 
                  class="w-full pl-10 pr-4 py-3 bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-xl focus:outline-hidden focus:border-blue-500 focus:ring-4 focus:ring-blue-100 dark:focus:ring-blue-950/30 text-slate-800 dark:text-slate-100 transition"
                  placeholder="Nhập tên đăng nhập hoặc email"
                />
              </div>
            </div>

            <div>
              <div class="flex justify-between items-center mb-2">
                <label class="block text-sm font-semibold text-slate-700 dark:text-slate-300">Mật khẩu</label>
                <a href="#" class="text-sm text-blue-600 hover:text-blue-700 font-medium">Quên mật khẩu?</a>
              </div>
              <div class="relative">
                <span class="absolute inset-y-0 left-0 pl-3 flex items-center text-slate-400">
                  <BaseIcon :path="mdiLock" w="w-5" h="h-5" />
                </span>
                <input 
                  v-model="form.pass" 
                  :type="showPassword ? 'text' : 'password'" 
                  required 
                  class="w-full pl-10 pr-12 py-3 bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-xl focus:outline-hidden focus:border-blue-500 focus:ring-4 focus:ring-blue-100 dark:focus:ring-blue-950/30 text-slate-800 dark:text-slate-100 transition"
                  placeholder="Nhập mật khẩu"
                />
                <button 
                  type="button"
                  @click="showPassword = !showPassword"
                  class="absolute inset-y-0 right-0 pr-3 flex items-center text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 transition"
                >
                  <BaseIcon :path="showPassword ? mdiEyeOff : mdiEye" w="w-5" h="h-5" />
                </button>
              </div>
            </div>

            <button 
              type="submit" 
              :disabled="isLoading"
              class="w-full py-3 bg-blue-600 hover:bg-blue-700 disabled:bg-blue-400 text-white font-bold rounded-xl transition shadow-lg shadow-blue-500/20 flex justify-center items-center gap-2"
            >
              <span v-if="isLoading" class="w-5 h-5 border-2 border-white border-t-transparent rounded-full animate-spin"></span>
              <span>{{ isLoading ? 'Đang xác thực...' : 'Đăng nhập hệ thống' }}</span>
            </button>
          </form>
        </div>
      </div>
    </div>
  </LayoutGuest>
</template>
