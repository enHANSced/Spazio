import type { AuthUser, LoginApiResponse, LoginPayload, ProfileApiResponse } from '../types/auth'

const parseErrorMessage = (error: unknown): string => {
  if (error && typeof error === 'object') {
    const data = (error as { data?: { message?: string }; message?: string }).data
    if (data?.message) return data.message
    if ('message' in error && typeof error.message === 'string') return error.message
  }
  if (error instanceof Error) return error.message
  return 'Ocurrió un error inesperado. Inténtalo de nuevo.'
}

export class AuthService {
  static async login(payload: LoginPayload): Promise<{ user: AuthUser; token: string }> {
    try {
      const config = useRuntimeConfig()
      const response = await $fetch<LoginApiResponse>(`${config.public.apiBaseUrl}/auth/login`, {
        method: 'POST',
        body: payload
      })

      if (!response.success) {
        throw new Error(response.message || 'No fue posible iniciar sesión')
      }

      return response.data
    } catch (error) {
      throw new Error(parseErrorMessage(error))
    }
  }

  static async profile(token: string): Promise<AuthUser> {
    try {
      const config = useRuntimeConfig()
      const response = await $fetch<ProfileApiResponse>(`${config.public.apiBaseUrl}/auth/profile`, {
        headers: {
          Authorization: `Bearer ${token}`
        }
      })

      if (!response.success) {
        throw new Error(response.message || 'No fue posible recuperar el perfil')
      }

      return response.data
    } catch (error) {
      throw new Error(parseErrorMessage(error))
    }
  }
}

export default AuthService
