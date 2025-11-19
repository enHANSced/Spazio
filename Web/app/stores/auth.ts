import { defineStore } from 'pinia'
import { computed, ref, watch } from 'vue'
import AuthService from '../services/auth.service'
import type { AuthUser, LoginPayload, RegisterPayload } from '../types/auth'

const isProd = process.env.NODE_ENV === 'production'

const parseUserCookie = (value: string | null): AuthUser | null => {
  if (!value) return null
  try {
    return JSON.parse(value) as AuthUser
  } catch (error) {
    console.warn('[auth] No fue posible parsear el usuario almacenado', error)
    return null
  }
}

export const useAuthStore = defineStore('auth', () => {
  const user = ref<AuthUser | null>(null)
  const token = ref<string | null>(null)
  const loading = ref(false)
  const error = ref<string | null>(null)
  const initialized = ref(false)

  const tokenCookie = useCookie<string | null>('spazio_token', {
    sameSite: 'lax',
    secure: isProd,
    default: () => null
  })

  const userCookie = useCookie<string | null>('spazio_user', {
    sameSite: 'lax',
    secure: isProd,
    default: () => null
  })

  let initPromise: Promise<void> | null = null

  const hydrateFromCookies = () => {
    token.value = tokenCookie.value
    user.value = parseUserCookie(userCookie.value)
  }

  const persistSession = () => {
    tokenCookie.value = token.value
    userCookie.value = user.value ? JSON.stringify(user.value) : null
  }

  const logout = () => {
    token.value = null
    user.value = null
    persistSession()
  }

  const init = async () => {
    if (initialized.value) return
    if (initPromise) {
      await initPromise
      return
    }

    initPromise = (async () => {
      hydrateFromCookies()

      if (!user.value && token.value) {
        try {
          const profile = await AuthService.profile(token.value)
          user.value = profile
        } catch (error) {
          console.error('[auth] Error al restaurar la sesión', error)
          logout()
        }
      }

      initialized.value = true
    })()

    try {
      await initPromise
    } finally {
      initPromise = null
    }
  }

  watch([user, token], persistSession, { deep: true })

  const login = async (payload: LoginPayload) => {
    loading.value = true
    error.value = null

    try {
      const data = await AuthService.login(payload)
      token.value = data.token
      user.value = data.user
      return data.user
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'No fue posible iniciar sesión'
      throw err
    } finally {
      loading.value = false
    }
  }

  const register = async (payload: RegisterPayload) => {
    loading.value = true
    error.value = null

    try {
      const data = await AuthService.register(payload)
      token.value = data.token
      user.value = data.user
      return data
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'No fue posible crear la cuenta'
      throw err
    } finally {
      loading.value = false
    }
  }

  const isAuthenticated = computed(() => Boolean(token.value && user.value))
  const userRole = computed(() => user.value?.role ?? null)
  const isOwner = computed(() => user.value?.role === 'owner')
  const isVerifiedOwner = computed(() => user.value?.role === 'owner' && user.value?.isVerified === true)
  const isAdmin = computed(() => user.value?.role === 'admin')

  return {
    user,
    token,
    loading,
    error,
    initialized,
    isAuthenticated,
    userRole,
    isOwner,
    isVerifiedOwner,
    isAdmin,
    login,
    register,
    logout,
    init
  }
})
