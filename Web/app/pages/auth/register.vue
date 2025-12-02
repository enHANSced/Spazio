<script setup lang="ts">
import { reactive, ref, watch, computed } from 'vue'
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
  businessName: '',
  businessDescription: '',
  acceptTerms: false,
  subscribe: true
})

const fieldErrors = reactive({
  name: '',
  email: '',
  password: '',
  businessName: '',
  acceptTerms: ''
})

// Indicador de fortaleza de contraseña
const passwordStrength = computed(() => {
  const password = form.password
  if (!password) return { level: 0, text: '', color: '' }
  
  let score = 0
  if (password.length >= 6) score++
  if (password.length >= 8) score++
  if (/[a-z]/.test(password) && /[A-Z]/.test(password)) score++
  if (/\d/.test(password)) score++
  if (/[^a-zA-Z0-9]/.test(password)) score++
  
  if (score <= 1) return { level: 1, text: 'Débil', color: 'bg-rose-500' }
  if (score <= 2) return { level: 2, text: 'Regular', color: 'bg-orange-500' }
  if (score <= 3) return { level: 3, text: 'Buena', color: 'bg-yellow-500' }
  if (score <= 4) return { level: 4, text: 'Fuerte', color: 'bg-emerald-500' }
  return { level: 5, text: 'Excelente', color: 'bg-emerald-600' }
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

  if (form.role === 'owner' && !form.businessName.trim()) {
    fieldErrors.businessName = 'El nombre del negocio es obligatorio para propietarios'
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

    if (form.role === 'owner') {
      payload.businessName = form.businessName.trim()
      if (form.businessDescription.trim()) {
        payload.businessDescription = form.businessDescription.trim()
      }
    }

    await register(payload, { redirectTo: form.role === 'owner' ? '/owner/pending-verification' : '/' })
  } catch (err) {
    serverError.value = err instanceof Error ? err.message : 'No fue posible crear tu cuenta'
  }
}
</script>

<template>
  <section class="flex w-full max-w-5xl overflow-hidden rounded-3xl bg-white shadow-2xl ring-1 ring-black/5">
    <!-- Panel izquierdo - Solo visible en lg+ -->
    <div class="relative hidden w-1/2 overflow-hidden lg:block">
      <!-- Fondo con gradiente -->
      <div class="absolute inset-0 bg-gradient-to-br from-primary via-primary-dark to-blue-900" />
      
      <!-- Patrón decorativo -->
      <div class="absolute inset-0 opacity-10">
        <div class="absolute -left-20 top-1/4 h-80 w-80 rounded-full bg-white/20 blur-3xl" />
        <div class="absolute -right-20 bottom-1/4 h-96 w-96 rounded-full bg-white/10 blur-3xl" />
      </div>
      
      <!-- Contenido -->
      <div class="relative flex h-full min-h-[700px] flex-col justify-between p-10 text-white">
        <div>
          <div class="mb-8 flex items-center gap-3">
            <div class="flex h-12 w-12 items-center justify-center rounded-2xl bg-white/20 backdrop-blur-sm">
              <span class="material-symbols-outlined text-2xl">home_work</span>
            </div>
            <span class="text-2xl font-bold">Spazio</span>
          </div>
          
          <h2 class="text-4xl font-bold leading-tight">
            Únete a la comunidad<br>
            <span class="text-white/80">de espacios inteligentes</span>
          </h2>
          
          <p class="mt-6 text-lg text-white/70">
            Crea tu cuenta y descubre un mundo de posibilidades para reservar 
            o gestionar espacios de trabajo.
          </p>
        </div>
        
        <!-- Beneficios -->
        <div class="space-y-3">
          <p class="text-sm font-medium uppercase tracking-wider text-white/60">Lo que obtendrás</p>
          
          <div class="flex items-center gap-4 rounded-2xl bg-white/10 p-4 backdrop-blur-sm">
            <div class="flex h-10 w-10 items-center justify-center rounded-xl bg-white/20">
              <span class="material-symbols-outlined text-lg">calendar_month</span>
            </div>
            <div>
              <p class="font-semibold">Reservas en tiempo real</p>
              <p class="text-sm text-white/70">Calendario siempre actualizado</p>
            </div>
          </div>
          
          <div class="flex items-center gap-4 rounded-2xl bg-white/10 p-4 backdrop-blur-sm">
            <div class="flex h-10 w-10 items-center justify-center rounded-xl bg-white/20">
              <span class="material-symbols-outlined text-lg">shield</span>
            </div>
            <div>
              <p class="font-semibold">Pagos seguros</p>
              <p class="text-sm text-white/70">Transacciones protegidas</p>
            </div>
          </div>
          
          <div class="flex items-center gap-4 rounded-2xl bg-white/10 p-4 backdrop-blur-sm">
            <div class="flex h-10 w-10 items-center justify-center rounded-xl bg-white/20">
              <span class="material-symbols-outlined text-lg">support_agent</span>
            </div>
            <div>
              <p class="font-semibold">Soporte dedicado</p>
              <p class="text-sm text-white/70">Ayuda cuando la necesites</p>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Panel derecho - Formulario -->
    <div class="w-full px-6 py-8 sm:px-10 lg:w-1/2 lg:px-12 lg:py-10">
      <!-- Header -->
      <header class="text-center">
        <div class="mx-auto mb-4 flex h-14 w-14 items-center justify-center rounded-2xl bg-gradient-to-br from-primary to-primary-dark shadow-lg shadow-primary/30">
          <span class="material-symbols-outlined text-2xl text-white">person_add</span>
        </div>
        <h1 class="text-2xl font-bold text-gray-900">Crea tu cuenta</h1>
        <p class="mt-1 text-sm text-gray-500">Completa el formulario para comenzar</p>
      </header>

      <form class="mt-6 space-y-4" novalidate @submit.prevent="handleSubmit">
        <!-- Tipo de cuenta -->
        <div class="space-y-2">
          <label class="text-sm font-medium text-gray-700">Tipo de cuenta</label>
          <div class="grid grid-cols-2 gap-3">
            <label 
              class="group relative flex cursor-pointer items-center gap-3 rounded-xl border-2 p-4 transition-all"
              :class="form.role === 'user' 
                ? 'border-primary bg-primary/5 shadow-sm' 
                : 'border-gray-200 hover:border-gray-300 hover:bg-gray-50'"
            >
              <input v-model="form.role" type="radio" value="user" class="sr-only" />
              <div 
                class="flex h-10 w-10 items-center justify-center rounded-xl transition-all"
                :class="form.role === 'user' ? 'bg-primary text-white' : 'bg-gray-100 text-gray-500'"
              >
                <span class="material-symbols-outlined text-xl">person</span>
              </div>
              <div class="flex-1">
                <p class="text-sm font-semibold text-gray-900">Usuario</p>
                <p class="text-xs text-gray-500">Reservar espacios</p>
              </div>
              <div 
                v-if="form.role === 'user'"
                class="absolute right-3 top-3 flex h-5 w-5 items-center justify-center rounded-full bg-primary text-white"
              >
                <span class="material-symbols-outlined text-sm">check</span>
              </div>
            </label>
            
            <label 
              class="group relative flex cursor-pointer items-center gap-3 rounded-xl border-2 p-4 transition-all"
              :class="form.role === 'owner' 
                ? 'border-primary bg-primary/5 shadow-sm' 
                : 'border-gray-200 hover:border-gray-300 hover:bg-gray-50'"
            >
              <input v-model="form.role" type="radio" value="owner" class="sr-only" />
              <div 
                class="flex h-10 w-10 items-center justify-center rounded-xl transition-all"
                :class="form.role === 'owner' ? 'bg-primary text-white' : 'bg-gray-100 text-gray-500'"
              >
                <span class="material-symbols-outlined text-xl">store</span>
              </div>
              <div class="flex-1">
                <p class="text-sm font-semibold text-gray-900">Propietario</p>
                <p class="text-xs text-gray-500">Gestionar espacios</p>
              </div>
              <div 
                v-if="form.role === 'owner'"
                class="absolute right-3 top-3 flex h-5 w-5 items-center justify-center rounded-full bg-primary text-white"
              >
                <span class="material-symbols-outlined text-sm">check</span>
              </div>
            </label>
          </div>
        </div>

        <!-- Nombre -->
        <div class="space-y-1.5">
          <label for="name" class="text-sm font-medium text-gray-700">Nombre completo</label>
          <div class="group relative">
            <span class="absolute inset-y-0 left-0 flex items-center pl-4 text-gray-400 transition-colors group-focus-within:text-primary">
              <span class="material-symbols-outlined text-xl">badge</span>
            </span>
            <input
              id="name"
              v-model.trim="form.name"
              type="text"
              class="h-11 w-full rounded-xl border border-gray-200 bg-gray-50/50 pl-12 pr-4 text-sm text-gray-900 transition-all placeholder:text-gray-400 hover:border-gray-300 focus:border-primary focus:bg-white focus:outline-none focus:ring-2 focus:ring-primary/20"
              placeholder="Ingresa tu nombre completo"
              autocomplete="name"
            />
          </div>
          <p v-if="fieldErrors.name" class="flex items-center gap-1.5 text-xs text-rose-600">
            <span class="material-symbols-outlined text-sm">error</span>
            {{ fieldErrors.name }}
          </p>
        </div>

        <!-- Email -->
        <div class="space-y-1.5">
          <label for="email" class="text-sm font-medium text-gray-700">Correo electrónico</label>
          <div class="group relative">
            <span class="absolute inset-y-0 left-0 flex items-center pl-4 text-gray-400 transition-colors group-focus-within:text-primary">
              <span class="material-symbols-outlined text-xl">mail</span>
            </span>
            <input
              id="email"
              v-model.trim="form.email"
              type="email"
              class="h-11 w-full rounded-xl border border-gray-200 bg-gray-50/50 pl-12 pr-4 text-sm text-gray-900 transition-all placeholder:text-gray-400 hover:border-gray-300 focus:border-primary focus:bg-white focus:outline-none focus:ring-2 focus:ring-primary/20"
              placeholder="tu@correo.com"
              autocomplete="email"
            />
          </div>
          <p v-if="fieldErrors.email" class="flex items-center gap-1.5 text-xs text-rose-600">
            <span class="material-symbols-outlined text-sm">error</span>
            {{ fieldErrors.email }}
          </p>
        </div>

        <!-- Campos de propietario -->
        <template v-if="form.role === 'owner'">
          <div class="space-y-1.5">
            <label for="businessName" class="text-sm font-medium text-gray-700">
              Nombre del negocio <span class="text-rose-500">*</span>
            </label>
            <div class="group relative">
              <span class="absolute inset-y-0 left-0 flex items-center pl-4 text-gray-400 transition-colors group-focus-within:text-primary">
                <span class="material-symbols-outlined text-xl">storefront</span>
              </span>
              <input
                id="businessName"
                v-model.trim="form.businessName"
                type="text"
                class="h-11 w-full rounded-xl border border-gray-200 bg-gray-50/50 pl-12 pr-4 text-sm text-gray-900 transition-all placeholder:text-gray-400 hover:border-gray-300 focus:border-primary focus:bg-white focus:outline-none focus:ring-2 focus:ring-primary/20"
                placeholder="Ej: Cowork Central, Salas Premium"
                autocomplete="organization"
              />
            </div>
            <p v-if="fieldErrors.businessName" class="flex items-center gap-1.5 text-xs text-rose-600">
              <span class="material-symbols-outlined text-sm">error</span>
              {{ fieldErrors.businessName }}
            </p>
          </div>

          <div class="space-y-1.5">
            <label for="businessDescription" class="text-sm font-medium text-gray-700">
              Descripción <span class="text-xs text-gray-400">(opcional)</span>
            </label>
            <textarea
              id="businessDescription"
              v-model.trim="form.businessDescription"
              rows="2"
              class="w-full rounded-xl border border-gray-200 bg-gray-50/50 px-4 py-3 text-sm text-gray-900 transition-all placeholder:text-gray-400 hover:border-gray-300 focus:border-primary focus:bg-white focus:outline-none focus:ring-2 focus:ring-primary/20"
              placeholder="Describe brevemente tu negocio..."
            />
          </div>
        </template>

        <!-- Contraseña -->
        <div class="space-y-1.5">
          <label for="password" class="text-sm font-medium text-gray-700">Contraseña</label>
          <div class="group relative">
            <span class="absolute inset-y-0 left-0 flex items-center pl-4 text-gray-400 transition-colors group-focus-within:text-primary">
              <span class="material-symbols-outlined text-xl">lock</span>
            </span>
            <input
              id="password"
              v-model="form.password"
              :type="showPassword ? 'text' : 'password'"
              class="h-11 w-full rounded-xl border border-gray-200 bg-gray-50/50 pl-12 pr-12 text-sm text-gray-900 transition-all placeholder:text-gray-400 hover:border-gray-300 focus:border-primary focus:bg-white focus:outline-none focus:ring-2 focus:ring-primary/20"
              placeholder="Crea una contraseña segura"
              autocomplete="new-password"
            />
            <button
              type="button"
              class="absolute inset-y-0 right-0 flex items-center pr-4 text-gray-400 transition-colors hover:text-gray-600"
              @click="showPassword = !showPassword"
            >
              <span class="material-symbols-outlined text-xl">{{ showPassword ? 'visibility_off' : 'visibility' }}</span>
            </button>
          </div>
          
          <!-- Indicador de fortaleza -->
          <div v-if="form.password" class="space-y-1.5">
            <div class="flex gap-1">
              <div 
                v-for="i in 5" 
                :key="i" 
                class="h-1 flex-1 rounded-full transition-all"
                :class="i <= passwordStrength.level ? passwordStrength.color : 'bg-gray-200'"
              />
            </div>
            <p class="text-xs" :class="passwordStrength.level >= 3 ? 'text-emerald-600' : 'text-gray-500'">
              Seguridad: {{ passwordStrength.text }}
            </p>
          </div>
          
          <p v-if="fieldErrors.password" class="flex items-center gap-1.5 text-xs text-rose-600">
            <span class="material-symbols-outlined text-sm">error</span>
            {{ fieldErrors.password }}
          </p>
        </div>

        <!-- Términos y condiciones -->
        <div class="space-y-3 pt-2">
          <label class="flex cursor-pointer items-start gap-3">
            <div class="relative mt-0.5">
              <input
                v-model="form.acceptTerms"
                type="checkbox"
                class="peer h-5 w-5 cursor-pointer appearance-none rounded-md border-2 border-gray-300 transition-all checked:border-primary checked:bg-primary hover:border-gray-400"
              />
              <span class="pointer-events-none absolute left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 text-white opacity-0 transition-opacity peer-checked:opacity-100">
                <span class="material-symbols-outlined text-sm font-bold">check</span>
              </span>
            </div>
            <span class="text-sm text-gray-600">
              Acepto los
              <NuxtLink to="#" class="font-medium text-primary hover:underline">Términos y Condiciones</NuxtLink>
              y la
              <NuxtLink to="#" class="font-medium text-primary hover:underline">Política de privacidad</NuxtLink>
            </span>
          </label>
          <p v-if="fieldErrors.acceptTerms" class="flex items-center gap-1.5 text-xs text-rose-600">
            <span class="material-symbols-outlined text-sm">error</span>
            {{ fieldErrors.acceptTerms }}
          </p>

          <label class="flex cursor-pointer items-start gap-3">
            <div class="relative mt-0.5">
              <input
                v-model="form.subscribe"
                type="checkbox"
                class="peer h-5 w-5 cursor-pointer appearance-none rounded-md border-2 border-gray-300 transition-all checked:border-primary checked:bg-primary hover:border-gray-400"
              />
              <span class="pointer-events-none absolute left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 text-white opacity-0 transition-opacity peer-checked:opacity-100">
                <span class="material-symbols-outlined text-sm font-bold">check</span>
              </span>
            </div>
            <span class="text-sm text-gray-600">Recibir novedades y consejos en mi correo</span>
          </label>
        </div>

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
            Crear cuenta
            <span class="material-symbols-outlined text-xl transition-transform group-hover:translate-x-1">arrow_forward</span>
          </span>
          <span v-else class="flex items-center gap-2">
            <span class="h-5 w-5 animate-spin rounded-full border-2 border-white/30 border-t-white" />
            Creando cuenta...
          </span>
        </button>
      </form>

      <!-- Footer -->
      <p class="mt-6 text-center text-sm text-gray-500">
        ¿Ya tienes una cuenta?
        <NuxtLink to="/auth/login" class="font-semibold text-primary hover:underline">Inicia sesión</NuxtLink>
      </p>
    </div>
  </section>
</template>
