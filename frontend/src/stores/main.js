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
  const userPermissions = ref(userFromStorage.permissions || [])

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
    if (payload.role_code) {
      userRole.value = payload.role_code
    }
    if (payload.branch_name) {
      userBranch.value = payload.branch_name
    }
    if (payload.dept_name) {
      userDept.value = payload.dept_name
    }
    if (payload.permissions !== undefined) {
      userPermissions.value = payload.permissions
    }
    
    // Đồng bộ lại vào localStorage
    if (typeof localStorage !== 'undefined') {
      const user = JSON.parse(localStorage.getItem('user') || '{}')
      user.full_name = userName.value
      user.email = userEmail.value
      user.phone = userPhone.value
      user.role_code = userRole.value
      user.branch_name = userBranch.value
      user.dept_name = userDept.value
      user.permissions = userPermissions.value
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
    userPermissions,
    userAvatar,
    isFieldFocusRegistered,
    clients,
    history,
    setUser,
    fetchSampleClients,
    fetchSampleHistory,
  }
})

