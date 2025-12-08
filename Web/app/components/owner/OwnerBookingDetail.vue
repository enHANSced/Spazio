<template>
  <Teleport to="body">
    <Transition name="modal">
      <div
        v-if="modelValue"
        @click="handleBackdropClick"
        class="fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-50 p-4"
      >
        <div
          @click.stop
          class="bg-white rounded-xl shadow-2xl max-w-2xl w-full max-h-[90vh] overflow-y-auto"
        >
          <!-- Header -->
          <div class="sticky top-0 bg-white border-b border-gray-200 px-6 py-4 flex items-center justify-between rounded-t-xl">
            <h2 class="text-2xl font-bold text-gray-900">Detalle de Reserva</h2>
            <button
              @click="close"
              class="text-gray-400 hover:text-gray-600 transition-colors"
            >
              <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M6 18L18 6M6 6l12 12"
                />
              </svg>
            </button>
          </div>

          <!-- Content -->
          <div class="p-6 space-y-6">
            <!-- Estado -->
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-2">Estado</label>
              <span
                :class="[
                  'inline-flex items-center gap-2 px-3 py-1.5 rounded-full text-sm font-medium',
                  statusStyles[booking.status]
                ]"
              >
                <span class="w-2 h-2 rounded-full bg-current"></span>
                {{ statusLabels[booking.status] }}
              </span>
            </div>

            <!-- Alerta de reserva pendiente de confirmación -->
            <div v-if="booking.status === 'pending'" class="bg-amber-50 border-2 border-amber-300 rounded-xl p-4">
              <div class="flex items-start gap-3">
                <div class="h-10 w-10 rounded-full bg-amber-100 flex items-center justify-center flex-shrink-0">
                  <span class="material-symbols-outlined text-amber-600">hourglass_empty</span>
                </div>
                <div class="flex-1">
                  <p class="font-bold text-amber-900">Esta reserva requiere tu confirmación</p>
                  <p class="text-sm text-amber-800 mt-1">
                    El cliente ha solicitado reservar este espacio. Revisa los detalles y decide si aceptar o rechazar la reserva.
                  </p>
                  <p v-if="booking.paymentMethod === 'cash'" class="text-xs text-amber-700 mt-2">
                    <span class="font-semibold">💰 Pago en efectivo:</span> El cliente pagará al momento de usar el espacio.
                  </p>
                  <p v-else-if="booking.paymentMethod === 'transfer' && booking.paymentStatus === 'pending'" class="text-xs text-amber-700 mt-2">
                    <span class="font-semibold">🏦 Transferencia pendiente:</span> Esperando que el cliente suba el comprobante.
                  </p>
                </div>
              </div>
            </div>

            <!-- Usuario -->
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-2">Cliente</label>
              <div class="bg-gray-50 rounded-lg p-4">
                <p class="font-semibold text-gray-900">{{ booking.user?.name || 'Sin nombre' }}</p>
                <p class="text-sm text-gray-600">{{ booking.user?.email || 'Sin email' }}</p>
              </div>
            </div>

            <!-- Espacio -->
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-2">Espacio</label>
              <div class="bg-gray-50 rounded-lg p-4">
                <p class="font-semibold text-gray-900">{{ booking.space?.name || 'Sin nombre' }}</p>
                <p v-if="booking.space?.description" class="text-sm text-gray-600 mt-1">
                  {{ booking.space.description }}
                </p>
              </div>
            </div>

            <!-- Fecha y Hora -->
            <div class="bg-gradient-to-br from-blue-50 to-indigo-50 rounded-xl p-6 border-2 border-blue-100">
              <div class="flex items-center gap-2 mb-4">
                <span class="material-symbols-outlined text-blue-600">event</span>
                <h3 class="text-base font-bold text-gray-900">Programación</h3>
              </div>
              <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div class="bg-white rounded-lg p-4 shadow-sm">
                  <div class="flex items-center gap-2 mb-2">
                    <span class="material-symbols-outlined text-green-600 !text-[18px]">play_circle</span>
                    <label class="text-xs font-semibold text-gray-600 uppercase">Inicio</label>
                  </div>
                  <p class="font-bold text-gray-900 text-base">
                    {{ formatDate(booking.startTime) }}
                  </p>
                  <p class="text-sm text-green-600 font-semibold mt-1">
                    {{ formatTime(booking.startTime) }}
                  </p>
                </div>
                <div class="bg-white rounded-lg p-4 shadow-sm">
                  <div class="flex items-center gap-2 mb-2">
                    <span class="material-symbols-outlined text-red-600 !text-[18px]">stop_circle</span>
                    <label class="text-xs font-semibold text-gray-600 uppercase">Fin</label>
                  </div>
                  <p class="font-bold text-gray-900 text-base">
                    {{ formatDate(booking.endTime) }}
                  </p>
                  <p class="text-sm text-red-600 font-semibold mt-1">
                    {{ formatTime(booking.endTime) }}
                  </p>
                </div>
              </div>
              <div class="mt-4 bg-white rounded-lg p-4 shadow-sm">
                <div class="flex items-center justify-between">
                  <div class="flex items-center gap-2">
                    <span class="material-symbols-outlined text-blue-600">schedule</span>
                    <span class="text-sm font-medium text-gray-700">Duración total</span>
                  </div>
                  <span class="text-xl font-bold text-blue-600">
                    {{ booking.durationHours }} {{ booking.durationHours === 1 ? 'hora' : 'horas' }}
                  </span>
                </div>
              </div>
            </div>

            <!-- Pago -->
            <div class="border-t-2 border-gray-200 pt-6">
              <div class="flex items-center gap-2 mb-4">
                <span class="material-symbols-outlined text-green-600">payments</span>
                <h3 class="text-lg font-bold text-gray-900">Información de Pago</h3>
              </div>
              
              <div class="bg-gradient-to-br from-green-50 to-emerald-50 rounded-xl p-5 border-2 border-green-100 space-y-4">
                <div class="bg-white rounded-lg p-4 shadow-sm">
                  <div class="flex items-center justify-between mb-3">
                    <div class="flex items-center gap-2">
                      <span class="material-symbols-outlined text-blue-600 !text-[20px]">credit_card</span>
                      <span class="text-sm font-semibold text-gray-700">Método de pago</span>
                    </div>
                    <span class="font-bold text-gray-900 text-base">
                      {{ paymentMethodLabels[booking.paymentMethod || 'cash'] }}
                    </span>
                  </div>
                  
                  <div class="flex items-center justify-between">
                    <div class="flex items-center gap-2">
                      <span class="material-symbols-outlined !text-[20px]"
                        :class="[
                          booking.paymentStatus === 'paid'
                            ? 'text-green-600'
                            : booking.paymentStatus === 'refunded'
                            ? 'text-purple-600'
                            : 'text-yellow-600'
                        ]"
                      >{{ booking.paymentStatus === 'paid' ? 'check_circle' : 'pending' }}</span>
                      <span class="text-sm font-semibold text-gray-700">Estado del pago</span>
                    </div>
                    <span
                      :class="[
                        'font-bold text-base px-3 py-1 rounded-full',
                        booking.paymentStatus === 'paid'
                          ? 'bg-green-100 text-green-700'
                          : booking.paymentStatus === 'refunded'
                          ? 'bg-purple-100 text-purple-700'
                          : 'bg-yellow-100 text-yellow-700'
                      ]"
                    >
                      {{ paymentStatusLabels[booking.paymentStatus || 'pending'] }}
                    </span>
                  </div>

                  <div v-if="booking.paidAt" class="flex items-center gap-2 mt-3 pt-3 border-t border-gray-200">
                    <span class="material-symbols-outlined text-gray-500 !text-[18px]">schedule</span>
                    <span class="text-xs text-gray-600">Pagado el {{ formatDateTime(booking.paidAt) }}</span>
                  </div>
                </div>

                <div class="bg-white rounded-lg p-4 shadow-sm">
                  <div class="space-y-2.5">
                    <div class="flex justify-between items-center">
                      <span class="text-sm text-gray-600">Subtotal</span>
                      <span class="font-semibold text-gray-900 text-base">{{ formatCurrency(booking.subtotal || 0) }}</span>
                    </div>
                    <div class="flex justify-between items-center">
                      <span class="text-sm text-gray-600">Comisión de servicio</span>
                      <span class="font-semibold text-gray-900 text-base">{{ formatCurrency(booking.serviceFee || 0) }}</span>
                    </div>
                    <div class="border-t-2 border-green-200 pt-3 mt-3 flex justify-between items-center">
                      <span class="text-base font-bold text-gray-900">Total a Pagar</span>
                      <span class="text-2xl font-black text-green-600">{{ formatCurrency(booking.totalAmount || 0) }}</span>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <!-- Comprobante de Transferencia -->
            <div v-if="booking.paymentMethod === 'transfer'" class="border-t border-gray-200 pt-6">
              <h3 class="text-lg font-semibold text-gray-900 mb-4 flex items-center gap-2">
                <span class="material-symbols-outlined text-primary">receipt_long</span>
                Comprobante de Transferencia
              </h3>

              <!-- Sin comprobante -->
              <div v-if="!booking.transferProofUrl && !booking.transferRejectedAt" class="bg-gray-50 rounded-lg p-4 text-center">
                <span class="material-symbols-outlined text-3xl text-gray-400">hourglass_empty</span>
                <p class="text-gray-600 mt-2">El cliente aún no ha subido el comprobante de transferencia</p>
              </div>

              <!-- Con comprobante pendiente de verificación -->
              <div v-else-if="booking.transferProofUrl && !booking.transferVerifiedAt && booking.paymentStatus === 'pending'" class="space-y-4">
                <div class="bg-amber-50 border border-amber-200 rounded-lg p-4">
                  <div class="flex items-start gap-3">
                    <span class="material-symbols-outlined text-amber-600">pending</span>
                    <div>
                      <p class="font-semibold text-amber-900">Comprobante pendiente de verificación</p>
                      <p class="text-sm text-amber-800 mt-1">
                        El cliente subió un comprobante el {{ formatDateTime(booking.transferProofUploadedAt!) }}
                      </p>
                    </div>
                  </div>
                </div>

                <!-- Vista previa del comprobante -->
                <div class="border border-gray-200 rounded-lg overflow-hidden">
                  <div class="bg-gray-100 px-4 py-2 border-b border-gray-200 flex items-center justify-between">
                    <span class="text-sm font-medium text-gray-700">Comprobante adjunto</span>
                    <a 
                      :href="booking.transferProofUrl"
                      target="_blank"
                      class="text-sm text-primary hover:underline flex items-center gap-1"
                    >
                      <span class="material-symbols-outlined !text-[16px]">open_in_new</span>
                      Ver en tamaño completo
                    </a>
                  </div>
                  <div class="p-4 bg-white">
                    <img 
                      :src="booking.transferProofUrl"
                      alt="Comprobante de transferencia"
                      class="max-h-64 mx-auto rounded shadow-sm cursor-pointer hover:opacity-90 transition"
                      @click="openImageInNewTab(booking.transferProofUrl!)"
                    />
                  </div>
                </div>

                <!-- Acciones de verificación -->
                <div class="flex gap-3">
                  <button
                    @click="handleVerifyTransfer(true)"
                    :disabled="isProcessing"
                    class="flex-1 px-4 py-3 bg-green-600 text-white rounded-lg font-semibold hover:bg-green-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2"
                  >
                    <span class="material-symbols-outlined !text-[20px]">check_circle</span>
                    Aprobar Pago
                  </button>
                  <button
                    @click="showRejectModal = true"
                    :disabled="isProcessing"
                    class="flex-1 px-4 py-3 bg-red-600 text-white rounded-lg font-semibold hover:bg-red-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2"
                  >
                    <span class="material-symbols-outlined !text-[20px]">cancel</span>
                    Rechazar
                  </button>
                </div>
              </div>

              <!-- Comprobante verificado -->
              <div v-else-if="booking.paymentStatus === 'paid' && booking.transferVerifiedAt" class="bg-green-50 border border-green-200 rounded-lg p-4">
                <div class="flex items-start gap-3">
                  <span class="material-symbols-outlined text-green-600">verified</span>
                  <div>
                    <p class="font-semibold text-green-900">Transferencia verificada</p>
                    <p class="text-sm text-green-800 mt-1">
                      Verificado el {{ formatDateTime(booking.transferVerifiedAt) }}
                    </p>
                    <a 
                      v-if="booking.transferProofUrl"
                      :href="booking.transferProofUrl"
                      target="_blank"
                      class="text-sm text-green-700 hover:underline flex items-center gap-1 mt-2"
                    >
                      <span class="material-symbols-outlined !text-[16px]">visibility</span>
                      Ver comprobante
                    </a>
                  </div>
                </div>
              </div>

              <!-- Comprobante rechazado (esperando nuevo) -->
              <div v-else-if="booking.transferRejectedAt && !booking.transferProofUrl" class="bg-red-50 border border-red-200 rounded-lg p-4">
                <div class="flex items-start gap-3">
                  <span class="material-symbols-outlined text-red-600">error</span>
                  <div>
                    <p class="font-semibold text-red-900">Comprobante rechazado</p>
                    <p class="text-sm text-red-800 mt-1">
                      Motivo: {{ booking.transferRejectionReason || 'No especificado' }}
                    </p>
                    <p class="text-xs text-red-700 mt-2">
                      El cliente puede subir un nuevo comprobante
                    </p>
                  </div>
                </div>
              </div>
            </div>

            <!-- Notas -->
            <div v-if="booking.notes">
              <label class="block text-sm font-medium text-gray-700 mb-2">Notas</label>
              <div class="bg-gray-50 rounded-lg p-4">
                <p class="text-gray-900">{{ booking.notes }}</p>
              </div>
            </div>

            <!-- Fechas de sistema -->
            <div class="border-t border-gray-200 pt-4 text-xs text-gray-500 space-y-1">
              <p>Creada: {{ formatDateTime(booking.createdAt) }}</p>
              <p v-if="booking.updatedAt">Actualizada: {{ formatDateTime(booking.updatedAt) }}</p>
            </div>
          </div>

          <!-- Actions -->
          <div class="sticky bottom-0 bg-gray-50 border-t border-gray-200 px-6 py-4 rounded-b-xl">
            <!-- Acciones para reservas pendientes de confirmación -->
            <div v-if="booking.status === 'pending'" class="flex gap-3 mb-3">
              <button
                @click="handleConfirmBooking"
                :disabled="isProcessing"
                class="flex-1 px-4 py-3 bg-green-600 text-white rounded-lg font-semibold hover:bg-green-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2"
              >
                <span class="material-symbols-outlined !text-[20px]">check_circle</span>
                {{ isProcessing ? 'Procesando...' : 'Confirmar Reserva' }}
              </button>
              <button
                @click="showRejectBookingModal = true"
                :disabled="isProcessing"
                class="flex-1 px-4 py-3 bg-red-600 text-white rounded-lg font-semibold hover:bg-red-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2"
              >
                <span class="material-symbols-outlined !text-[20px]">cancel</span>
                Rechazar Reserva
              </button>
            </div>

            <div class="flex gap-3">
              <!-- Cambiar estado de pago (solo si está confirmada y no es transferencia pendiente) -->
              <button
                v-if="booking.status === 'confirmed' && booking.paymentStatus === 'pending' && booking.paymentMethod !== 'transfer'"
                @click="handleMarkAsPaid"
                :disabled="isProcessing"
                class="flex-1 px-4 py-2 bg-green-600 text-white rounded-lg font-medium hover:bg-green-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
              >
                Marcar como Pagada
              </button>

              <!-- Cancelar reserva -->
              <button
                v-if="booking.status !== 'cancelled' && booking.status !== 'completed' && booking.status !== 'pending'"
                @click="handleCancel"
                :disabled="isProcessing"
                class="px-4 py-2 bg-red-600 text-white rounded-lg font-medium hover:bg-red-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
              >
                Cancelar Reserva
              </button>

              <button
                @click="close"
                class="px-4 py-2 border border-gray-300 rounded-lg font-medium text-gray-700 hover:bg-gray-50 transition-colors"
              >
                Cerrar
              </button>
            </div>
          </div>
        </div>
      </div>
    </Transition>

    <!-- Modal de rechazo -->
    <Transition name="modal">
      <div
        v-if="showRejectModal"
        @click="showRejectModal = false"
        class="fixed inset-0 z-[60] flex items-center justify-center bg-black bg-opacity-50 p-4"
      >
        <div
          @click.stop
          class="bg-white rounded-xl shadow-2xl max-w-md w-full"
        >
          <div class="p-6">
            <div class="flex items-center gap-3 mb-4">
              <div class="h-12 w-12 rounded-full bg-red-100 flex items-center justify-center">
                <span class="material-symbols-outlined text-red-600 text-2xl">error</span>
              </div>
              <h3 class="text-xl font-bold text-gray-900">Rechazar Comprobante</h3>
            </div>

            <p class="text-gray-600 mb-4">
              Por favor indica el motivo del rechazo para que el cliente pueda corregirlo:
            </p>

            <textarea
              v-model="rejectionReason"
              placeholder="Ej: La imagen está borrosa, el monto no coincide, etc."
              class="w-full rounded-lg border-2 border-gray-300 px-4 py-3 focus:border-red-500 focus:ring-4 focus:ring-red-100 resize-none"
              rows="3"
            ></textarea>

            <div class="flex gap-3 mt-4">
              <button
                @click="showRejectModal = false"
                :disabled="isProcessing"
                class="flex-1 px-4 py-2 border border-gray-300 rounded-lg font-medium text-gray-700 hover:bg-gray-50 transition-colors"
              >
                Cancelar
              </button>
              <button
                @click="handleVerifyTransfer(false)"
                :disabled="isProcessing || !rejectionReason.trim()"
                class="flex-1 px-4 py-2 bg-red-600 text-white rounded-lg font-medium hover:bg-red-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
              >
                {{ isProcessing ? 'Procesando...' : 'Rechazar' }}
              </button>
            </div>
          </div>
        </div>
      </div>
    </Transition>

    <!-- Modal de rechazo de reserva -->
    <Transition name="modal">
      <div
        v-if="showRejectBookingModal"
        @click="showRejectBookingModal = false"
        class="fixed inset-0 z-[60] flex items-center justify-center bg-black bg-opacity-50 p-4"
      >
        <div
          @click.stop
          class="bg-white rounded-xl shadow-2xl max-w-md w-full"
        >
          <div class="p-6">
            <div class="flex items-center gap-3 mb-4">
              <div class="h-12 w-12 rounded-full bg-red-100 flex items-center justify-center">
                <span class="material-symbols-outlined text-red-600 text-2xl">event_busy</span>
              </div>
              <h3 class="text-xl font-bold text-gray-900">Rechazar Reserva</h3>
            </div>

            <p class="text-gray-600 mb-4">
              Por favor indica el motivo del rechazo. El cliente recibirá esta información:
            </p>

            <textarea
              v-model="bookingRejectionReason"
              placeholder="Ej: El espacio no está disponible en esa fecha, el horario solicitado no es posible, etc."
              class="w-full rounded-lg border-2 border-gray-300 px-4 py-3 focus:border-red-500 focus:ring-4 focus:ring-red-100 resize-none"
              rows="3"
            ></textarea>

            <div class="flex gap-3 mt-4">
              <button
                @click="showRejectBookingModal = false"
                :disabled="isProcessing"
                class="flex-1 px-4 py-2 border border-gray-300 rounded-lg font-medium text-gray-700 hover:bg-gray-50 transition-colors"
              >
                Cancelar
              </button>
              <button
                @click="handleRejectBooking"
                :disabled="isProcessing || !bookingRejectionReason.trim()"
                class="flex-1 px-4 py-2 bg-red-600 text-white rounded-lg font-medium hover:bg-red-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
              >
                {{ isProcessing ? 'Procesando...' : 'Rechazar Reserva' }}
              </button>
            </div>
          </div>
        </div>
      </div>
    </Transition>
  </Teleport>
</template>

<script setup lang="ts">
import type { Booking } from '~/types/booking'
import { ownerBookingsService } from '~/services/owner-bookings.service'

interface Props {
  modelValue: boolean
  booking: Booking
}

interface Emits {
  (e: 'update:modelValue', value: boolean): void
  (e: 'updated'): void
}

const props = defineProps<Props>()
const emit = defineEmits<Emits>()

const toast = useToast()
const isProcessing = ref(false)
const showRejectModal = ref(false)
const rejectionReason = ref('')
const showRejectBookingModal = ref(false)
const bookingRejectionReason = ref('')

const statusStyles: Record<string, string> = {
  pending: 'bg-yellow-100 text-yellow-800',
  confirmed: 'bg-blue-100 text-blue-800',
  cancelled: 'bg-red-100 text-red-800',
  completed: 'bg-green-100 text-green-800'
}

const statusLabels: Record<string, string> = {
  pending: 'Pendiente',
  confirmed: 'Confirmada',
  cancelled: 'Cancelada',
  completed: 'Completada'
}

const paymentMethodLabels: Record<string, string> = {
  cash: 'Efectivo',
  card: 'Tarjeta',
  transfer: 'Transferencia'
}

const paymentStatusLabels: Record<string, string> = {
  pending: 'Pendiente',
  paid: 'Pagada',
  refunded: 'Reembolsada'
}

const formatDate = (date: string | Date) => {
  return new Date(date).toLocaleDateString('es-HN', {
    weekday: 'long',
    year: 'numeric',
    month: 'long',
    day: 'numeric'
  })
}

const formatTime = (date: string | Date) => {
  return new Date(date).toLocaleTimeString('es-HN', {
    hour: 'numeric',
    minute: '2-digit',
    hour12: true
  }).toUpperCase()
}

const formatDateTime = (date: string | Date) => {
  return new Date(date).toLocaleString('es-HN', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
    hour: 'numeric',
    minute: '2-digit',
    hour12: true
  }).toUpperCase()
}

const formatCurrency = (amount: number) => {
  return new Intl.NumberFormat('es-HN', {
    style: 'currency',
    currency: 'HNL',
    minimumFractionDigits: 2,
    maximumFractionDigits: 2
  }).format(amount).replace('HNL', 'L')
}

const openImageInNewTab = (url: string) => {
  window.open(url, '_blank')
}

const close = () => {
  emit('update:modelValue', false)
  showRejectModal.value = false
  rejectionReason.value = ''
  showRejectBookingModal.value = false
  bookingRejectionReason.value = ''
}

const handleBackdropClick = () => {
  close()
}

const handleMarkAsPaid = async () => {
  if (!confirm('¿Confirmar que el pago ha sido recibido?')) return

  isProcessing.value = true
  try {
    const response = await ownerBookingsService.update(props.booking._id, {
      paymentStatus: 'paid',
      paidAt: new Date().toISOString()
    })

    if (response.success) {
      toast.success('Pago actualizado exitosamente')
      emit('updated')
      close()
    } else {
      toast.error(response.message || 'Error al actualizar el pago')
    }
  } catch (error: any) {
    console.error('Error updating payment:', error)
    toast.error(error.data?.message || error.message || 'Error al actualizar el pago')
  } finally {
    isProcessing.value = false
  }
}

const handleVerifyTransfer = async (approved: boolean) => {
  isProcessing.value = true
  try {
    const response = await ownerBookingsService.verifyTransfer(
      props.booking._id, 
      approved,
      approved ? undefined : rejectionReason.value
    )

    if (response.success) {
      toast.success(approved ? 'Pago verificado exitosamente' : 'Comprobante rechazado')
      emit('updated')
      close()
    } else {
      toast.error(response.message || 'Error al procesar la solicitud')
    }
  } catch (error: any) {
    console.error('Error verifying transfer:', error)
    toast.error(error.data?.message || error.message || 'Error al procesar la solicitud')
  } finally {
    isProcessing.value = false
  }
}

const handleCancel = async () => {
  if (!confirm('¿Estás seguro de cancelar esta reserva?')) return

  isProcessing.value = true
  try {
    const response = await ownerBookingsService.cancel(props.booking._id)

    if (response.success) {
      toast.success('Reserva cancelada exitosamente')
      emit('updated')
      close()
    } else {
      toast.error(response.message || 'Error al cancelar la reserva')
    }
  } catch (error: any) {
    console.error('Error cancelling booking:', error)
    toast.error(error.data?.message || error.message || 'Error al cancelar la reserva')
  } finally {
    isProcessing.value = false
  }
}

const handleConfirmBooking = async () => {
  isProcessing.value = true
  try {
    const response = await ownerBookingsService.confirmBooking(props.booking._id)

    if (response.success) {
      toast.success('¡Reserva confirmada exitosamente!')
      emit('updated')
      close()
    } else {
      toast.error(response.message || 'Error al confirmar la reserva')
    }
  } catch (error: any) {
    console.error('Error confirming booking:', error)
    toast.error(error.data?.message || error.message || 'Error al confirmar la reserva')
  } finally {
    isProcessing.value = false
  }
}

const handleRejectBooking = async () => {
  isProcessing.value = true
  try {
    const response = await ownerBookingsService.rejectBooking(
      props.booking._id,
      bookingRejectionReason.value
    )

    if (response.success) {
      toast.success('Reserva rechazada')
      emit('updated')
      close()
    } else {
      toast.error(response.message || 'Error al rechazar la reserva')
    }
  } catch (error: any) {
    console.error('Error rejecting booking:', error)
    toast.error(error.data?.message || error.message || 'Error al rechazar la reserva')
  } finally {
    isProcessing.value = false
    showRejectBookingModal.value = false
    bookingRejectionReason.value = ''
  }
}
</script>

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
