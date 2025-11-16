import { storeToRefs } from 'pinia'
import type { LoginPayload } from '../types/auth'
import { useAuthStore } from '../stores/auth'

interface LoginOptions {
  redirectTo?: string
  skipRedirect?: boolean
}

export const useAuth = () => {
  const authStore = useAuthStore()
  const route = useRoute()

  const ensureSession = async () => {
    await authStore.init()
  }

  const login = async (payload: LoginPayload, options?: LoginOptions) => {
    await ensureSession()
    const user = await authStore.login(payload)

    if (!options?.skipRedirect) {
      const redirectTarget = options?.redirectTo ?? (typeof route.query.redirect === 'string' ? route.query.redirect : '/')
      await navigateTo(redirectTarget)
    }

    return user
  }

  const logout = async () => {
    authStore.logout()
    await navigateTo('/auth/login')
  }

  return {
    ...storeToRefs(authStore),
    login,
    logout,
    init: ensureSession
  }
}
