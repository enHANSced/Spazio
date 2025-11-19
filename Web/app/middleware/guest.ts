import { useAuthStore } from '../stores/auth'

export default defineNuxtRouteMiddleware(async () => {
  const authStore = useAuthStore()
  await authStore.init()

  if (authStore.isAuthenticated) {
    // Redirigir según el rol del usuario
    if (authStore.user?.role === 'owner') {
      return navigateTo(authStore.user.isVerified ? '/owner' : '/owner/pending-verification')
    } else if (authStore.user?.role === 'admin') {
      return navigateTo('/admin')
    }
    return navigateTo('/')
  }
})
