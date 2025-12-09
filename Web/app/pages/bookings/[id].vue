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
const showTransferModal = ref(false)
const isProcessing = ref(false)
const actionError = ref('')
const uploadSuccess = ref('')

// Datos de reprogramación
const newDate = ref('')
const newTime = ref('')
const newHours = ref(1)

// Datos de pago
const selectedPaymentMethod = ref<PaymentMethod>('cash')

// Datos de transferencia
const transferProofFile = ref<File | null>(null)
const transferProofPreview = ref<string | null>(null)

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

const getStatusConfig = (status: string) => {
  switch (status) {
    case 'confirmed':
      return {
        bg: 'bg-gradient-to-r from-emerald-500 to-emerald-600',
        bgLight: 'bg-emerald-50',
        text: 'text-emerald-700',
        border: 'ring-emerald-600/20',
        icon: 'check_circle',
        label: 'Confirmada',
        description: 'Tu reserva ha sido confirmada por el propietario'
      }
    case 'pending':
      return {
        bg: 'bg-gradient-to-r from-amber-400 to-amber-500',
        bgLight: 'bg-amber-50',
        text: 'text-amber-700',
        border: 'ring-amber-600/20',
        icon: 'schedule',
        label: 'Pendiente de confirmación',
        description: 'El propietario está revisando tu solicitud de reserva'
      }
    case 'cancelled':
      return {
        bg: 'bg-gradient-to-r from-rose-500 to-rose-600',
        bgLight: 'bg-rose-50',
        text: 'text-rose-700',
        border: 'ring-rose-600/20',
        icon: 'cancel',
        label: 'Cancelada',
        description: 'Esta reserva ha sido cancelada'
      }
    default:
      return {
        bg: 'bg-gradient-to-r from-gray-400 to-gray-500',
        bgLight: 'bg-gray-50',
        text: 'text-gray-700',
        border: 'ring-gray-600/20',
        icon: 'help',
        label: status,
        description: ''
      }
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

// Estado de transferencia
const transferStatus = computed(() => {
  if (!booking.value) return null
  if (booking.value.paymentMethod !== 'transfer') return null
  
  if (booking.value.paymentStatus === 'paid') return 'verified'
  if (booking.value.transferRejectedAt) return 'rejected'
  if (booking.value.transferProofUrl) return 'pending_verification'
  return 'awaiting_proof'
})

const canUploadProof = computed(() => {
  if (!booking.value) return false
  return booking.value.paymentMethod === 'transfer' && 
         booking.value.paymentStatus === 'pending' &&
         booking.value.status !== 'cancelled' &&
         (!booking.value.transferProofUrl || booking.value.transferRejectedAt)
})

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

  // Si es transferencia, abrir el modal de transferencia
  if (selectedPaymentMethod.value === 'transfer') {
    showPaymentModal.value = false
    showTransferModal.value = true
    return
  }

  // Para efectivo o tarjeta (simulado), actualizar directamente
  isProcessing.value = true
  actionError.value = ''

  try {
    const updatedBooking = await BookingsService.updatePayment(booking.value._id, {
      paymentMethod: selectedPaymentMethod.value,
      paymentStatus: selectedPaymentMethod.value === 'cash' ? 'pending' : 'paid'
    })
    
    await refresh()
    showPaymentModal.value = false
    
    if (selectedPaymentMethod.value === 'cash') {
      alert('Has seleccionado pago en efectivo. Deberás pagar al propietario el día de tu reserva.')
    } else {
      alert('¡Pago procesado exitosamente! (Simulado)')
    }
  } catch (error: any) {
    console.error('Error al procesar pago:', error)
    actionError.value = error?.data?.message || 'Error al procesar el pago'
  } finally {
    isProcessing.value = false
  }
}

// Manejar selección de archivo de comprobante
const handleFileSelect = (event: Event) => {
  const target = event.target as HTMLInputElement
  const file = target.files?.[0]
  
  if (file) {
    // Validar tipo de archivo
    if (!file.type.startsWith('image/')) {
      actionError.value = 'Por favor selecciona una imagen válida'
      return
    }
    
    // Validar tamaño (max 5MB)
    if (file.size > 5 * 1024 * 1024) {
      actionError.value = 'La imagen no debe superar los 5MB'
      return
    }
    
    transferProofFile.value = file
    actionError.value = ''
    
    // Crear preview
    const reader = new FileReader()
    reader.onload = (e) => {
      transferProofPreview.value = e.target?.result as string
    }
    reader.readAsDataURL(file)
  }
}

// Subir comprobante de transferencia
const handleUploadProof = async () => {
  if (!booking.value || !transferProofFile.value) {
    actionError.value = 'Por favor selecciona una imagen del comprobante'
    return
  }

  isProcessing.value = true
  actionError.value = ''
  uploadSuccess.value = ''

  try {
    await BookingsService.uploadTransferProof(booking.value._id, transferProofFile.value)
    
    await refresh()
    showTransferModal.value = false
    transferProofFile.value = null
    transferProofPreview.value = null
    uploadSuccess.value = '¡Comprobante subido exitosamente! El propietario lo revisará pronto.'
    
    // Limpiar mensaje de éxito después de 5 segundos
    setTimeout(() => {
      uploadSuccess.value = ''
    }, 5000)
  } catch (error: any) {
    console.error('Error al subir comprobante:', error)
    actionError.value = error?.data?.message || 'Error al subir el comprobante'
  } finally {
    isProcessing.value = false
  }
}

// Cerrar modal de transferencia
const closeTransferModal = () => {
  showTransferModal.value = false
  transferProofFile.value = null
  transferProofPreview.value = null
  actionError.value = ''
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
  <div class="min-h-screen bg-gradient-to-br from-slate-50 via-white to-blue-50/30">
    <!-- Hero Header con gradiente dinámico basado en status -->
    <div 
      class="relative overflow-hidden"
      :class="booking ? getStatusConfig(booking.status).bg : 'bg-gradient-to-r from-primary via-primary-dark to-blue-900'"
    >
      <!-- Patrón decorativo -->
      <div class="absolute inset-0 opacity-10">
        <div class="absolute -left-20 -top-20 h-80 w-80 rounded-full bg-white/20 blur-3xl" />
        <div class="absolute -bottom-20 right-10 h-96 w-96 rounded-full bg-white/10 blur-3xl" />
      </div>
      
      <div class="relative px-4 sm:px-6 lg:px-8 py-8 max-w-5xl mx-auto">
        <!-- Back button -->
        <button
          type="button"
          class="inline-flex items-center gap-2 text-white/80 hover:text-white mb-6 transition-colors"
          @click="goBack"
        >
          <span class="material-symbols-outlined">arrow_back</span>
          <span class="font-medium">Volver a mis reservas</span>
        </button>
        
        <div class="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
          <div>
            <div class="flex items-center gap-3 mb-3">
              <div class="flex h-14 w-14 items-center justify-center rounded-2xl bg-white/20 backdrop-blur-sm">
                <span class="material-symbols-outlined text-3xl text-white">
                  {{ booking ? getStatusConfig(booking.status).icon : 'calendar_month' }}
                </span>
              </div>
              <div>
                <h1 class="text-2xl font-bold text-white">Detalle de Reserva</h1>
                <p v-if="booking" class="text-white/70">
                  {{ getStatusConfig(booking.status).label }}
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <div class="px-4 sm:px-6 lg:px-8 py-8 max-w-5xl mx-auto -mt-6">
      <!-- Loading -->
      <div v-if="pending" class="bg-white rounded-2xl p-8 shadow-sm ring-1 ring-black/5 animate-pulse">
        <div class="space-y-4">
          <div class="h-8 w-1/3 bg-gray-200 rounded-lg"></div>
          <div class="h-4 w-1/2 bg-gray-200 rounded-lg"></div>
          <div class="h-4 w-2/3 bg-gray-200 rounded-lg"></div>
        </div>
      </div>

      <!-- Error -->
      <div v-else-if="error || !booking" class="bg-white rounded-2xl p-8 shadow-sm ring-1 ring-rose-200">
        <div class="flex items-start gap-4">
          <div class="flex h-14 w-14 items-center justify-center rounded-2xl bg-rose-100">
            <span class="material-symbols-outlined text-2xl text-rose-600">error</span>
          </div>
          <div>
            <h3 class="text-lg font-bold text-gray-900 mb-1">Reserva no encontrada</h3>
            <p class="text-gray-600">La reserva que buscas no existe o no tienes acceso a ella.</p>
          </div>
        </div>
      </div>

      <!-- Content -->
      <div v-else class="space-y-6">
        <!-- Status Banner Card -->
        <div 
          class="bg-white rounded-2xl p-6 shadow-sm ring-1 ring-black/5"
          :class="getStatusConfig(booking.status).bgLight"
        >
          <div class="flex items-center gap-4">
            <div 
              class="flex h-16 w-16 items-center justify-center rounded-2xl shadow-lg"
              :class="getStatusConfig(booking.status).bg"
            >
              <span class="material-symbols-outlined text-3xl text-white">
                {{ getStatusConfig(booking.status).icon }}
              </span>
            </div>
            <div class="flex-1">
              <h2 class="text-xl font-bold text-gray-900">
                {{ getStatusConfig(booking.status).label }}
              </h2>
              <p class="text-gray-600">
                {{ getStatusConfig(booking.status).description }}
              </p>
            </div>
          </div>
        </div>

        <!-- Main Info Card -->
        <div class="bg-white rounded-2xl p-6 shadow-sm ring-1 ring-black/5">
          <div class="flex items-start justify-between mb-6">
            <div class="flex-1">
              <h2 class="text-2xl font-bold text-gray-900 mb-2">{{ booking.space?.name || 'Espacio no disponible' }}</h2>
              <p class="text-gray-500 flex items-center gap-1.5">
                <span class="material-symbols-outlined !text-[18px]">location_on</span>
                {{ booking.space?.address || 'Dirección no disponible' }}
              </p>
            </div>
            <button
              v-if="booking.space"
              type="button"
              class="px-4 py-2.5 rounded-xl bg-primary/10 text-primary text-sm font-semibold hover:bg-primary/20 transition-all flex items-center gap-2"
              @click="viewSpace"
            >
              <span class="material-symbols-outlined !text-[18px]">visibility</span>
              Ver espacio
            </button>
          </div>

          <!-- Date & Time Grid -->
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-6">
            <div class="flex items-center gap-4 p-4 rounded-xl bg-gray-50">
              <div class="flex h-12 w-12 items-center justify-center rounded-xl bg-gradient-to-br from-primary to-primary-dark">
                <span class="material-symbols-outlined text-white">event</span>
              </div>
              <div>
                <p class="text-xs font-medium text-gray-500 uppercase tracking-wide">Fecha</p>
                <p class="text-lg font-bold text-gray-900">{{ formatDate(booking.startTime) }}</p>
              </div>
            </div>
            <div class="flex items-center gap-4 p-4 rounded-xl bg-gray-50">
              <div class="flex h-12 w-12 items-center justify-center rounded-xl bg-gradient-to-br from-primary to-primary-dark">
                <span class="material-symbols-outlined text-white">schedule</span>
              </div>
              <div>
                <p class="text-xs font-medium text-gray-500 uppercase tracking-wide">Horario</p>
                <p class="text-lg font-bold text-gray-900">
                  {{ formatTime(booking.startTime) }} - {{ formatTime(booking.endTime) }}
                </p>
                <p class="text-sm text-gray-500">{{ booking.durationHours || 1 }} {{ (booking.durationHours || 1) === 1 ? 'hora' : 'horas' }}</p>
              </div>
            </div>
          </div>

          <!-- Actions -->
          <div v-if="isUpcoming" class="flex flex-wrap gap-3 pt-4 border-t border-gray-100">
            <button
              v-if="canReschedule"
              type="button"
              class="flex-1 min-w-[180px] px-6 py-3 rounded-xl bg-gradient-to-r from-blue-500 to-blue-600 text-white font-semibold shadow-lg shadow-blue-500/25 hover:shadow-xl hover:shadow-blue-500/30 transition-all flex items-center justify-center gap-2"
              @click="showRescheduleModal = true"
            >
              <span class="material-symbols-outlined">event_repeat</span>
              Reprogramar
            </button>
            <button
              v-if="canPay"
              type="button"
              class="flex-1 min-w-[180px] px-6 py-3 rounded-xl bg-gradient-to-r from-emerald-500 to-emerald-600 text-white font-semibold shadow-lg shadow-emerald-500/25 hover:shadow-xl hover:shadow-emerald-500/30 transition-all flex items-center justify-center gap-2"
              @click="showPaymentModal = true"
            >
              <span class="material-symbols-outlined">payments</span>
              Pagar ahora
            </button>
            <button
              v-if="canCancel"
              type="button"
              class="flex-1 min-w-[180px] px-6 py-3 rounded-xl bg-rose-50 text-rose-700 font-semibold ring-1 ring-rose-200 hover:bg-rose-100 transition-all flex items-center justify-center gap-2"
              @click="showCancelModal = true"
            >
              <span class="material-symbols-outlined">cancel</span>
              Cancelar reserva
            </button>
          </div>
        </div>

        <!-- Payment Info Card -->
        <div class="bg-white rounded-2xl p-6 shadow-sm ring-1 ring-black/5">
          <div class="flex items-center gap-3 mb-6">
            <div class="flex h-10 w-10 items-center justify-center rounded-xl bg-gradient-to-br from-primary to-primary-dark">
              <span class="material-symbols-outlined text-white">receipt</span>
            </div>
            <h3 class="text-lg font-bold text-gray-900">Información de Pago</h3>
          </div>

          <div class="space-y-4">
            <!-- Payment breakdown -->
            <div class="space-y-3 p-4 rounded-xl bg-gray-50">
              <div class="flex justify-between text-gray-600">
                <span>Precio por hora</span>
                <span class="font-semibold text-gray-900">{{ formatCurrency(booking.pricePerHour) }}</span>
              </div>
              <div class="flex justify-between text-gray-600">
                <span>Duración ({{ booking.durationHours || 1 }} {{ (booking.durationHours || 1) === 1 ? 'hora' : 'horas' }})</span>
                <span class="font-semibold text-gray-900">{{ formatCurrency(booking.subtotal) }}</span>
              </div>
              <div class="flex justify-between text-gray-600">
                <span>Tarifa de servicio (8%)</span>
                <span class="font-semibold text-gray-900">{{ formatCurrency(booking.serviceFee) }}</span>
              </div>
              <div class="flex justify-between text-xl font-bold text-gray-900 border-t-2 border-gray-200 pt-3 mt-3">
                <span>Total</span>
                <span class="bg-gradient-to-r from-primary to-primary-dark bg-clip-text text-transparent">
                  {{ formatCurrency(booking.totalAmount) }}
                </span>
              </div>
            </div>

            <!-- Payment status -->
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div class="flex items-center gap-3 p-4 rounded-xl bg-gray-50">
                <span 
                  class="material-symbols-outlined text-2xl"
                  :class="booking.paymentStatus === 'paid' ? 'text-emerald-600' : 'text-amber-500'"
                >
                  {{ booking.paymentStatus === 'paid' ? 'check_circle' : 'schedule' }}
                </span>
                <div>
                  <p class="text-xs font-medium text-gray-500 uppercase tracking-wide">Estado del pago</p>
                  <p class="font-bold" :class="booking.paymentStatus === 'paid' ? 'text-emerald-600' : 'text-amber-600'">
                    {{ getPaymentStatusLabel(booking.paymentStatus) }}
                  </p>
                </div>
              </div>
              <div class="flex items-center gap-3 p-4 rounded-xl bg-gray-50">
                <span class="material-symbols-outlined text-2xl text-primary">account_balance</span>
                <div>
                  <p class="text-xs font-medium text-gray-500 uppercase tracking-wide">Método de pago</p>
                  <p class="font-bold text-gray-900">{{ getPaymentMethodLabel(booking.paymentMethod) }}</p>
                </div>
              </div>
            </div>

            <!-- Transfer Status Section -->
            <div v-if="booking.paymentMethod === 'transfer'" class="space-y-3">
              <!-- Awaiting proof -->
              <div v-if="transferStatus === 'awaiting_proof'" class="p-4 rounded-xl bg-blue-50 ring-1 ring-blue-200">
                <div class="flex items-start gap-4">
                  <div class="flex h-12 w-12 items-center justify-center rounded-xl bg-blue-100">
                    <span class="material-symbols-outlined text-blue-600">upload_file</span>
                  </div>
                  <div class="flex-1">
                    <p class="font-bold text-blue-900">Subir comprobante de transferencia</p>
                    <p class="text-sm text-blue-700 mt-1">
                      Por favor realiza la transferencia al propietario y sube una foto o captura del comprobante.
                    </p>
                    <button
                      type="button"
                      class="mt-3 px-4 py-2.5 rounded-xl bg-gradient-to-r from-blue-500 to-blue-600 text-white text-sm font-semibold shadow-lg shadow-blue-500/25 hover:shadow-xl transition-all flex items-center gap-2"
                      @click="showTransferModal = true"
                    >
                      <span class="material-symbols-outlined !text-[18px]">upload</span>
                      Subir comprobante
                    </button>
                  </div>
                </div>
              </div>

              <!-- Pending verification -->
              <div v-if="transferStatus === 'pending_verification'" class="p-4 rounded-xl bg-amber-50 ring-1 ring-amber-200">
                <div class="flex items-start gap-4">
                  <div class="flex h-12 w-12 items-center justify-center rounded-xl bg-amber-100">
                    <span class="material-symbols-outlined text-amber-600">hourglass_top</span>
                  </div>
                  <div class="flex-1">
                    <p class="font-bold text-amber-900">Comprobante pendiente de verificación</p>
                    <p class="text-sm text-amber-700 mt-1">
                      Tu comprobante ha sido enviado. El propietario lo revisará y confirmará el pago pronto.
                    </p>
                    <p class="text-xs text-amber-600 mt-2">
                      Subido el {{ new Date(booking.transferProofUploadedAt!).toLocaleString('es-HN', { 
                        year: 'numeric', month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' 
                      }) }}
                    </p>
                    <div v-if="booking.transferProofUrl" class="mt-3">
                      <a 
                        :href="booking.transferProofUrl" 
                        target="_blank"
                        class="inline-flex items-center gap-1.5 text-sm font-medium text-amber-700 hover:text-amber-900 transition-colors"
                      >
                        <span class="material-symbols-outlined !text-[16px]">visibility</span>
                        Ver comprobante subido
                      </a>
                    </div>
                  </div>
                </div>
              </div>

              <!-- Rejected -->
              <div v-if="transferStatus === 'rejected'" class="p-4 rounded-xl bg-rose-50 ring-1 ring-rose-200">
                <div class="flex items-start gap-4">
                  <div class="flex h-12 w-12 items-center justify-center rounded-xl bg-rose-100">
                    <span class="material-symbols-outlined text-rose-600">error</span>
                  </div>
                  <div class="flex-1">
                    <p class="font-bold text-rose-900">Comprobante rechazado</p>
                    <p class="text-sm text-rose-700 mt-1">
                      {{ booking.transferRejectionReason || 'El propietario rechazó el comprobante. Por favor sube uno nuevo.' }}
                    </p>
                    <button
                      type="button"
                      class="mt-3 px-4 py-2.5 rounded-xl bg-gradient-to-r from-rose-500 to-rose-600 text-white text-sm font-semibold shadow-lg shadow-rose-500/25 hover:shadow-xl transition-all flex items-center gap-2"
                      @click="showTransferModal = true"
                    >
                      <span class="material-symbols-outlined !text-[18px]">upload</span>
                      Subir nuevo comprobante
                    </button>
                  </div>
                </div>
              </div>

              <!-- Verified -->
              <div v-if="transferStatus === 'verified'" class="p-4 rounded-xl bg-emerald-50 ring-1 ring-emerald-200">
                <div class="flex items-start gap-4">
                  <div class="flex h-12 w-12 items-center justify-center rounded-xl bg-emerald-100">
                    <span class="material-symbols-outlined text-emerald-600">verified</span>
                  </div>
                  <div class="flex-1">
                    <p class="font-bold text-emerald-900">Transferencia verificada</p>
                    <p class="text-sm text-emerald-700 mt-1">
                      El propietario ha verificado tu comprobante de transferencia.
                    </p>
                    <p v-if="booking.transferVerifiedAt" class="text-xs text-emerald-600 mt-2">
                      Verificado el {{ new Date(booking.transferVerifiedAt).toLocaleString('es-HN', { 
                        year: 'numeric', month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' 
                      }) }}
                    </p>
                  </div>
                </div>
              </div>
            </div>

            <!-- Success message -->
            <div v-if="uploadSuccess" class="flex items-center gap-3 p-4 rounded-xl bg-emerald-50 ring-1 ring-emerald-200">
              <span class="material-symbols-outlined text-emerald-600">check_circle</span>
              <p class="text-sm font-medium text-emerald-800">{{ uploadSuccess }}</p>
            </div>

            <!-- Payment notes -->
            <div v-if="booking.paymentStatus === 'pending' && booking.paymentMethod !== 'transfer'" class="flex items-center gap-3 p-4 rounded-xl bg-amber-50 ring-1 ring-amber-200">
              <span class="material-symbols-outlined text-amber-600">info</span>
              <p class="text-sm text-amber-800">
                <strong>Recuerda:</strong> Debes completar el pago antes del día de tu reserva para garantizar tu espacio.
              </p>
            </div>

            <div v-if="booking.paymentStatus === 'paid' && booking.paidAt && booking.paymentMethod !== 'transfer'" class="flex items-center gap-3 p-4 rounded-xl bg-emerald-50 ring-1 ring-emerald-200">
              <span class="material-symbols-outlined text-emerald-600">check_circle</span>
              <p class="text-sm text-emerald-800">
                <strong>Pago completado</strong> el {{ new Date(booking.paidAt).toLocaleDateString('es-HN', { year: 'numeric', month: 'long', day: 'numeric' }) }}
              </p>
            </div>
          </div>
        </div>

        <!-- Space Details Card -->
        <div v-if="booking.space" class="bg-white rounded-2xl p-6 shadow-sm ring-1 ring-black/5">
          <div class="flex items-center gap-3 mb-6">
            <div class="flex h-10 w-10 items-center justify-center rounded-xl bg-gradient-to-br from-primary to-primary-dark">
              <span class="material-symbols-outlined text-white">home_work</span>
            </div>
            <h3 class="text-lg font-bold text-gray-900">Detalles del Espacio</h3>
          </div>

          <div class="grid grid-cols-2 md:grid-cols-3 gap-4">
            <div class="flex items-center gap-3 p-4 rounded-xl bg-gray-50">
              <span class="material-symbols-outlined text-primary">groups</span>
              <div>
                <p class="text-xs font-medium text-gray-500 uppercase tracking-wide">Capacidad</p>
                <p class="font-bold text-gray-900">{{ booking.space.capacity }} personas</p>
              </div>
            </div>

            <div v-if="booking.space.address" class="flex items-center gap-3 p-4 rounded-xl bg-gray-50">
              <span class="material-symbols-outlined text-primary">location_on</span>
              <div>
                <p class="text-xs font-medium text-gray-500 uppercase tracking-wide">Ubicación</p>
                <p class="font-bold text-gray-900">{{ booking.space.city || 'Sin especificar' }}</p>
              </div>
            </div>

            <div class="flex items-center gap-3 p-4 rounded-xl bg-gray-50">
              <span class="material-symbols-outlined text-primary">category</span>
              <div>
                <p class="text-xs font-medium text-gray-500 uppercase tracking-wide">Categoría</p>
                <p class="font-bold text-gray-900">{{ booking.space.category || 'Espacio' }}</p>
              </div>
            </div>
          </div>

          <div v-if="booking.space.description" class="mt-4 pt-4 border-t border-gray-100">
            <p class="text-gray-600">{{ booking.space.description }}</p>
          </div>
        </div>

        <!-- Booking Info Card -->
        <div class="bg-white rounded-2xl p-6 shadow-sm ring-1 ring-black/5">
          <div class="flex items-center gap-3 mb-6">
            <div class="flex h-10 w-10 items-center justify-center rounded-xl bg-gray-200">
              <span class="material-symbols-outlined text-gray-600">info</span>
            </div>
            <h3 class="text-lg font-bold text-gray-900">Información de la Reserva</h3>
          </div>

          <div class="space-y-3 text-sm">
            <div class="flex justify-between items-center p-3 rounded-lg bg-gray-50">
              <span class="text-gray-600">ID de reserva</span>
              <span class="font-mono font-semibold text-gray-900 text-xs bg-gray-200 px-2 py-1 rounded">{{ booking._id }}</span>
            </div>
            <div class="flex justify-between items-center p-3 rounded-lg bg-gray-50">
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
            <div v-if="booking.updatedAt !== booking.createdAt" class="flex justify-between items-center p-3 rounded-lg bg-gray-50">
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
          <div class="bg-white rounded-2xl max-w-md w-full shadow-2xl ring-1 ring-black/5">
            <div class="p-6">
              <div class="flex items-center gap-4 mb-4">
                <div class="flex h-14 w-14 items-center justify-center rounded-2xl bg-rose-100">
                  <span class="material-symbols-outlined text-rose-600 text-3xl">cancel</span>
                </div>
                <h3 class="text-xl font-bold text-gray-900">Cancelar Reserva</h3>
              </div>

              <p class="text-gray-600 mb-6">
                ¿Estás seguro de que deseas cancelar esta reserva? Esta acción no se puede deshacer.
              </p>

              <div v-if="actionError" class="mb-4 p-4 rounded-xl bg-rose-50 ring-1 ring-rose-200 text-sm text-rose-800">
                {{ actionError }}
              </div>

              <div class="flex gap-3">
                <button
                  type="button"
                  class="flex-1 px-6 py-3 rounded-xl bg-gray-100 font-semibold text-gray-700 hover:bg-gray-200 transition-all"
                  :disabled="isProcessing"
                  @click="showCancelModal = false"
                >
                  No, mantener
                </button>
                <button
                  type="button"
                  class="flex-1 px-6 py-3 rounded-xl bg-gradient-to-r from-rose-500 to-rose-600 font-semibold text-white shadow-lg shadow-rose-500/25 hover:shadow-xl transition-all disabled:opacity-50"
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
          <div class="bg-white rounded-2xl max-w-lg w-full shadow-2xl ring-1 ring-black/5 max-h-[90vh] overflow-y-auto">
            <div class="sticky top-0 bg-white border-b border-gray-100 px-6 py-4 flex items-center justify-between rounded-t-2xl">
              <h3 class="text-xl font-bold text-gray-900">Reprogramar Reserva</h3>
              <button
                type="button"
                class="p-2 rounded-lg text-gray-400 hover:text-gray-600 hover:bg-gray-100 transition-all"
                :disabled="isProcessing"
                @click="showRescheduleModal = false"
              >
                <span class="material-symbols-outlined">close</span>
              </button>
            </div>

            <div class="p-6 space-y-6">
              <div class="p-4 rounded-xl bg-blue-50 ring-1 ring-blue-200">
                <p class="text-sm text-blue-800">
                  <strong>Nota:</strong> Se creará una nueva reserva con la fecha y hora seleccionadas. Podrás cancelar la reserva anterior si lo deseas.
                </p>
              </div>

              <!-- Nueva fecha -->
              <div class="space-y-2">
                <label class="block text-sm font-semibold text-gray-700">Nueva fecha</label>
                <input
                  v-model="newDate"
                  type="date"
                  :min="new Date().toISOString().split('T')[0]"
                  class="h-12 w-full rounded-xl border border-gray-200 bg-gray-50/50 px-4 text-sm text-gray-900 transition-all hover:border-gray-300 focus:border-primary focus:bg-white focus:outline-none focus:ring-2 focus:ring-primary/20"
                />
              </div>

              <!-- Nueva hora -->
              <div class="space-y-2">
                <label class="block text-sm font-semibold text-gray-700">Nueva hora</label>
                <input
                  v-model="newTime"
                  type="time"
                  class="h-12 w-full rounded-xl border border-gray-200 bg-gray-50/50 px-4 text-sm text-gray-900 transition-all hover:border-gray-300 focus:border-primary focus:bg-white focus:outline-none focus:ring-2 focus:ring-primary/20"
                />
              </div>

              <!-- Duración -->
              <div class="space-y-2">
                <label class="block text-sm font-semibold text-gray-700">Duración (horas)</label>
                <input
                  v-model.number="newHours"
                  type="number"
                  min="1"
                  max="24"
                  class="h-12 w-full rounded-xl border border-gray-200 bg-gray-50/50 px-4 text-sm text-gray-900 transition-all hover:border-gray-300 focus:border-primary focus:bg-white focus:outline-none focus:ring-2 focus:ring-primary/20"
                />
              </div>

              <div v-if="actionError" class="p-4 rounded-xl bg-rose-50 ring-1 ring-rose-200 text-sm text-rose-800">
                {{ actionError }}
              </div>

              <div class="flex gap-3">
                <button
                  type="button"
                  class="flex-1 px-6 py-3 rounded-xl bg-gray-100 font-semibold text-gray-700 hover:bg-gray-200 transition-all"
                  :disabled="isProcessing"
                  @click="showRescheduleModal = false"
                >
                  Cancelar
                </button>
                <button
                  type="button"
                  class="flex-1 px-6 py-3 rounded-xl bg-gradient-to-r from-primary to-primary-dark font-semibold text-white shadow-lg shadow-primary/25 hover:shadow-xl transition-all disabled:opacity-50"
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
          <div class="bg-white rounded-2xl max-w-md w-full shadow-2xl ring-1 ring-black/5">
            <div class="sticky top-0 bg-white border-b border-gray-100 px-6 py-4 flex items-center justify-between rounded-t-2xl">
              <h3 class="text-xl font-bold text-gray-900">Procesar Pago</h3>
              <button
                type="button"
                class="p-2 rounded-lg text-gray-400 hover:text-gray-600 hover:bg-gray-100 transition-all"
                :disabled="isProcessing"
                @click="showPaymentModal = false"
              >
                <span class="material-symbols-outlined">close</span>
              </button>
            </div>

            <div class="p-6 space-y-6">
              <div class="p-4 rounded-xl bg-amber-50 ring-1 ring-amber-200">
                <p class="text-sm text-amber-800">
                  <strong>Simulación de pago:</strong> El proceso de pago es simulado para propósitos de demostración.
                </p>
              </div>

              <!-- Total a pagar -->
              <div class="text-center p-6 rounded-2xl bg-gradient-to-br from-primary/5 to-blue-50 ring-2 ring-primary/20">
                <p class="text-sm font-medium text-gray-600 mb-2">Total a pagar</p>
                <p class="text-4xl font-black bg-gradient-to-r from-primary to-primary-dark bg-clip-text text-transparent">
                  {{ formatCurrency(booking?.totalAmount) }}
                </p>
              </div>

              <!-- Método de pago -->
              <div>
                <label class="block text-sm font-semibold text-gray-700 mb-3">Método de pago</label>
                <div class="grid grid-cols-3 gap-3">
                  <button
                    type="button"
                    class="flex flex-col items-center gap-2 p-4 rounded-xl ring-2 transition-all"
                    :class="selectedPaymentMethod === 'cash' 
                      ? 'ring-primary bg-primary/5 shadow-lg shadow-primary/10' 
                      : 'ring-gray-200 hover:ring-gray-300'"
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
                    class="flex flex-col items-center gap-2 p-4 rounded-xl ring-2 transition-all"
                    :class="selectedPaymentMethod === 'card' 
                      ? 'ring-primary bg-primary/5 shadow-lg shadow-primary/10' 
                      : 'ring-gray-200 hover:ring-gray-300'"
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
                    class="flex flex-col items-center gap-2 p-4 rounded-xl ring-2 transition-all"
                    :class="selectedPaymentMethod === 'transfer' 
                      ? 'ring-primary bg-primary/5 shadow-lg shadow-primary/10' 
                      : 'ring-gray-200 hover:ring-gray-300'"
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

              <div v-if="actionError" class="p-4 rounded-xl bg-rose-50 ring-1 ring-rose-200 text-sm text-rose-800">
                {{ actionError }}
              </div>

              <!-- Notas según método -->
              <div v-if="selectedPaymentMethod === 'transfer'" class="p-4 rounded-xl bg-blue-50 ring-1 ring-blue-200 text-sm text-blue-800">
                <strong>Pago por transferencia:</strong> Después de seleccionar, deberás subir una foto del comprobante de transferencia para que el propietario lo verifique.
              </div>

              <div v-if="selectedPaymentMethod === 'card'" class="p-4 rounded-xl bg-amber-50 ring-1 ring-amber-200 text-sm text-amber-800">
                <strong>Nota:</strong> El pago con tarjeta aún no está disponible. Por favor selecciona otro método de pago.
              </div>

              <div class="flex gap-3">
                <button
                  type="button"
                  class="flex-1 px-6 py-3 rounded-xl bg-gray-100 font-semibold text-gray-700 hover:bg-gray-200 transition-all"
                  :disabled="isProcessing"
                  @click="showPaymentModal = false"
                >
                  Cancelar
                </button>
                <button
                  type="button"
                  class="flex-1 px-6 py-3 rounded-xl bg-gradient-to-r from-emerald-500 to-emerald-600 font-semibold text-white shadow-lg shadow-emerald-500/25 hover:shadow-xl transition-all disabled:opacity-50"
                  :disabled="isProcessing || selectedPaymentMethod === 'card'"
                  @click="handlePayment"
                >
                  {{ isProcessing ? 'Procesando...' : selectedPaymentMethod === 'transfer' ? 'Continuar' : 'Confirmar' }}
                </button>
              </div>
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>

    <!-- Modal: Subir comprobante de transferencia -->
    <Teleport to="body">
      <Transition name="modal">
        <div
          v-if="showTransferModal"
          class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm"
          @click.self="closeTransferModal"
        >
          <div class="bg-white rounded-2xl max-w-lg w-full shadow-2xl ring-1 ring-black/5 max-h-[90vh] overflow-y-auto">
            <div class="sticky top-0 bg-white border-b border-gray-100 px-6 py-4 flex items-center justify-between rounded-t-2xl">
              <h3 class="text-xl font-bold text-gray-900">Subir Comprobante de Transferencia</h3>
              <button
                type="button"
                class="p-2 rounded-lg text-gray-400 hover:text-gray-600 hover:bg-gray-100 transition-all"
                :disabled="isProcessing"
                @click="closeTransferModal"
              >
                <span class="material-symbols-outlined">close</span>
              </button>
            </div>

            <div class="p-6 space-y-6">
              <!-- Instrucciones -->
              <div class="p-4 rounded-xl bg-blue-50 ring-1 ring-blue-200">
                <h4 class="font-semibold text-blue-900 mb-2">Instrucciones para el pago</h4>
                <ol class="text-sm text-blue-800 list-decimal list-inside space-y-1">
                  <li>Realiza una transferencia al propietario del espacio</li>
                  <li>Toma una captura de pantalla o foto del comprobante</li>
                  <li>Sube la imagen aquí para que el propietario la verifique</li>
                </ol>
              </div>

              <!-- Total a pagar -->
              <div class="text-center p-4 rounded-2xl bg-gradient-to-br from-primary/5 to-blue-50 ring-2 ring-primary/20">
                <p class="text-sm font-medium text-gray-600 mb-1">Monto a transferir</p>
                <p class="text-3xl font-black bg-gradient-to-r from-primary to-primary-dark bg-clip-text text-transparent">
                  {{ formatCurrency(booking?.totalAmount) }}
                </p>
              </div>

              <!-- Input de archivo -->
              <div>
                <label class="block text-sm font-semibold text-gray-700 mb-2">Comprobante de transferencia</label>
                <div 
                  class="border-2 border-dashed rounded-xl p-6 text-center transition-all cursor-pointer"
                  :class="transferProofFile ? 'border-primary bg-primary/5' : 'border-gray-300 hover:border-primary/50'"
                  @click="($refs.fileInput as HTMLInputElement)?.click()"
                >
                  <input
                    ref="fileInput"
                    type="file"
                    accept="image/*"
                    class="hidden"
                    @change="handleFileSelect"
                  />
                  
                  <div v-if="!transferProofPreview">
                    <div class="flex h-16 w-16 items-center justify-center rounded-2xl bg-gray-100 mx-auto mb-3">
                      <span class="material-symbols-outlined text-3xl text-gray-400">cloud_upload</span>
                    </div>
                    <p class="text-sm font-medium text-gray-700">
                      Haz clic para seleccionar una imagen
                    </p>
                    <p class="text-xs text-gray-500 mt-1">
                      PNG, JPG o JPEG (máx. 5MB)
                    </p>
                  </div>
                  
                  <div v-else>
                    <img 
                      :src="transferProofPreview" 
                      alt="Preview del comprobante" 
                      class="max-h-48 mx-auto rounded-xl shadow-sm"
                    />
                    <p class="mt-3 text-sm text-primary font-semibold">
                      {{ transferProofFile?.name }}
                    </p>
                    <p class="text-xs text-gray-500">
                      Haz clic para cambiar la imagen
                    </p>
                  </div>
                </div>
              </div>

              <!-- Error -->
              <div v-if="actionError" class="p-4 rounded-xl bg-rose-50 ring-1 ring-rose-200 text-sm text-rose-800">
                {{ actionError }}
              </div>

              <!-- Botones -->
              <div class="flex gap-3">
                <button
                  type="button"
                  class="flex-1 px-6 py-3 rounded-xl bg-gray-100 font-semibold text-gray-700 hover:bg-gray-200 transition-all"
                  :disabled="isProcessing"
                  @click="closeTransferModal"
                >
                  Cancelar
                </button>
                <button
                  type="button"
                  class="flex-1 px-6 py-3 rounded-xl bg-gradient-to-r from-primary to-primary-dark font-semibold text-white shadow-lg shadow-primary/25 hover:shadow-xl transition-all disabled:opacity-50"
                  :disabled="isProcessing || !transferProofFile"
                  @click="handleUploadProof"
                >
                  <span v-if="isProcessing" class="flex items-center justify-center gap-2">
                    <span class="h-4 w-4 border-2 border-white border-t-transparent rounded-full animate-spin"></span>
                    Subiendo...
                  </span>
                  <span v-else class="flex items-center justify-center gap-2">
                    <span class="material-symbols-outlined !text-[18px]">upload</span>
                    Subir comprobante
                  </span>
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
  transform: scale(0.95);
}
</style>
