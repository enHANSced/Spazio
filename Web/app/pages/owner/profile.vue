<template>
  <div class="max-w-4xl mx-auto">
    <!-- Header -->
    <div class="mb-8">
      <h1 class="text-3xl font-bold text-gray-900">Perfil de Propietario</h1>
      <p class="mt-2 text-gray-600">
        Administra la información de tu cuenta y negocio
      </p>
    </div>

    <!-- Loading -->
    <div v-if="loading" class="flex items-center justify-center min-h-[400px]">
      <div class="text-center">
        <svg
          class="animate-spin h-12 w-12 text-blue-600 mx-auto"
          viewBox="0 0 24 24"
        >
          <circle
            class="opacity-25"
            cx="12"
            cy="12"
            r="10"
            stroke="currentColor"
            stroke-width="4"
            fill="none"
          />
          <path
            class="opacity-75"
            fill="currentColor"
            d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
          />
        </svg>
        <p class="mt-4 text-gray-600">Cargando perfil...</p>
      </div>
    </div>

    <!-- Contenido -->
    <div v-else class="space-y-6">
      <!-- Estado de verificación -->
      <div
        :class="[
          'rounded-xl p-6 border',
          profile.isVerified
            ? 'bg-green-50 border-green-200'
            : 'bg-yellow-50 border-yellow-200'
        ]"
      >
        <div class="flex items-start gap-4">
          <div
            :class="[
              'flex-shrink-0 w-12 h-12 rounded-full flex items-center justify-center',
              profile.isVerified ? 'bg-green-100' : 'bg-yellow-100'
            ]"
          >
            <svg
              class="w-6 h-6"
              :class="profile.isVerified ? 'text-green-600' : 'text-yellow-600'"
              fill="currentColor"
              viewBox="0 0 20 20"
            >
              <path
                v-if="profile.isVerified"
                fill-rule="evenodd"
                d="M6.267 3.455a3.066 3.066 0 001.745-.723 3.066 3.066 0 013.976 0 3.066 3.066 0 001.745.723 3.066 3.066 0 012.812 2.812c.051.643.304 1.254.723 1.745a3.066 3.066 0 010 3.976 3.066 3.066 0 00-.723 1.745 3.066 3.066 0 01-2.812 2.812 3.066 3.066 0 00-1.745.723 3.066 3.066 0 01-3.976 0 3.066 3.066 0 00-1.745-.723 3.066 3.066 0 01-2.812-2.812 3.066 3.066 0 00-.723-1.745 3.066 3.066 0 010-3.976 3.066 3.066 0 00.723-1.745 3.066 3.066 0 012.812-2.812zm7.44 5.252a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z"
                clip-rule="evenodd"
              />
              <path
                v-else
                fill-rule="evenodd"
                d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z"
                clip-rule="evenodd"
              />
            </svg>
          </div>
          <div class="flex-1">
            <h3
              :class="[
                'text-lg font-semibold',
                profile.isVerified ? 'text-green-900' : 'text-yellow-900'
              ]"
            >
              {{ profile.isVerified ? 'Cuenta Verificada' : 'Verificación Pendiente' }}
            </h3>
            <p
              :class="[
                'mt-1 text-sm',
                profile.isVerified ? 'text-green-700' : 'text-yellow-700'
              ]"
            >
              {{
                profile.isVerified
                  ? 'Tu cuenta está verificada y puedes crear espacios'
                  : 'Tu cuenta está pendiente de verificación por un administrador'
              }}
            </p>
          </div>
        </div>
      </div>

      <!-- Formulario -->
      <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-8">
        <form @submit.prevent="handleSubmit" class="space-y-6">
          <!-- Nombre personal -->
          <div>
            <label for="name" class="block text-sm font-medium text-gray-700 mb-2">
              Nombre completo <span class="text-red-500">*</span>
            </label>
            <input
              id="name"
              v-model="form.name"
              type="text"
              required
              minlength="2"
              maxlength="100"
              :class="[
                'w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors',
                errors.name ? 'border-red-500' : 'border-gray-300'
              ]"
              placeholder="Tu nombre completo"
            />
            <p v-if="errors.name" class="mt-1 text-sm text-red-600">{{ errors.name }}</p>
          </div>

          <!-- Email (read-only) -->
          <div>
            <label for="email" class="block text-sm font-medium text-gray-700 mb-2">
              Correo electrónico
            </label>
            <input
              id="email"
              :value="profile.email"
              type="email"
              disabled
              class="w-full px-4 py-2 border border-gray-300 rounded-lg bg-gray-50 text-gray-500 cursor-not-allowed"
            />
            <p class="mt-1 text-sm text-gray-500">
              El correo electrónico no se puede modificar
            </p>
          </div>

          <!-- Nombre del negocio -->
          <div>
            <label for="businessName" class="block text-sm font-medium text-gray-700 mb-2">
              Nombre del negocio
            </label>
            <input
              id="businessName"
              v-model="form.businessName"
              type="text"
              minlength="2"
              maxlength="150"
              :class="[
                'w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors',
                errors.businessName ? 'border-red-500' : 'border-gray-300'
              ]"
              placeholder="Nombre de tu empresa o negocio"
            />
            <p v-if="errors.businessName" class="mt-1 text-sm text-red-600">
              {{ errors.businessName }}
            </p>
          </div>

          <!-- Descripción del negocio -->
          <div>
            <label
              for="businessDescription"
              class="block text-sm font-medium text-gray-700 mb-2"
            >
              Descripción del negocio
            </label>
            <textarea
              id="businessDescription"
              v-model="form.businessDescription"
              rows="4"
              maxlength="1000"
              class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors resize-none"
              placeholder="Describe tu negocio, servicios que ofreces, etc."
            />
            <p class="mt-1 text-sm text-gray-500">
              {{ form.businessDescription.length }}/1000 caracteres
            </p>
          </div>

          <!-- Error general -->
          <div
            v-if="generalError"
            class="bg-red-50 border border-red-200 text-red-800 px-4 py-3 rounded-lg text-sm"
          >
            {{ generalError }}
          </div>

          <!-- Mensaje de éxito -->
          <div
            v-if="successMessage"
            class="bg-green-50 border border-green-200 text-green-800 px-4 py-3 rounded-lg text-sm"
          >
            {{ successMessage }}
          </div>

          <!-- Botones -->
          <div class="flex gap-4 pt-4">
            <button
              type="submit"
              :disabled="isSubmitting"
              :class="[
                'flex-1 px-6 py-3 rounded-lg font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2',
                isSubmitting
                  ? 'bg-gray-400 cursor-not-allowed'
                  : 'bg-blue-600 hover:bg-blue-700 focus:ring-blue-500 text-white'
              ]"
            >
              <span v-if="isSubmitting" class="flex items-center justify-center gap-2">
                <svg class="animate-spin h-5 w-5" viewBox="0 0 24 24">
                  <circle
                    class="opacity-25"
                    cx="12"
                    cy="12"
                    r="10"
                    stroke="currentColor"
                    stroke-width="4"
                    fill="none"
                  />
                  <path
                    class="opacity-75"
                    fill="currentColor"
                    d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                  />
                </svg>
                Guardando...
              </span>
              <span v-else>Guardar Cambios</span>
            </button>

            <button
              type="button"
              @click="resetForm"
              :disabled="isSubmitting"
              class="px-6 py-3 border border-gray-300 rounded-lg font-medium text-gray-700 hover:bg-gray-50 transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-gray-500 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              Restablecer
            </button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { usersService } from '~/services/users.service'

definePageMeta({
  layout: 'owner',
  middleware: ['auth', 'owner']
})

const toast = useToast()

const loading = ref(true)
const isSubmitting = ref(false)
const generalError = ref('')
const successMessage = ref('')

const profile = ref({
  email: '',
  name: '',
  businessName: '',
  businessDescription: '',
  isVerified: false
})

const form = reactive({
  name: '',
  businessName: '',
  businessDescription: ''
})

const errors = reactive({
  name: '',
  businessName: ''
})

// Cargar perfil
const loadProfile = async () => {
  try {
    loading.value = true
    const response = await usersService.getMyProfile()

    if (response.success && response.data) {
      profile.value = {
        email: response.data.email || '',
        name: response.data.name || '',
        businessName: response.data.businessName || '',
        businessDescription: response.data.businessDescription || '',
        isVerified: response.data.isVerified ?? false
      }

      // Copiar al formulario
      form.name = profile.value.name
      form.businessName = profile.value.businessName
      form.businessDescription = profile.value.businessDescription
    }
  } catch (error: any) {
    console.error('Error loading profile:', error)
    toast.error('Error al cargar el perfil')
  } finally {
    loading.value = false
  }
}

// Validar formulario
const validateForm = (): boolean => {
  let isValid = true
  errors.name = ''
  errors.businessName = ''

  if (!form.name.trim()) {
    errors.name = 'El nombre es requerido'
    isValid = false
  } else if (form.name.length < 2) {
    errors.name = 'El nombre debe tener al menos 2 caracteres'
    isValid = false
  }

  if (form.businessName && form.businessName.length < 2) {
    errors.businessName = 'El nombre del negocio debe tener al menos 2 caracteres'
    isValid = false
  }

  return isValid
}

// Enviar cambios
const handleSubmit = async () => {
  if (!validateForm()) {
    generalError.value = 'Por favor corrige los errores antes de continuar'
    return
  }

  isSubmitting.value = true
  generalError.value = ''
  successMessage.value = ''

  try {
    const response = await usersService.updateMyProfile({
      name: form.name.trim(),
      businessName: form.businessName.trim(),
      businessDescription: form.businessDescription.trim()
    })

    if (response.success) {
      successMessage.value = '¡Perfil actualizado exitosamente!'
      toast.success('Perfil actualizado exitosamente')
      
      // Recargar perfil
      await loadProfile()
    } else {
      generalError.value = response.message || 'Error al actualizar el perfil'
      toast.error(response.message || 'Error al actualizar el perfil')
    }
  } catch (error: any) {
    console.error('Error updating profile:', error)
    const errorMessage = error.data?.message || error.message || 'Error al actualizar el perfil'
    generalError.value = errorMessage
    toast.error(errorMessage)
  } finally {
    isSubmitting.value = false
  }
}

const resetForm = () => {
  form.name = profile.value.name
  form.businessName = profile.value.businessName
  form.businessDescription = profile.value.businessDescription
  errors.name = ''
  errors.businessName = ''
  generalError.value = ''
  successMessage.value = ''
}

// Cargar al montar
onMounted(() => {
  loadProfile()
})
</script>
