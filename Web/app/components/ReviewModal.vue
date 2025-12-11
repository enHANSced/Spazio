<script setup lang="ts">
import reviewsService from '~/services/reviews.service'

interface Props {
  isOpen: boolean
  bookingId: string
  spaceName: string
}

const props = defineProps<Props>()

const emit = defineEmits<{
  close: []
  submitted: []
}>()

// Estado
const rating = ref(0)
const hoverRating = ref(0)
const comment = ref('')
const isSubmitting = ref(false)
const error = ref<string | null>(null)

// Mensajes según la calificación
const ratingMessages: Record<number, string> = {
  1: '😞 Muy mala experiencia',
  2: '😕 Podría mejorar',
  3: '😐 Experiencia regular',
  4: '😊 Buena experiencia',
  5: '🤩 ¡Excelente experiencia!'
}

const currentMessage = computed(() => {
  const r = hoverRating.value || rating.value
  return r ? ratingMessages[r] : 'Selecciona una calificación'
})

// Validación
const canSubmit = computed(() => rating.value >= 1 && rating.value <= 5)

// Enviar reseña
const submitReview = async () => {
  if (!canSubmit.value) {
    error.value = 'Por favor selecciona una calificación'
    return
  }

  isSubmitting.value = true
  error.value = null

  try {
    await reviewsService.create({
      bookingId: props.bookingId,
      rating: rating.value,
      comment: comment.value.trim() || undefined
    })

    emit('submitted')
    closeModal()
  } catch (err) {
    error.value = err instanceof Error ? err.message : 'Error al enviar la reseña'
  } finally {
    isSubmitting.value = false
  }
}

// Cerrar modal
const closeModal = () => {
  rating.value = 0
  hoverRating.value = 0
  comment.value = ''
  error.value = null
  emit('close')
}

// Cerrar con Escape
const handleKeydown = (e: KeyboardEvent) => {
  if (e.key === 'Escape') closeModal()
}

onMounted(() => {
  window.addEventListener('keydown', handleKeydown)
})

onUnmounted(() => {
  window.removeEventListener('keydown', handleKeydown)
})
</script>

<template>
  <Teleport to="body">
    <Transition name="modal">
      <div
        v-if="isOpen"
        class="fixed inset-0 z-50 flex items-center justify-center p-4"
        @click.self="closeModal"
      >
        <!-- Overlay -->
        <div class="absolute inset-0 bg-black/50 backdrop-blur-sm" />
        
        <!-- Modal -->
        <div class="relative w-full max-w-md bg-white rounded-2xl shadow-2xl transform">
          <!-- Header -->
          <div class="p-6 border-b border-gray-100">
            <div class="flex items-center justify-between">
              <h3 class="text-xl font-bold text-gray-900 flex items-center gap-2">
                <span class="material-symbols-outlined text-primary">rate_review</span>
                Califica tu experiencia
              </h3>
              <button
                type="button"
                class="p-2 hover:bg-gray-100 rounded-lg transition"
                @click="closeModal"
              >
                <span class="material-symbols-outlined text-gray-500">close</span>
              </button>
            </div>
            <p class="text-sm text-gray-500 mt-1">
              {{ spaceName }}
            </p>
          </div>

          <!-- Content -->
          <div class="p-6 space-y-5">
            <!-- Estrellas -->
            <div class="text-center">
              <div class="flex items-center justify-center gap-2 mb-2">
                <button
                  v-for="star in 5"
                  :key="star"
                  type="button"
                  class="p-1 transition-transform hover:scale-110 focus:outline-none"
                  @click="rating = star"
                  @mouseenter="hoverRating = star"
                  @mouseleave="hoverRating = 0"
                >
                  <span
                    class="material-symbols-outlined !text-4xl transition-colors duration-150"
                    :class="(hoverRating || rating) >= star ? 'text-amber-500' : 'text-gray-300'"
                    style="font-variation-settings: 'FILL' 1;"
                  >star</span>
                </button>
              </div>
              <p class="text-sm font-medium" :class="rating ? 'text-gray-700' : 'text-gray-400'">
                {{ currentMessage }}
              </p>
            </div>

            <!-- Comentario -->
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-2">
                Cuéntanos más (opcional)
              </label>
              <textarea
                v-model="comment"
                rows="4"
                maxlength="1000"
                placeholder="¿Cómo fue tu experiencia con este espacio?"
                class="w-full rounded-xl border-2 border-gray-200 px-4 py-3 text-sm focus:border-primary focus:ring-2 focus:ring-primary/20 transition resize-none"
              />
              <p class="text-xs text-gray-400 text-right mt-1">
                {{ comment.length }}/1000
              </p>
            </div>

            <!-- Error -->
            <div v-if="error" class="bg-red-50 text-red-700 p-3 rounded-lg text-sm flex items-center gap-2">
              <span class="material-symbols-outlined !text-lg">error</span>
              {{ error }}
            </div>
          </div>

          <!-- Footer -->
          <div class="p-6 border-t border-gray-100 bg-gray-50 rounded-b-2xl">
            <div class="flex gap-3">
              <button
                type="button"
                class="flex-1 py-3 px-4 rounded-xl border-2 border-gray-300 text-gray-700 font-medium hover:bg-gray-100 transition"
                :disabled="isSubmitting"
                @click="closeModal"
              >
                Cancelar
              </button>
              <button
                type="button"
                class="flex-1 py-3 px-4 rounded-xl bg-primary text-white font-bold hover:bg-primary-dark transition disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2"
                :disabled="!canSubmit || isSubmitting"
                @click="submitReview"
              >
                <span v-if="isSubmitting" class="animate-spin material-symbols-outlined !text-lg">
                  progress_activity
                </span>
                <span>{{ isSubmitting ? 'Enviando...' : 'Enviar reseña' }}</span>
              </button>
            </div>
          </div>
        </div>
      </div>
    </Transition>
  </Teleport>
</template>

<style scoped>
.modal-enter-active,
.modal-leave-active {
  transition: all 0.3s ease;
}

.modal-enter-from,
.modal-leave-to {
  opacity: 0;
}

.modal-enter-from .relative,
.modal-leave-to .relative {
  transform: scale(0.95) translateY(10px);
}
</style>
