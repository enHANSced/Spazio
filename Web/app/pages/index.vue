<script setup lang="ts">
import { computed, ref } from 'vue'
import SpacesService from '~/services/spaces.service'
import type { Space } from '~/types/space'

definePageMeta({
  middleware: 'auth'
})

const { user, logout } = useAuth()

const searchQuery = ref('')
const minCapacity = ref<number | null>(null)
const sortOption = ref<'recent' | 'capacity'>('recent')

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
    .filter((space) => (minCapacity.value ? space.capacity >= minCapacity.value : true))
    .sort((a, b) => {
      if (sortOption.value === 'capacity') {
        return b.capacity - a.capacity
      }
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

const reloadSpaces = async () => {
  if (isRefreshing.value) return
  isRefreshing.value = true
  try {
    await refresh()
  } finally {
    isRefreshing.value = false
  }
}

const resetFilters = () => {
  searchQuery.value = ''
  minCapacity.value = null
  sortOption.value = 'recent'
}

const formatNumber = (value: number) => new Intl.NumberFormat('es-ES').format(value)
</script>

<template>
  <div class="min-h-screen bg-gradient-to-br from-gray-50 via-white to-blue-50/30">
    <!-- Hero Section -->
    <section class="relative overflow-hidden bg-gradient-to-br from-primary via-blue-600 to-indigo-700 pb-12 pt-8">
      <!-- Patrón de fondo decorativo -->
      <div class="absolute inset-0 opacity-10">
        <div class="absolute left-1/4 top-0 h-96 w-96 rounded-full bg-white blur-3xl"></div>
        <div class="absolute right-1/4 bottom-0 h-96 w-96 rounded-full bg-white blur-3xl"></div>
      </div>

      <div class="relative px-4 sm:px-6 lg:px-8 max-w-7xl mx-auto">
        <!-- Header con usuario y logout -->
        <div class="flex items-center justify-between mb-8">
          <div class="flex items-center gap-3">
            <div class="h-10 w-10 rounded-full bg-white/20 backdrop-blur flex items-center justify-center">
              <span class="material-symbols-outlined text-white text-2xl">account_circle</span>
            </div>
            <div>
              <p class="text-xs text-white/70 uppercase tracking-wide">Bienvenido de vuelta</p>
              <p class="text-white font-semibold">{{ user?.name ?? user?.email ?? 'Usuario' }}</p>
            </div>
          </div>
          
          <button
            type="button"
            class="inline-flex items-center gap-2 rounded-lg bg-white/10 backdrop-blur border border-white/20 px-4 py-2 text-sm font-medium text-white hover:bg-white/20 transition"
            @click="logout"
          >
            <span class="material-symbols-outlined !text-[18px]">logout</span>
            Cerrar sesión
          </button>
        </div>

        <!-- Título y descripción -->
        <div class="text-center max-w-3xl mx-auto mb-10">
          <h1 class="text-4xl md:text-5xl font-black text-white tracking-tight leading-tight">
            Encuentra y reserva el espacio perfecto
          </h1>
          <p class="mt-4 text-lg text-white/90">
            Explora espacios únicos cerca de ti. Ideal para reuniones, eventos, coworking y más.
          </p>
        </div>

        <!-- Barra de búsqueda principal -->
        <div class="max-w-4xl mx-auto">
          <div class="flex flex-col sm:flex-row gap-3">
            <div class="flex-1 flex items-center gap-3 rounded-2xl bg-white px-5 py-4 shadow-2xl">
              <span class="material-symbols-outlined text-2xl text-gray-400">search</span>
              <input
                v-model.trim="searchQuery"
                type="text"
                placeholder="Buscar por nombre, descripción o propietario..."
                class="flex-1 bg-transparent text-gray-900 placeholder:text-gray-400 focus:outline-none text-base"
              />
            </div>
            
            <button
              type="button"
              class="inline-flex items-center justify-center gap-2 rounded-2xl bg-white px-6 py-4 text-base font-bold text-primary shadow-2xl transition hover:bg-gray-50"
              :disabled="isRefreshing"
              @click="reloadSpaces"
            >
              <span class="material-symbols-outlined" :class="{ 'animate-spin': isRefreshing }">refresh</span>
              Actualizar
            </button>
          </div>

          <!-- Stats rápidas -->
          <div class="mt-6 flex flex-wrap items-center justify-center gap-6 text-white/90">
            <div class="flex items-center gap-2">
              <span class="material-symbols-outlined text-white/70">home_work</span>
              <span class="font-semibold">{{ formatNumber(statsSummary.totalActive) }}</span>
              <span class="text-sm text-white/70">espacios activos</span>
            </div>
            <div class="h-4 w-px bg-white/30 hidden sm:block"></div>
            <div class="flex items-center gap-2">
              <span class="material-symbols-outlined text-white/70">groups</span>
              <span class="font-semibold">{{ formatNumber(statsSummary.averageCapacity) }}</span>
              <span class="text-sm text-white/70">capacidad promedio</span>
            </div>
            <div class="h-4 w-px bg-white/30 hidden sm:block"></div>
            <div class="flex items-center gap-2">
              <span class="material-symbols-outlined text-white/70">celebration</span>
              <span class="font-semibold">{{ formatNumber(statsSummary.highCapacity) }}</span>
              <span class="text-sm text-white/70">alta capacidad</span>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- Sección de contenido principal -->
    <section class="px-4 sm:px-6 lg:px-8 py-10 max-w-7xl mx-auto space-y-8">
      <!-- Filtros avanzados -->
      <div class="rounded-2xl border border-gray-200 bg-white p-5 shadow-sm">
        <div class="flex flex-wrap gap-4 items-end">
          <div class="flex-1 min-w-[200px]">
            <label class="block text-sm font-medium text-gray-700 mb-2">
              <span class="flex items-center gap-2">
                <span class="material-symbols-outlined !text-[18px]">filter_list</span>
                Capacidad mínima
              </span>
            </label>
            <input
              v-model="capacityInput"
              type="number"
              min="1"
              placeholder="Ej: 10"
              class="w-full rounded-lg border border-gray-300 px-4 py-2.5 text-gray-900 placeholder:text-gray-400 focus:border-primary focus:ring-2 focus:ring-primary/20 focus:outline-none"
            />
          </div>

          <div class="flex-1 min-w-[200px]">
            <label class="block text-sm font-medium text-gray-700 mb-2">
              <span class="flex items-center gap-2">
                <span class="material-symbols-outlined !text-[18px]">sort</span>
                Ordenar por
              </span>
            </label>
            <select
              v-model="sortOption"
              class="w-full rounded-lg border border-gray-300 px-4 py-2.5 text-gray-900 focus:border-primary focus:ring-2 focus:ring-primary/20 focus:outline-none"
            >
              <option value="recent">Actualizados recientemente</option>
              <option value="capacity">Mayor capacidad</option>
            </select>
          </div>

          <button
            type="button"
            class="inline-flex items-center justify-center gap-2 rounded-lg border border-gray-300 bg-white px-5 py-2.5 text-sm font-semibold text-gray-700 hover:bg-gray-50 transition"
            @click="resetFilters"
          >
            <span class="material-symbols-outlined !text-[18px]">clear_all</span>
            Limpiar filtros
          </button>
        </div>
      </div>

      <!-- Mensajes de error -->
      <div v-if="errorMessage" class="rounded-xl border border-red-200 bg-red-50 p-6">
        <div class="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
          <div class="flex items-start gap-3">
            <span class="material-symbols-outlined text-2xl text-red-600">error</span>
            <div>
              <p class="font-semibold text-red-900">Error al cargar los espacios</p>
              <p class="mt-1 text-sm text-red-700">{{ errorMessage }}</p>
            </div>
          </div>
          <button
            type="button"
            class="inline-flex items-center gap-2 rounded-lg bg-red-600 px-4 py-2 text-sm font-semibold text-white hover:bg-red-700 transition"
            @click="reloadSpaces"
          >
            <span class="material-symbols-outlined !text-[18px]">refresh</span>
            Reintentar
          </button>
        </div>
      </div>

      <!-- Loading skeletons -->
      <div v-else-if="pending">
        <div class="mb-4">
          <div class="h-8 w-48 animate-pulse bg-gray-200 rounded"></div>
        </div>
        <div class="grid gap-6 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
          <div v-for="n in 8" :key="`skeleton-${n}`" class="h-96 animate-pulse rounded-xl bg-gray-100"></div>
        </div>
      </div>

      <!-- Estado vacío -->
      <div v-else-if="!filteredSpaces.length" class="rounded-2xl border border-gray-200 bg-white p-12 text-center">
        <div class="mx-auto flex h-24 w-24 items-center justify-center rounded-full bg-gray-100">
          <span class="material-symbols-outlined text-4xl text-gray-400">search_off</span>
        </div>
        <h2 class="mt-6 text-2xl font-bold text-gray-900">No se encontraron espacios</h2>
        <p class="mt-2 text-gray-600">Intenta ajustar los filtros para ver más resultados</p>
        <button
          type="button"
          class="mt-6 inline-flex items-center gap-2 rounded-lg bg-primary px-6 py-2.5 text-sm font-semibold text-white hover:bg-primary/90 transition"
          @click="resetFilters"
        >
          <span class="material-symbols-outlined !text-[18px]">refresh</span>
          Restablecer filtros
        </button>
      </div>

      <!-- Grid de espacios -->
      <div v-else class="space-y-10">
        <!-- Espacios destacados -->
        <div v-if="featuredSpaces.length">
          <div class="mb-6 flex flex-col gap-2 sm:flex-row sm:items-end sm:justify-between">
            <div>
              <p class="text-sm font-medium text-primary uppercase tracking-wider">Destacados</p>
              <h2 class="text-2xl font-bold text-gray-900 mt-1">Los espacios más populares</h2>
            </div>
            <p class="text-sm text-gray-600">{{ featuredSpaces.length }} disponibles</p>
          </div>
          <div class="grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
            <SpaceCard v-for="space in featuredSpaces" :key="`featured-${space.id}`" :space="space" />
          </div>
        </div>

        <!-- Todos los espacios -->
        <div v-if="secondarySpaces.length">
          <div class="mb-6 flex flex-col gap-2 sm:flex-row sm:items-end sm:justify-between">
            <div>
              <p class="text-sm font-medium text-gray-500 uppercase tracking-wider">Catálogo completo</p>
              <h2 class="text-2xl font-bold text-gray-900 mt-1">Más espacios disponibles</h2>
            </div>
            <p class="text-sm text-gray-600">{{ filteredSpaces.length }} resultados totales</p>
          </div>
          <div class="grid gap-6 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
            <SpaceCard
              v-for="space in secondarySpaces"
              :key="space.id"
              :space="space"
            />
          </div>
        </div>

        <!-- Si no hay secundarios, mostrar todos en un solo grid -->
        <div v-else-if="!featuredSpaces.length">
          <div class="mb-6">
            <h2 class="text-2xl font-bold text-gray-900">Espacios disponibles</h2>
            <p class="text-sm text-gray-600 mt-1">{{ filteredSpaces.length }} resultados encontrados</p>
          </div>
          <div class="grid gap-6 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
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
