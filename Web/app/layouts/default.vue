<script setup lang="ts">
import { ref } from 'vue'

const { user, logout } = useAuth()
const router = useRouter()

const showMobileMenu = ref(false)
const showUserMenu = ref(false)
const currentYear = new Date().getFullYear()

const handleLogout = async () => {
  showUserMenu.value = false
  showMobileMenu.value = false
  await logout()
  router.push('/auth/login')
}

const closeMobileMenu = () => {
  showMobileMenu.value = false
}
</script>

<template>
  <div class="min-h-screen bg-gradient-to-br from-slate-50 via-white to-blue-50/30 text-gray-900">
    <!-- Header con diseño moderno -->
    <header class="bg-white/70 backdrop-blur-lg border-b border-gray-200/50 sticky top-0 z-40">
      <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div class="flex items-center justify-between h-16">
          <!-- Logo -->
          <NuxtLink to="/" class="flex items-center gap-2.5 group">
            <div class="flex h-10 w-10 items-center justify-center rounded-xl bg-gradient-to-br from-primary to-primary-dark shadow-lg shadow-primary/25 transition-all group-hover:shadow-xl group-hover:shadow-primary/30">
              <span class="material-symbols-outlined text-xl text-white">home_work</span>
            </div>
            <span class="text-xl font-bold bg-gradient-to-r from-primary via-primary-dark to-blue-100 bg-clip-text text-transparent">Spazio</span>
          </NuxtLink>
          
          <!-- Desktop Navigation -->
          <nav class="hidden md:flex items-center gap-1">
            <NuxtLink 
              to="/" 
              class="px-4 py-2 rounded-xl text-sm font-medium text-gray-600 hover:text-primary hover:bg-primary/5 transition-all flex items-center gap-2"
              active-class="!text-primary !bg-primary/10"
            >
              <span class="material-symbols-outlined !text-[20px]">explore</span>
              Explorar
            </NuxtLink>
            
            <!-- Mis Reservas - solo para users -->
            <NuxtLink 
              v-if="user?.role === 'user'"
              to="/bookings" 
              class="px-4 py-2 rounded-xl text-sm font-medium text-gray-600 hover:text-primary hover:bg-primary/5 transition-all flex items-center gap-2"
              active-class="!text-primary !bg-primary/10"
            >
              <span class="material-symbols-outlined !text-[20px]">calendar_month</span>
              Mis Reservas
            </NuxtLink>
            
            <!-- Dashboard - owners y admins -->
            <NuxtLink 
              v-if="user?.role === 'owner' || user?.role === 'admin'"
              :to="user.role === 'owner' ? '/owner' : '/admin'" 
              class="px-4 py-2 rounded-xl text-sm font-medium text-gray-600 hover:text-primary hover:bg-primary/5 transition-all flex items-center gap-2"
              active-class="!text-primary !bg-primary/10"
            >
              <span class="material-symbols-outlined !text-[20px]">dashboard</span>
              Dashboard
            </NuxtLink>
          </nav>

          <!-- User Section - Desktop -->
          <div v-if="user" class="hidden md:flex items-center gap-3">
            <div class="relative">
              <button
                type="button"
                class="flex items-center gap-3 px-3 py-1.5 rounded-xl hover:bg-gray-100 transition-all"
                @click="showUserMenu = !showUserMenu"
              >
                <div class="flex h-9 w-9 items-center justify-center rounded-xl bg-gradient-to-br from-primary/10 to-blue-100 text-primary font-bold text-sm">
                  {{ user.name?.charAt(0).toUpperCase() }}
                </div>
                <div class="text-left">
                  <p class="text-sm font-semibold text-gray-900 leading-tight">{{ user.name }}</p>
                  <p class="text-xs text-gray-500 leading-tight">{{ user.role === 'user' ? 'Usuario' : user.role === 'owner' ? 'Propietario' : 'Admin' }}</p>
                </div>
                <span class="material-symbols-outlined text-gray-400 transition-transform" :class="showUserMenu ? 'rotate-180' : ''">expand_more</span>
              </button>
              
              <!-- Dropdown Menu -->
              <Transition
                enter-active-class="transition ease-out duration-100"
                enter-from-class="transform opacity-0 scale-95"
                enter-to-class="transform opacity-100 scale-100"
                leave-active-class="transition ease-in duration-75"
                leave-from-class="transform opacity-100 scale-100"
                leave-to-class="transform opacity-0 scale-95"
              >
                <div
                  v-if="showUserMenu"
                  class="absolute right-0 mt-2 w-56 origin-top-right rounded-xl bg-white shadow-lg ring-1 ring-black/5 focus:outline-none overflow-hidden"
                  @click="showUserMenu = false"
                >
                  <div class="px-4 py-3 border-b border-gray-100">
                    <p class="text-sm font-semibold text-gray-900">{{ user.name }}</p>
                    <p class="text-xs text-gray-500 truncate">{{ user.email }}</p>
                  </div>
                  <div class="py-1">
                    <NuxtLink
                      v-if="user.role === 'user'"
                      to="/bookings"
                      class="flex items-center gap-3 px-4 py-2.5 text-sm text-gray-700 hover:bg-gray-50 transition-colors"
                    >
                      <span class="material-symbols-outlined !text-[20px] text-gray-400">calendar_month</span>
                      Mis Reservas
                    </NuxtLink>
                    <button
                      type="button"
                      class="w-full flex items-center gap-3 px-4 py-2.5 text-sm text-rose-600 hover:bg-rose-50 transition-colors"
                      @click="handleLogout"
                    >
                      <span class="material-symbols-outlined !text-[20px]">logout</span>
                      Cerrar sesión
                    </button>
                  </div>
                </div>
              </Transition>
            </div>
          </div>

          <!-- Login button cuando no hay usuario -->
          <NuxtLink
            v-else
            to="/auth/login"
            class="hidden md:inline-flex items-center gap-2 px-5 py-2.5 rounded-xl bg-gradient-to-r from-primary to-primary-dark text-white text-sm font-semibold shadow-lg shadow-primary/25 hover:shadow-xl hover:shadow-primary/30 transition-all"
          >
            <span class="material-symbols-outlined !text-[18px]">login</span>
            Iniciar sesión
          </NuxtLink>

          <!-- Mobile menu button -->
          <button
            type="button"
            class="md:hidden p-2 rounded-xl hover:bg-gray-100 text-gray-600 transition-colors"
            @click="showMobileMenu = !showMobileMenu"
          >
            <span class="material-symbols-outlined text-2xl">{{ showMobileMenu ? 'close' : 'menu' }}</span>
          </button>
        </div>
      </div>

      <!-- Mobile Navigation -->
      <Transition
        enter-active-class="transition ease-out duration-200"
        enter-from-class="opacity-0 -translate-y-1"
        enter-to-class="opacity-100 translate-y-0"
        leave-active-class="transition ease-in duration-150"
        leave-from-class="opacity-100 translate-y-0"
        leave-to-class="opacity-0 -translate-y-1"
      >
        <div v-if="showMobileMenu" class="md:hidden border-t border-gray-100 bg-white">
          <div class="px-4 py-4 space-y-2">
            <NuxtLink 
              to="/" 
              class="flex items-center gap-3 px-4 py-3 rounded-xl text-gray-700 hover:bg-primary/5 hover:text-primary transition-all"
              active-class="!bg-primary/10 !text-primary"
              @click="closeMobileMenu"
            >
              <span class="material-symbols-outlined">explore</span>
              <span class="font-medium">Explorar</span>
            </NuxtLink>
            
            <NuxtLink 
              v-if="user?.role === 'user'"
              to="/bookings" 
              class="flex items-center gap-3 px-4 py-3 rounded-xl text-gray-700 hover:bg-primary/5 hover:text-primary transition-all"
              active-class="!bg-primary/10 !text-primary"
              @click="closeMobileMenu"
            >
              <span class="material-symbols-outlined">calendar_month</span>
              <span class="font-medium">Mis Reservas</span>
            </NuxtLink>
            
            <NuxtLink 
              v-if="user?.role === 'owner' || user?.role === 'admin'"
              :to="user.role === 'owner' ? '/owner' : '/admin'" 
              class="flex items-center gap-3 px-4 py-3 rounded-xl text-gray-700 hover:bg-primary/5 hover:text-primary transition-all"
              active-class="!bg-primary/10 !text-primary"
              @click="closeMobileMenu"
            >
              <span class="material-symbols-outlined">dashboard</span>
              <span class="font-medium">Dashboard</span>
            </NuxtLink>

            <!-- User info y logout en mobile -->
            <div v-if="user" class="pt-4 mt-4 border-t border-gray-100">
              <div class="flex items-center gap-3 px-4 py-3">
                <div class="flex h-10 w-10 items-center justify-center rounded-xl bg-gradient-to-br from-primary/10 to-blue-100 text-primary font-bold">
                  {{ user.name?.charAt(0).toUpperCase() }}
                </div>
                <div>
                  <p class="font-semibold text-gray-900">{{ user.name }}</p>
                  <p class="text-sm text-gray-500">{{ user.email }}</p>
                </div>
              </div>
              <button
                type="button"
                class="w-full flex items-center gap-3 px-4 py-3 rounded-xl text-rose-600 hover:bg-rose-50 transition-all mt-2"
                @click="handleLogout"
              >
                <span class="material-symbols-outlined">logout</span>
                <span class="font-medium">Cerrar sesión</span>
              </button>
            </div>

            <!-- Login en mobile cuando no hay usuario -->
            <NuxtLink
              v-else
              to="/auth/login"
              class="flex items-center justify-center gap-2 px-4 py-3 rounded-xl bg-gradient-to-r from-primary to-primary-dark text-white font-semibold shadow-lg shadow-primary/25 mt-4"
              @click="closeMobileMenu"
            >
              <span class="material-symbols-outlined">login</span>
              Iniciar sesión
            </NuxtLink>
          </div>
        </div>
      </Transition>
    </header>
    
    <!-- Overlay para cerrar el menú de usuario -->
    <div 
      v-if="showUserMenu" 
      class="fixed inset-0 z-30" 
      @click="showUserMenu = false"
    />
    
    <main>
      <slot />
    </main>
    
    <!-- Footer moderno -->
    <footer class="bg-white border-t border-gray-100 mt-16">
      <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8 py-12">
        <div class="flex flex-col md:flex-row items-center justify-between gap-6">
          <!-- Logo y descripción -->
          <div class="flex items-center gap-3">
            <div class="flex h-10 w-10 items-center justify-center rounded-xl bg-gradient-to-br from-primary to-primary-dark">
              <span class="material-symbols-outlined text-xl text-white">home_work</span>
            </div>
            <div>
              <p class="font-bold text-gray-900">Spazio</p>
              <p class="text-sm text-gray-500">Tu espacio ideal, a un clic</p>
            </div>
          </div>
          
          <!-- Links rápidos -->
          <div class="flex items-center gap-6 text-sm">
            <NuxtLink to="/" class="text-gray-600 hover:text-primary transition-colors">Explorar</NuxtLink>
            <NuxtLink to="/auth/login" class="text-gray-600 hover:text-primary transition-colors">Iniciar sesión</NuxtLink>
            <NuxtLink to="/auth/register" class="text-gray-600 hover:text-primary transition-colors">Registrarse</NuxtLink>
          </div>
          
          <!-- Copyright -->
          <p class="text-sm text-gray-400">
            © {{ currentYear }} Spazio. Todos los derechos reservados.
          </p>
        </div>
      </div>
    </footer>
  </div>
</template>
