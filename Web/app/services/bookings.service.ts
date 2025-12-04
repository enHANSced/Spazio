import type { Booking, BookingsApiResponse } from '~/types/booking'

class BookingsService {
  private getHeaders() {
    if (process.client) {
      // Obtener el token de las cookies
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

  private getAuthHeaders() {
    if (process.client) {
      const tokenCookie = document.cookie
        .split('; ')
        .find(row => row.startsWith('spazio_token='))
      const token = tokenCookie ? tokenCookie.split('=')[1] : null

      return token ? { Authorization: `Bearer ${token}` } : {}
    }
    return {}
  }

  private getApiUrl(path: string = '') {
    const config = useRuntimeConfig()
    const baseUrl = config.public.apiBaseUrl
    return `${baseUrl}/bookings${path}`
  }

  /**
   * Crear una nueva reserva
   */
  async create(data: {
    spaceId: string
    startTime: string
    endTime: string
    paymentMethod?: string
    paymentStatus?: string
    totalAmount?: number
    subtotal?: number
    serviceFee?: number
    pricePerHour?: number
    durationHours?: number
  }): Promise<Booking> {
    const response = await $fetch<{ success: boolean; data: Booking }>(this.getApiUrl(), {
      method: 'POST',
      headers: this.getHeaders(),
      body: data
    })
    return response.data
  }

  /**
   * Obtener todas las reservas del usuario autenticado
   */
  async list(): Promise<Booking[]> {
    const response = await $fetch<BookingsApiResponse>(this.getApiUrl('/my-bookings'), {
      headers: this.getHeaders()
    })
    return response.data
  }

  /**
   * Obtener una reserva específica por ID
   */
  async getById(id: string): Promise<Booking> {
    const response = await $fetch<{ success: boolean; data: Booking }>(this.getApiUrl(`/${id}`), {
      headers: this.getHeaders()
    })
    return response.data
  }

  /**
   * Cancelar una reserva
   */
  async cancel(id: string): Promise<Booking> {
    const response = await $fetch<{ success: boolean; data: Booking }>(this.getApiUrl(`/${id}`), {
      method: 'PATCH',
      headers: this.getHeaders(),
      body: { status: 'cancelled' }
    })
    return response.data
  }

  /**
   * Actualizar información de pago de una reserva
   */
  async updatePayment(id: string, data: {
    paymentMethod?: string
    paymentStatus?: string
    paidAt?: string
  }): Promise<Booking> {
    const response = await $fetch<{ success: boolean; data: Booking }>(this.getApiUrl(`/${id}`), {
      method: 'PATCH',
      headers: this.getHeaders(),
      body: data
    })
    return response.data
  }

  /**
   * Actualizar una reserva (para reprogramación u otros cambios)
   */
  async update(id: string, data: Partial<Booking>): Promise<Booking> {
    const response = await $fetch<{ success: boolean; data: Booking }>(this.getApiUrl(`/${id}`), {
      method: 'PATCH',
      headers: this.getHeaders(),
      body: data
    })
    return response.data
  }

  /**
   * Subir comprobante de transferencia
   */
  async uploadTransferProof(id: string, file: File): Promise<Booking> {
    const formData = new FormData()
    formData.append('proof', file)

    const response = await $fetch<{ success: boolean; data: Booking; message: string }>(
      this.getApiUrl(`/${id}/transfer-proof`),
      {
        method: 'POST',
        headers: this.getAuthHeaders(),
        body: formData
      }
    )
    return response.data
  }
}

export default new BookingsService()
