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
    await login({ ...form }, { redirectTo: redirectPath.value })
  } catch (err) {
    serverError.value = err instanceof Error ? err.message : 'No fue posible iniciar sesión'
  }
}
</script>

<template>
  <section class="flex w-full max-w-6xl flex-col overflow-hidden rounded-3xl bg-white shadow-xl ring-1 ring-black/5 md:flex-row">
    <div class="hidden w-full bg-cover bg-center md:w-1/2" aria-hidden="true"
      style="background-image: url('https://images.unsplash.com/photo-1486401899868-0e435ed85128?auto=format&fit=crop&w=1400&q=80');"
    >
      <div class="flex h-full w-full flex-col justify-between bg-gradient-to-t from-black/70 via-black/20 to-black/10 p-10 text-white">
        <div>
          <p class="text-sm uppercase tracking-[0.3em] text-white/80">Sistema inteligente</p>
          <h2 class="mt-3 text-4xl font-semibold">Gestiona tus espacios</h2>
          <p class="mt-4 text-lg text-white/80">
            Administra reservas, evita double-booking y ofrece experiencias memorables a tus clientes desde un solo panel.
          </p>
        </div>
        <div class="rounded-2xl bg-white/5 p-5 backdrop-blur">
          <p class="text-sm text-white/80">¿Eres propietario?</p>
          <p class="text-xl font-semibold">Solicita acceso verificado y publica tus espacios en minutos.</p>
        </div>
      </div>
    </div>

    <div class="w-full md:w-1/2">
      <div class="flex h-full flex-col justify-center px-6 py-10 sm:px-12 lg:px-16">
        <div class="mx-auto w-full max-w-md space-y-8">
          <div class="text-center">
            <p class="text-sm font-semibold uppercase tracking-[0.4em] text-primary">Spazio</p>
            <h1 class="mt-2 text-3xl font-bold text-[#111418]">Bienvenido de vuelta</h1>
            <p class="mt-2 text-base text-slate-500">Inicia sesión para continuar gestionando tus espacios.</p>
          </div>

          <form class="space-y-6" novalidate @submit.prevent="handleSubmit">
            <div class="space-y-2">
              <label class="text-sm font-medium text-[#111418]" for="email">Correo electrónico</label>
              <div class="relative">
                <span class="absolute inset-y-0 left-4 flex items-center text-slate-400">
                  <span class="material-symbols-outlined text-xl">mail</span>
                </span>
                <input
                  id="email"
                  v-model.trim="form.email"
                  type="email"
                  class="h-14 w-full rounded-xl border border-slate-200 bg-white/70 px-12 text-base text-[#111418] shadow-sm placeholder:text-slate-400 focus:border-primary focus:outline-none focus:ring-2 focus:ring-primary/20"
                  placeholder="correo@empresa.com"
                  autocomplete="email"
                />
              </div>
              <p v-if="fieldErrors.email" class="text-sm text-rose-600">{{ fieldErrors.email }}</p>
            </div>

            <div class="space-y-2">
              <div class="flex items-center justify-between">
                <label class="text-sm font-medium text-[#111418]" for="password">Contraseña</label>
                <NuxtLink to="#" class="text-sm font-semibold text-primary hover:underline">¿Olvidaste tu contraseña?</NuxtLink>
              </div>
              <div class="relative">
                <span class="absolute inset-y-0 left-4 flex items-center text-slate-400">
                  <span class="material-symbols-outlined text-xl">lock</span>
                </span>
                <input
                  id="password"
                  v-model.trim="form.password"
                  :type="showPassword ? 'text' : 'password'"
                  class="h-14 w-full rounded-xl border border-slate-200 bg-white/70 px-12 text-base text-[#111418] shadow-sm placeholder:text-slate-400 focus:border-primary focus:outline-none focus:ring-2 focus:ring-primary/20"
                  placeholder="••••••••"
                  autocomplete="current-password"
                />
                <button
                  type="button"
                  class="absolute inset-y-0 right-4 flex items-center text-slate-400 hover:text-primary"
                  @click="showPassword = !showPassword"
                >
                  <span class="material-symbols-outlined text-xl">{{ showPassword ? 'visibility_off' : 'visibility' }}</span>
                </button>
              </div>
              <p v-if="fieldErrors.password" class="text-sm text-rose-600">{{ fieldErrors.password }}</p>
            </div>

            <div v-if="serverError" class="rounded-xl border border-rose-100 bg-rose-50 px-4 py-3 text-sm text-rose-700">
              {{ serverError }}
            </div>

            <button
              type="submit"
              class="flex h-14 w-full items-center justify-center rounded-xl bg-primary text-base font-semibold text-white shadow-lg shadow-primary/30 transition hover:bg-primary/90 focus:outline-none focus:ring-2 focus:ring-primary/40"
              :disabled="loading"
            >
              <span v-if="!loading">Iniciar sesión</span>
              <span v-else class="flex items-center gap-2">
                <span class="h-4 w-4 animate-spin rounded-full border-2 border-white/50 border-t-white" />
                Procesando...
              </span>
            </button>
          </form>

          <p class="text-center text-sm text-slate-500">
            ¿No tienes una cuenta?
            <NuxtLink to="#" class="font-semibold text-primary hover:underline">Crea una cuenta</NuxtLink>
          </p>

          <p class="text-center text-xs text-slate-400">© {{ currentYear }} Spazio. Todos los derechos reservados.</p>
        </div>
      </div>
    </div>
  </section>
</template>
