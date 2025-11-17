import type { Booking, BookingsApiResponse } from '~/types/booking'

class BookingsService {
  private readonly baseUrl = '/api/bookings'

  /**
   * Crear una nueva reserva
   */
  async create(data: {
    spaceId: string
    startTime: string
    endTime: string
  }): Promise<Booking> {
    const response = await $fetch<{ success: boolean; data: Booking }>(this.baseUrl, {
      method: 'POST',
      body: data
    })
    return response.data
  }

  /**
   * Obtener todas las reservas del usuario autenticado
   */
  async list(): Promise<Booking[]> {
    const response = await $fetch<BookingsApiResponse>(this.baseUrl)
    return response.data
  }

  /**
   * Obtener una reserva específica por ID
   */
  async getById(id: string): Promise<Booking> {
    const response = await $fetch<{ success: boolean; data: Booking }>(`${this.baseUrl}/${id}`)
    return response.data
  }

  /**
   * Cancelar una reserva
   */
  async cancel(id: string): Promise<Booking> {
    const response = await $fetch<{ success: boolean; data: Booking }>(`${this.baseUrl}/${id}`, {
      method: 'PATCH',
      body: { status: 'cancelled' }
    })
    return response.data
  }
}

export default new BookingsService()
