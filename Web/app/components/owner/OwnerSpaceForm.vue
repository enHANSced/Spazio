<template>
  <form @submit.prevent="handleSubmit" class="space-y-6">
    <!-- Nombre del espacio -->
    <div>
      <label for="name" class="block text-sm font-medium text-gray-700 mb-2">
        Nombre del espacio <span class="text-red-500">*</span>
      </label>
      <input
        id="name"
        v-model="form.name"
        type="text"
        required
        maxlength="120"
        :class="[
          'w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors',
          errors.name ? 'border-red-500' : 'border-gray-300'
        ]"
        placeholder="Ej: Sala de Conferencias Principal"
      />
      <p v-if="errors.name" class="mt-1 text-sm text-red-600">{{ errors.name }}</p>
      <p class="mt-1 text-sm text-gray-500">{{ form.name.length }}/120 caracteres</p>
    </div>

    <!-- Descripción -->
    <div>
      <label for="description" class="block text-sm font-medium text-gray-700 mb-2">
        Descripción
      </label>
      <textarea
        id="description"
        v-model="form.description"
        rows="4"
        maxlength="1000"
        class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors resize-none"
        placeholder="Describe tu espacio, servicios incluidos, características especiales..."
      />
      <p class="mt-1 text-sm text-gray-500">{{ form.description.length }}/1000 caracteres</p>
    </div>

    <!-- Capacidad -->
    <div>
      <label for="capacity" class="block text-sm font-medium text-gray-700 mb-2">
        Capacidad <span class="text-red-500">*</span>
      </label>
      <input
        id="capacity"
        v-model.number="form.capacity"
        type="number"
        required
        min="1"
        max="10000"
        :class="[
          'w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors',
          errors.capacity ? 'border-red-500' : 'border-gray-300'
        ]"
        placeholder="Ej: 50"
      />
      <p v-if="errors.capacity" class="mt-1 text-sm text-red-600">{{ errors.capacity }}</p>
      <p class="mt-1 text-sm text-gray-500">Número de personas que puede acomodar</p>
    </div>

    <!-- Estado (solo en modo edición) -->
    <div v-if="mode === 'edit'" class="flex items-center gap-3">
      <label class="relative inline-flex items-center cursor-pointer">
        <input
          v-model="form.isActive"
          type="checkbox"
          class="sr-only peer"
        />
        <div
          class="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"
        ></div>
      </label>
      <div>
        <span class="text-sm font-medium text-gray-700">
          {{ form.isActive ? 'Espacio activo' : 'Espacio inactivo' }}
        </span>
        <p class="text-xs text-gray-500">
          {{ form.isActive ? 'Visible para usuarios' : 'Oculto del público' }}
        </p>
      </div>
    </div>

    <!-- Imágenes -->
    <div>
      <label class="block text-sm font-medium text-gray-700 mb-2">
        Imágenes del espacio
      </label>
      <ImageUploader
        v-model="images"
        :max-files="5"
        :max-size-m-b="5"
        :existing-images="existingImages"
      />
      <p class="mt-2 text-sm text-gray-500">
        Agrega fotos de buena calidad para atraer más clientes
      </p>
    </div>

    <!-- Errores generales -->
    <div
      v-if="generalError"
      class="bg-red-50 border border-red-200 text-red-800 px-4 py-3 rounded-lg text-sm"
    >
      {{ generalError }}
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
          {{ mode === 'create' ? 'Creando...' : 'Guardando...' }}
        </span>
        <span v-else>
          {{ mode === 'create' ? 'Crear Espacio' : 'Guardar Cambios' }}
        </span>
      </button>

      <button
        type="button"
        @click="handleCancel"
        :disabled="isSubmitting"
        class="px-6 py-3 border border-gray-300 rounded-lg font-medium text-gray-700 hover:bg-gray-50 transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-gray-500 disabled:opacity-50 disabled:cursor-not-allowed"
      >
        Cancelar
      </button>
    </div>
  </form>
</template>

<script setup lang="ts">
import type { Space } from '~/types/space'
import ImageUploader from './ImageUploader.vue'

interface Props {
  space?: Space
  mode: 'create' | 'edit'
}

interface Emits {
  (e: 'submit', data: any): void
  (e: 'cancel'): void
}

const props = defineProps<Props>()
const emit = defineEmits<Emits>()

const isSubmitting = ref(false)
const generalError = ref('')
const images = ref<any[]>([])
const existingImages = ref<Array<{ url: string; publicId: string }>>([])

// Formulario
const form = reactive({
  name: '',
  description: '',
  capacity: 1,
  isActive: true
})

// Errores de validación
const errors = reactive({
  name: '',
  capacity: ''
})

// Cargar datos existentes en modo edición
if (props.mode === 'edit' && props.space) {
  form.name = props.space.name || ''
  form.description = props.space.description || ''
  form.capacity = props.space.capacity || 1
  form.isActive = props.space.isActive ?? true

  if (props.space.images && Array.isArray(props.space.images)) {
    // @ts-ignore - Tipo de imagen puede ser string o objeto según backend
    existingImages.value = props.space.images
  }
}

// Validar formulario
const validateForm = (): boolean => {
  let isValid = true
  errors.name = ''
  errors.capacity = ''
  generalError.value = ''

  // Validar nombre
  if (!form.name.trim()) {
    errors.name = 'El nombre es requerido'
    isValid = false
  } else if (form.name.length < 3) {
    errors.name = 'El nombre debe tener al menos 3 caracteres'
    isValid = false
  } else if (form.name.length > 120) {
    errors.name = 'El nombre no puede exceder 120 caracteres'
    isValid = false
  }

  // Validar capacidad
  if (!form.capacity || form.capacity < 1) {
    errors.capacity = 'La capacidad debe ser al menos 1'
    isValid = false
  } else if (form.capacity > 10000) {
    errors.capacity = 'La capacidad no puede exceder 10,000'
    isValid = false
  }

  return isValid
}

// Enviar formulario
const handleSubmit = async () => {
  if (!validateForm()) {
    generalError.value = 'Por favor corrige los errores antes de continuar'
    return
  }

  isSubmitting.value = true
  generalError.value = ''

  try {
    // Preparar datos
    const data: any = {
      name: form.name.trim(),
      description: form.description.trim(),
      capacity: form.capacity
    }

    // Agregar isActive solo en modo edición
    if (props.mode === 'edit') {
      data.isActive = form.isActive
    }

    // Procesar imágenes
    if (images.value.length > 0) {
      data.images = images.value.map((img) => img.base64).filter(Boolean)
    } else if (props.mode === 'edit' && existingImages.value.length > 0) {
      // Mantener imágenes existentes si no se agregaron nuevas
      data.images = existingImages.value
    }

    emit('submit', data)
  } catch (error: any) {
    generalError.value = error.message || 'Error al procesar el formulario'
    isSubmitting.value = false
  }
}

const handleCancel = () => {
  emit('cancel')
}

// Exponer método para resetear el estado de envío (útil si el padre maneja el error)
defineExpose({
  stopSubmitting: () => {
    isSubmitting.value = false
  },
  setError: (message: string) => {
    generalError.value = message
    isSubmitting.value = false
  }
})
</script>
