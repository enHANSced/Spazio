<script setup lang="ts">
import { ref, watch, onMounted } from 'vue'
import type { Space } from '../../../types/space'
import { adminService, type Pagination } from '../../../services/admin.service'
import { useToast } from '../../../composables/useToast'

definePageMeta({
  layout: 'admin',
  middleware: 'admin'
})

useSeoMeta({
  title: 'Gestión de Espacios - Admin Spazio',
  description: 'Administrar todos los espacios del sistema'
})

const toast = useToast()

// State
const spaces = ref<Space[]>([])
const pagination = ref<Pagination | null>(null)
const loading = ref(true)
const currentPage = ref(1)
const limit = ref(10)

// Filters
const searchQuery = ref('')
const statusFilter = ref('')

// Modal state
const showConfirmModal = ref(false)
const confirmModalData = ref({
  title: '',
  message: '',
  variant: 'warning' as 'danger' | 'warning' | 'info' | 'success',
  action: null as (() => Promise<void>) | null
})
const modalLoading = ref(false)

const loadSpaces = async () => {
  loading.value = true
  
  try {
    const params: any = {
      page: currentPage.value,
      limit: limit.value
    }

    if (searchQuery.value) params.search = searchQuery.value
    if (statusFilter.value === 'active') params.isActive = true
    if (statusFilter.value === 'inactive') params.isActive = false

    const response = await adminService.getSpaces(params)
    
    if (response.success) {
      spaces.value = response.data
      pagination.value = response.pagination
    } else {
      toast.error(response.message || 'Error al cargar espacios')
    }
  } catch (err: any) {
    toast.error(err.message || 'Error inesperado')
  } finally {
    loading.value = false
  }
}

// Debounce search
let searchTimeout: ReturnType<typeof setTimeout>
watch(searchQuery, () => {
  clearTimeout(searchTimeout)
  searchTimeout = setTimeout(() => {
    currentPage.value = 1
    loadSpaces()
  }, 300)
})

watch(statusFilter, () => {
  currentPage.value = 1
  loadSpaces()
})

const handlePageChange = (page: number) => {
  currentPage.value = page
  loadSpaces()
}

const formatDate = (dateString?: string) => {
  if (!dateString) return '-'
  const date = new Date(dateString)
  return date.toLocaleDateString('es-ES', {
    day: '2-digit',
    month: 'short',
    year: 'numeric'
  })
}

const formatPrice = (price?: number | null) => {
  if (!price) return '-'
  return new Intl.NumberFormat('es-HN', {
    style: 'currency',
    currency: 'HNL'
  }).format(price)
}

const getSpaceImage = (space: Space): string => {
  if (space.images && space.images.length > 0) {
    const firstImage = space.images[0]
    if (typeof firstImage === 'string') return firstImage
    if (firstImage && typeof firstImage === 'object' && 'url' in firstImage) return firstImage.url
  }
  return ''
}

// Toggle active
const confirmToggleActive = (space: Space) => {
  const action = space.isActive ? 'desactivar' : 'activar'
  confirmModalData.value = {
    title: `${space.isActive ? 'Desactivar' : 'Activar'} Espacio`,
    message: `¿Estás seguro de que deseas ${action} "${space.name}"? ${space.isActive ? 'No aparecerá en las búsquedas públicas.' : 'Aparecerá nuevamente en las búsquedas públicas.'}`,
    variant: space.isActive ? 'warning' : 'success',
    action: async () => {
      const response = await adminService.toggleSpaceActive(space.id)
      if (response.success) {
        toast.success(response.message || 'Espacio actualizado')
        loadSpaces()
      } else {
        toast.error(response.message || 'Error al actualizar espacio')
      }
    }
  }
  showConfirmModal.value = true
}

const handleConfirm = async () => {
  if (confirmModalData.value.action) {
    modalLoading.value = true
    try {
      await confirmModalData.value.action()
    } finally {
      modalLoading.value = false
      showConfirmModal.value = false
    }
  }
}

onMounted(() => {
  loadSpaces()
})
</script>

<template>
  <div class="space-y-6">
    <!-- Header -->
    <div class="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
      <div>
        <h1 class="text-2xl font-bold text-[#111418]">Gestión de Espacios</h1>
        <p class="mt-1 text-sm text-slate-600">
          Administra todos los espacios registrados en la plataforma
        </p>
      </div>
    </div>

    <!-- Filters -->
    <div class="rounded-xl border border-slate-200 bg-white p-4 shadow-sm">
      <div class="grid gap-4 sm:grid-cols-3">
        <!-- Search -->
        <div class="sm:col-span-2">
          <label class="mb-1 block text-xs font-medium text-slate-600">Buscar</label>
          <div class="relative">
            <span class="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-xl text-slate-400">
              search
            </span>
            <input
              v-model="searchQuery"
              type="text"
              placeholder="Buscar por nombre, ciudad o dirección..."
              class="w-full rounded-lg border border-slate-200 py-2 pl-10 pr-4 text-sm focus:border-rose-500 focus:outline-none focus:ring-1 focus:ring-rose-500"
            />
          </div>
        </div>

        <!-- Status filter -->
        <div>
          <label class="mb-1 block text-xs font-medium text-slate-600">Estado</label>
          <select
            v-model="statusFilter"
            class="w-full rounded-lg border border-slate-200 px-3 py-2 text-sm focus:border-rose-500 focus:outline-none focus:ring-1 focus:ring-rose-500"
          >
            <option value="">Todos</option>
            <option value="active">Activos</option>
            <option value="inactive">Inactivos</option>
          </select>
        </div>
      </div>
    </div>

    <!-- Table -->
    <div class="overflow-hidden rounded-xl border border-slate-200 bg-white shadow-sm">
      <!-- Loading -->
      <div v-if="loading" class="flex items-center justify-center py-12">
        <div class="flex items-center gap-3 text-slate-600">
          <div class="h-6 w-6 animate-spin rounded-full border-2 border-slate-300 border-t-rose-600" />
          <span class="text-sm font-medium">Cargando espacios...</span>
        </div>
      </div>

      <!-- Empty -->
      <div v-else-if="spaces.length === 0" class="py-12 text-center">
        <span class="material-symbols-outlined text-4xl text-slate-300">store_off</span>
        <p class="mt-2 text-sm text-slate-600">No se encontraron espacios</p>
      </div>

      <!-- Table content -->
      <template v-else>
        <div class="overflow-x-auto">
          <table class="w-full">
            <thead class="border-b border-slate-200 bg-slate-50">
              <tr>
                <th class="px-4 py-3 text-left text-xs font-semibold uppercase text-slate-600">
                  Espacio
                </th>
                <th class="px-4 py-3 text-left text-xs font-semibold uppercase text-slate-600">
                  Propietario
                </th>
                <th class="px-4 py-3 text-left text-xs font-semibold uppercase text-slate-600">
                  Ubicación
                </th>
                <th class="px-4 py-3 text-left text-xs font-semibold uppercase text-slate-600">
                  Precio/Hora
                </th>
                <th class="px-4 py-3 text-left text-xs font-semibold uppercase text-slate-600">
                  Estado
                </th>
                <th class="px-4 py-3 text-left text-xs font-semibold uppercase text-slate-600">
                  Creado
                </th>
                <th class="px-4 py-3 text-right text-xs font-semibold uppercase text-slate-600">
                  Acciones
                </th>
              </tr>
            </thead>
            <tbody class="divide-y divide-slate-100">
              <tr
                v-for="space in spaces"
                :key="space.id"
                class="transition hover:bg-slate-50"
              >
                <td class="px-4 py-3">
                  <div class="flex items-center gap-3">
                    <div
                      class="h-12 w-12 flex-shrink-0 overflow-hidden rounded-lg bg-slate-100"
                    >
                      <img
                        v-if="getSpaceImage(space)"
                        :src="getSpaceImage(space)"
                        :alt="space.name"
                        class="h-full w-full object-cover"
                      />
                      <div v-else class="flex h-full w-full items-center justify-center">
                        <span class="material-symbols-outlined text-xl text-slate-400">image</span>
                      </div>
                    </div>
                    <div>
                      <p class="text-sm font-semibold text-[#111418]">{{ space.name }}</p>
                      <p class="text-xs text-slate-500">Capacidad: {{ space.capacity }} personas</p>
                    </div>
                  </div>
                </td>
                <td class="px-4 py-3">
                  <div v-if="space.owner">
                    <p class="text-sm font-medium text-[#111418]">
                      {{ space.owner.businessName || space.owner.name }}
                    </p>
                    <p v-if="space.owner.email" class="text-xs text-slate-500">{{ space.owner.email }}</p>
                  </div>
                  <span v-else class="text-sm text-slate-400">-</span>
                </td>
                <td class="px-4 py-3">
                  <div v-if="space.city || space.address">
                    <p class="text-sm text-[#111418]">{{ space.city || '-' }}</p>
                    <p v-if="space.address" class="truncate text-xs text-slate-500" style="max-width: 150px;">
                      {{ space.address }}
                    </p>
                  </div>
                  <span v-else class="text-sm text-slate-400">-</span>
                </td>
                <td class="px-4 py-3">
                  <span class="text-sm font-medium text-[#111418]">
                    {{ formatPrice(space.pricePerHour) }}
                  </span>
                </td>
                <td class="px-4 py-3">
                  <span
                    class="inline-flex items-center gap-1 rounded-full px-2.5 py-1 text-xs font-semibold"
                    :class="space.isActive ? 'bg-green-100 text-green-700' : 'bg-slate-100 text-slate-600'"
                  >
                    <span class="h-1.5 w-1.5 rounded-full" :class="space.isActive ? 'bg-green-500' : 'bg-slate-400'" />
                    {{ space.isActive ? 'Activo' : 'Inactivo' }}
                  </span>
                </td>
                <td class="px-4 py-3">
                  <span class="text-sm text-slate-600">{{ formatDate(space.createdAt) }}</span>
                </td>
                <td class="px-4 py-3">
                  <div class="flex items-center justify-end gap-2">
                    <NuxtLink
                      :to="`/spaces/${space.id}`"
                      target="_blank"
                      class="rounded-lg p-2 text-slate-600 transition hover:bg-slate-100"
                      title="Ver espacio"
                    >
                      <span class="material-symbols-outlined text-xl">visibility</span>
                    </NuxtLink>
                    <button
                      class="rounded-lg p-2 transition"
                      :class="space.isActive ? 'text-amber-600 hover:bg-amber-50' : 'text-green-600 hover:bg-green-50'"
                      :title="space.isActive ? 'Desactivar' : 'Activar'"
                      @click="confirmToggleActive(space)"
                    >
                      <span class="material-symbols-outlined text-xl">
                        {{ space.isActive ? 'visibility_off' : 'visibility' }}
                      </span>
                    </button>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <!-- Pagination -->
        <div v-if="pagination" class="border-t border-slate-200 px-4 py-3">
          <AdminPagination
            :current-page="pagination.page"
            :total-pages="pagination.totalPages"
            :total="pagination.total"
            :limit="pagination.limit"
            @page-change="handlePageChange"
          />
        </div>
      </template>
    </div>

    <!-- Confirm Modal -->
    <ConfirmModal
      :show="showConfirmModal"
      :title="confirmModalData.title"
      :message="confirmModalData.message"
      :variant="confirmModalData.variant"
      :loading="modalLoading"
      @confirm="handleConfirm"
      @cancel="showConfirmModal = false"
    />
  </div>
</template>
