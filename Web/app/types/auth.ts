export type UserRole = 'user' | 'owner' | 'admin'

// Tipos de cuenta bancaria (Honduras)
export type BankAccountType = 'ahorro_lempiras' | 'ahorro_dolares' | 'corriente_lempiras' | 'corriente_dolares'

// Lista de bancos de Honduras
export const HONDURAS_BANKS = [
  'BAC Honduras',
  'Banco Atlántida',
  'Ficohsa',
  'Banpaís',
  'Banco de Occidente',
  'Banco Promerica',
  'Davivienda Honduras',
  'Banco de los Trabajadores',
  'Banco Lafise',
  'Banco Ficensa',
  'Otro'
] as const

export type HondurasBank = typeof HONDURAS_BANKS[number]

export interface AuthUser {
  id: string
  name: string
  email: string
  role: UserRole
  isVerified: boolean
  businessName?: string | null
  businessDescription?: string | null
  phone?: string | null
  whatsappNumber?: string | null
  instagram?: string | null
  facebook?: string | null
  linkedin?: string | null
  // Información bancaria (solo para owners)
  bankName?: HondurasBank | null
  bankAccountType?: BankAccountType | null
  bankAccountNumber?: string | null
  bankAccountHolder?: string | null
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
  phone?: string | null
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
