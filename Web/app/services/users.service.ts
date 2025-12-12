import type { AuthUser, BankAccountType, HondurasBank } from '../types/auth'
import { buildApiUrl, extractApiErrorMessage } from '../utils/http'

interface UserApiResponse {
  success: boolean
  message?: string
  data: AuthUser
}

interface UpdateProfilePayload {
  name?: string
  businessName?: string
  businessDescription?: string
  phone?: string
  whatsappNumber?: string
  instagram?: string
  facebook?: string
  linkedin?: string
  // Campos bancarios para owners
  bankName?: HondurasBank | string | null
  bankAccountType?: BankAccountType | null
  bankAccountNumber?: string | null
  bankAccountHolder?: string | null
}

export class UsersService {
  /**
   * Obtener perfil del usuario autenticado
   */
  static async getMe(token: string): Promise<AuthUser> {
    try {
      const response = await $fetch<UserApiResponse>(buildApiUrl('/users/me'), {
        headers: {
          Authorization: `Bearer ${token}`
        }
      })

      if (!response.success) {
        throw new Error(response.message || 'No fue posible obtener tu perfil')
      }

      return response.data
    } catch (error) {
      throw new Error(extractApiErrorMessage(error))
    }
  }

  /**
   * Actualizar perfil del usuario autenticado
   */
  static async updateProfile(token: string, payload: UpdateProfilePayload): Promise<AuthUser> {
    try {
      const response = await $fetch<UserApiResponse>(buildApiUrl('/users/me'), {
        method: 'PUT',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json'
        },
        body: payload
      })

      if (!response.success) {
        throw new Error(response.message || 'No fue posible actualizar tu perfil')
      }

      return response.data
    } catch (error) {
      throw new Error(extractApiErrorMessage(error))
    }
  }
}

export default UsersService

// Versión con manejo automático de token
export const usersService = {
  async getMyProfile() {
    const token = useCookie('spazio_token').value
    if (!token) throw new Error('No autenticado')
    
    try {
      const url = buildApiUrl('/users/me')
      const response = await $fetch<UserApiResponse>(url, {
        headers: { Authorization: `Bearer ${token}` }
      })

      return { success: response.success, data: response.data, message: response.message }
    } catch (error: any) {
      return { success: false, message: extractApiErrorMessage(error) }
    }
  },

  async updateMyProfile(updates: UpdateProfilePayload) {
    const token = useCookie('spazio_token').value
    if (!token) throw new Error('No autenticado')
    
    try {
      const url = buildApiUrl('/users/me')
      const response = await $fetch<UserApiResponse>(url, {
        method: 'PUT',
        headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
        body: updates
      })

      return { success: response.success, data: response.data, message: response.message }
    } catch (error: any) {
      return { success: false, message: extractApiErrorMessage(error) }
    }
  }
}
