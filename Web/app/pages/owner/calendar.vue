<template>
  <div class="space-y-6">
    <!-- Header -->
    <div>
      <h1 class="text-3xl font-bold text-gray-900">Calendario de Reservas</h1>
      <p class="mt-2 text-gray-600">
        Vista de calendario de todas las reservas en tus espacios
      </p>
    </div>

    <!-- Filtros -->
    <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-4">
      <div class="flex flex-col md:flex-row gap-4">
        <!-- Filtro por espacio -->
        <div class="flex-1">
          <label for="space-filter" class="block text-sm font-medium text-gray-700 mb-2">
            Filtrar por espacio
          </label>
          <select
            id="space-filter"
            v-model="selectedSpaceId"
            class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
          >
            <option value="all">Todos los espacios</option>
            <option v-for="space in spaces" :key="space.id" :value="space.id">
              {{ space.name }}
            </option>
          </select>
        </div>

        <!-- Navegación de mes -->
        <div class="flex items-end gap-2">
          <button
            @click="previousMonth"
            class="px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors"
          >
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
            </svg>
          </button>
          <div class="px-4 py-2 bg-gray-50 border border-gray-200 rounded-lg font-medium text-gray-900 min-w-[200px] text-center">
            {{ currentMonthLabel }}
          </div>
          <button
            @click="nextMonth"
            class="px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors"
          >
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
            </svg>
          </button>
        </div>
      </div>
    </div>

    <!-- Leyenda -->
    <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-4">
      <div class="flex flex-wrap gap-4">
        <div class="flex items-center gap-2">
          <div class="w-4 h-4 rounded bg-yellow-400"></div>
          <span class="text-sm text-gray-700">Pendiente</span>
        </div>
        <div class="flex items-center gap-2">
          <div class="w-4 h-4 rounded bg-blue-500"></div>
          <span class="text-sm text-gray-700">Confirmada</span>
        </div>
        <div class="flex items-center gap-2">
          <div class="w-4 h-4 rounded bg-green-500"></div>
          <span class="text-sm text-gray-700">Completada</span>
        </div>
        <div class="flex items-center gap-2">
          <div class="w-4 h-4 rounded bg-red-500"></div>
          <span class="text-sm text-gray-700">Cancelada</span>
        </div>
      </div>
    </div>

    <!-- Loading -->
    <div v-if="loading" class="flex items-center justify-center py-12">
      <div class="text-center">
        <svg class="animate-spin h-12 w-12 text-blue-600 mx-auto" viewBox="0 0 24 24">
          <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4" fill="none" />
          <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
        </svg>
        <p class="mt-4 text-gray-600">Cargando reservas...</p>
      </div>
    </div>

    <!-- Calendario -->
    <div v-else class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
      <!-- Días de la semana -->
      <div class="grid grid-cols-7 gap-2 mb-2">
        <div v-for="day in weekDays" :key="day" class="text-center text-sm font-semibold text-gray-700 py-2">
          {{ day }}
        </div>
      </div>

      <!-- Días del mes -->
      <div class="grid grid-cols-7 gap-2">
        <div
          v-for="(day, index) in calendarDays"
          :key="index"
          :class="[
            'min-h-[120px] border border-gray-200 rounded-lg p-2 transition-colors',
            day.isCurrentMonth ? 'bg-white hover:bg-gray-50' : 'bg-gray-50',
            day.isToday ? 'ring-2 ring-blue-500' : ''
          ]"
        >
          <div :class="['text-sm font-semibold mb-2', day.isCurrentMonth ? 'text-gray-900' : 'text-gray-400']">
            {{ day.date.getDate() }}
          </div>

          <!-- Reservas del día -->
          <div class="space-y-1">
            <button
              v-for="booking in day.bookings"
              :key="booking._id"
              @click="handleViewDetail(booking)"
              :class="[
                'w-full text-left text-xs px-2 py-1 rounded truncate hover:opacity-80 transition-opacity',
                getBookingColor(booking.status)
              ]"
              :title="`${booking.space?.name} - ${formatTime(booking.startTime)}`"
            >
              {{ formatTime(booking.startTime) }} {{ booking.space?.name?.substring(0, 15) }}
            </button>
          </div>

          <!-- Indicador de más reservas -->
          <div v-if="day.bookings.length > 3" class="text-xs text-gray-500 mt-1">
            +{{ day.bookings.length - 3 }} más
          </div>
        </div>
      </div>
    </div>

    <!-- Modal de detalle -->
    <OwnerBookingDetail
      v-if="selectedBooking"
      v-model="showDetailModal"
      :booking="selectedBooking"
      @updated="loadBookings"
    />
  </div>
</template>

<script setup lang="ts">
import { ownerBookingsService } from '~/services/owner-bookings.service'
import { ownerSpacesService } from '~/services/owner-spaces.service'
import type { Booking } from '~/types/booking'
import type { Space } from '~/types/space'

definePageMeta({
  layout: 'owner',
  middleware: ['auth', 'verified-owner']
})

const loading = ref(true)
const bookings = ref<Booking[]>([])
const spaces = ref<Space[]>([])
const selectedSpaceId = ref('all')
const currentDate = ref(new Date())
const selectedBooking = ref<Booking | null>(null)
const showDetailModal = ref(false)

const weekDays = ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb']

const currentMonthLabel = computed(() => {
  return currentDate.value.toLocaleDateString('es-ES', {
    month: 'long',
    year: 'numeric'
  })
})

const filteredBookings = computed(() => {
  if (selectedSpaceId.value === 'all') {
    return bookings.value
  }
  return bookings.value.filter(b => b.spaceId === selectedSpaceId.value)
})

const calendarDays = computed(() => {
  const year = currentDate.value.getFullYear()
  const month = currentDate.value.getMonth()
  
  // Primer día del mes
  const firstDay = new Date(year, month, 1)
  // Último día del mes
  const lastDay = new Date(year, month + 1, 0)
  
  // Días del calendario (incluye días del mes anterior y siguiente)
  const days: Array<{
    date: Date
    isCurrentMonth: boolean
    isToday: boolean
    bookings: Booking[]
  }> = []
  
  // Agregar días del mes anterior para completar la primera semana
  const firstDayOfWeek = firstDay.getDay()
  for (let i = firstDayOfWeek - 1; i >= 0; i--) {
    const date = new Date(year, month, -i)
    days.push({
      date,
      isCurrentMonth: false,
      isToday: false,
      bookings: getBookingsForDate(date)
    })
  }
  
  // Agregar días del mes actual
  for (let i = 1; i <= lastDay.getDate(); i++) {
    const date = new Date(year, month, i)
    const today = new Date()
    const isToday = date.toDateString() === today.toDateString()
    
    days.push({
      date,
      isCurrentMonth: true,
      isToday,
      bookings: getBookingsForDate(date)
    })
  }
  
  // Agregar días del mes siguiente para completar la última semana
  const remainingDays = 7 - (days.length % 7)
  if (remainingDays < 7) {
    for (let i = 1; i <= remainingDays; i++) {
      const date = new Date(year, month + 1, i)
      days.push({
        date,
        isCurrentMonth: false,
        isToday: false,
        bookings: getBookingsForDate(date)
      })
    }
  }
  
  return days
})

const getBookingsForDate = (date: Date): Booking[] => {
  return filteredBookings.value.filter(booking => {
    const bookingDate = new Date(booking.startTime)
    return bookingDate.toDateString() === date.toDateString()
  }).slice(0, 3) // Mostrar máximo 3 reservas por día
}

const getBookingColor = (status: string): string => {
  switch (status) {
    case 'pending':
      return 'bg-yellow-400 text-yellow-900'
    case 'confirmed':
      return 'bg-blue-500 text-white'
    case 'completed':
      return 'bg-green-500 text-white'
    case 'cancelled':
      return 'bg-red-500 text-white'
    default:
      return 'bg-gray-400 text-white'
  }
}

const formatTime = (dateString: string): string => {
  return new Date(dateString).toLocaleTimeString('es-HN', {
    hour: 'numeric',
    minute: '2-digit',
    hour12: true
  })
}

const previousMonth = () => {
  currentDate.value = new Date(currentDate.value.getFullYear(), currentDate.value.getMonth() - 1, 1)
}

const nextMonth = () => {
  currentDate.value = new Date(currentDate.value.getFullYear(), currentDate.value.getMonth() + 1, 1)
}

const handleViewDetail = (booking: Booking) => {
  selectedBooking.value = booking
  showDetailModal.value = true
}

const loadBookings = async () => {
  try {
    loading.value = true
    
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
  } catch (error: any) {
    console.error('Error loading data:', error)
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  loadBookings()
})
</script>
