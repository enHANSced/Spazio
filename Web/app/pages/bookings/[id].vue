<script setup lang="ts">
import { computed, ref } from 'vue'
import BookingsService from '~/services/bookings.service'
import type { Booking, PaymentMethod } from '~/types/booking'

definePageMeta({
  middleware: 'auth'
})

const route = useRoute()
const router = useRouter()

const bookingId = computed(() => route.params.id as string)

// Cargar datos de la reserva
const { data: bookingData, pending, error, refresh } = await useAsyncData<Booking>(
  `booking:${bookingId.value}`,
  () => BookingsService.getById(bookingId.value),
  { server: false }
)

const booking = computed(() => bookingData.value)

// Estados
const showCancelModal = ref(false)
const showRescheduleModal = ref(false)
const showPaymentModal = ref(false)
const isProcessing = ref(false)
const actionError = ref('')

// Datos de reprogramación
const newDate = ref('')
const newTime = ref('')
const newHours = ref(1)

// Datos de pago
const selectedPaymentMethod = ref<PaymentMethod>('cash')

// Utilidades
const formatDate = (dateString: string) => {
  return new Date(dateString).toLocaleDateString('es-HN', {
    weekday: 'long',
    year: 'numeric',
    month: 'long',
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

const getStatusColor = (status: string) => {
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

const getStatusIcon = (status: string) => {
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

const getStatusLabel = (status: string) => {
  switch (status) {
    case 'confirmed':
      return 'Confirmada'
    case 'pending':
      return 'Pendiente de confirmación'
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
      return 'Tarjeta de crédito/débito'
    case 'transfer':
      return 'Transferencia bancaria'
    default:
      return 'No especificado'
  }
}

const canCancel = computed(() => {
  if (!booking.value) return false
  return booking.value.status !== 'cancelled' && new Date(booking.value.startTime) > new Date()
})

const canReschedule = computed(() => {
  if (!booking.value) return false
  return booking.value.status !== 'cancelled' && new Date(booking.value.startTime) > new Date()
})

const canPay = computed(() => {
  if (!booking.value) return false
  return booking.value.paymentStatus === 'pending' && booking.value.status !== 'cancelled'
})

const isUpcoming = computed(() => {
  if (!booking.value) return false
  return new Date(booking.value.startTime) > new Date()
})

// Acciones
const handleCancel = async () => {
  if (!booking.value) return

  isProcessing.value = true
  actionError.value = ''

  try {
    await BookingsService.cancel(booking.value._id)
    await refresh()
    showCancelModal.value = false
  } catch (error: any) {
    console.error('Error al cancelar reserva:', error)
    actionError.value = error?.data?.message || 'Error al cancelar la reserva'
  } finally {
    isProcessing.value = false
  }
}

const handleReschedule = async () => {
  if (!booking.value || !newDate.value || !newTime.value) {
    actionError.value = 'Por favor completa todos los campos'
    return
  }

  isProcessing.value = true
  actionError.value = ''

  try {
    const start = new Date(`${newDate.value}T${newTime.value}`)
    const end = new Date(start.getTime() + newHours.value * 60 * 60 * 1000)

    const newBookingData = {
      spaceId: booking.value.spaceId,
      startTime: start.toISOString(),
      endTime: end.toISOString(),
      paymentMethod: booking.value.paymentMethod,
      paymentStatus: booking.value.paymentStatus,
      totalAmount: booking.value.totalAmount,
      subtotal: booking.value.subtotal,
      serviceFee: booking.value.serviceFee,
      pricePerHour: booking.value.pricePerHour,
      durationHours: newHours.value
    }

    const newBooking = await BookingsService.create(newBookingData)
    
    // Opcional: cancelar la reserva anterior
    if (confirm('Reprogramación creada. ¿Deseas cancelar la reserva anterior?')) {
      await BookingsService.cancel(booking.value._id)
    }

    // Redirigir a la nueva reserva
    router.push(`/bookings/${newBooking._id}`)
  } catch (error: any) {
    console.error('Error al reprogramar reserva:', error)
    actionError.value = error?.data?.message || 'Error al reprogramar la reserva'
  } finally {
    isProcessing.value = false
  }
}

const handlePayment = async () => {
  if (!booking.value) return

  isProcessing.value = true
  actionError.value = ''

  try {
    const updatedBooking = await BookingsService.updatePayment(booking.value._id, {
      paymentMethod: selectedPaymentMethod.value,
      paymentStatus: 'paid'
    })
    
    await refresh()
    showPaymentModal.value = false
    
    alert('¡Pago procesado exitosamente! (Simulado)')
  } catch (error: any) {
    console.error('Error al procesar pago:', error)
    actionError.value = error?.data?.message || 'Error al procesar el pago'
  } finally {
    isProcessing.value = false
  }
}

const goBack = () => {
  router.push('/bookings')
}

const viewSpace = () => {
  if (booking.value?.spaceId) {
    router.push(`/spaces/${booking.value.spaceId}`)
  }
}
</script>

<template>
  <div class="min-h-screen bg-gray-50">
    <div class="px-4 sm:px-6 lg:px-8 py-8 max-w-5xl mx-auto">
      <!-- Header -->
      <div class="mb-6">
        <button
          type="button"
          class="inline-flex items-center gap-2 text-gray-600 hover:text-gray-900 mb-4 transition"
          @click="goBack"
        >
          <span class="material-symbols-outlined">arrow_back</span>
          <span class="font-semibold">Volver a mis reservas</span>
        </button>
        <h1 class="text-3xl font-black text-gray-900">Detalle de Reserva</h1>
      </div>

      <!-- Loading -->
      <div v-if="pending" class="bg-white rounded-xl p-8 shadow-sm border border-gray-200 animate-pulse">
        <div class="space-y-4">
          <div class="h-8 w-1/3 bg-gray-200 rounded"></div>
          <div class="h-4 w-1/2 bg-gray-200 rounded"></div>
          <div class="h-4 w-2/3 bg-gray-200 rounded"></div>
        </div>
      </div>

      <!-- Error -->
      <div v-else-if="error || !booking" class="bg-red-50 border border-red-200 rounded-xl p-6">
        <div class="flex items-start gap-3">
          <span class="material-symbols-outlined text-red-600">error</span>
          <div>
            <h3 class="font-semibold text-red-900 mb-1">Reserva no encontrada</h3>
            <p class="text-sm text-red-800">La reserva que buscas no existe o no tienes acceso a ella.</p>
          </div>
        </div>
      </div>

      <!-- Content -->
      <div v-else class="space-y-6">
        <!-- Status Banner -->
        <div
          class="rounded-xl p-6 border-2"
          :class="booking.status === 'confirmed' 
            ? 'bg-green-50 border-green-200' 
            : booking.status === 'pending' 
              ? 'bg-yellow-50 border-yellow-200' 
              : 'bg-red-50 border-red-200'"
        >
          <div class="flex items-center gap-3">
            <span
              class="material-symbols-outlined text-4xl"
              :class="booking.status === 'confirmed' 
                ? 'text-green-600' 
                : booking.status === 'pending' 
                  ? 'text-yellow-600' 
                  : 'text-red-600'"
            >
              {{ getStatusIcon(booking.status) }}
            </span>
            <div class="flex-1">
              <h2 class="text-xl font-bold" :class="booking.status === 'confirmed' 
                ? 'text-green-900' 
                : booking.status === 'pending' 
                  ? 'text-yellow-900' 
                  : 'text-red-900'">
                {{ getStatusLabel(booking.status) }}
              </h2>
              <p class="text-sm" :class="booking.status === 'confirmed' 
                ? 'text-green-700' 
                : booking.status === 'pending' 
                  ? 'text-yellow-700' 
                  : 'text-red-700'">
                {{ booking.status === 'confirmed' 
                  ? 'Tu reserva ha sido confirmada por el propietario' 
                  : booking.status === 'pending' 
                    ? 'El propietario está revisando tu solicitud de reserva' 
                    : 'Esta reserva ha sido cancelada' 
                }}
              </p>
            </div>
          </div>
        </div>

        <!-- Main Info -->
        <div class="bg-white rounded-xl p-6 shadow-sm border border-gray-200">
          <div class="flex items-start justify-between mb-6">
            <div class="flex-1">
              <h2 class="text-2xl font-bold text-gray-900 mb-2">{{ booking.space?.name || 'Espacio no disponible' }}</h2>
              <p class="text-gray-600 flex items-center gap-1">
                <span class="material-symbols-outlined !text-[18px]">location_on</span>
                {{ booking.space?.address || 'Dirección no disponible' }}
              </p>
            </div>
            <button
              v-if="booking.space"
              type="button"
              class="px-4 py-2 rounded-lg bg-primary/10 text-primary text-sm font-semibold hover:bg-primary/20 transition flex items-center gap-1"
              @click="viewSpace"
            >
              <span class="material-symbols-outlined !text-[18px]">visibility</span>
              Ver espacio
            </button>
          </div>

          <!-- Date & Time -->
          <div class="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6 p-4 bg-gray-50 rounded-xl">
            <div>
              <p class="text-sm text-gray-600 mb-1 flex items-center gap-1">
                <span class="material-symbols-outlined !text-[16px]">event</span>
                Fecha
              </p>
              <p class="text-lg font-bold text-gray-900">{{ formatDate(booking.startTime) }}</p>
            </div>
            <div>
              <p class="text-sm text-gray-600 mb-1 flex items-center gap-1">
                <span class="material-symbols-outlined !text-[16px]">schedule</span>
                Horario
              </p>
              <p class="text-lg font-bold text-gray-900">
                {{ formatTime(booking.startTime) }} - {{ formatTime(booking.endTime) }}
              </p>
              <p class="text-sm text-gray-600">{{ booking.durationHours || 1 }} {{ (booking.durationHours || 1) === 1 ? 'hora' : 'horas' }}</p>
            </div>
          </div>

          <!-- Actions -->
          <div v-if="isUpcoming" class="flex flex-wrap gap-3">
            <button
              v-if="canReschedule"
              type="button"
              class="flex-1 min-w-[200px] px-6 py-3 rounded-lg bg-blue-600 text-white font-semibold hover:bg-blue-700 transition flex items-center justify-center gap-2"
              @click="showRescheduleModal = true"
            >
              <span class="material-symbols-outlined">event_repeat</span>
              Reprogramar
            </button>
            <button
              v-if="canPay"
              type="button"
              class="flex-1 min-w-[200px] px-6 py-3 rounded-lg bg-green-600 text-white font-semibold hover:bg-green-700 transition flex items-center justify-center gap-2"
              @click="showPaymentModal = true"
            >
              <span class="material-symbols-outlined">payments</span>
              Pagar ahora
            </button>
            <button
              v-if="canCancel"
              type="button"
              class="flex-1 min-w-[200px] px-6 py-3 rounded-lg bg-red-600 text-white font-semibold hover:bg-red-700 transition flex items-center justify-center gap-2"
              @click="showCancelModal = true"
            >
              <span class="material-symbols-outlined">cancel</span>
              Cancelar reserva
            </button>
          </div>
        </div>

        <!-- Payment Info -->
        <div class="bg-white rounded-xl p-6 shadow-sm border border-gray-200">
          <h3 class="text-lg font-bold text-gray-900 mb-4 flex items-center gap-2">
            <span class="material-symbols-outlined text-primary">receipt</span>
            Información de Pago
          </h3>

          <div class="space-y-4">
            <!-- Payment breakdown -->
            <div class="space-y-2">
              <div class="flex justify-between text-gray-700">
                <span>Precio por hora</span>
                <span class="font-semibold">{{ formatCurrency(booking.pricePerHour) }}</span>
              </div>
              <div class="flex justify-between text-gray-700">
                <span>Duración ({{ booking.durationHours || 1 }} {{ (booking.durationHours || 1) === 1 ? 'hora' : 'horas' }})</span>
                <span class="font-semibold">{{ formatCurrency(booking.subtotal) }}</span>
              </div>
              <div class="flex justify-between text-gray-700">
                <span>Tarifa de servicio (8%)</span>
                <span class="font-semibold">{{ formatCurrency(booking.serviceFee) }}</span>
              </div>
              <div class="flex justify-between text-xl font-bold text-gray-900 border-t-2 border-gray-200 pt-2">
                <span>Total</span>
                <span class="text-primary">{{ formatCurrency(booking.totalAmount) }}</span>
              </div>
            </div>

            <!-- Payment status -->
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4 p-4 bg-gray-50 rounded-xl">
              <div>
                <p class="text-sm text-gray-600 mb-1">Estado del pago</p>
                <p class="font-bold" :class="booking.paymentStatus === 'paid' ? 'text-green-600' : 'text-yellow-600'">
                  {{ getPaymentStatusLabel(booking.paymentStatus) }}
                </p>
              </div>
              <div>
                <p class="text-sm text-gray-600 mb-1">Método de pago</p>
                <p class="font-bold text-gray-900">{{ getPaymentMethodLabel(booking.paymentMethod) }}</p>
              </div>
            </div>

            <!-- Payment note -->
            <div v-if="booking.paymentStatus === 'pending'" class="flex items-start gap-2 p-3 bg-yellow-50 border border-yellow-200 rounded-lg">
              <span class="material-symbols-outlined text-yellow-600 !text-[20px]">info</span>
              <p class="text-sm text-yellow-800">
                <strong>Recuerda:</strong> Debes completar el pago antes del día de tu reserva para garantizar tu espacio.
              </p>
            </div>

            <div v-if="booking.paymentStatus === 'paid' && booking.paidAt" class="flex items-start gap-2 p-3 bg-green-50 border border-green-200 rounded-lg">
              <span class="material-symbols-outlined text-green-600 !text-[20px]">check_circle</span>
              <p class="text-sm text-green-800">
                <strong>Pago completado</strong> el {{ new Date(booking.paidAt).toLocaleDateString('es-HN', { year: 'numeric', month: 'long', day: 'numeric' }) }}
              </p>
            </div>
          </div>
        </div>

        <!-- Space Details -->
        <div v-if="booking.space" class="bg-white rounded-xl p-6 shadow-sm border border-gray-200">
          <h3 class="text-lg font-bold text-gray-900 mb-4 flex items-center gap-2">
            <span class="material-symbols-outlined text-primary">home_work</span>
            Detalles del Espacio
          </h3>

          <div class="grid grid-cols-2 md:grid-cols-3 gap-4">
            <div class="flex items-center gap-2">
              <span class="material-symbols-outlined text-primary">groups</span>
              <div>
                <p class="text-sm text-gray-600">Capacidad</p>
                <p class="font-bold text-gray-900">{{ booking.space.capacity }} personas</p>
              </div>
            </div>

            <div class="flex items-center gap-2">
              <span class="material-symbols-outlined text-primary">square_foot</span>
              <div>
                <p class="text-sm text-gray-600">Área</p>
                <p class="font-bold text-gray-900">{{ booking.space.size }} m²</p>
              </div>
            </div>

            <div class="flex items-center gap-2">
              <span class="material-symbols-outlined text-primary">star</span>
              <div>
                <p class="text-sm text-gray-600">Tipo</p>
                <p class="font-bold text-gray-900">{{ booking.space.type || 'Espacio' }}</p>
              </div>
            </div>
          </div>

          <div v-if="booking.space.description" class="mt-4 pt-4 border-t border-gray-200">
            <p class="text-gray-700">{{ booking.space.description }}</p>
          </div>
        </div>

        <!-- Booking Info -->
        <div class="bg-white rounded-xl p-6 shadow-sm border border-gray-200">
          <h3 class="text-lg font-bold text-gray-900 mb-4 flex items-center gap-2">
            <span class="material-symbols-outlined text-primary">info</span>
            Información de la Reserva
          </h3>

          <div class="space-y-2 text-sm">
            <div class="flex justify-between">
              <span class="text-gray-600">ID de reserva</span>
              <span class="font-mono font-semibold text-gray-900">{{ booking._id }}</span>
            </div>
            <div class="flex justify-between">
              <span class="text-gray-600">Fecha de creación</span>
              <span class="font-semibold text-gray-900">
                {{ new Date(booking.createdAt).toLocaleString('es-HN', { 
                  year: 'numeric', 
                  month: 'long', 
                  day: 'numeric',
                  hour: '2-digit',
                  minute: '2-digit'
                }) }}
              </span>
            </div>
            <div v-if="booking.updatedAt !== booking.createdAt" class="flex justify-between">
              <span class="text-gray-600">Última actualización</span>
              <span class="font-semibold text-gray-900">
                {{ new Date(booking.updatedAt).toLocaleString('es-HN', { 
                  year: 'numeric', 
                  month: 'long', 
                  day: 'numeric',
                  hour: '2-digit',
                  minute: '2-digit'
                }) }}
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Modal: Cancelar -->
    <Teleport to="body">
      <Transition name="modal">
        <div
          v-if="showCancelModal"
          class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm"
          @click.self="showCancelModal = false"
        >
          <div class="bg-white rounded-2xl max-w-md w-full shadow-2xl">
            <div class="p-6">
              <div class="flex items-center gap-3 mb-4">
                <div class="h-12 w-12 rounded-full bg-red-100 flex items-center justify-center">
                  <span class="material-symbols-outlined text-red-600 text-2xl">cancel</span>
                </div>
                <h3 class="text-xl font-bold text-gray-900">Cancelar Reserva</h3>
              </div>

              <p class="text-gray-600 mb-6">
                ¿Estás seguro de que deseas cancelar esta reserva? Esta acción no se puede deshacer.
              </p>

              <div v-if="actionError" class="mb-4 p-3 bg-red-50 border border-red-200 rounded-lg text-sm text-red-800">
                {{ actionError }}
              </div>

              <div class="flex gap-3">
                <button
                  type="button"
                  class="flex-1 px-6 py-3 rounded-lg border-2 border-gray-300 font-semibold text-gray-700 hover:bg-gray-50 transition"
                  :disabled="isProcessing"
                  @click="showCancelModal = false"
                >
                  No, mantener
                </button>
                <button
                  type="button"
                  class="flex-1 px-6 py-3 rounded-lg bg-red-600 font-semibold text-white hover:bg-red-700 transition disabled:opacity-50"
                  :disabled="isProcessing"
                  @click="handleCancel"
                >
                  {{ isProcessing ? 'Cancelando...' : 'Sí, cancelar' }}
                </button>
              </div>
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>

    <!-- Modal: Reprogramar -->
    <Teleport to="body">
      <Transition name="modal">
        <div
          v-if="showRescheduleModal"
          class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm"
          @click.self="showRescheduleModal = false"
        >
          <div class="bg-white rounded-2xl max-w-lg w-full shadow-2xl max-h-[90vh] overflow-y-auto">
            <div class="sticky top-0 bg-white border-b border-gray-200 px-6 py-4 flex items-center justify-between">
              <h3 class="text-xl font-bold text-gray-900">Reprogramar Reserva</h3>
              <button
                type="button"
                class="text-gray-400 hover:text-gray-600 transition"
                :disabled="isProcessing"
                @click="showRescheduleModal = false"
              >
                <span class="material-symbols-outlined">close</span>
              </button>
            </div>

            <div class="p-6 space-y-6">
              <div class="bg-blue-50 border border-blue-200 rounded-lg p-4">
                <p class="text-sm text-blue-800">
                  <strong>Nota:</strong> Se creará una nueva reserva con la fecha y hora seleccionadas. Podrás cancelar la reserva anterior si lo deseas.
                </p>
              </div>

              <!-- Nueva fecha -->
              <div>
                <label class="block text-sm font-semibold text-gray-700 mb-2">Nueva fecha</label>
                <input
                  v-model="newDate"
                  type="date"
                  :min="new Date().toISOString().split('T')[0]"
                  class="w-full rounded-lg border-2 border-gray-300 px-4 py-3 focus:border-primary focus:ring-4 focus:ring-primary/10"
                />
              </div>

              <!-- Nueva hora -->
              <div>
                <label class="block text-sm font-semibold text-gray-700 mb-2">Nueva hora</label>
                <input
                  v-model="newTime"
                  type="time"
                  class="w-full rounded-lg border-2 border-gray-300 px-4 py-3 focus:border-primary focus:ring-4 focus:ring-primary/10"
                />
              </div>

              <!-- Duración -->
              <div>
                <label class="block text-sm font-semibold text-gray-700 mb-2">Duración (horas)</label>
                <input
                  v-model.number="newHours"
                  type="number"
                  min="1"
                  max="24"
                  class="w-full rounded-lg border-2 border-gray-300 px-4 py-3 focus:border-primary focus:ring-4 focus:ring-primary/10"
                />
              </div>

              <div v-if="actionError" class="p-3 bg-red-50 border border-red-200 rounded-lg text-sm text-red-800">
                {{ actionError }}
              </div>

              <div class="flex gap-3">
                <button
                  type="button"
                  class="flex-1 px-6 py-3 rounded-lg border-2 border-gray-300 font-semibold text-gray-700 hover:bg-gray-50 transition"
                  :disabled="isProcessing"
                  @click="showRescheduleModal = false"
                >
                  Cancelar
                </button>
                <button
                  type="button"
                  class="flex-1 px-6 py-3 rounded-lg bg-primary font-semibold text-white hover:bg-primary/90 transition disabled:opacity-50"
                  :disabled="isProcessing || !newDate || !newTime"
                  @click="handleReschedule"
                >
                  {{ isProcessing ? 'Procesando...' : 'Reprogramar' }}
                </button>
              </div>
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>

    <!-- Modal: Pagar -->
    <Teleport to="body">
      <Transition name="modal">
        <div
          v-if="showPaymentModal"
          class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm"
          @click.self="showPaymentModal = false"
        >
          <div class="bg-white rounded-2xl max-w-md w-full shadow-2xl">
            <div class="sticky top-0 bg-white border-b border-gray-200 px-6 py-4 flex items-center justify-between">
              <h3 class="text-xl font-bold text-gray-900">Procesar Pago</h3>
              <button
                type="button"
                class="text-gray-400 hover:text-gray-600 transition"
                :disabled="isProcessing"
                @click="showPaymentModal = false"
              >
                <span class="material-symbols-outlined">close</span>
              </button>
            </div>

            <div class="p-6 space-y-6">
              <div class="bg-yellow-50 border border-yellow-200 rounded-lg p-4">
                <p class="text-sm text-yellow-800">
                  <strong>Simulación de pago:</strong> El proceso de pago es simulado para propósitos de demostración.
                </p>
              </div>

              <!-- Total a pagar -->
              <div class="text-center p-6 bg-gradient-to-br from-primary/5 to-blue-50 rounded-xl border-2 border-primary/20">
                <p class="text-sm text-gray-600 mb-2">Total a pagar</p>
                <p class="text-4xl font-black text-primary">{{ formatCurrency(booking?.totalAmount) }}</p>
              </div>

              <!-- Método de pago -->
              <div>
                <label class="block text-sm font-semibold text-gray-700 mb-3">Método de pago</label>
                <div class="grid grid-cols-3 gap-3">
                  <button
                    type="button"
                    class="flex flex-col items-center gap-2 p-4 rounded-xl border-2 transition"
                    :class="selectedPaymentMethod === 'cash' 
                      ? 'border-primary bg-primary/5' 
                      : 'border-gray-200 hover:border-gray-300'"
                    @click="selectedPaymentMethod = 'cash'"
                  >
                    <span class="material-symbols-outlined text-2xl" :class="selectedPaymentMethod === 'cash' ? 'text-primary' : 'text-gray-400'">
                      payments
                    </span>
                    <span class="text-xs font-semibold" :class="selectedPaymentMethod === 'cash' ? 'text-gray-900' : 'text-gray-600'">
                      Efectivo
                    </span>
                  </button>

                  <button
                    type="button"
                    class="flex flex-col items-center gap-2 p-4 rounded-xl border-2 transition"
                    :class="selectedPaymentMethod === 'card' 
                      ? 'border-primary bg-primary/5' 
                      : 'border-gray-200 hover:border-gray-300'"
                    @click="selectedPaymentMethod = 'card'"
                  >
                    <span class="material-symbols-outlined text-2xl" :class="selectedPaymentMethod === 'card' ? 'text-primary' : 'text-gray-400'">
                      credit_card
                    </span>
                    <span class="text-xs font-semibold" :class="selectedPaymentMethod === 'card' ? 'text-gray-900' : 'text-gray-600'">
                      Tarjeta
                    </span>
                  </button>

                  <button
                    type="button"
                    class="flex flex-col items-center gap-2 p-4 rounded-xl border-2 transition"
                    :class="selectedPaymentMethod === 'transfer' 
                      ? 'border-primary bg-primary/5' 
                      : 'border-gray-200 hover:border-gray-300'"
                    @click="selectedPaymentMethod = 'transfer'"
                  >
                    <span class="material-symbols-outlined text-2xl" :class="selectedPaymentMethod === 'transfer' ? 'text-primary' : 'text-gray-400'">
                      account_balance
                    </span>
                    <span class="text-xs font-semibold" :class="selectedPaymentMethod === 'transfer' ? 'text-gray-900' : 'text-gray-600'">
                      Transfer.
                    </span>
                  </button>
                </div>
              </div>

              <div v-if="actionError" class="p-3 bg-red-50 border border-red-200 rounded-lg text-sm text-red-800">
                {{ actionError }}
              </div>

              <div class="flex gap-3">
                <button
                  type="button"
                  class="flex-1 px-6 py-3 rounded-lg border-2 border-gray-300 font-semibold text-gray-700 hover:bg-gray-50 transition"
                  :disabled="isProcessing"
                  @click="showPaymentModal = false"
                >
                  Cancelar
                </button>
                <button
                  type="button"
                  class="flex-1 px-6 py-3 rounded-lg bg-green-600 font-semibold text-white hover:bg-green-700 transition disabled:opacity-50"
                  :disabled="isProcessing"
                  @click="handlePayment"
                >
                  {{ isProcessing ? 'Procesando...' : 'Pagar ahora' }}
                </button>
              </div>
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>
  </div>
</template>

<style scoped>
.modal-enter-active,
.modal-leave-active {
  transition: opacity 0.3s ease;
}

.modal-enter-from,
.modal-leave-to {
  opacity: 0;
}

.modal-enter-active > div,
.modal-leave-active > div {
  transition: transform 0.3s ease;
}

.modal-enter-from > div,
.modal-leave-to > div {
  transform: scale(0.9);
}
</style>
