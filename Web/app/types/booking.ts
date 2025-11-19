import type { Space } from './space'
import type { AuthUser } from './auth'

export type BookingStatus = 'pending' | 'confirmed' | 'cancelled' | 'completed'
export type PaymentMethod = 'cash' | 'card' | 'transfer'
export type PaymentStatus = 'pending' | 'paid' | 'refunded'

export interface Booking {
  _id: string
  spaceId: string
  userId: string
  startTime: string
  endTime: string
  status: BookingStatus
  createdAt: string
  updatedAt: string
  // Campos de pago
  paymentMethod?: PaymentMethod
  paymentStatus?: PaymentStatus
  totalAmount?: number
  subtotal?: number
  serviceFee?: number
  pricePerHour?: number
  durationHours?: number
  paidAt?: string
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
