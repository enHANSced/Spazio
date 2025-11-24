<template>
  <div class="space-y-4">
    <!-- Zona de drag & drop -->
    <div
      @drop.prevent="handleDrop"
      @dragover.prevent="isDragging = true"
      @dragleave.prevent="isDragging = false"
      :class="[
        'border-2 border-dashed rounded-lg p-8 text-center transition-colors',
        isDragging
          ? 'border-blue-500 bg-blue-50'
          : 'border-gray-300 hover:border-gray-400'
      ]"
    >
      <div class="flex flex-col items-center space-y-3">
        <svg
          class="w-12 h-12 text-gray-400"
          fill="none"
          stroke="currentColor"
          viewBox="0 0 24 24"
        >
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="2"
            d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12"
          />
        </svg>
        <div>
          <label
            for="file-upload"
            class="cursor-pointer text-blue-600 hover:text-blue-700 font-medium"
          >
            Subir imágenes
          </label>
          <span class="text-gray-600"> o arrastra y suelta</span>
        </div>
        <p class="text-sm text-gray-500">
          PNG, JPG, WEBP hasta {{ maxSizeMB }}MB cada una
        </p>
        <input
          id="file-upload"
          ref="fileInput"
          type="file"
          multiple
          accept="image/png,image/jpeg,image/jpg,image/webp"
          @change="handleFileSelect"
          class="hidden"
        />
      </div>
    </div>

    <!-- Preview de imágenes -->
    <div v-if="previewImages.length > 0" class="grid grid-cols-2 md:grid-cols-3 gap-4">
      <div
        v-for="(image, index) in previewImages"
        :key="index"
        class="relative group aspect-video rounded-lg overflow-hidden bg-gray-100 border border-gray-200"
      >
        <img
          :src="image.preview"
          :alt="`Preview ${index + 1}`"
          class="w-full h-full object-cover"
        />
        <div
          class="absolute inset-0 bg-black bg-opacity-0 group-hover:bg-opacity-40 transition-all flex items-center justify-center"
        >
          <button
            @click="removeImage(index)"
            type="button"
            class="opacity-0 group-hover:opacity-100 transition-opacity bg-red-600 text-white rounded-full p-2 hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-red-500 focus:ring-offset-2"
          >
            <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
              <path
                fill-rule="evenodd"
                d="M9 2a1 1 0 00-.894.553L7.382 4H4a1 1 0 000 2v10a2 2 0 002 2h8a2 2 0 002-2V6a1 1 0 100-2h-3.382l-.724-1.447A1 1 0 0011 2H9zM7 8a1 1 0 012 0v6a1 1 0 11-2 0V8zm5-1a1 1 0 00-1 1v6a1 1 0 102 0V8a1 1 0 00-1-1z"
                clip-rule="evenodd"
              />
            </svg>
          </button>
        </div>
        <div
          v-if="image.size"
          class="absolute bottom-2 right-2 bg-black bg-opacity-60 text-white text-xs px-2 py-1 rounded"
        >
          {{ formatFileSize(image.size) }}
        </div>
      </div>
    </div>

    <!-- Errores -->
    <div v-if="errors.length > 0" class="space-y-2">
      <div
        v-for="(error, index) in errors"
        :key="index"
        class="bg-red-50 border border-red-200 text-red-800 px-4 py-3 rounded-lg text-sm flex items-start gap-2"
      >
        <svg class="w-5 h-5 flex-shrink-0 mt-0.5" fill="currentColor" viewBox="0 0 20 20">
          <path
            fill-rule="evenodd"
            d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z"
            clip-rule="evenodd"
          />
        </svg>
        <span>{{ error }}</span>
      </div>
    </div>

    <!-- Info adicional -->
    <p v-if="maxFiles" class="text-sm text-gray-600">
      Máximo {{ maxFiles }} imágenes. Actualmente: {{ previewImages.length }}/{{ maxFiles }}
    </p>
  </div>
</template>

<script setup lang="ts">
interface ImagePreview {
  preview: string
  file?: File
  size?: number
  base64?: string
}

interface Props {
  modelValue?: ImagePreview[]
  maxFiles?: number
  maxSizeMB?: number
  existingImages?: Array<{ url: string; publicId: string }>
}

interface Emits {
  (e: 'update:modelValue', value: ImagePreview[]): void
}

const props = withDefaults(defineProps<Props>(), {
  modelValue: () => [],
  maxFiles: 5,
  maxSizeMB: 5
})

const emit = defineEmits<Emits>()

const isDragging = ref(false)
const fileInput = ref<HTMLInputElement>()
const errors = ref<string[]>([])
const previewImages = ref<ImagePreview[]>([...props.modelValue])

// Cargar imágenes existentes si las hay
watch(
  () => props.existingImages,
  (newImages) => {
    if (newImages && newImages.length > 0) {
      previewImages.value = newImages.map((img) => ({
        preview: img.url,
        base64: img.url
      }))
    }
  },
  { immediate: true }
)

const handleDrop = (e: DragEvent) => {
  isDragging.value = false
  const files = Array.from(e.dataTransfer?.files || [])
  processFiles(files)
}

const handleFileSelect = (e: Event) => {
  const target = e.target as HTMLInputElement
  const files = Array.from(target.files || [])
  processFiles(files)
  // Limpiar input para permitir seleccionar el mismo archivo de nuevo
  if (fileInput.value) {
    fileInput.value.value = ''
  }
}

const processFiles = async (files: File[]) => {
  errors.value = []

  // Validar cantidad
  if (props.maxFiles && previewImages.value.length + files.length > props.maxFiles) {
    errors.value.push(`Máximo ${props.maxFiles} imágenes permitidas`)
    return
  }

  // Validar y procesar cada archivo
  for (const file of files) {
    // Validar tipo
    if (!file.type.match(/^image\/(png|jpeg|jpg|webp)$/)) {
      errors.value.push(`${file.name}: Formato no válido. Solo PNG, JPG, WEBP`)
      continue
    }

    // Validar tamaño
    const fileSizeMB = file.size / (1024 * 1024)
    if (fileSizeMB > props.maxSizeMB) {
      errors.value.push(
        `${file.name}: Tamaño ${fileSizeMB.toFixed(2)}MB excede el límite de ${props.maxSizeMB}MB`
      )
      continue
    }

    // Convertir a base64
    try {
      const base64 = await fileToBase64(file)
      previewImages.value.push({
        preview: base64,
        file,
        size: file.size,
        base64
      })
    } catch (error) {
      errors.value.push(`${file.name}: Error al procesar imagen`)
    }
  }

  // Emitir cambios
  emit('update:modelValue', previewImages.value)
}

const fileToBase64 = (file: File): Promise<string> => {
  return new Promise((resolve, reject) => {
    const reader = new FileReader()
    reader.readAsDataURL(file)
    reader.onload = () => resolve(reader.result as string)
    reader.onerror = (error) => reject(error)
  })
}

const removeImage = (index: number) => {
  previewImages.value.splice(index, 1)
  emit('update:modelValue', previewImages.value)
}

const formatFileSize = (bytes: number): string => {
  if (bytes < 1024) return `${bytes} B`
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`
  return `${(bytes / (1024 * 1024)).toFixed(2)} MB`
}

// Exponer método para limpiar desde el padre
defineExpose({
  clear: () => {
    previewImages.value = []
    errors.value = []
    emit('update:modelValue', [])
  }
})
</script>
