# Sistema de Reservas con Gestión de Pagos - Spazio

## 📋 Resumen de Implementación

Se ha implementado un sistema completo de reservas con gestión de pagos simulados para la plataforma Spazio. Los usuarios ahora pueden:

1. **Reservar espacios** con selección de fecha, hora y duración
2. **Gestionar sus reservas** (ver, cancelar, reprogramar)
3. **Simular pagos** con diferentes métodos (efectivo, tarjeta, transferencia)
4. **Pagar inmediatamente o más tarde** antes del día de la reserva

---

## 🎯 Funcionalidades Implementadas

### 1. Reserva de Espacios (`/spaces/[id]`)

**Características:**
- Modal de confirmación de reserva con:
  - Selección de fecha y hora
  - Duración configurable (1-24 horas)
  - Resumen de precios (subtotal + tarifa de servicio)
  - Selección de método de pago (efectivo, tarjeta, transferencia)
  - Opción de pagar ahora o más tarde
- Cálculo automático de precios:
  - Precio por hora según capacidad del espacio
  - Tarifa de servicio del 8%
  - Total en Lempiras (HNL)
- Validaciones:
  - Fecha y hora obligatorias
  - No permite reservas en el pasado
  - Duración mínima de 1 hora, máxima de 24 horas

### 2. Gestión de Reservas (`/bookings`)

**Características:**
- Vista de todas las reservas del usuario
- Filtros por estado (pendiente, confirmada, cancelada)
- Búsqueda por nombre o dirección del espacio
- Tarjetas estadísticas con contadores
- Agrupación de reservas:
  - **Próximas:** Reservas futuras activas
  - **Pasadas:** Reservas completadas o canceladas
- Acciones disponibles:
  - Ver detalles
  - Cancelar (solo reservas futuras)
  - Reprogramar (solo reservas futuras)

### 3. Detalle de Reserva (`/bookings/[id]`)

**Características:**
- Información completa de la reserva:
  - Estado visual (confirmada, pendiente, cancelada)
  - Detalles del espacio
  - Fecha y horario
  - Información de pago
- Opciones de gestión:
  - **Cancelar reserva:** Con confirmación modal
  - **Reprogramar:** Crea nueva reserva y permite cancelar la anterior
  - **Pagar ahora:** Modal para procesar pago simulado
- Desglose de pago:
  - Precio por hora
  - Duración
  - Subtotal
  - Tarifa de servicio
  - Total
  - Estado del pago
  - Método de pago

### 4. Navegación Mejorada

**Características:**
- Header actualizado con:
  - Logo de Spazio
  - Menú de navegación (Explorar, Mis Reservas)
  - Información del usuario autenticado
  - Botón de cerrar sesión
- Footer con información básica

---

## 🗄️ Cambios en el Backend

### Modelo de Booking (`Backend/src/entities/Booking.js`)

**Nuevos campos:**
```javascript
{
  // Campos de pago
  paymentMethod: 'cash' | 'card' | 'transfer',
  paymentStatus: 'pending' | 'paid' | 'refunded',
  totalAmount: Number,
  subtotal: Number,
  serviceFee: Number,
  pricePerHour: Number,
  durationHours: Number,
  paidAt: Date
}
```

### Use Case de Bookings (`Backend/src/use-cases/bookings.usecase.js`)

**Métodos actualizados:**
- `create()`: Acepta campos de pago
- `enrichBooking()`: Incluye más información del espacio
- **Nuevo:** `update()`: Permite actualizar campos de la reserva

### Controller y Rutas

**Nueva ruta:**
- `PATCH /api/bookings/:id` - Actualizar reserva

---

## 💻 Cambios en el Frontend

### Tipos (`Web/app/types/booking.ts`)

**Tipos agregados:**
```typescript
export type PaymentMethod = 'cash' | 'card' | 'transfer'
export type PaymentStatus = 'pending' | 'paid' | 'refunded'

interface Booking {
  // ... campos existentes
  paymentMethod?: PaymentMethod
  paymentStatus?: PaymentStatus
  totalAmount?: number
  subtotal?: number
  serviceFee?: number
  pricePerHour?: number
  durationHours?: number
  paidAt?: string
}
```

### Servicios (`Web/app/services/bookings.service.ts`)

**Métodos actualizados:**
- `create()`: Acepta campos de pago
- **Nuevo:** `updatePayment()`: Actualizar información de pago
- **Nuevo:** `update()`: Actualizar reserva general

### Páginas creadas/actualizadas

1. **`/spaces/[id].vue`** - Modal de reserva implementado
2. **`/bookings/index.vue`** - Gestión de reservas (NUEVA)
3. **`/bookings/[id].vue`** - Detalle de reserva (NUEVA)
4. **`/layouts/default.vue`** - Navegación mejorada

---

## 🎨 Interfaz de Usuario

### Diseño
- Diseño moderno con Tailwind CSS
- Iconos Material Symbols
- Transiciones y animaciones suaves
- Responsive design (mobile, tablet, desktop)

### Estados visuales
- **Confirmada:** Verde
- **Pendiente:** Amarillo
- **Cancelada:** Rojo
- **Pago completado:** Verde
- **Pago pendiente:** Amarillo

### Modales
- Modal de confirmación de reserva
- Modal de cancelación
- Modal de reprogramación
- Modal de pago

---

## 🔄 Flujo de Usuario

### Crear una Reserva

1. Usuario navega a `/spaces/[id]`
2. Selecciona fecha, hora y duración
3. Hace clic en "Confirmar reserva"
4. Se abre modal con:
   - Resumen de reserva
   - Selección de método de pago
   - Opción de pagar ahora o después
5. Confirma y se crea la reserva
6. Redirección automática a `/bookings`

### Gestionar Reservas

1. Usuario navega a `/bookings`
2. Ve listado de todas sus reservas
3. Puede filtrar por estado o buscar
4. Hacer clic en una reserva para ver detalles
5. Desde el detalle puede:
   - Cancelar (si es futura)
   - Reprogramar (si es futura)
   - Pagar (si está pendiente)

### Pagar una Reserva

1. Usuario navega a `/bookings/[id]`
2. Si el pago está pendiente, ve botón "Pagar ahora"
3. Se abre modal con:
   - Total a pagar
   - Selección de método de pago
   - Nota de simulación
4. Confirma el pago
5. Estado cambia a "Pagado"

### Reprogramar una Reserva

1. Usuario navega a `/bookings/[id]`
2. Hace clic en "Reprogramar"
3. Se abre modal con:
   - Nueva fecha
   - Nueva hora
   - Nueva duración
4. Confirma la reprogramación
5. Se crea nueva reserva
6. Opción de cancelar la reserva anterior

---

## ⚠️ Notas Importantes

### Pagos Simulados

El sistema de pagos es completamente **simulado** para propósitos de demostración:
- No se procesan pagos reales
- No se requiere información de tarjeta
- Los estados de pago se actualizan instantáneamente
- Se muestra mensaje claro al usuario sobre la simulación

### Validaciones

**Frontend:**
- Fecha y hora obligatorias
- Duración entre 1 y 24 horas
- No permite fechas pasadas

**Backend:**
- Verificación de disponibilidad (previene double-booking)
- Validación de fechas
- Owners no pueden hacer reservas
- Solo el propietario puede modificar su reserva

### Precios

Los precios están calculados según la capacidad del espacio:
- Hasta 10 personas: L 300/hora
- 11-20 personas: L 500/hora
- 21-40 personas: L 800/hora
- 41-80 personas: L 1,500/hora
- Más de 80: L 2,500/hora

Tarifa de servicio: 8% del subtotal

---

## 🚀 Próximos Pasos Sugeridos

1. **Notificaciones:**
   - Email cuando se confirma una reserva
   - Email recordatorio 24h antes
   - Notificaciones push en la app móvil

2. **Pagos reales:**
   - Integración con pasarela de pagos (Stripe, PayPal)
   - Sistema de reembolsos
   - Historial de transacciones

3. **Calendario interactivo:**
   - Vista de calendario para seleccionar fechas
   - Visualización de disponibilidad en tiempo real
   - Sincronización con Google Calendar

4. **Sistema de reseñas:**
   - Usuarios pueden calificar espacios después de usarlos
   - Owners pueden responder a reseñas
   - Filtros por calificación

5. **Chat en tiempo real:**
   - Comunicación directa usuario-propietario
   - Notificaciones de mensajes
   - Historial de conversaciones

---

## 📱 Pruebas Recomendadas

1. **Crear una reserva completa:**
   - Seleccionar espacio
   - Configurar fecha/hora/duración
   - Elegir método de pago
   - Confirmar reserva

2. **Gestión de reservas:**
   - Ver listado de reservas
   - Filtrar por estado
   - Buscar por nombre/dirección

3. **Detalle de reserva:**
   - Ver información completa
   - Cancelar reserva
   - Reprogramar reserva
   - Simular pago

4. **Navegación:**
   - Probar menú de navegación
   - Verificar responsive design
   - Probar logout

---

## 🐛 Manejo de Errores

El sistema maneja diversos errores:
- Espacios no disponibles (conflicto de horarios)
- Reservas no encontradas
- Permisos insuficientes
- Errores de validación
- Errores de red

Todos los errores se muestran al usuario con mensajes claros y descriptivos.

---

## 🎉 Conclusión

El sistema de reservas está completamente funcional y listo para usar. Los usuarios pueden crear, ver, gestionar y pagar sus reservas de forma intuitiva. El sistema incluye todas las validaciones necesarias y una interfaz moderna y responsive.

El código sigue las convenciones del proyecto:
- Arquitectura limpia en el backend
- Composables y servicios en el frontend
- TypeScript estricto
- Componentes reutilizables
- Manejo consistente de errores
