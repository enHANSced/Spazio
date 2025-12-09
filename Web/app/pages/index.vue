<script setup lang="ts">
import { computed, ref } from 'vue'
import SpacesService from '~/services/spaces.service'
import type { Space } from '~/types/space'

definePageMeta({
  middleware: 'auth'
})

useSeoMeta({
  title: 'Explorar Espacios - Spazio',
  description: 'Descubre y reserva espacios increíbles para tu próximo evento, reunión o proyecto'
})

const { user, logout } = useAuth()

const searchQuery = ref('')
const minCapacity = ref<number | null>(null)
const maxCapacity = ref<number | null>(null)
const sortOption = ref<'recent' | 'capacity' | 'name' | 'price'>('recent')
const viewMode = ref<'grid' | 'list'>('grid')
const selectedSizeFilter = ref<'all' | 'small' | 'medium' | 'large'>('all')
const selectedCategory = ref<string | null>(null)

// Categorías de espacios con iconos y descripciones amigables
const spaceCategories = [
  { value: 'coworking', label: 'Coworking', icon: 'laptop_mac', color: 'blue', description: 'Espacios de trabajo compartido' },
  { value: 'meetings', label: 'Reuniones', icon: 'groups', color: 'indigo', description: 'Salas para juntas y presentaciones' },
  { value: 'private', label: 'Privado', icon: 'meeting_room', color: 'emerald', description: 'Espacios íntimos 1-10 personas' },
  { value: 'events', label: 'Eventos', icon: 'celebration', color: 'pink', description: 'Salones para eventos y celebraciones' },
  { value: 'training', label: 'Capacitación', icon: 'school', color: 'amber', description: 'Aulas y salas de formación' },
  { value: 'studio', label: 'Estudio', icon: 'videocam', color: 'purple', description: 'Fotografía, grabación y producción' },
  { value: 'teams', label: 'Equipos', icon: 'diversity_3', color: 'orange', description: 'Espacios amplios para grupos grandes' },
]

const { data: spacesData, pending, error: spacesError, refresh } = await useAsyncData<Space[]>(
  'spaces:list',
  () => SpacesService.list(),
  { server: false }
)

const spaces = computed(() => spacesData.value ?? [])

const statsSummary = computed(() => {
  const activeSpaces = spaces.value.filter((space) => space.isActive)
  const totalCapacity = spaces.value.reduce((sum, space) => sum + space.capacity, 0)
  const averageCapacity = spaces.value.length ? Math.round(totalCapacity / spaces.value.length) : 0
  const highCapacity = activeSpaces.filter((space) => space.capacity >= 50).length

  return {
    totalActive: activeSpaces.length,
    averageCapacity,
    highCapacity
  }
})

// Conteo por tamaño (capacidad)
const sizeFilters = computed(() => {
  const active = spaces.value.filter(s => s.isActive)
  return {
    small: active.filter(s => s.capacity < 20).length,
    medium: active.filter(s => s.capacity >= 20 && s.capacity < 50).length,
    large: active.filter(s => s.capacity >= 50).length
  }
})

// Conteo por categoría real
const categoryCountMap = computed(() => {
  const active = spaces.value.filter(s => s.isActive)
  const counts: Record<string, number> = {}
  for (const cat of spaceCategories) {
    counts[cat.value] = active.filter(s => s.category === cat.value).length
  }
  return counts
})

const normalizeText = (value?: string | null) => value?.toLowerCase().trim() ?? ''
const getTimestamp = (space: Space) => {
  const target = space.updatedAt || space.createdAt
  const time = target ? Date.parse(target) : 0
  return Number.isNaN(time) ? 0 : time
}

const filteredSpaces = computed(() => {
  const query = normalizeText(searchQuery.value)

  return spaces.value
    .filter((space) => space.isActive)
    .filter((space) => {
      if (!query) return true
      const haystack = [space.name, space.description, space.owner?.businessName, space.owner?.name]
        .map(normalizeText)
        .join(' ')
      return haystack.includes(query)
    })
    .filter((space) => {
      if (minCapacity.value && space.capacity < minCapacity.value) return false
      if (maxCapacity.value && space.capacity > maxCapacity.value) return false
      return true
    })
    .filter((space) => {
      // Filtro por tamaño
      if (selectedSizeFilter.value !== 'all') {
        if (selectedSizeFilter.value === 'small' && space.capacity >= 20) return false
        if (selectedSizeFilter.value === 'medium' && (space.capacity < 20 || space.capacity >= 50)) return false
        if (selectedSizeFilter.value === 'large' && space.capacity < 50) return false
      }
      // Filtro por categoría
      if (selectedCategory.value && space.category !== selectedCategory.value) return false
      return true
    })
    .sort((a, b) => {
      if (sortOption.value === 'capacity') return b.capacity - a.capacity
      if (sortOption.value === 'name') return a.name.localeCompare(b.name)
      if (sortOption.value === 'price') return (a.pricePerHour || 0) - (b.pricePerHour || 0)
      return getTimestamp(b) - getTimestamp(a)
    })
})

const featuredSpaces = computed(() => filteredSpaces.value.slice(0, 3))
const secondarySpaces = computed(() => filteredSpaces.value.slice(featuredSpaces.value.length))

const capacityInput = computed({
  get: () => (minCapacity.value ?? '') as number | string,
  set: (value: number | string) => {
    if (value === '' || value === null) {
      minCapacity.value = null
      return
    }
    const numeric = Number(value)
    minCapacity.value = Number.isFinite(numeric) && numeric > 0 ? Math.round(numeric) : null
  }
})

const errorMessage = computed(() => spacesError.value?.message ?? null)
const isRefreshing = ref(false)
const isSearching = ref(false)
const resultsRef = ref<HTMLElement | null>(null)

const reloadSpaces = async () => {
  if (isRefreshing.value) return
  isRefreshing.value = true
  try {
    await refresh()
  } finally {
    isRefreshing.value = false
  }
}

const handleSearch = async () => {
  isSearching.value = true
  
  // Pequeño delay para efecto visual
  await new Promise(resolve => setTimeout(resolve, 300))
  
  // Scroll suave a los resultados
  if (resultsRef.value) {
    resultsRef.value.scrollIntoView({ 
      behavior: 'smooth', 
      block: 'start',
      inline: 'nearest'
    })
  }
  
  isSearching.value = false
}

const handleSearchKeypress = (event: KeyboardEvent) => {
  if (event.key === 'Enter') {
    handleSearch()
  }
}

const resetFilters = () => {
  searchQuery.value = ''
  minCapacity.value = null
  maxCapacity.value = null
  sortOption.value = 'recent'
  selectedSizeFilter.value = 'all'
  selectedCategory.value = null
}

const selectCategory = (category: string | null) => {
  selectedCategory.value = selectedCategory.value === category ? null : category
}

const getCategoryColor = (color: string, isSelected: boolean) => {
  const colors: Record<string, { bg: string; border: string; text: string; selectedBg: string }> = {
    blue: { bg: 'bg-blue-50', border: 'border-blue-200 hover:border-blue-400', text: 'text-blue-700', selectedBg: 'bg-blue-500' },
    indigo: { bg: 'bg-indigo-50', border: 'border-indigo-200 hover:border-indigo-400', text: 'text-indigo-700', selectedBg: 'bg-indigo-500' },
    emerald: { bg: 'bg-emerald-50', border: 'border-emerald-200 hover:border-emerald-400', text: 'text-emerald-700', selectedBg: 'bg-emerald-500' },
    pink: { bg: 'bg-pink-50', border: 'border-pink-200 hover:border-pink-400', text: 'text-pink-700', selectedBg: 'bg-pink-500' },
    amber: { bg: 'bg-amber-50', border: 'border-amber-200 hover:border-amber-400', text: 'text-amber-700', selectedBg: 'bg-amber-500' },
    purple: { bg: 'bg-purple-50', border: 'border-purple-200 hover:border-purple-400', text: 'text-purple-700', selectedBg: 'bg-purple-500' },
    orange: { bg: 'bg-orange-50', border: 'border-orange-200 hover:border-orange-400', text: 'text-orange-700', selectedBg: 'bg-orange-500' },
  }
  const c = colors[color] || colors.blue
  return isSelected 
    ? `${c.selectedBg} text-white shadow-lg` 
    : `${c.bg} ${c.border} ${c.text} border`
}

const formatNumber = (value: number) => new Intl.NumberFormat('es-HN').format(value)
</script>

<template>
  <div class="min-h-screen bg-gradient-to-br from-gray-50 via-white to-blue-50/30">
    <!-- Hero Section Mejorado -->
    <section class="relative overflow-hidden bg-gradient-to-br from-primary via-primary-dark to-blue-900 pb-20 pt-10">
      <!-- Patrón de fondo animado -->
      <div class="absolute inset-0 opacity-10">
        <div class="absolute left-1/4 top-0 h-[500px] w-[500px] rounded-full bg-white blur-3xl animate-pulse"></div>
        <div class="absolute right-1/4 bottom-0 h-[400px] w-[400px] rounded-full bg-white blur-3xl animate-pulse" style="animation-delay: 1s;"></div>
        <div class="absolute left-1/2 top-1/2 h-72 w-72 rounded-full bg-white blur-2xl animate-pulse" style="animation-delay: 2s;"></div>
      </div>

      <!-- Formas geométricas decorativas -->
      <div class="absolute inset-0 overflow-hidden pointer-events-none">
        <div class="absolute top-20 left-10 h-3 w-3 rounded-full bg-white/20 animate-bounce" style="animation-duration: 3s;"></div>
        <div class="absolute top-40 right-20 h-4 w-4 rounded-full bg-white/15 animate-bounce" style="animation-duration: 4s; animation-delay: 1s;"></div>
        <div class="absolute bottom-32 left-1/3 h-3 w-3 rounded-full bg-white/20 animate-bounce" style="animation-duration: 5s; animation-delay: 2s;"></div>
        <div class="absolute top-1/2 right-1/4 h-20 w-20 border border-white/10 rounded-2xl rotate-12"></div>
        <div class="absolute bottom-1/4 left-1/4 h-16 w-16 border border-white/10 rounded-full"></div>
      </div>

      <div class="relative px-4 sm:px-6 lg:px-8 max-w-7xl mx-auto">
        <!-- Header mejorado -->
        <div class="flex flex-col sm:flex-row items-center justify-between gap-4 mb-12">
          <div class="flex items-center gap-4">
            <div class="relative">
              <div class="h-14 w-14 rounded-2xl bg-gradient-to-br from-white/30 to-white/10 backdrop-blur-xl flex items-center justify-center ring-2 ring-white/20 shadow-lg shadow-black/10">
                <span class="material-symbols-outlined text-white text-3xl">account_circle</span>
              </div>
              <div class="absolute -bottom-1 -right-1 h-5 w-5 rounded-full bg-green-400 border-2 border-white shadow-sm flex items-center justify-center">
                <span class="material-symbols-outlined text-white !text-[12px]">check</span>
              </div>
            </div>
            <div>
              <p class="text-xs text-white/60 uppercase tracking-wider font-semibold">¡Bienvenido de nuevo!</p>
              <p class="text-white font-bold text-xl">{{ user?.name ?? user?.email ?? 'Usuario' }}</p>
            </div>
          </div>
          
          <div class="flex items-center gap-3">
            <NuxtLink
              to="/bookings"
              class="inline-flex items-center gap-2 rounded-xl bg-white/15 backdrop-blur-xl border border-white/20 px-5 py-3 text-sm font-bold text-white hover:bg-white/25 transition-all duration-200 shadow-lg shadow-black/10"
            >
              <span class="material-symbols-outlined !text-[20px]">calendar_month</span>
              <span class="hidden sm:inline">Mis Reservas</span>
            </NuxtLink>
            <button
              type="button"
              class="inline-flex items-center gap-2 rounded-xl bg-white/15 backdrop-blur-xl border border-white/20 px-5 py-3 text-sm font-bold text-white hover:bg-white/25 transition-all duration-200 shadow-lg shadow-black/10"
              @click="logout"
            >
              <span class="material-symbols-outlined !text-[20px]">logout</span>
              <span class="hidden sm:inline">Salir</span>
            </button>
          </div>
        </div>

        <!-- Título principal con estilo mejorado -->
        <div class="text-center max-w-4xl mx-auto mb-14">
          <div class="inline-flex items-center gap-2 rounded-full bg-white/10 backdrop-blur-xl border border-white/20 px-5 py-2.5 mb-8 shadow-lg">
            <span class="flex h-2 w-2 rounded-full bg-green-400 animate-pulse"></span>
            <span class="text-white text-sm font-bold">Espacios verificados y listos para reservar</span>
          </div>
          <h1 class="text-5xl md:text-7xl font-black text-white tracking-tight leading-[1.1] mb-8">
            Descubre espacios
            <span class="relative">
              <span class="bg-gradient-to-r from-yellow-300 via-orange-300 to-pink-300 bg-clip-text text-transparent">increíbles</span>
              <span class="absolute -bottom-2 left-0 right-0 h-1 bg-gradient-to-r from-yellow-300 via-orange-300 to-pink-300 rounded-full opacity-50"></span>
            </span>
          </h1>
          <p class="text-xl md:text-2xl text-white/80 max-w-2xl mx-auto leading-relaxed font-medium">
            Encuentra el lugar perfecto para tu próxima reunión, evento o proyecto. 
            <span class="text-white font-bold">Reserva en segundos.</span>
          </p>
        </div>

        <!-- Barra de búsqueda premium -->
        <div class="max-w-4xl mx-auto mb-12">
          <div class="relative">
            <div class="absolute inset-0 bg-white/20 rounded-3xl blur-xl"></div>
            <div class="relative flex flex-col lg:flex-row gap-3 p-4 rounded-2xl bg-white shadow-2xl shadow-black/20 ring-1 ring-black/5">
              <div class="flex-1 flex items-center gap-4 px-5 py-3 rounded-xl bg-gray-50/80 border border-gray-100">
                <div class="flex h-10 w-10 items-center justify-center rounded-xl bg-gradient-to-br from-primary to-primary-dark">
                  <span class="material-symbols-outlined text-white text-xl">search</span>
                </div>
                <input
                  v-model.trim="searchQuery"
                  type="text"
                  placeholder="¿Qué tipo de espacio necesitas?"
                  class="flex-1 bg-transparent text-gray-900 placeholder:text-gray-400 focus:outline-none font-medium text-lg border-0"
                  @keypress="handleSearchKeypress"
                />
                <button
                  v-if="searchQuery"
                  type="button"
                  class="flex h-8 w-8 items-center justify-center rounded-full text-gray-400 hover:text-gray-600 hover:bg-gray-100 transition"
                  @click="searchQuery = ''"
                >
                  <span class="material-symbols-outlined !text-[20px]">close</span>
                </button>
              </div>
              
              <button
                type="button"
                class="inline-flex items-center justify-center gap-3 rounded-xl bg-gradient-to-r from-primary via-primary-dark to-blue-200 px-10 py-4 font-bold text-white shadow-lg shadow-primary/30 transition-all duration-200 hover:shadow-xl hover:shadow-primary/40 hover:scale-[1.02] active:scale-[0.98]"
                :disabled="isSearching || pending"
                @click="handleSearch"
              >
                <span class="material-symbols-outlined text-xl" :class="{ 'animate-spin': isSearching }">{{ isSearching ? 'progress_activity' : 'search' }}</span>
                <span class="text-lg">Buscar</span>
              </button>
            </div>
          </div>
        </div>

        <!-- Cards promocionales premium -->
        <div class="grid grid-cols-1 sm:grid-cols-3 gap-5 max-w-4xl mx-auto">
          <!-- Reserva rápida -->
          <div class="relative group cursor-pointer" @click="handleSearch">
            <div class="absolute inset-0 bg-gradient-to-br from-emerald-400/40 to-green-500/30 rounded-2xl blur-xl opacity-0 group-hover:opacity-100 transition-opacity duration-300"></div>
            <div class="relative bg-white/10 backdrop-blur-xl border border-white/20 rounded-2xl p-7 hover:bg-white/20 hover:scale-[1.03] transition-all duration-300 shadow-lg">
              <div class="flex items-center justify-between mb-4">
                <div class="h-14 w-14 rounded-2xl bg-gradient-to-br from-emerald-400 to-green-500 flex items-center justify-center shadow-lg shadow-emerald-500/30">
                  <span class="material-symbols-outlined text-white text-3xl">bolt</span>
                </div>
                <span class="material-symbols-outlined text-white/50 group-hover:translate-x-1 transition-transform">arrow_forward</span>
              </div>
              <p class="text-2xl font-black text-white mb-2">Reserva Rápida</p>
              <p class="text-sm text-white/70 font-medium">Encuentra y reserva en minutos</p>
            </div>
          </div>

          <!-- Verificación -->
          <div class="relative group">
            <div class="absolute inset-0 bg-gradient-to-br from-blue-400/40 to-cyan-500/30 rounded-2xl blur-xl opacity-0 group-hover:opacity-100 transition-opacity duration-300"></div>
            <div class="relative bg-white/10 backdrop-blur-xl border border-white/20 rounded-2xl p-7 hover:bg-white/20 transition-all duration-300 shadow-lg">
              <div class="flex items-center justify-between mb-4">
                <div class="h-14 w-14 rounded-2xl bg-gradient-to-br from-blue-400 to-cyan-500 flex items-center justify-center shadow-lg shadow-blue-500/30">
                  <span class="material-symbols-outlined text-white text-3xl">verified</span>
                </div>
                <span class="flex h-3 w-3 rounded-full bg-green-400 animate-pulse shadow-lg shadow-green-400/50"></span>
              </div>
              <p class="text-2xl font-black text-white mb-2">100% Verificado</p>
              <p class="text-sm text-white/70 font-medium">Espacios confiables y seguros</p>
            </div>
          </div>

          <!-- Soporte -->
          <div class="relative group">
            <div class="absolute inset-0 bg-gradient-to-br from-purple-400/40 to-pink-500/30 rounded-2xl blur-xl opacity-0 group-hover:opacity-100 transition-opacity duration-300"></div>
            <div class="relative bg-white/10 backdrop-blur-xl border border-white/20 rounded-2xl p-7 hover:bg-white/20 transition-all duration-300 shadow-lg">
              <div class="flex items-center justify-between mb-4">
                <div class="h-14 w-14 rounded-2xl bg-gradient-to-br from-purple-400 to-pink-500 flex items-center justify-center shadow-lg shadow-purple-500/30">
                  <span class="material-symbols-outlined text-white text-3xl">support_agent</span>
                </div>
                <span class="text-xs font-black text-white bg-white/20 px-3 py-1.5 rounded-full">24/7</span>
              </div>
              <p class="text-2xl font-black text-white mb-2">Soporte Total</p>
              <p class="text-sm text-white/70 font-medium">Asistencia cuando la necesites</p>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- Sección de contenido principal -->
    <section ref="resultsRef" class="px-4 sm:px-6 lg:px-8 py-12 max-w-7xl mx-auto space-y-8">
      
      <!-- Categorías por tipo de espacio -->
      <div class="bg-white rounded-2xl shadow-sm ring-1 ring-black/5 p-8">
        <div class="flex items-center justify-between mb-6">
          <div class="flex items-center gap-4">
            <div class="flex h-12 w-12 items-center justify-center rounded-xl bg-gradient-to-br from-primary to-primary-dark shadow-lg shadow-primary/25">
              <span class="material-symbols-outlined text-white text-2xl">category</span>
            </div>
            <div>
              <h3 class="text-xl font-bold text-gray-900">¿Qué tipo de espacio buscas?</h3>
              <p class="text-sm text-gray-500 mt-0.5">Selecciona una categoría para filtrar</p>
            </div>
          </div>
          <button 
            v-if="selectedCategory"
            type="button"
            class="inline-flex items-center gap-1.5 text-sm font-semibold text-gray-500 hover:text-primary transition px-3 py-2 rounded-lg hover:bg-gray-50"
            @click="selectedCategory = null"
          >
            <span class="material-symbols-outlined !text-[18px]">close</span>
            Limpiar filtro
          </button>
        </div>
        
        <div class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-7 gap-3">
          <button
            v-for="cat in spaceCategories"
            :key="cat.value"
            type="button"
            class="group relative flex flex-col items-center p-4 rounded-xl transition-all duration-200 transform hover:scale-105"
            :class="getCategoryColor(cat.color, selectedCategory === cat.value)"
            @click="selectCategory(cat.value)"
          >
            <div class="relative mb-2">
              <span 
                class="material-symbols-outlined text-3xl transition-transform group-hover:scale-110"
                :class="selectedCategory === cat.value ? 'text-white' : ''"
              >{{ cat.icon }}</span>
              <span 
                v-if="categoryCountMap[cat.value] > 0"
                class="absolute -top-2 -right-3 text-xs font-bold px-1.5 py-0.5 rounded-full"
                :class="selectedCategory === cat.value ? 'bg-white/30 text-white' : 'bg-gray-200 text-gray-700'"
              >
                {{ categoryCountMap[cat.value] }}
              </span>
            </div>
            <span class="text-sm font-semibold text-center">{{ cat.label }}</span>
            <span 
              class="text-[10px] text-center leading-tight mt-1 hidden sm:block"
              :class="selectedCategory === cat.value ? 'text-white/80' : 'text-gray-500'"
            >{{ cat.description }}</span>
          </button>
        </div>
      </div>

      <!-- Filtros por tamaño y controles -->
      <div class="flex flex-wrap items-center justify-between gap-4">
        <div class="flex flex-wrap items-center gap-3">
          <span class="text-sm font-medium text-gray-500 mr-2">Por capacidad:</span>
          <button
            type="button"
            class="inline-flex items-center gap-2 rounded-xl px-4 py-2 text-sm font-semibold transition"
            :class="selectedSizeFilter === 'all' 
              ? 'bg-primary text-white shadow-lg shadow-primary/30' 
              : 'bg-white text-gray-700 border border-gray-200 hover:border-primary hover:text-primary'"
            @click="selectedSizeFilter = 'all'"
          >
            <span class="material-symbols-outlined !text-[18px]">home_work</span>
            <span>Todos</span>
          </button>

          <button
            type="button"
            class="inline-flex items-center gap-2 rounded-xl px-4 py-2 text-sm font-semibold transition"
            :class="selectedSizeFilter === 'small' 
              ? 'bg-green-500 text-white shadow-lg shadow-green-500/30' 
              : 'bg-white text-gray-700 border border-gray-200 hover:border-green-500 hover:text-green-600'"
            @click="selectedSizeFilter = 'small'"
          >
            <span class="material-symbols-outlined !text-[18px]">person</span>
            <span>&lt;20</span>
            <span class="text-xs opacity-80">({{ sizeFilters.small }})</span>
          </button>

          <button
            type="button"
            class="inline-flex items-center gap-2 rounded-xl px-4 py-2 text-sm font-semibold transition"
            :class="selectedSizeFilter === 'medium' 
              ? 'bg-orange-500 text-white shadow-lg shadow-orange-500/30' 
              : 'bg-white text-gray-700 border border-gray-200 hover:border-orange-500 hover:text-orange-600'"
            @click="selectedSizeFilter = 'medium'"
          >
            <span class="material-symbols-outlined !text-[18px]">group</span>
            <span>20-50</span>
            <span class="text-xs opacity-80">({{ sizeFilters.medium }})</span>
          </button>

          <button
            type="button"
            class="inline-flex items-center gap-2 rounded-xl px-4 py-2 text-sm font-semibold transition"
            :class="selectedSizeFilter === 'large' 
              ? 'bg-purple-500 text-white shadow-lg shadow-purple-500/30' 
              : 'bg-white text-gray-700 border border-gray-200 hover:border-purple-500 hover:text-purple-600'"
            @click="selectedSizeFilter = 'large'"
          >
            <span class="material-symbols-outlined !text-[18px]">groups</span>
            <span>50+</span>
            <span class="text-xs opacity-80">({{ sizeFilters.large }})</span>
          </button>
        </div>

        <!-- Filtros activos y controles de vista -->
        <div class="flex items-center gap-3">
          <!-- Indicador de filtros activos -->
          <div v-if="selectedCategory || selectedSizeFilter !== 'all'" class="hidden sm:flex items-center gap-2">
            <span class="text-xs text-gray-500">Filtros:</span>
            <span 
              v-if="selectedCategory" 
              class="inline-flex items-center gap-1 px-2 py-1 text-xs font-medium bg-primary/10 text-primary rounded-full"
            >
              {{ spaceCategories.find(c => c.value === selectedCategory)?.label }}
              <button type="button" class="hover:text-primary/80" @click="selectedCategory = null">
                <span class="material-symbols-outlined !text-[14px]">close</span>
              </button>
            </span>
            <span 
              v-if="selectedSizeFilter !== 'all'" 
              class="inline-flex items-center gap-1 px-2 py-1 text-xs font-medium bg-gray-100 text-gray-700 rounded-full"
            >
              {{ selectedSizeFilter === 'small' ? '<20 personas' : selectedSizeFilter === 'medium' ? '20-50 personas' : '50+ personas' }}
              <button type="button" class="hover:text-gray-600" @click="selectedSizeFilter = 'all'">
                <span class="material-symbols-outlined !text-[14px]">close</span>
              </button>
            </span>
          </div>

          <!-- Controles de vista -->
          <div class="flex items-center gap-2 bg-white rounded-xl border border-gray-200 p-1">
            <button
              type="button"
              class="rounded-lg px-3 py-2 transition"
              :class="viewMode === 'grid' ? 'bg-primary text-white' : 'text-gray-600 hover:text-primary'"
              @click="viewMode = 'grid'"
            >
              <span class="material-symbols-outlined !text-[20px]">grid_view</span>
            </button>
            <button
              type="button"
              class="rounded-lg px-3 py-2 transition"
              :class="viewMode === 'list' ? 'bg-primary text-white' : 'text-gray-600 hover:text-primary'"
              @click="viewMode = 'list'"
            >
              <span class="material-symbols-outlined !text-[20px]">view_list</span>
            </button>
          </div>
        </div>
      </div>

      <!-- Filtros avanzados -->
      <div class="rounded-2xl bg-white shadow-sm ring-1 ring-black/5 overflow-hidden">
        <div class="bg-gradient-to-r from-gray-50 via-gray-50/80 to-white px-6 py-5 border-b border-gray-100">
          <div class="flex items-center justify-between">
            <div class="flex items-center gap-3">
              <div class="flex h-10 w-10 items-center justify-center rounded-xl bg-gradient-to-br from-primary to-primary-dark">
                <span class="material-symbols-outlined text-white">tune</span>
              </div>
              <h3 class="font-bold text-gray-900 text-lg">Filtros avanzados</h3>
            </div>
            <button
              type="button"
              class="inline-flex items-center gap-2 text-sm font-semibold text-primary hover:text-primary/80 transition px-3 py-2 rounded-lg hover:bg-primary/5"
              @click="resetFilters"
            >
              <span class="material-symbols-outlined !text-[18px]">restart_alt</span>
              Restablecer
            </button>
          </div>
        </div>

        <div class="p-6">
          <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
            <div>
              <label class="block text-sm font-semibold text-gray-700 mb-3">
                <span class="flex items-center gap-2">
                  <span class="material-symbols-outlined !text-[18px] text-primary">group_add</span>
                  Capacidad mínima
                </span>
              </label>
              <input
                v-model="capacityInput"
                type="number"
                min="1"
                placeholder="Ej: 10 personas"
                class="w-full h-12 rounded-xl border-gray-200 bg-gray-50/50 px-4 py-3 text-gray-900 placeholder:text-gray-400 focus:border-primary focus:ring-2 focus:ring-primary/20 transition"
              />
            </div>

            <div>
              <label class="block text-sm font-semibold text-gray-700 mb-3">
                <span class="flex items-center gap-2">
                  <span class="material-symbols-outlined !text-[18px] text-primary">group_remove</span>
                  Capacidad máxima
                </span>
              </label>
              <input
                v-model.number="maxCapacity"
                type="number"
                min="1"
                placeholder="Ej: 100 personas"
                class="w-full h-12 rounded-xl border-gray-200 bg-gray-50/50 px-4 py-3 text-gray-900 placeholder:text-gray-400 focus:border-primary focus:ring-2 focus:ring-primary/20 transition"
              />
            </div>

            <div>
              <label class="block text-sm font-semibold text-gray-700 mb-3">
                <span class="flex items-center gap-2">
                  <span class="material-symbols-outlined !text-[18px] text-primary">sort</span>
                  Ordenar por
                </span>
              </label>
              <select
                v-model="sortOption"
                class="w-full h-12 rounded-xl border-gray-200 bg-gray-50/50 px-4 py-3 text-gray-900 focus:border-primary focus:ring-2 focus:ring-primary/20 transition"
              >
                <option value="recent">Más recientes</option>
                <option value="capacity">Mayor capacidad</option>
                <option value="price">Menor precio</option>
                <option value="name">Nombre (A-Z)</option>
              </select>
            </div>
          </div>
        </div>
      </div>

      <!-- Mensajes de error -->
      <div v-if="errorMessage" class="rounded-2xl bg-white shadow-sm ring-1 ring-red-200 p-8">
        <div class="flex flex-col gap-6 sm:flex-row sm:items-center sm:justify-between">
          <div class="flex items-start gap-4">
            <div class="flex h-14 w-14 items-center justify-center rounded-2xl bg-gradient-to-br from-red-500 to-red-600 shadow-lg shadow-red-500/30">
              <span class="material-symbols-outlined text-3xl text-white">error</span>
            </div>
            <div>
              <p class="text-xl font-bold text-gray-900">No pudimos cargar los espacios</p>
              <p class="mt-1 text-sm text-gray-600">{{ errorMessage }}</p>
              <p class="mt-2 text-xs text-gray-500">Verifica tu conexión e inténtalo nuevamente</p>
            </div>
          </div>
          <button
            type="button"
            class="inline-flex items-center gap-2 rounded-xl bg-gradient-to-r from-red-500 to-red-600 px-6 py-3 font-bold text-white hover:shadow-lg hover:shadow-red-500/30 transition-all"
            @click="reloadSpaces"
          >
            <span class="material-symbols-outlined">refresh</span>
            Reintentar
          </button>
        </div>
      </div>

      <!-- Loading skeletons premium -->
      <div v-else-if="pending">
        <div class="mb-6 flex items-center gap-4">
          <div class="h-10 w-10 animate-spin rounded-full border-4 border-primary/20 border-t-primary"></div>
          <div class="h-8 w-48 animate-pulse bg-gray-200 rounded-xl"></div>
        </div>
        <div 
          class="grid gap-6"
          :class="viewMode === 'grid' ? 'sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4' : 'grid-cols-1'"
        >
          <div v-for="n in 8" :key="`skeleton-${n}`" class="rounded-2xl bg-white shadow-sm ring-1 ring-black/5 overflow-hidden">
            <div class="h-52 animate-pulse bg-gradient-to-br from-gray-100 via-gray-200 to-gray-100"></div>
            <div class="p-6 space-y-4">
              <div class="h-6 w-3/4 animate-pulse bg-gray-200 rounded-lg"></div>
              <div class="h-4 w-full animate-pulse bg-gray-100 rounded-lg"></div>
              <div class="h-4 w-2/3 animate-pulse bg-gray-100 rounded-lg"></div>
              <div class="flex gap-3 pt-2">
                <div class="h-10 w-24 animate-pulse bg-gray-200 rounded-xl"></div>
                <div class="h-10 w-28 animate-pulse bg-gray-200 rounded-xl"></div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Estado vacío -->
      <div v-else-if="!filteredSpaces.length" class="rounded-2xl bg-white shadow-sm ring-1 ring-black/5 p-16 text-center">
        <div class="mx-auto flex h-32 w-32 items-center justify-center rounded-3xl bg-gradient-to-br from-gray-100 to-gray-200 shadow-inner">
          <span class="material-symbols-outlined text-6xl text-gray-400">search_off</span>
        </div>
        <h2 class="mt-8 text-3xl font-black text-gray-900">No encontramos espacios</h2>
        <p class="mt-3 text-lg text-gray-500 max-w-md mx-auto">
          Intenta ajustar tus filtros o buscar con otros términos para ver más resultados
        </p>
        <div class="mt-8 flex flex-wrap items-center justify-center gap-4">
          <button
            type="button"
            class="inline-flex items-center gap-2 rounded-xl bg-gradient-to-r from-primary to-primary-dark px-6 py-3 font-bold text-white hover:shadow-lg hover:shadow-primary/30 transition-all"
            @click="resetFilters"
          >
            <span class="material-symbols-outlined">restart_alt</span>
            Restablecer filtros
          </button>
          <button
            type="button"
            class="inline-flex items-center gap-2 rounded-xl bg-white ring-1 ring-gray-200 px-6 py-3 font-bold text-gray-700 hover:ring-primary hover:text-primary transition"
            @click="reloadSpaces"
          >
            <span class="material-symbols-outlined">refresh</span>
            Recargar
          </button>
        </div>
      </div>

      <!-- Resultados -->
      <div v-else>
        <!-- Header de resultados -->
        <div class="mb-8 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 bg-white rounded-2xl shadow-sm ring-1 ring-black/5 p-6">
          <div class="flex items-center gap-4">
            <div class="flex h-12 w-12 items-center justify-center rounded-xl bg-gradient-to-br from-primary to-primary-dark shadow-lg shadow-primary/25">
              <span class="material-symbols-outlined text-white text-2xl">explore</span>
            </div>
            <div>
              <h2 class="text-2xl font-bold text-gray-900">Espacios disponibles</h2>
              <p class="text-sm text-gray-500 mt-0.5">
                <span class="font-bold text-gray-900">{{ filteredSpaces.length }}</span> 
                {{ filteredSpaces.length === 1 ? 'resultado' : 'resultados' }}
                <span v-if="searchQuery"> para "<span class="font-semibold text-primary">{{ searchQuery }}</span>"</span>
              </p>
            </div>
          </div>

          <!-- Quick actions -->
          <div class="flex items-center gap-3">
            <button
              v-if="filteredSpaces.length !== spaces.length"
              type="button"
              class="inline-flex items-center gap-2 rounded-xl bg-gray-100 px-4 py-2.5 text-sm font-bold text-gray-700 hover:bg-gray-200 transition"
              @click="resetFilters"
            >
              <span class="material-symbols-outlined !text-[18px]">filter_list_off</span>
              Ver todos
            </button>
          </div>
        </div>

        <!-- Grid de espacios destacados -->
        <div v-if="featuredSpaces.length" class="mb-12">
          <div class="mb-6 flex items-center gap-4">
            <div class="flex h-12 w-12 items-center justify-center rounded-xl bg-gradient-to-br from-yellow-400 to-orange-500 shadow-lg shadow-orange-500/30">
              <span class="material-symbols-outlined text-white text-2xl">star</span>
            </div>
            <div>
              <h3 class="text-xl font-bold text-gray-900">Destacados</h3>
              <p class="text-sm text-gray-500">Los más populares del momento</p>
            </div>
          </div>
          <div 
            class="grid gap-6"
            :class="viewMode === 'grid' ? 'sm:grid-cols-2 lg:grid-cols-3' : 'grid-cols-1'"
          >
            <SpaceCard 
              v-for="space in featuredSpaces" 
              :key="`featured-${space.id}`" 
              :space="space" 
            />
          </div>
        </div>

        <!-- Grid de todos los espacios -->
        <div v-if="secondarySpaces.length" class="mb-12">
          <div class="mb-6 flex items-center gap-4">
            <div class="flex h-12 w-12 items-center justify-center rounded-xl bg-gradient-to-br from-primary to-blue-600 shadow-lg shadow-blue-600/30">
              <span class="material-symbols-outlined text-white text-2xl">apps</span>
            </div>
            <div>
              <h3 class="text-xl font-bold text-gray-900">Todos los espacios</h3>
              <p class="text-sm text-gray-500">{{ secondarySpaces.length }} opciones adicionales</p>
            </div>
          </div>
          <div 
            class="grid gap-6"
            :class="viewMode === 'grid' ? 'sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4' : 'grid-cols-1'"
          >
            <SpaceCard
              v-for="space in secondarySpaces"
              :key="space.id"
              :space="space"
            />
          </div>
        </div>

        <!-- Si solo hay espacios sin destacados -->
        <div v-if="!featuredSpaces.length && filteredSpaces.length">
          <div 
            class="grid gap-6"
            :class="viewMode === 'grid' ? 'sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4' : 'grid-cols-1'"
          >
            <SpaceCard
              v-for="space in filteredSpaces"
              :key="space.id"
              :space="space"
            />
          </div>
        </div>
      </div>
    </section>
  </div>
</template>
