<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import type { Booking } from '../../../types/booking'
import { ownerBookingsService } from '../../../services/owner-bookings.service'
import type { Space } from '../../../types/space'
import { ownerSpacesService } from '../../../services/owner-spaces.service'

definePageMeta({
  layout: 'owner',
  middleware: 'verified-owner'
})

useSeoMeta({
  title: 'Reservas - Spazio Owner',
  description: 'Gestiona las reservas de tus espacios'
})

const bookings = ref<Booking[]>([])
const spaces = ref<Space[]>([])
const loading = ref(true)
const error = ref('')
const searchQuery = ref('')
const statusFilter = ref<'all' | 'pending' | 'confirmed' | 'cancelled' | 'completed'>('all')
const spaceFilter = ref<string>('all')
const selectedBooking = ref<Booking | null>(null)
const showDetailModal = ref(false)

const filteredBookings = computed(() => {
  let filtered = bookings.value

  // Filtrar por búsqueda
  if (searchQuery.value) {
    const query = searchQuery.value.toLowerCase()
    filtered = filtered.filter(booking => 
      booking.user?.name?.toLowerCase().includes(query) ||
      booking.user?.email?.toLowerCase().includes(query) ||
      booking.space?.name?.toLowerCase().includes(query)
    )
  }

  // Filtrar por estado
  if (statusFilter.value !== 'all') {
    filtered = filtered.filter(booking => booking.status === statusFilter.value)
  }

  // Filtrar por espacio
  if (spaceFilter.value !== 'all') {
    filtered = filtered.filter(booking => booking.spaceId === spaceFilter.value)
  }

  return filtered
})

const statusCounts = computed(() => {
  return {
    pending: bookings.value.filter(b => b.status === 'pending').length,
    confirmed: bookings.value.filter(b => b.status === 'confirmed').length,
    cancelled: bookings.value.filter(b => b.status === 'cancelled').length,
    completed: bookings.value.filter(b => b.status === 'completed').length
  }
})

const loadBookings = async () => {
  loading.value = true
  error.value = ''
  
  try {
    const [bookingsResponse, spacesResponse] = await Promise.all([
      ownerBookingsService.getOwnerBookings(),
      ownerSpacesService.getMySpaces()
    ])
    
    if (bookingsResponse.success && bookingsResponse.data) {
      bookings.value = bookingsResponse.data
    }
    
    if (spacesResponse.success && spacesResponse.data) {
      spaces.value = spacesResponse.data
    }
  } catch (err: any) {
    error.value = err.data?.message || err.message || 'Error al cargar reservas'
  } finally {
    loading.value = false
  }
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
    year: 'numeric',
    weekday: 'short'
  })
}

const formatTime = (dateString: string) => {
  const date = new Date(dateString)
  return date.toLocaleTimeString('es-ES', { 
    hour: '2-digit', 
    minute: '2-digit'
  })
}

const formatTimeRange = (start: string, end: string) => {
  return `${formatTime(start)} - ${formatTime(end)}`
}

const handleViewDetail = (booking: Booking) => {
  selectedBooking.value = booking
  showDetailModal.value = true
}

const handleBookingUpdated = () => {
  loadBookings()
}

onMounted(() => {
  loadBookings()
})
</script>

<template>
  <div class="space-y-6">
    <!-- Header -->
    <div>
      <h1 class="text-3xl font-bold text-[#111418]">Reservas de Mis Espacios</h1>
      <p class="mt-1 text-sm text-slate-600">
        Gestiona todas las reservas realizadas en tus espacios
      </p>
    </div>

    <!-- Stats Cards -->
    <div class="grid gap-4 sm:grid-cols-4">
      <div class="rounded-xl border border-slate-200 bg-white p-5 shadow-sm">
        <div class="flex items-center justify-between">
          <div>
            <p class="text-sm text-slate-600">Pendientes</p>
            <p class="mt-1 text-3xl font-bold text-amber-600">{{ statusCounts.pending }}</p>
          </div>
          <div class="flex h-12 w-12 items-center justify-center rounded-full bg-amber-100">
            <span class="material-symbols-outlined text-2xl text-amber-600">pending</span>
          </div>
        </div>
      </div>

      <div class="rounded-xl border border-slate-200 bg-white p-5 shadow-sm">
        <div class="flex items-center justify-between">
          <div>
            <p class="text-sm text-slate-600">Confirmadas</p>
            <p class="mt-1 text-3xl font-bold text-green-600">{{ statusCounts.confirmed }}</p>
          </div>
          <div class="flex h-12 w-12 items-center justify-center rounded-full bg-green-100">
            <span class="material-symbols-outlined text-2xl text-green-600">check_circle</span>
          </div>
        </div>
      </div>

      <div class="rounded-xl border border-slate-200 bg-white p-5 shadow-sm">
        <div class="flex items-center justify-between">
          <div>
            <p class="text-sm text-slate-600">Completadas</p>
            <p class="mt-1 text-3xl font-bold text-blue-600">{{ statusCounts.completed }}</p>
          </div>
          <div class="flex h-12 w-12 items-center justify-center rounded-full bg-blue-100">
            <span class="material-symbols-outlined text-2xl text-blue-600">task_alt</span>
          </div>
        </div>
      </div>

      <div class="rounded-xl border border-slate-200 bg-white p-5 shadow-sm">
        <div class="flex items-center justify-between">
          <div>
            <p class="text-sm text-slate-600">Canceladas</p>
            <p class="mt-1 text-3xl font-bold text-rose-600">{{ statusCounts.cancelled }}</p>
          </div>
          <div class="flex h-12 w-12 items-center justify-center rounded-full bg-rose-100">
            <span class="material-symbols-outlined text-2xl text-rose-600">cancel</span>
          </div>
        </div>
      </div>
    </div>

    <!-- Filters -->
    <div class="space-y-4 rounded-xl border border-slate-200 bg-white p-4">
      <div class="flex flex-col gap-4 sm:flex-row">
        <!-- Search -->
        <div class="flex-1">
          <div class="relative">
            <span class="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-slate-400">
              search
            </span>
            <input
              v-model="searchQuery"
              type="text"
              placeholder="Buscar por usuario, email o espacio..."
              class="h-10 w-full rounded-lg border border-slate-200 bg-white pl-10 pr-4 text-sm focus:border-primary focus:outline-none focus:ring-2 focus:ring-primary/20"
            />
          </div>
        </div>

        <!-- Space Filter -->
        <select
          v-model="spaceFilter"
          class="h-10 rounded-lg border border-slate-200 bg-white px-4 text-sm focus:border-primary focus:outline-none focus:ring-2 focus:ring-primary/20"
        >
          <option value="all">Todos los espacios</option>
          <option v-for="space in spaces" :key="space.id" :value="space.id">
            {{ space.name }}
          </option>
        </select>
      </div>

      <!-- Status Filters -->
      <div class="flex flex-wrap gap-2">
        <button
          class="rounded-lg px-4 py-2 text-sm font-medium transition"
          :class="statusFilter === 'all' ? 'bg-primary text-white' : 'bg-slate-100 text-slate-700 hover:bg-slate-200'"
          @click="statusFilter = 'all'"
        >
          Todas ({{ bookings.length }})
        </button>
        <button
          class="rounded-lg px-4 py-2 text-sm font-medium transition"
          :class="statusFilter === 'pending' ? 'bg-amber-600 text-white' : 'bg-slate-100 text-slate-700 hover:bg-slate-200'"
          @click="statusFilter = 'pending'"
        >
          Pendientes ({{ statusCounts.pending }})
        </button>
        <button
          class="rounded-lg px-4 py-2 text-sm font-medium transition"
          :class="statusFilter === 'confirmed' ? 'bg-green-600 text-white' : 'bg-slate-100 text-slate-700 hover:bg-slate-200'"
          @click="statusFilter = 'confirmed'"
        >
          Confirmadas ({{ statusCounts.confirmed }})
        </button>
        <button
          class="rounded-lg px-4 py-2 text-sm font-medium transition"
          :class="statusFilter === 'completed' ? 'bg-blue-600 text-white' : 'bg-slate-100 text-slate-700 hover:bg-slate-200'"
          @click="statusFilter = 'completed'"
        >
          Completadas ({{ statusCounts.completed }})
        </button>
        <button
          class="rounded-lg px-4 py-2 text-sm font-medium transition"
          :class="statusFilter === 'cancelled' ? 'bg-rose-600 text-white' : 'bg-slate-100 text-slate-700 hover:bg-slate-200'"
          @click="statusFilter = 'cancelled'"
        >
          Canceladas ({{ statusCounts.cancelled }})
        </button>
      </div>
    </div>

    <!-- Loading -->
    <div v-if="loading" class="flex items-center justify-center py-12">
      <div class="flex items-center gap-3 text-slate-600">
        <div class="h-6 w-6 animate-spin rounded-full border-2 border-slate-300 border-t-primary"></div>
        <span class="text-sm font-medium">Cargando reservas...</span>
      </div>
    </div>

    <!-- Error -->
    <div v-else-if="error" class="rounded-xl border border-rose-200 bg-rose-50 p-6 text-center">
      <span class="material-symbols-outlined text-4xl text-rose-600">error</span>
      <p class="mt-2 text-sm font-medium text-rose-900">{{ error }}</p>
      <button
        class="mt-4 text-sm font-semibold text-rose-600 hover:underline"
        @click="loadBookings"
      >
        Reintentar
      </button>
    </div>

    <!-- Empty State -->
    <div v-else-if="filteredBookings.length === 0 && bookings.length === 0" class="rounded-xl border border-slate-200 bg-white p-12 text-center">
      <div class="mx-auto flex h-16 w-16 items-center justify-center rounded-full bg-slate-100">
        <span class="material-symbols-outlined text-4xl text-slate-400">event_busy</span>
      </div>
      <h3 class="mt-4 text-lg font-semibold text-[#111418]">No hay reservas</h3>
      <p class="mt-2 text-sm text-slate-600">
        Aún no tienes reservas en tus espacios
      </p>
    </div>

    <!-- No Results -->
    <div v-else-if="filteredBookings.length === 0" class="rounded-xl border border-slate-200 bg-white p-12 text-center">
      <span class="material-symbols-outlined text-4xl text-slate-400">search_off</span>
      <h3 class="mt-4 text-lg font-semibold text-[#111418]">No se encontraron reservas</h3>
      <p class="mt-2 text-sm text-slate-600">
        Intenta ajustar los filtros o la búsqueda
      </p>
    </div>

    <!-- Table -->
    <div v-else class="overflow-hidden rounded-xl border border-slate-200 bg-white shadow-sm">
      <div class="overflow-x-auto">
        <table class="w-full">
          <thead class="border-b border-slate-200 bg-slate-50">
            <tr>
              <th class="px-6 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-600">
                Usuario
              </th>
              <th class="px-6 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-600">
                Espacio
              </th>
              <th class="px-6 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-600">
                Fecha
              </th>
              <th class="px-6 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-600">
                Horario
              </th>
              <th class="px-6 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-600">
                Estado
              </th>
              <th class="px-6 py-3 text-right text-xs font-semibold uppercase tracking-wide text-slate-600">
                Acciones
              </th>
            </tr>
          </thead>
          <tbody class="divide-y divide-slate-100">
            <tr
              v-for="booking in filteredBookings"
              :key="booking._id"
              class="transition hover:bg-slate-50"
            >
              <td class="px-6 py-4">
                <div class="flex items-center gap-3">
                  <div class="flex h-10 w-10 flex-shrink-0 items-center justify-center rounded-full bg-primary/10">
                    <span class="material-symbols-outlined text-xl text-primary">person</span>
                  </div>
                  <div>
                    <p class="text-sm font-semibold text-[#111418]">
                      {{ booking.user?.name || 'Usuario' }}
                    </p>
                    <p class="text-xs text-slate-600">
                      {{ booking.user?.email || '' }}
                    </p>
                  </div>
                </div>
              </td>
              <td class="px-6 py-4">
                <p class="text-sm font-medium text-[#111418]">
                  {{ booking.space?.name || 'Espacio' }}
                </p>
              </td>
              <td class="px-6 py-4">
                <p class="text-sm text-slate-900">
                  {{ formatDate(booking.startTime) }}
                </p>
              </td>
              <td class="px-6 py-4">
                <p class="text-sm text-slate-900">
                  {{ formatTimeRange(booking.startTime, booking.endTime) }}
                </p>
              </td>
              <td class="px-6 py-4">
                <span 
                  class="inline-flex items-center gap-1.5 rounded-full px-3 py-1 text-xs font-semibold"
                  :class="getStatusBadgeClass(booking.status)"
                >
                  {{ getStatusLabel(booking.status) }}
                </span>
              </td>
              <td class="px-6 py-4">
                <div class="flex items-center justify-end gap-2">
                  <button
                    @click="handleViewDetail(booking)"
                    class="inline-flex items-center gap-1 rounded-lg px-3 py-1.5 text-sm font-medium text-blue-600 hover:bg-blue-50 transition-colors"
                    title="Ver detalle"
                  >
                    <span class="material-symbols-outlined !text-[18px]">visibility</span>
                    Ver detalle
                  </button>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- Modal de detalle -->
    <OwnerBookingDetail
      v-if="selectedBooking"
      v-model="showDetailModal"
      :booking="selectedBooking"
      @updated="handleBookingUpdated"
    />
  </div>
</template>
