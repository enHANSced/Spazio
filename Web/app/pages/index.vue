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
  <section class="space-y-10">
    <div class="grid gap-6 lg:grid-cols-[2fr,1fr]">
      <div class="rounded-3xl bg-gradient-to-r from-primary/90 to-[#0f5fb7] p-8 text-white">
        <p class="text-sm uppercase tracking-[0.2em] text-white/70">Panel de reservas</p>
        <h1 class="mt-2 text-3xl font-semibold">Hola, {{ user?.name ?? 'Usuario' }}</h1>
        <p class="mt-3 max-w-2xl text-base text-white/80">
          Explora los espacios disponibles en tiempo real y encuentra el lugar perfecto para tu próxima reunión o evento.
        </p>

        <div class="mt-6 grid gap-3 md:grid-cols-[minmax(0,2fr)_minmax(0,1fr)]">
          <label class="flex items-center gap-3 rounded-2xl bg-white/10 px-4 py-3 text-sm backdrop-blur">
            <span class="material-symbols-outlined text-2xl text-white">search</span>
            <input
              v-model.trim="searchQuery"
              type="text"
              placeholder="Buscar por nombre, propietario o descripción"
              class="w-full bg-transparent text-white placeholder:text-white/70 focus:outline-none"
            />
          </label>

          <button
            type="button"
            class="inline-flex items-center justify-center gap-2 rounded-2xl bg-white px-4 py-3 text-sm font-semibold text-primary shadow-lg transition hover:bg-white/90"
            :disabled="isRefreshing"
            @click="reloadSpaces"
          >
            <span class="material-symbols-outlined text-base" :class="{ 'animate-spin': isRefreshing }">refresh</span>
            Actualizar listado
          </button>
        </div>
      </div>

      <div class="rounded-3xl border border-slate-200 bg-white p-6 shadow-sm">
        <div class="flex items-center justify-between gap-4">
          <div>
            <p class="text-sm uppercase tracking-wide text-slate-500">Tu cuenta</p>
            <p class="text-2xl font-semibold text-[#111418]">{{ user?.email }}</p>
          </div>
          <button
            type="button"
            class="rounded-xl border border-slate-200 px-4 py-2 text-sm font-semibold text-slate-600 hover:bg-slate-50"
            @click="logout"
          >
            Cerrar sesión
          </button>
        </div>

        <dl class="mt-6 grid gap-4 sm:grid-cols-3">
          <div class="rounded-2xl bg-slate-50 p-4">
            <dt class="text-xs uppercase tracking-wide text-slate-500">Espacios activos</dt>
            <dd class="mt-2 text-2xl font-semibold text-[#111418]">{{ formatNumber(statsSummary.totalActive) }}</dd>
          </div>
          <div class="rounded-2xl bg-slate-50 p-4">
            <dt class="text-xs uppercase tracking-wide text-slate-500">Cupo promedio</dt>
            <dd class="mt-2 text-2xl font-semibold text-[#111418]">{{ formatNumber(statsSummary.averageCapacity) }}</dd>
          </div>
          <div class="rounded-2xl bg-slate-50 p-4">
            <dt class="text-xs uppercase tracking-wide text-slate-500">Alta capacidad</dt>
            <dd class="mt-2 text-2xl font-semibold text-[#111418]">{{ formatNumber(statsSummary.highCapacity) }}</dd>
          </div>
        </dl>
      </div>
    </div>

    <div class="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
      <div class="flex flex-col gap-4 md:flex-row md:items-end">
        <label class="flex-1 text-sm">
          <span class="text-slate-500">Búsqueda rápida</span>
          <div class="mt-2 flex items-center gap-3 rounded-2xl border border-slate-200 px-4 py-2">
            <span class="material-symbols-outlined text-xl text-slate-400">travel_explore</span>
            <input
              v-model.trim="searchQuery"
              type="text"
              placeholder="Ej. Auditorio, cowork, salón"
              class="w-full border-none bg-transparent text-base text-[#111418] placeholder:text-slate-400 focus:outline-none"
            />
          </div>
        </label>

        <label class="text-sm md:w-40">
          <span class="text-slate-500">Capacidad mínima</span>
          <div class="mt-2 rounded-2xl border border-slate-200 px-4 py-2">
            <input
              v-model="capacityInput"
              type="number"
              min="1"
              placeholder="Sin filtro"
              class="w-full border-none bg-transparent text-base text-[#111418] placeholder:text-slate-400 focus:outline-none"
            />
          </div>
        </label>

        <label class="text-sm md:w-56">
          <span class="text-slate-500">Ordenar por</span>
          <div class="mt-2 rounded-2xl border border-slate-200 px-4 py-2">
            <select
              v-model="sortOption"
              class="w-full border-none bg-transparent text-base text-[#111418] focus:outline-none"
            >
              <option value="recent">Actualizados recientemente</option>
              <option value="capacity">Mayor capacidad</option>
            </select>
          </div>
        </label>

        <button
          type="button"
          class="inline-flex items-center justify-center gap-2 rounded-2xl border border-slate-200 px-4 py-2 text-sm font-semibold text-slate-600 hover:bg-slate-50"
          @click="resetFilters"
        >
          <span class="material-symbols-outlined text-base">layers_clear</span>
          Limpiar
        </button>
      </div>
    </div>

    <div v-if="errorMessage" class="rounded-3xl border border-red-100 bg-red-50/60 p-6 text-red-800">
      <div class="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <p class="text-lg font-semibold">No pudimos cargar los espacios</p>
          <p class="text-sm text-red-700/80">{{ errorMessage }}</p>
        </div>
        <button
          type="button"
          class="inline-flex items-center gap-2 rounded-xl bg-red-600 px-4 py-2 text-sm font-semibold text-white hover:bg-red-500"
          @click="reloadSpaces"
        >
          Reintentar
          <span class="material-symbols-outlined text-base">refresh</span>
        </button>
      </div>
    </div>

    <div v-else>
      <div v-if="pending" class="grid gap-5 sm:grid-cols-2 xl:grid-cols-3">
        <div v-for="n in 6" :key="`skeleton-${n}`" class="h-72 animate-pulse rounded-2xl border border-slate-200 bg-slate-100/70"></div>
      </div>

      <div v-else-if="!filteredSpaces.length" class="rounded-3xl border border-slate-200 bg-white p-10 text-center">
        <div class="mx-auto flex h-20 w-20 items-center justify-center rounded-full bg-slate-100">
          <span class="material-symbols-outlined text-3xl text-slate-400">weekend</span>
        </div>
        <h2 class="mt-6 text-2xl font-semibold text-[#111418]">Aún no hay espacios disponibles con tus filtros</h2>
        <p class="mt-2 text-slate-500">Prueba ajustando la búsqueda o quita la capacidad mínima para ver todas las opciones.</p>
        <button
          type="button"
          class="mt-6 rounded-2xl border border-slate-200 px-5 py-2.5 text-sm font-semibold text-slate-600 hover:bg-slate-50"
          @click="resetFilters"
        >
          Restablecer filtros
        </button>
      </div>

      <div v-else class="space-y-10">
        <div v-if="featuredSpaces.length" class="space-y-4">
          <div class="flex flex-col gap-2 sm:flex-row sm:items-end sm:justify-between">
            <div>
              <p class="text-sm uppercase tracking-wide text-slate-500">Selección rápida</p>
              <h2 class="text-2xl font-semibold text-[#111418]">Destacados para ti</h2>
            </div>
            <p class="text-sm text-slate-500">{{ featuredSpaces.length }} espacios listos para reservar</p>
          </div>
          <div class="grid gap-4 md:grid-cols-3">
            <SpaceCard v-for="space in featuredSpaces" :key="`featured-${space.id}`" :space="space" />
          </div>
        </div>

        <div class="space-y-4">
          <div class="flex flex-col gap-2 sm:flex-row sm:items-end sm:justify-between">
            <div>
              <p class="text-sm uppercase tracking-wide text-slate-500">Catálogo completo</p>
              <h2 class="text-2xl font-semibold text-[#111418]">Todos los espacios disponibles</h2>
            </div>
            <p class="text-sm text-slate-500">{{ filteredSpaces.length }} resultados</p>
          </div>

          <div class="grid gap-5 sm:grid-cols-2 xl:grid-cols-3">
            <SpaceCard
              v-for="space in (secondarySpaces.length ? secondarySpaces : filteredSpaces)"
              :key="space.id"
              :space="space"
            />
          </div>
        </div>
      </div>
    </div>
  </section>
</template>
