<template>
  <div class="space-y-6">
    <!-- Progress Bar -->
    <div class="mb-8">
      <div class="flex items-center justify-between mb-2">
        <span v-for="(step, index) in steps" :key="index" 
          class="text-sm font-medium"
          :class="index <= currentStep ? 'text-blue-600' : 'text-gray-400'"
        >
          {{ step.title }}
        </span>
      </div>
      <div class="h-2 bg-gray-200 rounded-full overflow-hidden">
        <div 
          class="h-full bg-blue-600 transition-all duration-300 ease-out"
          :style="{ width: `${((currentStep + 1) / steps.length) * 100}%` }"
        ></div>
      </div>
    </div>

    <form @submit.prevent="handleSubmit" class="space-y-6">
      <!-- Step 1: Información Básica -->
      <div v-show="currentStep === 0" class="space-y-6 animate-fadeIn">
        <h2 class="text-xl font-semibold text-gray-800">Información Básica</h2>
        
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

        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
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

          <!-- Precio por hora -->
          <div>
            <label for="pricePerHour" class="block text-sm font-medium text-gray-700 mb-2">
              Precio por hora (HNL) <span class="text-red-500">*</span>
            </label>
            <div class="relative">
              <span class="absolute left-3 top-2.5 text-gray-500">L</span>
              <input
                id="pricePerHour"
                v-model.number="form.pricePerHour"
                type="number"
                required
                min="0"
                step="0.01"
                class="w-full pl-8 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors"
                placeholder="300.00"
              />
            </div>
            <p class="mt-1 text-sm text-gray-500">
              Precio sugerido: <strong>L {{ suggestedPrice }}</strong> por hora (basado en capacidad)
            </p>
          </div>
        </div>
      </div>

      <!-- Step 2: Ubicación -->
      <div v-show="currentStep === 1" class="space-y-6 animate-fadeIn">
        <h2 class="text-xl font-semibold text-gray-800">Ubicación</h2>
        
        <div class="bg-gray-50 p-6 rounded-xl border border-gray-200">
          <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div class="md:col-span-2">
              <label for="address" class="block text-sm font-medium text-gray-700 mb-2">
                Dirección completa <span class="text-red-500">*</span>
              </label>
              <input
                id="address"
                v-model="form.address"
                type="text"
                required
                maxlength="255"
                class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors"
                placeholder="Ej: Boulevard Morazán, Edificio Plaza Azul, 3er piso"
              />
            </div>

            <div>
              <label for="city" class="block text-sm font-medium text-gray-700 mb-2">
                Ciudad <span class="text-red-500">*</span>
              </label>
              <input
                id="city"
                v-model="form.city"
                type="text"
                required
                maxlength="100"
                class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors"
                placeholder="Ej: Tegucigalpa"
              />
            </div>

            <div>
              <label for="state" class="block text-sm font-medium text-gray-700 mb-2">
                Departamento <span class="text-red-500">*</span>
              </label>
              <input
                id="state"
                v-model="form.state"
                type="text"
                required
                maxlength="100"
                class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors"
                placeholder="Ej: Francisco Morazán"
              />
            </div>
            
            <div>
              <label for="country" class="block text-sm font-medium text-gray-700 mb-2">
                País
              </label>
              <input
                id="country"
                v-model="form.country"
                type="text"
                readonly
                class="w-full px-4 py-2 border border-gray-300 rounded-lg bg-gray-100 text-gray-500 cursor-not-allowed"
              />
            </div>


          </div>
        </div>
      </div>

      <!-- Step 3: Detalles y Reglas -->
      <div v-show="currentStep === 2" class="space-y-6 animate-fadeIn">
        <h2 class="text-xl font-semibold text-gray-800">Detalles y Reglas</h2>

        <!-- Amenidades -->
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-3">
            Amenidades disponibles
          </label>
          <div class="grid grid-cols-2 md:grid-cols-3 gap-3">
            <label
              v-for="amenity in availableAmenities"
              :key="amenity"
              class="flex items-center gap-3 p-3 border rounded-lg cursor-pointer hover:bg-blue-50 hover:border-blue-200 transition-all duration-200"
              :class="form.amenities.includes(amenity) ? 'bg-blue-50 border-blue-500 ring-1 ring-blue-500' : 'border-gray-300'"
            >
              <input
                v-model="form.amenities"
                type="checkbox"
                :value="amenity"
                class="w-4 h-4 text-blue-600 border-gray-300 rounded focus:ring-blue-500"
              />
              <span class="text-sm text-gray-700">{{ amenity }}</span>
            </label>
          </div>
        </div>

        <!-- Horarios de operación -->
        <div class="p-6 bg-gray-50 rounded-xl border border-gray-200">
          <h3 class="text-sm font-semibold text-gray-700 mb-4">🕐 Horarios de operación</h3>
          
          <div class="grid grid-cols-2 gap-6">
            <div>
              <label for="workingHoursStart" class="block text-sm font-medium text-gray-700 mb-2">
                Apertura
              </label>
              <input
                id="workingHoursStart"
                v-model="form.workingHours.start"
                type="time"
                class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors"
              />
            </div>

            <div>
              <label for="workingHoursEnd" class="block text-sm font-medium text-gray-700 mb-2">
                Cierre
              </label>
              <input
                id="workingHoursEnd"
                v-model="form.workingHours.end"
                type="time"
                class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors"
              />
            </div>
          </div>
        </div>

        <!-- Reglas del espacio -->
        <div>
          <label for="rules" class="block text-sm font-medium text-gray-700 mb-2">
            Reglas del espacio
          </label>
          <textarea
            id="rules"
            v-model="form.rules"
            rows="3"
            maxlength="2000"
            class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors resize-none"
            placeholder="Ej: No fumar, No se permiten mascotas, Respetar el horario..."
          />
          <p class="mt-1 text-sm text-gray-500">{{ form.rules.length }}/2000 caracteres</p>
        </div>

        <!-- Política de cancelación -->
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-2">
            Política de cancelación
          </label>
          <select
            v-model="form.cancellationPolicy"
            class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors"
          >
            <option value="flexible">Flexible - Reembolso hasta 24h antes</option>
            <option value="moderate">Moderada - Reembolso hasta 5 días antes</option>
            <option value="strict">Estricta - Reembolso hasta 7 días antes</option>
          </select>
        </div>
      </div>

      <!-- Step 4: Imágenes y Revisión -->
      <div v-show="currentStep === 3" class="space-y-6 animate-fadeIn">
        <h2 class="text-xl font-semibold text-gray-800">Imágenes y Revisión</h2>

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
            Agrega fotos de buena calidad para atraer más clientes. Máximo 5 imágenes.
          </p>
        </div>

        <!-- Estado (solo en modo edición) -->
        <div v-if="mode === 'edit'" class="flex items-center gap-3 p-4 bg-gray-50 rounded-lg border border-gray-200">
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
      </div>

      <!-- Errores generales -->
      <div
        v-if="generalError"
        class="bg-red-50 border border-red-200 text-red-800 px-4 py-3 rounded-lg text-sm"
      >
        {{ generalError }}
      </div>

      <!-- Botones de Navegación -->
      <div class="flex justify-between pt-6 border-t border-gray-100">
        <button
          type="button"
          @click="prevStep"
          v-if="currentStep > 0"
          class="px-6 py-2.5 border border-gray-300 rounded-lg font-medium text-gray-700 hover:bg-gray-50 transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-gray-500"
        >
          Anterior
        </button>
        <button
          type="button"
          @click="handleCancel"
          v-else
          class="px-6 py-2.5 border border-gray-300 rounded-lg font-medium text-gray-700 hover:bg-gray-50 transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-gray-500"
        >
          Cancelar
        </button>

        <button
          type="button"
          @click="nextStep"
          v-if="currentStep < steps.length - 1"
          class="px-6 py-2.5 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
        >
          Siguiente
        </button>
        
        <button
          type="submit"
          v-else
          :disabled="isSubmitting"
          :class="[
            'px-6 py-2.5 rounded-lg font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2',
            isSubmitting
              ? 'bg-gray-400 cursor-not-allowed'
              : 'bg-green-600 hover:bg-green-700 focus:ring-green-500 text-white'
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
      </div>
    </form>
  </div>
</template>

<script setup lang="ts">
import type { Space } from '~/types/space'
import ImageUploader from './ImageUploader.vue'
import LocationMap from '~/components/LocationMap.vue'

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

// Wizard Steps
const currentStep = ref(0)
const steps = [
  { title: 'Información Básica' },
  { title: 'Ubicación' },
  { title: 'Detalles y Reglas' },
  { title: 'Imágenes' }
]

// Lista de amenidades disponibles
const availableAmenities = [
  'Wi-Fi',
  'Aire acondicionado',
  'Proyector',
  'Pizarra',
  'Sonido',
  'Estacionamiento',
  'Café/Bebidas',
  'Cocina',
  'Baños privados',
  'Acceso 24/7',
  'Seguridad',
  'Recepción'
]

// Formulario
const form = reactive({
  name: '',
  description: '',
  capacity: 1,
  pricePerHour: 0,
  address: '',
  city: '',
  state: '',
  country: 'Honduras',
  latitude: 0,
  longitude: 0,
  amenities: [] as string[],
  workingHours: {
    start: '08:00',
    end: '22:00'
  },
  rules: '',
  cancellationPolicy: 'flexible',
  isActive: true
})

// Errores de validación
const errors = reactive({
  name: '',
  capacity: '',
  address: '',
  city: '',
  state: ''
})

// Calcular precio sugerido basado en capacidad
const suggestedPrice = computed(() => {
  const capacity = form.capacity || 1
  if (capacity <= 10) return 300
  if (capacity <= 20) return 500
  if (capacity <= 40) return 800
  if (capacity <= 80) return 1500
  return 2500
})

// Auto-sugerir precio si no está establecido
watch(() => form.capacity, (newCapacity) => {
  if (!form.pricePerHour || form.pricePerHour === 0) {
    form.pricePerHour = suggestedPrice.value
  }
})

// Cargar datos existentes en modo edición
if (props.mode === 'edit' && props.space) {
  form.name = props.space.name || ''
  form.description = props.space.description || ''
  form.capacity = props.space.capacity || 1
  form.pricePerHour = props.space.pricePerHour || 0
  form.address = props.space.address || ''
  form.city = props.space.city || ''
  form.state = props.space.state || ''
  form.country = props.space.country || 'Honduras'
  form.latitude = props.space.latitude || 0
  form.longitude = props.space.longitude || 0
  form.amenities = props.space.amenities || []
  form.rules = props.space.rules || ''
  form.cancellationPolicy = props.space.cancellationPolicy || 'flexible'
  form.isActive = props.space.isActive ?? true

  if (props.space.workingHours) {
    form.workingHours = {
      start: props.space.workingHours.start || '08:00',
      end: props.space.workingHours.end || '22:00'
    }
  }

  if (props.space.images && Array.isArray(props.space.images)) {
    // @ts-ignore - Tipo de imagen puede ser string o objeto según backend
    existingImages.value = props.space.images
  }
}

// Validar paso actual
const validateStep = (step: number): boolean => {
  let isValid = true
  generalError.value = ''

  if (step === 0) {
    errors.name = ''
    errors.capacity = ''

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

    if (!form.capacity || form.capacity < 1) {
      errors.capacity = 'La capacidad debe ser al menos 1'
      isValid = false
    } else if (form.capacity > 10000) {
      errors.capacity = 'La capacidad no puede exceder 10,000'
      isValid = false
    }
  } else if (step === 1) {
    // Validar ubicación (aunque los campos tienen 'required' en HTML, validamos aquí también)
    if (!form.address.trim()) isValid = false
    if (!form.city.trim()) isValid = false
    if (!form.state.trim()) isValid = false
    
    if (!isValid) {
      generalError.value = 'Por favor completa todos los campos obligatorios de ubicación'
    }
  }

  return isValid
}

const nextStep = () => {
  if (validateStep(currentStep.value)) {
    currentStep.value++
    window.scrollTo({ top: 0, behavior: 'smooth' })
  }
}

const prevStep = () => {
  if (currentStep.value > 0) {
    currentStep.value--
    window.scrollTo({ top: 0, behavior: 'smooth' })
  }
}

// Enviar formulario
const handleSubmit = async () => {
  // Validar todos los pasos antes de enviar
  let allValid = true
  for (let i = 0; i < steps.length; i++) {
    if (!validateStep(i)) {
      allValid = false
      // Si hay error, ir a ese paso
      currentStep.value = i
      break
    }
  }

  if (!allValid) {
    generalError.value = 'Por favor revisa los pasos anteriores y corrige los errores'
    return
  }

  isSubmitting.value = true
  generalError.value = ''

  try {
    // Preparar datos
    const data: any = {
      name: form.name.trim(),
      description: form.description.trim(),
      capacity: form.capacity,
      pricePerHour: form.pricePerHour,
      address: form.address.trim(),
      city: form.city.trim(),
      state: form.state.trim(),
      country: form.country,
      latitude: form.latitude,
      longitude: form.longitude,
      amenities: form.amenities,
      workingHours: form.workingHours,
      rules: form.rules.trim(),
      cancellationPolicy: form.cancellationPolicy
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
