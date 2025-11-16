<script setup lang="ts">
import { reactive, ref, watch } from 'vue'
import type { RegisterPayload } from '../../types/auth'

definePageMeta({
  layout: 'auth',
  middleware: 'guest'
})

useSeoMeta({
  title: 'Crear cuenta - Spazio',
  description: 'Regístrate en Spazio y gestiona reservas inteligentes en minutos.'
})

const { register, loading, error } = useAuth()
const showPassword = ref(false)
const serverError = ref('')

const form = reactive({
  name: '',
  email: '',
  password: '',
  role: 'user' as RegisterPayload['role'],
  acceptTerms: false,
  subscribe: true
})

const fieldErrors = reactive({
  name: '',
  email: '',
  password: '',
  acceptTerms: ''
})

watch(error, (value) => {
  if (value) serverError.value = value
})

watch(
  () => [form.name, form.email, form.password, form.acceptTerms, form.subscribe],
  () => {
    serverError.value = ''
  }
)

const validate = () => {
  fieldErrors.name = ''
  fieldErrors.email = ''
  fieldErrors.password = ''
  fieldErrors.acceptTerms = ''
  let isValid = true

  if (!form.name.trim()) {
    fieldErrors.name = 'El nombre es obligatorio'
    isValid = false
  }

  if (!form.email.trim()) {
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

  if (!form.acceptTerms) {
    fieldErrors.acceptTerms = 'Debes aceptar los términos y condiciones'
    isValid = false
  }

  return isValid
}

const handleSubmit = async () => {
  if (!validate()) return

  serverError.value = ''

  try {
    const payload: RegisterPayload = {
      name: form.name.trim(),
      email: form.email.trim(),
      password: form.password,
      role: form.role
    }

    await register(payload, { redirectTo: '/' })
  } catch (err) {
    serverError.value = err instanceof Error ? err.message : 'No fue posible crear tu cuenta'
  }
}
</script>

<template>
  <section class="flex w-full max-w-5xl overflow-hidden rounded-3xl bg-white shadow-2xl ring-1 ring-black/5">
    <div class="hidden w-1/2 flex-col justify-between bg-gradient-to-b from-primary to-primary-dark p-10 text-white lg:flex">
      <div>
        <p class="text-sm uppercase tracking-[0.3em] text-white/70">Spazio</p>
        <h2 class="mt-3 text-4xl font-bold leading-tight">Gestiona espacios sin complicaciones</h2>
        <p class="mt-4 text-base text-white/80">
          Registra tu cuenta y accede al ecosistema inteligente que evita dobles reservas y te mantiene en control.
        </p>
      </div>
      <div class="rounded-2xl bg-white/10 p-5 backdrop-blur">
        <p class="text-sm uppercase tracking-wide text-white/70">Beneficios</p>
        <ul class="mt-3 space-y-2 text-base">
          <li class="flex items-start gap-2">
            <span class="material-symbols-outlined text-xl">event_available</span>
            <span>Calendario en tiempo real para tus espacios</span>
          </li>
          <li class="flex items-start gap-2">
            <span class="material-symbols-outlined text-xl">verified_user</span>
            <span>Roles y verificaciones para propietarios</span>
          </li>
          <li class="flex items-start gap-2">
            <span class="material-symbols-outlined text-xl">flash_on</span>
            <span>Reservas confirmadas en segundos</span>
          </li>
        </ul>
      </div>
    </div>

    <div class="w-full px-6 py-10 sm:px-10 lg:w-1/2 lg:px-12">
      <header class="text-center">
        <div class="mx-auto mb-6 flex h-12 w-12 items-center justify-center rounded-2xl bg-primary/10 text-primary">
          <span class="material-symbols-outlined text-2xl">sparkles</span>
        </div>
        <p class="text-sm font-semibold uppercase tracking-[0.35em] text-primary">Spazio</p>
        <h1 class="mt-2 text-3xl font-bold text-[#111418]">Crea tu cuenta</h1>
        <p class="mt-2 text-base text-slate-500">Empieza a reservar tus espacios favoritos en minutos.</p>
      </header>

      <form class="mt-8 space-y-5" novalidate @submit.prevent="handleSubmit">
        <div class="space-y-2">
          <label for="name" class="text-sm font-medium text-[#111418]">Nombre completo</label>
          <input
            id="name"
            v-model.trim="form.name"
            type="text"
            class="h-12 w-full rounded-xl border border-slate-200 bg-white/80 px-4 text-base text-[#111418] shadow-sm placeholder:text-slate-400 focus:border-primary focus:outline-none focus:ring-2 focus:ring-primary/20"
            placeholder="Ingresa tu nombre completo"
            autocomplete="name"
          />
          <p v-if="fieldErrors.name" class="text-sm text-rose-600">{{ fieldErrors.name }}</p>
        </div>

        <div class="space-y-2">
          <label for="email" class="text-sm font-medium text-[#111418]">Correo electrónico</label>
          <input
            id="email"
            v-model.trim="form.email"
            type="email"
            class="h-12 w-full rounded-xl border border-slate-200 bg-white/80 px-4 text-base text-[#111418] shadow-sm placeholder:text-slate-400 focus:border-primary focus:outline-none focus:ring-2 focus:ring-primary/20"
            placeholder="tu@correo.com"
            autocomplete="email"
          />
          <p v-if="fieldErrors.email" class="text-sm text-rose-600">{{ fieldErrors.email }}</p>
        </div>

        <div class="space-y-2">
          <label for="password" class="text-sm font-medium text-[#111418]">Contraseña</label>
          <div class="relative">
            <input
              id="password"
              v-model="form.password"
              :type="showPassword ? 'text' : 'password'"
              class="h-12 w-full rounded-xl border border-slate-200 bg-white/80 px-4 pr-12 text-base text-[#111418] shadow-sm placeholder:text-slate-400 focus:border-primary focus:outline-none focus:ring-2 focus:ring-primary/20"
              placeholder="Crea una contraseña segura"
              autocomplete="new-password"
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
          <p class="text-xs text-slate-400">Mínimo 6 caracteres. Usa letras, números y símbolos si es posible.</p>
        </div>

        <div class="space-y-3">
          <label class="flex items-start gap-3">
            <input
              v-model="form.acceptTerms"
              type="checkbox"
              class="mt-1 h-5 w-5 rounded border-slate-300 text-primary focus:ring-primary/40"
            />
            <span class="text-sm text-slate-600">
              Acepto los
              <NuxtLink to="#" class="font-semibold text-primary hover:underline">Términos y Condiciones</NuxtLink>
              y la
              <NuxtLink to="#" class="font-semibold text-primary hover:underline">Política de privacidad</NuxtLink>.
            </span>
          </label>
          <p v-if="fieldErrors.acceptTerms" class="text-sm text-rose-600">{{ fieldErrors.acceptTerms }}</p>

          <label class="flex items-start gap-3">
            <input
              v-model="form.subscribe"
              type="checkbox"
              class="mt-1 h-5 w-5 rounded border-slate-300 text-primary focus:ring-primary/40"
            />
            <span class="text-sm text-slate-600">Deseo recibir novedades y consejos exclusivos en mi correo.</span>
          </label>
        </div>

        <div v-if="serverError" class="rounded-xl border border-rose-100 bg-rose-50 px-4 py-3 text-sm text-rose-700">
          {{ serverError }}
        </div>

        <button
          type="submit"
          class="flex h-12 w-full items-center justify-center rounded-xl bg-primary text-base font-semibold text-white shadow-lg shadow-primary/30 transition hover:bg-primary/90 focus:outline-none focus:ring-2 focus:ring-primary/40"
          :disabled="loading"
        >
          <span v-if="!loading">Crear cuenta</span>
          <span v-else class="flex items-center gap-2">
            <span class="h-4 w-4 animate-spin rounded-full border-2 border-white/50 border-t-white" />
            Creando cuenta...
          </span>
        </button>
      </form>

      <p class="mt-8 text-center text-sm text-slate-500">
        ¿Ya tienes una cuenta?
        <NuxtLink to="/auth/login" class="font-semibold text-primary hover:underline">Inicia sesión</NuxtLink>
      </p>
    </div>
  </section>
</template>
