import { useRuntimeConfig } from '#imports'

interface ApiErrorLike {
  data?: { message?: string }
  message?: string
}

export const extractApiErrorMessage = (
  error: unknown,
  fallback = 'Ocurrió un error inesperado. Inténtalo de nuevo.'
): string => {
  if (error && typeof error === 'object') {
    const apiError = error as ApiErrorLike
    if (apiError.data?.message) return apiError.data.message
    if (typeof apiError.message === 'string') return apiError.message
  }

  if (error instanceof Error) return error.message
  return fallback
}

export const buildApiUrl = (path: string): string => {
  const config = useRuntimeConfig()
  const base = config.public.apiBaseUrl?.replace(/\/$/, '') ?? ''
  const normalizedPath = path.startsWith('/') ? path : `/${path}`
  return `${base}${normalizedPath}`
}
