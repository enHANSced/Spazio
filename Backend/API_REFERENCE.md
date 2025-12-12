# API Endpoints - Referencia Rápida

## Base URL
```
http://localhost:3001
```

## Autenticación

### POST /api/auth/register
Registrar nuevo usuario.
```json
{
  "name": "string",
  "email": "string",
  "password": "string"
}
```

### POST /api/auth/login
Iniciar sesión.
```json
{
  "email": "string",
  "password": "string"
}
```
**Response**: `{ user, token }`

### GET /api/auth/profile
Obtener perfil del usuario autenticado.  
**Auth**: Required

---

## Espacios

### GET /api/spaces
Listar todos los espacios activos.  
**Auth**: No

### GET /api/spaces/:id
Obtener un espacio por ID.  
**Auth**: No

### POST /api/spaces
Crear nuevo espacio.  
**Auth**: Required (Admin)
```json
{
  "name": "string",
  "description": "string",
  "capacity": number
}
```

### PUT /api/spaces/:id
Actualizar espacio.  
**Auth**: Required (Admin)

### DELETE /api/spaces/:id
Eliminar espacio (soft-delete).  
**Auth**: Required (Admin)

---

## Reservas

### POST /api/bookings
Crear nueva reserva.  
**Auth**: Required
```json
{
  "spaceId": "uuid",
  "startTime": "ISO 8601 date",
  "endTime": "ISO 8601 date",
  "notes": "string (opcional)"
}
```
**Validaciones automáticas**:
- Espacio existe y está activo
- Fechas válidas (end > start)
- No en el pasado
- **No solapamiento con otras reservas**

### GET /api/bookings/my-bookings
Obtener reservas del usuario autenticado.  
**Auth**: Required  
**Query params**: `startDate`, `endDate` (opcionales)

### GET /api/bookings/space/:spaceId
Obtener reservas de un espacio (calendario).  
**Auth**: Required  
**Query params**: `startDate`, `endDate` (requeridos)

### GET /api/bookings/:id
Obtener detalle de una reserva.  
**Auth**: Required (solo dueño)

### DELETE /api/bookings/:id
Cancelar reserva.  
**Auth**: Required (dueño o admin)

---

## Reseñas y Calificaciones

### GET /api/reviews/owner/:ownerId/stats
Obtener estadísticas de un propietario (público).
**Response**:
```json
{
  "owner": {
    "id": "uuid",
    "name": "string",
    "businessName": "string | null",
    "isVerified": boolean,
    "memberSince": "ISO date"
  },
  "stats": {
    "spacesCount": number,
    "totalBookings": number,
    "completedBookings": number,
    "totalReviews": number,
    "averageRating": number,
    "ratingDistribution": { "1": n, "2": n, "3": n, "4": n, "5": n }
  }
}
```

### GET /api/reviews/owner/:ownerId
Obtener reseñas de un propietario (público).  
**Query params**: `page`, `limit`

### GET /api/reviews/space/:spaceId/stats
Obtener estadísticas de un espacio (público).

### GET /api/reviews/space/:spaceId
Obtener reseñas de un espacio (público).  
**Query params**: `page`, `limit`

### GET /api/reviews/can-review/:bookingId
Verificar si el usuario puede dejar reseña.  
**Auth**: Required

### GET /api/reviews/my-reviews
Obtener reseñas del usuario autenticado.  
**Auth**: Required  
**Query params**: `page`, `limit`

### POST /api/reviews
Crear nueva reseña.  
**Auth**: Required
```json
{
  "bookingId": "ObjectId",
  "rating": 1-5,
  "comment": "string (opcional, max 1000)"
}
```
**Validaciones**:
- Reserva confirmada y terminada
- Usuario es quien hizo la reserva
- No existe reseña previa para esta reserva

### POST /api/reviews/:reviewId/respond
Propietario responde a una reseña.  
**Auth**: Required (owner verificado)
```json
{
  "response": "string"
}
```

### DELETE /api/reviews/:reviewId
Eliminar reseña (soft-delete).  
**Auth**: Required (autor o admin)

---

## Health Check

### GET /
Mensaje de bienvenida.

### GET /health
Estado del servidor.

---

## Códigos de Respuesta

- `200` - OK
- `201` - Created
- `400` - Bad Request (validación)
- `401` - Unauthorized (sin token o token inválido)
- `403` - Forbidden (sin permisos)
- `404` - Not Found
- `409` - Conflict (double-booking)
- `500` - Internal Server Error

---

## Headers Requeridos

Para endpoints protegidos:
```
Authorization: Bearer <token>
Content-Type: application/json
```

