import type { Space } from './space'
import type { AuthUser } from './auth'

export type BookingStatus = 'pending' | 'confirmed' | 'cancelled'

export interface Booking {
  _id: string
  spaceId: string
  userId: string
  startTime: string
  endTime: string
  status: BookingStatus
  createdAt: string
  updatedAt: string
  // Enriquecido con datos relacionados
  space?: Space
  user?: AuthUser
}

export interface BookingsApiResponse {
  success: boolean
  message?: string
  data: Booking[]
}

export interface BookingApiResponse {
  success: boolean
  message?: string
  data: Booking
}
