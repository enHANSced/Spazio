import type {
  Review,
  OwnerStats,
  SpaceStats,
  CanReviewResult,
  ReviewsApiResponse,
  ReviewApiResponse,
  OwnerStatsApiResponse,
  SpaceStatsApiResponse,
  CanReviewApiResponse,
  CreateReviewData,
  Pagination
} from '~/types/review'
import { buildApiUrl, extractApiErrorMessage } from '~/utils/http'

class ReviewsService {
  private getHeaders() {
    if (import.meta.client) {
      const tokenCookie = document.cookie
        .split('; ')
        .find(row => row.startsWith('spazio_token='))
      const token = tokenCookie ? tokenCookie.split('=')[1] : null

      return {
        'Content-Type': 'application/json',
        ...(token && { Authorization: `Bearer ${token}` })
      }
    }
    return {
      'Content-Type': 'application/json'
    }
  }

  /**
   * Obtener estadísticas de un propietario (público)
   */
  async getOwnerStats(ownerId: string): Promise<OwnerStats> {
    try {
      const response = await $fetch<OwnerStatsApiResponse>(
        buildApiUrl(`/reviews/owner/${ownerId}/stats`)
      )

      if (!response.success) {
        throw new Error(response.message || 'Error al obtener estadísticas del propietario')
      }

      return response.data
    } catch (error) {
      throw new Error(extractApiErrorMessage(error))
    }
  }

  /**
   * Obtener reseñas de un propietario (público)
   */
  async getOwnerReviews(
    ownerId: string, 
    options?: { page?: number; limit?: number }
  ): Promise<{ reviews: Review[]; pagination: Pagination }> {
    try {
      const params = new URLSearchParams()
      if (options?.page) params.append('page', options.page.toString())
      if (options?.limit) params.append('limit', options.limit.toString())

      const queryString = params.toString()
      const url = buildApiUrl(`/reviews/owner/${ownerId}${queryString ? `?${queryString}` : ''}`)

      const response = await $fetch<ReviewsApiResponse>(url)

      if (!response.success) {
        throw new Error(response.message || 'Error al obtener reseñas del propietario')
      }

      return {
        reviews: response.data,
        pagination: response.pagination
      }
    } catch (error) {
      throw new Error(extractApiErrorMessage(error))
    }
  }

  /**
   * Obtener estadísticas de un espacio (público)
   */
  async getSpaceStats(spaceId: string): Promise<SpaceStats> {
    try {
      const response = await $fetch<SpaceStatsApiResponse>(
        buildApiUrl(`/reviews/space/${spaceId}/stats`)
      )

      if (!response.success) {
        throw new Error(response.message || 'Error al obtener estadísticas del espacio')
      }

      return response.data
    } catch (error) {
      throw new Error(extractApiErrorMessage(error))
    }
  }

  /**
   * Obtener reseñas de un espacio (público)
   */
  async getSpaceReviews(
    spaceId: string,
    options?: { page?: number; limit?: number }
  ): Promise<{ reviews: Review[]; pagination: Pagination }> {
    try {
      const params = new URLSearchParams()
      if (options?.page) params.append('page', options.page.toString())
      if (options?.limit) params.append('limit', options.limit.toString())

      const queryString = params.toString()
      const url = buildApiUrl(`/reviews/space/${spaceId}${queryString ? `?${queryString}` : ''}`)

      const response = await $fetch<ReviewsApiResponse>(url)

      if (!response.success) {
        throw new Error(response.message || 'Error al obtener reseñas del espacio')
      }

      return {
        reviews: response.data,
        pagination: response.pagination
      }
    } catch (error) {
      throw new Error(extractApiErrorMessage(error))
    }
  }

  /**
   * Verificar si el usuario puede dejar reseña en una reserva
   */
  async canReview(bookingId: string): Promise<CanReviewResult> {
    try {
      const response = await $fetch<CanReviewApiResponse>(
        buildApiUrl(`/reviews/can-review/${bookingId}`),
        { headers: this.getHeaders() }
      )

      if (!response.success) {
        throw new Error(response.message || 'Error al verificar permisos de reseña')
      }

      return response.data
    } catch (error) {
      throw new Error(extractApiErrorMessage(error))
    }
  }

  /**
   * Crear una nueva reseña
   */
  async create(data: CreateReviewData): Promise<Review> {
    try {
      const response = await $fetch<ReviewApiResponse>(
        buildApiUrl('/reviews'),
        {
          method: 'POST',
          headers: this.getHeaders(),
          body: data
        }
      )

      if (!response.success) {
        throw new Error(response.message || 'Error al crear la reseña')
      }

      return response.data
    } catch (error) {
      throw new Error(extractApiErrorMessage(error))
    }
  }

  /**
   * Obtener mis reseñas (como usuario)
   */
  async getMyReviews(
    options?: { page?: number; limit?: number }
  ): Promise<{ reviews: Review[]; pagination: Pagination }> {
    try {
      const params = new URLSearchParams()
      if (options?.page) params.append('page', options.page.toString())
      if (options?.limit) params.append('limit', options.limit.toString())

      const queryString = params.toString()
      const url = buildApiUrl(`/reviews/my-reviews${queryString ? `?${queryString}` : ''}`)

      const response = await $fetch<ReviewsApiResponse>(url, {
        headers: this.getHeaders()
      })

      if (!response.success) {
        throw new Error(response.message || 'Error al obtener mis reseñas')
      }

      return {
        reviews: response.data,
        pagination: response.pagination
      }
    } catch (error) {
      throw new Error(extractApiErrorMessage(error))
    }
  }

  /**
   * Propietario responde a una reseña
   */
  async respondToReview(reviewId: string, response: string): Promise<Review> {
    try {
      const apiResponse = await $fetch<ReviewApiResponse>(
        buildApiUrl(`/reviews/${reviewId}/respond`),
        {
          method: 'POST',
          headers: this.getHeaders(),
          body: { response }
        }
      )

      if (!apiResponse.success) {
        throw new Error(apiResponse.message || 'Error al responder a la reseña')
      }

      return apiResponse.data
    } catch (error) {
      throw new Error(extractApiErrorMessage(error))
    }
  }

  /**
   * Eliminar una reseña
   */
  async delete(reviewId: string): Promise<void> {
    try {
      const response = await $fetch<{ success: boolean; message?: string }>(
        buildApiUrl(`/reviews/${reviewId}`),
        {
          method: 'DELETE',
          headers: this.getHeaders()
        }
      )

      if (!response.success) {
        throw new Error(response.message || 'Error al eliminar la reseña')
      }
    } catch (error) {
      throw new Error(extractApiErrorMessage(error))
    }
  }
}

export const reviewsService = new ReviewsService()
export default reviewsService
