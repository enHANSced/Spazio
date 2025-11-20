<script setup lang="ts">
import { computed } from 'vue'
import type { Space } from '../../types/space'

const props = defineProps<{ space: Space }>()

const emit = defineEmits<{
  edit: []
  delete: []
  toggleStatus: []
}>()

const usageBadge = computed(() => {
  if (props.space.capacity >= 80) return { label: 'Eventos masivos', icon: 'celebration' }
  if (props.space.capacity >= 40) return { label: 'Equipos grandes', icon: 'groups' }
  if (props.space.capacity >= 15) return { label: 'Reuniones', icon: 'group' }
  return { label: 'Sesiones privadas', icon: 'person' }
})

const description = computed(() => {
  if (props.space.description?.length) {
    return props.space.description.length > 120 
      ? props.space.description.substring(0, 117) + '...' 
      : props.space.description
  }
  return 'Espacio listo para recibir equipos y eventos.'
})

const placeholderImage = computed(() => {
  const colors = [
    'from-blue-400 to-blue-600',
    'from-purple-400 to-purple-600',
    'from-pink-400 to-pink-600',
    'from-indigo-400 to-indigo-600',
    'from-cyan-400 to-cyan-600',
    'from-teal-400 to-teal-600',
  ]
  
  const colorIndex = parseInt(props.space.id.substring(0, 8), 16) % colors.length
  return colors[colorIndex]
})

const imageUrl = computed(() => {
  if (props.space.imageUrl) return props.space.imageUrl
  const imgs = props.space.images as any
  if (imgs && imgs.length > 0) {
    const first = imgs[0]
    if (typeof first === 'string') return first
    if (first && typeof first === 'object' && 'url' in first) return first.url as string
  }
  return null
})

const hasRealImage = computed(() => !!imageUrl.value)
</script>

<template>
  <article
    class="group flex h-full flex-col overflow-hidden rounded-xl border border-slate-200 bg-white shadow-sm transition-all duration-300 hover:shadow-lg"
  >
    <!-- Imagen -->
    <div class="relative aspect-[4/3] w-full overflow-hidden">
      <img 
        v-if="hasRealImage"
        :src="imageUrl!"
        :alt="space.name"
        class="h-full w-full object-cover"
      />
      
      <div 
        v-else
        class="h-full w-full bg-gradient-to-br" 
        :class="placeholderImage"
      >
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
      
      <!-- Badge de estado -->
      <div class="absolute right-3 top-3 z-10">
        <span 
          class="inline-flex items-center gap-1 rounded-full px-2.5 py-1 text-xs font-medium shadow-md backdrop-blur"
          :class="space.isActive ? 'bg-green-500/95 text-white' : 'bg-slate-500/95 text-white'"
        >
          <span class="h-1.5 w-1.5 rounded-full" :class="space.isActive ? 'bg-white' : 'bg-slate-300'"></span>
          {{ space.isActive ? 'Activo' : 'Inactivo' }}
        </span>
      </div>

      <!-- Acciones hover -->
      <div class="absolute inset-0 flex items-center justify-center gap-2 bg-black/50 opacity-0 transition-opacity group-hover:opacity-100">
        <button
          class="flex h-10 w-10 items-center justify-center rounded-full bg-white text-primary shadow-lg transition hover:bg-primary hover:text-white"
          title="Editar espacio"
          @click.stop="emit('edit')"
        >
          <span class="material-symbols-outlined text-xl">edit</span>
        </button>
        
        <NuxtLink
          :to="`/spaces/${space.id}`"
          target="_blank"
          class="flex h-10 w-10 items-center justify-center rounded-full bg-white text-slate-700 shadow-lg transition hover:bg-slate-100"
          title="Ver como usuario"
        >
          <span class="material-symbols-outlined text-xl">visibility</span>
        </NuxtLink>
        
        <button
          class="flex h-10 w-10 items-center justify-center rounded-full bg-white shadow-lg transition"
          :class="space.isActive ? 'text-slate-600 hover:bg-slate-100' : 'text-green-600 hover:bg-green-50'"
          :title="space.isActive ? 'Desactivar' : 'Activar'"
          @click.stop="emit('toggleStatus')"
        >
          <span class="material-symbols-outlined text-xl">
            {{ space.isActive ? 'toggle_on' : 'toggle_off' }}
          </span>
        </button>
      </div>
    </div>

    <!-- Contenido -->
    <div class="flex flex-1 flex-col p-4">
      <div class="flex-1">
        <div class="flex items-start justify-between gap-2">
          <h3 class="flex-1 text-lg font-bold leading-tight text-[#111418]">
            {{ space.name }}
          </h3>
          <span class="inline-flex items-center gap-1 text-xs text-slate-500">
            <span class="material-symbols-outlined !text-[14px]">{{ usageBadge.icon }}</span>
            {{ usageBadge.label }}
          </span>
        </div>
        
        <p class="mt-2 text-sm leading-relaxed text-slate-600">
          {{ description }}
        </p>
      </div>

      <!-- Footer -->
      <div class="mt-4 flex items-center justify-between border-t border-slate-100 pt-4">
        <div class="flex items-center gap-2 text-slate-600">
          <span class="material-symbols-outlined !text-[18px]">groups</span>
          <span class="text-sm font-medium">{{ space.capacity }} personas</span>
        </div>
        
        <button
          class="flex items-center gap-1 text-sm font-medium text-rose-600 transition hover:text-rose-700"
          @click.stop="emit('delete')"
        >
          <span class="material-symbols-outlined !text-[18px]">delete</span>
          Eliminar
        </button>
      </div>
    </div>
  </article>
</template>
