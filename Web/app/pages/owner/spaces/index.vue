<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useAuthStore } from '../../../stores/auth'
import type { Space } from '../../../types/space'
import OwnerSpacesService from '../../../services/owner-spaces.service'

definePageMeta({
  layout: 'owner',
  middleware: 'verified-owner'
})

useSeoMeta({
  title: 'Mis Espacios - Spazio',
  description: 'Gestiona tus espacios'
})

const authStore = useAuthStore()
const spaces = ref<Space[]>([])
const loading = ref(true)
const error = ref('')
const searchQuery = ref('')
const statusFilter = ref<'all' | 'active' | 'inactive'>('all')

const filteredSpaces = computed(() => {
  let filtered = spaces.value

  // Filtrar por búsqueda
  if (searchQuery.value) {
    const query = searchQuery.value.toLowerCase()
    filtered = filtered.filter(space => 
      space.name.toLowerCase().includes(query) ||
      space.description?.toLowerCase().includes(query)
    )
  }

  // Filtrar por estado
  if (statusFilter.value !== 'all') {
    filtered = filtered.filter(space => 
      statusFilter.value === 'active' ? space.isActive : !space.isActive
    )
  }

  return filtered
})

const activeSpacesCount = computed(() => spaces.value.filter(s => s.isActive).length)
const inactiveSpacesCount = computed(() => spaces.value.filter(s => !s.isActive).length)

const loadSpaces = async () => {
  loading.value = true
  error.value = ''
  
  try {
    if (!authStore.token) throw new Error('No autenticado')
    spaces.value = await OwnerSpacesService.getMySpaces(authStore.token)
  } catch (err) {
    error.value = err instanceof Error ? err.message : 'Error al cargar espacios'
  } finally {
    loading.value = false
  }
}

const handleEdit = (space: Space) => {
  navigateTo(`/owner/spaces/${space.id}/edit`)
}

const handleToggleStatus = async (space: Space) => {
  try {
    if (!authStore.token) throw new Error('No autenticado')
    
    await OwnerSpacesService.updateSpace(authStore.token, space.id, {
      isActive: !space.isActive
    })
    
    await loadSpaces()
  } catch (err) {
    alert(err instanceof Error ? err.message : 'Error al actualizar estado')
  }
}

const handleDelete = async (space: Space) => {
  if (!confirm(`¿Estás seguro de eliminar "${space.name}"? Esta acción no se puede deshacer.`)) {
    return
  }
  
  try {
    if (!authStore.token) throw new Error('No autenticado')
    
    await OwnerSpacesService.deleteSpace(authStore.token, space.id)
    await loadSpaces()
  } catch (err) {
    alert(err instanceof Error ? err.message : 'Error al eliminar espacio')
  }
}

onMounted(() => {
  loadSpaces()
})
</script>

<template>
  <div class="space-y-6">
    <!-- Header -->
    <div class="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
      <div>
        <h1 class="text-3xl font-bold text-[#111418]">Mis Espacios</h1>
        <p class="mt-1 text-sm text-slate-600">
          Gestiona tus espacios disponibles para reserva
        </p>
      </div>
      
      <NuxtLink
        to="/owner/spaces/new"
        class="inline-flex items-center justify-center gap-2 rounded-xl bg-primary px-6 py-3 text-sm font-semibold text-white shadow-md transition hover:bg-primary/90"
      >
        <span class="material-symbols-outlined text-xl">add_circle</span>
        Crear espacio
      </NuxtLink>
    </div>

    <!-- Stats Cards -->
    <div class="grid gap-4 sm:grid-cols-3">
      <div class="rounded-xl border border-slate-200 bg-white p-5 shadow-sm">
        <div class="flex items-center justify-between">
          <div>
            <p class="text-sm text-slate-600">Total de espacios</p>
            <p class="mt-1 text-3xl font-bold text-[#111418]">{{ spaces.length }}</p>
          </div>
          <div class="flex h-12 w-12 items-center justify-center rounded-full bg-primary/10">
            <span class="material-symbols-outlined text-2xl text-primary">store</span>
          </div>
        </div>
      </div>

      <div class="rounded-xl border border-slate-200 bg-white p-5 shadow-sm">
        <div class="flex items-center justify-between">
          <div>
            <p class="text-sm text-slate-600">Espacios activos</p>
            <p class="mt-1 text-3xl font-bold text-green-600">{{ activeSpacesCount }}</p>
          </div>
          <div class="flex h-12 w-12 items-center justify-center rounded-full bg-green-100">
            <span class="material-symbols-outlined text-2xl text-green-600">check_circle</span>
          </div>
        </div>
      </div>

      <div class="rounded-xl border border-slate-200 bg-white p-5 shadow-sm">
        <div class="flex items-center justify-between">
          <div>
            <p class="text-sm text-slate-600">Espacios inactivos</p>
            <p class="mt-1 text-3xl font-bold text-slate-600">{{ inactiveSpacesCount }}</p>
          </div>
          <div class="flex h-12 w-12 items-center justify-center rounded-full bg-slate-100">
            <span class="material-symbols-outlined text-2xl text-slate-600">cancel</span>
          </div>
        </div>
      </div>
    </div>

    <!-- Filters -->
    <div class="flex flex-col gap-4 rounded-xl border border-slate-200 bg-white p-4 sm:flex-row">
      <div class="flex-1">
        <div class="relative">
          <span class="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-slate-400">
            search
          </span>
          <input
            v-model="searchQuery"
            type="text"
            placeholder="Buscar espacios..."
            class="h-10 w-full rounded-lg border border-slate-200 bg-white pl-10 pr-4 text-sm focus:border-primary focus:outline-none focus:ring-2 focus:ring-primary/20"
          />
        </div>
      </div>

      <div class="flex gap-2">
        <button
          class="rounded-lg px-4 py-2 text-sm font-medium transition"
          :class="statusFilter === 'all' ? 'bg-primary text-white' : 'bg-slate-100 text-slate-700 hover:bg-slate-200'"
          @click="statusFilter = 'all'"
        >
          Todos
        </button>
        <button
          class="rounded-lg px-4 py-2 text-sm font-medium transition"
          :class="statusFilter === 'active' ? 'bg-green-600 text-white' : 'bg-slate-100 text-slate-700 hover:bg-slate-200'"
          @click="statusFilter = 'active'"
        >
          Activos
        </button>
        <button
          class="rounded-lg px-4 py-2 text-sm font-medium transition"
          :class="statusFilter === 'inactive' ? 'bg-slate-600 text-white' : 'bg-slate-100 text-slate-700 hover:bg-slate-200'"
          @click="statusFilter = 'inactive'"
        >
          Inactivos
        </button>
      </div>
    </div>

    <!-- Loading -->
    <div v-if="loading" class="flex items-center justify-center py-12">
      <div class="flex items-center gap-3 text-slate-600">
        <div class="h-6 w-6 animate-spin rounded-full border-2 border-slate-300 border-t-primary"></div>
        <span class="text-sm font-medium">Cargando espacios...</span>
      </div>
    </div>

    <!-- Error -->
    <div v-else-if="error" class="rounded-xl border border-rose-200 bg-rose-50 p-6 text-center">
      <span class="material-symbols-outlined text-4xl text-rose-600">error</span>
      <p class="mt-2 text-sm font-medium text-rose-900">{{ error }}</p>
      <button
        class="mt-4 text-sm font-semibold text-rose-600 hover:underline"
        @click="loadSpaces"
      >
        Reintentar
      </button>
    </div>

    <!-- Empty State -->
    <div v-else-if="filteredSpaces.length === 0 && spaces.length === 0" class="rounded-xl border border-slate-200 bg-white p-12 text-center">
      <div class="mx-auto flex h-16 w-16 items-center justify-center rounded-full bg-slate-100">
        <span class="material-symbols-outlined text-4xl text-slate-400">store</span>
      </div>
      <h3 class="mt-4 text-lg font-semibold text-[#111418]">No tienes espacios</h3>
      <p class="mt-2 text-sm text-slate-600">
        Comienza creando tu primer espacio para que los usuarios puedan hacer reservas
      </p>
      <NuxtLink
        to="/owner/spaces/new"
        class="mt-6 inline-flex items-center gap-2 rounded-xl bg-primary px-6 py-3 text-sm font-semibold text-white shadow-md transition hover:bg-primary/90"
      >
        <span class="material-symbols-outlined text-xl">add_circle</span>
        Crear mi primer espacio
      </NuxtLink>
    </div>

    <!-- No Results -->
    <div v-else-if="filteredSpaces.length === 0" class="rounded-xl border border-slate-200 bg-white p-12 text-center">
      <span class="material-symbols-outlined text-4xl text-slate-400">search_off</span>
      <h3 class="mt-4 text-lg font-semibold text-[#111418]">No se encontraron espacios</h3>
      <p class="mt-2 text-sm text-slate-600">
        Intenta ajustar los filtros o la búsqueda
      </p>
    </div>

    <!-- Grid de Espacios -->
    <div v-else class="grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
      <OwnerSpaceCard
        v-for="space in filteredSpaces"
        :key="space.id"
        :space="space"
        @edit="handleEdit(space)"
        @delete="handleDelete(space)"
        @toggle-status="handleToggleStatus(space)"
      />
    </div>
  </div>
</template>
