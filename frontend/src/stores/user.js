import { defineStore } from 'pinia';
import { ref } from 'vue';
import api from '@/services/api';


export const useUserStore = defineStore('user', () => {
  const userProfileData = ref({
    user_id: "",
    branch_name: "",
    dept_name: "",
    username: "",
    full_name: "",
    email: "",
    phone: "",
    avatar: "",
    role: "",
    permissions: [],
  });

  const editUserProfileData = ref({
    user_id: "",
    full_name: "",
    email: "",
    phone: "",
    avatar: "",
  });

  const editPasswordData = ref({
    user_id: "",
    currentPassword: "",
    newPassword: "",
    confirmPassword: "",
  });

  function resetUserProfileData() {
    userProfileData.value = {
      user_id: "",
      username: "",
      full_name: "",
      email: "",
      phone: "",
      avatar: "",
    };
  }

  function resetEditUserProfileData() {
    editUserProfileData.value = {
      user_id: "",
      full_name: "",
      email: "",
      phone: "",
      avatar: "",
    };
  }

  function resetEditPasswordData() {
    editPasswordData.value = {
      user_id: "",
      currentPassword: "",
      newPassword: "",
      confirmPassword: "",
    };
  }

  async function hanldeEditUserProfile() {
    const res = await api.put(`/auth/profile`, editUserProfileData.value);
    if (res && res.data) {
      setUserProfileData(res.data);
    }
  }

  async function handleEditPassword() {
    const res = await api.post(`/auth/change-password`, editPasswordData.value);
    if (res && res.data) {
      resetEditPasswordData();
    }
  }

  function logoutUser() {
    resetUserProfileData();
    resetEditUserProfileData();
    resetEditPasswordData();
  }

  function setUserProfileData(data) {
    userProfileData.value = data;
    editUserProfileData.value = {
      user_id: data.user_id ?? '',
      full_name: data.full_name ?? '',
      email: data.email ?? '',
      phone: data.phone ?? '',
      avatar: data.avatar ?? '',
    };
    editPasswordData.value.user_id = data.user_id;
  }

  async function fetchUserProfile() {
    try {
      const res = await api.get('/auth/profile');
      if (res && res.data) {
        setUserProfileData(res.data);
      }
    } catch (error) {
      console.error('Error fetching user profile:', error);
    }
  }

  return {
    userProfileData,
    editUserProfileData,
    editPasswordData,
    hanldeEditUserProfile,
    handleEditPassword,
    fetchUserProfile,
    logoutUser,
    setUserProfileData,
  };
});