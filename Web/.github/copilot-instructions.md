# Spazio Web - Instrucciones para GitHub Copilot

## Contexto del Proyecto

Frontend web del sistema de reservas Spazio, construido con **Nuxt.js 4 + Vue 3 + TypeScript**.

## Stack y Convenciones

### Tecnologías Core
- **Framework:** Nuxt.js 4 (auto-imports, file-based routing, SSR)
- **UI:** Vue 3 Composition API con `<script setup>`
- **Lenguaje:** TypeScript en modo strict
- **Estado:** Pinia (pendiente instalación)
- **Estilos:** TailwindCSS (pendiente instalación)

### Estructura de Archivos
```
app/
├── components/     → Componentes Vue (.vue)
├── composables/    → useX.ts (lógica reutilizable)
├── layouts/        → X.vue (plantillas de layout)
├── pages/          → X.vue (routing automático)
├── middleware/     → X.ts (protección de rutas)
├── stores/         → X.ts (Pinia stores)
├── services/       → X.service.ts (API calls)
├── types/          → X.ts (tipos TypeScript)
└── utils/          → X.ts (helpers)
```

## Patrones de Código

### 1. Componentes Vue

```vue
<script setup lang="ts">
// Orden estricto:
// 1. Imports
import { ref, computed } from 'vue'

// 2. Props
const props = defineProps<{
  title: string
  optional?: number
}>()

// 3. Emits
const emit = defineEmits<{
  submit: [value: string]
}>()

// 4. Composables
const { user } = useAuth()

// 5. State
const loading = ref(false)

// 6. Computed
const displayName = computed(() => user.value?.name)

// 7. Methods
const handleClick = () => {
  emit('submit', 'value')
}

// 8. Lifecycle
onMounted(() => {})
</script>

<template>
  <div>
    <!-- Siempre usar v-if, v-for con :key -->
  </div>
</template>

<style scoped>
/* TailwindCSS classes preferred */
</style>
```

### 2. Composables

```typescript
// composables/useAuth.ts
export const useAuth = () => {
  const authStore = useAuthStore()
  const router = useRouter()
  
  const login = async (credentials: LoginCredentials) => {
    try {
      const response = await AuthService.login(credentials)
      authStore.setToken(response.token)
      authStore.setUser(response.user)
      router.push('/dashboard')
    } catch (error) {
      throw error
    }
  }
  
  const logout = () => {
    authStore.clearAuth()
    router.push('/login')
  }
  
  return {
    user: computed(() => authStore.user),
    isAuthenticated: computed(() => authStore.isAuthenticated),
    login,
    logout
  }
}
```

### 3. Services (API)

```typescript
// services/auth.service.ts
export class AuthService {
  private static readonly BASE_URL = '/auth'
  
  static async login(credentials: LoginCredentials): Promise<AuthResponse> {
    const config = useRuntimeConfig()
    
    return await $fetch(`${config.public.apiBaseUrl}${this.BASE_URL}/login`, {
      method: 'POST',
      body: credentials
    })
  }
  
  static async register(data: RegisterData): Promise<AuthResponse> {
    const config = useRuntimeConfig()
    
    return await $fetch(`${config.public.apiBaseUrl}${this.BASE_URL}/register`, {
      method: 'POST',
      body: data
    })
  }
}
```

### 4. Pinia Stores

```typescript
// stores/auth.ts
import { defineStore } from 'pinia'

export const useAuthStore = defineStore('auth', {
  state: () => ({
    user: null as User | null,
    token: null as string | null
  }),
  
  getters: {
    isAuthenticated: (state) => !!state.token,
    isOwner: (state) => state.user?.role === 'owner',
    isAdmin: (state) => state.user?.role === 'admin'
  },
  
  actions: {
    setUser(user: User) {
      this.user = user
    },
    
    setToken(token: string) {
      this.token = token
      // Persistir en localStorage
      if (process.client) {
        localStorage.setItem('token', token)
      }
    },
    
    clearAuth() {
      this.user = null
      this.token = null
      if (process.client) {
        localStorage.removeItem('token')
      }
    }
  }
})
```

### 5. Middleware

```typescript
// middleware/auth.ts
export default defineNuxtRouteMiddleware((to, from) => {
  const authStore = useAuthStore()
  
  if (!authStore.isAuthenticated) {
    return navigateTo('/login')
  }
})

// middleware/guest.ts
export default defineNuxtRouteMiddleware((to, from) => {
  const authStore = useAuthStore()
  
  if (authStore.isAuthenticated) {
    return navigateTo('/dashboard')
  }
})

// middleware/owner.ts
export default defineNuxtRouteMiddleware((to, from) => {
  const authStore = useAuthStore()
  
  if (!authStore.isOwner && !authStore.isAdmin) {
    return navigateTo('/')
  }
})
```

### 6. Tipos TypeScript

```typescript
// types/models.ts
export interface User {
  id: string
  email: string
  name: string
  role: 'user' | 'owner' | 'admin'
  isVerified: boolean
  createdAt: string
  updatedAt: string
}

export interface Space {
  id: string
  name: string
  description: string
  capacity: number
  pricePerHour: number
  ownerId: string
  isActive: boolean
  createdAt: string
  updatedAt: string
}

export interface Booking {
  id: string
  userId: string
  spaceId: string
  startTime: string
  endTime: string
  status: 'pending' | 'confirmed' | 'cancelled'
  createdAt: string
  updatedAt: string
}

// types/api.ts
export interface LoginCredentials {
  email: string
  password: string
}

export interface RegisterData {
  email: string
  password: string
  name: string
  role?: 'user' | 'owner'
}

export interface AuthResponse {
  success: boolean
  token: string
  user: User
}

export interface ApiError {
  success: false
  message: string
  errors?: Record<string, string[]>
}
```

## Integración con Backend

### Configuración
- **Base URL:** `http://localhost:3001/api` (configurable en `.env`)
- **Autenticación:** JWT en header `Authorization: Bearer <token>`
- **Formato:** JSON para requests y responses

### Manejo de Errores

```typescript
// services/api.service.ts
export const handleApiError = (error: any) => {
  if (error.response) {
    // Error del servidor
    const apiError = error.response._data as ApiError
    return apiError.message || 'Error del servidor'
  } else if (error.request) {
    // Sin respuesta del servidor
    return 'No se pudo conectar al servidor'
  } else {
    // Error al preparar request
    return 'Error al procesar la solicitud'
  }
}
```

## Usuarios de Prueba (Backend)

```typescript
// Usar para desarrollo/testing
const testUsers = {
  admin: { email: 'admin@spazio.com', password: 'admin123' },
  user: { email: 'user@spazio.com', password: 'user123' },
  owner1: { email: 'owner1@spazio.com', password: 'owner123' },
  owner2: { email: 'owner2@spazio.com', password: 'owner123' },
  pending: { email: 'pending@spazio.com', password: 'pending123' }
}
```

## Reglas de Código

### DO's ✅
- Usar Composition API con `<script setup>`
- TypeScript estricto, tipar TODO
- Auto-imports de Nuxt (ref, computed, useFetch, etc.)
- Componentes pequeños y reutilizables
- Validación client-side antes de enviar
- Manejo de errores con try/catch
- Loading states en operaciones async
- Feedback visual al usuario (toast/notifications)

### DON'Ts ❌
- NO usar Options API
- NO ignorar tipos TypeScript
- NO hacer llamadas API directamente en componentes (usar services)
- NO olvidar validación de formularios
- NO exponer datos sensibles en cliente
- NO hardcodear URLs (usar runtimeConfig)
- NO omitir estados de loading/error

## Nomenclatura

- **Componentes:** PascalCase (`SpaceCard.vue`, `BookingForm.vue`)
- **Composables:** camelCase con `use` (`useAuth.ts`, `useSpaces.ts`)
- **Stores:** camelCase con `Store` (`authStore.ts`, `spacesStore.ts`)
- **Services:** PascalCase con `Service` (`AuthService.ts`, `SpacesService.ts`)
- **Types:** PascalCase (`User`, `Space`, `Booking`)
- **Utils:** camelCase (`formatDate.ts`, `validators.ts`)

## Meta de Páginas

```typescript
// Proteger ruta con middleware
definePageMeta({
  middleware: 'auth'
})

// Múltiples middleware
definePageMeta({
  middleware: ['auth', 'owner']
})

// Layout personalizado
definePageMeta({
  layout: 'dashboard'
})
```

## Variables de Entorno

```typescript
// Acceder a variables en código
const config = useRuntimeConfig()
console.log(config.public.apiBaseUrl) // ✅
console.log(config.public.appName)     // ✅

// NO acceder directamente a process.env ❌
```

## Estado Actual del Proyecto

- ✅ Proyecto Nuxt 4 inicializado
- ✅ Estructura de carpetas creada
- ✅ TypeScript configurado (strict mode)
- ✅ Variables de entorno configuradas
- ⏳ Pinia NO instalado aún
- ⏳ TailwindCSS NO instalado aún
- ⏳ FullCalendar NO instalado aún
- ⏳ Componentes NO creados aún
- ⏳ Páginas NO creadas aún

## Cuando Implementar Features

1. **SIEMPRE preguntar** si faltan dependencias antes de crear código que las use
2. **NO asumir** que Pinia, TailwindCSS o FullCalendar están instalados
3. **Seguir arquitectura** similar al backend (separación de concerns)
4. **Tipar todo** con TypeScript
5. **Usar convenciones** de Nuxt (auto-imports, file-based routing)

## Próximos Pasos Típicos

1. Instalar Pinia → `npm install pinia @pinia/nuxt`
2. Instalar TailwindCSS → `npx nuxi module add @nuxtjs/tailwindcss`
3. Crear tipos base en `types/`
4. Crear servicios API en `services/`
5. Crear stores en `stores/`
6. Crear composables en `composables/`
7. Crear componentes en `components/`
8. Crear páginas en `pages/`
9. Crear layouts en `layouts/`
10. Crear middleware en `middleware/`
