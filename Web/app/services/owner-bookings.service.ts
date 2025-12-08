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

// Versión con manejo automático de token
export const ownerBookingsService = {
  async getOwnerBookings(filters?: OwnerBookingsFilters) {
    const token = useCookie('spazio_token').value
    if (!token) throw new Error('No autenticado')
    
    try {
      const queryParams = new URLSearchParams()
      
      if (filters?.status) queryParams.append('status', filters.status)
      if (filters?.startDate) queryParams.append('startDate', filters.startDate)
      if (filters?.endDate) queryParams.append('endDate', filters.endDate)

      const url = buildApiUrl(`/bookings/owner/bookings${queryParams.toString() ? `?${queryParams.toString()}` : ''}`)

      const response = await $fetch<BookingsApiResponse>(url, {
        headers: { Authorization: `Bearer ${token}` }
      })

      return { success: response.success, data: response.data, message: response.message }
    } catch (error: any) {
      return { success: false, data: [], message: extractApiErrorMessage(error) }
    }
  },

  async getPendingTransferVerifications() {
    const token = useCookie('spazio_token').value
    if (!token) throw new Error('No autenticado')
    
    try {
      const url = buildApiUrl('/bookings/owner/pending-transfers')
      const response = await $fetch<BookingsApiResponse>(url, {
        headers: { Authorization: `Bearer ${token}` }
      })

      return { success: response.success, data: response.data, message: response.message }
    } catch (error: any) {
      return { success: false, data: [], message: extractApiErrorMessage(error) }
    }
  },

  async update(bookingId: string, updates: Partial<Booking>) {
    const token = useCookie('spazio_token').value
    if (!token) throw new Error('No autenticado')
    
    try {
      const url = buildApiUrl(`/bookings/${bookingId}`)
      const response = await $fetch<{ success: boolean; data?: Booking; message?: string }>(url, {
        method: 'PATCH',
        headers: { Authorization: `Bearer ${token}` },
        body: updates
      })

      return { success: response.success, data: response.data, message: response.message }
    } catch (error: any) {
      return { success: false, message: extractApiErrorMessage(error) }
    }
  },

  async verifyTransfer(bookingId: string, approved: boolean, rejectionReason?: string) {
    const token = useCookie('spazio_token').value
    if (!token) throw new Error('No autenticado')
    
    try {
      const url = buildApiUrl(`/bookings/${bookingId}/verify-transfer`)
      const response = await $fetch<{ success: boolean; data?: Booking; message?: string }>(url, {
        method: 'PATCH',
        headers: { Authorization: `Bearer ${token}` },
        body: { approved, rejectionReason }
      })

      return { success: response.success, data: response.data, message: response.message }
    } catch (error: any) {
      return { success: false, message: extractApiErrorMessage(error) }
    }
  },

  async cancel(bookingId: string) {
    const token = useCookie('spazio_token').value
    if (!token) throw new Error('No autenticado')
    
    try {
      const url = buildApiUrl(`/bookings/${bookingId}`)
      const response = await $fetch<{ success: boolean; data?: Booking; message?: string }>(url, {
        method: 'PATCH',
        headers: { Authorization: `Bearer ${token}` },
        body: { status: 'cancelled' }
      })

      return { success: response.success, data: response.data, message: response.message }
    } catch (error: any) {
      return { success: false, message: extractApiErrorMessage(error) }
    }
  },

  /**
   * Obtener reservas pendientes de confirmación (status='pending')
   */
  async getPendingBookings() {
    const token = useCookie('spazio_token').value
    if (!token) throw new Error('No autenticado')
    
    try {
      const url = buildApiUrl('/bookings/owner/pending')
      const response = await $fetch<BookingsApiResponse>(url, {
        headers: { Authorization: `Bearer ${token}` }
      })

      return { success: response.success, data: response.data, message: response.message }
    } catch (error: any) {
      return { success: false, data: [], message: extractApiErrorMessage(error) }
    }
  },

  /**
   * Confirmar una reserva pendiente
   */
  async confirmBooking(bookingId: string) {
    const token = useCookie('spazio_token').value
    if (!token) throw new Error('No autenticado')
    
    try {
      const url = buildApiUrl(`/bookings/owner/${bookingId}/confirm`)
      const response = await $fetch<{ success: boolean; data?: Booking; message?: string }>(url, {
        method: 'PATCH',
        headers: { Authorization: `Bearer ${token}` }
      })

      return { success: response.success, data: response.data, message: response.message }
    } catch (error: any) {
      return { success: false, message: extractApiErrorMessage(error) }
    }
  },

  /**
   * Rechazar una reserva pendiente
   */
  async rejectBooking(bookingId: string, reason: string) {
    const token = useCookie('spazio_token').value
    if (!token) throw new Error('No autenticado')
    
    try {
      const url = buildApiUrl(`/bookings/owner/${bookingId}/reject`)
      const response = await $fetch<{ success: boolean; data?: Booking; message?: string }>(url, {
        method: 'PATCH',
        headers: { Authorization: `Bearer ${token}` },
        body: { reason }
      })

      return { success: response.success, data: response.data, message: response.message }
    } catch (error: any) {
      return { success: false, message: extractApiErrorMessage(error) }
    }
  }
}
