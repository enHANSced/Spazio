import { useAuthStore } from '../stores/auth'

export default defineNuxtRouteMiddleware(async (to) => {
  const authStore = useAuthStore()
  await authStore.init()

  if (!authStore.isAuthenticated) {
    return navigateTo({
      path: '/auth/login',
      query: { redirect: to.fullPath }
    })
  }

  if (!authStore.isOwner && !authStore.isAdmin) {
    return navigateTo('/')
  }

  // Si es owner pero no verificado, redirigir a página de verificación pendiente
  if (authStore.isOwner && !authStore.user?.isVerified) {
    return navigateTo('/owner/pending-verification')
  }
})
