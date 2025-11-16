import { storeToRefs } from 'pinia'
import type { LoginPayload, RegisterPayload } from '../types/auth'
import { useAuthStore } from '../stores/auth'

interface AuthActionOptions {
  redirectTo?: string
  skipRedirect?: boolean
}

export const useAuth = () => {
  const authStore = useAuthStore()
  const route = useRoute()

  const ensureSession = async () => {
    await authStore.init()
  }

  const login = async (payload: LoginPayload, options?: AuthActionOptions) => {
    await ensureSession()
    const user = await authStore.login(payload)

    if (!options?.skipRedirect) {
      const redirectTarget = options?.redirectTo ?? (typeof route.query.redirect === 'string' ? route.query.redirect : '/')
      await navigateTo(redirectTarget)
    }

    return user
  }

  const register = async (payload: RegisterPayload, options?: AuthActionOptions) => {
    await ensureSession()
    const result = await authStore.register(payload)

    if (!options?.skipRedirect) {
      const redirectTarget = options?.redirectTo ?? '/'
      await navigateTo(redirectTarget)
    }

    return result
  }

  const logout = async () => {
    authStore.logout()
    await navigateTo('/auth/login')
  }

  return {
    ...storeToRefs(authStore),
    login,
    register,
    logout,
    init: ensureSession
  }
}
