<script setup lang="ts">
import { computed, ref } from 'vue'
import SpacesService from '~/services/spaces.service'
import type { Space } from '~/types/space'

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

// Cálculos
const pricePerHour = computed(() => {
  // Por ahora precio fijo, en el futuro vendrá del backend
  if (!space.value) return 0
  // Precio base según capacidad
  return Math.round(space.value.capacity * 15)
})

const subtotal = computed(() => pricePerHour.value * bookingHours.value)
const serviceFee = computed(() => Math.round(subtotal.value * 0.1))
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

const imageUrl = computed(() => {
  if (!space.value) return null
  if (space.value.imageUrl) return space.value.imageUrl
  if (space.value.images && space.value.images.length > 0) return space.value.images[0]
  return null
})

const hasRealImage = computed(() => !!imageUrl.value)

const ownerName = computed(() => {
  if (!space.value?.owner) return 'Propietario verificado'
  return space.value.owner.businessName || space.value.owner.name || 'Propietario verificado'
})

// Navegación
const goBack = () => {
  router.push('/')
}

const handleBooking = () => {
  // TODO: Implementar lógica de reserva
  console.log('Reserva:', {
    spaceId: spaceId.value,
    date: bookingDate.value,
    time: bookingTime.value,
    hours: bookingHours.value,
    total: total.value
  })
}

// Formatear números
const formatCurrency = (value: number) => {
  return new Intl.NumberFormat('es-MX', {
    style: 'currency',
    currency: 'MXN',
    minimumFractionDigits: 0
  }).format(value)
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

      <!-- Título y ubicación -->
      <div>
        <h1 class="text-3xl lg:text-4xl font-black text-gray-900 leading-tight">
          {{ space.name }}
        </h1>
        <div class="mt-3 flex flex-wrap items-center gap-4 text-sm text-gray-600">
          <div class="flex items-center gap-1.5">
            <span class="material-symbols-outlined !text-[20px] text-primary">group</span>
            <span class="font-medium">Capacidad: {{ space.capacity }} personas</span>
          </div>
          <span class="text-gray-300">·</span>
          <div class="flex items-center gap-1.5">
            <span class="material-symbols-outlined !text-[20px] text-primary">store</span>
            <span>{{ ownerName }}</span>
          </div>
          <span class="text-gray-300">·</span>
          <div class="flex items-center gap-1.5">
            <span class="material-symbols-outlined !text-[20px] text-green-500">check_circle</span>
            <span class="text-green-600 font-medium">Disponible</span>
          </div>
        </div>
      </div>

      <!-- Galería de imágenes -->
      <div class="grid grid-cols-1 md:grid-cols-4 gap-2 rounded-xl overflow-hidden h-[400px] md:h-[500px]">
        <!-- Imagen principal -->
        <div class="md:col-span-3 h-full">
          <div v-if="hasRealImage" class="h-full">
            <img 
              :src="imageUrl!" 
              :alt="space.name"
              class="h-full w-full object-cover"
            />
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

        <!-- Miniaturas (placeholders para futuras imágenes) -->
        <div class="hidden md:grid md:grid-rows-2 gap-2 h-full">
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
          <div class="bg-white rounded-xl p-6 shadow-sm border border-gray-200">
            <h2 class="text-2xl font-bold text-gray-900 mb-4">Acerca de este espacio</h2>
            <p class="text-gray-700 leading-relaxed">
              {{ space.description || 'Este espacio está diseñado para ofrecer el ambiente perfecto para tus reuniones, eventos o sesiones de trabajo. Con instalaciones modernas y servicios completos, garantizamos una experiencia profesional y cómoda.' }}
            </p>
            
            <div class="mt-6 grid grid-cols-2 gap-4">
              <div class="flex items-center gap-3 text-gray-700">
                <div class="flex h-10 w-10 items-center justify-center rounded-full bg-blue-100">
                  <span class="material-symbols-outlined text-blue-600">group</span>
                </div>
                <div>
                  <p class="text-xs text-gray-500">Capacidad máxima</p>
                  <p class="font-semibold">{{ space.capacity }} personas</p>
                </div>
              </div>
              
              <div class="flex items-center gap-3 text-gray-700">
                <div class="flex h-10 w-10 items-center justify-center rounded-full bg-green-100">
                  <span class="material-symbols-outlined text-green-600">schedule</span>
                </div>
                <div>
                  <p class="text-xs text-gray-500">Reserva mínima</p>
                  <p class="font-semibold">1 hora</p>
                </div>
              </div>
            </div>
          </div>

          <!-- Características -->
          <div class="bg-white rounded-xl p-6 shadow-sm border border-gray-200">
            <h2 class="text-2xl font-bold text-gray-900 mb-6">Características y servicios</h2>
            <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div 
                v-for="feature in features" 
                :key="feature.icon"
                class="flex items-center gap-3 p-3 rounded-lg bg-gray-50 hover:bg-gray-100 transition"
              >
                <span class="material-symbols-outlined text-primary text-2xl">{{ feature.icon }}</span>
                <span class="text-gray-700 font-medium">{{ feature.label }}</span>
              </div>
            </div>
          </div>

          <!-- Propietario -->
          <div class="bg-white rounded-xl p-6 shadow-sm border border-gray-200">
            <h2 class="text-2xl font-bold text-gray-900 mb-4">Anfitrión del espacio</h2>
            <div class="flex items-center gap-4">
              <div class="flex h-16 w-16 items-center justify-center rounded-full bg-primary/10">
                <span class="material-symbols-outlined text-3xl text-primary">store</span>
              </div>
              <div>
                <p class="text-lg font-bold text-gray-900">{{ ownerName }}</p>
                <p class="text-sm text-gray-600">Propietario verificado</p>
              </div>
            </div>
            <p v-if="space.owner?.businessDescription" class="mt-4 text-gray-700">
              {{ space.owner.businessDescription }}
            </p>
          </div>
        </div>

        <!-- Columna derecha: Panel de reserva -->
        <div class="lg:col-span-1">
          <div class="sticky top-24">
            <div class="bg-white rounded-xl p-6 shadow-lg border border-gray-200">
              <div class="mb-6">
                <div class="flex items-baseline gap-2">
                  <p class="text-3xl font-bold text-gray-900">{{ formatCurrency(pricePerHour) }}</p>
                  <span class="text-gray-600">/ hora</span>
                </div>
                <p class="text-xs text-gray-500 mt-1">Precio estimado</p>
              </div>

              <!-- Formulario de reserva -->
              <div class="space-y-4 mb-6">
                <div>
                  <label class="block text-xs font-semibold text-gray-700 uppercase mb-2">
                    Fecha
                  </label>
                  <input
                    v-model="bookingDate"
                    type="date"
                    class="w-full rounded-lg border border-gray-300 px-4 py-2.5 text-gray-900 focus:border-primary focus:ring-2 focus:ring-primary/20"
                  />
                </div>

                <div>
                  <label class="block text-xs font-semibold text-gray-700 uppercase mb-2">
                    Hora de inicio
                  </label>
                  <input
                    v-model="bookingTime"
                    type="time"
                    class="w-full rounded-lg border border-gray-300 px-4 py-2.5 text-gray-900 focus:border-primary focus:ring-2 focus:ring-primary/20"
                  />
                </div>

                <div>
                  <label class="block text-xs font-semibold text-gray-700 uppercase mb-2">
                    Duración (horas)
                  </label>
                  <input
                    v-model.number="bookingHours"
                    type="number"
                    min="1"
                    max="24"
                    class="w-full rounded-lg border border-gray-300 px-4 py-2.5 text-gray-900 focus:border-primary focus:ring-2 focus:ring-primary/20"
                  />
                </div>
              </div>

              <button
                type="button"
                class="w-full rounded-lg bg-primary px-4 py-3 text-base font-bold text-white hover:bg-primary/90 transition shadow-md"
                :disabled="!bookingDate || !bookingTime"
                @click="handleBooking"
              >
                Reservar ahora
              </button>
              
              <p class="text-center text-xs text-gray-500 mt-3">
                No se te cobrará nada aún
              </p>

              <!-- Desglose de precio -->
              <div class="mt-6 space-y-3 border-t border-gray-200 pt-4">
                <div class="flex justify-between text-sm text-gray-700">
                  <span>{{ formatCurrency(pricePerHour) }} × {{ bookingHours }} {{ bookingHours === 1 ? 'hora' : 'horas' }}</span>
                  <span class="font-medium">{{ formatCurrency(subtotal) }}</span>
                </div>
                <div class="flex justify-between text-sm text-gray-700">
                  <span>Tarifa de servicio</span>
                  <span class="font-medium">{{ formatCurrency(serviceFee) }}</span>
                </div>
                <div class="flex justify-between text-lg font-bold text-gray-900 border-t border-gray-200 pt-3">
                  <span>Total</span>
                  <span>{{ formatCurrency(total) }}</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
