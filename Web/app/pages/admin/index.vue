<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { adminService, type AdminStats } from '../../services/admin.service'
import { useAuthStore } from '../../stores/auth'

definePageMeta({
  layout: 'admin',
  middleware: 'admin'
})

const authStore = useAuthStore()

useSeoMeta({
  title: 'Dashboard - Admin Spazio',
  description: 'Panel de administración de Spazio'
})

const stats = ref<AdminStats | null>(null)
const loading = ref(true)
const error = ref<string | null>(null)

const loadStats = async () => {
  loading.value = true
  error.value = null

  try {
    const response = await adminService.getStats()
    if (response.success && response.data) {
      stats.value = response.data
    } else {
      error.value = response.message || 'Error al cargar estadísticas'
    }
  } catch (err: any) {
    error.value = err.message || 'Error inesperado'
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  loadStats()
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
        Bienvenido, {{ authStore.user?.name }}. Aquí tienes un resumen general del sistema.
      </p>
    </div>

    <!-- Loading -->
    <div v-if="loading" class="flex items-center justify-center py-12">
      <div class="flex items-center gap-3 text-slate-600">
        <div class="h-6 w-6 animate-spin rounded-full border-2 border-slate-300 border-t-rose-600" />
        <span class="text-sm font-medium">Cargando estadísticas...</span>
      </div>
    </div>

    <!-- Error -->
    <div v-else-if="error" class="rounded-xl border border-rose-200 bg-rose-50 p-6 text-center">
      <span class="material-symbols-outlined text-4xl text-rose-400">error</span>
      <p class="mt-2 text-sm text-rose-700">{{ error }}</p>
      <button
        class="mt-4 rounded-lg bg-rose-600 px-4 py-2 text-sm font-semibold text-white hover:bg-rose-700"
        @click="loadStats"
      >
        Reintentar
      </button>
    </div>

    <!-- Stats Content -->
    <template v-else-if="stats">
      <!-- Users Stats -->
      <div>
        <h2 class="mb-4 text-lg font-semibold text-[#111418]">Usuarios</h2>
        <div class="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          <div class="rounded-xl border border-slate-200 bg-white p-5 shadow-sm">
            <div class="flex items-center justify-between">
              <div>
                <p class="text-sm text-slate-600">Usuarios Registrados</p>
                <p class="mt-1 text-3xl font-bold text-[#111418]">{{ stats.users.total }}</p>
              </div>
              <div class="flex h-12 w-12 items-center justify-center rounded-full bg-blue-100">
                <span class="material-symbols-outlined text-2xl text-blue-600">person</span>
              </div>
            </div>
          </div>

          <div class="rounded-xl border border-slate-200 bg-white p-5 shadow-sm">
            <div class="flex items-center justify-between">
              <div>
                <p class="text-sm text-slate-600">Propietarios</p>
                <p class="mt-1 text-3xl font-bold text-purple-600">{{ stats.users.owners }}</p>
              </div>
              <div class="flex h-12 w-12 items-center justify-center rounded-full bg-purple-100">
                <span class="material-symbols-outlined text-2xl text-purple-600">store</span>
              </div>
            </div>
          </div>

          <NuxtLink
            to="/admin/pending-owners"
            class="rounded-xl border border-slate-200 bg-white p-5 shadow-sm transition hover:border-amber-300 hover:shadow-md"
          >
            <div class="flex items-center justify-between">
              <div>
                <p class="text-sm text-slate-600">Pendientes de Verificación</p>
                <p class="mt-1 text-3xl font-bold text-amber-600">{{ stats.users.pendingOwners }}</p>
              </div>
              <div class="flex h-12 w-12 items-center justify-center rounded-full bg-amber-100">
                <span class="material-symbols-outlined text-2xl text-amber-600">pending</span>
              </div>
            </div>
            <p class="mt-3 flex items-center gap-1 text-xs text-amber-600">
              <span class="material-symbols-outlined !text-[14px]">arrow_forward</span>
              Revisar solicitudes
            </p>
          </NuxtLink>
        </div>
      </div>

      <!-- Spaces Stats -->
      <div>
        <h2 class="mb-4 text-lg font-semibold text-[#111418]">Espacios</h2>
        <div class="grid gap-4 sm:grid-cols-3">
          <div class="rounded-xl border border-slate-200 bg-white p-5 shadow-sm">
            <div class="flex items-center justify-between">
              <div>
                <p class="text-sm text-slate-600">Total Espacios</p>
                <p class="mt-1 text-3xl font-bold text-[#111418]">{{ stats.spaces.total }}</p>
              </div>
              <div class="flex h-12 w-12 items-center justify-center rounded-full bg-slate-100">
                <span class="material-symbols-outlined text-2xl text-slate-600">apartment</span>
              </div>
            </div>
          </div>

          <div class="rounded-xl border border-slate-200 bg-white p-5 shadow-sm">
            <div class="flex items-center justify-between">
              <div>
                <p class="text-sm text-slate-600">Espacios Activos</p>
                <p class="mt-1 text-3xl font-bold text-green-600">{{ stats.spaces.active }}</p>
              </div>
              <div class="flex h-12 w-12 items-center justify-center rounded-full bg-green-100">
                <span class="material-symbols-outlined text-2xl text-green-600">check_circle</span>
              </div>
            </div>
          </div>

          <div class="rounded-xl border border-slate-200 bg-white p-5 shadow-sm">
            <div class="flex items-center justify-between">
              <div>
                <p class="text-sm text-slate-600">Espacios Inactivos</p>
                <p class="mt-1 text-3xl font-bold text-rose-600">{{ stats.spaces.inactive }}</p>
              </div>
              <div class="flex h-12 w-12 items-center justify-center rounded-full bg-rose-100">
                <span class="material-symbols-outlined text-2xl text-rose-600">cancel</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Bookings Stats -->
      <div>
        <h2 class="mb-4 text-lg font-semibold text-[#111418]">Reservas</h2>
        <div class="grid gap-4 sm:grid-cols-2 lg:grid-cols-5">
          <div class="rounded-xl border border-slate-200 bg-white p-5 shadow-sm">
            <div class="flex items-center justify-between">
              <div>
                <p class="text-sm text-slate-600">Total Reservas</p>
                <p class="mt-1 text-3xl font-bold text-[#111418]">{{ stats.bookings.total }}</p>
              </div>
              <div class="flex h-12 w-12 items-center justify-center rounded-full bg-slate-100">
                <span class="material-symbols-outlined text-2xl text-slate-600">event_note</span>
              </div>
            </div>
          </div>

          <div class="rounded-xl border border-slate-200 bg-white p-5 shadow-sm">
            <div class="flex items-center justify-between">
              <div>
                <p class="text-sm text-slate-600">Confirmadas</p>
                <p class="mt-1 text-3xl font-bold text-green-600">{{ stats.bookings.confirmed }}</p>
              </div>
              <div class="flex h-12 w-12 items-center justify-center rounded-full bg-green-100">
                <span class="material-symbols-outlined text-2xl text-green-600">event_available</span>
              </div>
            </div>
          </div>

          <div class="rounded-xl border border-slate-200 bg-white p-5 shadow-sm">
            <div class="flex items-center justify-between">
              <div>
                <p class="text-sm text-slate-600">Canceladas</p>
                <p class="mt-1 text-3xl font-bold text-rose-600">{{ stats.bookings.cancelled }}</p>
              </div>
              <div class="flex h-12 w-12 items-center justify-center rounded-full bg-rose-100">
                <span class="material-symbols-outlined text-2xl text-rose-600">event_busy</span>
              </div>
            </div>
          </div>

          <div class="rounded-xl border border-slate-200 bg-white p-5 shadow-sm">
            <div class="flex items-center justify-between">
              <div>
                <p class="text-sm text-slate-600">Últimos 30 días</p>
                <p class="mt-1 text-3xl font-bold text-blue-600">{{ stats.bookings.recentThirtyDays }}</p>
              </div>
              <div class="flex h-12 w-12 items-center justify-center rounded-full bg-blue-100">
                <span class="material-symbols-outlined text-2xl text-blue-600">calendar_month</span>
              </div>
            </div>
          </div>

          <div class="rounded-xl border border-slate-200 bg-white p-5 shadow-sm">
            <div class="flex items-center justify-between">
              <div>
                <p class="text-sm text-slate-600">Reservas Hoy</p>
                <p class="mt-1 text-3xl font-bold text-primary">{{ stats.bookings.today }}</p>
              </div>
              <div class="flex h-12 w-12 items-center justify-center rounded-full bg-primary/10">
                <span class="material-symbols-outlined text-2xl text-primary">today</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Quick Actions -->
      <div class="rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
        <h2 class="text-lg font-bold text-[#111418]">Acciones Rápidas</h2>
        <div class="mt-4 grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
          <NuxtLink
            to="/admin/users"
            class="flex items-center gap-3 rounded-lg border border-slate-200 p-4 transition hover:border-rose-300 hover:bg-rose-50"
          >
            <div class="flex h-10 w-10 items-center justify-center rounded-full bg-rose-100">
              <span class="material-symbols-outlined text-xl text-rose-600">group</span>
            </div>
            <div>
              <p class="text-sm font-semibold text-[#111418]">Gestionar Usuarios</p>
              <p class="text-xs text-slate-600">Ver todos los usuarios</p>
            </div>
          </NuxtLink>

          <NuxtLink
            to="/admin/pending-owners"
            class="flex items-center gap-3 rounded-lg border border-slate-200 p-4 transition hover:border-amber-300 hover:bg-amber-50"
          >
            <div class="flex h-10 w-10 items-center justify-center rounded-full bg-amber-100">
              <span class="material-symbols-outlined text-xl text-amber-600">verified_user</span>
            </div>
            <div>
              <p class="text-sm font-semibold text-[#111418]">Verificar Owners</p>
              <p class="text-xs text-slate-600">{{ stats.users.pendingOwners }} pendientes</p>
            </div>
          </NuxtLink>

          <NuxtLink
            to="/admin/spaces"
            class="flex items-center gap-3 rounded-lg border border-slate-200 p-4 transition hover:border-purple-300 hover:bg-purple-50"
          >
            <div class="flex h-10 w-10 items-center justify-center rounded-full bg-purple-100">
              <span class="material-symbols-outlined text-xl text-purple-600">store</span>
            </div>
            <div>
              <p class="text-sm font-semibold text-[#111418]">Ver Espacios</p>
              <p class="text-xs text-slate-600">Todos los espacios</p>
            </div>
          </NuxtLink>

          <NuxtLink
            to="/admin/bookings"
            class="flex items-center gap-3 rounded-lg border border-slate-200 p-4 transition hover:border-blue-300 hover:bg-blue-50"
          >
            <div class="flex h-10 w-10 items-center justify-center rounded-full bg-blue-100">
              <span class="material-symbols-outlined text-xl text-blue-600">event_note</span>
            </div>
            <div>
              <p class="text-sm font-semibold text-[#111418]">Ver Reservas</p>
              <p class="text-xs text-slate-600">Todas las reservas</p>
            </div>
          </NuxtLink>
        </div>
      </div>
    </template>
  </div>
</template>
