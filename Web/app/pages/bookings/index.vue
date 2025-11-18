<script setup lang="ts">
import { computed, ref } from 'vue'
import BookingsService from '~/services/bookings.service'
import type { Booking, BookingStatus } from '~/types/booking'

definePageMeta({
  middleware: 'auth'
})

const router = useRouter()
const { user } = useAuth()

// Cargar reservas del usuario
const { data: bookingsData, pending, error, refresh } = await useAsyncData<Booking[]>(
  'user-bookings',
  () => BookingsService.list(),
  { server: false }
)

const bookings = computed(() => bookingsData.value || [])

// Filtros
const statusFilter = ref<BookingStatus | 'all'>('all')
const searchQuery = ref('')

// Reservas filtradas
const filteredBookings = computed(() => {
  let result = bookings.value

  // Filtrar por estado
  if (statusFilter.value !== 'all') {
    result = result.filter(b => b.status === statusFilter.value)
  }

  // Filtrar por búsqueda
  if (searchQuery.value) {
    const query = searchQuery.value.toLowerCase()
    result = result.filter(b => 
      b.space?.name?.toLowerCase().includes(query) ||
      b.space?.address?.toLowerCase().includes(query)
    )
  }

  // Ordenar por fecha de inicio (más recientes primero)
  return result.sort((a, b) => 
    new Date(b.startTime).getTime() - new Date(a.startTime).getTime()
  )
})

// Agrupar reservas
const upcomingBookings = computed(() => 
  filteredBookings.value.filter(b => 
    b.status !== 'cancelled' && new Date(b.startTime) > new Date()
  )
)

const pastBookings = computed(() => 
  filteredBookings.value.filter(b => 
    b.status === 'cancelled' || new Date(b.endTime) < new Date()
  )
)

// Contadores
const bookingCounts = computed(() => ({
  all: bookings.value.length,
  pending: bookings.value.filter(b => b.status === 'pending').length,
  confirmed: bookings.value.filter(b => b.status === 'confirmed').length,
  cancelled: bookings.value.filter(b => b.status === 'cancelled').length
}))

// Acciones
const viewBooking = (bookingId: string) => {
  router.push(`/bookings/${bookingId}`)
}

const cancelBooking = async (bookingId: string) => {
  if (!confirm('¿Estás seguro de que deseas cancelar esta reserva?')) {
    return
  }

  try {
    await BookingsService.cancel(bookingId)
    await refresh()
  } catch (error) {
    console.error('Error al cancelar reserva:', error)
    alert('Error al cancelar la reserva. Por favor intenta nuevamente.')
  }
}

// Utilidades
const formatDate = (dateString: string) => {
  return new Date(dateString).toLocaleDateString('es-HN', {
    weekday: 'short',
    year: 'numeric',
    month: 'short',
    day: 'numeric'
  })
}

const formatTime = (dateString: string) => {
  return new Date(dateString).toLocaleTimeString('es-HN', {
    hour: '2-digit',
    minute: '2-digit'
  })
}

const formatCurrency = (value?: number) => {
  if (!value) return 'N/A'
  return new Intl.NumberFormat('es-HN', {
    style: 'currency',
    currency: 'HNL',
    minimumFractionDigits: 2
  }).format(value)
}

const getStatusColor = (status: BookingStatus) => {
  switch (status) {
    case 'confirmed':
      return 'bg-green-100 text-green-800 border-green-200'
    case 'pending':
      return 'bg-yellow-100 text-yellow-800 border-yellow-200'
    case 'cancelled':
      return 'bg-red-100 text-red-800 border-red-200'
    default:
      return 'bg-gray-100 text-gray-800 border-gray-200'
  }
}

const getStatusIcon = (status: BookingStatus) => {
  switch (status) {
    case 'confirmed':
      return 'check_circle'
    case 'pending':
      return 'schedule'
    case 'cancelled':
      return 'cancel'
    default:
      return 'help'
  }
}

const getStatusLabel = (status: BookingStatus) => {
  switch (status) {
    case 'confirmed':
      return 'Confirmada'
    case 'pending':
      return 'Pendiente'
    case 'cancelled':
      return 'Cancelada'
    default:
      return status
  }
}

const getPaymentStatusLabel = (paymentStatus?: string) => {
  switch (paymentStatus) {
    case 'paid':
      return 'Pagado'
    case 'pending':
      return 'Pendiente de pago'
    case 'refunded':
      return 'Reembolsado'
    default:
      return 'No especificado'
  }
}

const getPaymentMethodLabel = (method?: string) => {
  switch (method) {
    case 'cash':
      return 'Efectivo'
    case 'card':
      return 'Tarjeta'
    case 'transfer':
      return 'Transferencia'
    default:
      return 'No especificado'
  }
}

const canCancel = (booking: Booking) => {
  return booking.status !== 'cancelled' && new Date(booking.startTime) > new Date()
}
</script>

<template>
  <div class="min-h-screen bg-gray-50">
    <div class="px-4 sm:px-6 lg:px-8 py-8 max-w-7xl mx-auto">
      <!-- Header -->
      <div class="mb-8">
        <h1 class="text-3xl font-black text-gray-900 mb-2">Mis Reservas</h1>
        <p class="text-gray-600">Gestiona tus reservas de espacios</p>
      </div>

      <!-- Loading -->
      <div v-if="pending" class="space-y-4">
        <div v-for="i in 3" :key="i" class="bg-white rounded-xl p-6 shadow-sm border border-gray-200 animate-pulse">
          <div class="h-6 w-1/3 bg-gray-200 rounded mb-4"></div>
          <div class="h-4 w-1/2 bg-gray-200 rounded mb-2"></div>
          <div class="h-4 w-2/3 bg-gray-200 rounded"></div>
        </div>
      </div>

      <!-- Error -->
      <div v-else-if="error" class="bg-red-50 border border-red-200 rounded-xl p-6 flex items-start gap-3">
        <span class="material-symbols-outlined text-red-600">error</span>
        <div>
          <h3 class="font-semibold text-red-900 mb-1">Error al cargar reservas</h3>
          <p class="text-sm text-red-800">Por favor intenta nuevamente más tarde.</p>
        </div>
      </div>

      <!-- Content -->
      <div v-else>
        <!-- Stats Cards -->
        <div class="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
          <div class="bg-white rounded-xl p-4 shadow-sm border border-gray-200">
            <div class="flex items-center gap-3">
              <div class="h-12 w-12 rounded-full bg-blue-100 flex items-center justify-center">
                <span class="material-symbols-outlined text-blue-600">calendar_month</span>
              </div>
              <div>
                <p class="text-2xl font-bold text-gray-900">{{ bookingCounts.all }}</p>
                <p class="text-sm text-gray-600">Total</p>
              </div>
            </div>
          </div>

          <div class="bg-white rounded-xl p-4 shadow-sm border border-gray-200">
            <div class="flex items-center gap-3">
              <div class="h-12 w-12 rounded-full bg-yellow-100 flex items-center justify-center">
                <span class="material-symbols-outlined text-yellow-600">schedule</span>
              </div>
              <div>
                <p class="text-2xl font-bold text-gray-900">{{ bookingCounts.pending }}</p>
                <p class="text-sm text-gray-600">Pendientes</p>
              </div>
            </div>
          </div>

          <div class="bg-white rounded-xl p-4 shadow-sm border border-gray-200">
            <div class="flex items-center gap-3">
              <div class="h-12 w-12 rounded-full bg-green-100 flex items-center justify-center">
                <span class="material-symbols-outlined text-green-600">check_circle</span>
              </div>
              <div>
                <p class="text-2xl font-bold text-gray-900">{{ bookingCounts.confirmed }}</p>
                <p class="text-sm text-gray-600">Confirmadas</p>
              </div>
            </div>
          </div>

          <div class="bg-white rounded-xl p-4 shadow-sm border border-gray-200">
            <div class="flex items-center gap-3">
              <div class="h-12 w-12 rounded-full bg-red-100 flex items-center justify-center">
                <span class="material-symbols-outlined text-red-600">cancel</span>
              </div>
              <div>
                <p class="text-2xl font-bold text-gray-900">{{ bookingCounts.cancelled }}</p>
                <p class="text-sm text-gray-600">Canceladas</p>
              </div>
            </div>
          </div>
        </div>

        <!-- Filters -->
        <div class="bg-white rounded-xl p-4 shadow-sm border border-gray-200 mb-6">
          <div class="flex flex-col sm:flex-row gap-4">
            <!-- Search -->
            <div class="flex-1">
              <div class="relative">
                <span class="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-gray-400">
                  search
                </span>
                <input
                  v-model="searchQuery"
                  type="text"
                  placeholder="Buscar por nombre o dirección..."
                  class="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary focus:border-transparent"
                />
              </div>
            </div>

            <!-- Status Filter -->
            <div class="flex gap-2 overflow-x-auto pb-2 sm:pb-0">
              <button
                type="button"
                class="px-4 py-2 rounded-lg text-sm font-semibold whitespace-nowrap transition"
                :class="statusFilter === 'all' 
                  ? 'bg-primary text-white' 
                  : 'bg-gray-100 text-gray-700 hover:bg-gray-200'"
                @click="statusFilter = 'all'"
              >
                Todas
              </button>
              <button
                type="button"
                class="px-4 py-2 rounded-lg text-sm font-semibold whitespace-nowrap transition"
                :class="statusFilter === 'pending' 
                  ? 'bg-yellow-600 text-white' 
                  : 'bg-gray-100 text-gray-700 hover:bg-gray-200'"
                @click="statusFilter = 'pending'"
              >
                Pendientes
              </button>
              <button
                type="button"
                class="px-4 py-2 rounded-lg text-sm font-semibold whitespace-nowrap transition"
                :class="statusFilter === 'confirmed' 
                  ? 'bg-green-600 text-white' 
                  : 'bg-gray-100 text-gray-700 hover:bg-gray-200'"
                @click="statusFilter = 'confirmed'"
              >
                Confirmadas
              </button>
              <button
                type="button"
                class="px-4 py-2 rounded-lg text-sm font-semibold whitespace-nowrap transition"
                :class="statusFilter === 'cancelled' 
                  ? 'bg-red-600 text-white' 
                  : 'bg-gray-100 text-gray-700 hover:bg-gray-200'"
                @click="statusFilter = 'cancelled'"
              >
                Canceladas
              </button>
            </div>
          </div>
        </div>

        <!-- Empty State -->
        <div v-if="filteredBookings.length === 0" class="text-center py-16">
          <div class="mx-auto flex h-24 w-24 items-center justify-center rounded-full bg-gray-100 mb-4">
            <span class="material-symbols-outlined text-5xl text-gray-400">event_busy</span>
          </div>
          <h3 class="text-xl font-bold text-gray-900 mb-2">No hay reservas</h3>
          <p class="text-gray-600 mb-6">
            {{ searchQuery || statusFilter !== 'all' 
              ? 'No se encontraron reservas con los filtros aplicados.' 
              : 'Aún no has realizado ninguna reserva.' 
            }}
          </p>
          <button
            v-if="!searchQuery && statusFilter === 'all'"
            type="button"
            class="inline-flex items-center gap-2 rounded-lg bg-primary px-6 py-3 text-sm font-semibold text-white hover:bg-primary/90"
            @click="router.push('/')"
          >
            <span class="material-symbols-outlined">explore</span>
            Explorar espacios
          </button>
        </div>

        <!-- Bookings List -->
        <div v-else class="space-y-8">
          <!-- Upcoming Bookings -->
          <div v-if="upcomingBookings.length > 0">
            <h2 class="text-xl font-bold text-gray-900 mb-4 flex items-center gap-2">
              <span class="material-symbols-outlined text-primary">upcoming</span>
              Próximas reservas
            </h2>
            <div class="space-y-4">
              <div
                v-for="booking in upcomingBookings"
                :key="booking._id"
                class="bg-white rounded-xl p-6 shadow-sm border border-gray-200 hover:shadow-md transition cursor-pointer"
                @click="viewBooking(booking._id)"
              >
                <div class="flex flex-col lg:flex-row lg:items-center gap-4">
                  <!-- Space Info -->
                  <div class="flex-1">
                    <div class="flex items-start justify-between mb-2">
                      <div>
                        <h3 class="text-lg font-bold text-gray-900 mb-1">{{ booking.space?.name || 'Espacio no disponible' }}</h3>
                        <p class="text-sm text-gray-600 flex items-center gap-1">
                          <span class="material-symbols-outlined !text-[16px]">location_on</span>
                          {{ booking.space?.address || 'Dirección no disponible' }}
                        </p>
                      </div>
                      <span
                        class="px-3 py-1 rounded-full text-xs font-semibold border flex items-center gap-1"
                        :class="getStatusColor(booking.status)"
                      >
                        <span class="material-symbols-outlined !text-[14px]">{{ getStatusIcon(booking.status) }}</span>
                        {{ getStatusLabel(booking.status) }}
                      </span>
                    </div>

                    <div class="grid grid-cols-2 md:grid-cols-4 gap-4 mt-4">
                      <div class="flex items-center gap-2 text-sm text-gray-700">
                        <span class="material-symbols-outlined !text-[18px] text-primary">event</span>
                        <div>
                          <p class="font-semibold">{{ formatDate(booking.startTime) }}</p>
                        </div>
                      </div>

                      <div class="flex items-center gap-2 text-sm text-gray-700">
                        <span class="material-symbols-outlined !text-[18px] text-primary">schedule</span>
                        <div>
                          <p class="font-semibold">{{ formatTime(booking.startTime) }} - {{ formatTime(booking.endTime) }}</p>
                        </div>
                      </div>

                      <div class="flex items-center gap-2 text-sm text-gray-700">
                        <span class="material-symbols-outlined !text-[18px] text-primary">payments</span>
                        <div>
                          <p class="font-semibold">{{ formatCurrency(booking.totalAmount) }}</p>
                          <p class="text-xs text-gray-500">{{ getPaymentMethodLabel(booking.paymentMethod) }}</p>
                        </div>
                      </div>

                      <div class="flex items-center gap-2 text-sm text-gray-700">
                        <span class="material-symbols-outlined !text-[18px]" :class="booking.paymentStatus === 'paid' ? 'text-green-600' : 'text-yellow-600'">
                          {{ booking.paymentStatus === 'paid' ? 'check_circle' : 'schedule' }}
                        </span>
                        <div>
                          <p class="font-semibold">{{ getPaymentStatusLabel(booking.paymentStatus) }}</p>
                        </div>
                      </div>
                    </div>
                  </div>

                  <!-- Actions -->
                  <div class="flex lg:flex-col gap-2">
                    <button
                      type="button"
                      class="flex-1 lg:flex-none px-4 py-2 rounded-lg bg-primary text-white text-sm font-semibold hover:bg-primary/90 transition flex items-center justify-center gap-1"
                      @click.stop="viewBooking(booking._id)"
                    >
                      <span class="material-symbols-outlined !text-[18px]">visibility</span>
                      Ver detalles
                    </button>
                    <button
                      v-if="canCancel(booking)"
                      type="button"
                      class="flex-1 lg:flex-none px-4 py-2 rounded-lg bg-red-50 text-red-700 text-sm font-semibold hover:bg-red-100 transition flex items-center justify-center gap-1"
                      @click.stop="cancelBooking(booking._id)"
                    >
                      <span class="material-symbols-outlined !text-[18px]">cancel</span>
                      Cancelar
                    </button>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- Past Bookings -->
          <div v-if="pastBookings.length > 0">
            <h2 class="text-xl font-bold text-gray-900 mb-4 flex items-center gap-2">
              <span class="material-symbols-outlined text-gray-600">history</span>
              Reservas pasadas
            </h2>
            <div class="space-y-4">
              <div
                v-for="booking in pastBookings"
                :key="booking._id"
                class="bg-white rounded-xl p-6 shadow-sm border border-gray-200 opacity-75 hover:opacity-100 hover:shadow-md transition cursor-pointer"
                @click="viewBooking(booking._id)"
              >
                <div class="flex flex-col lg:flex-row lg:items-center gap-4">
                  <!-- Space Info -->
                  <div class="flex-1">
                    <div class="flex items-start justify-between mb-2">
                      <div>
                        <h3 class="text-lg font-bold text-gray-900 mb-1">{{ booking.space?.name || 'Espacio no disponible' }}</h3>
                        <p class="text-sm text-gray-600 flex items-center gap-1">
                          <span class="material-symbols-outlined !text-[16px]">location_on</span>
                          {{ booking.space?.address || 'Dirección no disponible' }}
                        </p>
                      </div>
                      <span
                        class="px-3 py-1 rounded-full text-xs font-semibold border flex items-center gap-1"
                        :class="getStatusColor(booking.status)"
                      >
                        <span class="material-symbols-outlined !text-[14px]">{{ getStatusIcon(booking.status) }}</span>
                        {{ getStatusLabel(booking.status) }}
                      </span>
                    </div>

                    <div class="grid grid-cols-2 md:grid-cols-3 gap-4 mt-4">
                      <div class="flex items-center gap-2 text-sm text-gray-700">
                        <span class="material-symbols-outlined !text-[18px] text-gray-400">event</span>
                        <div>
                          <p class="font-semibold">{{ formatDate(booking.startTime) }}</p>
                        </div>
                      </div>

                      <div class="flex items-center gap-2 text-sm text-gray-700">
                        <span class="material-symbols-outlined !text-[18px] text-gray-400">schedule</span>
                        <div>
                          <p class="font-semibold">{{ formatTime(booking.startTime) }} - {{ formatTime(booking.endTime) }}</p>
                        </div>
                      </div>

                      <div class="flex items-center gap-2 text-sm text-gray-700">
                        <span class="material-symbols-outlined !text-[18px] text-gray-400">payments</span>
                        <div>
                          <p class="font-semibold">{{ formatCurrency(booking.totalAmount) }}</p>
                        </div>
                      </div>
                    </div>
                  </div>

                  <!-- Actions -->
                  <div>
                    <button
                      type="button"
                      class="px-4 py-2 rounded-lg bg-gray-100 text-gray-700 text-sm font-semibold hover:bg-gray-200 transition flex items-center justify-center gap-1"
                      @click.stop="viewBooking(booking._id)"
                    >
                      <span class="material-symbols-outlined !text-[18px]">visibility</span>
                      Ver detalles
                    </button>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
