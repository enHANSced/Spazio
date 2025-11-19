<script setup lang="ts">
const { user, logout } = useAuth()
const router = useRouter()

const handleLogout = async () => {
  await logout()
  router.push('/auth/login')
}
</script>

<template>
  <div class="min-h-screen bg-gray-50 text-gray-900">
    <header class="border-b border-gray-200 bg-white shadow-sm sticky top-0 z-40">
      <div class="mx-auto flex max-w-7xl items-center justify-between px-4 sm:px-6 lg:px-8 py-4">
        <NuxtLink to="/" class="text-2xl font-bold text-primary flex items-center gap-2">
          <span class="material-symbols-outlined text-3xl">home_work</span>
          Spazio
        </NuxtLink>
        
        <nav class="hidden md:flex items-center gap-6">
          <NuxtLink 
            to="/" 
            class="text-gray-700 hover:text-primary font-semibold transition flex items-center gap-1"
            active-class="text-primary"
          >
            <span class="material-symbols-outlined !text-[20px]">explore</span>
            Explorar
          </NuxtLink>
          
          <!-- Link condicional: Mis Reservas solo para users regulares -->
          <NuxtLink 
            v-if="user?.role === 'user'"
            to="/bookings" 
            class="text-gray-700 hover:text-primary font-semibold transition flex items-center gap-1"
            active-class="text-primary"
          >
            <span class="material-symbols-outlined !text-[20px]">calendar_month</span>
            Mis Reservas
          </NuxtLink>
          
          <!-- Link al Dashboard para owners y admins -->
          <NuxtLink 
            v-if="user?.role === 'owner' || user?.role === 'admin'"
            :to="user.role === 'owner' ? '/owner' : '/admin'" 
            class="text-gray-700 hover:text-primary font-semibold transition flex items-center gap-1"
            active-class="text-primary"
          >
            <span class="material-symbols-outlined !text-[20px]">dashboard</span>
            Dashboard
          </NuxtLink>
          
          <div v-if="user" class="flex items-center gap-4 ml-4 pl-4 border-l border-gray-200">
            <div class="text-sm">
              <p class="font-semibold text-gray-900">{{ user.name }}</p>
              <p class="text-gray-600">{{ user.email }}</p>
            </div>
            <button
              type="button"
              class="p-2 rounded-lg hover:bg-gray-100 text-gray-600 hover:text-gray-900 transition"
              @click="handleLogout"
              title="Cerrar sesión"
            >
              <span class="material-symbols-outlined">logout</span>
            </button>
          </div>
        </nav>

        <!-- Mobile menu button -->
        <button
          type="button"
          class="md:hidden p-2 rounded-lg hover:bg-gray-100 text-gray-600"
        >
          <span class="material-symbols-outlined">menu</span>
        </button>
      </div>
    </header>
    
    <main>
      <slot />
    </main>
    
    <footer class="border-t border-gray-200 bg-white mt-16">
      <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8 py-8">
        <div class="text-center text-gray-600">
          <p class="font-semibold text-gray-900 mb-2">Spazio</p>
          <p class="text-sm">© 2025 Spazio. Todos los derechos reservados.</p>
        </div>
      </div>
    </footer>
  </div>
</template>
