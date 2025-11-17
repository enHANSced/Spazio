import type {
  AuthSessionPayload,
  AuthUser,
  LoginApiResponse,
  LoginPayload,
  ProfileApiResponse,
  RegisterApiResponse,
  RegisterPayload
} from '../types/auth'
import { buildApiUrl, extractApiErrorMessage } from '../utils/http'

export class AuthService {
  static async login(payload: LoginPayload): Promise<AuthSessionPayload> {
    try {
      const response = await $fetch<LoginApiResponse>(buildApiUrl('/auth/login'), {
        method: 'POST',
        body: payload
      })

      if (!response.success) {
        throw new Error(response.message || 'No fue posible iniciar sesión')
      }

      return response.data
    } catch (error) {
      throw new Error(extractApiErrorMessage(error))
    }
  }

  static async register(payload: RegisterPayload): Promise<{ user: AuthUser; token: string; message?: string }> {
    try {
      const response = await $fetch<RegisterApiResponse>(buildApiUrl('/auth/register'), {
        method: 'POST',
        body: payload
      })

      if (!response.success) {
        throw new Error(response.message || 'No fue posible crear tu cuenta')
      }

      return response.data
    } catch (error) {
      throw new Error(extractApiErrorMessage(error))
    }
  }

  static async profile(token: string): Promise<AuthUser> {
    try {
      const response = await $fetch<ProfileApiResponse>(buildApiUrl('/auth/profile'), {
        headers: {
          Authorization: `Bearer ${token}`
        }
      })

      if (!response.success) {
        throw new Error(response.message || 'No fue posible recuperar el perfil')
      }

      return response.data
    } catch (error) {
      throw new Error(extractApiErrorMessage(error))
    }
  }
}

export default AuthService
