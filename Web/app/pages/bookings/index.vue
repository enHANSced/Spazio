<script setup lang="ts">
import { computed, ref } from 'vue'
import BookingsService from '~/services/bookings.service'
import type { Booking, BookingStatus } from '~/types/booking'

definePageMeta({
  middleware: 'auth'
})

useSeoMeta({
  title: 'Mis Reservas - Spazio',
  description: 'Gestiona tus reservas de espacios'
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
const sortOption = ref<'created-desc' | 'created-asc' | 'date-desc' | 'date-asc' | 'amount-desc' | 'amount-asc'>('created-desc')

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

  // Ordenar según la opción seleccionada
  return result.sort((a, b) => {
    switch (sortOption.value) {
      case 'created-desc':
        // Más reciente primero (por fecha de creación)
        return new Date(b.createdAt || b.startTime).getTime() - new Date(a.createdAt || a.startTime).getTime()
      case 'created-asc':
        // Más antigua primero (por fecha de creación)
        return new Date(a.createdAt || a.startTime).getTime() - new Date(b.createdAt || b.startTime).getTime()
      case 'date-desc':
        // Fecha de reserva más próxima primero
        return new Date(b.startTime).getTime() - new Date(a.startTime).getTime()
      case 'date-asc':
        // Fecha de reserva más lejana primero
        return new Date(a.startTime).getTime() - new Date(b.startTime).getTime()
      case 'amount-desc':
        // Mayor monto primero
        return (b.totalAmount || 0) - (a.totalAmount || 0)
      case 'amount-asc':
        // Menor monto primero
        return (a.totalAmount || 0) - (b.totalAmount || 0)
      default:
        return 0
    }
  })
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
  if (value === undefined || value === null) return 'Sin cargo'
  if (value === 0) return 'Gratis'
  return new Intl.NumberFormat('es-HN', {
    style: 'currency',
    currency: 'HNL',
    minimumFractionDigits: 2
  }).format(value)
}

const getStatusColor = (status: BookingStatus) => {
  switch (status) {
    case 'confirmed':
      return 'bg-emerald-50 text-emerald-700 ring-1 ring-emerald-600/20'
    case 'pending':
      return 'bg-amber-50 text-amber-700 ring-1 ring-amber-600/20'
    case 'cancelled':
      return 'bg-rose-50 text-rose-700 ring-1 ring-rose-600/20'
    default:
      return 'bg-gray-50 text-gray-700 ring-1 ring-gray-600/20'
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
  <div class="min-h-screen bg-gradient-to-br from-slate-50 via-white to-blue-50/30">
    <!-- Hero Header con gradiente -->
    <div class="relative overflow-hidden bg-gradient-to-r from-primary via-primary-dark to-blue-900">
      <!-- Patrón decorativo -->
      <div class="absolute inset-0 opacity-10">
        <div class="absolute -left-20 -top-20 h-80 w-80 rounded-full bg-white/20 blur-3xl" />
        <div class="absolute -bottom-20 right-10 h-96 w-96 rounded-full bg-white/10 blur-3xl" />
      </div>
      
      <div class="relative px-4 sm:px-6 lg:px-8 py-12 max-w-7xl mx-auto">
        <div class="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
          <div>
            <div class="flex items-center gap-3 mb-3">
              <div class="flex h-12 w-12 items-center justify-center rounded-2xl bg-white/20 backdrop-blur-sm">
                <span class="material-symbols-outlined text-2xl text-white">calendar_month</span>
              </div>
              <h1 class="text-3xl font-bold text-white">Mis Reservas</h1>
            </div>
            <p class="text-white/70 text-lg">
              Gestiona y da seguimiento a todas tus reservas de espacios
            </p>
          </div>
          
          <NuxtLink 
            to="/"
            class="inline-flex items-center gap-2 rounded-xl bg-white/10 backdrop-blur-sm px-5 py-3 font-semibold text-white ring-1 ring-white/20 transition-all hover:bg-white/20 hover:ring-white/40"
          >
            <span class="material-symbols-outlined">explore</span>
            Explorar espacios
          </NuxtLink>
        </div>
      </div>
    </div>

    <div class="px-4 sm:px-6 lg:px-8 py-8 max-w-7xl mx-auto -mt-6">
      <!-- Loading -->
      <div v-if="pending" class="space-y-4">
        <div v-for="i in 3" :key="i" class="bg-white rounded-2xl p-6 shadow-sm ring-1 ring-black/5 animate-pulse">
          <div class="h-6 w-1/3 bg-gray-200 rounded-lg mb-4"></div>
          <div class="h-4 w-1/2 bg-gray-200 rounded-lg mb-2"></div>
          <div class="h-4 w-2/3 bg-gray-200 rounded-lg"></div>
        </div>
      </div>

      <!-- Error -->
      <div v-else-if="error" class="bg-white rounded-2xl p-6 shadow-sm ring-1 ring-rose-200">
        <div class="flex items-start gap-4">
          <div class="flex h-12 w-12 items-center justify-center rounded-xl bg-rose-100">
            <span class="material-symbols-outlined text-rose-600">error</span>
          </div>
          <div>
            <h3 class="font-semibold text-gray-900 mb-1">Error al cargar reservas</h3>
            <p class="text-sm text-gray-600">Por favor intenta nuevamente más tarde.</p>
          </div>
        </div>
      </div>

      <!-- Content -->
      <div v-else>
        <!-- Stats Cards - Diseño moderno -->
        <div class="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
          <div class="group bg-white rounded-2xl p-5 shadow-sm ring-1 ring-black/5 hover:shadow-md transition-all">
            <div class="flex items-center gap-4">
              <div class="flex h-14 w-14 items-center justify-center rounded-2xl bg-gradient-to-br from-blue-500 to-blue-600 shadow-lg shadow-blue-500/25">
                <span class="material-symbols-outlined text-2xl text-white">calendar_month</span>
              </div>
              <div>
                <p class="text-3xl font-bold text-gray-900">{{ bookingCounts.all }}</p>
                <p class="text-sm font-medium text-gray-500">Total</p>
              </div>
            </div>
          </div>

          <div class="group bg-white rounded-2xl p-5 shadow-sm ring-1 ring-black/5 hover:shadow-md transition-all">
            <div class="flex items-center gap-4">
              <div class="flex h-14 w-14 items-center justify-center rounded-2xl bg-gradient-to-br from-amber-400 to-amber-500 shadow-lg shadow-amber-500/25">
                <span class="material-symbols-outlined text-2xl text-white">schedule</span>
              </div>
              <div>
                <p class="text-3xl font-bold text-gray-900">{{ bookingCounts.pending }}</p>
                <p class="text-sm font-medium text-gray-500">Pendientes</p>
              </div>
            </div>
          </div>

          <div class="group bg-white rounded-2xl p-5 shadow-sm ring-1 ring-black/5 hover:shadow-md transition-all">
            <div class="flex items-center gap-4">
              <div class="flex h-14 w-14 items-center justify-center rounded-2xl bg-gradient-to-br from-emerald-500 to-emerald-600 shadow-lg shadow-emerald-500/25">
                <span class="material-symbols-outlined text-2xl text-white">check_circle</span>
              </div>
              <div>
                <p class="text-3xl font-bold text-gray-900">{{ bookingCounts.confirmed }}</p>
                <p class="text-sm font-medium text-gray-500">Confirmadas</p>
              </div>
            </div>
          </div>

          <div class="group bg-white rounded-2xl p-5 shadow-sm ring-1 ring-black/5 hover:shadow-md transition-all">
            <div class="flex items-center gap-4">
              <div class="flex h-14 w-14 items-center justify-center rounded-2xl bg-gradient-to-br from-rose-500 to-rose-600 shadow-lg shadow-rose-500/25">
                <span class="material-symbols-outlined text-2xl text-white">cancel</span>
              </div>
              <div>
                <p class="text-3xl font-bold text-gray-900">{{ bookingCounts.cancelled }}</p>
                <p class="text-sm font-medium text-gray-500">Canceladas</p>
              </div>
            </div>
          </div>
        </div>

        <!-- Filters - Estilo moderno -->
        <div class="bg-white rounded-2xl p-5 shadow-sm ring-1 ring-black/5 mb-8">
          <div class="flex flex-col gap-4">
            <!-- Fila 1: Búsqueda y Ordenamiento -->
            <div class="flex flex-col sm:flex-row gap-4">
              <!-- Search -->
              <div class="flex-1">
                <div class="group relative">
                  <span class="absolute inset-y-0 left-0 flex items-center pl-4 text-gray-400 transition-colors group-focus-within:text-primary">
                    <span class="material-symbols-outlined text-xl">search</span>
                  </span>
                  <input
                    v-model="searchQuery"
                    type="text"
                    placeholder="Buscar por nombre o dirección..."
                    class="h-12 w-full rounded-xl border border-gray-200 bg-gray-50/50 pl-12 pr-4 text-sm text-gray-900 transition-all placeholder:text-gray-400 hover:border-gray-300 focus:border-primary focus:bg-white focus:outline-none focus:ring-2 focus:ring-primary/20"
                  />
                </div>
              </div>

              <!-- Sort -->
              <div class="sm:w-64">
                <div class="group relative">
                  <span class="absolute inset-y-0 left-0 flex items-center pl-4 text-gray-400 transition-colors group-focus-within:text-primary">
                    <span class="material-symbols-outlined text-xl">sort</span>
                  </span>
                  <select
                    v-model="sortOption"
                    class="h-12 w-full rounded-xl border border-gray-200 bg-gray-50/50 pl-12 pr-4 text-sm text-gray-900 transition-all hover:border-gray-300 focus:border-primary focus:bg-white focus:outline-none focus:ring-2 focus:ring-primary/20 appearance-none cursor-pointer"
                  >
                    <option value="created-desc">Más recientes primero</option>
                    <option value="created-asc">Más antiguas primero</option>
                    <option value="date-desc">Próximas reservas</option>
                    <option value="date-asc">Reservas lejanas</option>
                    <option value="amount-desc">Mayor monto</option>
                    <option value="amount-asc">Menor monto</option>
                  </select>
                  <span class="absolute inset-y-0 right-0 flex items-center pr-4 pointer-events-none">
                    <span class="material-symbols-outlined text-gray-400 text-xl">expand_more</span>
                  </span>
                </div>
              </div>
            </div>

            <!-- Fila 2: Status Filter - Pills modernos -->
            <div class="flex gap-2 overflow-x-auto pb-2 sm:pb-0">
              <button
                type="button"
                class="px-4 py-2.5 rounded-xl text-sm font-semibold whitespace-nowrap transition-all"
                :class="statusFilter === 'all' 
                  ? 'bg-gradient-to-r from-primary to-primary-dark text-white shadow-lg shadow-primary/25' 
                  : 'bg-gray-100 text-gray-600 hover:bg-gray-200'"
                @click="statusFilter = 'all'"
              >
                Todas
              </button>
              <button
                type="button"
                class="px-4 py-2.5 rounded-xl text-sm font-semibold whitespace-nowrap transition-all"
                :class="statusFilter === 'pending' 
                  ? 'bg-gradient-to-r from-amber-400 to-amber-500 text-white shadow-lg shadow-amber-500/25' 
                  : 'bg-gray-100 text-gray-600 hover:bg-gray-200'"
                @click="statusFilter = 'pending'"
              >
                Pendientes
              </button>
              <button
                type="button"
                class="px-4 py-2.5 rounded-xl text-sm font-semibold whitespace-nowrap transition-all"
                :class="statusFilter === 'confirmed' 
                  ? 'bg-gradient-to-r from-emerald-500 to-emerald-600 text-white shadow-lg shadow-emerald-500/25' 
                  : 'bg-gray-100 text-gray-600 hover:bg-gray-200'"
                @click="statusFilter = 'confirmed'"
              >
                Confirmadas
              </button>
              <button
                type="button"
                class="px-4 py-2.5 rounded-xl text-sm font-semibold whitespace-nowrap transition-all"
                :class="statusFilter === 'cancelled' 
                  ? 'bg-gradient-to-r from-rose-500 to-rose-600 text-white shadow-lg shadow-rose-500/25' 
                  : 'bg-gray-100 text-gray-600 hover:bg-gray-200'"
                @click="statusFilter = 'cancelled'"
              >
                Canceladas
              </button>
            </div>
          </div>
        </div>

        <!-- Contador de resultados -->
        <div v-if="filteredBookings.length > 0" class="mb-6 flex items-center justify-between">
          <div class="text-sm text-gray-600">
            Mostrando <span class="font-bold text-gray-900">{{ filteredBookings.length }}</span> 
            {{ filteredBookings.length === 1 ? 'reserva' : 'reservas' }}
            <span v-if="statusFilter !== 'all' || searchQuery" class="text-gray-400">
              de {{ bookings.length }} en total
            </span>
          </div>
          <button
            v-if="statusFilter !== 'all' || searchQuery"
            type="button"
            class="inline-flex items-center gap-1.5 text-sm font-semibold text-primary hover:text-primary/80 transition"
            @click="statusFilter = 'all'; searchQuery = ''"
          >
            <span class="material-symbols-outlined !text-[18px]">close</span>
            Limpiar filtros
          </button>
        </div>

        <!-- Empty State - Mejorado -->
        <div v-if="filteredBookings.length === 0" class="text-center py-20">
          <div class="mx-auto flex h-28 w-28 items-center justify-center rounded-3xl bg-gradient-to-br from-gray-100 to-gray-200 mb-6">
            <span class="material-symbols-outlined text-6xl text-gray-400">event_busy</span>
          </div>
          <h3 class="text-2xl font-bold text-gray-900 mb-3">No hay reservas</h3>
          <p class="text-gray-500 mb-8 max-w-md mx-auto">
            {{ searchQuery || statusFilter !== 'all' 
              ? 'No se encontraron reservas con los filtros aplicados.' 
              : 'Aún no has realizado ninguna reserva. ¡Explora espacios disponibles!' 
            }}
          </p>
          <button
            v-if="!searchQuery && statusFilter === 'all'"
            type="button"
            class="group inline-flex items-center gap-2 rounded-xl bg-gradient-to-r from-primary to-primary-dark px-8 py-4 font-semibold text-white shadow-lg shadow-primary/30 transition-all hover:shadow-xl hover:shadow-primary/40"
            @click="router.push('/')"
          >
            <span class="material-symbols-outlined">explore</span>
            Explorar espacios
            <span class="material-symbols-outlined text-xl transition-transform group-hover:translate-x-1">arrow_forward</span>
          </button>
        </div>

        <!-- Bookings List -->
        <div v-else class="space-y-10">
          <!-- Upcoming Bookings -->
          <div v-if="upcomingBookings.length > 0">
            <div class="flex items-center gap-3 mb-6">
              <div class="flex h-10 w-10 items-center justify-center rounded-xl bg-gradient-to-br from-primary to-primary-dark">
                <span class="material-symbols-outlined text-white">upcoming</span>
              </div>
              <h2 class="text-xl font-bold text-gray-900">Próximas reservas</h2>
              <span class="px-3 py-1 rounded-full bg-primary/10 text-primary text-sm font-semibold">
                {{ upcomingBookings.length }}
              </span>
            </div>
            
            <div class="space-y-4">
              <div
                v-for="booking in upcomingBookings"
                :key="booking._id"
                class="group bg-white rounded-2xl p-6 shadow-sm ring-1 ring-black/5 hover:shadow-lg hover:ring-primary/20 transition-all cursor-pointer"
                @click="viewBooking(booking._id)"
              >
                <div class="flex flex-col lg:flex-row lg:items-center gap-5">
                  <!-- Space Info -->
                  <div class="flex-1">
                    <div class="flex items-start justify-between mb-4">
                      <div>
                        <h3 class="text-lg font-bold text-gray-900 mb-1 group-hover:text-primary transition-colors">
                          {{ booking.space?.name || 'Espacio no disponible' }}
                        </h3>
                        <p class="text-sm text-gray-500 flex items-center gap-1.5">
                          <span class="material-symbols-outlined !text-[16px]">location_on</span>
                          {{ booking.space?.address || 'Dirección no disponible' }}
                        </p>
                      </div>
                      <span
                        class="px-3 py-1.5 rounded-lg text-xs font-semibold flex items-center gap-1.5"
                        :class="getStatusColor(booking.status)"
                      >
                        <span class="material-symbols-outlined !text-[14px]">{{ getStatusIcon(booking.status) }}</span>
                        {{ getStatusLabel(booking.status) }}
                      </span>
                    </div>

                    <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
                      <div class="flex items-center gap-3 p-3 rounded-xl bg-gray-50">
                        <span class="material-symbols-outlined text-primary">event</span>
                        <div>
                          <p class="text-xs text-gray-500">Fecha</p>
                          <p class="font-semibold text-gray-900 text-sm">{{ formatDate(booking.startTime) }}</p>
                        </div>
                      </div>

                      <div class="flex items-center gap-3 p-3 rounded-xl bg-gray-50">
                        <span class="material-symbols-outlined text-primary">schedule</span>
                        <div>
                          <p class="text-xs text-gray-500">Horario</p>
                          <p class="font-semibold text-gray-900 text-sm">{{ formatTime(booking.startTime) }} - {{ formatTime(booking.endTime) }}</p>
                        </div>
                      </div>

                      <div class="flex items-center gap-3 p-3 rounded-xl bg-gray-50">
                        <span class="material-symbols-outlined text-primary">payments</span>
                        <div>
                          <p class="text-xs text-gray-500">Total</p>
                          <p class="font-semibold text-gray-900 text-sm">{{ formatCurrency(booking.totalAmount) }}</p>
                        </div>
                      </div>

                      <div class="flex items-center gap-3 p-3 rounded-xl bg-gray-50">
                        <span class="material-symbols-outlined" :class="booking.paymentStatus === 'paid' ? 'text-emerald-600' : 'text-amber-500'">
                          {{ booking.paymentStatus === 'paid' ? 'check_circle' : 'schedule' }}
                        </span>
                        <div>
                          <p class="text-xs text-gray-500">Pago</p>
                          <p class="font-semibold text-gray-900 text-sm">{{ getPaymentStatusLabel(booking.paymentStatus) }}</p>
                        </div>
                      </div>
                    </div>
                  </div>

                  <!-- Actions -->
                  <div class="flex lg:flex-col gap-3">
                    <button
                      type="button"
                      class="flex-1 lg:flex-none px-5 py-2.5 rounded-xl bg-gradient-to-r from-primary to-primary-dark text-white text-sm font-semibold shadow-md shadow-primary/20 hover:shadow-lg hover:shadow-primary/30 transition-all flex items-center justify-center gap-2"
                      @click.stop="viewBooking(booking._id)"
                    >
                      <span class="material-symbols-outlined !text-[18px]">visibility</span>
                      Ver detalles
                    </button>
                    <button
                      v-if="canCancel(booking)"
                      type="button"
                      class="flex-1 lg:flex-none px-5 py-2.5 rounded-xl bg-rose-50 text-rose-700 text-sm font-semibold ring-1 ring-rose-200 hover:bg-rose-100 transition-all flex items-center justify-center gap-2"
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
            <div class="flex items-center gap-3 mb-6">
              <div class="flex h-10 w-10 items-center justify-center rounded-xl bg-gray-200">
                <span class="material-symbols-outlined text-gray-600">history</span>
              </div>
              <h2 class="text-xl font-bold text-gray-900">Reservas pasadas</h2>
              <span class="px-3 py-1 rounded-full bg-gray-100 text-gray-600 text-sm font-semibold">
                {{ pastBookings.length }}
              </span>
            </div>
            
            <div class="space-y-4">
              <div
                v-for="booking in pastBookings"
                :key="booking._id"
                class="group bg-white rounded-2xl p-6 shadow-sm ring-1 ring-black/5 opacity-80 hover:opacity-100 hover:shadow-md transition-all cursor-pointer"
                @click="viewBooking(booking._id)"
              >
                <div class="flex flex-col lg:flex-row lg:items-center gap-5">
                  <!-- Space Info -->
                  <div class="flex-1">
                    <div class="flex items-start justify-between mb-4">
                      <div>
                        <h3 class="text-lg font-bold text-gray-900 mb-1">{{ booking.space?.name || 'Espacio no disponible' }}</h3>
                        <p class="text-sm text-gray-500 flex items-center gap-1.5">
                          <span class="material-symbols-outlined !text-[16px]">location_on</span>
                          {{ booking.space?.address || 'Dirección no disponible' }}
                        </p>
                      </div>
                      <span
                        class="px-3 py-1.5 rounded-lg text-xs font-semibold flex items-center gap-1.5"
                        :class="getStatusColor(booking.status)"
                      >
                        <span class="material-symbols-outlined !text-[14px]">{{ getStatusIcon(booking.status) }}</span>
                        {{ getStatusLabel(booking.status) }}
                      </span>
                    </div>

                    <div class="grid grid-cols-2 md:grid-cols-3 gap-4">
                      <div class="flex items-center gap-3 p-3 rounded-xl bg-gray-50">
                        <span class="material-symbols-outlined text-gray-400">event</span>
                        <div>
                          <p class="text-xs text-gray-500">Fecha</p>
                          <p class="font-semibold text-gray-900 text-sm">{{ formatDate(booking.startTime) }}</p>
                        </div>
                      </div>

                      <div class="flex items-center gap-3 p-3 rounded-xl bg-gray-50">
                        <span class="material-symbols-outlined text-gray-400">schedule</span>
                        <div>
                          <p class="text-xs text-gray-500">Horario</p>
                          <p class="font-semibold text-gray-900 text-sm">{{ formatTime(booking.startTime) }} - {{ formatTime(booking.endTime) }}</p>
                        </div>
                      </div>

                      <div class="flex items-center gap-3 p-3 rounded-xl bg-gray-50">
                        <span class="material-symbols-outlined text-gray-400">payments</span>
                        <div>
                          <p class="text-xs text-gray-500">Total</p>
                          <p class="font-semibold text-gray-900 text-sm">{{ formatCurrency(booking.totalAmount) }}</p>
                        </div>
                      </div>
                    </div>
                  </div>

                  <!-- Actions -->
                  <div>
                    <button
                      type="button"
                      class="px-5 py-2.5 rounded-xl bg-gray-100 text-gray-700 text-sm font-semibold hover:bg-gray-200 transition-all flex items-center justify-center gap-2"
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
