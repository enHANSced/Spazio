<script setup lang="ts">
import { computed } from 'vue'
import type { Space } from '../types/space'

const props = defineProps<{ space: Space }>()

const ownerName = computed(() => props.space.owner?.businessName || props.space.owner?.name || 'Propietario verificado')

const usageBadge = computed(() => {
  if (props.space.capacity >= 80) return { label: 'Eventos masivos', icon: 'celebration' }
  if (props.space.capacity >= 40) return { label: 'Equipos grandes', icon: 'groups' }
  if (props.space.capacity >= 15) return { label: 'Reuniones', icon: 'group' }
  return { label: 'Sesiones privadas', icon: 'person' }
})

const description = computed(() => {
  if (props.space.description?.length) {
    return props.space.description.length > 100 
      ? props.space.description.substring(0, 97) + '...' 
      : props.space.description
  }
  return 'Espacio listo para recibir tus equipos y eventos. Incluye servicios básicos y soporte del propietario.'
})

// Generar placeholder de imagen basado en el ID del espacio para consistencia
const placeholderImage = computed(() => {
  const colors = [
    'from-blue-400 to-blue-600',
    'from-purple-400 to-purple-600',
    'from-pink-400 to-pink-600',
    'from-indigo-400 to-indigo-600',
    'from-cyan-400 to-cyan-600',
    'from-teal-400 to-teal-600',
  ]
  
  // Usar el ID para seleccionar un color consistente
  const colorIndex = parseInt(props.space.id.substring(0, 8), 16) % colors.length
  return colors[colorIndex]
})

// Determinar si usar imagen real o placeholder
const imageUrl = computed(() => {
  // Si hay imageUrl o images[0], usar la imagen real
  if (props.space.imageUrl) return props.space.imageUrl
  const imgs = props.space.images
  if (imgs && imgs.length > 0) {
    const first = imgs[0] as any
    if (typeof first === 'string') return first
    if (first && typeof first === 'object' && 'url' in first) return first.url as string
  }
  // Si no, retornar null para usar placeholder
  return null
})

const hasRealImage = computed(() => !!imageUrl.value)

const amenities = computed(() => {
  const items = []
  
  if (props.space.capacity >= 10) {
    items.push({ icon: 'wifi', label: 'Wi-Fi' })
  }
  
  if (props.space.capacity >= 20) {
    items.push({ icon: 'coffee', label: 'Café' })
  }
  
  if (props.space.capacity >= 50) {
    items.push({ icon: 'mic', label: 'Audio' })
  }
  
  return items
})
</script>

<template>
  <article
    class="group flex h-full flex-col overflow-hidden rounded-xl border border-gray-200 bg-white shadow-sm transition-all duration-300 hover:shadow-xl hover:-translate-y-1"
  >
    <!-- Imagen (con soporte para imágenes reales o placeholder) -->
    <div class="relative aspect-[4/3] w-full overflow-hidden">
      <!-- Imagen real si está disponible -->
      <img 
        v-if="hasRealImage"
        :src="imageUrl!"
        :alt="space.name"
        class="h-full w-full object-cover transition-transform duration-300 group-hover:scale-110"
      />
      
      <!-- Placeholder con gradiente si no hay imagen -->
      <div 
        v-else
        class="h-full w-full bg-gradient-to-br" 
        :class="placeholderImage"
      >
        <!-- Overlay con icono para placeholder -->
        <div class="absolute inset-0 flex items-center justify-center bg-black/10 backdrop-blur-[1px]">
          <div class="flex flex-col items-center gap-2 text-white">
            <span class="material-symbols-outlined text-6xl opacity-60">
              {{ usageBadge.icon }}
            </span>
            <span class="text-xs font-medium uppercase tracking-wider opacity-80">
              {{ space.capacity }} personas
            </span>
          </div>
        </div>
      </div>
      
      <!-- Badge flotante -->
      <div class="absolute left-3 top-3 z-10">
        <span class="inline-flex items-center gap-1.5 rounded-full bg-white/95 px-3 py-1.5 text-xs font-semibold text-gray-800 shadow-md backdrop-blur">
          <span class="material-symbols-outlined !text-[16px] text-primary">{{ usageBadge.icon }}</span>
          {{ usageBadge.label }}
        </span>
      </div>
      
      <!-- Estado de disponibilidad -->
      <div class="absolute right-3 top-3 z-10">
        <span class="inline-flex items-center gap-1 rounded-full bg-green-500/95 px-2.5 py-1 text-xs font-medium text-white shadow-md backdrop-blur">
          <span class="h-1.5 w-1.5 rounded-full bg-white animate-pulse"></span>
          Disponible
        </span>
      </div>
    </div>

    <!-- Contenido -->
    <div class="flex flex-1 flex-col p-4">
      <!-- Título y descripción -->
      <div class="flex-1">
        <h3 class="text-lg font-bold leading-tight text-gray-900 group-hover:text-primary transition-colors">
          {{ space.name }}
        </h3>
        <p class="mt-2 text-sm leading-relaxed text-gray-600">
          {{ description }}
        </p>
      </div>

      <!-- Amenidades -->
      <div v-if="amenities.length" class="mt-4 flex items-center gap-4 text-gray-500">
        <div 
          v-for="amenity in amenities" 
          :key="amenity.icon"
          class="flex items-center gap-1.5 text-xs"
        >
          <span class="material-symbols-outlined !text-[16px]">{{ amenity.icon }}</span>
          <span>{{ amenity.label }}</span>
        </div>
      </div>

      <!-- Propietario y capacidad -->
      <div class="mt-4 flex items-center justify-between border-t border-gray-100 pt-4">
        <div class="flex items-center gap-2">
          <div class="flex h-8 w-8 items-center justify-center rounded-full bg-primary/10">
            <span class="material-symbols-outlined !text-[16px] text-primary">store</span>
          </div>
          <div class="text-xs">
            <p class="font-medium text-gray-900">{{ ownerName }}</p>
            <p class="text-gray-500">Propietario</p>
          </div>
        </div>
        
        <div class="text-right">
          <p class="text-xs text-gray-500">Capacidad</p>
          <p class="text-lg font-bold text-gray-900">{{ space.capacity }}</p>
        </div>
      </div>

      <!-- Botón de acción -->
      <NuxtLink
        :to="`/spaces/${space.id}`"
        class="mt-4 w-full inline-flex items-center justify-center gap-2 rounded-lg bg-primary px-4 py-2.5 text-sm font-semibold text-white shadow-md transition-all hover:bg-primary/90 hover:shadow-lg"
      >
        Ver detalles
        <span class="material-symbols-outlined !text-[18px]">arrow_forward</span>
      </NuxtLink>
    </div>
  </article>
</template>
