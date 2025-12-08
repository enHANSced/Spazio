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
const pendingTransfers = ref<Booking[]>([])
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
    const [bookingsResponse, spacesResponse, pendingTransfersResponse] = await Promise.all([
      ownerBookingsService.getOwnerBookings(),
      ownerSpacesService.getMySpaces(),
      ownerBookingsService.getPendingTransferVerifications()
    ])
    
    if (bookingsResponse.success && bookingsResponse.data) {
      bookings.value = bookingsResponse.data
    }
    
    if (spacesResponse.success && spacesResponse.data) {
      spaces.value = spacesResponse.data
    }

    if (pendingTransfersResponse.success && pendingTransfersResponse.data) {
      pendingTransfers.value = pendingTransfersResponse.data
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
  return date.toLocaleDateString('es-HN', { 
    day: '2-digit', 
    month: 'long',
    year: 'numeric'
  })
}

const formatDateShort = (dateString: string) => {
  const date = new Date(dateString)
  return date.toLocaleDateString('es-HN', { 
    day: '2-digit', 
    month: 'short',
    weekday: 'short'
  })
}

const formatTime = (dateString: string) => {
  const date = new Date(dateString)
  return date.toLocaleTimeString('es-HN', { 
    hour: 'numeric', 
    minute: '2-digit',
    hour12: true
  }).toUpperCase()
}

const formatTimeRange = (start: string, end: string) => {
  return `${formatTime(start)} - ${formatTime(end)}`
}

const formatCurrency = (amount: number) => {
  return new Intl.NumberFormat('es-HN', {
    style: 'currency',
    currency: 'HNL',
    minimumFractionDigits: 2,
    maximumFractionDigits: 2
  }).format(amount).replace('HNL', 'L')
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
      <div class="rounded-xl border-2 border-amber-200 bg-gradient-to-br from-amber-50 to-white p-5 shadow-sm hover:shadow-md transition-shadow">
        <div class="flex items-center justify-between">
          <div>
            <p class="text-sm font-medium text-amber-700">Pendientes</p>
            <p class="mt-1 text-3xl font-bold text-amber-600">{{ statusCounts.pending }}</p>
            <p class="text-xs text-amber-600 mt-1">Requieren atención</p>
          </div>
          <div class="flex h-14 w-14 items-center justify-center rounded-2xl bg-amber-100 shadow-inner">
            <span class="material-symbols-outlined text-3xl text-amber-600">pending</span>
          </div>
        </div>
      </div>

      <div class="rounded-xl border-2 border-green-200 bg-gradient-to-br from-green-50 to-white p-5 shadow-sm hover:shadow-md transition-shadow">
        <div class="flex items-center justify-between">
          <div>
            <p class="text-sm font-medium text-green-700">Confirmadas</p>
            <p class="mt-1 text-3xl font-bold text-green-600">{{ statusCounts.confirmed }}</p>
            <p class="text-xs text-green-600 mt-1">Pagos verificados</p>
          </div>
          <div class="flex h-14 w-14 items-center justify-center rounded-2xl bg-green-100 shadow-inner">
            <span class="material-symbols-outlined text-3xl text-green-600">check_circle</span>
          </div>
        </div>
      </div>

      <div class="rounded-xl border-2 border-blue-200 bg-gradient-to-br from-blue-50 to-white p-5 shadow-sm hover:shadow-md transition-shadow">
        <div class="flex items-center justify-between">
          <div>
            <p class="text-sm font-medium text-blue-700">Completadas</p>
            <p class="mt-1 text-3xl font-bold text-blue-600">{{ statusCounts.completed }}</p>
            <p class="text-xs text-blue-600 mt-1">Finalizadas</p>
          </div>
          <div class="flex h-14 w-14 items-center justify-center rounded-2xl bg-blue-100 shadow-inner">
            <span class="material-symbols-outlined text-3xl text-blue-600">task_alt</span>
          </div>
        </div>
      </div>

      <div class="rounded-xl border-2 border-rose-200 bg-gradient-to-br from-rose-50 to-white p-5 shadow-sm hover:shadow-md transition-shadow">
        <div class="flex items-center justify-between">
          <div>
            <p class="text-sm font-medium text-rose-700">Canceladas</p>
            <p class="mt-1 text-3xl font-bold text-rose-600">{{ statusCounts.cancelled }}</p>
            <p class="text-xs text-rose-600 mt-1">Sin actividad</p>
          </div>
          <div class="flex h-14 w-14 items-center justify-center rounded-2xl bg-rose-100 shadow-inner">
            <span class="material-symbols-outlined text-3xl text-rose-600">cancel</span>
          </div>
        </div>
      </div>
    </div>

    <!-- Pending Transfer Verifications Alert -->
    <div v-if="pendingTransfers.length > 0" class="rounded-xl border-2 border-amber-300 bg-amber-50 p-5">
      <div class="flex items-start gap-4">
        <div class="flex h-12 w-12 flex-shrink-0 items-center justify-center rounded-full bg-amber-200">
          <span class="material-symbols-outlined text-2xl text-amber-700">receipt_long</span>
        </div>
        <div class="flex-1">
          <h3 class="text-lg font-bold text-amber-900">
            {{ pendingTransfers.length }} {{ pendingTransfers.length === 1 ? 'comprobante pendiente' : 'comprobantes pendientes' }} de verificación
          </h3>
          <p class="mt-1 text-sm text-amber-800">
            Los siguientes clientes han subido comprobantes de transferencia que requieren tu verificación.
          </p>
          
          <div class="mt-4 space-y-3">
            <div 
              v-for="transfer in pendingTransfers" 
              :key="transfer._id"
              class="flex items-center justify-between rounded-lg bg-white p-3 shadow-sm border border-amber-200"
            >
              <div class="flex items-center gap-3">
                <div class="flex h-10 w-10 items-center justify-center rounded-full bg-amber-100">
                  <span class="material-symbols-outlined text-amber-600">person</span>
                </div>
                <div>
                  <p class="font-semibold text-slate-900">{{ transfer.user?.name || 'Usuario' }}</p>
                  <p class="text-xs text-slate-600">
                    {{ transfer.space?.name }} · {{ formatDate(transfer.startTime) }}
                  </p>
                </div>
              </div>
              <button
                @click="handleViewDetail(transfer)"
                class="rounded-lg bg-amber-600 px-4 py-2 text-sm font-semibold text-white hover:bg-amber-700 transition-colors flex items-center gap-1"
              >
                <span class="material-symbols-outlined !text-[18px]">visibility</span>
                Revisar
              </button>
            </div>
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
              <th class="px-6 py-4 text-left text-xs font-bold uppercase tracking-wide text-slate-700 bg-slate-50">
                Cliente
              </th>
              <th class="px-6 py-4 text-left text-xs font-bold uppercase tracking-wide text-slate-700 bg-slate-50">
                Espacio
              </th>
              <th class="px-6 py-4 text-left text-xs font-bold uppercase tracking-wide text-slate-700 bg-slate-50">
                Fecha y Duración
              </th>
              <th class="px-6 py-4 text-left text-xs font-bold uppercase tracking-wide text-slate-700 bg-slate-50">
                Horario
              </th>
              <th class="px-6 py-4 text-left text-xs font-bold uppercase tracking-wide text-slate-700 bg-slate-50">
                Estado y Monto
              </th>
              <th class="px-6 py-4 text-right text-xs font-bold uppercase tracking-wide text-slate-700 bg-slate-50">
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
                  <div class="flex h-11 w-11 flex-shrink-0 items-center justify-center rounded-xl bg-gradient-to-br from-primary/20 to-primary/10 shadow-sm">
                    <span class="material-symbols-outlined text-xl text-primary">person</span>
                  </div>
                  <div class="min-w-0">
                    <p class="text-sm font-bold text-[#111418] truncate">
                      {{ booking.user?.name || 'Usuario' }}
                    </p>
                    <p class="text-xs text-slate-600 truncate">
                      {{ booking.user?.email || '' }}
                    </p>
                  </div>
                </div>
              </td>
              <td class="px-6 py-4">
                <p class="text-sm font-bold text-[#111418]">
                  {{ booking.space?.name || 'Espacio' }}
                </p>
              </td>
              <td class="px-6 py-4">
                <div class="flex flex-col">
                  <p class="text-sm font-semibold text-slate-900">
                    {{ formatDateShort(booking.startTime) }}
                  </p>
                  <p class="text-xs text-slate-500 mt-0.5">
                    {{ booking.durationHours }}h de uso
                  </p>
                </div>
              </td>
              <td class="px-6 py-4">
                <div class="flex items-center gap-2">
                  <span class="material-symbols-outlined text-slate-400 !text-[18px]">schedule</span>
                  <span class="text-sm font-medium text-slate-900">
                    {{ formatTimeRange(booking.startTime, booking.endTime) }}
                  </span>
                </div>
              </td>
              <td class="px-6 py-4">
                <div class="flex flex-col gap-1.5">
                  <span 
                    class="inline-flex items-center gap-1.5 rounded-full px-3 py-1 text-xs font-semibold w-fit"
                    :class="getStatusBadgeClass(booking.status)"
                  >
                    <span class="w-1.5 h-1.5 rounded-full bg-current"></span>
                    {{ getStatusLabel(booking.status) }}
                  </span>
                  <span class="text-xs font-bold text-slate-900">
                    {{ formatCurrency(booking.totalAmount || 0) }}
                  </span>
                </div>
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
