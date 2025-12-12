<script setup lang="ts">
import { computed, ref, onMounted, onUnmounted } from 'vue'
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

// ========== SISTEMA DE EFECTOS OPTIMIZADO (CSS-only) ==========
const heroRef = ref<HTMLElement | null>(null)
const mousePosition = ref({ x: 50, y: 50 })
const isMouseInHero = ref(false)
const showRipple = ref(false)
const ripplePosition = ref({ x: 0, y: 0 })

// Throttle para el mouse move (mejora rendimiento)
let lastMouseMove = 0
const THROTTLE_MS = 16 // ~60fps

const handleMouseMove = (e: MouseEvent) => {
  const now = Date.now()
  if (now - lastMouseMove < THROTTLE_MS) return
  lastMouseMove = now
  
  if (!heroRef.value) return
  const rect = heroRef.value.getBoundingClientRect()
  mousePosition.value = {
    x: ((e.clientX - rect.left) / rect.width) * 100,
    y: ((e.clientY - rect.top) / rect.height) * 100
  }
}

const handleMouseEnter = () => {
  isMouseInHero.value = true
}

const handleMouseLeave = () => {
  isMouseInHero.value = false
}

const handleHeroClick = (e: MouseEvent) => {
  if (!heroRef.value) return
  const rect = heroRef.value.getBoundingClientRect()
  ripplePosition.value = {
    x: ((e.clientX - rect.left) / rect.width) * 100,
    y: ((e.clientY - rect.top) / rect.height) * 100
  }
  showRipple.value = true
  setTimeout(() => { showRipple.value = false }, 800)
}

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
  <div class="min-h-screen bg-gradient-to-br from-gray-50 via-white to-blue-50/30 overflow-hidden">
    <!-- Hero Section Mejorado con Animaciones OPTIMIZADAS -->
    <section 
      ref="heroRef"
      class="relative overflow-hidden hero-animated-bg pb-20 pt-10"
      @mousemove="handleMouseMove"
      @mouseenter="handleMouseEnter"
      @mouseleave="handleMouseLeave"
      @click="handleHeroClick"
    >
      <!-- Partículas CSS puras (GPU accelerated) -->
      <div class="particles-container">
        <div class="particle particle-1"></div>
        <div class="particle particle-2"></div>
        <div class="particle particle-3"></div>
        <div class="particle particle-4"></div>
        <div class="particle particle-5"></div>
        <div class="particle particle-6"></div>
        <div class="particle particle-7"></div>
        <div class="particle particle-8"></div>
      </div>

      <!-- Click ripple effect (single element, reused) -->
      <div 
        v-if="showRipple"
        class="click-ripple"
        :style="{
          left: `${ripplePosition.x}%`,
          top: `${ripplePosition.y}%`,
        }"
      />

      <!-- Aurora gradient animado (CSS only) -->
      <div class="aurora-container">
        <div class="aurora aurora-1"></div>
        <div class="aurora aurora-2"></div>
      </div>

      <!-- Orbes flotantes (CSS only, will-change optimized) -->
      <div class="floating-orbs">
        <div class="orb orb-1"></div>
        <div class="orb orb-2"></div>
        <div class="orb orb-3"></div>
        <div class="orb orb-4"></div>
      </div>

      <!-- Formas geométricas rotantes -->
      <div class="geometric-shapes">
        <div class="shape shape-1"></div>
        <div class="shape shape-2"></div>
      </div>

      <!-- Cursor follower glow (optimized with will-change) -->
      <div 
        class="cursor-glow"
        :class="{ 'cursor-glow-visible': isMouseInHero }"
        :style="{
          '--mouse-x': `${mousePosition.x}%`,
          '--mouse-y': `${mousePosition.y}%`,
        }"
      />

      <div class="relative px-4 sm:px-6 lg:px-8 max-w-7xl mx-auto">
        <!-- Header mejorado con animaciones de entrada -->
        <div class="flex flex-col sm:flex-row items-center justify-between gap-4 mb-12 animate-slide-down">
          <div class="flex items-center gap-4 group cursor-pointer hover-lift">
            <div class="relative">
              <div class="h-14 w-14 rounded-2xl bg-gradient-to-br from-white/30 to-white/10 backdrop-blur-xl flex items-center justify-center ring-2 ring-white/20 shadow-lg shadow-black/10 group-hover:ring-white/40 group-hover:shadow-xl transition-all duration-300 avatar-glow">
                <span class="material-symbols-outlined text-white text-3xl group-hover:scale-110 transition-transform">account_circle</span>
              </div>
              <div class="absolute -bottom-1 -right-1 h-5 w-5 rounded-full bg-green-400 border-2 border-white shadow-sm flex items-center justify-center status-pulse">
                <span class="material-symbols-outlined text-white !text-[12px]">check</span>
              </div>
            </div>
            <div>
              <p class="text-xs text-white/60 uppercase tracking-wider font-semibold animate-fade-in" style="animation-delay: 0.2s;">¡Bienvenido de nuevo!</p>
              <p class="text-white font-bold text-xl text-glow animate-fade-in" style="animation-delay: 0.3s;">{{ user?.name ?? user?.email ?? 'Usuario' }}</p>
            </div>
          </div>
          
          <div class="flex items-center gap-3 animate-fade-in" style="animation-delay: 0.4s;">
            <NuxtLink
              to="/bookings"
              class="inline-flex items-center gap-2 rounded-xl bg-white/15 backdrop-blur-xl border border-white/20 px-5 py-3 text-sm font-bold text-white hover:bg-white/25 transition-all duration-300 shadow-lg shadow-black/10 btn-hover"
            >
              <span class="material-symbols-outlined !text-[20px] btn-icon">calendar_month</span>
              <span class="hidden sm:inline">Mis Reservas</span>
            </NuxtLink>
            <button
              type="button"
              class="inline-flex items-center gap-2 rounded-xl bg-white/15 backdrop-blur-xl border border-white/20 px-5 py-3 text-sm font-bold text-white hover:bg-white/25 transition-all duration-300 shadow-lg shadow-black/10 btn-hover"
              @click="logout"
            >
              <span class="material-symbols-outlined !text-[20px]">logout</span>
              <span class="hidden sm:inline">Salir</span>
            </button>
          </div>
        </div>

        <!-- Título principal con animaciones -->
        <div class="text-center max-w-4xl mx-auto mb-14">
          <div class="inline-flex items-center gap-2 rounded-full bg-white/10 backdrop-blur-xl border border-white/20 px-5 py-2.5 mb-8 shadow-lg animate-bounce-in badge-shimmer">
            <span class="flex h-2 w-2 rounded-full bg-green-400 status-pulse"></span>
            <span class="text-white text-sm font-bold">Espacios verificados y listos para reservar</span>
          </div>
          
          <h1 class="text-5xl md:text-7xl font-black text-white tracking-tight leading-[1.1] mb-8">
            <span class="inline-block animate-slide-up" style="animation-delay: 0.1s;">Descubre</span> <span class="inline-block animate-slide-up" style="animation-delay: 0.2s;">espacios</span>
            <br>
            <span class="relative inline-block animate-slide-up" style="animation-delay: 0.3s;">
              <span class="title-gradient-animated">increíbles</span>
              <span class="absolute -bottom-2 left-0 right-0 h-1.5 title-underline rounded-full"></span>
            </span>
          </h1>
          
          <p class="text-xl md:text-2xl text-white/80 max-w-2xl mx-auto leading-relaxed font-medium animate-fade-in-up" style="animation-delay: 0.5s;">
            Encuentra el lugar perfecto para tu próxima reunión, evento o proyecto. 
            <span class="text-white font-bold">Reserva en segundos.</span>
          </p>
        </div>

        <!-- Barra de búsqueda premium -->
        <div class="max-w-4xl mx-auto mb-12 animate-scale-in" style="animation-delay: 0.6s;">
          <div class="relative group">
            <div class="absolute inset-0 bg-white/20 rounded-3xl blur-xl transition-all duration-500"></div>
            <div class="search-glow-border"></div>
            <div class="relative flex flex-col lg:flex-row gap-3 p-4 rounded-2xl bg-white shadow-2xl shadow-black/20 ring-1 ring-black/5 search-card">
              <div class="flex-1 flex items-center gap-4 px-5 py-3 rounded-xl bg-gray-50/80 border border-gray-100 transition-all duration-300 search-input-wrapper">
                <div class="flex h-10 w-10 items-center justify-center rounded-xl bg-gradient-to-br from-primary to-primary-dark">
                  <span class="material-symbols-outlined text-white text-xl">search</span>
                </div>
                <input
                  v-model.trim="searchQuery"
                  type="text"
                  placeholder="¿Qué tipo de espacio necesitas?"
                  class="search-input flex-1 bg-transparent text-gray-900 placeholder:text-gray-400 font-medium text-lg border-0"
                  @keypress="handleSearchKeypress"
                />
                <button
                  v-if="searchQuery"
                  type="button"
                  class="flex h-8 w-8 items-center justify-center rounded-full text-gray-400 hover:text-gray-600 hover:bg-gray-100 transition-all duration-200 hover:rotate-90"
                  @click="searchQuery = ''"
                >
                  <span class="material-symbols-outlined !text-[20px]">close</span>
                </button>
              </div>
              
              <button
                type="button"
                class="search-btn inline-flex items-center justify-center gap-3 rounded-xl bg-gradient-to-r from-primary via-primary-dark to-blue-300 px-10 py-4 font-bold text-white shadow-lg shadow-primary/30 transition-all duration-300 hover:shadow-xl hover:shadow-primary/50 active:scale-[0.98]"
                :disabled="isSearching || pending"
                @click="handleSearch"
              >
                <span class="material-symbols-outlined text-xl" :class="{ 'animate-spin': isSearching }">{{ isSearching ? 'progress_activity' : 'search' }}</span>
                <span class="text-lg">Buscar</span>
              </button>
            </div>
          </div>
        </div>

        <!-- Cards promocionales -->
        <div class="grid grid-cols-1 sm:grid-cols-3 gap-5 max-w-4xl mx-auto">
          <!-- Reserva rápida -->
          <div class="promo-card-wrapper animate-slide-up" style="animation-delay: 0.7s;" @click="handleSearch">
            <div class="promo-card promo-card-green">
              <div class="flex items-center justify-between mb-4">
                <div class="h-14 w-14 rounded-2xl bg-gradient-to-br from-emerald-400 to-green-500 flex items-center justify-center shadow-lg shadow-emerald-500/30">
                  <span class="material-symbols-outlined text-white text-3xl">bolt</span>
                </div>
                <span class="material-symbols-outlined text-white/50 promo-arrow">arrow_forward</span>
              </div>
              <p class="text-2xl font-black text-white mb-2">Reserva Rápida</p>
              <p class="text-sm text-white/70 font-medium">Encuentra y reserva en minutos</p>
            </div>
          </div>

          <!-- Verificación -->
          <div class="promo-card-wrapper animate-slide-up" style="animation-delay: 0.8s;">
            <div class="promo-card promo-card-blue">
              <div class="flex items-center justify-between mb-4">
                <div class="h-14 w-14 rounded-2xl bg-gradient-to-br from-blue-400 to-cyan-500 flex items-center justify-center shadow-lg shadow-blue-500/30">
                  <span class="material-symbols-outlined text-white text-3xl">verified</span>
                </div>
                <span class="flex h-3 w-3 rounded-full bg-green-400 status-pulse"></span>
              </div>
              <p class="text-2xl font-black text-white mb-2 group-hover:text-glow">100% Verificado</p>
              <p class="text-sm text-white/70 font-medium">Espacios confiables y seguros</p>
            </div>
          </div>

          <!-- Soporte -->
          <div class="promo-card-wrapper animate-slide-up" style="animation-delay: 0.9s;">
            <div class="promo-card promo-card-purple">
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

    <!-- Sección de contenido principal con transición suave -->
    <section ref="resultsRef" class="relative -mt-8 px-4 sm:px-6 lg:px-8 max-w-7xl mx-auto space-y-6">
      
      <!-- Categorías por tipo de espacio - Diseño tipo Netflix/Airbnb -->
      <div class="relative overflow-hidden rounded-3xl bg-gradient-to-br from-white via-white to-blue-50/30 shadow-xl ring-1 ring-black/5 backdrop-blur-xl">
        <!-- Decoración de fondo -->
        <div class="absolute top-0 right-0 w-96 h-96 bg-gradient-to-br from-primary/5 to-transparent rounded-full blur-3xl -z-0"></div>
        <div class="absolute bottom-0 left-0 w-64 h-64 bg-gradient-to-tr from-purple-500/5 to-transparent rounded-full blur-3xl -z-0"></div>
        
        <div class="relative p-6 sm:p-8">
          <div class="flex items-center justify-between mb-8">
            <div class="flex items-center gap-3">
              <div class="relative">
                <div class="flex h-11 w-11 items-center justify-center rounded-xl bg-gradient-to-br from-primary to-primary-dark shadow-md">
                  <span class="material-symbols-outlined text-white text-xl">category</span>
                </div>
                <div class="absolute -top-1 -right-1 h-4 w-4 rounded-full bg-gradient-to-br from-green-400 to-emerald-500 border-2 border-white shadow-sm animate-pulse"></div>
              </div>
              <div>
                <h3 class="text-lg sm:text-xl font-bold text-gray-900">¿Qué tipo de espacio buscas?</h3>
                <p class="text-xs sm:text-sm text-gray-500 mt-0.5">Selecciona una categoría para filtrar</p>
              </div>
            </div>
            
            <!-- Botón restablecer filtros -->
            <button 
              v-if="selectedCategory || selectedSizeFilter !== 'all'"
              type="button"
              class="inline-flex items-center gap-1.5 text-xs sm:text-sm font-semibold text-gray-600 hover:text-primary transition px-3 py-2 rounded-lg hover:bg-white/60 active:scale-95"
              @click="resetFilters"
            >
              <span class="material-symbols-outlined !text-[18px]">restart_alt</span>
              <span class="hidden sm:inline">Restablecer</span>
            </button>
          </div>
          
          <!-- Grid de categorías mejorado -->
          <div class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-7 gap-3 mb-6">
            <button
              v-for="cat in spaceCategories"
              :key="cat.value"
              type="button"
              class="group relative flex flex-col items-center justify-center p-4 sm:p-5 rounded-2xl transition-all duration-300 transform hover:scale-105 hover:-translate-y-1 active:scale-95"
              :class="selectedCategory === cat.value 
                ? `${getCategoryColor(cat.color, true)} shadow-xl ring-2 ring-offset-2 ring-offset-white` 
                : `${getCategoryColor(cat.color, false)} hover:shadow-lg`"
              @click="selectCategory(cat.value)"
            >
              <!-- Badge de contador -->
              <div 
                v-if="categoryCountMap[cat.value] > 0"
                class="absolute top-2 right-2 flex items-center justify-center min-w-[20px] h-5 px-1.5 rounded-full text-xs font-bold transition-transform group-hover:scale-110"
                :class="selectedCategory === cat.value ? 'bg-white/30 text-white shadow-sm' : 'bg-white text-gray-700 shadow-sm'"
              >
                {{ categoryCountMap[cat.value] }}
              </div>
              
              <!-- Icono -->
              <div class="relative mb-2.5">
                <span 
                  class="material-symbols-outlined text-3xl sm:text-4xl transition-all duration-300 group-hover:scale-110"
                  :class="selectedCategory === cat.value ? 'text-white' : ''"
                >{{ cat.icon }}</span>
              </div>
              
              <!-- Texto -->
              <span 
                class="text-xs sm:text-sm font-bold text-center leading-tight"
                :class="selectedCategory === cat.value ? 'text-white' : ''"
              >{{ cat.label }}</span>
              
              <!-- Descripción (oculta en móviles) -->
              <span 
                class="text-[10px] text-center leading-tight mt-1 hidden lg:block"
                :class="selectedCategory === cat.value ? 'text-white/80' : 'text-gray-500'"
              >{{ cat.description }}</span>
              
              <!-- Efecto hover -->
              <div 
                class="absolute inset-0 rounded-2xl opacity-0 group-hover:opacity-100 transition-opacity duration-300 pointer-events-none"
                :class="selectedCategory === cat.value ? '' : 'bg-gradient-to-t from-white/50 to-transparent'"
              ></div>
            </button>
          </div>

          <!-- Filtros por capacidad - Diseño horizontal mejorado -->
          <div class="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 pt-6 border-t border-gray-100">
            <div class="flex flex-wrap items-center gap-2 sm:gap-3">
              <span class="text-xs font-semibold text-gray-400 uppercase tracking-wider flex items-center gap-1.5">
                <span class="material-symbols-outlined !text-[16px]">groups</span>
                Por capacidad:
              </span>
              
              <div class="flex flex-wrap items-center gap-2">
                <button
                  type="button"
                  class="inline-flex items-center gap-1.5 sm:gap-2 rounded-xl px-3 sm:px-4 py-2 text-xs sm:text-sm font-bold transition-all duration-300 active:scale-95"
                  :class="selectedSizeFilter === 'all' 
                    ? 'bg-gradient-to-r from-primary to-primary-dark text-white shadow-lg shadow-primary/30 ring-2 ring-primary/20 ring-offset-2' 
                    : 'bg-white text-gray-600 border border-gray-200 hover:border-primary/50 hover:text-primary hover:shadow-md'"
                  @click="selectedSizeFilter = 'all'"
                >
                  <span class="material-symbols-outlined !text-[16px] sm:!text-[18px]">home_work</span>
                  <span>Todos</span>
                </button>

                <button
                  type="button"
                  class="inline-flex items-center gap-1.5 sm:gap-2 rounded-xl px-3 sm:px-4 py-2 text-xs sm:text-sm font-bold transition-all duration-300 active:scale-95"
                  :class="selectedSizeFilter === 'small' 
                    ? 'bg-gradient-to-r from-green-500 to-emerald-600 text-white shadow-lg shadow-green-500/30 ring-2 ring-green-500/20 ring-offset-2' 
                    : 'bg-white text-gray-600 border border-gray-200 hover:border-green-500/50 hover:text-green-600 hover:shadow-md'"
                  @click="selectedSizeFilter = 'small'"
                >
                  <span class="material-symbols-outlined !text-[16px] sm:!text-[18px]">person</span>
                  <span>&lt;20</span>
                  <span class="text-[10px] sm:text-xs opacity-75 bg-white/20 px-1.5 py-0.5 rounded-full">{{ sizeFilters.small }}</span>
                </button>

                <button
                  type="button"
                  class="inline-flex items-center gap-1.5 sm:gap-2 rounded-xl px-3 sm:px-4 py-2 text-xs sm:text-sm font-bold transition-all duration-300 active:scale-95"
                  :class="selectedSizeFilter === 'medium' 
                    ? 'bg-gradient-to-r from-orange-500 to-amber-600 text-white shadow-lg shadow-orange-500/30 ring-2 ring-orange-500/20 ring-offset-2' 
                    : 'bg-white text-gray-600 border border-gray-200 hover:border-orange-500/50 hover:text-orange-600 hover:shadow-md'"
                  @click="selectedSizeFilter = 'medium'"
                >
                  <span class="material-symbols-outlined !text-[16px] sm:!text-[18px]">group</span>
                  <span>20-50</span>
                  <span class="text-[10px] sm:text-xs opacity-75 bg-white/20 px-1.5 py-0.5 rounded-full">{{ sizeFilters.medium }}</span>
                </button>

                <button
                  type="button"
                  class="inline-flex items-center gap-1.5 sm:gap-2 rounded-xl px-3 sm:px-4 py-2 text-xs sm:text-sm font-bold transition-all duration-300 active:scale-95"
                  :class="selectedSizeFilter === 'large' 
                    ? 'bg-gradient-to-r from-purple-500 to-pink-600 text-white shadow-lg shadow-purple-500/30 ring-2 ring-purple-500/20 ring-offset-2' 
                    : 'bg-white text-gray-600 border border-gray-200 hover:border-purple-500/50 hover:text-purple-600 hover:shadow-md'"
                  @click="selectedSizeFilter = 'large'"
                >
                  <span class="material-symbols-outlined !text-[16px] sm:!text-[18px]">groups</span>
                  <span>50+</span>
                  <span class="text-[10px] sm:text-xs opacity-75 bg-white/20 px-1.5 py-0.5 rounded-full">{{ sizeFilters.large }}</span>
                </button>
              </div>
            </div>

            <!-- Controles de vista y ordenamiento -->
            <div class="flex items-center gap-3">
              <!-- Controles de vista con diseño premium -->
              <div class="relative flex items-center bg-gray-100/80 p-1 rounded-xl border border-gray-200/50 shadow-inner w-[104px] sm:w-[120px]">
                <!-- Fondo deslizante -->
                <div 
                  class="absolute inset-y-1 w-[calc(50%-4px)] bg-white rounded-lg shadow-sm ring-1 ring-black/5 transition-all duration-300 ease-[cubic-bezier(0.34,1.56,0.64,1)]"
                  :class="viewMode === 'grid' ? 'left-1' : 'left-[calc(50%+2px)]'"
                ></div>

                <!-- Botón Grid -->
                <button
                  type="button"
                  class="relative z-10 flex-1 flex items-center justify-center py-2 rounded-lg transition-colors duration-200"
                  :class="viewMode === 'grid' ? 'text-primary' : 'text-gray-500 hover:text-gray-700'"
                  @click="viewMode = 'grid'"
                  title="Vista en cuadrícula"
                >
                  <span class="material-symbols-outlined !text-[20px] transition-transform duration-300" :class="{ 'scale-110': viewMode === 'grid' }">grid_view</span>
                </button>

                <!-- Botón Lista -->
                <button
                  type="button"
                  class="relative z-10 flex-1 flex items-center justify-center py-2 rounded-lg transition-colors duration-200"
                  :class="viewMode === 'list' ? 'text-primary' : 'text-gray-500 hover:text-gray-700'"
                  @click="viewMode = 'list'"
                  title="Vista en lista"
                >
                  <span class="material-symbols-outlined !text-[20px] transition-transform duration-300" :class="{ 'scale-110': viewMode === 'list' }">view_list</span>
                </button>
              </div>

              <!-- Selector de ordenamiento compacto -->
              <div class="relative">
                <select
                  v-model="sortOption"
                  class="appearance-none bg-white border border-gray-200 rounded-xl pl-3 pr-10 py-2 text-xs sm:text-sm font-semibold text-gray-700 hover:border-primary/50 focus:border-primary focus:ring-2 focus:ring-primary/20 transition-all cursor-pointer shadow-sm"
                >
                  <option value="recent">Más recientes</option>
                  <option value="capacity">Mayor capacidad</option>
                  <option value="price">Menor precio</option>
                  <option value="name">A-Z</option>
                </select>
                <span class="material-symbols-outlined absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 pointer-events-none !text-[18px]">unfold_more</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Filtros avanzados (colapsable en acordeón) -->
      <details class="group rounded-3xl bg-white shadow-lg ring-1 ring-black/5 overflow-hidden transition-all duration-300 hover:shadow-xl">
        <summary class="cursor-pointer px-6 py-5 flex items-center justify-between hover:bg-gray-50/50 transition-colors select-none">
          <div class="flex items-center gap-3">
            <div class="flex h-10 w-10 items-center justify-center rounded-xl bg-gradient-to-br from-indigo-500 to-purple-600 shadow-md group-open:shadow-lg transition-shadow">
              <span class="material-symbols-outlined text-white text-xl">tune</span>
            </div>
            <div>
              <h3 class="font-bold text-gray-900 text-base sm:text-lg">Filtros avanzados</h3>
              <p class="text-xs text-gray-500 mt-0.5">Afina tu búsqueda con más opciones</p>
            </div>
          </div>
          <span class="material-symbols-outlined text-gray-400 group-open:rotate-180 transition-transform duration-300">expand_more</span>
        </summary>

        <div class="border-t border-gray-100 p-6 bg-gradient-to-br from-gray-50/50 to-white">
          <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-5">
            <!-- Capacidad mínima -->
            <div class="space-y-2">
              <label class="block text-xs sm:text-sm font-bold text-gray-700">
                <span class="flex items-center gap-2">
                  <span class="material-symbols-outlined !text-[16px] text-emerald-600">group_add</span>
                  Capacidad mínima
                </span>
              </label>
              <div class="relative">
                <input
                  v-model="capacityInput"
                  type="number"
                  min="1"
                  placeholder="Ej: 10 personas"
                  class="w-full h-11 rounded-xl border-gray-200 bg-white px-4 py-3 pr-12 text-sm text-gray-900 placeholder:text-gray-400 focus:border-emerald-500 focus:ring-2 focus:ring-emerald-500/20 transition-all shadow-sm"
                />
                <span class="material-symbols-outlined absolute right-3 top-1/2 -translate-y-1/2 text-gray-300 !text-[20px]">person</span>
              </div>
            </div>

            <!-- Capacidad máxima -->
            <div class="space-y-2">
              <label class="block text-xs sm:text-sm font-bold text-gray-700">
                <span class="flex items-center gap-2">
                  <span class="material-symbols-outlined !text-[16px] text-orange-600">group_remove</span>
                  Capacidad máxima
                </span>
              </label>
              <div class="relative">
                <input
                  v-model.number="maxCapacity"
                  type="number"
                  min="1"
                  placeholder="Ej: 100 personas"
                  class="w-full h-11 rounded-xl border-gray-200 bg-white px-4 py-3 pr-12 text-sm text-gray-900 placeholder:text-gray-400 focus:border-orange-500 focus:ring-2 focus:ring-orange-500/20 transition-all shadow-sm"
                />
                <span class="material-symbols-outlined absolute right-3 top-1/2 -translate-y-1/2 text-gray-300 !text-[20px]">groups</span>
              </div>
            </div>

            <!-- Botón aplicar filtros (en móviles) -->
            <div class="flex items-end sm:col-span-2 lg:col-span-1">
              <button
                type="button"
                class="w-full h-11 inline-flex items-center justify-center gap-2 rounded-xl bg-gradient-to-r from-primary to-primary-dark text-white font-bold text-sm shadow-lg shadow-primary/30 hover:shadow-xl hover:shadow-primary/40 active:scale-[0.98] transition-all"
                @click="handleSearch"
              >
                <span class="material-symbols-outlined !text-[18px]">filter_alt</span>
                <span>Aplicar filtros</span>
              </button>
            </div>
          </div>
        </div>
      </details>

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
              :view-mode="viewMode"
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
              :view-mode="viewMode"
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
              :view-mode="viewMode"
            />
          </div>
        </div>
      </div>
    </section>
  </div>
</template>

<style scoped>
/* ========== OPTIMIZADO PARA RENDIMIENTO ==========
   - Usa will-change solo donde es necesario
   - Animaciones CSS puras (GPU accelerated)
   - Reduce repaints y reflows
   - contain: layout para aislar elementos
========== */

/* ========== FONDO ANIMADO (GPU) ========== */
.hero-animated-bg {
  background: linear-gradient(-45deg, #1e40af, #3b82f6, #0ea5e9, #1e3a8a, #2563eb);
  background-size: 400% 400%;
  animation: gradient-flow 20s ease infinite;
  contain: layout style;
}

@keyframes gradient-flow {
  0%, 100% { background-position: 0% 50%; }
  50% { background-position: 100% 50%; }
}

/* ========== PARTÍCULAS CSS PURAS ========== */
.particles-container {
  position: absolute;
  inset: 0;
  overflow: hidden;
  pointer-events: none;
  contain: strict;
}

.particle {
  position: absolute;
  border-radius: 50%;
  opacity: 0.4;
  will-change: transform;
}

.particle-1 {
  width: 6px; height: 6px;
  background: rgba(96, 165, 250, 0.8);
  box-shadow: 0 0 12px rgba(96, 165, 250, 0.6);
  top: 15%; left: 10%;
  animation: float-particle 25s ease-in-out infinite;
}

.particle-2 {
  width: 4px; height: 4px;
  background: rgba(167, 139, 250, 0.8);
  box-shadow: 0 0 10px rgba(167, 139, 250, 0.6);
  top: 25%; right: 15%;
  animation: float-particle 20s ease-in-out infinite reverse;
}

.particle-3 {
  width: 5px; height: 5px;
  background: rgba(34, 211, 238, 0.8);
  box-shadow: 0 0 10px rgba(34, 211, 238, 0.6);
  bottom: 30%; left: 20%;
  animation: float-particle 22s ease-in-out infinite;
  animation-delay: -5s;
}

.particle-4 {
  width: 3px; height: 3px;
  background: rgba(251, 191, 36, 0.7);
  box-shadow: 0 0 8px rgba(251, 191, 36, 0.5);
  top: 40%; right: 25%;
  animation: float-particle 18s ease-in-out infinite;
  animation-delay: -3s;
}

.particle-5 {
  width: 4px; height: 4px;
  background: rgba(244, 114, 182, 0.7);
  box-shadow: 0 0 10px rgba(244, 114, 182, 0.5);
  bottom: 20%; right: 10%;
  animation: float-particle 24s ease-in-out infinite reverse;
  animation-delay: -8s;
}

.particle-6 {
  width: 5px; height: 5px;
  background: rgba(74, 222, 128, 0.7);
  box-shadow: 0 0 10px rgba(74, 222, 128, 0.5);
  top: 60%; left: 30%;
  animation: float-particle 21s ease-in-out infinite;
  animation-delay: -10s;
}

.particle-7 {
  width: 3px; height: 3px;
  background: rgba(129, 140, 248, 0.8);
  box-shadow: 0 0 8px rgba(129, 140, 248, 0.6);
  top: 70%; right: 35%;
  animation: float-particle 19s ease-in-out infinite reverse;
  animation-delay: -2s;
}

.particle-8 {
  width: 4px; height: 4px;
  background: rgba(252, 211, 77, 0.7);
  box-shadow: 0 0 10px rgba(252, 211, 77, 0.5);
  bottom: 40%; left: 45%;
  animation: float-particle 23s ease-in-out infinite;
  animation-delay: -7s;
}

@keyframes float-particle {
  0%, 100% { transform: translate(0, 0); }
  25% { transform: translate(30px, -40px); }
  50% { transform: translate(-20px, 30px); }
  75% { transform: translate(40px, 20px); }
}

/* ========== CLICK RIPPLE ========== */
.click-ripple {
  position: absolute;
  width: 0;
  height: 0;
  border-radius: 50%;
  background: radial-gradient(circle, rgba(255,255,255,0.5) 0%, transparent 70%);
  transform: translate(-50%, -50%);
  animation: ripple-expand 0.8s ease-out forwards;
  pointer-events: none;
  will-change: width, height, opacity;
}

@keyframes ripple-expand {
  0% { width: 0; height: 0; opacity: 1; }
  100% { width: 250px; height: 250px; opacity: 0; }
}

/* ========== AURORA (CSS only) ========== */
.aurora-container {
  position: absolute;
  inset: 0;
  overflow: hidden;
  pointer-events: none;
  opacity: 0.15;
  contain: strict;
}

.aurora {
  position: absolute;
  border-radius: 50%;
  filter: blur(80px);
  will-change: transform;
}

.aurora-1 {
  width: 400px; height: 400px;
  background: linear-gradient(135deg, rgba(56, 189, 248, 0.5), rgba(59, 130, 246, 0.3));
  top: -100px; left: 10%;
  animation: aurora-float 25s ease-in-out infinite;
}

.aurora-2 {
  width: 350px; height: 350px;
  background: linear-gradient(135deg, rgba(168, 85, 247, 0.4), rgba(236, 72, 153, 0.3));
  bottom: -50px; right: 15%;
  animation: aurora-float 20s ease-in-out infinite reverse;
}

@keyframes aurora-float {
  0%, 100% { transform: translate(0, 0) scale(1); }
  50% { transform: translate(50px, 30px) scale(1.1); }
}

/* ========== ORBES FLOTANTES ========== */
.floating-orbs {
  position: absolute;
  inset: 0;
  pointer-events: none;
  contain: strict;
}

.orb {
  position: absolute;
  border-radius: 50%;
  will-change: transform;
}

.orb-1 {
  width: 8px; height: 8px;
  background: rgba(255, 255, 255, 0.4);
  box-shadow: 0 0 15px rgba(255, 255, 255, 0.3);
  top: 15%; left: 8%;
  animation: orb-float 6s ease-in-out infinite;
}

.orb-2 {
  width: 10px; height: 10px;
  background: rgba(34, 211, 238, 0.5);
  box-shadow: 0 0 20px rgba(34, 211, 238, 0.3);
  top: 30%; right: 12%;
  animation: orb-float 7s ease-in-out infinite;
  animation-delay: -2s;
}

.orb-3 {
  width: 6px; height: 6px;
  background: rgba(251, 191, 36, 0.5);
  box-shadow: 0 0 12px rgba(251, 191, 36, 0.3);
  bottom: 25%; left: 25%;
  animation: orb-float 5s ease-in-out infinite;
  animation-delay: -1s;
}

.orb-4 {
  width: 7px; height: 7px;
  background: rgba(244, 114, 182, 0.4);
  box-shadow: 0 0 14px rgba(244, 114, 182, 0.3);
  top: 45%; right: 30%;
  animation: orb-float 8s ease-in-out infinite;
  animation-delay: -3s;
}

@keyframes orb-float {
  0%, 100% { transform: translateY(0); opacity: 0.6; }
  50% { transform: translateY(-15px); opacity: 1; }
}

/* ========== FORMAS GEOMÉTRICAS ========== */
.geometric-shapes {
  position: absolute;
  inset: 0;
  pointer-events: none;
  contain: strict;
}

.shape {
  position: absolute;
  border: 2px solid rgba(255, 255, 255, 0.1);
  will-change: transform;
}

.shape-1 {
  width: 80px; height: 80px;
  border-radius: 16px;
  top: 50%; right: 20%;
  animation: rotate-shape 30s linear infinite;
}

.shape-2 {
  width: 60px; height: 60px;
  border-radius: 50%;
  bottom: 25%; left: 15%;
  animation: rotate-shape 25s linear infinite reverse;
}

@keyframes rotate-shape {
  from { transform: rotate(0deg); }
  to { transform: rotate(360deg); }
}

/* ========== CURSOR GLOW ========== */
.cursor-glow {
  position: absolute;
  width: 200px;
  height: 200px;
  border-radius: 50%;
  pointer-events: none;
  background: radial-gradient(circle, rgba(255,255,255,0.12) 0%, transparent 70%);
  left: var(--mouse-x, 50%);
  top: var(--mouse-y, 50%);
  transform: translate(-50%, -50%);
  opacity: 0;
  transition: opacity 0.3s ease;
  will-change: left, top;
}

.cursor-glow-visible {
  opacity: 1;
}

/* ========== ANIMACIONES DE ENTRADA ========== */
.animate-slide-down {
  animation: slide-down 0.6s ease-out forwards;
}

@keyframes slide-down {
  from { opacity: 0; transform: translateY(-20px); }
  to { opacity: 1; transform: translateY(0); }
}

.animate-slide-up {
  animation: slide-up 0.6s ease-out forwards;
  opacity: 0;
}

@keyframes slide-up {
  from { opacity: 0; transform: translateY(30px); }
  to { opacity: 1; transform: translateY(0); }
}

.animate-fade-in {
  animation: fade-in 0.5s ease-out forwards;
  opacity: 0;
}

@keyframes fade-in {
  from { opacity: 0; }
  to { opacity: 1; }
}

.animate-fade-in-up {
  animation: fade-in-up 0.6s ease-out forwards;
  opacity: 0;
}

@keyframes fade-in-up {
  from { opacity: 0; transform: translateY(15px); }
  to { opacity: 1; transform: translateY(0); }
}

.animate-bounce-in {
  animation: bounce-in 0.6s cubic-bezier(0.68, -0.3, 0.265, 1.3) forwards;
}

@keyframes bounce-in {
  0% { opacity: 0; transform: scale(0.5); }
  70% { transform: scale(1.05); }
  100% { opacity: 1; transform: scale(1); }
}

.animate-scale-in {
  animation: scale-in 0.5s ease-out forwards;
  opacity: 0;
}

@keyframes scale-in {
  from { opacity: 0; transform: scale(0.95); }
  to { opacity: 1; transform: scale(1); }
}

/* ========== TÍTULO GRADIENTE ========== */
.title-gradient-animated {
  background: linear-gradient(90deg, #fcd34d, #fb923c, #f472b6, #fb923c, #fcd34d);
  background-size: 200% auto;
  -webkit-background-clip: text;
  background-clip: text;
  -webkit-text-fill-color: transparent;
  animation: gradient-text 4s linear infinite;
}

@keyframes gradient-text {
  from { background-position: 0% center; }
  to { background-position: 200% center; }
}

.title-underline {
  background: linear-gradient(90deg, #fcd34d, #fb923c, #f472b6);
  opacity: 0.7;
  animation: underline-expand 0.8s ease-out 0.5s forwards;
  transform: scaleX(0);
  transform-origin: left;
}

@keyframes underline-expand {
  to { transform: scaleX(1); }
}

/* ========== EFECTOS HOVER SIMPLES ========== */
.text-glow {
  text-shadow: 0 0 20px rgba(255, 255, 255, 0.4);
}

.avatar-glow {
  transition: box-shadow 0.3s ease;
}

.avatar-glow:hover {
  box-shadow: 0 0 25px rgba(255, 255, 255, 0.3);
}

.hover-lift {
  transition: transform 0.2s ease;
}

.hover-lift:hover {
  transform: translateY(-2px);
}

.btn-hover {
  transition: all 0.2s ease;
}

.btn-hover:hover {
  background: rgba(255, 255, 255, 0.25);
  transform: translateY(-1px);
}

/* ========== STATUS PULSE (optimizado) ========== */
.status-pulse {
  animation: status-pulse 2s ease-in-out infinite;
}

@keyframes status-pulse {
  0%, 100% { opacity: 1; transform: scale(1); }
  50% { opacity: 0.7; transform: scale(1.1); }
}

/* ========== BADGE SHIMMER ========== */
.badge-shimmer {
  position: relative;
  overflow: hidden;
}

.badge-shimmer::after {
  content: '';
  position: absolute;
  top: 0;
  left: -100%;
  width: 50%;
  height: 100%;
  background: linear-gradient(90deg, transparent, rgba(255, 255, 255, 0.15), transparent);
  animation: shimmer 4s ease-in-out infinite;
}

@keyframes shimmer {
  0% { left: -100%; }
  50%, 100% { left: 200%; }
}

/* ========== SEARCH CARD ========== */
.search-card {
  transition: transform 0.3s ease, box-shadow 0.3s ease;
}

.search-card:hover {
  transform: translateY(-2px);
}

.search-glow-border {
  position: absolute;
  inset: -2px;
  background: linear-gradient(45deg, #06b6d4, #3b82f6, #8b5cf6);
  border-radius: 1.5rem;
  opacity: 0;
  z-index: -1;
  filter: blur(8px);
  transition: opacity 0.4s ease;
  animation: glow-rotate 3s linear infinite;
}

.group:hover .search-glow-border {
  opacity: 0.4;
}

/* Input de búsqueda */
.search-input {
  outline: none !important;
  border: none !important;
  box-shadow: none !important;
}

.search-input:focus {
  outline: none !important;
  border: none !important;
  box-shadow: none !important;
}

.search-input-wrapper {
  position: relative;
  overflow: hidden;
}

.search-input-wrapper::before {
  content: '';
  position: absolute;
  inset: -2px;
  background: linear-gradient(
    90deg,
    transparent,
    rgba(6, 182, 212, 0.4),
    rgba(59, 130, 246, 0.4),
    rgba(139, 92, 246, 0.4),
    transparent
  );
  border-radius: 0.75rem;
  opacity: 0;
  z-index: -1;
  filter: blur(10px);
  transition: opacity 0.5s ease;
  animation: shimmer-glow 3s ease-in-out infinite;
}

.search-input-wrapper:has(.search-input:focus)::before {
  opacity: 1;
  animation: shimmer-glow 2s ease-in-out infinite, pulse-glow 1.5s ease-in-out infinite;
}

.search-input-wrapper:has(.search-input:focus) {
  border-color: rgba(6, 182, 212, 0.3);
  background: linear-gradient(135deg, rgba(255, 255, 255, 0.95), rgba(249, 250, 251, 0.95));
  box-shadow: 
    0 0 20px rgba(6, 182, 212, 0.2),
    0 0 40px rgba(59, 130, 246, 0.1),
    0 4px 20px rgba(0, 0, 0, 0.05);
}

@keyframes shimmer-glow {
  0% { 
    transform: translateX(-100%);
  }
  100% { 
    transform: translateX(200%);
  }
}

@keyframes pulse-glow {
  0%, 100% { 
    filter: blur(10px) brightness(1);
  }
  50% { 
    filter: blur(15px) brightness(1.3);
  }
}

@keyframes glow-rotate {
  0% {
    filter: blur(8px) hue-rotate(0deg);
  }
  100% {
    filter: blur(8px) hue-rotate(360deg);
  }
}

.search-btn {
  position: relative;
  overflow: hidden;
}

.search-btn::before {
  content: '';
  position: absolute;
  top: 0;
  left: -100%;
  width: 100%;
  height: 100%;
  background: linear-gradient(90deg, transparent, rgba(255, 255, 255, 0.2), transparent);
  transition: left 0.5s ease;
}

.search-btn:hover::before {
  left: 100%;
}

/* ========== PROMO CARDS ========== */
.promo-card-wrapper {
  cursor: pointer;
}

.promo-card {
  position: relative;
  background: rgba(255, 255, 255, 0.1);
  backdrop-filter: blur(12px);
  border: 1px solid rgba(255, 255, 255, 0.2);
  border-radius: 1rem;
  padding: 1.75rem;
  transition: all 0.3s ease;
  overflow: hidden;
}

.promo-card::before {
  content: '';
  position: absolute;
  inset: 0;
  background: linear-gradient(135deg, transparent, rgba(255, 255, 255, 0.05));
  opacity: 0;
  transition: opacity 0.3s ease;
}

.promo-card-wrapper:hover .promo-card {
  background: rgba(255, 255, 255, 0.15);
  transform: translateY(-4px);
  box-shadow: 0 20px 40px -10px rgba(0, 0, 0, 0.3);
}

.promo-card-wrapper:hover .promo-card::before {
  opacity: 1;
}

.promo-arrow {
  transition: transform 0.3s ease, color 0.3s ease;
}

.promo-card-wrapper:hover .promo-arrow {
  transform: translateX(4px);
  color: white;
}

/* Card colors on hover */
.promo-card-green:hover { box-shadow: 0 20px 40px -10px rgba(16, 185, 129, 0.3); }
.promo-card-blue:hover { box-shadow: 0 20px 40px -10px rgba(59, 130, 246, 0.3); }
.promo-card-purple:hover { box-shadow: 0 20px 40px -10px rgba(168, 85, 247, 0.3); }

/* ========== REDUCED MOTION ========== */
@media (prefers-reduced-motion: reduce) {
  *,
  *::before,
  *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
  }
  
  .particles-container,
  .aurora-container,
  .floating-orbs,
  .geometric-shapes {
    display: none;
  }
}
</style>