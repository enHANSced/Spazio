<script setup lang="ts">
import { ref, watch, onMounted } from 'vue'
import type { Booking } from '../../../types/booking'
import { adminService, type Pagination } from '../../../services/admin.service'
import { useToast } from '../../../composables/useToast'

definePageMeta({
  layout: 'admin',
  middleware: 'admin'
})

useSeoMeta({
  title: 'Gestión de Reservas - Admin Spazio',
  description: 'Administrar todas las reservas del sistema'
})

const toast = useToast()

// State
const bookings = ref<Booking[]>([])
const pagination = ref<Pagination | null>(null)
const loading = ref(true)
const currentPage = ref(1)
const limit = ref(10)

// Filters
const statusFilter = ref('')
const startDate = ref('')
const endDate = ref('')

// Modal state
const showConfirmModal = ref(false)
const confirmModalData = ref({
  title: '',
  message: '',
  variant: 'danger' as 'danger' | 'warning' | 'info' | 'success',
  action: null as (() => Promise<void>) | null
})
const modalLoading = ref(false)

// Detail modal
const showDetailModal = ref(false)
const selectedBooking = ref<Booking | null>(null)

const loadBookings = async () => {
  loading.value = true
  
  try {
    const params: any = {
      page: currentPage.value,
      limit: limit.value
    }

    if (statusFilter.value) params.status = statusFilter.value
    if (startDate.value) params.startDate = startDate.value
    if (endDate.value) params.endDate = endDate.value

    const response = await adminService.getBookings(params)
    
    if (response.success) {
      bookings.value = response.data
      pagination.value = response.pagination
    } else {
      toast.error(response.message || 'Error al cargar reservas')
    }
  } catch (err: any) {
    toast.error(err.message || 'Error inesperado')
  } finally {
    loading.value = false
  }
}

watch([statusFilter, startDate, endDate], () => {
  currentPage.value = 1
  loadBookings()
})

const handlePageChange = (page: number) => {
  currentPage.value = page
  loadBookings()
}

const getStatusBadgeClass = (status: string) => {
  switch (status) {
    case 'confirmed':
      return 'bg-green-100 text-green-700'
    case 'pending':
      return 'bg-amber-100 text-amber-700'
    case 'cancelled':
      return 'bg-rose-100 text-rose-700'
    case 'completed':
      return 'bg-blue-100 text-blue-700'
    default:
      return 'bg-slate-100 text-slate-700'
  }
}

const getStatusLabel = (status: string) => {
  const labels: Record<string, string> = {
    confirmed: 'Confirmada',
    pending: 'Pendiente',
    cancelled: 'Cancelada',
    completed: 'Completada'
  }
  return labels[status] || status
}

const formatDate = (dateString: string) => {
  const date = new Date(dateString)
  return date.toLocaleDateString('es-ES', {
    day: '2-digit',
    month: 'short',
    year: 'numeric'
  })
}

const formatTime = (dateString: string) => {
  const date = new Date(dateString)
  return date.toLocaleTimeString('es-ES', {
    hour: '2-digit',
    minute: '2-digit'
  })
}

const formatDateTime = (dateString: string) => {
  const date = new Date(dateString)
  return date.toLocaleString('es-ES', {
    day: '2-digit',
    month: 'long',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  })
}

const formatPrice = (amount?: number) => {
  if (!amount) return '-'
  return new Intl.NumberFormat('es-HN', {
    style: 'currency',
    currency: 'HNL'
  }).format(amount)
}

// Cancel booking
const confirmCancel = (booking: Booking) => {
  confirmModalData.value = {
    title: 'Cancelar Reserva',
    message: `¿Estás seguro de que deseas cancelar la reserva de "${booking.user?.name || 'Usuario'}" en "${booking.space?.name || 'Espacio'}"? Esta acción no se puede deshacer.`,
    variant: 'danger',
    action: async () => {
      const response = await adminService.cancelBooking(booking._id)
      if (response.success) {
        toast.success('Reserva cancelada correctamente')
        loadBookings()
      } else {
        toast.error(response.message || 'Error al cancelar reserva')
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

const openDetail = (booking: Booking) => {
  selectedBooking.value = booking
  showDetailModal.value = true
}

const clearFilters = () => {
  statusFilter.value = ''
  startDate.value = ''
  endDate.value = ''
}

onMounted(() => {
  loadBookings()
})
</script>

<template>
  <div class="space-y-6">
    <!-- Header -->
    <div class="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
      <div>
        <h1 class="text-2xl font-bold text-[#111418]">Gestión de Reservas</h1>
        <p class="mt-1 text-sm text-slate-600">
          Visualiza y administra todas las reservas del sistema
        </p>
      </div>
    </div>

    <!-- Filters -->
    <div class="rounded-xl border border-slate-200 bg-white p-4 shadow-sm">
      <div class="grid gap-4 sm:grid-cols-4">
        <!-- Status filter -->
        <div>
          <label class="mb-1 block text-xs font-medium text-slate-600">Estado</label>
          <select
            v-model="statusFilter"
            class="w-full rounded-lg border border-slate-200 px-3 py-2 text-sm focus:border-rose-500 focus:outline-none focus:ring-1 focus:ring-rose-500"
          >
            <option value="">Todos los estados</option>
            <option value="confirmed">Confirmadas</option>
            <option value="pending">Pendientes</option>
            <option value="cancelled">Canceladas</option>
            <option value="completed">Completadas</option>
          </select>
        </div>

        <!-- Start date -->
        <div>
          <label class="mb-1 block text-xs font-medium text-slate-600">Desde</label>
          <input
            v-model="startDate"
            type="date"
            class="w-full rounded-lg border border-slate-200 px-3 py-2 text-sm focus:border-rose-500 focus:outline-none focus:ring-1 focus:ring-rose-500"
          />
        </div>

        <!-- End date -->
        <div>
          <label class="mb-1 block text-xs font-medium text-slate-600">Hasta</label>
          <input
            v-model="endDate"
            type="date"
            class="w-full rounded-lg border border-slate-200 px-3 py-2 text-sm focus:border-rose-500 focus:outline-none focus:ring-1 focus:ring-rose-500"
          />
        </div>

        <!-- Clear filters -->
        <div class="flex items-end">
          <button
            v-if="statusFilter || startDate || endDate"
            class="flex items-center gap-2 rounded-lg border border-slate-200 bg-white px-4 py-2 text-sm font-medium text-slate-600 transition hover:bg-slate-50"
            @click="clearFilters"
          >
            <span class="material-symbols-outlined !text-[18px]">close</span>
            Limpiar filtros
          </button>
        </div>
      </div>
    </div>

    <!-- Table -->
    <div class="overflow-hidden rounded-xl border border-slate-200 bg-white shadow-sm">
      <!-- Loading -->
      <div v-if="loading" class="flex items-center justify-center py-12">
        <div class="flex items-center gap-3 text-slate-600">
          <div class="h-6 w-6 animate-spin rounded-full border-2 border-slate-300 border-t-rose-600" />
          <span class="text-sm font-medium">Cargando reservas...</span>
        </div>
      </div>

      <!-- Empty -->
      <div v-else-if="bookings.length === 0" class="py-12 text-center">
        <span class="material-symbols-outlined text-4xl text-slate-300">event_busy</span>
        <p class="mt-2 text-sm text-slate-600">No se encontraron reservas</p>
      </div>

      <!-- Table content -->
      <template v-else>
        <div class="overflow-x-auto">
          <table class="w-full">
            <thead class="border-b border-slate-200 bg-slate-50">
              <tr>
                <th class="px-4 py-3 text-left text-xs font-semibold uppercase text-slate-600">
                  Usuario
                </th>
                <th class="px-4 py-3 text-left text-xs font-semibold uppercase text-slate-600">
                  Espacio
                </th>
                <th class="px-4 py-3 text-left text-xs font-semibold uppercase text-slate-600">
                  Fecha
                </th>
                <th class="px-4 py-3 text-left text-xs font-semibold uppercase text-slate-600">
                  Horario
                </th>
                <th class="px-4 py-3 text-left text-xs font-semibold uppercase text-slate-600">
                  Total
                </th>
                <th class="px-4 py-3 text-left text-xs font-semibold uppercase text-slate-600">
                  Estado
                </th>
                <th class="px-4 py-3 text-right text-xs font-semibold uppercase text-slate-600">
                  Acciones
                </th>
              </tr>
            </thead>
            <tbody class="divide-y divide-slate-100">
              <tr
                v-for="booking in bookings"
                :key="booking._id"
                class="transition hover:bg-slate-50"
              >
                <td class="px-4 py-3">
                  <div class="flex items-center gap-3">
                    <div class="flex h-10 w-10 flex-shrink-0 items-center justify-center rounded-full bg-slate-100">
                      <span class="material-symbols-outlined text-xl text-slate-600">person</span>
                    </div>
                    <div>
                      <p class="text-sm font-semibold text-[#111418]">
                        {{ booking.user?.name || 'Usuario desconocido' }}
                      </p>
                      <p class="text-xs text-slate-500">{{ booking.user?.email || '-' }}</p>
                    </div>
                  </div>
                </td>
                <td class="px-4 py-3">
                  <p class="text-sm font-medium text-[#111418]">
                    {{ booking.space?.name || 'Espacio eliminado' }}
                  </p>
                  <p v-if="booking.space?.address" class="truncate text-xs text-slate-500" style="max-width: 150px;">
                    {{ booking.space.address }}
                  </p>
                </td>
                <td class="px-4 py-3">
                  <span class="text-sm text-[#111418]">{{ formatDate(booking.startTime) }}</span>
                </td>
                <td class="px-4 py-3">
                  <span class="text-sm text-[#111418]">
                    {{ formatTime(booking.startTime) }} - {{ formatTime(booking.endTime) }}
                  </span>
                </td>
                <td class="px-4 py-3">
                  <span class="text-sm font-medium text-[#111418]">
                    {{ formatPrice(booking.totalAmount) }}
                  </span>
                </td>
                <td class="px-4 py-3">
                  <span
                    class="inline-flex rounded-full px-2.5 py-1 text-xs font-semibold"
                    :class="getStatusBadgeClass(booking.status)"
                  >
                    {{ getStatusLabel(booking.status) }}
                  </span>
                </td>
                <td class="px-4 py-3">
                  <div class="flex items-center justify-end gap-2">
                    <button
                      class="rounded-lg p-2 text-slate-600 transition hover:bg-slate-100"
                      title="Ver detalles"
                      @click="openDetail(booking)"
                    >
                      <span class="material-symbols-outlined text-xl">visibility</span>
                    </button>
                    <button
                      v-if="booking.status !== 'cancelled'"
                      class="rounded-lg p-2 text-rose-600 transition hover:bg-rose-50"
                      title="Cancelar reserva"
                      @click="confirmCancel(booking)"
                    >
                      <span class="material-symbols-outlined text-xl">cancel</span>
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
      confirm-text="Cancelar reserva"
      @confirm="handleConfirm"
      @cancel="showConfirmModal = false"
    />

    <!-- Detail Modal -->
    <Teleport to="body">
      <Transition
        enter-active-class="transition-opacity duration-200"
        leave-active-class="transition-opacity duration-200"
        enter-from-class="opacity-0"
        leave-to-class="opacity-0"
      >
        <div
          v-if="showDetailModal && selectedBooking"
          class="fixed inset-0 z-50 flex items-center justify-center p-4"
        >
          <div class="absolute inset-0 bg-black/50" @click="showDetailModal = false" />
          
          <div class="relative w-full max-w-lg rounded-xl bg-white p-6 shadow-xl">
            <div class="flex items-center justify-between">
              <h3 class="text-lg font-semibold text-[#111418]">Detalles de la Reserva</h3>
              <button
                class="rounded-lg p-1 text-slate-400 transition hover:bg-slate-100 hover:text-slate-600"
                @click="showDetailModal = false"
              >
                <span class="material-symbols-outlined">close</span>
              </button>
            </div>

            <div class="mt-6 space-y-4">
              <!-- Status -->
              <div class="flex items-center justify-between">
                <span class="text-sm text-slate-600">Estado:</span>
                <span
                  class="rounded-full px-3 py-1 text-xs font-semibold"
                  :class="getStatusBadgeClass(selectedBooking.status)"
                >
                  {{ getStatusLabel(selectedBooking.status) }}
                </span>
              </div>

              <!-- User -->
              <div class="rounded-lg bg-slate-50 p-4">
                <p class="text-xs font-medium text-slate-500">Usuario</p>
                <p class="mt-1 text-sm font-semibold text-[#111418]">
                  {{ selectedBooking.user?.name || 'Usuario desconocido' }}
                </p>
                <p class="text-sm text-slate-600">{{ selectedBooking.user?.email || '-' }}</p>
              </div>

              <!-- Space -->
              <div class="rounded-lg bg-slate-50 p-4">
                <p class="text-xs font-medium text-slate-500">Espacio</p>
                <p class="mt-1 text-sm font-semibold text-[#111418]">
                  {{ selectedBooking.space?.name || 'Espacio eliminado' }}
                </p>
                <p v-if="selectedBooking.space?.address" class="text-sm text-slate-600">
                  {{ selectedBooking.space.address }}
                </p>
              </div>

              <!-- DateTime -->
              <div class="grid grid-cols-2 gap-4">
                <div>
                  <p class="text-xs font-medium text-slate-500">Inicio</p>
                  <p class="mt-1 text-sm text-[#111418]">{{ formatDateTime(selectedBooking.startTime) }}</p>
                </div>
                <div>
                  <p class="text-xs font-medium text-slate-500">Fin</p>
                  <p class="mt-1 text-sm text-[#111418]">{{ formatDateTime(selectedBooking.endTime) }}</p>
                </div>
              </div>

              <!-- Payment -->
              <div class="grid grid-cols-2 gap-4">
                <div>
                  <p class="text-xs font-medium text-slate-500">Total</p>
                  <p class="mt-1 text-lg font-semibold text-[#111418]">
                    {{ formatPrice(selectedBooking.totalAmount) }}
                  </p>
                </div>
                <div>
                  <p class="text-xs font-medium text-slate-500">Estado de pago</p>
                  <p class="mt-1 text-sm text-[#111418]">
                    {{ selectedBooking.paymentStatus === 'paid' ? 'Pagado' : 'Pendiente' }}
                  </p>
                </div>
              </div>

              <!-- Notes -->
              <div v-if="selectedBooking.notes">
                <p class="text-xs font-medium text-slate-500">Notas</p>
                <p class="mt-1 text-sm text-[#111418]">{{ selectedBooking.notes }}</p>
              </div>

              <!-- Timestamps -->
              <div class="border-t border-slate-200 pt-4 text-xs text-slate-500">
                <p>Creada: {{ formatDateTime(selectedBooking.createdAt) }}</p>
              </div>
            </div>

            <div class="mt-6">
              <button
                class="w-full rounded-lg bg-slate-100 px-4 py-2.5 text-sm font-semibold text-slate-700 transition hover:bg-slate-200"
                @click="showDetailModal = false"
              >
                Cerrar
              </button>
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>
  </div>
</template>
