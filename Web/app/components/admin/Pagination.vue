<script setup lang="ts">
interface Props {
  currentPage: number
  totalPages: number
  total: number
  limit: number
}

const props = defineProps<Props>()

const emit = defineEmits<{
  pageChange: [page: number]
}>()

const startItem = computed(() => {
  if (props.total === 0) return 0
  return (props.currentPage - 1) * props.limit + 1
})

const endItem = computed(() => {
  return Math.min(props.currentPage * props.limit, props.total)
})

const visiblePages = computed(() => {
  const pages: (number | string)[] = []
  const current = props.currentPage
  const total = props.totalPages

  if (total <= 7) {
    for (let i = 1; i <= total; i++) {
      pages.push(i)
    }
  } else {
    if (current <= 3) {
      pages.push(1, 2, 3, 4, '...', total)
    } else if (current >= total - 2) {
      pages.push(1, '...', total - 3, total - 2, total - 1, total)
    } else {
      pages.push(1, '...', current - 1, current, current + 1, '...', total)
    }
  }

  return pages
})

const goToPage = (page: number | string) => {
  if (typeof page === 'number' && page !== props.currentPage && page >= 1 && page <= props.totalPages) {
    emit('pageChange', page)
  }
}
</script>

<template>
  <div class="flex flex-col items-center justify-between gap-4 sm:flex-row">
    <!-- Info -->
    <p class="text-sm text-slate-600">
      Mostrando <span class="font-semibold text-[#111418]">{{ startItem }}</span> a
      <span class="font-semibold text-[#111418]">{{ endItem }}</span> de
      <span class="font-semibold text-[#111418]">{{ total }}</span> resultados
    </p>

    <!-- Pagination -->
    <nav v-if="totalPages > 1" class="flex items-center gap-1">
      <!-- Previous -->
      <button
        type="button"
        class="flex h-9 w-9 items-center justify-center rounded-lg border border-slate-200 text-slate-600 transition hover:bg-slate-100 disabled:cursor-not-allowed disabled:opacity-50"
        :disabled="currentPage === 1"
        @click="goToPage(currentPage - 1)"
      >
        <span class="material-symbols-outlined text-xl">chevron_left</span>
      </button>

      <!-- Pages -->
      <template v-for="(page, index) in visiblePages" :key="index">
        <span
          v-if="page === '...'"
          class="flex h-9 w-9 items-center justify-center text-slate-400"
        >
          ...
        </span>
        <button
          v-else
          type="button"
          class="flex h-9 w-9 items-center justify-center rounded-lg text-sm font-medium transition"
          :class="
            page === currentPage
              ? 'bg-rose-600 text-white'
              : 'border border-slate-200 text-slate-600 hover:bg-slate-100'
          "
          @click="goToPage(page)"
        >
          {{ page }}
        </button>
      </template>

      <!-- Next -->
      <button
        type="button"
        class="flex h-9 w-9 items-center justify-center rounded-lg border border-slate-200 text-slate-600 transition hover:bg-slate-100 disabled:cursor-not-allowed disabled:opacity-50"
        :disabled="currentPage === totalPages"
        @click="goToPage(currentPage + 1)"
      >
        <span class="material-symbols-outlined text-xl">chevron_right</span>
      </button>
    </nav>
  </div>
</template>
