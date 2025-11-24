# Pruebas de Validación - Ejemplos

Este documento contiene ejemplos específicos para probar las validaciones implementadas con `express-validator`.

## 🧪 Pruebas de Autenticación

### ❌ Error: Email inválido
```bash
curl -X POST http://localhost:3001/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test User",
    "email": "invalid-email",
    "password": "Pass123"
  }'
```

**Respuesta esperada (400):**
```json
{
  "success": false,
  "message": "Errores de validación",
  "errors": [
    {
      "field": "email",
      "message": "Debe ser un email válido",
      "value": "invalid-email"
    }
  ]
}
```

### ❌ Error: Contraseña débil
```bash
curl -X POST http://localhost:3001/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test User",
    "email": "test@example.com",
    "password": "weak"
  }'
```

**Respuesta esperada (400):**
```json
{
  "success": false,
  "message": "Errores de validación",
  "errors": [
    {
      "field": "password",
      "message": "La contraseña debe contener al menos una letra minúscula y una mayúscula o número",
      "value": "weak"
    }
  ]
}
```

### ❌ Error: Nombre con caracteres inválidos
```bash
curl -X POST http://localhost:3001/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test123",
    "email": "test@example.com",
    "password": "Pass123"
  }'
```

**Respuesta esperada (400):**
```json
{
  "success": false,
  "message": "Errores de validación",
  "errors": [
    {
      "field": "name",
      "message": "El nombre solo puede contener letras y espacios",
      "value": "Test123"
    }
  ]
}
```

### ❌ Error: Múltiples campos faltantes
```bash
curl -X POST http://localhost:3001/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{}'
```

**Respuesta esperada (400):**
```json
{
  "success": false,
  "message": "Errores de validación",
  "errors": [
    {
      "field": "name",
      "message": "El nombre es requerido"
    },
    {
      "field": "email",
      "message": "El email es requerido"
    },
    {
      "field": "password",
      "message": "La contraseña es requerida"
    }
  ]
}
```

---

## 🧪 Pruebas de Espacios

### ❌ Error: Capacidad inválida
```bash
TOKEN="your-admin-token"
curl -X POST http://localhost:3001/api/spaces \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "name": "Sala Test",
    "capacity": "not-a-number"
  }'
```

**Respuesta esperada (400):**
```json
{
  "success": false,
  "message": "Errores de validación",
  "errors": [
    {
      "field": "capacity",
      "message": "La capacidad debe ser un número entero entre 1 y 10000",
      "value": "not-a-number"
    }
  ]
}
```

### ❌ Error: Nombre muy corto
```bash
TOKEN="your-admin-token"
curl -X POST http://localhost:3001/api/spaces \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "name": "AB",
    "capacity": 10
  }'
```

**Respuesta esperada (400):**
```json
{
  "success": false,
  "message": "Errores de validación",
  "errors": [
    {
      "field": "name",
      "message": "El nombre debe tener entre 3 y 120 caracteres",
      "value": "AB"
    }
  ]
}
```

### ❌ Error: UUID inválido
```bash
TOKEN="your-admin-token"
curl -X GET http://localhost:3001/api/spaces/invalid-uuid \
  -H "Authorization: Bearer $TOKEN"
```

**Respuesta esperada (400):**
```json
{
  "success": false,
  "message": "Errores de validación",
  "errors": [
    {
      "field": "id",
      "message": "ID de espacio inválido",
      "value": "invalid-uuid"
    }
  ]
}
```

---

## 🧪 Pruebas de Reservas

### ❌ Error: Formato de fecha inválido
```bash
TOKEN="your-token"
SPACE_ID="550e8400-e29b-41d4-a716-446655440000"
curl -X POST http://localhost:3001/api/bookings \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{
    \"spaceId\": \"$SPACE_ID\",
    \"startTime\": \"05/11/2025\",
    \"endTime\": \"05/11/2025\"
  }"
```

**Respuesta esperada (400):**
```json
{
  "success": false,
  "message": "Errores de validación",
  "errors": [
    {
      "field": "startTime",
      "message": "Formato de fecha inválido. Use ISO 8601 (ej: 2025-11-05T10:00:00Z)",
      "value": "05/11/2025"
    }
  ]
}
```

### ❌ Error: Reserva en el pasado
```bash
TOKEN="your-token"
SPACE_ID="550e8400-e29b-41d4-a716-446655440000"
curl -X POST http://localhost:3001/api/bookings \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{
    \"spaceId\": \"$SPACE_ID\",
    \"startTime\": \"2020-01-01T10:00:00Z\",
    \"endTime\": \"2020-01-01T12:00:00Z\"
  }"
```

**Respuesta esperada (400):**
```json
{
  "success": false,
  "message": "Errores de validación",
  "errors": [
    {
      "field": "startTime",
      "message": "No se pueden crear reservas en el pasado",
      "value": "2020-01-01T10:00:00.000Z"
    }
  ]
}
```

### ❌ Error: EndTime antes de StartTime
```bash
TOKEN="your-token"
SPACE_ID="550e8400-e29b-41d4-a716-446655440000"
curl -X POST http://localhost:3001/api/bookings \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{
    \"spaceId\": \"$SPACE_ID\",
    \"startTime\": \"2025-11-05T12:00:00Z\",
    \"endTime\": \"2025-11-05T10:00:00Z\"
  }"
```

**Respuesta esperada (400):**
```json
{
  "success": false,
  "message": "Errores de validación",
  "errors": [
    {
      "field": "endTime",
      "message": "La hora de fin debe ser posterior a la hora de inicio",
      "value": "2025-11-05T10:00:00.000Z"
    }
  ]
}
```

### ❌ Error: Duración muy corta (menos de 30 min)
```bash
TOKEN="your-token"
SPACE_ID="550e8400-e29b-41d4-a716-446655440000"
curl -X POST http://localhost:3001/api/bookings \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{
    \"spaceId\": \"$SPACE_ID\",
    \"startTime\": \"2025-11-05T10:00:00Z\",
    \"endTime\": \"2025-11-05T10:15:00Z\"
  }"
```

**Respuesta esperada (400):**
```json
{
  "success": false,
  "message": "Errores de validación",
  "errors": [
    {
      "field": "endTime",
      "message": "La reserva debe ser de al menos 30 minutos",
      "value": "2025-11-05T10:15:00.000Z"
    }
  ]
}
```

### ❌ Error: Duración muy larga (más de 24 horas)
```bash
TOKEN="your-token"
SPACE_ID="550e8400-e29b-41d4-a716-446655440000"
curl -X POST http://localhost:3001/api/bookings \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{
    \"spaceId\": \"$SPACE_ID\",
    \"startTime\": \"2025-11-05T10:00:00Z\",
    \"endTime\": \"2025-11-07T10:00:00Z\"
  }"
```

**Respuesta esperada (400):**
```json
{
  "success": false,
  "message": "Errores de validación",
  "errors": [
    {
      "field": "endTime",
      "message": "La reserva no puede exceder 24 horas",
      "value": "2025-11-07T10:00:00.000Z"
    }
  ]
}
```

### ❌ Error: Rango de fechas muy amplio (calendario)
```bash
TOKEN="your-token"
SPACE_ID="550e8400-e29b-41d4-a716-446655440000"
curl "http://localhost:3001/api/bookings/space/$SPACE_ID?startDate=2025-01-01&endDate=2026-01-01" \
  -H "Authorization: Bearer $TOKEN"
```

**Respuesta esperada (400):**
```json
{
  "success": false,
  "message": "Errores de validación",
  "errors": [
    {
      "field": "endDate",
      "message": "El rango de fechas no puede exceder 6 meses",
      "value": "2026-01-01T00:00:00.000Z"
    }
  ]
}
```

### ❌ Error: MongoDB ObjectId inválido
```bash
TOKEN="your-token"
curl -X DELETE http://localhost:3001/api/bookings/invalid-objectid \
  -H "Authorization: Bearer $TOKEN"
```

**Respuesta esperada (400):**
```json
{
  "success": false,
  "message": "Errores de validación",
  "errors": [
    {
      "field": "id",
      "message": "ID de reserva inválido",
      "value": "invalid-objectid"
    }
  ]
}
```

---

## ✅ Pruebas Exitosas

### Registro exitoso
```bash
curl -X POST http://localhost:3001/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Juan Pérez",
    "email": "juan@example.com",
    "password": "Pass123"
  }'
```

### Crear espacio exitoso
```bash
TOKEN="your-admin-token"
curl -X POST http://localhost:3001/api/spaces \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "name": "Sala de Reuniones A",
    "description": "Sala equipada",
    "capacity": 10
  }'
```

### Crear reserva exitosa
```bash
TOKEN="your-token"
SPACE_ID="550e8400-e29b-41d4-a716-446655440000"
curl -X POST http://localhost:3001/api/bookings \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{
    \"spaceId\": \"$SPACE_ID\",
    \"startTime\": \"2025-11-05T10:00:00Z\",
    \"endTime\": \"2025-11-05T12:00:00Z\",
    \"notes\": \"Reunión de equipo\"
  }"
```

---

## 🎯 Checklist de Pruebas

### Autenticación
- [ ] Email inválido
- [ ] Contraseña débil
- [ ] Nombre con números
- [ ] Campos faltantes
- [ ] Email muy largo (>100 chars)
- [ ] Registro exitoso

### Espacios
- [ ] Capacidad negativa
- [ ] Capacidad como string
- [ ] Nombre muy corto (<3 chars)
- [ ] Descripción muy larga (>1000 chars)
- [ ] UUID inválido
- [ ] Creación exitosa

### Reservas
- [ ] Formato de fecha inválido
- [ ] Reserva en el pasado
- [ ] EndTime antes de StartTime
- [ ] Duración < 30 minutos
- [ ] Duración > 24 horas
- [ ] Rango de calendario > 6 meses
- [ ] ObjectId inválido
- [ ] Creación exitosa

---

## 📝 Notas

1. Los errores de validación siempre devuelven código **400**
2. Los errores de autenticación devuelven código **401**
3. Los errores de autorización (permisos) devuelven código **403**
4. Los errores de recursos no encontrados devuelven código **404**
5. Los conflictos (double-booking, email duplicado) devuelven código **409**

Ver `VALIDATIONS.md` para la documentación completa de validaciones.
