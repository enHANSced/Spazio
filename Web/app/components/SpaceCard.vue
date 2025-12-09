<script setup lang="ts">
import { computed, ref } from 'vue'
import type { Space } from '../types/space'

const props = defineProps<{ space: Space }>()

const ownerName = computed(() => props.space.owner?.businessName || props.space.owner?.name || 'Propietario verificado')

// Mapeo de categorías a etiquetas, iconos y gradientes
type CategoryBadge = { label: string; icon: string; gradient: string }

const categoryMap: Record<string, CategoryBadge> = {
  private: { label: 'Privado', icon: 'meeting_room', gradient: 'from-violet-500 to-purple-600' },
  meetings: { label: 'Reuniones', icon: 'groups', gradient: 'from-blue-500 to-indigo-600' },
  teams: { label: 'Equipos', icon: 'diversity_3', gradient: 'from-cyan-500 to-blue-600' },
  events: { label: 'Eventos', icon: 'celebration', gradient: 'from-pink-500 to-rose-600' },
  coworking: { label: 'Coworking', icon: 'laptop_mac', gradient: 'from-emerald-500 to-teal-600' },
  studio: { label: 'Estudio', icon: 'videocam', gradient: 'from-amber-500 to-orange-600' },
  training: { label: 'Capacitación', icon: 'school', gradient: 'from-indigo-500 to-violet-600' }
}

const usageBadge = computed((): CategoryBadge => {
  if (props.space.category && categoryMap[props.space.category]) {
    return categoryMap[props.space.category]!
  }
  if (props.space.capacity >= 80) return categoryMap.events!
  if (props.space.capacity >= 40) return categoryMap.teams!
  if (props.space.capacity >= 15) return categoryMap.meetings!
  return categoryMap.private!
})

const description = computed(() => {
  if (props.space.description?.length) {
    return props.space.description.length > 85 
      ? props.space.description.substring(0, 82) + '...' 
      : props.space.description
  }
  return 'Espacio listo para recibir tus equipos y eventos.'
})

// Formatear precio
const formattedPrice = computed(() => {
  if (!props.space.pricePerHour) return null
  return new Intl.NumberFormat('es-HN', {
    style: 'currency',
    currency: 'HNL',
    minimumFractionDigits: 0,
    maximumFractionDigits: 0
  }).format(props.space.pricePerHour)
})

// Generar placeholder de imagen
const placeholderGradient = computed(() => {
  const colors = [
    'from-blue-400 via-blue-500 to-indigo-600',
    'from-purple-400 via-purple-500 to-violet-600',
    'from-pink-400 via-pink-500 to-rose-600',
    'from-indigo-400 via-indigo-500 to-blue-600',
    'from-cyan-400 via-cyan-500 to-teal-600',
    'from-teal-400 via-teal-500 to-emerald-600',
  ]
  
  const colorIndex = parseInt(props.space.id.substring(0, 8), 16) % colors.length
  return colors[colorIndex]
})

// Carousel state
const currentImageIndex = ref(0)

const images = computed(() => {
  const imgs = props.space.images
  if (!imgs || imgs.length === 0) return []
  
  return imgs.map((img: any) => {
    if (typeof img === 'string') return img
    if (img && typeof img === 'object' && 'url' in img) return img.url
    return null
  }).filter((url): url is string => !!url)
})

const imageUrl = computed(() => {
  if (props.space.imageUrl) return props.space.imageUrl
  if (images.value.length > 0) return images.value[currentImageIndex.value]
  return null
})

const hasRealImage = computed(() => !!imageUrl.value)
const hasMultipleImages = computed(() => images.value.length > 1)

// Carousel navigation
const nextImage = (e: Event) => {
  e.preventDefault()
  e.stopPropagation()
  if (images.value.length > 0) {
    currentImageIndex.value = (currentImageIndex.value + 1) % images.value.length
  }
}

const prevImage = (e: Event) => {
  e.preventDefault()
  e.stopPropagation()
  if (images.value.length > 0) {
    currentImageIndex.value = (currentImageIndex.value - 1 + images.value.length) % images.value.length
  }
}

const goToImage = (index: number, e: Event) => {
  e.preventDefault()
  e.stopPropagation()
  currentImageIndex.value = index
}

// Amenidades con iconos
const amenityIcons: Record<string, string> = {
  wifi: 'wifi', 'wi-fi': 'wifi',
  coffee: 'coffee', café: 'coffee',
  parking: 'local_parking', estacionamiento: 'local_parking',
  projector: 'cast', proyector: 'cast',
  'air conditioning': 'ac_unit', 'aire acondicionado': 'ac_unit',
  kitchen: 'kitchen', cocina: 'kitchen',
  audio: 'mic', sonido: 'mic',
  whiteboard: 'edit_note', pizarra: 'edit_note',
  tv: 'tv', televisión: 'tv',
  printer: 'print', impresora: 'print'
}

const displayAmenities = computed(() => {
  const items: { icon: string; label: string }[] = []
  
  if (props.space.amenities && props.space.amenities.length > 0) {
    for (const amenity of props.space.amenities.slice(0, 3)) {
      const lowerAmenity = amenity.toLowerCase()
      let icon = 'check_circle'
      
      for (const [key, iconName] of Object.entries(amenityIcons)) {
        if (lowerAmenity.includes(key)) {
          icon = iconName
          break
        }
      }
      
      items.push({ icon, label: amenity })
    }
  } else {
    if (props.space.capacity >= 10) items.push({ icon: 'wifi', label: 'Wi-Fi' })
    if (props.space.capacity >= 20) items.push({ icon: 'ac_unit', label: 'A/C' })
    if (props.space.capacity >= 40) items.push({ icon: 'mic', label: 'Audio' })
  }
  
  return items.slice(0, 3)
})

// Ubicación formateada
const locationText = computed(() => {
  if (props.space.address && props.space.city) {
    return props.space.city
  }
  if (props.space.address) {
    return props.space.address.length > 20 ? props.space.address.substring(0, 17) + '...' : props.space.address
  }
  if (props.space.city) return props.space.city
  return null
})
</script>

<template>
  <article
    class="group relative flex h-full flex-col overflow-hidden rounded-2xl bg-white shadow-lg ring-1 ring-black/5 transition-all duration-300 hover:shadow-2xl hover:shadow-primary/10 hover:-translate-y-1"
  >
    <!-- Borde gradiente en hover -->
    <div 
      class="pointer-events-none absolute inset-0 rounded-2xl opacity-0 group-hover:opacity-100 transition-opacity duration-300"
      :class="`bg-gradient-to-br ${usageBadge.gradient}`"
      style="padding: 2px; z-index: 0;"
    >
      <div class="h-full w-full rounded-2xl bg-white"></div>
    </div>

    <!-- Contenido principal -->
    <div class="relative z-10 flex h-full flex-col">
      <!-- Imagen con Carousel -->
      <div class="relative aspect-[16/10] w-full overflow-hidden group/carousel">
        <!-- Imagen real -->
        <img 
          v-if="hasRealImage"
          :src="imageUrl!"
          :alt="space.name"
          class="h-full w-full object-cover transition-transform duration-500 group-hover:scale-105"
        />
        
        <!-- Placeholder con gradiente -->
        <div 
          v-else
          class="h-full w-full bg-gradient-to-br" 
          :class="placeholderGradient"
        >
          <div class="absolute inset-0 flex items-center justify-center">
            <div class="flex flex-col items-center gap-3 text-white">
              <div class="flex h-20 w-20 items-center justify-center rounded-2xl bg-white/20 backdrop-blur-sm">
                <span class="material-symbols-outlined text-5xl">{{ usageBadge.icon }}</span>
              </div>
              <span class="text-sm font-medium opacity-90">{{ space.capacity }} personas</span>
            </div>
          </div>
        </div>

        <!-- Overlay degradado inferior -->
        <div class="absolute inset-x-0 bottom-0 h-24 bg-gradient-to-t from-black/60 via-black/20 to-transparent"></div>

        <!-- Controles de navegación del carousel -->
        <template v-if="hasMultipleImages">
          <button
            type="button"
            @click="prevImage"
            class="absolute left-3 top-1/2 -translate-y-1/2 z-20 flex h-9 w-9 items-center justify-center rounded-full bg-white/95 text-gray-800 shadow-lg opacity-0 group-hover/carousel:opacity-100 hover:bg-white hover:scale-110 transition-all duration-200"
            aria-label="Imagen anterior"
          >
            <span class="material-symbols-outlined !text-[20px]">chevron_left</span>
          </button>

          <button
            type="button"
            @click="nextImage"
            class="absolute right-3 top-1/2 -translate-y-1/2 z-20 flex h-9 w-9 items-center justify-center rounded-full bg-white/95 text-gray-800 shadow-lg opacity-0 group-hover/carousel:opacity-100 hover:bg-white hover:scale-110 transition-all duration-200"
            aria-label="Imagen siguiente"
          >
            <span class="material-symbols-outlined !text-[20px]">chevron_right</span>
          </button>

          <div class="absolute bottom-14 left-1/2 -translate-x-1/2 z-20 flex items-center gap-1.5">
            <button
              v-for="(img, index) in images"
              :key="index"
              type="button"
              @click="(e) => goToImage(index, e)"
              :class="[
                'h-1.5 rounded-full transition-all duration-200',
                index === currentImageIndex 
                  ? 'w-6 bg-white' 
                  : 'w-1.5 bg-white/60 hover:bg-white/80'
              ]"
              :aria-label="`Ir a imagen ${index + 1}`"
            />
          </div>
        </template>
        
        <!-- Badge de categoría con gradiente -->
        <div class="absolute left-3 top-3 z-10">
          <span 
            class="inline-flex items-center gap-1.5 rounded-xl px-3 py-1.5 text-xs font-bold text-white shadow-lg backdrop-blur-sm bg-gradient-to-r"
            :class="usageBadge.gradient"
          >
            <span class="material-symbols-outlined !text-[16px]">{{ usageBadge.icon }}</span>
            {{ usageBadge.label }}
          </span>
        </div>
        
        <!-- Badge de disponibilidad 
        <div class="absolute right-3 top-3 z-10">
          <span class="inline-flex items-center gap-1.5 rounded-xl bg-emerald-500 px-2.5 py-1.5 text-xs font-bold text-white shadow-lg">
            <span class="relative flex h-2 w-2">
              <span class="animate-ping absolute inline-flex h-full w-full rounded-full bg-white opacity-75"></span>
              <span class="relative inline-flex rounded-full h-2 w-2 bg-white"></span>
            </span>
            Disponible
          </span>
        </div>-->

        <!-- Precio destacado sobre la imagen -->
        <div v-if="formattedPrice" class="absolute bottom-3 right-3 z-10">
          <div class="flex items-baseline gap-1 rounded-xl bg-white/95 px-3 py-2 shadow-lg backdrop-blur-sm">
            <span class="text-xl font-black text-gray-900">{{ formattedPrice }}</span>
            <span class="text-xs font-medium text-gray-500">/hora</span>
          </div>
        </div>

        <!-- Ubicación sobre la imagen -->
        <div v-if="locationText" class="absolute bottom-3 left-3 z-10">
          <div class="flex items-center gap-1.5 rounded-xl bg-black/50 px-3 py-1.5 text-white backdrop-blur-sm">
            <span class="material-symbols-outlined !text-[16px]">location_on</span>
            <span class="text-xs font-medium">{{ locationText }}</span>
          </div>
        </div>
      </div>

      <!-- Contenido -->
      <div class="flex flex-1 flex-col p-5">
        <!-- Título y descripción -->
        <div class="flex-1">
          <h3 class="text-lg font-bold leading-tight text-gray-900 group-hover:text-primary transition-colors line-clamp-1">
            {{ space.name }}
          </h3>
          <p class="mt-2 text-sm leading-relaxed text-gray-600 line-clamp-2">
            {{ description }}
          </p>
        </div>

        <!-- Stats rápidas con diseño premium -->
        <div class="mt-4 grid grid-cols-3 gap-2">
          <!-- Capacidad -->
          <div class="group/stat relative overflow-hidden rounded-xl bg-gradient-to-br from-blue-50 to-blue-100/50 p-3 ring-1 ring-blue-200/50">
            <div class="absolute -right-2 -top-2 h-10 w-10 rounded-full bg-blue-400/10 blur-xl"></div>
            <div class="relative flex flex-col items-center">
              <span class="material-symbols-outlined text-blue-600 !text-[20px]">group</span>
              <span class="mt-1 text-sm font-bold text-gray-900">{{ space.capacity }}</span>
              <span class="text-[10px] font-medium text-gray-500 uppercase tracking-wide">personas</span>
            </div>
          </div>

          <!-- Precio mini -->
          <div 
            v-if="formattedPrice" 
            class="group/stat relative overflow-hidden rounded-xl bg-gradient-to-br from-emerald-50 to-emerald-100/50 p-3 ring-1 ring-emerald-200/50"
          >
            <div class="absolute -right-2 -top-2 h-10 w-10 rounded-full bg-emerald-400/10 blur-xl"></div>
            <div class="relative flex flex-col items-center">
              <span class="material-symbols-outlined text-emerald-600 !text-[20px]">payments</span>
              <span class="mt-1 text-sm font-bold text-gray-900">{{ space.pricePerHour }}</span>
              <span class="text-[10px] font-medium text-gray-500 uppercase tracking-wide">L/hora</span>
            </div>
          </div>
          <div 
            v-else 
            class="group/stat relative overflow-hidden rounded-xl bg-gradient-to-br from-gray-50 to-gray-100/50 p-3 ring-1 ring-gray-200/50"
          >
            <div class="absolute -right-2 -top-2 h-10 w-10 rounded-full bg-gray-400/10 blur-xl"></div>
            <div class="relative flex flex-col items-center">
              <span class="material-symbols-outlined text-gray-500 !text-[20px]">info</span>
              <span class="mt-1 text-xs font-semibold text-gray-600">Consultar</span>
              <span class="text-[10px] font-medium text-gray-500 uppercase tracking-wide">precio</span>
            </div>
          </div>

          <!-- Amenidades -->
          <div class="group/stat relative overflow-hidden rounded-xl bg-gradient-to-br from-purple-50 to-purple-100/50 p-3 ring-1 ring-purple-200/50">
            <div class="absolute -right-2 -top-2 h-10 w-10 rounded-full bg-purple-400/10 blur-xl"></div>
            <div class="relative flex flex-col items-center">
              <div class="flex -space-x-1">
                <span 
                  v-for="(amenity, idx) in displayAmenities.slice(0, 2)" 
                  :key="idx"
                  class="material-symbols-outlined text-purple-600 !text-[16px]"
                >
                  {{ amenity.icon }}
                </span>
              </div>
              <span class="mt-1 text-sm font-bold text-gray-900">{{ displayAmenities.length }}+</span>
              <span class="text-[10px] font-medium text-gray-500 uppercase tracking-wide">servicios</span>
            </div>
          </div>
        </div>

        <!-- Propietario -->
        <div class="mt-4 flex items-center gap-3 rounded-xl bg-gray-50 p-3">
          <div class="flex h-10 w-10 items-center justify-center rounded-xl bg-gradient-to-br from-primary to-primary-dark shadow-md shadow-primary/20">
            <span class="material-symbols-outlined text-white !text-[20px]">store</span>
          </div>
          <div class="flex-1 min-w-0">
            <p class="font-semibold text-gray-900 text-sm truncate">{{ ownerName }}</p>
            <div class="flex items-center gap-1 text-xs text-gray-500">
              <span class="material-symbols-outlined !text-[14px] text-emerald-500">verified</span>
              Propietario verificado
            </div>
          </div>
        </div>

        <!-- Botón de acción premium -->
        <NuxtLink
          :to="`/spaces/${space.id}`"
          class="group/btn mt-4 relative overflow-hidden w-full inline-flex items-center justify-center gap-2 rounded-xl bg-gradient-to-r from-primary via-primary-dark to-blue-300 px-5 py-3.5 text-sm font-bold text-white shadow-lg shadow-primary/30 transition-all duration-300 hover:shadow-xl hover:shadow-primary/40"
        >
          <span class="relative z-10">Ver detalles y reservar</span>
          <span class="material-symbols-outlined !text-[20px] relative z-10 transition-transform group-hover/btn:translate-x-1">arrow_forward</span>
          
          <!-- Efecto shine en hover -->
          <div class="absolute inset-0 -translate-x-full group-hover/btn:translate-x-full transition-transform duration-700 bg-gradient-to-r from-transparent via-white/20 to-transparent skew-x-12"></div>
        </NuxtLink>
      </div>
    </div>
  </article>
</template>

<style scoped>
.line-clamp-1 {
  display: -webkit-box;
  -webkit-line-clamp: 1;
  line-clamp: 1;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.line-clamp-2 {
  display: -webkit-box;
  -webkit-line-clamp: 2;
  line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}
</style>
