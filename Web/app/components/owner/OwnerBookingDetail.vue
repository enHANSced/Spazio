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
            <div class="grid grid-cols-2 gap-4">
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-2">Inicio</label>
                <div class="bg-gray-50 rounded-lg p-4">
                  <p class="font-semibold text-gray-900">
                    {{ formatDate(booking.startTime) }}
                  </p>
                  <p class="text-sm text-gray-600">
                    {{ formatTime(booking.startTime) }}
                  </p>
                </div>
              </div>
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-2">Fin</label>
                <div class="bg-gray-50 rounded-lg p-4">
                  <p class="font-semibold text-gray-900">
                    {{ formatDate(booking.endTime) }}
                  </p>
                  <p class="text-sm text-gray-600">
                    {{ formatTime(booking.endTime) }}
                  </p>
                </div>
              </div>
            </div>

            <!-- Duración -->
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-2">Duración</label>
              <p class="text-lg font-semibold text-gray-900">
                {{ booking.durationHours }} {{ booking.durationHours === 1 ? 'hora' : 'horas' }}
              </p>
            </div>

            <!-- Pago -->
            <div class="border-t border-gray-200 pt-6">
              <h3 class="text-lg font-semibold text-gray-900 mb-4">Información de Pago</h3>
              
              <div class="space-y-3">
                <div class="flex justify-between">
                  <span class="text-gray-600">Método de pago:</span>
                  <span class="font-medium text-gray-900">
                    {{ paymentMethodLabels[booking.paymentMethod || 'cash'] }}
                  </span>
                </div>
                
                <div class="flex justify-between">
                  <span class="text-gray-600">Estado del pago:</span>
                  <span
                    :class="[
                      'font-medium',
                      booking.paymentStatus === 'paid'
                        ? 'text-green-600'
                        : booking.paymentStatus === 'refunded'
                        ? 'text-purple-600'
                        : 'text-yellow-600'
                    ]"
                  >
                    {{ paymentStatusLabels[booking.paymentStatus || 'pending'] }}
                  </span>
                </div>

                <div v-if="booking.paidAt" class="flex justify-between text-sm">
                  <span class="text-gray-600">Fecha de pago:</span>
                  <span class="text-gray-900">{{ formatDateTime(booking.paidAt) }}</span>
                </div>

                <div class="border-t border-gray-200 pt-3 mt-3">
                  <div class="flex justify-between text-sm">
                    <span class="text-gray-600">Subtotal:</span>
                    <span class="text-gray-900">{{ formatCurrency(booking.subtotal || 0) }}</span>
                  </div>
                  <div class="flex justify-between text-sm mt-2">
                    <span class="text-gray-600">Comisión de servicio:</span>
                    <span class="text-gray-900">{{ formatCurrency(booking.serviceFee || 0) }}</span>
                  </div>
                  <div class="flex justify-between text-lg font-bold mt-3">
                    <span class="text-gray-900">Total:</span>
                    <span class="text-gray-900">{{ formatCurrency(booking.totalAmount || 0) }}</span>
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
          <div class="sticky bottom-0 bg-gray-50 border-t border-gray-200 px-6 py-4 rounded-b-xl flex gap-3">
            <!-- Cambiar estado de pago -->
            <button
              v-if="booking.status !== 'cancelled' && booking.paymentStatus === 'pending'"
              @click="handleMarkAsPaid"
              :disabled="isProcessing"
              class="flex-1 px-4 py-2 bg-green-600 text-white rounded-lg font-medium hover:bg-green-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
            >
              Marcar como Pagada
            </button>

            <!-- Cancelar reserva -->
            <button
              v-if="booking.status !== 'cancelled' && booking.status !== 'completed'"
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

const statusStyles = {
  pending: 'bg-yellow-100 text-yellow-800',
  confirmed: 'bg-blue-100 text-blue-800',
  cancelled: 'bg-red-100 text-red-800',
  completed: 'bg-green-100 text-green-800'
}

const statusLabels = {
  pending: 'Pendiente',
  confirmed: 'Confirmada',
  cancelled: 'Cancelada',
  completed: 'Completada'
}

const paymentMethodLabels = {
  cash: 'Efectivo',
  card: 'Tarjeta',
  transfer: 'Transferencia'
}

const paymentStatusLabels = {
  pending: 'Pendiente',
  paid: 'Pagada',
  refunded: 'Reembolsada'
}

const formatDate = (date: string | Date) => {
  return new Date(date).toLocaleDateString('es-ES', {
    year: 'numeric',
    month: 'long',
    day: 'numeric'
  })
}

const formatTime = (date: string | Date) => {
  return new Date(date).toLocaleTimeString('es-ES', {
    hour: '2-digit',
    minute: '2-digit'
  })
}

const formatDateTime = (date: string | Date) => {
  return new Date(date).toLocaleString('es-ES', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  })
}

const formatCurrency = (amount: number) => {
  return new Intl.NumberFormat('es-ES', {
    style: 'currency',
    currency: 'USD'
  }).format(amount)
}

const close = () => {
  emit('update:modelValue', false)
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
