<template>
  <div class="max-w-4xl mx-auto">
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
        <p class="mt-4 text-gray-600">Cargando espacio...</p>
      </div>
    </div>

    <!-- Error -->
    <div v-else-if="error" class="text-center py-12">
      <div class="bg-red-50 border border-red-200 rounded-lg p-6 max-w-md mx-auto">
        <svg
          class="w-12 h-12 text-red-600 mx-auto mb-4"
          fill="none"
          stroke="currentColor"
          viewBox="0 0 24 24"
        >
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="2"
            d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"
          />
        </svg>
        <h3 class="text-lg font-semibold text-red-900 mb-2">Error al cargar el espacio</h3>
        <p class="text-red-700 mb-4">{{ error }}</p>
        <button
          @click="router.push('/owner/spaces')"
          class="px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors"
        >
          Volver a Mis Espacios
        </button>
      </div>
    </div>

    <!-- Formulario -->
    <div v-else>
      <!-- Header -->
      <div class="mb-8">
        <button
          @click="router.back()"
          class="flex items-center gap-2 text-gray-600 hover:text-gray-900 mb-4 transition-colors"
        >
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M15 19l-7-7 7-7"
            />
          </svg>
          Volver
        </button>

        <h1 class="text-3xl font-bold text-gray-900">Editar Espacio</h1>
        <p class="mt-2 text-gray-600">
          Actualiza la información de tu espacio
        </p>
      </div>

      <!-- Formulario -->
      <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-8">
        <OwnerSpaceForm
          v-if="space"
          mode="edit"
          :space="space"
          @submit="handleSubmit"
          @cancel="handleCancel"
          ref="formRef"
        />
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ownerSpacesService } from '~/services/owner-spaces.service'
import type { Space } from '~/types/space'

definePageMeta({
  layout: 'owner',
  middleware: ['auth', 'verified-owner']
})

const router = useRouter()
const route = useRoute()
const toast = useToast()

const loading = ref(true)
const error = ref('')
const space = ref<Space | null>(null)
const formRef = ref<any>(null)

// Cargar espacio
const loadSpace = async () => {
  try {
    loading.value = true
    error.value = ''

    const spaceId = route.params.id as string

    // Obtener todos los espacios del owner y filtrar por ID
    const response = await ownerSpacesService.getMySpaces()

    if (response.success && response.data) {
      const foundSpace = response.data.find((s: Space) => s.id === spaceId)

      if (foundSpace) {
        space.value = foundSpace
      } else {
        error.value = 'Espacio no encontrado o no tienes permisos para editarlo'
      }
    } else {
      error.value = response.message || 'Error al cargar el espacio'
    }
  } catch (err: any) {
    console.error('Error loading space:', err)
    error.value = err.data?.message || err.message || 'Error al cargar el espacio'
  } finally {
    loading.value = false
  }
}

// Enviar cambios
const handleSubmit = async (data: any) => {
  if (!space.value) return

  try {
    const response = await ownerSpacesService.updateSpace(space.value.id, data)

    if (response.success) {
      toast.success('¡Espacio actualizado exitosamente!')
      
      // Redirigir a la lista de espacios
      await router.push('/owner/spaces')
    } else {
      formRef.value?.setError(response.message || 'Error al actualizar el espacio')
      toast.error(response.message || 'Error al actualizar el espacio')
    }
  } catch (error: any) {
    console.error('Error updating space:', error)
    const errorMessage = error.data?.message || error.message || 'Error al actualizar el espacio'
    formRef.value?.setError(errorMessage)
    toast.error(errorMessage)
  }
}

const handleCancel = () => {
  router.back()
}

// Cargar al montar
onMounted(() => {
  loadSpace()
})
</script>
