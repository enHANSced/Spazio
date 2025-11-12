// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  compatibilityDate: '2025-07-15',
  
  devtools: { enabled: true },

  // Runtime Config
  runtimeConfig: {
    public: {
      apiBaseUrl: process.env.NUXT_PUBLIC_API_BASE_URL || 'http://localhost:3001/api',
      appName: process.env.NUXT_PUBLIC_APP_NAME || 'Spazio',
      appVersion: process.env.NUXT_PUBLIC_APP_VERSION || '1.0.0',
    }
  },

  // App Configuration
  app: {
    head: {
      title: 'Spazio - Sistema de Reservas Inteligente',
      meta: [
        { charset: 'utf-8' },
        { name: 'viewport', content: 'width=device-width, initial-scale=1' },
        { name: 'description', content: 'Sistema de reservas de espacios inteligente' }
      ],
      link: [
        { rel: 'icon', type: 'image/x-icon', href: '/favicon.ico' }
      ]
    }
  },

  // TypeScript Configuration
  typescript: {
    strict: true,
    typeCheck: false // Cambiar a true después de instalar vue-tsc
  },

  // CSS Configuration
  css: [],

  // Modules
  modules: []
})
