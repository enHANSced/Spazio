# Spazio Backend - API REST

Backend completo para el sistema de reservas Spazio con arquitectura limpia, validación de disponibilidad y prevención de double-booking.

## ✨ Características Principales

- ✅ **Autenticación JWT** con roles (user, admin)
- ✅ **CRUD completo de Espacios** (MySQL)
- ✅ **Sistema de Reservas** con validación de disponibilidad (MongoDB)
- ✅ **Prevención de double-booking** mediante queries de solapamiento
- ✅ **Arquitectura limpia** (entities, use-cases, controllers, routes)
- ✅ **Bases de datos híbridas** (MySQL + MongoDB)
- ✅ **Seeder de datos** para desarrollo rápido

## 🚀 Configuración Inicial

### 1. Instalar dependencias
```bash
npm install
```

### 2. Configurar variables de entorno
Copia `.env.example` a `.env` y configura tus credenciales:
```bash
cp .env.example .env
```

### 3. Configurar bases de datos

#### MySQL
Crea la base de datos:
```sql
CREATE DATABASE spazio_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

#### MongoDB
Asegúrate de tener MongoDB corriendo en localhost:27017 o actualiza la URI en `.env`

### 4. Iniciar servidor de desarrollo
```bash
npm run dev
```

El servidor estará disponible en `http://localhost:3001`

### 5. (Opcional) Poblar datos de prueba
Para facilitar el desarrollo, puedes ejecutar el seeder que crea:
- Usuario admin (admin@spazio.com / admin123)
- Usuario normal (user@spazio.com / user123)
- 4 espacios de ejemplo
- 2 reservas de ejemplo

```bash
npm run seed
```

### (Opcional) Arrancar sin bases de datos
Si solo quieres probar que el servidor levanta y las rutas básicas sin conectarte a MySQL/MongoDB, puedes usar:

```bash
SKIP_DB=true npm run dev
```

## 📚 Endpoints Disponibles

### Salud del servidor
- `GET /` - Mensaje de bienvenida
- `GET /health` - Estado del servidor

### Autenticación
- `POST /api/auth/register` - Registrar nuevo usuario
  ```json
  {
    "name": "Juan Pérez",
    "email": "juan@example.com",
    "password": "contraseña123"
  }
  ```

- `POST /api/auth/login` - Iniciar sesión
  ```json
  {
    "email": "juan@example.com",
    "password": "contraseña123"
  }
  ```

- `GET /api/auth/profile` - Obtener perfil (requiere token)
  - Header: `Authorization: Bearer <token>`

### Espacios
- `GET /api/spaces` - Listar espacios activos
- `GET /api/spaces/:id` - Obtener un espacio por ID
- `POST /api/spaces` - Crear espacio (admin)
  - Body ejemplo:
  ```json
  {
    "name": "Sala Reuniones A",
    "description": "Sala con proyector",
    "capacity": 10
  }
  ```
- `PUT /api/spaces/:id` - Actualizar espacio (admin)
- `DELETE /api/spaces/:id` - Eliminar espacio (admin, soft-delete)

### Reservas (Bookings)
Todas las rutas requieren autenticación (`Authorization: Bearer <token>`)

- `POST /api/bookings` - Crear nueva reserva
  - Body ejemplo:
  ```json
  {
    "spaceId": "uuid-del-espacio",
    "startTime": "2025-11-05T10:00:00Z",
    "endTime": "2025-11-05T12:00:00Z",
    "notes": "Reunión de equipo"
  }
  ```
  - Validaciones automáticas:
    - ✅ Verifica que el espacio existe y está activo
    - ✅ Previene reservas en el pasado
    - ✅ Valida que endTime > startTime
    - ✅ **Previene double-booking** (verifica solapamiento)

- `GET /api/bookings/my-bookings` - Obtener mis reservas
  - Query params opcionales: `?startDate=2025-11-01&endDate=2025-11-30`

- `GET /api/bookings/space/:spaceId` - Obtener reservas de un espacio (para calendario)
  - Query params requeridos: `?startDate=2025-11-01&endDate=2025-11-30`
  - Útil para renderizar calendario en frontend

- `GET /api/bookings/:id` - Obtener detalle de una reserva
  - Solo el dueño de la reserva puede verla

- `DELETE /api/bookings/:id` - Cancelar reserva
  - El dueño o un admin pueden cancelar
  - Marca status como 'cancelled' (soft-delete)

## 🏗️ Estructura del Proyecto

```
Backend/
├── src/
│   ├── config/           # Configuración de bases de datos
│   ├── entities/         # Modelos de datos (User, Space en MySQL; Booking en MongoDB)
│   ├── use-cases/        # Lógica de negocio
│   ├── controllers/      # Controladores de rutas
│   ├── routes/           # Definición de endpoints
│   ├── middleware/       # Auth, validación
│   └── index.js          # Punto de entrada
├── .env.example          # Variables de entorno ejemplo
└── package.json
```

## 🔐 Autenticación

El sistema usa JWT (JSON Web Tokens). Al hacer login o registro, recibirás un token que debes incluir en las peticiones protegidas:

```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

## 🛠️ Tecnologías

- **Express** - Framework web
- **MySQL + Sequelize** - Base de datos relacional
- **MongoDB + Mongoose** - Base de datos NoSQL
- **JWT** - Autenticación
- **bcryptjs** - Encriptación de contraseñas

## 📝 Próximos Pasos

- [x] Implementar CRUD de Espacios
- [x] Implementar sistema de Reservas con validación
- [ ] Agregar documentación Swagger
- [ ] Implementar logs y auditoría
- [x] Seeders para datos de prueba (admin + espacios)

## 🎯 Características Core Implementadas

### Sistema de Reservas
- ✅ Validación de disponibilidad en tiempo real
- ✅ Prevención de double-booking con query de solapamiento
- ✅ Soft-delete de reservas (status: cancelled)
- ✅ Enriquecimiento automático con datos de espacio y usuario
- ✅ Filtrado por usuario, espacio y rango de fechas
- ✅ Índices optimizados en MongoDB para queries rápidas

### Arquitectura
- ✅ Clean Architecture (entities, use-cases, controllers, routes)
- ✅ Bases de datos híbridas (MySQL para relacional, MongoDB para flexible)
- ✅ Autenticación JWT con roles (user, admin)
- ✅ Middleware de autorización
- ✅ Validaciones de negocio en capa de use-cases
