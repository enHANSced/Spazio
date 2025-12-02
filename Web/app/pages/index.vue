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
const sortOption = ref<'recent' | 'capacity' | 'name'>('recent')
const viewMode = ref<'grid' | 'list'>('grid')
const selectedCategory = ref<'all' | 'small' | 'medium' | 'large'>('all')

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

// Categorías por capacidad
const categories = computed(() => {
  const active = spaces.value.filter(s => s.isActive)
  return {
    small: active.filter(s => s.capacity < 20).length,
    medium: active.filter(s => s.capacity >= 20 && s.capacity < 50).length,
    large: active.filter(s => s.capacity >= 50).length
  }
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
      if (selectedCategory.value === 'all') return true
      if (selectedCategory.value === 'small') return space.capacity < 20
      if (selectedCategory.value === 'medium') return space.capacity >= 20 && space.capacity < 50
      if (selectedCategory.value === 'large') return space.capacity >= 50
      return true
    })
    .sort((a, b) => {
      if (sortOption.value === 'capacity') return b.capacity - a.capacity
      if (sortOption.value === 'name') return a.name.localeCompare(b.name)
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
  selectedCategory.value = 'all'
}

const formatNumber = (value: number) => new Intl.NumberFormat('es-HN').format(value)
</script>

<template>
  <div class="min-h-screen bg-gradient-to-br from-gray-50 via-white to-blue-50/30">
    <!-- Hero Section Mejorado -->
    <section class="relative overflow-hidden bg-gradient-to-br from-primary via-blue-600 to-indigo-700 pb-16 pt-8">
      <!-- Patrón de fondo animado -->
      <div class="absolute inset-0 opacity-10">
        <div class="absolute left-1/4 top-0 h-96 w-96 rounded-full bg-white blur-3xl animate-pulse"></div>
        <div class="absolute right-1/4 bottom-0 h-96 w-96 rounded-full bg-white blur-3xl animate-pulse" style="animation-delay: 1s;"></div>
        <div class="absolute left-1/2 top-1/2 h-64 w-64 rounded-full bg-white blur-2xl animate-pulse" style="animation-delay: 2s;"></div>
      </div>

      <!-- Partículas decorativas -->
      <div class="absolute inset-0 overflow-hidden pointer-events-none">
        <div class="absolute top-20 left-10 h-2 w-2 rounded-full bg-white/30 animate-bounce" style="animation-duration: 3s;"></div>
        <div class="absolute top-40 right-20 h-3 w-3 rounded-full bg-white/20 animate-bounce" style="animation-duration: 4s; animation-delay: 1s;"></div>
        <div class="absolute bottom-20 left-1/3 h-2 w-2 rounded-full bg-white/25 animate-bounce" style="animation-duration: 5s; animation-delay: 2s;"></div>
      </div>

      <div class="relative px-4 sm:px-6 lg:px-8 max-w-7xl mx-auto">
        <!-- Header mejorado -->
        <div class="flex flex-col sm:flex-row items-center justify-between gap-4 mb-10">
          <div class="flex items-center gap-4">
            <div class="relative">
              <div class="h-12 w-12 rounded-full bg-gradient-to-br from-white/30 to-white/10 backdrop-blur flex items-center justify-center ring-2 ring-white/20">
                <span class="material-symbols-outlined text-white text-2xl">account_circle</span>
              </div>
              <div class="absolute -bottom-1 -right-1 h-4 w-4 rounded-full bg-green-400 border-2 border-white"></div>
            </div>
            <div>
              <p class="text-xs text-white/70 uppercase tracking-wider font-medium">Hola de nuevo 👋</p>
              <p class="text-white font-bold text-lg">{{ user?.name ?? user?.email ?? 'Usuario' }}</p>
            </div>
          </div>
          
          <div class="flex items-center gap-3">
            <NuxtLink
              to="/bookings"
              class="inline-flex items-center gap-2 rounded-xl bg-white/10 backdrop-blur border border-white/20 px-4 py-2.5 text-sm font-semibold text-white hover:bg-white/20 transition"
            >
              <span class="material-symbols-outlined !text-[18px]">calendar_month</span>
              <span class="hidden sm:inline">Mis Reservas</span>
            </NuxtLink>
            <button
              type="button"
              class="inline-flex items-center gap-2 rounded-xl bg-white/10 backdrop-blur border border-white/20 px-4 py-2.5 text-sm font-semibold text-white hover:bg-white/20 transition"
              @click="logout"
            >
              <span class="material-symbols-outlined !text-[18px]">logout</span>
              <span class="hidden sm:inline">Salir</span>
            </button>
          </div>
        </div>

        <!-- Título animado -->
        <div class="text-center max-w-4xl mx-auto mb-12">
          <div class="inline-flex items-center gap-2 rounded-full bg-white/10 backdrop-blur border border-white/20 px-4 py-2 mb-6">
            <span class="material-symbols-outlined text-white !text-[18px]">verified</span>
            <span class="text-white text-sm font-semibold">Espacios verificados y listos para reservar</span>
          </div>
          <h1 class="text-5xl md:text-6xl font-black text-white tracking-tight leading-tight mb-6">
            Descubre espacios <span class="bg-gradient-to-r from-yellow-200 to-orange-200 bg-clip-text text-transparent">increíbles</span>
          </h1>
          <p class="text-xl text-white/90 max-w-2xl mx-auto leading-relaxed">
            Encuentra el lugar perfecto para tu próxima reunión, evento o proyecto. 
            <span class="font-semibold text-white">Reserva en segundos.</span>
          </p>
        </div>

        <!-- Barra de búsqueda mejorada -->
        <div class="max-w-5xl mx-auto mb-10">
          <div class="relative">
            <div class="flex flex-col lg:flex-row gap-3 p-3 rounded-2xl bg-white shadow-2xl">
              <div class="flex-1 flex items-center gap-3 px-4 py-3 rounded-xl bg-gray-50">
                <span class="material-symbols-outlined text-2xl text-primary">search</span>
                <input
                  v-model.trim="searchQuery"
                  type="text"
                  placeholder="¿Qué tipo de espacio necesitas?"
                  class="flex-1 bg-transparent text-gray-900 placeholder:text-gray-500 focus:outline-none font-medium"
                  @keypress="handleSearchKeypress"
                />
                <button
                  v-if="searchQuery"
                  type="button"
                  class="text-gray-400 hover:text-gray-600 transition"
                  @click="searchQuery = ''"
                >
                  <span class="material-symbols-outlined !text-[20px]">close</span>
                </button>
              </div>
              
              <button
                type="button"
                class="inline-flex items-center justify-center gap-2 rounded-xl bg-gradient-to-r from-primary to-blue-600 px-8 py-3 font-bold text-white shadow-lg transition hover:shadow-xl hover:scale-105 active:scale-95"
                :disabled="isSearching || pending"
                @click="handleSearch"
              >
                <span class="material-symbols-outlined" :class="{ 'animate-spin': isSearching }">search</span>
                <span>Buscar</span>
              </button>
            </div>
          </div>
        </div>

        <!-- Cards promocionales -->
        <div class="grid grid-cols-1 sm:grid-cols-3 gap-4 max-w-4xl mx-auto">
          <!-- Reserva rápida -->
          <div class="relative group cursor-pointer" @click="handleSearch">
            <div class="absolute inset-0 bg-gradient-to-br from-emerald-400/30 to-green-400/20 rounded-2xl blur-xl group-hover:blur-2xl transition"></div>
            <div class="relative bg-white/10 backdrop-blur-xl border border-white/20 rounded-2xl p-6 hover:bg-white/15 hover:scale-105 transition-all">
              <div class="flex items-center justify-between mb-3">
                <div class="h-12 w-12 rounded-xl bg-emerald-400/20 flex items-center justify-center">
                  <span class="material-symbols-outlined text-white text-2xl">bolt</span>
                </div>
                <span class="material-symbols-outlined text-white/60">arrow_forward</span>
              </div>
              <p class="text-xl font-black text-white mb-1">Reserva Rápida</p>
              <p class="text-sm text-white/80 font-medium">Encuentra y reserva en minutos</p>
            </div>
          </div>

          <!-- Verificación -->
          <div class="relative group">
            <div class="absolute inset-0 bg-gradient-to-br from-blue-400/30 to-cyan-400/20 rounded-2xl blur-xl group-hover:blur-2xl transition"></div>
            <div class="relative bg-white/10 backdrop-blur-xl border border-white/20 rounded-2xl p-6 hover:bg-white/15 transition-all">
              <div class="flex items-center justify-between mb-3">
                <div class="h-12 w-12 rounded-xl bg-blue-400/20 flex items-center justify-center">
                  <span class="material-symbols-outlined text-white text-2xl">verified</span>
                </div>
                <span class="h-2 w-2 rounded-full bg-green-400 animate-pulse"></span>
              </div>
              <p class="text-xl font-black text-white mb-1">100% Verificado</p>
              <p class="text-sm text-white/80 font-medium">Espacios confiables y seguros</p>
            </div>
          </div>

          <!-- Soporte -->
          <div class="relative group">
            <div class="absolute inset-0 bg-gradient-to-br from-purple-400/30 to-pink-400/20 rounded-2xl blur-xl group-hover:blur-2xl transition"></div>
            <div class="relative bg-white/10 backdrop-blur-xl border border-white/20 rounded-2xl p-6 hover:bg-white/15 transition-all">
              <div class="flex items-center justify-between mb-3">
                <div class="h-12 w-12 rounded-xl bg-purple-400/20 flex items-center justify-center">
                  <span class="material-symbols-outlined text-white text-2xl">support_agent</span>
                </div>
                <span class="text-xs font-bold text-white/90 bg-white/20 px-2 py-1 rounded-full">24/7</span>
              </div>
              <p class="text-xl font-black text-white mb-1">Soporte Total</p>
              <p class="text-sm text-white/80 font-medium">Asistencia cuando la necesites</p>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- Sección de contenido principal -->
    <section ref="resultsRef" class="px-4 sm:px-6 lg:px-8 py-12 max-w-7xl mx-auto space-y-8">
      <!-- Categorías rápidas -->
      <div class="flex flex-wrap items-center justify-between gap-4">
        <div class="flex flex-wrap items-center gap-3">
          <button
            type="button"
            class="inline-flex items-center gap-2 rounded-xl px-5 py-2.5 font-semibold transition"
            :class="selectedCategory === 'all' 
              ? 'bg-primary text-white shadow-lg shadow-primary/30' 
              : 'bg-white text-gray-700 border border-gray-200 hover:border-primary hover:text-primary'"
            @click="selectedCategory = 'all'"
          >
            <span class="material-symbols-outlined !text-[20px]">home_work</span>
            <span>Todos</span>
            <span class="text-sm opacity-80">({{ filteredSpaces.length }})</span>
          </button>

          <button
            type="button"
            class="inline-flex items-center gap-2 rounded-xl px-5 py-2.5 font-semibold transition"
            :class="selectedCategory === 'small' 
              ? 'bg-green-500 text-white shadow-lg shadow-green-500/30' 
              : 'bg-white text-gray-700 border border-gray-200 hover:border-green-500 hover:text-green-600'"
            @click="selectedCategory = 'small'"
          >
            <span class="material-symbols-outlined !text-[20px]">meeting_room</span>
            <span>Pequeños</span>
            <span class="text-sm opacity-80">({{ categories.small }})</span>
          </button>

          <button
            type="button"
            class="inline-flex items-center gap-2 rounded-xl px-5 py-2.5 font-semibold transition"
            :class="selectedCategory === 'medium' 
              ? 'bg-orange-500 text-white shadow-lg shadow-orange-500/30' 
              : 'bg-white text-gray-700 border border-gray-200 hover:border-orange-500 hover:text-orange-600'"
            @click="selectedCategory = 'medium'"
          >
            <span class="material-symbols-outlined !text-[20px]">groups</span>
            <span>Medianos</span>
            <span class="text-sm opacity-80">({{ categories.medium }})</span>
          </button>

          <button
            type="button"
            class="inline-flex items-center gap-2 rounded-xl px-5 py-2.5 font-semibold transition"
            :class="selectedCategory === 'large' 
              ? 'bg-purple-500 text-white shadow-lg shadow-purple-500/30' 
              : 'bg-white text-gray-700 border border-gray-200 hover:border-purple-500 hover:text-purple-600'"
            @click="selectedCategory = 'large'"
          >
            <span class="material-symbols-outlined !text-[20px]">celebration</span>
            <span>Grandes</span>
            <span class="text-sm opacity-80">({{ categories.large }})</span>
          </button>
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

      <!-- Filtros avanzados -->
      <div class="rounded-2xl border border-gray-200 bg-white shadow-sm overflow-hidden">
        <div class="bg-gradient-to-r from-gray-50 to-white px-6 py-4 border-b border-gray-200">
          <div class="flex items-center justify-between">
            <h3 class="font-bold text-gray-900 flex items-center gap-2">
              <span class="material-symbols-outlined text-primary">tune</span>
              Filtros avanzados
            </h3>
            <button
              type="button"
              class="text-sm font-semibold text-primary hover:text-primary/80 transition flex items-center gap-1"
              @click="resetFilters"
            >
              <span class="material-symbols-outlined !text-[18px]">restart_alt</span>
              Restablecer
            </button>
          </div>
        </div>

        <div class="p-6">
          <div class="grid grid-cols-1 md:grid-cols-3 gap-5">
            <div>
              <label class="block text-sm font-semibold text-gray-700 mb-2">
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
                class="w-full rounded-xl border-2 border-gray-200 px-4 py-3 text-gray-900 placeholder:text-gray-400 focus:border-primary focus:ring-4 focus:ring-primary/10 transition"
              />
            </div>

            <div>
              <label class="block text-sm font-semibold text-gray-700 mb-2">
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
                class="w-full rounded-xl border-2 border-gray-200 px-4 py-3 text-gray-900 placeholder:text-gray-400 focus:border-primary focus:ring-4 focus:ring-primary/10 transition"
              />
            </div>

            <div>
              <label class="block text-sm font-semibold text-gray-700 mb-2">
                <span class="flex items-center gap-2">
                  <span class="material-symbols-outlined !text-[18px] text-primary">sort</span>
                  Ordenar por
                </span>
              </label>
              <select
                v-model="sortOption"
                class="w-full rounded-xl border-2 border-gray-200 px-4 py-3 text-gray-900 focus:border-primary focus:ring-4 focus:ring-primary/10 transition bg-white"
              >
                <option value="recent">Más recientes</option>
                <option value="capacity">Mayor capacidad</option>
                <option value="name">Nombre (A-Z)</option>
              </select>
            </div>
          </div>
        </div>
      </div>

      <!-- Mensajes de error -->
      <div v-if="errorMessage" class="rounded-2xl border-2 border-red-200 bg-gradient-to-br from-red-50 to-red-100/50 p-8 shadow-lg">
        <div class="flex flex-col gap-6 sm:flex-row sm:items-center sm:justify-between">
          <div class="flex items-start gap-4">
            <div class="flex h-12 w-12 items-center justify-center rounded-full bg-red-100 ring-4 ring-red-200/50">
              <span class="material-symbols-outlined text-2xl text-red-600">error</span>
            </div>
            <div>
              <p class="text-lg font-bold text-red-900">No pudimos cargar los espacios</p>
              <p class="mt-1 text-sm text-red-700">{{ errorMessage }}</p>
              <p class="mt-2 text-xs text-red-600">Verifica tu conexión e inténtalo nuevamente</p>
            </div>
          </div>
          <button
            type="button"
            class="inline-flex items-center gap-2 rounded-xl bg-red-600 px-6 py-3 font-bold text-white hover:bg-red-700 transition shadow-lg hover:shadow-xl"
            @click="reloadSpaces"
          >
            <span class="material-symbols-outlined">refresh</span>
            Reintentar
          </button>
        </div>
      </div>

      <!-- Loading skeletons mejorado -->
      <div v-else-if="pending">
        <div class="mb-6 flex items-center gap-3">
          <div class="h-8 w-8 animate-spin rounded-full border-4 border-gray-200 border-t-primary"></div>
          <div class="h-8 w-64 animate-pulse bg-gray-200 rounded-lg"></div>
        </div>
        <div 
          class="grid gap-6"
          :class="viewMode === 'grid' ? 'sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4' : 'grid-cols-1'"
        >
          <div v-for="n in 8" :key="`skeleton-${n}`" class="rounded-2xl bg-white border border-gray-200 overflow-hidden">
            <div class="h-48 animate-pulse bg-gradient-to-br from-gray-100 to-gray-200"></div>
            <div class="p-5 space-y-3">
              <div class="h-6 w-3/4 animate-pulse bg-gray-200 rounded"></div>
              <div class="h-4 w-full animate-pulse bg-gray-100 rounded"></div>
              <div class="h-4 w-2/3 animate-pulse bg-gray-100 rounded"></div>
              <div class="flex gap-2 pt-2">
                <div class="h-8 w-20 animate-pulse bg-gray-200 rounded-lg"></div>
                <div class="h-8 w-24 animate-pulse bg-gray-200 rounded-lg"></div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Estado vacío mejorado -->
      <div v-else-if="!filteredSpaces.length" class="rounded-2xl border-2 border-dashed border-gray-300 bg-white p-16 text-center">
        <div class="mx-auto flex h-32 w-32 items-center justify-center rounded-full bg-gradient-to-br from-gray-100 to-gray-200">
          <span class="material-symbols-outlined text-6xl text-gray-400">search_off</span>
        </div>
        <h2 class="mt-8 text-3xl font-black text-gray-900">No encontramos espacios</h2>
        <p class="mt-3 text-lg text-gray-600 max-w-md mx-auto">
          Intenta ajustar tus filtros o buscar con otros términos para ver más resultados
        </p>
        <div class="mt-8 flex flex-wrap items-center justify-center gap-3">
          <button
            type="button"
            class="inline-flex items-center gap-2 rounded-xl bg-primary px-6 py-3 font-bold text-white hover:bg-primary/90 transition shadow-lg hover:shadow-xl"
            @click="resetFilters"
          >
            <span class="material-symbols-outlined">restart_alt</span>
            Restablecer filtros
          </button>
          <button
            type="button"
            class="inline-flex items-center gap-2 rounded-xl bg-white border-2 border-gray-300 px-6 py-3 font-bold text-gray-700 hover:border-primary hover:text-primary transition"
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
        <div class="mb-6 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 bg-white rounded-2xl border border-gray-200 p-5">
          <div>
            <h2 class="text-2xl font-bold text-gray-900 flex items-center gap-3">
              <span class="material-symbols-outlined text-primary text-3xl">explore</span>
              Espacios disponibles
            </h2>
            <p class="text-sm text-gray-600 mt-1">
              <span class="font-semibold text-gray-900">{{ filteredSpaces.length }}</span> 
              {{ filteredSpaces.length === 1 ? 'resultado' : 'resultados' }}
              <span v-if="searchQuery"> para "<span class="font-semibold text-primary">{{ searchQuery }}</span>"</span>
            </p>
          </div>

          <!-- Quick actions -->
          <div class="flex items-center gap-2">
            <button
              v-if="filteredSpaces.length !== spaces.length"
              type="button"
              class="inline-flex items-center gap-2 rounded-xl bg-gray-100 px-4 py-2 text-sm font-semibold text-gray-700 hover:bg-gray-200 transition"
              @click="resetFilters"
            >
              <span class="material-symbols-outlined !text-[18px]">filter_list_off</span>
              Ver todos
            </button>
          </div>
        </div>

        <!-- Grid de espacios destacados -->
        <div v-if="featuredSpaces.length" class="mb-10">
          <div class="mb-6 flex items-center gap-3">
            <div class="flex h-10 w-10 items-center justify-center rounded-xl bg-gradient-to-br from-yellow-400 to-orange-500">
              <span class="material-symbols-outlined text-white text-xl">star</span>
            </div>
            <div>
              <h3 class="text-xl font-bold text-gray-900">Destacados</h3>
              <p class="text-sm text-gray-600">Los más populares del momento</p>
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
        <div v-if="secondarySpaces.length" class="mb-10">
          <div class="mb-6 flex items-center gap-3">
            <div class="flex h-10 w-10 items-center justify-center rounded-xl bg-gradient-to-br from-primary to-blue-600">
              <span class="material-symbols-outlined text-white text-xl">apps</span>
            </div>
            <div>
              <h3 class="text-xl font-bold text-gray-900">Todos los espacios</h3>
              <p class="text-sm text-gray-600">{{ secondarySpaces.length }} opciones adicionales</p>
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
