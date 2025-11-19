import type { Booking } from '../types/booking'
import { buildApiUrl, extractApiErrorMessage } from '../utils/http'

interface OwnerBookingsFilters {
  status?: 'pending' | 'confirmed' | 'cancelled' | 'completed'
  startDate?: string // ISO 8601
  endDate?: string   // ISO 8601
}

interface BookingsApiResponse {
  success: boolean
  message?: string
  data: Booking[]
}

export class OwnerBookingsService {
  /**
   * Obtener todas las reservas de los espacios del propietario autenticado
   */
  static async getOwnerBookings(token: string, filters?: OwnerBookingsFilters): Promise<Booking[]> {
    try {
      const queryParams = new URLSearchParams()
      
      if (filters?.status) {
        queryParams.append('status', filters.status)
      }
      
      if (filters?.startDate) {
        queryParams.append('startDate', filters.startDate)
      }
      
      if (filters?.endDate) {
        queryParams.append('endDate', filters.endDate)
      }

      const url = buildApiUrl(`/bookings/owner/bookings${queryParams.toString() ? `?${queryParams.toString()}` : ''}`)

      const response = await $fetch<BookingsApiResponse>(url, {
        headers: {
          Authorization: `Bearer ${token}`
        }
      })

      if (!response.success) {
        throw new Error(response.message || 'No fue posible cargar las reservas')
      }

      return response.data
    } catch (error) {
      throw new Error(extractApiErrorMessage(error))
    }
  }
}

export default OwnerBookingsService
