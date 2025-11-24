# Validaciones - Sistema de Reservas Spazio

Este documento describe todas las validaciones implementadas con `express-validator` en la API.

## 📋 Índice
- [Validaciones de Autenticación](#validaciones-de-autenticación)
- [Validaciones de Espacios](#validaciones-de-espacios)
- [Validaciones de Reservas](#validaciones-de-reservas)
- [Formato de Errores](#formato-de-errores)
- [Ejemplos de Respuestas](#ejemplos-de-respuestas)

---

## Validaciones de Autenticación

### POST /api/auth/register

| Campo | Validaciones |
|-------|-------------|
| `name` | • Requerido<br>• 2-100 caracteres<br>• Solo letras y espacios<br>• Se elimina espacios en blanco al inicio/final |
| `email` | • Requerido<br>• Formato de email válido<br>• Máximo 100 caracteres<br>• Se normaliza (lowercase) |
| `password` | • Requerido<br>• 6-50 caracteres<br>• Debe contener al menos una minúscula y una mayúscula o número |

**Ejemplo válido:**
```json
{
  "name": "Juan Pérez",
  "email": "juan@example.com",
  "password": "Pass123"
}
```

**Errores comunes:**
```json
{
  "success": false,
  "message": "Errores de validación",
  "errors": [
    {
      "field": "name",
      "message": "El nombre debe tener entre 2 y 100 caracteres",
      "value": "J"
    },
    {
      "field": "email",
      "message": "Debe ser un email válido",
      "value": "invalid-email"
    },
    {
      "field": "password",
      "message": "La contraseña debe contener al menos una letra minúscula y una mayúscula o número",
      "value": "pass"
    }
  ]
}
```

### POST /api/auth/login

| Campo | Validaciones |
|-------|-------------|
| `email` | • Requerido<br>• Formato de email válido |
| `password` | • Requerido |

---

## Validaciones de Espacios

### POST /api/spaces

| Campo | Validaciones |
|-------|-------------|
| `name` | • Requerido<br>• 3-120 caracteres<br>• Se elimina espacios en blanco |
| `description` | • Opcional<br>• Máximo 1000 caracteres |
| `capacity` | • Requerido<br>• Entero entre 1 y 10,000 |

**Ejemplo válido:**
```json
{
  "name": "Sala de Reuniones A",
  "description": "Sala con proyector y pizarra",
  "capacity": 10
}
```

### PUT /api/spaces/:id

| Campo | Validaciones |
|-------|-------------|
| `id` (param) | • Debe ser UUID válido |
| `name` | • Opcional<br>• 3-120 caracteres |
| `description` | • Opcional<br>• Máximo 1000 caracteres |
| `capacity` | • Opcional<br>• Entero entre 1 y 10,000 |
| `isActive` | • Opcional<br>• Booleano (true/false) |

### GET/DELETE /api/spaces/:id

| Campo | Validaciones |
|-------|-------------|
| `id` (param) | • Debe ser UUID válido |

---

## Validaciones de Reservas

### POST /api/bookings

| Campo | Validaciones |
|-------|-------------|
| `spaceId` | • Requerido<br>• UUID válido |
| `startTime` | • Requerido<br>• Formato ISO 8601<br>• No puede ser en el pasado |
| `endTime` | • Requerido<br>• Formato ISO 8601<br>• Debe ser posterior a startTime<br>• Duración mínima: 30 minutos<br>• Duración máxima: 24 horas |
| `notes` | • Opcional<br>• Máximo 500 caracteres |

**Ejemplo válido:**
```json
{
  "spaceId": "550e8400-e29b-41d4-a716-446655440000",
  "startTime": "2025-11-05T10:00:00Z",
  "endTime": "2025-11-05T12:00:00Z",
  "notes": "Reunión de equipo"
}
```

**Errores comunes:**
```json
{
  "success": false,
  "message": "Errores de validación",
  "errors": [
    {
      "field": "spaceId",
      "message": "ID de espacio inválido",
      "value": "invalid-uuid"
    },
    {
      "field": "startTime",
      "message": "No se pueden crear reservas en el pasado",
      "value": "2025-01-01T10:00:00Z"
    },
    {
      "field": "endTime",
      "message": "La hora de fin debe ser posterior a la hora de inicio",
      "value": "2025-11-05T09:00:00Z"
    }
  ]
}
```

### GET /api/bookings/space/:spaceId

| Campo | Validaciones |
|-------|-------------|
| `spaceId` (param) | • Requerido<br>• UUID válido |
| `startDate` (query) | • Requerido<br>• Formato ISO 8601 |
| `endDate` (query) | • Requerido<br>• Formato ISO 8601<br>• Debe ser posterior a startDate<br>• Rango máximo: 6 meses |

**Ejemplo válido:**
```
GET /api/bookings/space/550e8400-e29b-41d4-a716-446655440000?startDate=2025-11-01&endDate=2025-11-30
```

### GET /api/bookings/my-bookings

| Campo | Validaciones |
|-------|-------------|
| `startDate` (query) | • Opcional<br>• Formato ISO 8601 |
| `endDate` (query) | • Opcional<br>• Formato ISO 8601<br>• Debe ser posterior a startDate |

**Ejemplo válido:**
```
GET /api/bookings/my-bookings?startDate=2025-11-01&endDate=2025-11-30
```

### GET/DELETE /api/bookings/:id

| Campo | Validaciones |
|-------|-------------|
| `id` (param) | • Debe ser MongoDB ObjectId válido |

---

## Formato de Errores

Todos los errores de validación devuelven un código HTTP **400 Bad Request** con el siguiente formato:

```json
{
  "success": false,
  "message": "Errores de validación",
  "errors": [
    {
      "field": "nombre_del_campo",
      "message": "Descripción del error",
      "value": "valor_proporcionado"
    }
  ]
}
```

### Campos del Error

- **field**: Nombre del campo que falló la validación
- **message**: Mensaje descriptivo del error
- **value**: Valor que fue proporcionado (puede estar ausente en algunos casos)

---

## Ejemplos de Respuestas

### ✅ Validación Exitosa (sin errores)
La petición pasa al controlador normalmente y devuelve:
```json
{
  "success": true,
  "message": "...",
  "data": { ... }
}
```

### ❌ Error de Validación Único
```json
{
  "success": false,
  "message": "Errores de validación",
  "errors": [
    {
      "field": "email",
      "message": "Debe ser un email válido",
      "value": "not-an-email"
    }
  ]
}
```

### ❌ Múltiples Errores de Validación
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
      "message": "La contraseña debe tener entre 6 y 50 caracteres",
      "value": "123"
    }
  ]
}
```

### ❌ Error de Tipo de Dato
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

### ❌ Error de Formato de Fecha
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

### ❌ Error de Lógica de Negocio en Validador
```json
{
  "success": false,
  "message": "Errores de validación",
  "errors": [
    {
      "field": "endTime",
      "message": "La reserva debe ser de al menos 30 minutos",
      "value": "2025-11-05T10:15:00Z"
    }
  ]
}
```

---

## Validaciones Adicionales en Casos de Uso

Además de las validaciones de formato con `express-validator`, los casos de uso implementan validaciones de lógica de negocio:

### Autenticación
- ✅ Email no duplicado (registro)
- ✅ Credenciales válidas (login)
- ✅ Usuario activo

### Espacios
- ✅ Nombre único
- ✅ Espacio existe (para update/delete)
- ✅ Espacio activo

### Reservas
- ✅ Espacio existe y está activo
- ✅ Usuario existe y está activo
- ✅ **No solapamiento** con otras reservas (double-booking prevention)
- ✅ Permisos de usuario (solo dueño puede ver/cancelar)

Estas validaciones devuelven códigos HTTP diferentes:
- **400**: Error de validación de formato
- **401**: No autenticado
- **403**: Sin permisos
- **404**: Recurso no encontrado
- **409**: Conflicto (ej: double-booking, email duplicado)

---

## Formatos de Fecha Aceptados

### ISO 8601 (Recomendado)
```
2025-11-05T10:00:00Z          # UTC
2025-11-05T10:00:00-06:00     # Con zona horaria
2025-11-05                     # Solo fecha
```

### Ejemplos NO válidos
```
05/11/2025                     # Formato DD/MM/YYYY
11-05-2025                     # Guiones invertidos
2025-11-05 10:00:00           # Espacio en lugar de 'T'
```

---

## Testing de Validaciones

### Con cURL
```bash
# Error de validación: email inválido
curl -X POST http://localhost:3001/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test",
    "email": "invalid-email",
    "password": "Test123"
  }'
```

### Con Postman/Thunder Client
1. Crear petición con datos inválidos
2. Verificar código de respuesta 400
3. Revisar campo `errors` en la respuesta

---

## Tips de Desarrollo

1. **Siempre envía todos los campos requeridos**: Los validadores rechazan peticiones incompletas
2. **Usa formato ISO 8601 para fechas**: Es el estándar internacional
3. **Revisa el array de errores**: Puede contener múltiples validaciones fallidas
4. **Los espacios se eliminan automáticamente**: En campos como `name`, `email`, etc.
5. **El email se normaliza a lowercase**: `Test@Email.COM` → `test@email.com`

---

## Personalización

Si necesitas agregar nuevas validaciones, edita los archivos en `src/validators/`:
- `auth.validators.js` - Validaciones de autenticación
- `spaces.validators.js` - Validaciones de espacios
- `bookings.validators.js` - Validaciones de reservas

Y asegúrate de importarlas en las rutas correspondientes.
