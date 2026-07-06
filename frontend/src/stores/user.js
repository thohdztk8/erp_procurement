import { defineStore } from 'pinia';
import { ref } from 'vue';
import api from '@/services/api';
import * as yup from 'yup';


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

  const editUserProfileSchema = ref(
    yup.object().shape({
      full_name: yup.string().required('Full name is required'),
      email: yup.string().email('Invalid email format').required('Email is required'),
      phone: yup.string().matches(/^\d{10}$/, 'Phone number must be 10 digits').required('Phone number is required'),
    })
  )

  const editPasswordData = ref({
    user_id: "",
    currentPassword: "",
    newPassword: "",
    confirmPassword: "",
  });

  const editPasswordSchema = ref(
    yup.object().shape({
      currentPassword: yup.string().required('Current password is required'),
      newPassword: yup.string().min(6, 'New password must be at least 6 characters').required('New password is required'),
      confirmPassword: yup.string()
        .oneOf([yup.ref('newPassword'), null], 'Passwords must match')
        .required('Confirm password is required'),
    })
  )

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

  async function handleEditUserProfile() {
    const res = await api.put(`/auth/profile`, editUserProfileData.value);
    if (res && res.data) {
      setUserProfileData(res.data);
    }

    return res;
  }

  async function handleEditPassword() {
    const res = await api.post(`/auth/change-password`, editPasswordData.value);
    if (res && res.data) {
      resetEditPasswordData();
    }

    return res;
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
    editUserProfileSchema,
    editPasswordSchema,
    handleEditUserProfile,
    handleEditPassword,
    fetchUserProfile,
    logoutUser,
    setUserProfileData,
  };
});