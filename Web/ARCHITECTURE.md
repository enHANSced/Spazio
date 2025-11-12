# Arquitectura Frontend - Spazio Web

## Visión General

El frontend web de Spazio está construido con **Nuxt.js 4** siguiendo una arquitectura limpia y modular, similar al backend, para mantener consistencia en todo el proyecto.

## Stack Tecnológico

### Core
- **Framework:** Nuxt.js 4 (Auto-imports, SSR, File-based routing)
- **UI Framework:** Vue 3 Composition API
- **Lenguaje:** TypeScript (strict mode)
- **Build Tool:** Vite (incluido en Nuxt)

### Dependencias Planeadas
- **Estado Global:** Pinia
- **Estilos:** TailwindCSS
- **Calendario:** FullCalendar
- **HTTP:** useFetch (Nuxt built-in)
- **Validación:** Vuelidate o similar
- **Notificaciones:** TBD

## Estructura de Carpetas

```
Web/app/
├── components/          # Componentes Vue reutilizables
│   ├── common/         # Botones, inputs, modals
│   ├── layout/         # Header, Footer, Sidebar
│   ├── spaces/         # Componentes de espacios
│   └── bookings/       # Componentes de reservas
│
├── composables/        # Funciones Composition API
│   ├── useAuth.ts      # Autenticación
│   ├── useApi.ts       # Llamadas HTTP
│   └── useToast.ts     # Notificaciones
│
├── layouts/            # Plantillas de diseño
│   ├── default.vue     # Layout principal
│   ├── auth.vue        # Layout de login/registro
│   └── dashboard.vue   # Layout del dashboard
│
├── pages/              # Páginas (routing automático)
│   ├── index.vue       # Página principal
│   ├── login.vue       # Login
│   ├── spaces/         # Páginas de espacios
│   ├── bookings/       # Páginas de reservas
│   └── dashboard/      # Dashboard de usuario
│
├── middleware/         # Middleware de routing
│   ├── auth.ts         # Protege rutas autenticadas
│   ├── guest.ts        # Rutas solo para invitados
│   └── role.ts         # Verifica roles
│
├── stores/             # Estado global (Pinia)
│   ├── auth.ts         # Estado de autenticación
│   ├── spaces.ts       # Estado de espacios
│   └── bookings.ts     # Estado de reservas
│
├── services/           # Servicios de API
│   ├── api.service.ts  # Cliente HTTP base
│   ├── auth.service.ts # Endpoints de auth
│   ├── spaces.service.ts
│   └── bookings.service.ts
│
├── types/              # Tipos TypeScript
│   ├── models.ts       # Modelos de datos
│   ├── api.ts          # Tipos de API
│   └── enums.ts        # Enumeraciones
│
└── utils/              # Utilidades
    ├── validators.ts   # Validadores
    ├── formatters.ts   # Formateadores de fecha/hora
    └── constants.ts    # Constantes
```

## Patrones de Diseño

### 1. Composables (Lógica Reutilizable)

Los composables encapsulan lógica que puede ser reutilizada en múltiples componentes:

```typescript
// composables/useAuth.ts
export const useAuth = () => {
  const authStore = useAuthStore()
  const router = useRouter()
  
  const login = async (credentials) => {
    // Lógica de login
  }
  
  const logout = () => {
    // Lógica de logout
  }
  
  return { login, logout, user: authStore.user }
}
```

### 2. Services (Comunicación con API)

Los services manejan todas las llamadas HTTP al backend:

```typescript
// services/auth.service.ts
export class AuthService {
  static async login(credentials) {
    return await $fetch('/auth/login', {
      method: 'POST',
      body: credentials
    })
  }
}
```

### 3. Stores (Estado Global con Pinia)

Los stores gestionan el estado global de la aplicación:

```typescript
// stores/auth.ts
export const useAuthStore = defineStore('auth', {
  state: () => ({
    user: null,
    token: null
  }),
  
  actions: {
    setUser(user) {
      this.user = user
    }
  }
})
```

### 4. Middleware (Protección de Rutas)

El middleware controla el acceso a páginas:

```typescript
// middleware/auth.ts
export default defineNuxtRouteMiddleware((to, from) => {
  const authStore = useAuthStore()
  
  if (!authStore.isAuthenticated) {
    return navigateTo('/login')
  }
})
```

## Flujo de Datos

```
┌──────────┐
│  Pages   │  ← Usuario interactúa
└────┬─────┘
     │
     ↓ usa
┌──────────────┐
│ Composables  │  ← Lógica reutilizable
└────┬─────────┘
     │
     ↓ accede
┌──────────────┐
│    Stores    │  ← Estado global
└────┬─────────┘
     │
     ↓ llama
┌──────────────┐
│   Services   │  ← HTTP requests
└────┬─────────┘
     │
     ↓ consume
┌──────────────┐
│ Backend API  │  ← http://localhost:3001/api
└──────────────┘
```

## Convenciones de Código

### Nomenclatura
- **Componentes:** PascalCase (`SpaceCard.vue`)
- **Composables:** camelCase con prefijo `use` (`useAuth.ts`)
- **Stores:** camelCase con sufijo Store (`authStore.ts`)
- **Services:** PascalCase con sufijo Service (`AuthService.ts`)
- **Types:** PascalCase para interfaces (`User`, `Space`)

### Organización de Componentes

```vue
<script setup lang="ts">
// 1. Imports
import { ref } from 'vue'

// 2. Props
const props = defineProps<{
  title: string
}>()

// 3. Emits
const emit = defineEmits<{
  submit: []
}>()

// 4. Composables
const { login } = useAuth()

// 5. Reactive state
const loading = ref(false)

// 6. Computed
const isValid = computed(() => ...)

// 7. Methods
const handleSubmit = () => {...}

// 8. Lifecycle
onMounted(() => {...})
</script>

<template>
  <!-- Template -->
</template>

<style scoped>
/* Estilos */
</style>
```

## Sistema de Autenticación

### Flujo de Login
1. Usuario ingresa credenciales en `/login`
2. `useAuth()` composable llama `AuthService.login()`
3. Backend retorna JWT + datos del usuario
4. Token se guarda en `authStore` y `localStorage`
5. Redirect a dashboard según rol

### Persistencia de Sesión
- JWT almacenado en `localStorage`
- Auto-login en página refresh si token válido
- Middleware `auth.ts` verifica token en cada navegación

### Protección de Rutas

```typescript
// pages/dashboard.vue
definePageMeta({
  middleware: 'auth' // Solo usuarios autenticados
})

// pages/spaces/create.vue
definePageMeta({
  middleware: ['auth', 'owner'] // Solo owners
})
```

## Manejo de Errores

### Estrategia Global
- Interceptor de errores HTTP en `services/api.service.ts`
- Toast notifications para errores de usuario
- Logging de errores en consola (dev) o servicio externo (prod)

### Validación de Formularios
- Validación client-side antes de enviar
- Mostrar errores del servidor en UI
- Feedback visual inmediato

## Performance

### Optimizaciones Planeadas
- ✅ Auto-imports (Nuxt built-in)
- ✅ Code splitting automático (Nuxt)
- ⏳ Lazy loading de componentes pesados
- ⏳ Paginación de listas grandes
- ⏳ Debounce en búsquedas
- ⏳ Caché de datos frecuentes

## Responsividad

### Breakpoints (TailwindCSS)
- **Mobile:** < 640px
- **Tablet:** 640px - 1024px
- **Desktop:** > 1024px

### Mobile-First
- Diseño responsive desde el inicio
- Touch-friendly UI components
- Menús adaptables

## Testing (Planeado)

### Unit Tests
- Composables con Vitest
- Stores con Vitest
- Utils con Vitest

### Integration Tests
- Flujos completos con Playwright
- E2E testing de casos críticos

## Estado Actual

- ✅ Proyecto Nuxt 4 inicializado
- ✅ Estructura de carpetas creada
- ✅ Configuración base establecida
- ✅ Variables de entorno configuradas
- ✅ TypeScript strict mode activado
- ⏳ Dependencias adicionales pendientes
- ⏳ Implementación de features pendiente

## Próximos Pasos

1. Instalar Pinia para estado global
2. Instalar TailwindCSS para estilos
3. Crear servicios de API
4. Implementar sistema de autenticación
5. Desarrollar componentes base
6. Crear páginas principales
