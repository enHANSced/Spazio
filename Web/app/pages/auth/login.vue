<script setup lang="ts">
import { computed, reactive, ref, watch } from 'vue'
import type { LoginPayload } from '../../types/auth'

definePageMeta({
  layout: 'auth',
  middleware: 'guest'
})

useSeoMeta({
  title: 'Iniciar sesión - Spazio',
  description: 'Ingresa tus credenciales para acceder al panel inteligente de reservas Spazio.'
})

const route = useRoute()
const { login, loading, error } = useAuth()

const form = reactive<LoginPayload>({
  email: '',
  password: ''
})

const fieldErrors = reactive({
  email: '',
  password: ''
})

const serverError = ref('')
const showPassword = ref(false)
const rememberMe = ref(false)
const currentYear = new Date().getFullYear()

const redirectPath = computed(() =>
  typeof route.query.redirect === 'string' && route.query.redirect.length > 0
    ? route.query.redirect
    : '/'
)

watch(error, (value) => {
  if (value) {
    serverError.value = value
  }
})

watch(
  () => [form.email, form.password],
  () => {
    serverError.value = ''
  }
)

const validate = () => {
  fieldErrors.email = ''
  fieldErrors.password = ''
  let isValid = true

  if (!form.email) {
    fieldErrors.email = 'El correo es obligatorio'
    isValid = false
  } else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(form.email)) {
    fieldErrors.email = 'Ingresa un correo válido'
    isValid = false
  }

  if (!form.password) {
    fieldErrors.password = 'La contraseña es obligatoria'
    isValid = false
  } else if (form.password.length < 6) {
    fieldErrors.password = 'La contraseña debe tener al menos 6 caracteres'
    isValid = false
  }

  return isValid
}

const handleSubmit = async () => {
  if (!validate()) return

  serverError.value = ''

  try {
    const options = redirectPath.value !== '/' 
      ? { redirectTo: redirectPath.value } 
      : undefined
    
    await login({ ...form }, options)
  } catch (err) {
    serverError.value = err instanceof Error ? err.message : 'No fue posible iniciar sesión'
  }
}
</script>

<template>
  <section class="flex w-full max-w-5xl flex-col overflow-hidden rounded-3xl bg-white shadow-2xl ring-1 ring-black/5 lg:flex-row">
    <!-- Panel izquierdo - Solo visible en lg+ -->
    <div 
      class="relative hidden w-full overflow-hidden lg:block lg:w-1/2"
      aria-hidden="true"
    >
      <!-- Fondo con gradiente -->
      <div class="absolute inset-0 bg-gradient-to-br from-primary via-primary-dark to-blue-900" />
      
      <!-- Patrón decorativo -->
      <div class="absolute inset-0 opacity-10">
        <div class="absolute -left-20 -top-20 h-80 w-80 rounded-full bg-white/20 blur-3xl" />
        <div class="absolute -bottom-20 -right-20 h-96 w-96 rounded-full bg-white/10 blur-3xl" />
      </div>
      
      <!-- Contenido -->
      <div class="relative flex h-full min-h-[600px] flex-col justify-between p-10 text-white">
        <div>
          <div class="mb-8 flex items-center gap-3">
            <div class="flex h-12 w-12 items-center justify-center rounded-2xl bg-white/20 backdrop-blur-sm">
              <span class="material-symbols-outlined text-2xl">home_work</span>
            </div>
            <span class="text-2xl font-bold">Spazio</span>
          </div>
          
          <h2 class="text-4xl font-bold leading-tight">
            Tu espacio ideal,<br>
            <span class="text-white/80">a un clic de distancia</span>
          </h2>
          
          <p class="mt-6 text-lg text-white/70">
            Reserva salas de reuniones, espacios de coworking y más. 
            Sin complicaciones, sin dobles reservas.
          </p>
        </div>
        
        <!-- Stats/Features -->
        <div class="space-y-4">
          <div class="flex items-center gap-4 rounded-2xl bg-white/10 p-4 backdrop-blur-sm">
            <div class="flex h-12 w-12 items-center justify-center rounded-xl bg-white/20">
              <span class="material-symbols-outlined text-xl">verified</span>
            </div>
            <div>
              <p class="font-semibold">Espacios verificados</p>
              <p class="text-sm text-white/70">100% confiables y seguros</p>
            </div>
          </div>
          
          <div class="flex items-center gap-4 rounded-2xl bg-white/10 p-4 backdrop-blur-sm">
            <div class="flex h-12 w-12 items-center justify-center rounded-xl bg-white/20">
              <span class="material-symbols-outlined text-xl">bolt</span>
            </div>
            <div>
              <p class="font-semibold">Reserva instantánea</p>
              <p class="text-sm text-white/70">Confirmación en segundos</p>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Panel derecho - Formulario -->
    <div class="w-full lg:w-1/2">
      <div class="flex h-full flex-col justify-center px-6 py-12 sm:px-12 lg:px-14">
        <div class="mx-auto w-full max-w-sm space-y-8">
          <!-- Header -->
          <div class="text-center">
            <!-- Logo animado -->
            <div class="mx-auto mb-6 flex h-16 w-16 items-center justify-center rounded-2xl bg-gradient-to-br from-primary to-primary-dark shadow-lg shadow-primary/30">
              <span class="material-symbols-outlined text-3xl text-white">home_work</span>
            </div>
            
            <h1 class="text-2xl font-bold text-gray-900">¡Bienvenido de vuelta!</h1>
            <p class="mt-2 text-sm text-gray-500">Ingresa tus credenciales para continuar</p>
          </div>

          <!-- Formulario -->
          <form class="space-y-5" novalidate @submit.prevent="handleSubmit">
            <!-- Email -->
            <div class="space-y-1.5">
              <label class="text-sm font-medium text-gray-700" for="email">Correo electrónico</label>
              <div class="group relative">
                <span class="absolute inset-y-0 left-0 flex items-center pl-4 text-gray-400 transition-colors group-focus-within:text-primary">
                  <span class="material-symbols-outlined text-xl">mail</span>
                </span>
                <input
                  id="email"
                  v-model.trim="form.email"
                  type="email"
                  class="h-12 w-full rounded-xl border border-gray-200 bg-gray-50/50 pl-12 pr-4 text-sm text-gray-900 transition-all placeholder:text-gray-400 hover:border-gray-300 focus:border-primary focus:bg-white focus:outline-none focus:ring-2 focus:ring-primary/20"
                  placeholder="tu@correo.com"
                  autocomplete="email"
                />
              </div>
              <p v-if="fieldErrors.email" class="flex items-center gap-1.5 text-xs text-rose-600">
                <span class="material-symbols-outlined text-sm">error</span>
                {{ fieldErrors.email }}
              </p>
            </div>

            <!-- Password -->
            <div class="space-y-1.5">
              <div class="flex items-center justify-between">
                <label class="text-sm font-medium text-gray-700" for="password">Contraseña</label>
                <NuxtLink to="#" class="text-xs font-medium text-primary transition-colors hover:text-primary-dark">
                  ¿Olvidaste tu contraseña?
                </NuxtLink>
              </div>
              <div class="group relative">
                <span class="absolute inset-y-0 left-0 flex items-center pl-4 text-gray-400 transition-colors group-focus-within:text-primary">
                  <span class="material-symbols-outlined text-xl">lock</span>
                </span>
                <input
                  id="password"
                  v-model.trim="form.password"
                  :type="showPassword ? 'text' : 'password'"
                  class="h-12 w-full rounded-xl border border-gray-200 bg-gray-50/50 pl-12 pr-12 text-sm text-gray-900 transition-all placeholder:text-gray-400 hover:border-gray-300 focus:border-primary focus:bg-white focus:outline-none focus:ring-2 focus:ring-primary/20"
                  placeholder="••••••••"
                  autocomplete="current-password"
                />
                <button
                  type="button"
                  class="absolute inset-y-0 right-0 flex items-center pr-4 text-gray-400 transition-colors hover:text-gray-600"
                  @click="showPassword = !showPassword"
                >
                  <span class="material-symbols-outlined text-xl">{{ showPassword ? 'visibility_off' : 'visibility' }}</span>
                </button>
              </div>
              <p v-if="fieldErrors.password" class="flex items-center gap-1.5 text-xs text-rose-600">
                <span class="material-symbols-outlined text-sm">error</span>
                {{ fieldErrors.password }}
              </p>
            </div>

            <!-- Recordarme -->
            <label class="flex cursor-pointer items-center gap-3">
              <div class="relative">
                <input
                  v-model="rememberMe"
                  type="checkbox"
                  class="peer h-5 w-5 cursor-pointer appearance-none rounded-md border-2 border-gray-300 transition-all checked:border-primary checked:bg-primary hover:border-gray-400"
                />
                <span class="pointer-events-none absolute left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 text-white opacity-0 transition-opacity peer-checked:opacity-100">
                  <span class="material-symbols-outlined text-sm font-bold">check</span>
                </span>
              </div>
              <span class="text-sm text-gray-600">Recordarme por 30 días</span>
            </label>

            <!-- Error del servidor -->
            <div v-if="serverError" class="flex items-start gap-3 rounded-xl border border-rose-200 bg-rose-50 px-4 py-3">
              <span class="material-symbols-outlined text-rose-500">error</span>
              <p class="text-sm text-rose-700">{{ serverError }}</p>
            </div>

            <!-- Botón submit -->
            <button
              type="submit"
              class="group relative flex h-12 w-full items-center justify-center overflow-hidden rounded-xl bg-gradient-to-r from-primary to-primary-dark font-semibold text-white shadow-lg shadow-primary/25 transition-all hover:shadow-xl hover:shadow-primary/30 focus:outline-none focus:ring-2 focus:ring-primary/40 disabled:cursor-not-allowed disabled:opacity-70"
              :disabled="loading"
            >
              <span v-if="!loading" class="flex items-center gap-2">
                Iniciar sesión
                <span class="material-symbols-outlined text-xl transition-transform group-hover:translate-x-1">arrow_forward</span>
              </span>
              <span v-else class="flex items-center gap-2">
                <span class="h-5 w-5 animate-spin rounded-full border-2 border-white/30 border-t-white" />
                Ingresando...
              </span>
            </button>
          </form>

          <!-- Divider -->
          <div class="relative">
            <div class="absolute inset-0 flex items-center">
              <div class="w-full border-t border-gray-200" />
            </div>
            <div class="relative flex justify-center text-xs uppercase">
              <span class="bg-white px-4 text-gray-400">¿Nuevo en Spazio?</span>
            </div>
          </div>

          <!-- Registro -->
          <NuxtLink 
            to="/auth/register" 
            class="flex h-12 w-full items-center justify-center gap-2 rounded-xl border-2 border-gray-200 font-medium text-gray-700 transition-all hover:border-primary hover:bg-primary/5 hover:text-primary"
          >
            <span class="material-symbols-outlined text-xl">person_add</span>
            Crear una cuenta
          </NuxtLink>

          <!-- Footer -->
          <p class="text-center text-xs text-gray-400">
            © {{ currentYear }} Spazio. Todos los derechos reservados.
          </p>
        </div>
      </div>
    </div>
  </section>
</template>
