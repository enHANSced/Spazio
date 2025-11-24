# Guía de Prueba Rápida - Sistema de Reservas

Este documento te guía para probar el sistema completo de autenticación, espacios y reservas.

## Requisitos Previos
- Servidor corriendo: `npm run dev`
- MySQL y MongoDB activos
- Cliente HTTP (curl, Postman, Thunder Client, etc.)

## Flujo de Prueba Completo

### 1. Registrar un usuario administrador
```bash
curl -X POST http://localhost:3001/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Admin User",
    "email": "admin@spazio.com",
    "password": "admin123"
  }'
```

**Respuesta esperada:**
```json
{
  "success": true,
  "message": "Usuario registrado exitosamente",
  "data": {
    "user": { "id": "uuid-aqui", "name": "Admin User", "email": "admin@spazio.com", "role": "user" },
    "token": "eyJhbGc..."
  }
}
```

⚠️ **Importante**: Guarda el `token` para usarlo en las siguientes peticiones.

### 2. Actualizar el usuario a rol admin (directo en MySQL)
```sql
-- Conectar a MySQL
mysql -u root -p spazio_db

-- Actualizar rol a admin
UPDATE users SET role = 'admin' WHERE email = 'admin@spazio.com';
```

### 3. Crear espacios (como admin)
```bash
# Reemplaza YOUR_TOKEN con el token del paso 1
curl -X POST http://localhost:3001/api/spaces \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "name": "Sala de Reuniones A",
    "description": "Sala con proyector y pizarra",
    "capacity": 10
  }'
```

```bash
curl -X POST http://localhost:3001/api/spaces \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "name": "Sala de Conferencias",
    "description": "Sala grande para eventos",
    "capacity": 50
  }'
```

**Respuesta esperada:**
```json
{
  "success": true,
  "message": "Espacio creado",
  "data": { "id": "uuid-del-espacio", "name": "Sala de Reuniones A", ... }
}
```

⚠️ **Importante**: Guarda el `id` del espacio para crear reservas.

### 4. Listar espacios disponibles (público)
```bash
curl http://localhost:3001/api/spaces
```

### 5. Crear una reserva
```bash
# Reemplaza YOUR_TOKEN y SPACE_ID
curl -X POST http://localhost:3001/api/bookings \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "spaceId": "SPACE_ID",
    "startTime": "2025-11-05T10:00:00Z",
    "endTime": "2025-11-05T12:00:00Z",
    "notes": "Reunión de equipo"
  }'
```

**Respuesta esperada:**
```json
{
  "success": true,
  "message": "Reserva creada exitosamente",
  "data": {
    "_id": "mongodb-id",
    "spaceId": "uuid",
    "userId": "uuid",
    "startTime": "2025-11-05T10:00:00.000Z",
    "endTime": "2025-11-05T12:00:00.000Z",
    "status": "confirmed",
    "space": { "id": "...", "name": "Sala de Reuniones A", "capacity": 10 },
    "user": { "id": "...", "name": "Admin User", "email": "admin@spazio.com" }
  }
}
```

### 6. Intentar crear reserva solapada (debe fallar)
```bash
# Mismo espacio, hora solapada
curl -X POST http://localhost:3001/api/bookings \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "spaceId": "SPACE_ID",
    "startTime": "2025-11-05T11:00:00Z",
    "endTime": "2025-11-05T13:00:00Z",
    "notes": "Esto debería fallar"
  }'
```

**Respuesta esperada (ERROR 409):**
```json
{
  "success": false,
  "message": "El espacio no está disponible en el horario seleccionado"
}
```

### 7. Ver mis reservas
```bash
curl http://localhost:3001/api/bookings/my-bookings \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### 8. Ver calendario de un espacio
```bash
curl "http://localhost:3001/api/bookings/space/SPACE_ID?startDate=2025-11-01&endDate=2025-11-30" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### 9. Cancelar una reserva
```bash
curl -X DELETE http://localhost:3001/api/bookings/BOOKING_ID \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## Casos de Prueba Importantes

### ✅ Validaciones que debes probar:

1. **Double-booking prevention**
   - Crear reserva de 10:00-12:00
   - Intentar crear otra de 11:00-13:00 (solapamiento) → Debe fallar

2. **Reservas en el pasado**
   - Intentar crear reserva con `startTime` en el pasado → Debe fallar

3. **EndTime antes de StartTime**
   - `startTime: 12:00, endTime: 10:00` → Debe fallar

4. **Espacio inexistente**
   - Usar `spaceId` que no existe → Debe fallar

5. **Sin autenticación**
   - Crear reserva sin token → Debe devolver 401

6. **Usuario normal intentando crear espacio**
   - Sin rol admin → Debe devolver 403

## Verificación en Base de Datos

### MySQL (espacios y usuarios)
```sql
SELECT * FROM spaces;
SELECT id, name, email, role FROM users;
```

### MongoDB (reservas)
```bash
# Conectar a MongoDB
mongosh

use spazio_db
db.bookings.find().pretty()
```

## Health Check
```bash
curl http://localhost:3001/health
```

## Próximos pasos para frontend
Con estos endpoints, el frontend (Web/Móvil) puede:
- Mostrar galería de espacios
- Renderizar calendario con reservas existentes
- Crear nuevas reservas con drag-and-drop
- Validar disponibilidad en tiempo real
- Mostrar "Mis Reservas" del usuario
