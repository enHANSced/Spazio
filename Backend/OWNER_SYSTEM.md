# Sistema de Roles Owner - Implementación Completa

## 📋 Resumen de Cambios

Implementación del sistema de doble rol (user/owner) con aprobación administrativa para cuentas owner.

## 🎯 Arquitectura del Sistema

### Roles del Sistema
- **user**: Puede reservar espacios (no puede gestionar espacios)
- **owner**: Gestiona espacios propios (NO puede reservar, es una empresa)
- **admin**: Control total + aprobación de owners

### Flujo de Aprobación
1. Owner se registra con datos de negocio (`businessName`, `businessDescription`)
2. Cuenta queda con `isVerified: false`
3. Admin aprueba/rechaza desde `/api/users/:id/verify`
4. Solo owners verificados pueden crear/gestionar espacios

## 🗄️ Cambios en Base de Datos

### MySQL - Tabla `users`
```sql
role ENUM('user', 'owner', 'admin')  -- Agregado 'owner'
isVerified BOOLEAN DEFAULT TRUE      -- Para aprobación de owners
businessName VARCHAR(150) NULL       -- Nombre del negocio
businessDescription TEXT NULL        -- Descripción del negocio
```

### MySQL - Tabla `spaces`
```sql
ownerId CHAR(36) NOT NULL           -- FK a users.id
FOREIGN KEY (ownerId) REFERENCES users(id) ON DELETE CASCADE
INDEX idx_spaces_owner (ownerId)
```

### Índices Agregados
- `idx_spaces_owner` → Optimiza consultas de espacios por owner
- `idx_users_role_verified` → Optimiza filtrado de owners verificados

## 🔐 Middleware Creados

### `/src/middleware/role.middleware.js`
```javascript
isOwner              // Verifica que sea owner o admin
isVerifiedOwner      // Verifica que owner esté aprobado
isOwnerOrAdmin       // Permite owner O admin
isResourceOwner      // Verifica propiedad del recurso
```

## 🛣️ Nuevos Endpoints

### Gestión de Usuarios (`/api/users`)
```
GET    /api/users/me                    → Perfil del usuario autenticado
PUT    /api/users/me                    → Actualizar perfil
GET    /api/users                       → [ADMIN] Listar usuarios (con filtros)
GET    /api/users/pending-owners        → [ADMIN] Owners pendientes
GET    /api/users/:id                   → [ADMIN] Ver usuario
PATCH  /api/users/:id/verify            → [ADMIN] Aprobar/rechazar owner
```

### Espacios Actualizados (`/api/spaces`)
```
GET    /api/spaces                      → Público (ahora incluye owner info)
GET    /api/spaces/:id                  → Público (ahora incluye owner info)
GET    /api/spaces/owner/my-spaces      → [OWNER] Mis espacios
POST   /api/spaces                      → [OWNER] Crear espacio
PUT    /api/spaces/:id                  → [OWNER] Actualizar (solo propios)
DELETE /api/spaces/:id                  → [OWNER] Eliminar (solo propios)
```

### Reservas Actualizadas (`/api/bookings`)
```
GET    /api/bookings/owner/bookings     → [OWNER] Reservas de mis espacios
POST   /api/bookings                    → [USER] Crear (owners bloqueados)
```

## 📝 Validaciones de Negocio

### Registro de Owner
- Requiere `businessName` (2-150 chars)
- `businessDescription` opcional (max 1000 chars)
- Se crea con `isVerified: false`

### Creación de Espacios
- Solo owners verificados (`isVerified: true`)
- `ownerId` se inyecta automáticamente desde JWT
- Owners solo pueden editar/eliminar sus propios espacios

### Restricción de Reservas
- **Owners NO pueden crear reservas**
- Error: "Los propietarios no pueden realizar reservas. Crea una cuenta de usuario."
- Validación en `BookingsUseCase.create()`

## 🌱 Datos de Seed Actualizados

### Usuarios Creados
```javascript
admin@spazio.com / admin123           // Admin
user@spazio.com / user123             // Usuario normal

// Owners verificados
owner1@spazio.com / owner123          // CoWork Central (2 espacios)
owner2@spazio.com / owner123          // Salas Premium (2 espacios)

// Owner pendiente
pending@spazio.com / pending123       // Espacios Creativos (sin verificar)
```

### Espacios Asignados
- **Sala de Reuniones A** → owner1 (CoWork Central)
- **Sala de Conferencias** → owner2 (Salas Premium)
- **Sala de Capacitación** → owner1 (CoWork Central)
- **Espacio de Coworking** → owner2 (Salas Premium)

## 🔧 Archivos Modificados

### Entidades
- ✅ `entities/User.js` → Campos owner + asociación con Space
- ✅ `entities/Space.js` → Campo ownerId + asociación con User

### Middleware
- ✅ `middleware/auth.middleware.js` → Mejoras en verificación
- ✨ `middleware/role.middleware.js` → NUEVO

### Use Cases
- ✅ `use-cases/auth.usecase.js` → Registro con rol owner
- ✅ `use-cases/spaces.usecase.js` → Validación de owner + `findByOwner()`
- ✅ `use-cases/bookings.usecase.js` → Bloqueo owners + `getOwnerBookings()`
- ✨ `use-cases/users.usecase.js` → NUEVO (gestión de usuarios)

### Controllers
- ✅ `controllers/spaces.controller.js` → Método `getMySpaces()`
- ✅ `controllers/bookings.controller.js` → Método `getOwnerBookings()`
- ✨ `controllers/users.controller.js` → NUEVO

### Rutas
- ✅ `routes/spaces.routes.js` → Protección por rol + owner routes
- ✅ `routes/bookings.routes.js` → Endpoint owner bookings
- ✨ `routes/users.routes.js` → NUEVO
- ✅ `index.js` → Registro de `/api/users`

### Validadores
- ✅ `validators/auth.validators.js` → Validación de campos owner

### Seed & Migración
- ✅ `seed.js` → Usuarios owner + espacios con ownerId
- ✨ `migration_owner_system.sql` → NUEVO
- ✨ `migrate.sh` → Script automatizado

## 🚀 Pasos para Aplicar los Cambios

### 1. Ejecutar Migración SQL
```bash
cd Backend
./migrate.sh
# O manualmente:
mysql -u root -p spazio_db < migration_owner_system.sql
```

### 2. Ejecutar Seed
```bash
npm run seed
```

### 3. Iniciar Servidor
```bash
npm run dev
```

## 🧪 Pruebas Recomendadas

### 1. Registro de Owner
```bash
curl -X POST http://localhost:3001/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Owner",
    "email": "testowner@test.com",
    "password": "Test123",
    "role": "owner",
    "businessName": "Test Business",
    "businessDescription": "Test description"
  }'
```

### 2. Login de Owner
```bash
curl -X POST http://localhost:3001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "owner1@spazio.com",
    "password": "owner123"
  }'
```

### 3. Crear Espacio (Owner)
```bash
curl -X POST http://localhost:3001/api/spaces \
  -H "Authorization: Bearer <TOKEN_OWNER>" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Nueva Sala",
    "description": "Descripción",
    "capacity": 15
  }'
```

### 4. Ver Mis Espacios (Owner)
```bash
curl -X GET http://localhost:3001/api/spaces/owner/my-spaces \
  -H "Authorization: Bearer <TOKEN_OWNER>"
```

### 5. Ver Reservas de Mis Espacios (Owner)
```bash
curl -X GET http://localhost:3001/api/bookings/owner/bookings \
  -H "Authorization: Bearer <TOKEN_OWNER>"
```

### 6. Intentar Reservar como Owner (Debe fallar)
```bash
curl -X POST http://localhost:3001/api/bookings \
  -H "Authorization: Bearer <TOKEN_OWNER>" \
  -H "Content-Type: application/json" \
  -d '{
    "spaceId": "<SPACE_UUID>",
    "startTime": "2025-11-10T10:00:00Z",
    "endTime": "2025-11-10T12:00:00Z"
  }'
# Debe retornar error: "Los propietarios no pueden realizar reservas..."
```

### 7. Aprobar Owner Pendiente (Admin)
```bash
curl -X PATCH http://localhost:3001/api/users/<OWNER_ID>/verify \
  -H "Authorization: Bearer <TOKEN_ADMIN>" \
  -H "Content-Type: application/json" \
  -d '{"isVerified": true}'
```

### 8. Ver Owners Pendientes (Admin)
```bash
curl -X GET http://localhost:3001/api/users/pending-owners \
  -H "Authorization: Bearer <TOKEN_ADMIN>"
```

## 🎨 Próximos Pasos: Frontend Web

### Layouts Necesarios
- **default.vue** → Para users (explorar + reservar)
- **owner.vue** → Para owners (dashboard de gestión)
- **admin.vue** → Para admins (aprobaciones + métricas)

### Páginas Principales

#### Para Users
- `/spaces` → Explorar espacios disponibles
- `/spaces/:id` → Detalle + calendario de reserva
- `/my-bookings` → Mis reservas

#### Para Owners
- `/owner/dashboard` → Resumen + estadísticas
- `/owner/spaces` → Gestión de mis espacios
- `/owner/spaces/create` → Crear nuevo espacio
- `/owner/spaces/:id/edit` → Editar espacio
- `/owner/bookings` → Reservas de mis espacios

#### Para Admins
- `/admin/dashboard` → Panel de control
- `/admin/pending-owners` → Aprobaciones pendientes
- `/admin/users` → Gestión de usuarios
- `/admin/spaces` → Ver todos los espacios

## 📊 Estadísticas del Sistema

### Archivos Creados: 5
- `middleware/role.middleware.js`
- `use-cases/users.usecase.js`
- `controllers/users.controller.js`
- `routes/users.routes.js`
- `migration_owner_system.sql`
- `migrate.sh`

### Archivos Modificados: 11
- `entities/User.js`
- `entities/Space.js`
- `middleware/auth.middleware.js`
- `use-cases/auth.usecase.js`
- `use-cases/spaces.usecase.js`
- `use-cases/bookings.usecase.js`
- `controllers/spaces.controller.js`
- `controllers/bookings.controller.js`
- `routes/spaces.routes.js`
- `routes/bookings.routes.js`
- `validators/auth.validators.js`
- `seed.js`
- `index.js`

### Endpoints Agregados: 9
- `GET /api/users/me`
- `PUT /api/users/me`
- `GET /api/users`
- `GET /api/users/pending-owners`
- `GET /api/users/:id`
- `PATCH /api/users/:id/verify`
- `GET /api/spaces/owner/my-spaces`
- `GET /api/bookings/owner/bookings`

## ⚠️ Consideraciones Importantes

1. **Migración SQL es obligatoria** antes de ejecutar el seed
2. **Espacios existentes** necesitan asignarse a un owner manualmente
3. **Reservas existentes** seguirán funcionando normalmente
4. **Admin puede gestionar** todos los espacios (bypass de permisos)
5. **Owner pendiente** puede login pero NO puede crear espacios

## 🔒 Seguridad

- ✅ Owners solo pueden modificar sus propios espacios
- ✅ Owners NO pueden reservar (roles exclusivos)
- ✅ Verificación obligatoria para crear espacios
- ✅ Admin puede revocar verificación en cualquier momento
- ✅ Validación de propiedad en cada operación CRUD de espacios
