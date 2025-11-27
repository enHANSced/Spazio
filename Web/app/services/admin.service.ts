import type { AuthUser } from '../types/auth'
import type { Space } from '../types/space'
import type { Booking } from '../types/booking'
import { buildApiUrl, extractApiErrorMessage } from '../utils/http'

// Tipos específicos para admin
export interface AdminStats {
  users: {
    total: number
    owners: number
    pendingOwners: number
  }
  spaces: {
    total: number
    active: number
    inactive: number
  }
  bookings: {
    total: number
    confirmed: number
    cancelled: number
    recentThirtyDays: number
    today: number
  }
}

export interface Pagination {
  total: number
  page: number
  limit: number
  totalPages: number
}

export interface PaginatedResponse<T> {
  success: boolean
  data: T[]
  pagination: Pagination
  message?: string
}

export interface AdminUser extends AuthUser {
  isActive: boolean
  phone?: string | null
  whatsappNumber?: string | null
  instagram?: string | null
  facebook?: string | null
  linkedin?: string | null
}

export interface UpdateUserPayload {
  name?: string
  role?: 'user' | 'owner' | 'admin'
  isActive?: boolean
  isVerified?: boolean
  businessName?: string
  businessDescription?: string
  phone?: string
  whatsappNumber?: string
}

export interface OwnerSpaceSummary {
  id: string
  name: string
  description?: string
  capacity: number
  pricePerHour?: number
  isActive: boolean
  city?: string
  images?: Array<{ url: string; publicId?: string }>
  createdAt: string
}

export interface OwnerStats {
  spaceStats: {
    total: number
    active: number
    inactive: number
  }
  bookingStats: {
    total: number
    confirmed: number
    cancelled: number
    pending: number
    completed: number
    totalRevenue: number
  }
}

export interface OwnerDetails {
  user: AdminUser
  spaces: OwnerSpaceSummary[]
  spaceStats: OwnerStats['spaceStats']
  bookingStats: OwnerStats['bookingStats']
}

// Service para administración
export const adminService = {
  // ============ ESTADÍSTICAS ============
  async getStats() {
    const token = useCookie('spazio_token').value
    if (!token) throw new Error('No autenticado')

    try {
      const response = await $fetch<{ success: boolean; data: AdminStats }>(
        buildApiUrl('/bookings/admin/stats'),
        {
          headers: { Authorization: `Bearer ${token}` }
        }
      )
      return { success: response.success, data: response.data }
    } catch (error: any) {
      return { success: false, data: null, message: extractApiErrorMessage(error) }
    }
  },

  // ============ USUARIOS ============
  async getUsers(params: {
    page?: number
    limit?: number
    role?: string
    isActive?: boolean
    isVerified?: boolean
    search?: string
  } = {}) {
    const token = useCookie('spazio_token').value
    if (!token) throw new Error('No autenticado')

    try {
      const query = new URLSearchParams()
      if (params.page) query.append('page', params.page.toString())
      if (params.limit) query.append('limit', params.limit.toString())
      if (params.role) query.append('role', params.role)
      if (params.isActive !== undefined) query.append('isActive', params.isActive.toString())
      if (params.isVerified !== undefined) query.append('isVerified', params.isVerified.toString())
      if (params.search) query.append('search', params.search)

      const response = await $fetch<PaginatedResponse<AdminUser>>(
        buildApiUrl(`/users?${query.toString()}`),
        {
          headers: { Authorization: `Bearer ${token}` }
        }
      )
      return { success: response.success, data: response.data, pagination: response.pagination }
    } catch (error: any) {
      return { success: false, data: [], pagination: null, message: extractApiErrorMessage(error) }
    }
  },

  async getUser(id: string) {
    const token = useCookie('spazio_token').value
    if (!token) throw new Error('No autenticado')

    try {
      const response = await $fetch<{ success: boolean; data: AdminUser }>(
        buildApiUrl(`/users/${id}`),
        {
          headers: { Authorization: `Bearer ${token}` }
        }
      )
      return { success: response.success, data: response.data }
    } catch (error: any) {
      return { success: false, data: null, message: extractApiErrorMessage(error) }
    }
  },

  async updateUser(id: string, payload: UpdateUserPayload) {
    const token = useCookie('spazio_token').value
    if (!token) throw new Error('No autenticado')

    try {
      const response = await $fetch<{ success: boolean; data: AdminUser; message?: string }>(
        buildApiUrl(`/users/${id}`),
        {
          method: 'PUT',
          headers: { Authorization: `Bearer ${token}` },
          body: payload
        }
      )
      return { success: response.success, data: response.data, message: response.message }
    } catch (error: any) {
      return { success: false, data: null, message: extractApiErrorMessage(error) }
    }
  },

  async toggleUserActive(id: string) {
    const token = useCookie('spazio_token').value
    if (!token) throw new Error('No autenticado')

    try {
      const response = await $fetch<{ success: boolean; data: AdminUser; message?: string }>(
        buildApiUrl(`/users/${id}/toggle`),
        {
          method: 'PATCH',
          headers: { Authorization: `Bearer ${token}` }
        }
      )
      return { success: response.success, data: response.data, message: response.message }
    } catch (error: any) {
      return { success: false, data: null, message: extractApiErrorMessage(error) }
    }
  },

  // ============ VERIFICACIÓN DE OWNERS ============
  async getPendingOwners() {
    const token = useCookie('spazio_token').value
    if (!token) throw new Error('No autenticado')

    try {
      const response = await $fetch<{ success: boolean; data: AdminUser[] }>(
        buildApiUrl('/users/pending-owners'),
        {
          headers: { Authorization: `Bearer ${token}` }
        }
      )
      return { success: response.success, data: response.data }
    } catch (error: any) {
      return { success: false, data: [], message: extractApiErrorMessage(error) }
    }
  },

  async verifyOwner(id: string, isVerified: boolean) {
    const token = useCookie('spazio_token').value
    if (!token) throw new Error('No autenticado')

    try {
      const response = await $fetch<{ success: boolean; data: AdminUser; message?: string }>(
        buildApiUrl(`/users/${id}/verify`),
        {
          method: 'PATCH',
          headers: { Authorization: `Bearer ${token}` },
          body: { isVerified }
        }
      )
      return { success: response.success, data: response.data, message: response.message }
    } catch (error: any) {
      return { success: false, data: null, message: extractApiErrorMessage(error) }
    }
  },

  async getOwnerDetails(id: string) {
    const token = useCookie('spazio_token').value
    if (!token) throw new Error('No autenticado')

    try {
      const response = await $fetch<{ success: boolean; data: OwnerDetails }>(
        buildApiUrl(`/users/owner/${id}/details`),
        {
          headers: { Authorization: `Bearer ${token}` }
        }
      )
      return { success: response.success, data: response.data }
    } catch (error: any) {
      return { success: false, data: null, message: extractApiErrorMessage(error) }
    }
  },

  // ============ ESPACIOS ============
  async getSpaces(params: {
    page?: number
    limit?: number
    isActive?: boolean
    search?: string
    ownerId?: string
  } = {}) {
    const token = useCookie('spazio_token').value
    if (!token) throw new Error('No autenticado')

    try {
      const query = new URLSearchParams()
      if (params.page) query.append('page', params.page.toString())
      if (params.limit) query.append('limit', params.limit.toString())
      if (params.isActive !== undefined) query.append('isActive', params.isActive.toString())
      if (params.search) query.append('search', params.search)
      if (params.ownerId) query.append('ownerId', params.ownerId)

      const response = await $fetch<PaginatedResponse<Space>>(
        buildApiUrl(`/spaces/admin/all?${query.toString()}`),
        {
          headers: { Authorization: `Bearer ${token}` }
        }
      )
      return { success: response.success, data: response.data, pagination: response.pagination }
    } catch (error: any) {
      return { success: false, data: [], pagination: null, message: extractApiErrorMessage(error) }
    }
  },

  async toggleSpaceActive(id: string) {
    const token = useCookie('spazio_token').value
    if (!token) throw new Error('No autenticado')

    try {
      const response = await $fetch<{ success: boolean; data: Space; message?: string }>(
        buildApiUrl(`/spaces/admin/${id}/toggle`),
        {
          method: 'PATCH',
          headers: { Authorization: `Bearer ${token}` }
        }
      )
      return { success: response.success, data: response.data, message: response.message }
    } catch (error: any) {
      return { success: false, data: null, message: extractApiErrorMessage(error) }
    }
  },

  // ============ RESERVAS ============
  async getBookings(params: {
    page?: number
    limit?: number
    status?: string
    spaceId?: string
    userId?: string
    startDate?: string
    endDate?: string
  } = {}) {
    const token = useCookie('spazio_token').value
    if (!token) throw new Error('No autenticado')

    try {
      const query = new URLSearchParams()
      if (params.page) query.append('page', params.page.toString())
      if (params.limit) query.append('limit', params.limit.toString())
      if (params.status) query.append('status', params.status)
      if (params.spaceId) query.append('spaceId', params.spaceId)
      if (params.userId) query.append('userId', params.userId)
      if (params.startDate) query.append('startDate', params.startDate)
      if (params.endDate) query.append('endDate', params.endDate)

      const response = await $fetch<PaginatedResponse<Booking>>(
        buildApiUrl(`/bookings/admin/all?${query.toString()}`),
        {
          headers: { Authorization: `Bearer ${token}` }
        }
      )
      return { success: response.success, data: response.data, pagination: response.pagination }
    } catch (error: any) {
      return { success: false, data: [], pagination: null, message: extractApiErrorMessage(error) }
    }
  },

  async cancelBooking(id: string) {
    const token = useCookie('spazio_token').value
    if (!token) throw new Error('No autenticado')

    try {
      const response = await $fetch<{ success: boolean; data: Booking; message?: string }>(
        buildApiUrl(`/bookings/admin/${id}`),
        {
          method: 'DELETE',
          headers: { Authorization: `Bearer ${token}` }
        }
      )
      return { success: response.success, data: response.data, message: response.message }
    } catch (error: any) {
      return { success: false, data: null, message: extractApiErrorMessage(error) }
    }
  }
}

export default adminService
