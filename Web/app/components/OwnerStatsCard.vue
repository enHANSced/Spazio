<script setup lang="ts">
import type { OwnerStats, Review, Pagination } from '~/types/review'
import reviewsService from '~/services/reviews.service'

interface Props {
  ownerId: string
  ownerName?: string
}

const props = defineProps<Props>()

// Estado
const stats = ref<OwnerStats | null>(null)
const reviews = ref<Review[]>([])
const pagination = ref<Pagination | null>(null)
const loading = ref(true)
const loadingReviews = ref(false)
const error = ref<string | null>(null)
const showAllReviews = ref(false)

// Cargar estadísticas del propietario
const loadOwnerStats = async () => {
  try {
    stats.value = await reviewsService.getOwnerStats(props.ownerId)
  } catch (err) {
    console.error('Error loading owner stats:', err)
    error.value = 'No se pudieron cargar las estadísticas'
  }
}

// Cargar reseñas del propietario
const loadOwnerReviews = async (page = 1, limit = 3) => {
  loadingReviews.value = true
  try {
    const result = await reviewsService.getOwnerReviews(props.ownerId, { page, limit })
    reviews.value = result.reviews
    pagination.value = result.pagination
  } catch (err) {
    console.error('Error loading owner reviews:', err)
  } finally {
    loadingReviews.value = false
  }
}

// Cargar más reseñas
const loadMoreReviews = async () => {
  if (!pagination.value || pagination.value.page >= pagination.value.totalPages) return
  
  loadingReviews.value = true
  try {
    const result = await reviewsService.getOwnerReviews(props.ownerId, { 
      page: pagination.value.page + 1, 
      limit: 5 
    })
    reviews.value = [...reviews.value, ...result.reviews]
    pagination.value = result.pagination
  } catch (err) {
    console.error('Error loading more reviews:', err)
  } finally {
    loadingReviews.value = false
  }
}

// Formatear fecha
const formatDate = (dateString: string) => {
  const date = new Date(dateString)
  return date.toLocaleDateString('es-ES', { 
    year: 'numeric', 
    month: 'long', 
    day: 'numeric' 
  })
}

// Formatear fecha de "miembro desde"
const formatMemberSince = (dateString: string) => {
  const date = new Date(dateString)
  const now = new Date()
  const months = (now.getFullYear() - date.getFullYear()) * 12 + (now.getMonth() - date.getMonth())
  
  if (months < 1) return 'Este mes'
  if (months === 1) return 'Hace 1 mes'
  if (months < 12) return `Hace ${months} meses`
  
  const years = Math.floor(months / 12)
  if (years === 1) return 'Hace 1 año'
  return `Hace ${years} años`
}

// Calcular porcentaje para la barra de distribución
const getRatingPercentage = (count: number) => {
  if (!stats.value?.stats.totalReviews) return 0
  return Math.round((count / stats.value.stats.totalReviews) * 100)
}

// Inicializar
onMounted(async () => {
  loading.value = true
  await Promise.all([
    loadOwnerStats(),
    loadOwnerReviews()
  ])
  loading.value = false
})

// Computed
const hasReviews = computed(() => stats.value && stats.value.stats.totalReviews > 0)
const hasMoreReviews = computed(() => pagination.value && pagination.value.page < pagination.value.totalPages)
</script>

<template>
  <div class="space-y-6">
    <!-- Skeleton Loading -->
    <div v-if="loading" class="animate-pulse space-y-4">
      <div class="h-24 bg-gray-200 rounded-xl" />
      <div class="grid grid-cols-2 gap-3">
        <div class="h-16 bg-gray-200 rounded-lg" />
        <div class="h-16 bg-gray-200 rounded-lg" />
      </div>
    </div>

    <!-- Estadísticas -->
    <div v-else-if="stats" class="space-y-5">
      <!-- Calificación prominente -->
      <div v-if="hasReviews" class="bg-gradient-to-br from-amber-50 to-orange-50 rounded-xl p-5 border border-amber-200/50">
        <div class="flex items-center gap-4">
          <!-- Rating grande -->
          <div class="flex items-center gap-2">
            <span class="text-4xl font-black text-amber-600">{{ stats.stats.averageRating.toFixed(1) }}</span>
            <span class="material-symbols-outlined text-amber-500 !text-4xl" style="font-variation-settings: 'FILL' 1;">star</span>
          </div>
          
          <!-- Estrellas visuales -->
          <div class="flex-1">
            <div class="flex items-center gap-1 mb-1">
              <template v-for="i in 5" :key="i">
                <span 
                  class="material-symbols-outlined !text-xl"
                  :class="i <= Math.round(stats.stats.averageRating) ? 'text-amber-500' : 'text-gray-300'"
                  style="font-variation-settings: 'FILL' 1;"
                >star</span>
              </template>
            </div>
            <p class="text-sm text-gray-600">
              {{ stats.stats.totalReviews }} {{ stats.stats.totalReviews === 1 ? 'reseña' : 'reseñas' }}
            </p>
          </div>
        </div>

        <!-- Distribución de calificaciones -->
        <div v-if="stats.stats.totalReviews > 2" class="mt-4 space-y-1.5">
          <div v-for="star in [5, 4, 3, 2, 1]" :key="star" class="flex items-center gap-2 text-sm">
            <span class="w-3 text-gray-600">{{ star }}</span>
            <span class="material-symbols-outlined !text-sm text-amber-500" style="font-variation-settings: 'FILL' 1;">star</span>
            <div class="flex-1 h-2 bg-gray-200 rounded-full overflow-hidden">
              <div 
                class="h-full bg-amber-500 rounded-full transition-all duration-500"
                :style="{ width: `${getRatingPercentage(stats.stats.ratingDistribution[star.toString() as keyof typeof stats.stats.ratingDistribution])}%` }"
              />
            </div>
            <span class="w-8 text-right text-gray-500 text-xs">
              {{ stats.stats.ratingDistribution[star.toString() as keyof typeof stats.stats.ratingDistribution] }}
            </span>
          </div>
        </div>
      </div>

      <!-- Si no hay reseñas -->
      <div v-else class="bg-gray-50 rounded-xl p-5 border border-gray-200">
        <div class="flex items-center gap-3 text-gray-500">
          <span class="material-symbols-outlined text-2xl">rate_review</span>
          <div>
            <p class="font-medium">Sin reseñas aún</p>
            <p class="text-sm">Sé el primero en dejar una reseña</p>
          </div>
        </div>
      </div>

      <!-- Stats cards -->
      <div class="grid grid-cols-2 gap-3">
        <div class="bg-gray-50 rounded-lg p-4 text-center border border-gray-100">
          <span class="material-symbols-outlined text-primary text-2xl mb-1">apartment</span>
          <p class="text-2xl font-bold text-gray-900">{{ stats.stats.spacesCount }}</p>
          <p class="text-xs text-gray-500">{{ stats.stats.spacesCount === 1 ? 'Espacio' : 'Espacios' }}</p>
        </div>
        <div class="bg-gray-50 rounded-lg p-4 text-center border border-gray-100">
          <span class="material-symbols-outlined text-green-600 text-2xl mb-1">check_circle</span>
          <p class="text-2xl font-bold text-gray-900">{{ stats.stats.completedBookings }}</p>
          <p class="text-xs text-gray-500">Reservas completadas</p>
        </div>
      </div>

      <!-- Info del propietario -->
      <div class="flex items-center gap-2 text-sm text-gray-500 pt-2 border-t border-gray-100">
        <span class="material-symbols-outlined !text-sm">schedule</span>
        <span>Miembro {{ formatMemberSince(stats.owner.memberSince) }}</span>
      </div>

      <!-- Reseñas -->
      <div v-if="hasReviews && reviews.length > 0" class="pt-4 border-t border-gray-200">
        <div class="flex items-center justify-between mb-4">
          <h3 class="font-bold text-gray-900 flex items-center gap-2">
            <span class="material-symbols-outlined text-primary !text-xl">reviews</span>
            Reseñas recientes
          </h3>
          <button 
            v-if="stats.stats.totalReviews > 3"
            type="button"
            class="text-sm text-primary font-medium hover:underline"
            @click="showAllReviews = !showAllReviews"
          >
            {{ showAllReviews ? 'Ver menos' : `Ver todas (${stats.stats.totalReviews})` }}
          </button>
        </div>

        <div class="space-y-4">
          <div 
            v-for="review in (showAllReviews ? reviews : reviews.slice(0, 3))" 
            :key="review._id"
            class="bg-gray-50 rounded-xl p-4 border border-gray-100"
          >
            <!-- Header de la reseña -->
            <div class="flex items-start justify-between mb-2">
              <div class="flex items-center gap-2">
                <div class="w-8 h-8 rounded-full bg-primary/10 flex items-center justify-center">
                  <span class="text-sm font-bold text-primary">
                    {{ review.user?.name?.charAt(0).toUpperCase() || 'U' }}
                  </span>
                </div>
                <div>
                  <p class="font-medium text-gray-900 text-sm">{{ review.user?.name || 'Usuario' }}</p>
                  <p class="text-xs text-gray-500">{{ formatDate(review.createdAt) }}</p>
                </div>
              </div>
              <div class="flex items-center gap-0.5">
                <template v-for="i in 5" :key="i">
                  <span 
                    class="material-symbols-outlined !text-sm"
                    :class="i <= review.rating ? 'text-amber-500' : 'text-gray-300'"
                    style="font-variation-settings: 'FILL' 1;"
                  >star</span>
                </template>
              </div>
            </div>

            <!-- Espacio relacionado -->
            <p v-if="review.space" class="text-xs text-gray-400 mb-2 flex items-center gap-1">
              <span class="material-symbols-outlined !text-xs">location_on</span>
              {{ review.space.name }}
            </p>

            <!-- Comentario -->
            <p v-if="review.comment" class="text-sm text-gray-700 leading-relaxed">
              {{ review.comment }}
            </p>

            <!-- Respuesta del propietario -->
            <div v-if="review.ownerResponse?.text" class="mt-3 pl-3 border-l-2 border-primary/30 bg-primary/5 rounded-r-lg p-2">
              <p class="text-xs font-medium text-primary mb-1 flex items-center gap-1">
                <span class="material-symbols-outlined !text-xs">reply</span>
                Respuesta del propietario
              </p>
              <p class="text-sm text-gray-600">{{ review.ownerResponse.text }}</p>
            </div>
          </div>
        </div>

        <!-- Cargar más -->
        <button
          v-if="showAllReviews && hasMoreReviews"
          type="button"
          class="w-full mt-4 py-2 text-sm text-primary font-medium hover:bg-primary/5 rounded-lg transition"
          :disabled="loadingReviews"
          @click="loadMoreReviews"
        >
          <span v-if="loadingReviews" class="flex items-center justify-center gap-2">
            <span class="animate-spin material-symbols-outlined !text-sm">progress_activity</span>
            Cargando...
          </span>
          <span v-else>Cargar más reseñas</span>
        </button>
      </div>
    </div>

    <!-- Error -->
    <div v-else-if="error" class="text-center py-4 text-gray-500">
      <span class="material-symbols-outlined text-2xl">error_outline</span>
      <p class="mt-1 text-sm">{{ error }}</p>
    </div>
  </div>
</template>
