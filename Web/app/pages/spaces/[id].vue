<script setup lang="ts">
import { computed, ref, onMounted, onBeforeUnmount } from 'vue'
import SpacesService from '~/services/spaces.service'
import BookingsService from '~/services/bookings.service'
import type { Space } from '~/types/space'
import type { PaymentMethod } from '~/types/booking'

definePageMeta({
  middleware: 'auth'
})

const route = useRoute()
const router = useRouter()
const { user } = useAuth()

const spaceId = computed(() => route.params.id as string)

// Cargar datos del espacio
const { data: spaceData, pending, error } = await useAsyncData<Space>(
  `space:${spaceId.value}`,
  () => SpacesService.detail(spaceId.value),
  { server: false }
)

const space = computed(() => spaceData.value)

// Datos de la reserva
const bookingDate = ref('')
const bookingTime = ref('')
const bookingHours = ref(1)
const showBookingModal = ref(false)
const selectedPaymentMethod = ref<PaymentMethod>('card')
const paymentChoice = ref<'now' | 'later' | null>(null)
const isSubmitting = ref(false)
const bookingError = ref('')
const bookingSuccess = ref(false)

// Selectores personalizados
const showDatePicker = ref(false)
const showTimePicker = ref(false)
const currentMonth = ref(new Date())
const selectedDate = ref<Date | null>(null)
const selectedTime = ref<string>('')

// Generar días del mes actual
const calendarDays = computed(() => {
  const year = currentMonth.value.getFullYear()
  const month = currentMonth.value.getMonth()
  const firstDay = new Date(year, month, 1)
  const lastDay = new Date(year, month + 1, 0)
  const daysInMonth = lastDay.getDate()
  const startingDayOfWeek = firstDay.getDay()
  
  const days: (Date | null)[] = []
  
  // Días vacíos al inicio
  for (let i = 0; i < startingDayOfWeek; i++) {
    days.push(null)
  }
  
  // Días del mes
  for (let i = 1; i <= daysInMonth; i++) {
    days.push(new Date(year, month, i))
  }
  
  return days
})

// Generar horas disponibles (8:00 AM - 10:00 PM en intervalos de 30 min)
const availableTimes = computed(() => {
  const times: string[] = []
  for (let hour = 8; hour <= 22; hour++) {
    for (let minute of [0, 30]) {
      if (hour === 22 && minute === 30) break // No más de 10:00 PM
      const timeString = `${hour.toString().padStart(2, '0')}:${minute.toString().padStart(2, '0')}`
      times.push(timeString)
    }
  }
  return times
})

// Formatear fecha
const formatDateDisplay = (date: Date | null) => {
  if (!date) return 'Selecciona una fecha'
  return date.toLocaleDateString('es-HN', { 
    weekday: 'short', 
    year: 'numeric', 
    month: 'short', 
    day: 'numeric' 
  })
}

// Formatear hora
const formatTimeDisplay = (time: string) => {
  if (!time) return 'Selecciona una hora'
  const [hour, minute] = time.split(':')
  const hourNum = parseInt(hour)
  const ampm = hourNum >= 12 ? 'PM' : 'AM'
  const hour12 = hourNum > 12 ? hourNum - 12 : hourNum === 0 ? 12 : hourNum
  return `${hour12}:${minute} ${ampm}`
}

// Verificar si una fecha es hoy o pasada
const isDateDisabled = (date: Date | null) => {
  if (!date) return true
  const today = new Date()
  today.setHours(0, 0, 0, 0)
  return date < today
}

// Verificar si una fecha es la seleccionada
const isDateSelected = (date: Date | null) => {
  if (!date || !selectedDate.value) return false
  return date.toDateString() === selectedDate.value.toDateString()
}

// Seleccionar fecha
const selectDate = (date: Date | null) => {
  if (!date || isDateDisabled(date)) return
  selectedDate.value = date
  bookingDate.value = date.toISOString().split('T')[0]
  showDatePicker.value = false
}

// Seleccionar hora
const selectTime = (time: string) => {
  selectedTime.value = time
  bookingTime.value = time
  showTimePicker.value = false
}

// Navegar meses
const previousMonth = () => {
  currentMonth.value = new Date(currentMonth.value.getFullYear(), currentMonth.value.getMonth() - 1, 1)
}

const nextMonth = () => {
  currentMonth.value = new Date(currentMonth.value.getFullYear(), currentMonth.value.getMonth() + 1, 1)
}

// Cerrar pickers al hacer click fuera
const closePickers = () => {
  showDatePicker.value = false
  showTimePicker.value = false
}

// Listener para cerrar pickers al hacer click fuera
onMounted(() => {
  if (process.client) {
    document.addEventListener('click', closePickers)
  }
})

onBeforeUnmount(() => {
  if (process.client) {
    document.removeEventListener('click', closePickers)
  }
})

// Cálculos de precio en Lempiras (Honduras)
const pricePerHour = computed(() => {
  // Por ahora precio fijo, en el futuro vendrá del backend
  if (!space.value) return 0
  // Precio base según capacidad (Lempiras)
  // Espacios pequeños: ~250-400 L/h, medianos: 500-800 L/h, grandes: 1000+ L/h
  if (space.value.capacity <= 10) return 300
  if (space.value.capacity <= 20) return 500
  if (space.value.capacity <= 40) return 800
  if (space.value.capacity <= 80) return 1500
  return 2500
})

const subtotal = computed(() => pricePerHour.value * bookingHours.value)
const serviceFee = computed(() => Math.round(subtotal.value * 0.08)) // 8% tarifa
const total = computed(() => subtotal.value + serviceFee.value)

// Características del espacio
const features = computed(() => {
  if (!space.value) return []
  
  const items = [
    { icon: 'wifi', label: 'Wi-Fi de alta velocidad', enabled: true },
    { icon: 'coffee_maker', label: 'Servicio de café', enabled: space.value.capacity >= 10 },
    { icon: 'ac_unit', label: 'Aire acondicionado', enabled: true },
    { icon: 'local_parking', label: 'Estacionamiento', enabled: space.value.capacity >= 20 },
    { icon: 'videocam', label: 'Proyector HD', enabled: space.value.capacity >= 15 },
    { icon: 'edit_note', label: 'Pizarra blanca', enabled: space.value.capacity >= 8 },
  ]
  
  return items.filter(item => item.enabled)
})

// Placeholder de imagen
const placeholderImage = computed(() => {
  if (!space.value) return 'from-blue-400 to-blue-600'
  
  const colors = [
    'from-blue-400 to-blue-600',
    'from-purple-400 to-purple-600',
    'from-pink-400 to-pink-600',
    'from-indigo-400 to-indigo-600',
    'from-cyan-400 to-cyan-600',
    'from-teal-400 to-teal-600',
  ]
  
  const colorIndex = parseInt(space.value.id.substring(0, 8), 16) % colors.length
  return colors[colorIndex]
})

// Gallery state
const currentImageIndex = ref(0)

const images = computed(() => {
  if (!space.value) return []
  const imgs = space.value.images as any[] | null | undefined
  if (!imgs || imgs.length === 0) return []
  
  return imgs.map((img: any) => {
    if (typeof img === 'string') return img
    if (img && typeof img === 'object' && 'url' in img) return img.url
    return null
  }).filter((url): url is string => !!url)
})

const imageUrl = computed(() => {
  if (!space.value) return null
  if (space.value.imageUrl) return space.value.imageUrl
  if (images.value.length > 0) return images.value[currentImageIndex.value]
  return null
})

const hasRealImage = computed(() => !!imageUrl.value)
const hasMultipleImages = computed(() => images.value.length > 1)

// Gallery navigation
const nextImage = () => {
  if (images.value.length > 0) {
    currentImageIndex.value = (currentImageIndex.value + 1) % images.value.length
  }
}

const prevImage = () => {
  if (images.value.length > 0) {
    currentImageIndex.value = (currentImageIndex.value - 1 + images.value.length) % images.value.length
  }
}

const selectImage = (index: number) => {
  currentImageIndex.value = index
}

const ownerName = computed(() => {
  if (!space.value?.owner) return 'Propietario verificado'
  return space.value.owner.businessName || space.value.owner.name || 'Propietario verificado'
})

// Navegación
const goBack = () => {
  router.push('/')
}

const handleBooking = () => {
  if (!bookingDate.value || !bookingTime.value) {
    return
  }
  bookingError.value = ''
  paymentChoice.value = null
  showBookingModal.value = true
}

const selectPaymentChoice = (choice: 'now' | 'later') => {
  paymentChoice.value = choice
  if (choice === 'later') {
    selectedPaymentMethod.value = 'cash' // Por defecto para pago posterior
  } else {
    selectedPaymentMethod.value = 'card' // Por defecto para pago inmediato
  }
}

const confirmBooking = async () => {
  if (!bookingDate.value || !bookingTime.value) {
    bookingError.value = 'Por favor completa todos los campos requeridos'
    return
  }

  if (!paymentChoice.value) {
    bookingError.value = 'Por favor selecciona una opción de pago'
    return
  }

  isSubmitting.value = true
  bookingError.value = ''

  try {
    const startDateTime = new Date(`${bookingDate.value}T${bookingTime.value}`)
    const endDateTime = new Date(startDateTime.getTime() + bookingHours.value * 60 * 60 * 1000)

    const bookingData = {
      spaceId: spaceId.value,
      startTime: startDateTime.toISOString(),
      endTime: endDateTime.toISOString(),
      paymentMethod: selectedPaymentMethod.value,
      paymentStatus: paymentChoice.value === 'now' ? 'paid' : 'pending',
      totalAmount: total.value,
      subtotal: subtotal.value,
      serviceFee: serviceFee.value,
      pricePerHour: pricePerHour.value,
      durationHours: bookingHours.value
    }

    const booking = await BookingsService.create(bookingData)
    
    bookingSuccess.value = true
    
    setTimeout(() => {
      router.push('/bookings')
    }, 2000)
  } catch (error: any) {
    console.error('Error al crear reserva:', error)
    bookingError.value = error?.data?.message || 'Error al procesar la reserva. Por favor intenta nuevamente.'
  } finally {
    isSubmitting.value = false
  }
}

const closeModal = () => {
  if (!isSubmitting.value) {
    showBookingModal.value = false
    bookingError.value = ''
    bookingSuccess.value = false
    paymentChoice.value = null
  }
}

// Formatear números en Lempiras (Honduras)
const formatCurrency = (value: number) => {
  return new Intl.NumberFormat('es-HN', {
    style: 'currency',
    currency: 'HNL',
    minimumFractionDigits: 2
  }).format(value)
}

const formatNumber = (value: number) => {
  return new Intl.NumberFormat('es-HN').format(value)
}
</script>

<template>
  <div class="min-h-screen bg-gray-50">
    <!-- Loading -->
    <div v-if="pending" class="px-4 sm:px-6 lg:px-8 py-8 max-w-7xl mx-auto">
      <div class="animate-pulse space-y-6">
        <div class="h-8 w-32 bg-gray-200 rounded"></div>
        <div class="h-96 bg-gray-200 rounded-xl"></div>
        <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
          <div class="lg:col-span-2 space-y-6">
            <div class="h-64 bg-gray-200 rounded-lg"></div>
          </div>
          <div class="h-96 bg-gray-200 rounded-lg"></div>
        </div>
      </div>
    </div>

    <!-- Error -->
    <div v-else-if="error || !space" class="px-4 sm:px-6 lg:px-8 py-16 max-w-4xl mx-auto">
      <div class="text-center">
        <div class="mx-auto flex h-24 w-24 items-center justify-center rounded-full bg-red-100">
          <span class="material-symbols-outlined text-4xl text-red-600">error</span>
        </div>
        <h2 class="mt-6 text-2xl font-bold text-gray-900">Espacio no encontrado</h2>
        <p class="mt-2 text-gray-600">El espacio que buscas no existe o no está disponible.</p>
        <button
          type="button"
          class="mt-6 inline-flex items-center gap-2 rounded-lg bg-primary px-6 py-2.5 text-sm font-semibold text-white hover:bg-primary/90"
          @click="goBack"
        >
          <span class="material-symbols-outlined !text-[18px]">arrow_back</span>
          Volver a inicio
        </button>
      </div>
    </div>

    <!-- Contenido principal -->
    <div v-else class="px-4 sm:px-6 lg:px-8 py-8 max-w-7xl mx-auto space-y-6">
      <!-- Breadcrumb y botón volver -->
      <div class="flex items-center gap-4">
        <button
          type="button"
          class="inline-flex items-center gap-2 text-gray-600 hover:text-primary transition"
          @click="goBack"
        >
          <span class="material-symbols-outlined">arrow_back</span>
          <span class="text-sm font-medium">Volver</span>
        </button>
      </div>

      <!-- Título y metadatos -->
      <div class="space-y-4">
        <div>
          <h1 class="text-3xl lg:text-4xl font-black text-gray-900 leading-tight">
            {{ space.name }}
          </h1>
          <div class="mt-3 flex flex-wrap items-center gap-3 text-sm">
            <div class="inline-flex items-center gap-1.5 bg-primary/10 text-primary px-3 py-1.5 rounded-full font-medium">
              <span class="material-symbols-outlined !text-[18px]">group</span>
              <span>{{ formatNumber(space.capacity) }} personas</span>
            </div>
            <div class="inline-flex items-center gap-1.5 bg-green-100 text-green-700 px-3 py-1.5 rounded-full font-medium">
              <span class="h-2 w-2 rounded-full bg-green-500 animate-pulse"></span>
              <span>Disponible ahora</span>
            </div>
            <div class="inline-flex items-center gap-1.5 text-gray-600">
              <span class="material-symbols-outlined !text-[18px]">location_on</span>
              <span>Honduras</span>
            </div>
          </div>
        </div>

        <!-- Info del propietario en header -->
        <div class="flex items-center gap-3 p-4 bg-gray-50 rounded-lg border border-gray-200">
          <div class="flex h-12 w-12 items-center justify-center rounded-full bg-primary/10 flex-shrink-0">
            <span class="material-symbols-outlined text-2xl text-primary">store</span>
          </div>
          <div class="flex-1 min-w-0">
            <p class="font-semibold text-gray-900 truncate">{{ ownerName }}</p>
            <p class="text-xs text-gray-600">Propietario verificado</p>
          </div>
          <div class="flex items-center gap-1 text-sm">
            <span class="material-symbols-outlined !text-[18px] text-yellow-500">verified</span>
          </div>
        </div>
      </div>

      <!-- Galería de imágenes -->
      <div class="grid grid-cols-1 md:grid-cols-4 gap-2 rounded-xl overflow-hidden h-[400px] md:h-[500px]">
        <!-- Imagen principal con controles de navegación -->
        <div class="md:col-span-3 h-full relative group/gallery">
          <div v-if="hasRealImage" class="h-full">
            <img 
              :src="imageUrl!" 
              :alt="space.name"
              class="h-full w-full object-cover"
            />
            
            <!-- Controles de navegación (solo si hay múltiples imágenes) -->
            <template v-if="hasMultipleImages">
              <!-- Botón anterior -->
              <button
                type="button"
                @click="prevImage"
                class="absolute left-4 top-1/2 -translate-y-1/2 z-10 flex h-12 w-12 items-center justify-center rounded-full bg-white/90 text-gray-800 shadow-xl opacity-0 group-hover/gallery:opacity-100 hover:bg-white hover:scale-110 transition-all duration-200"
                aria-label="Imagen anterior"
              >
                <span class="material-symbols-outlined !text-[28px]">chevron_left</span>
              </button>

              <!-- Botón siguiente -->
              <button
                type="button"
                @click="nextImage"
                class="absolute right-4 top-1/2 -translate-y-1/2 z-10 flex h-12 w-12 items-center justify-center rounded-full bg-white/90 text-gray-800 shadow-xl opacity-0 group-hover/gallery:opacity-100 hover:bg-white hover:scale-110 transition-all duration-200"
                aria-label="Imagen siguiente"
              >
                <span class="material-symbols-outlined !text-[28px]">chevron_right</span>
              </button>

              <!-- Contador de imágenes -->
              <div class="absolute bottom-4 right-4 z-10 bg-black/70 text-white px-3 py-1.5 rounded-full text-sm font-medium backdrop-blur">
                {{ currentImageIndex + 1 }} / {{ images.length }}
              </div>
            </template>
          </div>
          <div v-else class="h-full bg-gradient-to-br" :class="placeholderImage">
            <div class="h-full flex items-center justify-center bg-black/10">
              <div class="text-center text-white">
                <span class="material-symbols-outlined text-8xl opacity-60">home_work</span>
                <p class="mt-4 text-xl font-semibold">{{ space.name }}</p>
              </div>
            </div>
          </div>
        </div>

        <!-- Miniaturas de imágenes reales -->
        <div v-if="hasRealImage && images.length > 0" class="hidden md:flex md:flex-col gap-2 h-full overflow-y-auto custom-scrollbar">
          <button
            v-for="(img, index) in images"
            :key="index"
            type="button"
            @click="selectImage(index)"
            :class="[
              'relative flex-shrink-0 rounded-lg overflow-hidden transition-all duration-200 hover:ring-4 hover:ring-primary/50',
              index === currentImageIndex ? 'ring-4 ring-primary' : '',
              images.length === 1 ? 'h-full' : images.length === 2 ? 'h-[calc(50%-4px)]' : 'h-40'
            ]"
          >
            <img 
              :src="img" 
              :alt="`${space.name} - Imagen ${index + 1}`"
              class="h-full w-full object-cover"
            />
            <!-- Overlay cuando está seleccionada -->
            <div 
              v-if="index === currentImageIndex"
              class="absolute inset-0 bg-primary/20 flex items-center justify-center"
            >
              <div class="bg-white rounded-full p-1">
                <span class="material-symbols-outlined text-primary !text-[20px]">check_circle</span>
              </div>
            </div>
          </button>
        </div>

        <!-- Miniaturas placeholder (solo si no hay imágenes reales) -->
        <div v-else class="hidden md:grid md:grid-rows-2 gap-2 h-full">
          <div class="bg-gradient-to-br from-gray-300 to-gray-400 rounded-lg flex items-center justify-center">
            <span class="material-symbols-outlined text-4xl text-white opacity-50">photo_camera</span>
          </div>
          <div class="bg-gradient-to-br from-gray-300 to-gray-400 rounded-lg flex items-center justify-center">
            <span class="material-symbols-outlined text-4xl text-white opacity-50">photo_camera</span>
          </div>
        </div>
      </div>

      <!-- Grid principal -->
      <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
        <!-- Columna izquierda: Detalles -->
        <div class="lg:col-span-2 space-y-8">
          <!-- Descripción -->
          <div class="bg-white rounded-2xl p-8 shadow-sm border border-gray-200">
            <div class="flex items-center gap-3 mb-6">
              <div class="h-10 w-1 bg-primary rounded-full"></div>
              <h2 class="text-2xl font-bold text-gray-900">Acerca de este espacio</h2>
            </div>
            
            <p class="text-gray-700 leading-relaxed text-lg">
              {{ space.description || 'Este espacio está diseñado para ofrecer el ambiente perfecto para tus reuniones, eventos o sesiones de trabajo. Con instalaciones modernas y servicios completos, garantizamos una experiencia profesional y cómoda para ti y tu equipo.' }}
            </p>
            
            <div class="mt-8 grid grid-cols-1 sm:grid-cols-3 gap-4">
              <div class="flex flex-col items-center text-center p-4 bg-gradient-to-br from-blue-50 to-blue-100/50 rounded-xl">
                <div class="flex h-14 w-14 items-center justify-center rounded-full bg-blue-600 mb-3">
                  <span class="material-symbols-outlined text-white text-2xl">group</span>
                </div>
                <p class="text-xs text-gray-600 uppercase font-semibold mb-1">Capacidad</p>
                <p class="text-2xl font-bold text-gray-900">{{ formatNumber(space.capacity) }}</p>
                <p class="text-xs text-gray-600">personas</p>
              </div>
              
              <div class="flex flex-col items-center text-center p-4 bg-gradient-to-br from-green-50 to-green-100/50 rounded-xl">
                <div class="flex h-14 w-14 items-center justify-center rounded-full bg-green-600 mb-3">
                  <span class="material-symbols-outlined text-white text-2xl">schedule</span>
                </div>
                <p class="text-xs text-gray-600 uppercase font-semibold mb-1">Mínimo</p>
                <p class="text-2xl font-bold text-gray-900">1</p>
                <p class="text-xs text-gray-600">hora</p>
              </div>

              <div class="flex flex-col items-center text-center p-4 bg-gradient-to-br from-purple-50 to-purple-100/50 rounded-xl">
                <div class="flex h-14 w-14 items-center justify-center rounded-full bg-purple-600 mb-3">
                  <span class="material-symbols-outlined text-white text-2xl">reply</span>
                </div>
                <p class="text-xs text-gray-600 uppercase font-semibold mb-1">Respuesta</p>
                <p class="text-2xl font-bold text-gray-900">&lt;1</p>
                <p class="text-xs text-gray-600">hora</p>
              </div>
            </div>
          </div>

          <!-- Características -->
          <div class="bg-white rounded-2xl p-8 shadow-sm border border-gray-200">
            <div class="flex items-center gap-3 mb-6">
              <div class="h-10 w-1 bg-primary rounded-full"></div>
              <h2 class="text-2xl font-bold text-gray-900">Lo que incluye</h2>
            </div>
            
            <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
              <div 
                v-for="feature in features" 
                :key="feature.icon"
                class="flex items-center gap-4 p-4 rounded-xl bg-gradient-to-r from-gray-50 to-gray-100/50 border border-gray-200 hover:border-primary hover:shadow-md transition-all duration-200"
              >
                <div class="flex h-12 w-12 items-center justify-center rounded-full bg-primary/10 flex-shrink-0">
                  <span class="material-symbols-outlined text-primary text-xl">{{ feature.icon }}</span>
                </div>
                <span class="text-gray-900 font-semibold">{{ feature.label }}</span>
              </div>
            </div>

            <div class="mt-6 p-4 bg-green-50 border border-green-200 rounded-xl">
              <div class="flex items-start gap-3">
                <span class="material-symbols-outlined text-green-600 text-2xl flex-shrink-0">verified</span>
                <div>
                  <p class="font-semibold text-green-900">Espacio verificado</p>
                  <p class="text-sm text-green-700 mt-1">
                    Todas las características han sido verificadas por nuestro equipo para garantizar tu satisfacción.
                  </p>
                </div>
              </div>
            </div>
          </div>

          <!-- Propietario -->
          <div class="bg-gradient-to-br from-primary/5 via-blue-50 to-white rounded-2xl p-8 shadow-sm border-2 border-primary/20">
            <div class="flex items-center gap-3 mb-6">
              <div class="h-10 w-1 bg-primary rounded-full"></div>
              <h2 class="text-2xl font-bold text-gray-900">Conoce a tu anfitrión</h2>
            </div>

            <div class="flex items-start gap-4 mb-6">
              <div class="flex h-20 w-20 items-center justify-center rounded-2xl bg-gradient-to-br from-primary to-blue-600 shadow-lg flex-shrink-0">
                <span class="material-symbols-outlined text-4xl text-white">store</span>
              </div>
              <div class="flex-1">
                <p class="text-xl font-bold text-gray-900">{{ ownerName }}</p>
                <div class="flex items-center gap-2 mt-2">
                  <span class="inline-flex items-center gap-1 bg-green-100 text-green-700 px-2 py-1 rounded-full text-xs font-semibold">
                    <span class="material-symbols-outlined !text-[14px]">verified</span>
                    Verificado
                  </span>
                  <span class="inline-flex items-center gap-1 bg-blue-100 text-blue-700 px-2 py-1 rounded-full text-xs font-semibold">
                    <span class="material-symbols-outlined !text-[14px]">star</span>
                    Anfitrión destacado
                  </span>
                </div>
              </div>
            </div>

            <p v-if="space.owner?.businessDescription" class="text-gray-700 leading-relaxed mb-6">
              {{ space.owner.businessDescription }}
            </p>
            <p v-else class="text-gray-700 leading-relaxed mb-6">
              Anfitrión profesional comprometido con brindarte la mejor experiencia en su espacio. Responde rápidamente y se asegura de que todo esté en perfecto estado para tu visita.
            </p>

            <div class="grid grid-cols-3 gap-4 mb-6">
              <div class="text-center p-3 bg-white rounded-xl border border-gray-200">
                <p class="text-2xl font-bold text-primary">5.0</p>
                <p class="text-xs text-gray-600 mt-1">Calificación</p>
              </div>
              <div class="text-center p-3 bg-white rounded-xl border border-gray-200">
                <p class="text-2xl font-bold text-primary">24</p>
                <p class="text-xs text-gray-600 mt-1">Reservas</p>
              </div>
              <div class="text-center p-3 bg-white rounded-xl border border-gray-200">
                <p class="text-2xl font-bold text-primary">&lt;1h</p>
                <p class="text-xs text-gray-600 mt-1">Respuesta</p>
              </div>
            </div>

            <button
              type="button"
              class="w-full inline-flex items-center justify-center gap-2 rounded-xl bg-white border-2 border-primary px-6 py-3 text-sm font-bold text-primary hover:bg-primary hover:text-white transition-all duration-200"
            >
              <span class="material-symbols-outlined !text-[20px]">contact_mail</span>
              Enviar mensaje
            </button>
          </div>
        </div>

        <!-- Columna derecha: Panel de reserva -->
        <div class="lg:col-span-1">
          <div class="sticky top-24 space-y-4">
            <!-- Tarjeta de precio -->
            <div class="bg-gradient-to-br from-primary/5 to-blue-50 rounded-2xl p-6 border-2 border-primary/20">
              <div class="flex items-center justify-between mb-2">
                <div>
                  <p class="text-4xl font-black text-gray-900">{{ formatCurrency(pricePerHour) }}</p>
                  <p class="text-sm text-gray-600 mt-1">por hora de uso</p>
                </div>
                <div class="flex items-center gap-1 text-yellow-500">
                  <span class="material-symbols-outlined text-2xl">star</span>
                  <span class="font-bold text-lg text-gray-900">5.0</span>
                </div>
              </div>
              <div class="mt-4 grid grid-cols-3 gap-2 text-center">
                <div class="bg-white/80 rounded-lg p-2">
                  <p class="text-xs text-gray-600">Min.</p>
                  <p class="font-bold text-gray-900">1h</p>
                </div>
                <div class="bg-white/80 rounded-lg p-2">
                  <p class="text-xs text-gray-600">Máx.</p>
                  <p class="font-bold text-gray-900">24h</p>
                </div>
                <div class="bg-white/80 rounded-lg p-2">
                  <p class="text-xs text-gray-600">Resp.</p>
                  <p class="font-bold text-gray-900">1h</p>
                </div>
              </div>
            </div>

            <!-- Formulario de reserva -->
            <div class="bg-white rounded-2xl p-6 shadow-lg border border-gray-200">
              <h3 class="text-lg font-bold text-gray-900 mb-4 flex items-center gap-2">
                <span class="material-symbols-outlined text-primary">calendar_month</span>
                Programa tu visita
              </h3>

              <div class="space-y-4">
                <!-- Fecha con selector personalizado -->
                <div class="relative">
                  <label class="flex items-center gap-2 text-sm font-semibold text-gray-700 mb-2">
                    <span class="material-symbols-outlined !text-[18px] text-primary">event</span>
                    ¿Qué día?
                  </label>
                  <button
                    type="button"
                    class="w-full rounded-lg border-2 px-4 py-3 text-left transition flex items-center justify-between"
                    :class="bookingDate 
                      ? 'border-primary bg-primary/5 text-gray-900' 
                      : 'border-gray-300 text-gray-500 hover:border-gray-400'"
                    @click.stop="showDatePicker = !showDatePicker; showTimePicker = false"
                  >
                    <span class="font-medium">{{ formatDateDisplay(selectedDate) }}</span>
                    <span class="material-symbols-outlined">calendar_today</span>
                  </button>

                  <!-- Calendario desplegable -->
                  <Transition name="dropdown">
                    <div
                      v-if="showDatePicker"
                      class="absolute z-50 mt-2 w-full bg-white rounded-xl shadow-2xl border border-gray-200 p-4"
                      @click.stop
                    >
                      <!-- Header del calendario -->
                      <div class="flex items-center justify-between mb-4">
                        <button
                          type="button"
                          class="p-2 hover:bg-gray-100 rounded-lg transition"
                          @click="previousMonth"
                        >
                          <span class="material-symbols-outlined">chevron_left</span>
                        </button>
                        <h4 class="font-bold text-gray-900">
                          {{ currentMonth.toLocaleDateString('es-HN', { month: 'long', year: 'numeric' }) }}
                        </h4>
                        <button
                          type="button"
                          class="p-2 hover:bg-gray-100 rounded-lg transition"
                          @click="nextMonth"
                        >
                          <span class="material-symbols-outlined">chevron_right</span>
                        </button>
                      </div>

                      <!-- Días de la semana -->
                      <div class="grid grid-cols-7 gap-1 mb-2">
                        <div v-for="day in ['D', 'L', 'M', 'M', 'J', 'V', 'S']" :key="day" class="text-center text-xs font-semibold text-gray-600 py-2">
                          {{ day }}
                        </div>
                      </div>

                      <!-- Días del mes -->
                      <div class="grid grid-cols-7 gap-1">
                        <button
                          v-for="(day, index) in calendarDays"
                          :key="index"
                          type="button"
                          class="aspect-square rounded-lg text-sm font-semibold transition"
                          :class="{
                            'text-gray-400 cursor-not-allowed': !day || isDateDisabled(day),
                            'bg-primary text-white': day && isDateSelected(day),
                            'hover:bg-primary/10 text-gray-900': day && !isDateDisabled(day) && !isDateSelected(day),
                            'invisible': !day
                          }"
                          :disabled="!day || isDateDisabled(day)"
                          @click="selectDate(day)"
                        >
                          {{ day?.getDate() }}
                        </button>
                      </div>
                    </div>
                  </Transition>
                </div>

                <!-- Hora con selector personalizado -->
                <div class="relative">
                  <label class="flex items-center gap-2 text-sm font-semibold text-gray-700 mb-2">
                    <span class="material-symbols-outlined !text-[18px] text-primary">schedule</span>
                    ¿A qué hora?
                  </label>
                  <button
                    type="button"
                    class="w-full rounded-lg border-2 px-4 py-3 text-left transition flex items-center justify-between"
                    :class="bookingTime 
                      ? 'border-primary bg-primary/5 text-gray-900' 
                      : 'border-gray-300 text-gray-500 hover:border-gray-400'"
                    @click.stop="showTimePicker = !showTimePicker; showDatePicker = false"
                  >
                    <span class="font-medium">{{ formatTimeDisplay(selectedTime) }}</span>
                    <span class="material-symbols-outlined">access_time</span>
                  </button>

                  <!-- Selector de hora desplegable -->
                  <Transition name="dropdown">
                    <div
                      v-if="showTimePicker"
                      class="absolute z-50 mt-2 w-full bg-white rounded-xl shadow-2xl border border-gray-200 max-h-64 overflow-y-auto"
                      @click.stop
                    >
                      <div class="p-2">
                        <button
                          v-for="time in availableTimes"
                          :key="time"
                          type="button"
                          class="w-full text-left px-4 py-2.5 rounded-lg font-medium transition"
                          :class="selectedTime === time 
                            ? 'bg-primary text-white' 
                            : 'text-gray-900 hover:bg-gray-100'"
                          @click="selectTime(time)"
                        >
                          {{ formatTimeDisplay(time) }}
                        </button>
                      </div>
                    </div>
                  </Transition>
                </div>

                <!-- Duración con botones rápidos -->
                <div>
                  <label class="flex items-center gap-2 text-sm font-semibold text-gray-700 mb-2">
                    <span class="material-symbols-outlined !text-[18px] text-primary">hourglass_empty</span>
                    ¿Por cuánto tiempo?
                  </label>
                  
                  <!-- Botones rápidos -->
                  <div class="grid grid-cols-4 gap-2 mb-2">
                    <button
                      v-for="h in [1, 2, 4, 8]"
                      :key="h"
                      type="button"
                      class="px-3 py-2 rounded-lg text-sm font-semibold transition"
                      :class="bookingHours === h 
                        ? 'bg-primary text-white' 
                        : 'bg-gray-100 text-gray-700 hover:bg-gray-200'"
                      @click="bookingHours = h"
                    >
                      {{ h }}h
                    </button>
                  </div>
                  
                  <input
                    v-model.number="bookingHours"
                    type="number"
                    min="1"
                    max="24"
                    class="w-full rounded-lg border-2 border-gray-300 px-4 py-3 text-gray-900 focus:border-primary focus:ring-4 focus:ring-primary/10 transition"
                    placeholder="O ingresa las horas"
                  />
                </div>
              </div>

              <!-- Desglose de precio con animación -->
              <div class="mt-6 space-y-3 bg-gray-50 rounded-lg p-4">
                <div class="flex justify-between text-sm text-gray-700">
                  <span class="flex items-center gap-1">
                    <span class="material-symbols-outlined !text-[16px]">payments</span>
                    {{ formatCurrency(pricePerHour) }} × {{ bookingHours }} {{ bookingHours === 1 ? 'hora' : 'horas' }}
                  </span>
                  <span class="font-semibold">{{ formatCurrency(subtotal) }}</span>
                </div>
                <div class="flex justify-between text-sm text-gray-700">
                  <span class="flex items-center gap-1">
                    <span class="material-symbols-outlined !text-[16px]">receipt_long</span>
                    Tarifa de servicio (8%)
                  </span>
                  <span class="font-semibold">{{ formatCurrency(serviceFee) }}</span>
                </div>
                <div class="flex justify-between items-center text-xl font-bold text-gray-900 border-t-2 border-gray-300 pt-3 mt-3">
                  <span>Total a pagar</span>
                  <span class="text-primary">{{ formatCurrency(total) }}</span>
                </div>
              </div>

              <!-- Botón de reserva -->
              <button
                type="button"
                class="mt-6 w-full rounded-xl bg-gradient-to-r from-primary to-blue-600 px-6 py-4 text-base font-bold text-white shadow-lg transition-all duration-200 disabled:opacity-50 disabled:cursor-not-allowed"
                :class="bookingDate && bookingTime ? 'hover:shadow-xl hover:scale-[1.02] active:scale-[0.98]' : ''"
                :disabled="!bookingDate || !bookingTime"
                @click="handleBooking"
              >
                <span v-if="!bookingDate || !bookingTime" class="flex items-center justify-center gap-2">
                  <span class="material-symbols-outlined">lock</span>
                  Completa los datos para reservar
                </span>
                <span v-else class="flex items-center justify-center gap-2">
                  <span class="material-symbols-outlined">check_circle</span>
                  Confirmar reserva por {{ formatCurrency(total) }}
                </span>
              </button>
              
              <div class="mt-4 flex items-start gap-2 text-xs text-gray-600 bg-blue-50 p-3 rounded-lg">
                <span class="material-symbols-outlined !text-[16px] text-blue-600 flex-shrink-0">info</span>
                <p>
                  <strong class="text-blue-900">Reserva sin cargo inmediato.</strong> El propietario confirmará tu solicitud y luego podrás proceder con el pago.
                </p>
              </div>
            </div>

            <!-- Tarjeta de contacto rápido -->
            <div class="bg-white rounded-2xl p-6 border border-gray-200">
              <h3 class="text-sm font-bold text-gray-900 mb-3 flex items-center gap-2">
                <span class="material-symbols-outlined !text-[18px] text-primary">support_agent</span>
                ¿Tienes preguntas?
              </h3>
              <button
                type="button"
                class="w-full inline-flex items-center justify-center gap-2 rounded-lg bg-gray-100 px-4 py-3 text-sm font-semibold text-gray-700 hover:bg-gray-200 transition"
              >
                <span class="material-symbols-outlined !text-[18px]">chat</span>
                Contactar al propietario
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Modal de confirmación de reserva -->
    <Teleport to="body">
      <Transition name="modal">
        <div
          v-if="showBookingModal"
          class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm"
          @click.self="closeModal"
        >
          <div class="bg-white rounded-2xl max-w-lg w-full max-h-[90vh] overflow-y-auto shadow-2xl">
            <!-- Header -->
            <div class="sticky top-0 bg-white border-b border-gray-200 px-6 py-4 flex items-center justify-between">
              <h3 class="text-xl font-bold text-gray-900">Confirmar reserva</h3>
              <button
                type="button"
                class="text-gray-400 hover:text-gray-600 transition"
                :disabled="isSubmitting"
                @click="closeModal"
              >
                <span class="material-symbols-outlined">close</span>
              </button>
            </div>

            <!-- Success State -->
            <div v-if="bookingSuccess" class="p-8 text-center">
              <div class="mx-auto flex h-20 w-20 items-center justify-center rounded-full bg-green-100 mb-4">
                <span class="material-symbols-outlined text-4xl text-green-600">check_circle</span>
              </div>
              <h4 class="text-2xl font-bold text-gray-900 mb-2">¡Reserva creada!</h4>
              <p class="text-gray-600 mb-4">
                Tu solicitud de reserva ha sido enviada al propietario. Te notificaremos cuando sea confirmada.
              </p>
              <p class="text-sm text-gray-500">Redirigiendo a tus reservas...</p>
            </div>

            <!-- Form Content -->
            <div v-else class="p-6 space-y-6">
              <!-- Resumen de reserva -->
              <div class="bg-gray-50 rounded-xl p-4 space-y-3">
                <h4 class="font-semibold text-gray-900 mb-3">Resumen de tu reserva</h4>
                
                <div class="flex items-start gap-3">
                  <span class="material-symbols-outlined text-primary">home_work</span>
                  <div class="flex-1">
                    <p class="font-semibold text-gray-900">{{ space?.name }}</p>
                    <p class="text-sm text-gray-600">{{ space?.address }}</p>
                  </div>
                </div>

                <div class="flex items-center gap-3">
                  <span class="material-symbols-outlined text-primary">event</span>
                  <div>
                    <p class="font-semibold text-gray-900">
                      {{ new Date(bookingDate).toLocaleDateString('es-HN', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' }) }}
                    </p>
                    <p class="text-sm text-gray-600">{{ bookingTime }} por {{ bookingHours }} {{ bookingHours === 1 ? 'hora' : 'horas' }}</p>
                  </div>
                </div>

                <div class="border-t border-gray-200 pt-3 space-y-2">
                  <div class="flex justify-between text-sm">
                    <span class="text-gray-600">Subtotal</span>
                    <span class="font-semibold text-gray-900">{{ formatCurrency(subtotal) }}</span>
                  </div>
                  <div class="flex justify-between text-sm">
                    <span class="text-gray-600">Tarifa de servicio</span>
                    <span class="font-semibold text-gray-900">{{ formatCurrency(serviceFee) }}</span>
                  </div>
                  <div class="flex justify-between text-lg font-bold border-t border-gray-300 pt-2">
                    <span class="text-gray-900">Total</span>
                    <span class="text-primary">{{ formatCurrency(total) }}</span>
                  </div>
                </div>
              </div>

              <!-- Selección de opción de pago -->
              <div v-if="!paymentChoice">
                <label class="block text-sm font-semibold text-gray-700 mb-3">
                  <span class="flex items-center gap-2">
                    <span class="material-symbols-outlined !text-[18px] text-primary">schedule</span>
                    ¿Cuándo deseas pagar?
                  </span>
                </label>
                <div class="grid grid-cols-2 gap-4">
                  <button
                    type="button"
                    class="flex flex-col items-center gap-3 p-6 rounded-xl border-2 border-gray-200 hover:border-primary hover:bg-primary/5 transition group"
                    @click="selectPaymentChoice('now')"
                  >
                    <div class="h-12 w-12 rounded-full bg-green-100 group-hover:bg-green-200 flex items-center justify-center transition">
                      <span class="material-symbols-outlined text-2xl text-green-600">
                        bolt
                      </span>
                    </div>
                    <div class="text-center">
                      <p class="font-bold text-gray-900 mb-1">Pagar ahora</p>
                      <p class="text-xs text-gray-600">Pago digital instantáneo</p>
                    </div>
                  </button>

                  <button
                    type="button"
                    class="flex flex-col items-center gap-3 p-6 rounded-xl border-2 border-gray-200 hover:border-primary hover:bg-primary/5 transition group"
                    @click="selectPaymentChoice('later')"
                  >
                    <div class="h-12 w-12 rounded-full bg-blue-100 group-hover:bg-blue-200 flex items-center justify-center transition">
                      <span class="material-symbols-outlined text-2xl text-blue-600">
                        schedule
                      </span>
                    </div>
                    <div class="text-center">
                      <p class="font-bold text-gray-900 mb-1">Pagar más tarde</p>
                      <p class="text-xs text-gray-600">Antes de tu reserva</p>
                    </div>
                  </button>
                </div>
              </div>

              <!-- Paso 2: Método de pago (solo si eligió "pagar ahora") -->
              <div v-else>
                <!-- Botón para volver -->
                <button
                  type="button"
                  class="flex items-center gap-2 text-sm text-gray-600 hover:text-primary mb-4 transition"
                  @click="paymentChoice = null"
                >
                  <span class="material-symbols-outlined !text-[18px]">arrow_back</span>
                  Cambiar opción de pago
                </button>

                <!-- Si eligió pagar ahora -->
                <div v-if="paymentChoice === 'now'">
                  <label class="block text-sm font-semibold text-gray-700 mb-3">
                    <span class="flex items-center gap-2">
                      <span class="material-symbols-outlined !text-[18px] text-primary">payments</span>
                      Selecciona método de pago digital
                    </span>
                  </label>
                  <div class="grid grid-cols-2 gap-3">
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
                      <span class="text-sm font-semibold" :class="selectedPaymentMethod === 'card' ? 'text-gray-900' : 'text-gray-600'">
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
                      <span class="text-sm font-semibold" :class="selectedPaymentMethod === 'transfer' ? 'text-gray-900' : 'text-gray-600'">
                        Transferencia
                      </span>
                    </button>
                  </div>
                  <div class="mt-4 bg-green-50 border border-green-200 rounded-xl p-4 flex items-start gap-3">
                    <span class="material-symbols-outlined text-green-600">check_circle</span>
                    <div class="flex-1">
                      <p class="text-sm font-semibold text-green-900 mb-1">Pago simulado</p>
                      <p class="text-xs text-green-700">
                        Esta es una simulación. Tu reserva será marcada como "Pagada" instantáneamente para propósitos de demostración.
                      </p>
                    </div>
                  </div>
                </div>

                <!-- Si eligió pagar más tarde -->
                <div v-else-if="paymentChoice === 'later'">
                  <div class="bg-blue-50 border border-blue-200 rounded-xl p-5">
                    <div class="flex items-start gap-3 mb-4">
                      <span class="material-symbols-outlined text-blue-600">info</span>
                      <div class="flex-1">
                        <p class="text-sm font-semibold text-blue-900 mb-2">Instrucciones de pago</p>
                        <ul class="text-sm text-blue-800 space-y-2">
                          <li class="flex items-start gap-2">
                            <span class="material-symbols-outlined !text-[16px] mt-0.5">schedule</span>
                            <span>Debes completar el pago <strong>antes del día de tu reserva</strong></span>
                          </li>
                          <li class="flex items-start gap-2">
                            <span class="material-symbols-outlined !text-[16px] mt-0.5">payments</span>
                            <span>Podrás pagar con efectivo directamente al propietario o mediante transferencia</span>
                          </li>
                          <li class="flex items-start gap-2">
                            <span class="material-symbols-outlined !text-[16px] mt-0.5">notifications</span>
                            <span>Recibirás recordatorios para completar tu pago</span>
                          </li>
                          <li class="flex items-start gap-2">
                            <span class="material-symbols-outlined !text-[16px] mt-0.5">bookmark</span>
                            <span>Puedes gestionar tu pago desde "Mis Reservas"</span>
                          </li>
                        </ul>
                      </div>
                    </div>
                    <div class="bg-white rounded-lg p-3 border border-blue-300">
                      <p class="text-xs text-gray-700">
                        <strong class="text-gray-900">Total a pagar:</strong> 
                        <span class="text-lg font-bold text-primary ml-2">{{ formatCurrency(total) }}</span>
                      </p>
                    </div>
                  </div>
                </div>
              </div>

              <!-- Error message -->
              <div v-if="bookingError" class="bg-red-50 border border-red-200 rounded-xl p-4 flex items-start gap-3">
                <span class="material-symbols-outlined text-red-600">error</span>
                <p class="text-sm text-red-800">{{ bookingError }}</p>
              </div>

              <!-- Actions -->
              <div class="flex gap-3">
                <button
                  type="button"
                  class="flex-1 rounded-xl border-2 border-gray-300 px-6 py-3 font-semibold text-gray-700 hover:bg-gray-50 transition"
                  :disabled="isSubmitting"
                  @click="closeModal"
                >
                  Cancelar
                </button>
                <button
                  type="button"
                  class="flex-1 rounded-xl bg-gradient-to-r from-primary to-blue-600 px-6 py-3 font-semibold text-white hover:shadow-lg transition disabled:opacity-50"
                  :disabled="isSubmitting"
                  @click="confirmBooking"
                >
                  <span v-if="isSubmitting" class="flex items-center justify-center gap-2">
                    <span class="material-symbols-outlined animate-spin">progress_activity</span>
                    Procesando...
                  </span>
                  <span v-else class="flex items-center justify-center gap-2">
                    <span class="material-symbols-outlined">check_circle</span>
                    Confirmar reserva
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
  transform: scale(0.9);
}

.dropdown-enter-active,
.dropdown-leave-active {
  transition: all 0.2s ease;
}

.dropdown-enter-from,
.dropdown-leave-to {
  opacity: 0;
  transform: translateY(-10px);
}

/* Estilos personalizados para el scroll del selector de tiempo */
.dropdown-enter-active div::-webkit-scrollbar,
.dropdown-leave-active div::-webkit-scrollbar {
  width: 6px;
}

.dropdown-enter-active div::-webkit-scrollbar-track,
.dropdown-leave-active div::-webkit-scrollbar-track {
  background: #f1f5f9;
  border-radius: 10px;
}

.dropdown-enter-active div::-webkit-scrollbar-thumb,
.dropdown-leave-active div::-webkit-scrollbar-thumb {
  background: #cbd5e1;
  border-radius: 10px;
}

.dropdown-enter-active div::-webkit-scrollbar-thumb:hover,
.dropdown-leave-active div::-webkit-scrollbar-thumb:hover {
  background: #94a3b8;
}
</style>
