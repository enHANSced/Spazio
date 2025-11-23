<template>
  <div class="max-w-4xl mx-auto">
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

      <h1 class="text-3xl font-bold text-gray-900">Crear Nuevo Espacio</h1>
      <p class="mt-2 text-gray-600">
        Completa la información de tu espacio para que los usuarios puedan reservarlo
      </p>
    </div>

    <!-- Formulario -->
    <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-8">
      <OwnerSpaceForm mode="create" @submit="handleSubmit" @cancel="handleCancel" ref="formRef" />
    </div>
  </div>
</template>

<script setup lang="ts">
import { ownerSpacesService } from '~/services/owner-spaces.service'

definePageMeta({
  layout: 'owner',
  middleware: ['auth', 'verified-owner']
})

const router = useRouter()
const toast = useToast()
const formRef = ref<any>(null)

const handleSubmit = async (data: any) => {
  try {
    const response = await ownerSpacesService.createSpace(data)

    if (response.success) {
      toast.success('¡Espacio creado exitosamente!')
      
      // Redirigir a la lista de espacios
      await router.push('/owner/spaces')
    } else {
      formRef.value?.setError(response.message || 'Error al crear el espacio')
      toast.error(response.message || 'Error al crear el espacio')
    }
  } catch (error: any) {
    console.error('Error creating space:', error)
    const errorMessage = error.data?.message || error.message || 'Error al crear el espacio'
    formRef.value?.setError(errorMessage)
    toast.error(errorMessage)
  }
}

const handleCancel = () => {
  router.back()
}
</script>
