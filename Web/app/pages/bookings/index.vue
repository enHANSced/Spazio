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
const toast = useToast()

// Cargar reservas del usuario
const { data: bookingsData, pending, error, refresh } = await useAsyncData<Booking[]>(
  'user-bookings',
  () => BookingsService.list(),
  { server: false }
)

const bookings = computed(() => bookingsData.value || [])

// Estado de notificaciones descartadas (persistido en localStorage)
const dismissedNotifications = ref<Set<string>>(new Set())

// Cargar notificaciones descartadas desde localStorage
onMounted(() => {
  try {
    const saved = localStorage.getItem('spazio_dismissed_booking_notifications')
    if (saved) {
      const parsed = JSON.parse(saved)
      // Limpiar notificaciones viejas (más de 24h)
      const now = Date.now()
      const validEntries = parsed.filter((entry: { id: string, timestamp: number }) => 
        now - entry.timestamp < 24 * 60 * 60 * 1000
      )
      dismissedNotifications.value = new Set(validEntries.map((e: { id: string }) => e.id))
      // Guardar solo las válidas
      localStorage.setItem('spazio_dismissed_booking_notifications', JSON.stringify(validEntries))
    }
  } catch (e) {
    // Si hay error, limpiar
    localStorage.removeItem('spazio_dismissed_booking_notifications')
  }
})

// Descartar una notificación
const dismissNotification = (bookingId: string) => {
  dismissedNotifications.value.add(bookingId)
  // Guardar en localStorage con timestamp
  try {
    const saved = localStorage.getItem('spazio_dismissed_booking_notifications')
    const entries = saved ? JSON.parse(saved) : []
    entries.push({ id: bookingId, timestamp: Date.now() })
    localStorage.setItem('spazio_dismissed_booking_notifications', JSON.stringify(entries))
  } catch (e) {
    // Ignorar errores de localStorage
  }
}

// Descartar todas las notificaciones
const dismissAllNotifications = () => {
  const allIds = [
    ...recentlyConfirmedBookings.value.map(b => b._id),
    ...recentlyRejectedBookings.value.map(b => b._id)
  ]
  allIds.forEach(id => dismissNotification(id))
}

// Modal de subir comprobante
const showUploadModal = ref(false)
const selectedBookingForUpload = ref<Booking | null>(null)
const uploadingProof = ref(false)
const proofFile = ref<File | null>(null)
const fileInputRef = ref<HTMLInputElement | null>(null)

// Abrir modal de subir comprobante
const openUploadModal = (booking: Booking) => {
  selectedBookingForUpload.value = booking
  proofFile.value = null
  showUploadModal.value = true
}

// Seleccionar archivo
const onFileSelect = (event: Event) => {
  const target = event.target as HTMLInputElement
  if (target.files && target.files[0]) {
    const file = target.files[0]
    // Validar tipo de archivo
    if (!file.type.startsWith('image/') && file.type !== 'application/pdf') {
      toast.error('Solo se permiten imágenes o archivos PDF')
      return
    }
    // Validar tamaño (máximo 5MB)
    if (file.size > 5 * 1024 * 1024) {
      toast.error('El archivo no puede superar los 5MB')
      return
    }
    proofFile.value = file
  }
}

// Subir comprobante
const uploadProof = async () => {
  if (!selectedBookingForUpload.value || !proofFile.value) return

  uploadingProof.value = true
  try {
    await BookingsService.uploadTransferProof(selectedBookingForUpload.value._id, proofFile.value)
    toast.success('¡Comprobante subido exitosamente! El propietario lo verificará pronto.')
    showUploadModal.value = false
    selectedBookingForUpload.value = null
    proofFile.value = null
    await refresh()
  } catch (error: any) {
    console.error('Error al subir comprobante:', error)
    toast.error(error?.data?.message || 'Error al subir el comprobante. Intenta nuevamente.')
  } finally {
    uploadingProof.value = false
  }
}

// Verificar si una reserva necesita comprobante de transferencia
const needsTransferProof = (booking: Booking) => {
  return booking.paymentMethod === 'transfer' && 
         !booking.transferProofUrl && 
         booking.status !== 'cancelled' &&
         booking.paymentStatus !== 'paid'
}

// Verificar si el comprobante está pendiente de verificación
const isTransferPending = (booking: Booking) => {
  return booking.paymentMethod === 'transfer' && 
         booking.transferProofUrl && 
         !booking.transferVerifiedAt &&
         !booking.transferRejectedAt
}

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

// Agrupar reservas - mantener el orden de filteredBookings
const upcomingBookings = computed(() => {
  // Filtrar reservas activas (no canceladas) y futuras
  const filtered = filteredBookings.value.filter(b => 
    b.status !== 'cancelled' && new Date(b.startTime) > new Date()
  )
  // El orden ya viene de filteredBookings, no necesitamos reordenar
  return filtered
})

const pastBookings = computed(() => {
  // Reservas canceladas/rechazadas O que ya pasaron
  const filtered = filteredBookings.value.filter(b => 
    b.status === 'cancelled' || new Date(b.endTime) < new Date()
  )
  // El orden ya viene de filteredBookings, no necesitamos reordenar
  return filtered
})

// Reservas recién confirmadas (para destacar) - excluir descartadas
const recentlyConfirmedBookings = computed(() => 
  bookings.value.filter(b => {
    if (b.status !== 'confirmed' || !b.confirmedAt) return false
    if (dismissedNotifications.value.has(b._id)) return false
    // Mostrar como "recién confirmada" si fue confirmada en las últimas 24 horas
    const confirmedDate = new Date(b.confirmedAt)
    const now = new Date()
    const hoursDiff = (now.getTime() - confirmedDate.getTime()) / (1000 * 60 * 60)
    return hoursDiff <= 24
  })
)

// Reservas rechazadas recientemente (para destacar) - excluir descartadas
const recentlyRejectedBookings = computed(() => 
  bookings.value.filter(b => {
    if (b.status !== 'cancelled' || !b.rejectedAt) return false
    if (dismissedNotifications.value.has(b._id)) return false
    // Mostrar como "recién rechazada" si fue rechazada en las últimas 24 horas
    const rejectedDate = new Date(b.rejectedAt)
    const now = new Date()
    const hoursDiff = (now.getTime() - rejectedDate.getTime()) / (1000 * 60 * 60)
    return hoursDiff <= 24
  })
)

// Total de notificaciones activas
const totalActiveNotifications = computed(() => 
  recentlyConfirmedBookings.value.length + recentlyRejectedBookings.value.length
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

const formatDateTime = (dateString: string) => {
  return new Date(dateString).toLocaleString('es-HN', {
    day: 'numeric',
    month: 'short',
    hour: 'numeric',
    minute: '2-digit',
    hour12: true
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
    case 'pending':
      return 'Por definir'
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

        <!-- Alertas de notificaciones - Estilo compacto tipo notificación móvil -->
        <div v-if="totalActiveNotifications > 0" class="mb-6">
          <!-- Header de notificaciones -->
          <div class="flex items-center justify-between mb-3">
            <div class="flex items-center gap-2">
              <span class="material-symbols-outlined text-gray-500 !text-[20px]">notifications</span>
              <span class="text-sm font-semibold text-gray-700">
                {{ totalActiveNotifications }} {{ totalActiveNotifications === 1 ? 'notificación' : 'notificaciones' }}
              </span>
            </div>
            <button
              v-if="totalActiveNotifications > 1"
              @click="dismissAllNotifications"
              class="text-xs text-gray-500 hover:text-gray-700 font-medium transition-colors"
            >
              Descartar todas
            </button>
          </div>

          <div class="space-y-2">
            <!-- Notificaciones de reservas confirmadas -->
            <TransitionGroup name="notification">
              <div 
                v-for="booking in recentlyConfirmedBookings"
                :key="'confirmed-' + booking._id"
                class="group flex items-center gap-3 bg-white rounded-xl p-3 shadow-sm ring-1 ring-emerald-200 hover:shadow-md transition-all"
              >
                <div class="flex h-10 w-10 items-center justify-center rounded-full bg-emerald-100 flex-shrink-0">
                  <span class="material-symbols-outlined text-emerald-600 !text-[20px]">check_circle</span>
                </div>
                <div class="flex-1 min-w-0">
                  <p class="text-sm font-semibold text-gray-900 truncate">
                    ¡Reserva confirmada!
                  </p>
                  <p class="text-xs text-gray-500 truncate">
                    {{ booking.space?.name }} · {{ formatDateTime(booking.confirmedAt!) }}
                  </p>
                </div>
                <div class="flex items-center gap-1 flex-shrink-0">
                  <button
                    @click.stop="viewBooking(booking._id)"
                    class="p-2 rounded-lg text-emerald-600 hover:bg-emerald-50 transition-colors"
                    title="Ver detalles"
                  >
                    <span class="material-symbols-outlined !text-[20px]">visibility</span>
                  </button>
                  <button
                    @click.stop="dismissNotification(booking._id)"
                    class="p-2 rounded-lg text-gray-400 hover:text-gray-600 hover:bg-gray-100 transition-colors opacity-0 group-hover:opacity-100"
                    title="Descartar"
                  >
                    <span class="material-symbols-outlined !text-[20px]">close</span>
                  </button>
                </div>
              </div>
            </TransitionGroup>

            <!-- Notificaciones de reservas rechazadas -->
            <TransitionGroup name="notification">
              <div 
                v-for="booking in recentlyRejectedBookings"
                :key="'rejected-' + booking._id"
                class="group flex items-center gap-3 bg-white rounded-xl p-3 shadow-sm ring-1 ring-rose-200 hover:shadow-md transition-all"
              >
                <div class="flex h-10 w-10 items-center justify-center rounded-full bg-rose-100 flex-shrink-0">
                  <span class="material-symbols-outlined text-rose-600 !text-[20px]">cancel</span>
                </div>
                <div class="flex-1 min-w-0">
                  <p class="text-sm font-semibold text-gray-900 truncate">
                    Reserva rechazada
                  </p>
                  <p class="text-xs text-gray-500 truncate">
                    {{ booking.space?.name }} · {{ booking.rejectionReason || 'Sin motivo especificado' }}
                  </p>
                </div>
                <div class="flex items-center gap-1 flex-shrink-0">
                  <button
                    @click.stop="viewBooking(booking._id)"
                    class="p-2 rounded-lg text-rose-600 hover:bg-rose-50 transition-colors"
                    title="Ver detalles"
                  >
                    <span class="material-symbols-outlined !text-[20px]">visibility</span>
                  </button>
                  <button
                    @click.stop="dismissNotification(booking._id)"
                    class="p-2 rounded-lg text-gray-400 hover:text-gray-600 hover:bg-gray-100 transition-colors opacity-0 group-hover:opacity-100"
                    title="Descartar"
                  >
                    <span class="material-symbols-outlined !text-[20px]">close</span>
                  </button>
                </div>
              </div>
            </TransitionGroup>
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
            
            <div class="space-y-5">
              <article
                v-for="booking in upcomingBookings"
                :key="booking._id"
                class="group relative overflow-hidden bg-white rounded-2xl shadow-lg ring-1 ring-black/5 hover:shadow-xl hover:shadow-primary/10 transition-all duration-300 cursor-pointer"
                @click="viewBooking(booking._id)"
              >
                <!-- Decorative gradient border on hover -->
                <div class="absolute inset-0 rounded-2xl bg-gradient-to-r from-primary via-primary-dark to-blue-600 opacity-0 group-hover:opacity-100 transition-opacity duration-300" style="padding: 2px;">
                  <div class="h-full w-full rounded-2xl bg-white"></div>
                </div>

                <div class="relative p-6 lg:p-8">
                  <div class="flex flex-col gap-6">
                    <!-- Header Section -->
                    <div class="flex items-start justify-between gap-4">
                      <div class="flex-1 min-w-0">
                        <h3 class="text-xl font-bold text-gray-900 mb-2 group-hover:text-primary transition-colors truncate">
                          {{ booking.space?.name || 'Espacio no disponible' }}
                        </h3>
                        <p class="text-sm text-gray-600 flex items-center gap-2">
                          <span class="material-symbols-outlined !text-[18px] text-gray-400">location_on</span>
                          {{ booking.space?.address || 'Dirección no disponible' }}
                        </p>
                      </div>
                      
                      <!-- Status Badge con gradiente -->
                      <div
                        class="shrink-0 px-4 py-2 rounded-xl text-xs font-bold flex items-center gap-2 shadow-md"
                        :class="booking.status === 'confirmed' 
                          ? 'bg-gradient-to-r from-emerald-500 to-emerald-600 text-white shadow-emerald-500/30'
                          : 'bg-gradient-to-r from-amber-400 to-amber-500 text-white shadow-amber-500/30'"
                      >
                        <span class="material-symbols-outlined !text-[16px]">{{ getStatusIcon(booking.status) }}</span>
                        {{ getStatusLabel(booking.status) }}
                      </div>
                    </div>

                    <!-- Alerta de confirmación por el propietario -->
                    <div 
                      v-if="booking.status === 'confirmed' && booking.confirmedAt"
                      class="p-3 rounded-xl bg-gradient-to-r from-emerald-50 to-teal-50 ring-1 ring-emerald-200"
                    >
                      <div class="flex items-center gap-2">
                        <span class="material-symbols-outlined text-emerald-600 !text-[18px]">verified</span>
                        <p class="text-sm font-medium text-emerald-700">
                          Confirmada por el propietario el {{ formatDateTime(booking.confirmedAt) }}
                        </p>
                      </div>
                    </div>

                    <!-- Motivo de rechazo (si aplica) -->
                    <div 
                      v-if="booking.status === 'cancelled' && booking.rejectedAt"
                      class="p-4 rounded-xl bg-gradient-to-r from-rose-50 to-rose-100/50 ring-1 ring-rose-200"
                    >
                      <div class="flex items-start gap-3">
                        <div class="flex h-9 w-9 items-center justify-center rounded-lg bg-rose-200 flex-shrink-0">
                          <span class="material-symbols-outlined text-rose-600 !text-[18px]">info</span>
                        </div>
                        <div class="flex-1 min-w-0">
                          <p class="text-sm font-semibold text-rose-700 mb-1">Reserva rechazada por el propietario</p>
                          <p v-if="booking.rejectionReason" class="text-sm text-rose-600">
                            "{{ booking.rejectionReason }}"
                          </p>
                          <p v-else class="text-sm text-rose-500 italic">
                            No se proporcionó un motivo
                          </p>
                        </div>
                      </div>
                    </div>

                    <!-- Info Grid con diseño premium -->
                    <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
                      <!-- Fecha -->
                      <div class="group/card relative overflow-hidden rounded-xl bg-gradient-to-br from-blue-50 to-blue-100/50 p-4 ring-1 ring-blue-200/50 hover:shadow-md transition-all">
                        <div class="absolute -right-2 -top-2 h-16 w-16 rounded-full bg-gradient-to-br from-blue-400/10 to-blue-600/10 blur-2xl"></div>
                        <div class="relative flex items-center gap-3">
                          <div class="flex h-10 w-10 items-center justify-center rounded-lg bg-gradient-to-br from-blue-500 to-blue-600 shadow-lg shadow-blue-500/25">
                            <span class="material-symbols-outlined text-white !text-[20px]">event</span>
                          </div>
                          <div class="flex-1 min-w-0">
                            <p class="text-xs font-medium text-blue-600 uppercase tracking-wide mb-0.5">Fecha</p>
                            <p class="font-bold text-gray-900 text-sm truncate">{{ formatDate(booking.startTime) }}</p>
                          </div>
                        </div>
                      </div>

                      <!-- Horario -->
                      <div class="group/card relative overflow-hidden rounded-xl bg-gradient-to-br from-purple-50 to-purple-100/50 p-4 ring-1 ring-purple-200/50 hover:shadow-md transition-all">
                        <div class="absolute -right-2 -top-2 h-16 w-16 rounded-full bg-gradient-to-br from-purple-400/10 to-purple-600/10 blur-2xl"></div>
                        <div class="relative flex items-center gap-3">
                          <div class="flex h-10 w-10 items-center justify-center rounded-lg bg-gradient-to-br from-purple-500 to-purple-600 shadow-lg shadow-purple-500/25">
                            <span class="material-symbols-outlined text-white !text-[20px]">schedule</span>
                          </div>
                          <div class="flex-1 min-w-0">
                            <p class="text-xs font-medium text-purple-600 uppercase tracking-wide mb-0.5">Horario</p>
                            <p class="font-bold text-gray-900 text-sm truncate">{{ formatTime(booking.startTime) }} - {{ formatTime(booking.endTime) }}</p>
                          </div>
                        </div>
                      </div>

                      <!-- Total -->
                      <div class="group/card relative overflow-hidden rounded-xl bg-gradient-to-br from-emerald-50 to-emerald-100/50 p-4 ring-1 ring-emerald-200/50 hover:shadow-md transition-all">
                        <div class="absolute -right-2 -top-2 h-16 w-16 rounded-full bg-gradient-to-br from-emerald-400/10 to-emerald-600/10 blur-2xl"></div>
                        <div class="relative flex items-center gap-3">
                          <div class="flex h-10 w-10 items-center justify-center rounded-lg bg-gradient-to-br from-emerald-500 to-emerald-600 shadow-lg shadow-emerald-500/25">
                            <span class="material-symbols-outlined text-white !text-[20px]">payments</span>
                          </div>
                          <div class="flex-1 min-w-0">
                            <p class="text-xs font-medium text-emerald-600 uppercase tracking-wide mb-0.5">Total</p>
                            <p class="font-bold text-gray-900 text-sm truncate">{{ formatCurrency(booking.totalAmount) }}</p>
                          </div>
                        </div>
                      </div>

                      <!-- Estado de Pago -->
                      <div 
                        class="group/card relative overflow-hidden rounded-xl p-4 ring-1 hover:shadow-md transition-all"
                        :class="booking.paymentStatus === 'paid' 
                          ? 'bg-gradient-to-br from-teal-50 to-teal-100/50 ring-teal-200/50' 
                          : 'bg-gradient-to-br from-amber-50 to-amber-100/50 ring-amber-200/50'"
                      >
                        <div 
                          class="absolute -right-2 -top-2 h-16 w-16 rounded-full blur-2xl"
                          :class="booking.paymentStatus === 'paid' 
                            ? 'bg-gradient-to-br from-teal-400/10 to-teal-600/10' 
                            : 'bg-gradient-to-br from-amber-400/10 to-amber-600/10'"
                        ></div>
                        <div class="relative flex items-center gap-3">
                          <div 
                            class="flex h-10 w-10 items-center justify-center rounded-lg shadow-lg"
                            :class="booking.paymentStatus === 'paid' 
                              ? 'bg-gradient-to-br from-teal-500 to-teal-600 shadow-teal-500/25' 
                              : 'bg-gradient-to-br from-amber-400 to-amber-500 shadow-amber-500/25'"
                          >
                            <span class="material-symbols-outlined text-white !text-[20px]">
                              {{ booking.paymentStatus === 'paid' ? 'check_circle' : 'schedule' }}
                            </span>
                          </div>
                          <div class="flex-1 min-w-0">
                            <p 
                              class="text-xs font-medium uppercase tracking-wide mb-0.5"
                              :class="booking.paymentStatus === 'paid' ? 'text-teal-600' : 'text-amber-600'"
                            >
                              Pago
                            </p>
                            <p class="font-bold text-gray-900 text-sm truncate">{{ getPaymentStatusLabel(booking.paymentStatus) }}</p>
                          </div>
                        </div>
                      </div>
                    </div>

                    <!-- Transfer Proof Status -->
                    <div 
                      v-if="booking.paymentMethod === 'transfer'"
                      class="flex items-center gap-3 pt-2"
                    >
                      <!-- Needs upload -->
                      <div 
                        v-if="needsTransferProof(booking)"
                        class="flex items-center gap-2 px-3 py-2 rounded-lg bg-amber-50 ring-1 ring-amber-200"
                      >
                        <span class="material-symbols-outlined text-amber-600 !text-[18px]">info</span>
                        <span class="text-sm font-medium text-amber-700">Pendiente: Subir comprobante de transferencia</span>
                      </div>
                      
                      <!-- Proof uploaded, pending verification -->
                      <div 
                        v-else-if="isTransferPending(booking)"
                        class="flex items-center gap-2 px-3 py-2 rounded-lg bg-blue-50 ring-1 ring-blue-200"
                      >
                        <span class="material-symbols-outlined text-blue-600 !text-[18px]">schedule</span>
                        <span class="text-sm font-medium text-blue-700">Comprobante enviado, pendiente de verificación</span>
                      </div>
                      
                      <!-- Proof verified -->
                      <div 
                        v-else-if="booking.transferProofUrl && booking.transferVerifiedAt"
                        class="flex items-center gap-2 px-3 py-2 rounded-lg bg-emerald-50 ring-1 ring-emerald-200"
                      >
                        <span class="material-symbols-outlined text-emerald-600 !text-[18px]">check_circle</span>
                        <span class="text-sm font-medium text-emerald-700">Transferencia verificada</span>
                      </div>
                    </div>

                    <!-- Actions Section -->
                    <div class="flex flex-col sm:flex-row gap-3 pt-4 border-t border-gray-100">
                      <button
                        type="button"
                        class="group/btn flex-1 sm:flex-none relative overflow-hidden px-6 py-3 rounded-xl bg-gradient-to-r from-primary via-primary-dark to-blue-600 text-white font-bold shadow-lg shadow-primary/30 hover:shadow-xl hover:shadow-primary/40 transition-all duration-300 flex items-center justify-center gap-2"
                        @click.stop="viewBooking(booking._id)"
                      >
                        <span class="material-symbols-outlined !text-[20px]">visibility</span>
                        Ver detalles
                        <span class="material-symbols-outlined !text-[20px] transition-transform group-hover/btn:translate-x-1">arrow_forward</span>
                      </button>
                      
                      <!-- Upload Transfer Proof Button -->
                      <button
                        v-if="needsTransferProof(booking)"
                        type="button"
                        class="group/btn flex-1 sm:flex-none px-6 py-3 rounded-xl bg-gradient-to-r from-amber-400 to-amber-500 text-white font-bold shadow-lg shadow-amber-500/30 hover:shadow-xl hover:shadow-amber-500/40 transition-all duration-300 flex items-center justify-center gap-2"
                        @click.stop="openUploadModal(booking)"
                      >
                        <span class="material-symbols-outlined !text-[20px]">upload_file</span>
                        Subir comprobante
                      </button>
                      
                      <button
                        v-if="canCancel(booking)"
                        type="button"
                        class="group/btn flex-1 sm:flex-none px-6 py-3 rounded-xl bg-gradient-to-r from-rose-50 to-rose-100 text-rose-700 font-bold ring-2 ring-rose-200 hover:from-rose-100 hover:to-rose-200 hover:ring-rose-300 transition-all duration-300 flex items-center justify-center gap-2"
                        @click.stop="cancelBooking(booking._id)"
                      >
                        <span class="material-symbols-outlined !text-[20px]">cancel</span>
                        Cancelar reserva
                      </button>
                    </div>
                  </div>
                </div>
              </article>
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
            
            <div class="space-y-5">
              <article
                v-for="booking in pastBookings"
                :key="booking._id"
                class="group relative overflow-hidden bg-gradient-to-br from-gray-50 to-gray-100/50 rounded-2xl shadow-md ring-1 ring-gray-200/50 hover:shadow-lg hover:from-white hover:to-gray-50 transition-all duration-300 cursor-pointer"
                @click="viewBooking(booking._id)"
              >
                <div class="p-6 lg:p-8">
                  <div class="flex flex-col gap-5">
                    <!-- Header Section -->
                    <div class="flex items-start justify-between gap-4">
                      <div class="flex-1 min-w-0">
                        <h3 class="text-lg font-bold text-gray-800 mb-2 truncate">
                          {{ booking.space?.name || 'Espacio no disponible' }}
                        </h3>
                        <p class="text-sm text-gray-500 flex items-center gap-2">
                          <span class="material-symbols-outlined !text-[18px] text-gray-400">location_on</span>
                          {{ booking.space?.address || 'Dirección no disponible' }}
                        </p>
                      </div>
                      
                      <!-- Status Badge -->
                      <div
                        class="shrink-0 px-3 py-1.5 rounded-lg text-xs font-bold flex items-center gap-1.5 ring-1"
                        :class="booking.status === 'cancelled' 
                          ? 'bg-gray-100 text-gray-600 ring-gray-300' 
                          : 'bg-gray-200 text-gray-700 ring-gray-400'"
                      >
                        <span class="material-symbols-outlined !text-[14px]">{{ getStatusIcon(booking.status) }}</span>
                        {{ getStatusLabel(booking.status) }}
                      </div>
                    </div>

                    <!-- Motivo de rechazo (si aplica) -->
                    <div 
                      v-if="booking.status === 'cancelled' && booking.rejectedAt"
                      class="p-3 rounded-xl bg-rose-50 ring-1 ring-rose-200"
                    >
                      <div class="flex items-start gap-2">
                        <span class="material-symbols-outlined text-rose-500 !text-[18px] flex-shrink-0">info</span>
                        <div class="flex-1 min-w-0">
                          <p class="text-xs font-semibold text-rose-600 mb-0.5">Rechazada por el propietario</p>
                          <p v-if="booking.rejectionReason" class="text-sm text-rose-600">
                            "{{ booking.rejectionReason }}"
                          </p>
                          <p v-else class="text-xs text-rose-400 italic">
                            Sin motivo especificado
                          </p>
                        </div>
                      </div>
                    </div>

                    <!-- Info Grid simplificado -->
                    <div class="grid grid-cols-1 sm:grid-cols-3 gap-4">
                      <!-- Fecha -->
                      <div class="flex items-center gap-3 p-3 rounded-xl bg-white/60 ring-1 ring-gray-200">
                        <div class="flex h-9 w-9 items-center justify-center rounded-lg bg-gray-200">
                          <span class="material-symbols-outlined text-gray-600 !text-[18px]">event</span>
                        </div>
                        <div class="flex-1 min-w-0">
                          <p class="text-xs font-medium text-gray-500 uppercase tracking-wide">Fecha</p>
                          <p class="font-bold text-gray-800 text-sm truncate">{{ formatDate(booking.startTime) }}</p>
                        </div>
                      </div>

                      <!-- Horario -->
                      <div class="flex items-center gap-3 p-3 rounded-xl bg-white/60 ring-1 ring-gray-200">
                        <div class="flex h-9 w-9 items-center justify-center rounded-lg bg-gray-200">
                          <span class="material-symbols-outlined text-gray-600 !text-[18px]">schedule</span>
                        </div>
                        <div class="flex-1 min-w-0">
                          <p class="text-xs font-medium text-gray-500 uppercase tracking-wide">Horario</p>
                          <p class="font-bold text-gray-800 text-sm truncate">{{ formatTime(booking.startTime) }} - {{ formatTime(booking.endTime) }}</p>
                        </div>
                      </div>

                      <!-- Total -->
                      <div class="flex items-center gap-3 p-3 rounded-xl bg-white/60 ring-1 ring-gray-200">
                        <div class="flex h-9 w-9 items-center justify-center rounded-lg bg-gray-200">
                          <span class="material-symbols-outlined text-gray-600 !text-[18px]">payments</span>
                        </div>
                        <div class="flex-1 min-w-0">
                          <p class="text-xs font-medium text-gray-500 uppercase tracking-wide">Total</p>
                          <p class="font-bold text-gray-800 text-sm truncate">{{ formatCurrency(booking.totalAmount) }}</p>
                        </div>
                      </div>
                    </div>

                    <!-- Actions Section -->
                    <div class="pt-3 border-t border-gray-200">
                      <button
                        type="button"
                        class="group/btn w-full sm:w-auto px-6 py-2.5 rounded-xl bg-white text-gray-700 font-semibold ring-1 ring-gray-300 hover:bg-gray-50 hover:ring-gray-400 transition-all flex items-center justify-center gap-2"
                        @click.stop="viewBooking(booking._id)"
                      >
                        <span class="material-symbols-outlined !text-[18px]">visibility</span>
                        Ver detalles
                        <span class="material-symbols-outlined !text-[18px] transition-transform group-hover/btn:translate-x-1">arrow_forward</span>
                      </button>
                    </div>
                  </div>
                </div>
              </article>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Modal: Subir Comprobante de Transferencia -->
    <Teleport to="body">
      <Transition name="modal">
        <div 
          v-if="showUploadModal" 
          class="fixed inset-0 z-50 flex items-center justify-center p-4"
        >
          <!-- Backdrop -->
          <div 
            class="absolute inset-0 bg-black/50 backdrop-blur-sm"
            @click="showUploadModal = false"
          ></div>
          
          <!-- Modal Content -->
          <div class="relative w-full max-w-lg bg-white rounded-2xl shadow-2xl overflow-hidden">
            <!-- Header -->
            <div class="px-6 py-5 bg-gradient-to-r from-primary via-primary-dark to-blue-600">
              <div class="flex items-center justify-between">
                <div class="flex items-center gap-3">
                  <div class="flex h-10 w-10 items-center justify-center rounded-xl bg-white/20">
                    <span class="material-symbols-outlined text-white">receipt_long</span>
                  </div>
                  <h3 class="text-xl font-bold text-white">Subir Comprobante</h3>
                </div>
                <button
                  type="button"
                  class="p-2 rounded-lg bg-white/10 text-white hover:bg-white/20 transition"
                  @click="showUploadModal = false"
                >
                  <span class="material-symbols-outlined">close</span>
                </button>
              </div>
            </div>
            
            <!-- Body -->
            <div class="p-6 space-y-5">
              <!-- Info del espacio -->
              <div v-if="selectedBookingForUpload" class="p-4 rounded-xl bg-gray-50 ring-1 ring-gray-200">
                <p class="text-sm text-gray-500 mb-1">Reserva en:</p>
                <p class="font-bold text-gray-900">{{ selectedBookingForUpload.space?.name }}</p>
                <p class="text-sm text-gray-600 mt-1">
                  {{ formatDate(selectedBookingForUpload.startTime) }} • 
                  {{ formatCurrency(selectedBookingForUpload.totalAmount) }}
                </p>
              </div>
              
              <!-- Instrucciones -->
              <div class="flex items-start gap-3 p-4 rounded-xl bg-amber-50 ring-1 ring-amber-200">
                <span class="material-symbols-outlined text-amber-600 mt-0.5">info</span>
                <div>
                  <p class="text-sm font-medium text-amber-800">Sube una imagen o PDF del comprobante de tu transferencia.</p>
                  <p class="text-xs text-amber-600 mt-1">Formato: JPG, PNG o PDF • Máximo 5MB</p>
                </div>
              </div>
              
              <!-- File Upload Area -->
              <div class="space-y-3">
                <label 
                  class="relative flex flex-col items-center justify-center w-full h-44 border-2 border-dashed rounded-xl cursor-pointer transition-all"
                  :class="proofFile 
                    ? 'border-emerald-400 bg-emerald-50/50' 
                    : 'border-gray-300 hover:border-primary hover:bg-primary/5'"
                >
                  <input
                    ref="fileInputRef"
                    type="file"
                    accept="image/*,.pdf"
                    class="sr-only"
                    @change="onFileSelect"
                  />
                  
                  <template v-if="!proofFile">
                    <div class="flex h-14 w-14 items-center justify-center rounded-full bg-gray-100 mb-3">
                      <span class="material-symbols-outlined text-3xl text-gray-400">cloud_upload</span>
                    </div>
                    <p class="text-sm font-semibold text-gray-700 mb-1">Haz clic para seleccionar archivo</p>
                    <p class="text-xs text-gray-500">o arrastra y suelta aquí</p>
                  </template>
                  
                  <template v-else>
                    <div class="flex h-14 w-14 items-center justify-center rounded-full bg-emerald-100 mb-3">
                      <span class="material-symbols-outlined text-3xl text-emerald-600">check_circle</span>
                    </div>
                    <p class="text-sm font-bold text-emerald-700 mb-1">{{ proofFile.name }}</p>
                    <p class="text-xs text-gray-500">{{ (proofFile.size / 1024 / 1024).toFixed(2) }} MB</p>
                    <button
                      type="button"
                      class="mt-2 text-xs text-rose-600 hover:text-rose-700 font-medium"
                      @click.stop.prevent="proofFile = null"
                    >
                      Cambiar archivo
                    </button>
                  </template>
                </label>
              </div>
            </div>
            
            <!-- Footer -->
            <div class="px-6 py-4 bg-gray-50 border-t border-gray-200 flex gap-3">
              <button
                type="button"
                class="flex-1 px-4 py-3 rounded-xl bg-gray-200 text-gray-700 font-semibold hover:bg-gray-300 transition"
                @click="showUploadModal = false"
              >
                Cancelar
              </button>
              <button
                type="button"
                class="flex-1 px-4 py-3 rounded-xl bg-gradient-to-r from-primary to-primary-dark text-white font-bold shadow-lg shadow-primary/30 hover:shadow-primary/40 transition-all disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2"
                :disabled="!proofFile || uploadingProof"
                @click="uploadProof"
              >
                <span v-if="uploadingProof" class="material-symbols-outlined animate-spin">refresh</span>
                <span v-else class="material-symbols-outlined">upload</span>
                {{ uploadingProof ? 'Subiendo...' : 'Enviar comprobante' }}
              </button>
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>
  </div>
</template>

<style scoped>
/* Modal transitions */
.modal-enter-active,
.modal-leave-active {
  transition: all 0.3s ease;
}

.modal-enter-from,
.modal-leave-to {
  opacity: 0;
}

.modal-enter-from > div:last-child,
.modal-leave-to > div:last-child {
  transform: scale(0.95) translateY(10px);
}

/* Notification transitions */
.notification-enter-active {
  transition: all 0.3s ease-out;
}

.notification-leave-active {
  transition: all 0.25s ease-in;
}

.notification-enter-from {
  opacity: 0;
  transform: translateX(-20px);
}

.notification-leave-to {
  opacity: 0;
  transform: translateX(20px);
}

.notification-move {
  transition: transform 0.25s ease;
}
</style>
