import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import axios from 'axios'

export const useMainStore = defineStore('main', () => {
  const userFromStorage = typeof localStorage !== 'undefined' ? JSON.parse(localStorage.getItem('user') || '{}') : {}
  const userName = ref(userFromStorage.full_name || 'John Doe')
  const userEmail = ref(userFromStorage.email || 'doe.doe.doe@example.com')
  const userPhone = ref(userFromStorage.phone || '')
  const userRole = ref(userFromStorage.role_code || '')
  const userBranch = ref(userFromStorage.branch_name || '')
  const userDept = ref(userFromStorage.dept_name || '')

  const userAvatar = computed(
    () =>
      `https://api.dicebear.com/7.x/avataaars/svg?seed=${userEmail.value.replace(
        /[^a-z0-9]+/gi,
        '-',
      )}`,
  )

  const isFieldFocusRegistered = ref(false)

  const clients = ref([])
  const history = ref([])

  function setUser(payload) {
    if (payload.full_name || payload.name) {
      userName.value = payload.full_name || payload.name
    }
    if (payload.email) {
      userEmail.value = payload.email
    }
    if (payload.phone !== undefined) {
      userPhone.value = payload.phone
    }
    
    // Đồng bộ lại vào localStorage
    if (typeof localStorage !== 'undefined') {
      const user = JSON.parse(localStorage.getItem('user') || '{}')
      user.full_name = userName.value
      user.email = userEmail.value
      user.phone = userPhone.value
      localStorage.setItem('user', JSON.stringify(user))
    }
  }

  function fetchSampleClients() {
    axios
      .get(`data-sources/clients.json?v=3`)
      .then((result) => {
        clients.value = result?.data?.data
      })
      .catch((error) => {
        alert(error.message)
      })
  }

  function fetchSampleHistory() {
    axios
      .get(`data-sources/history.json`)
      .then((result) => {
        history.value = result?.data?.data
      })
      .catch((error) => {
        alert(error.message)
      })
  }

  return {
    userName,
    userEmail,
    userPhone,
    userRole,
    userBranch,
    userDept,
    userAvatar,
    isFieldFocusRegistered,
    clients,
    history,
    setUser,
    fetchSampleClients,
    fetchSampleHistory,
  }
})

