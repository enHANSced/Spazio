# Spazio - Frontend Web

Frontend web del Sistema de Reservas Inteligente construido con **Nuxt.js 4** + **Vue 3**.

## Stack Tecnológico

- **Framework:** Nuxt.js 4 (Vue 3)
- **Lenguaje:** TypeScript
- **Gestión de Estado:** Pinia (pendiente instalación)
- **UI Library:** TailwindCSS (pendiente instalación)
- **Calendar:** FullCalendar (pendiente instalación)
- **HTTP Client:** useFetch (Nuxt built-in)
- **Autenticación:** JWT + Middleware

## Estructura del Proyecto

```
Web/
├── app/
│   ├── app.vue                 # Componente raíz
│   ├── components/             # Componentes Vue reutilizables
│   ├── composables/            # Funciones Composition API
│   ├── layouts/                # Plantillas de diseño
│   ├── pages/                  # Páginas (routing automático)
│   ├── middleware/             # Middleware de autenticación
│   ├── stores/                 # Estado global (Pinia)
│   ├── services/               # Servicios de API
│   ├── types/                  # Tipos TypeScript
│   └── utils/                  # Funciones utilitarias
├── public/                     # Archivos estáticos
├── .env                        # Variables de entorno
├── nuxt.config.ts              # Configuración de Nuxt
└── package.json                # Dependencias
```

## Configuración Inicial

### 1. Instalar Dependencias

```bash
npm install
```

### 2. Configurar Variables de Entorno

Copia el archivo `.env.example` a `.env` y ajusta las variables:

```bash
cp .env.example .env
```

Variables disponibles:
- `NUXT_PUBLIC_API_BASE_URL`: URL del backend API (default: `http://localhost:3001/api`)
- `NUXT_PUBLIC_APP_NAME`: Nombre de la aplicación
- `NUXT_PUBLIC_APP_VERSION`: Versión de la aplicación

### 3. Asegúrate que el Backend esté corriendo

El backend debe estar corriendo en `http://localhost:3001` antes de iniciar el frontend.

```bash
cd ../Backend
npm run dev
```

## Comandos Disponibles

### Desarrollo

Inicia el servidor de desarrollo en `http://localhost:3000`:

```bash
npm run dev
```

### Producción

Construye la aplicación para producción:

```bash
npm run build
```

Previsualiza el build de producción localmente:

```bash
npm run preview
```

### Type Checking

Ejecuta verificación de tipos TypeScript:

```bash
npm run typecheck
```

## Arquitectura Frontend

### Capas de la Aplicación

```
┌─────────────────────────────────────────┐
│           UI Components                 │  ← Componentes Vue
│         (components/, pages/)           │
├─────────────────────────────────────────┤
│          Composables                    │  ← Lógica reutilizable
│         (composables/)                  │
├─────────────────────────────────────────┤
│         State Management                │  ← Pinia stores
│           (stores/)                     │
├─────────────────────────────────────────┤
│         API Services                    │  ← Servicios HTTP
│          (services/)                    │
├─────────────────────────────────────────┤
│         Backend API                     │  ← Node.js Express
│      (http://localhost:3001)            │
└─────────────────────────────────────────┘
```

### Comunicación con el Backend

- **Endpoint Base:** `http://localhost:3001/api`
- **Autenticación:** JWT en header `Authorization: Bearer <token>`
- **Formato:** JSON para requests y responses

### Usuarios de Prueba (del Backend)

```
Admin:    admin@spazio.com    / admin123
User:     user@spazio.com     / user123
Owner:    owner1@spazio.com   / owner123
```

## Próximos Pasos

1. ⏳ Instalar dependencias adicionales (Pinia, TailwindCSS, FullCalendar)
2. ⏳ Implementar sistema de autenticación
3. ⏳ Crear servicios de API
4. ⏳ Desarrollar componentes UI base
5. ⏳ Implementar páginas principales
6. ⏳ Integrar calendario de reservas

## Documentación

- [Nuxt.js Documentation](https://nuxt.com/docs)
- [Vue 3 Documentation](https://vuejs.org/)
- [TypeScript Documentation](https://www.typescriptlang.org/docs/)

## Estado del Proyecto

- ✅ Proyecto inicializado con Nuxt 4
- ✅ Estructura de carpetas creada
- ✅ Configuración base establecida
- ⏳ Dependencias adicionales pendientes
- ⏳ Implementación de features pendiente
