<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import type { Space } from '../../types/space'
import type { Booking } from '../../types/booking'
import { ownerSpacesService } from '../../services/owner-spaces.service'
import { ownerBookingsService } from '../../services/owner-bookings.service'
import { useAuthStore } from '../../stores/auth'

definePageMeta({
  layout: 'owner',
  middleware: 'verified-owner'
})

const authStore = useAuthStore()

useSeoMeta({
  title: 'Dashboard - Spazio Owner',
  description: 'Panel de control para propietarios'
})

const spaces = ref<Space[]>([])
const recentBookings = ref<Booking[]>([])
const loading = ref(true)

const activeSpacesCount = computed(() => spaces.value.filter(s => s.isActive).length)

const todayBookingsCount = computed(() => {
  const today = new Date().toISOString().split('T')[0]
  return recentBookings.value.filter(b => {
    const bookingDate = new Date(b.startTime).toISOString().split('T')[0]
    return bookingDate === today && b.status === 'confirmed'
  }).length
})

const totalBookingsCount = computed(() => recentBookings.value.length)

const loadDashboardData = async () => {
  loading.value = true
  
  try {
    const [spacesResponse, bookingsResponse] = await Promise.all([
      ownerSpacesService.getMySpaces(),
      ownerBookingsService.getOwnerBookings()
    ])
    
    if (spacesResponse.success && spacesResponse.data) {
      spaces.value = spacesResponse.data
    }
    
    if (bookingsResponse.success && bookingsResponse.data) {
      recentBookings.value = bookingsResponse.data.slice(0, 5) // Solo las 5 más recientes
    }
  } catch (err) {
    console.error('Error cargando datos del dashboard:', err)
  } finally {
    loading.value = false
  }
}

const getStatusBadgeClass = (status: string) => {
  switch (status) {
    case 'confirmed':
      return 'bg-green-100 text-green-700'
    case 'pending':
      return 'bg-amber-100 text-amber-700'
    case 'cancelled':
      return 'bg-rose-100 text-rose-700'
    case 'completed':
      return 'bg-blue-100 text-blue-700'
    default:
      return 'bg-slate-100 text-slate-700'
  }
}

const getStatusLabel = (status: string) => {
  const labels: Record<string, string> = {
    confirmed: 'Confirmada',
    pending: 'Pendiente',
    cancelled: 'Cancelada',
    completed: 'Completada'
  }
  return labels[status] || status
}

const formatDate = (dateString: string) => {
  const date = new Date(dateString)
  return date.toLocaleDateString('es-ES', { 
    day: '2-digit', 
    month: 'short',
    year: 'numeric'
  })
}

const formatTime = (dateString: string) => {
  const date = new Date(dateString)
  return date.toLocaleTimeString('es-ES', { 
    hour: '2-digit', 
    minute: '2-digit'
  })
}

onMounted(() => {
  loadDashboardData()
})
</script>

<template>
  <div class="space-y-6">
    <!-- Header -->
    <div>
      <h1 class="text-3xl font-bold text-[#111418]">
        Dashboard
      </h1>
      <p class="mt-1 text-sm text-slate-600">
        Bienvenido, {{ authStore.user?.businessName || authStore.user?.name }}
      </p>
    </div>

    <!-- Stats Cards -->
    <div class="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
      <div class="rounded-xl border border-slate-200 bg-white p-5 shadow-sm">
        <div class="flex items-center justify-between">
          <div>
            <p class="text-sm text-slate-600">Espacios Activos</p>
            <p class="mt-1 text-3xl font-bold text-[#111418]">{{ activeSpacesCount }}</p>
          </div>
          <div class="flex h-12 w-12 items-center justify-center rounded-full bg-primary/10">
            <span class="material-symbols-outlined text-2xl text-primary">store</span>
          </div>
        </div>
      </div>

      <div class="rounded-xl border border-slate-200 bg-white p-5 shadow-sm">
        <div class="flex items-center justify-between">
          <div>
            <p class="text-sm text-slate-600">Reservas Hoy</p>
            <p class="mt-1 text-3xl font-bold text-green-600">{{ todayBookingsCount }}</p>
          </div>
          <div class="flex h-12 w-12 items-center justify-center rounded-full bg-green-100">
            <span class="material-symbols-outlined text-2xl text-green-600">event_available</span>
          </div>
        </div>
      </div>

      <div class="rounded-xl border border-slate-200 bg-white p-5 shadow-sm">
        <div class="flex items-center justify-between">
          <div>
            <p class="text-sm text-slate-600">Total Reservas</p>
            <p class="mt-1 text-3xl font-bold text-blue-600">{{ totalBookingsCount }}</p>
          </div>
          <div class="flex h-12 w-12 items-center justify-center rounded-full bg-blue-100">
            <span class="material-symbols-outlined text-2xl text-blue-600">calendar_month</span>
          </div>
        </div>
      </div>

      <div class="rounded-xl border border-slate-200 bg-white p-5 shadow-sm">
        <div class="flex items-center justify-between">
          <div>
            <p class="text-sm text-slate-600">Total Espacios</p>
            <p class="mt-1 text-3xl font-bold text-purple-600">{{ spaces.length }}</p>
          </div>
          <div class="flex h-12 w-12 items-center justify-center rounded-full bg-purple-100">
            <span class="material-symbols-outlined text-2xl text-purple-600">apartment</span>
          </div>
        </div>
      </div>
    </div>

    <!-- Loading -->
    <div v-if="loading" class="flex items-center justify-center py-12">
      <div class="flex items-center gap-3 text-slate-600">
        <div class="h-6 w-6 animate-spin rounded-full border-2 border-slate-300 border-t-primary"></div>
        <span class="text-sm font-medium">Cargando información...</span>
      </div>
    </div>

    <!-- Content -->
    <div v-else class="grid gap-6 lg:grid-cols-2">
      <!-- Últimas Reservas -->
      <div class="rounded-xl border border-slate-200 bg-white shadow-sm">
        <div class="border-b border-slate-200 p-5">
          <div class="flex items-center justify-between">
            <h2 class="text-lg font-bold text-[#111418]">Últimas Reservas</h2>
            <NuxtLink
              to="/owner/bookings"
              class="text-sm font-semibold text-primary hover:underline"
            >
              Ver todas
            </NuxtLink>
          </div>
        </div>

        <div v-if="recentBookings.length === 0" class="p-8 text-center">
          <span class="material-symbols-outlined text-4xl text-slate-300">event_busy</span>
          <p class="mt-2 text-sm text-slate-600">No hay reservas recientes</p>
        </div>

        <div v-else class="divide-y divide-slate-100">
          <div
            v-for="booking in recentBookings"
            :key="booking._id"
            class="flex items-center gap-4 p-4 transition hover:bg-slate-50"
          >
            <div class="flex h-10 w-10 flex-shrink-0 items-center justify-center rounded-full bg-primary/10">
              <span class="material-symbols-outlined text-xl text-primary">person</span>
            </div>
            
            <div class="min-w-0 flex-1">
              <p class="truncate text-sm font-semibold text-[#111418]">
                {{ booking.user?.name || 'Usuario' }}
              </p>
              <p class="truncate text-xs text-slate-600">
                {{ booking.space?.name || 'Espacio' }}
              </p>
            </div>

            <div class="text-right">
              <p class="text-xs font-medium text-slate-900">
                {{ formatDate(booking.startTime) }}
              </p>
              <p class="text-xs text-slate-600">
                {{ formatTime(booking.startTime) }}
              </p>
            </div>

            <span 
              class="rounded-full px-2.5 py-1 text-xs font-semibold"
              :class="getStatusBadgeClass(booking.status)"
            >
              {{ getStatusLabel(booking.status) }}
            </span>
          </div>
        </div>
      </div>

      <!-- Mis Espacios -->
      <div class="rounded-xl border border-slate-200 bg-white shadow-sm">
        <div class="border-b border-slate-200 p-5">
          <div class="flex items-center justify-between">
            <h2 class="text-lg font-bold text-[#111418]">Mis Espacios</h2>
            <NuxtLink
              to="/owner/spaces"
              class="text-sm font-semibold text-primary hover:underline"
            >
              Ver todos
            </NuxtLink>
          </div>
        </div>

        <div v-if="spaces.length === 0" class="p-8 text-center">
          <span class="material-symbols-outlined text-4xl text-slate-300">store_off</span>
          <p class="mt-2 text-sm text-slate-600">No tienes espacios creados</p>
          <NuxtLink
            to="/owner/spaces/new"
            class="mt-4 inline-flex items-center gap-1 text-sm font-semibold text-primary hover:underline"
          >
            <span class="material-symbols-outlined !text-[16px]">add</span>
            Crear espacio
          </NuxtLink>
        </div>

        <div v-else class="divide-y divide-slate-100">
          <div
            v-for="space in spaces.slice(0, 5)"
            :key="space.id"
            class="flex items-center gap-4 p-4 transition hover:bg-slate-50"
          >
            <div class="flex h-10 w-10 flex-shrink-0 items-center justify-center rounded-full bg-primary/10">
              <span class="material-symbols-outlined text-xl text-primary">store</span>
            </div>
            
            <div class="min-w-0 flex-1">
              <p class="truncate text-sm font-semibold text-[#111418]">
                {{ space.name }}
              </p>
              <p class="text-xs text-slate-600">
                Capacidad: {{ space.capacity }} personas
              </p>
            </div>

            <span 
              class="rounded-full px-2.5 py-1 text-xs font-semibold"
              :class="space.isActive ? 'bg-green-100 text-green-700' : 'bg-slate-100 text-slate-700'"
            >
              {{ space.isActive ? 'Activo' : 'Inactivo' }}
            </span>
          </div>
        </div>
      </div>
    </div>

    <!-- Quick Actions -->
    <div class="rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
      <h2 class="text-lg font-bold text-[#111418]">Acciones Rápidas</h2>
      <div class="mt-4 grid gap-4 sm:grid-cols-3">
        <NuxtLink
          to="/owner/spaces/new"
          class="flex items-center gap-3 rounded-lg border border-slate-200 p-4 transition hover:border-primary hover:bg-primary/5"
        >
          <div class="flex h-10 w-10 items-center justify-center rounded-full bg-primary/10">
            <span class="material-symbols-outlined text-xl text-primary">add_circle</span>
          </div>
          <div>
            <p class="text-sm font-semibold text-[#111418]">Crear Espacio</p>
            <p class="text-xs text-slate-600">Añadir nuevo espacio</p>
          </div>
        </NuxtLink>

        <NuxtLink
          to="/owner/bookings"
          class="flex items-center gap-3 rounded-lg border border-slate-200 p-4 transition hover:border-primary hover:bg-primary/5"
        >
          <div class="flex h-10 w-10 items-center justify-center rounded-full bg-primary/10">
            <span class="material-symbols-outlined text-xl text-primary">event_note</span>
          </div>
          <div>
            <p class="text-sm font-semibold text-[#111418]">Ver Reservas</p>
            <p class="text-xs text-slate-600">Gestionar reservas</p>
          </div>
        </NuxtLink>

        <NuxtLink
          to="/owner/profile"
          class="flex items-center gap-3 rounded-lg border border-slate-200 p-4 transition hover:border-primary hover:bg-primary/5"
        >
          <div class="flex h-10 w-10 items-center justify-center rounded-full bg-primary/10">
            <span class="material-symbols-outlined text-xl text-primary">settings</span>
          </div>
          <div>
            <p class="text-sm font-semibold text-[#111418]">Configuración</p>
            <p class="text-xs text-slate-600">Editar perfil</p>
          </div>
        </NuxtLink>
      </div>
    </div>
  </div>
</template>
