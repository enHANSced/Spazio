import { useAuthStore } from '../stores/auth'

export default defineNuxtRouteMiddleware(async () => {
  const authStore = useAuthStore()
  await authStore.init()

  if (authStore.isAuthenticated) {
    return navigateTo('/')
  }
})
