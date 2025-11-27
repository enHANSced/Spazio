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

          <!-- Información de Contacto -->
          <div class="pt-6 border-t border-gray-100">
            <h3 class="text-lg font-medium text-gray-900 mb-4">Información de Contacto</h3>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
              <!-- Teléfono -->
              <div>
                <label for="phone" class="block text-sm font-medium text-gray-700 mb-2">
                  Teléfono
                </label>
                <input
                  id="phone"
                  v-model="form.phone"
                  type="tel"
                  maxlength="20"
                  class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors"
                  placeholder="+504 9999-9999"
                />
              </div>

              <!-- WhatsApp -->
              <div>
                <label for="whatsapp" class="block text-sm font-medium text-gray-700 mb-2">
                  WhatsApp
                </label>
                <input
                  id="whatsapp"
                  v-model="form.whatsappNumber"
                  type="tel"
                  maxlength="20"
                  class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors"
                  placeholder="+504 9999-9999"
                />
              </div>
            </div>
          </div>

          <!-- Redes Sociales -->
          <div class="pt-6 border-t border-gray-100">
            <h3 class="text-lg font-medium text-gray-900 mb-4">Redes Sociales</h3>
            <div class="space-y-4">
              <!-- Instagram -->
              <div>
                <label for="instagram" class="block text-sm font-medium text-gray-700 mb-2">
                  Instagram URL
                </label>
                <div class="relative">
                  <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                    <svg class="h-5 w-5 text-gray-400" fill="currentColor" viewBox="0 0 24 24">
                      <path d="M12 2.163c3.204 0 3.584.012 4.85.07 3.252.148 4.771 1.691 4.919 4.919.058 1.265.069 1.645.069 4.849 0 3.205-.012 3.584-.069 4.849-.149 3.225-1.664 4.771-4.919 4.919-1.266.058-1.644.07-4.85.07-3.204 0-3.584-.012-4.849-.07-3.26-.149-4.771-1.699-4.919-4.92-.058-1.265-.07-1.644-.07-4.849 0-3.204.013-3.583.07-4.849.149-3.227 1.664-4.771 4.919-4.919 1.266-.057 1.645-.069 4.849-.069zm0-2.163c-3.259 0-3.667.014-4.947.072-4.358.2-6.78 2.618-6.98 6.98-.059 1.281-.073 1.689-.073 4.948 0 3.259.014 3.668.072 4.948.2 4.358 2.618 6.78 6.98 6.98 1.281.058 1.689.072 4.948.072 3.259 0 3.668-.014 4.948-.072 4.354-.2 6.782-2.618 6.979-6.98.059-1.28.073-1.689.073-4.948 0-3.259-.014-3.667-.072-4.947-.196-4.354-2.617-6.78-6.979-6.98-1.281-.059-1.69-.073-4.949-.073zm0 5.838c-3.403 0-6.162 2.759-6.162 6.162s2.759 6.163 6.162 6.163 6.162-2.759 6.162-6.163c0-3.403-2.759-6.162-6.162-6.162zm0 10.162c-2.209 0-4-1.79-4-4 0-2.209 1.791-4 4-4s4 1.791 4 4c0 2.21-1.791 4-4 4zm6.406-11.845c-.796 0-1.441.645-1.441 1.44s.645 1.44 1.441 1.44c.795 0 1.439-.645 1.439-1.44s-.644-1.44-1.439-1.44z"/>
                    </svg>
                  </div>
                  <input
                    id="instagram"
                    v-model="form.instagram"
                    type="url"
                    class="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors"
                    placeholder="https://instagram.com/tu_negocio"
                  />
                </div>
              </div>

              <!-- Facebook -->
              <div>
                <label for="facebook" class="block text-sm font-medium text-gray-700 mb-2">
                  Facebook URL
                </label>
                <div class="relative">
                  <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                    <svg class="h-5 w-5 text-gray-400" fill="currentColor" viewBox="0 0 24 24">
                      <path d="M9 8h-3v4h3v12h5v-12h3.642l.358-4h-4v-1.667c0-.955.192-1.333 1.115-1.333h2.885v-5h-3.808c-3.596 0-5.192 1.583-5.192 4.615v3.385z"/>
                    </svg>
                  </div>
                  <input
                    id="facebook"
                    v-model="form.facebook"
                    type="url"
                    class="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors"
                    placeholder="https://facebook.com/tu_negocio"
                  />
                </div>
              </div>

              <!-- LinkedIn -->
              <div>
                <label for="linkedin" class="block text-sm font-medium text-gray-700 mb-2">
                  LinkedIn URL
                </label>
                <div class="relative">
                  <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                    <svg class="h-5 w-5 text-gray-400" fill="currentColor" viewBox="0 0 24 24">
                      <path d="M4.98 3.5c0 1.381-1.11 2.5-2.48 2.5s-2.48-1.119-2.48-2.5c0-1.38 1.11-2.5 2.48-2.5s2.48 1.12 2.48 2.5zm.02 4.5h-5v16h5v-16zm7.982 0h-4.968v16h4.969v-8.399c0-4.67 6.029-5.052 6.029 0v8.399h4.988v-10.131c0-7.88-8.922-7.593-11.018-3.714v-2.155z"/>
                    </svg>
                  </div>
                  <input
                    id="linkedin"
                    v-model="form.linkedin"
                    type="url"
                    class="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors"
                    placeholder="https://linkedin.com/in/tu_negocio"
                  />
                </div>
              </div>
            </div>
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
  isVerified: false,
  phone: '',
  whatsappNumber: '',
  instagram: '',
  facebook: '',
  linkedin: ''
})

const form = reactive({
  name: '',
  businessName: '',
  businessDescription: '',
  phone: '',
  whatsappNumber: '',
  instagram: '',
  facebook: '',
  linkedin: ''
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
        isVerified: response.data.isVerified ?? false,
        phone: response.data.phone || '',
        whatsappNumber: response.data.whatsappNumber || '',
        instagram: response.data.instagram || '',
        facebook: response.data.facebook || '',
        linkedin: response.data.linkedin || ''
      }

      // Copiar al formulario
      form.name = profile.value.name
      form.businessName = profile.value.businessName
      form.businessDescription = profile.value.businessDescription
      form.phone = profile.value.phone
      form.whatsappNumber = profile.value.whatsappNumber
      form.instagram = profile.value.instagram
      form.facebook = profile.value.facebook
      form.linkedin = profile.value.linkedin
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
      businessDescription: form.businessDescription.trim(),
      phone: form.phone.trim(),
      whatsappNumber: form.whatsappNumber.trim(),
      instagram: form.instagram.trim(),
      facebook: form.facebook.trim(),
      linkedin: form.linkedin.trim()
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
  form.phone = profile.value.phone
  form.whatsappNumber = profile.value.whatsappNumber
  form.instagram = profile.value.instagram
  form.facebook = profile.value.facebook
  form.linkedin = profile.value.linkedin
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
