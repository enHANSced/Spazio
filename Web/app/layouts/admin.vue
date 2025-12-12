<script setup lang="ts">
import { ref } from 'vue'
import { useAuthStore } from '../stores/auth'

const authStore = useAuthStore()
const route = useRoute()

const sidebarOpen = ref(true)

const navigation = [
  {
    name: 'Dashboard',
    path: '/admin',
    icon: 'dashboard'
  },
  {
    name: 'Usuarios',
    path: '/admin/users',
    icon: 'group'
  },
  {
    name: 'Verificaciones',
    path: '/admin/pending-owners',
    icon: 'verified_user'
  },
  {
    name: 'Espacios',
    path: '/admin/spaces',
    icon: 'store'
  },
  {
    name: 'Reservas',
    path: '/admin/bookings',
    icon: 'event_note'
  }
]

const isActive = (path: string) => {
  if (path === '/admin') {
    return route.path === path
  }
  return route.path.startsWith(path)
}

const handleLogout = () => {
  authStore.logout()
  navigateTo('/auth/login')
}
</script>

<template>
  <div class="flex h-screen bg-slate-50">
    <!-- Sidebar -->
    <aside
      class="flex w-64 flex-col border-r border-slate-200 bg-white transition-all duration-300"
      :class="{ 'w-64': sidebarOpen, 'w-20': !sidebarOpen }"
    >
      <!-- Logo -->
      <div class="flex h-16 items-center justify-between border-b border-slate-200 px-6">
        <NuxtLink to="/admin" class="flex items-center gap-3">
          <div class="flex h-10 w-10 items-center justify-center rounded-xl bg-rose-600 text-white">
            <span class="material-symbols-outlined text-2xl">admin_panel_settings</span>
          </div>
          <span v-if="sidebarOpen" class="text-xl font-bold text-[#111418]">Admin</span>
        </NuxtLink>
        <button
          v-if="sidebarOpen"
          class="text-slate-400 hover:text-slate-600"
          @click="sidebarOpen = !sidebarOpen"
        >
          <span class="material-symbols-outlined">menu_open</span>
        </button>
      </div>

      <!-- User Info -->
      <div class="border-b border-slate-200 p-4">
        <div class="flex items-center gap-3">
          <div class="flex h-10 w-10 flex-shrink-0 items-center justify-center rounded-full bg-rose-100 text-rose-600">
            <span class="material-symbols-outlined">shield_person</span>
          </div>
          <div v-if="sidebarOpen" class="min-w-0 flex-1">
            <p class="truncate text-sm font-semibold text-[#111418]">
              {{ authStore.user?.name }}
            </p>
            <p class="text-xs text-slate-500">
              Administrador
            </p>
          </div>
        </div>
      </div>

      <!-- Navigation -->
      <nav class="flex-1 space-y-1 p-4">
        <NuxtLink
          v-for="item in navigation"
          :key="item.path"
          :to="item.path"
          class="flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium transition-colors"
          :class="
            isActive(item.path)
              ? 'bg-rose-100 text-rose-700'
              : 'text-slate-600 hover:bg-slate-100 hover:text-slate-900'
          "
        >
          <span class="material-symbols-outlined text-xl">{{ item.icon }}</span>
          <span v-if="sidebarOpen">{{ item.name }}</span>
        </NuxtLink>
      </nav>

      <!-- Bottom Actions -->
      <div class="border-t border-slate-200 p-4">
        <NuxtLink
          to="/"
          class="mb-2 flex w-full items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium text-slate-600 transition-colors hover:bg-slate-100 hover:text-slate-900"
        >
          <span class="material-symbols-outlined text-xl">home</span>
          <span v-if="sidebarOpen">Ver sitio público</span>
        </NuxtLink>
        <button
          class="flex w-full items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium text-slate-600 transition-colors hover:bg-slate-100 hover:text-slate-900"
          @click="handleLogout"
        >
          <span class="material-symbols-outlined text-xl">logout</span>
          <span v-if="sidebarOpen">Cerrar sesión</span>
        </button>
      </div>
    </aside>

    <!-- Main Content -->
    <div class="flex flex-1 flex-col overflow-hidden">
      <!-- Top Bar -->
      <header class="flex h-16 items-center justify-between border-b border-slate-200 bg-white px-6">
        <button
          v-if="!sidebarOpen"
          class="text-slate-400 hover:text-slate-600"
          @click="sidebarOpen = true"
        >
          <span class="material-symbols-outlined">menu</span>
        </button>
        
        <div class="flex items-center gap-4">
          <span class="rounded-full bg-rose-100 px-3 py-1 text-xs font-semibold text-rose-700">
            Panel de Administración
          </span>
        </div>
      </header>

      <!-- Page Content -->
      <main class="flex-1 overflow-auto p-6">
        <slot />
      </main>
    </div>
  </div>
</template>
