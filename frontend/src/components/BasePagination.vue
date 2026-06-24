<script setup>
/**
 * Component phân trang dùng chung (BasePagination)
 * 
 * Props:
 * - currentPage (Number): Trang hiện tại (1-based index).
 * - totalPages (Number): Tổng số trang.
 * - totalItems (Number): Tổng số dòng/bản ghi.
 * - pageSize (Number): Kích thước một trang (mặc định 20).
 * 
 * Events:
 * - change-page (page: Number): Phát ra sự kiện chuyển trang khi click vào nút số trang.
 */
import { computed } from 'vue'
import BaseLevel from '@/components/BaseLevel.vue'
import BaseButtons from '@/components/BaseButtons.vue'
import BaseButton from '@/components/BaseButton.vue'

const props = defineProps({
  currentPage: {
    type: Number,
    default: 1
  },
  totalPages: {
    type: Number,
    default: 1
  },
  totalItems: {
    type: Number,
    default: 0
  },
  pageSize: {
    type: Number,
    default: 20
  }
})

const emit = defineEmits(['change-page'])

// Tính toán danh sách số trang cần hiển thị (tối đa 5 trang xung quanh trang hiện tại)
const pagesList = computed(() => {
  const pages = []
  const start = Math.max(1, props.currentPage - 2)
  const end = Math.min(props.totalPages, start + 4)
  const adjustedStart = Math.max(1, end - 4)
  
  for (let i = adjustedStart; i <= end; i++) {
    pages.push(i)
  }
  return pages
})

/**
 * Xử lý chọn chuyển trang.
 * @param {number} page - Số trang mục tiêu.
 */
const selectPage = (page) => {
  if (page >= 1 && page <= props.totalPages && page !== props.currentPage) {
    emit('change-page', page)
  }
}
</script>

<template>
  <div v-if="totalPages > 1" class="border-t border-gray-100 p-3 lg:px-6 dark:border-slate-800">
    <BaseLevel>
      <BaseButtons>
        <BaseButton
          v-if="currentPage > 1"
          label="«"
          color="whiteDark"
          small
          @click="selectPage(1)"
        />
        <BaseButton
          v-if="currentPage > 1"
          label="‹"
          color="whiteDark"
          small
          @click="selectPage(currentPage - 1)"
        />
        <BaseButton
          v-for="page in pagesList"
          :key="page"
          :active="page === currentPage"
          :label="page"
          :color="page === currentPage ? 'lightDark' : 'whiteDark'"
          small
          @click="selectPage(page)"
        />
        <BaseButton
          v-if="currentPage < totalPages"
          label="›"
          color="whiteDark"
          small
          @click="selectPage(currentPage + 1)"
        />
        <BaseButton
          v-if="currentPage < totalPages"
          label="»"
          color="whiteDark"
          small
          @click="selectPage(totalPages)"
        />
      </BaseButtons>
      <small class="text-gray-500 dark:text-slate-400">
        Trang {{ currentPage }} / {{ totalPages }} (Tổng {{ totalItems }} dòng)
      </small>
    </BaseLevel>
  </div>
</template>
