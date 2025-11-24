export type UserRole = 'user' | 'owner' | 'admin'

export interface AuthUser {
  id: string
  name: string
  email: string
  role: UserRole
  isVerified: boolean
  businessName?: string | null
  businessDescription?: string | null
  createdAt?: string
  updatedAt?: string
}

export interface LoginPayload {
  email: string
  password: string
}

export interface RegisterPayload extends LoginPayload {
  name: string
  role?: UserRole
  businessName?: string | null
  businessDescription?: string | null
}

export interface ApiSuccessResponse<T> {
  success: true
  message?: string
  data: T
}

export interface ApiErrorResponse {
  success: false
  message: string
}

export interface AuthSessionPayload {
  user: AuthUser
  token: string
}

export type LoginApiResponse = ApiSuccessResponse<AuthSessionPayload> | ApiErrorResponse
export type RegisterApiResponse = ApiSuccessResponse<{ user: AuthUser; token: string; message?: string }> | ApiErrorResponse

export type ProfileApiResponse = ApiSuccessResponse<AuthUser> | ApiErrorResponse
