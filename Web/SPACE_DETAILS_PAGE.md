# Página de Detalles del Espacio - `/spaces/[id]`

## 🎯 Funcionalidad Implementada

Página dinámica completa para ver los detalles de un espacio individual y realizar reservas.

## 📋 Características Principales

### 1. **Información del Espacio**
- ✅ Título destacado con nombre del espacio
- ✅ Capacidad máxima de personas
- ✅ Información del propietario
- ✅ Estado de disponibilidad (badge verde)
- ✅ Descripción completa con fallback automático
- ✅ Botón de "Volver" para navegación fácil

### 2. **Galería de Imágenes**
- ✅ Grid de imágenes (imagen principal + miniaturas)
- ✅ Layout responsivo tipo Airbnb
- ✅ Soporte para imágenes reales o placeholders
- ✅ Imagen principal con placeholder único basado en ID
- ✅ Miniaturas preparadas para galería futura

**Layout:**
- Desktop: Imagen grande (3 columnas) + 2 miniaturas (1 columna)
- Mobile: Solo imagen principal en pantalla completa

### 3. **Panel de Reserva (Sticky)**
- ✅ Precio calculado dinámicamente (basado en capacidad × 15 MXN)
- ✅ Formulario de reserva con:
  - Selector de fecha (`<input type="date">`)
  - Selector de hora (`<input type="time">`)
  - Selector de duración (horas)
- ✅ Cálculo automático del precio:
  - Subtotal = precio por hora × duración
  - Tarifa de servicio = 10% del subtotal
  - Total = subtotal + tarifa de servicio
- ✅ Botón de reserva deshabilitado si faltan datos
- ✅ Mensaje "No se te cobrará nada aún"
- ✅ Desglose detallado del precio

### 4. **Características y Servicios**
Sistema inteligente que muestra amenidades según la capacidad:

| Capacidad | Amenidades Mostradas |
|-----------|---------------------|
| Todas     | Wi-Fi, Aire acondicionado |
| ≥ 8       | + Pizarra blanca |
| ≥ 10      | + Servicio de café |
| ≥ 15      | + Proyector HD |
| ≥ 20      | + Estacionamiento |

### 5. **Información del Propietario**
- ✅ Avatar con icono de tienda
- ✅ Nombre del negocio o propietario
- ✅ Badge de "Propietario verificado"
- ✅ Descripción del negocio (si está disponible)

### 6. **Estados de la Página**

#### **Loading (Pending)**
```
- Skeleton de breadcrumb
- Skeleton de imagen (400px-500px)
- Skeletons de contenido y panel de reserva
```

#### **Error / No encontrado**
```
- Icono de error grande
- Mensaje claro: "Espacio no encontrado"
- Botón para volver a inicio
```

#### **Success**
```
- Contenido completo con todos los datos
- Panel de reserva funcional
- Navegación habilitada
```

## 🎨 Diseño y UX

### **Inspiración**
Basado en el prototipo `detalle_del_espacio_1` con mejoras:
- Grid moderno de imágenes
- Panel de reserva sticky
- Diseño limpio y profesional
- Uso consistente de iconos Material Symbols

### **Paleta de Colores**
- **Primary**: `#137fec`
- **Success**: Verde para disponibilidad
- **Backgrounds**: Blanco con borders grises sutiles
- **Text**: Grises escalonados para jerarquía

### **Typography**
- **Título**: 3xl-4xl, font-black
- **Secciones**: 2xl, font-bold
- **Cuerpo**: base, regular
- **Labels**: xs, font-semibold, uppercase

## 🚀 Navegación

### **Desde Inicio**
```vue
<!-- SpaceCard.vue -->
<NuxtLink :to="`/spaces/${space.id}`">
  Ver detalles
</NuxtLink>
```

### **Volver**
```vue
<button @click="goBack">
  Volver
</button>
```

**Función `goBack()`:**
```typescript
const goBack = () => {
  router.push('/')
}
```

## 💰 Sistema de Precios

### **Cálculo Actual (Sin Backend)**
```typescript
// Precio base según capacidad
pricePerHour = capacity × 15 MXN

// Ejemplo:
// Espacio de 20 personas = 20 × 15 = 300 MXN/hora
// Espacio de 50 personas = 50 × 15 = 750 MXN/hora
```

### **Desglose**
```typescript
subtotal = pricePerHour × bookingHours
serviceFee = Math.round(subtotal × 0.1) // 10%
total = subtotal + serviceFee
```

### **Formateo**
```typescript
formatCurrency(value: number) {
  return new Intl.NumberFormat('es-MX', {
    style: 'currency',
    currency: 'MXN',
    minimumFractionDigits: 0
  }).format(value)
}
```

## 📱 Responsive Design

### **Mobile (< 768px)**
- Layout de 1 columna
- Panel de reserva debajo del contenido
- Imagen principal en pantalla completa
- Grid de características en 1 columna

### **Tablet (768px - 1024px)**
- Layout de 2 columnas para características
- Imagen principal + 1 miniatura visible

### **Desktop (≥ 1024px)**
- Grid de 3 columnas (2 para contenido, 1 para reserva)
- Panel de reserva sticky (top-24)
- Imagen principal + 2 miniaturas
- Grid de características en 2 columnas

## 🔧 Integración con Backend

### **Endpoint Usado**
```typescript
GET /api/spaces/:id
```

### **Respuesta Esperada**
```typescript
{
  success: true,
  data: {
    id: string
    name: string
    description?: string
    capacity: number
    ownerId: string
    isActive: boolean
    imageUrl?: string
    images?: string[]
    createdAt: string
    updatedAt: string
    owner: {
      id: string
      name?: string
      businessName?: string
      businessDescription?: string
    }
  }
}
```

### **Servicio**
```typescript
// ~/services/spaces.service.ts
SpacesService.detail(id: string): Promise<Space>
```

## 🎯 Siguiente Paso: Implementar Reservas

### **Archivos Preparados**
```
✅ ~/types/booking.ts
✅ ~/services/bookings.service.ts
```

### **Función de Reserva**
```typescript
const handleBooking = async () => {
  try {
    // Construir fechas ISO 8601
    const startTime = new Date(`${bookingDate.value}T${bookingTime.value}`)
    const endTime = new Date(startTime)
    endTime.setHours(endTime.getHours() + bookingHours.value)
    
    // Crear reserva
    const booking = await BookingsService.create({
      spaceId: spaceId.value,
      startTime: startTime.toISOString(),
      endTime: endTime.toISOString()
    })
    
    // Redirigir a página de confirmación
    router.push(`/bookings/${booking._id}`)
  } catch (error) {
    console.error('Error al crear reserva:', error)
    // Mostrar mensaje de error
  }
}
```

## 📂 Estructura de Archivos

```
Web/app/
├── pages/
│   └── spaces/
│       └── [id].vue                 ✨ Nueva página de detalles
├── components/
│   └── SpaceCard.vue                ✨ Actualizado con navegación
├── services/
│   ├── spaces.service.ts            ✅ Método detail() existente
│   └── bookings.service.ts          ✨ Nuevo servicio
└── types/
    ├── space.ts                     ✅ Con soporte de imágenes
    └── booking.ts                   ✨ Nuevo tipo
```

## ✅ Checklist de Funcionalidades

### **Completado**
- [x] Página dinámica con routing `/spaces/[id]`
- [x] Integración con API del backend
- [x] Estados de loading y error
- [x] Galería de imágenes con placeholders
- [x] Panel de reserva sticky
- [x] Cálculo dinámico de precios
- [x] Formulario de reserva con validación
- [x] Información del propietario
- [x] Lista de características inteligente
- [x] Navegación desde/hacia inicio
- [x] Responsive completo
- [x] Formateo de moneda en español

### **Pendiente (Futura Implementación)**
- [ ] Conectar botón de reserva con backend
- [ ] Modal de confirmación de reserva
- [ ] Sistema de reseñas/calificaciones
- [ ] Calendario de disponibilidad real
- [ ] Galería de imágenes modal
- [ ] Botón de favoritos
- [ ] Compartir espacio (redes sociales)
- [ ] Mapa de ubicación
- [ ] Espacios similares/recomendados

## 🎨 Mejoras de UX Aplicadas

1. **Feedback visual inmediato**: Loading skeletons mientras carga
2. **Navegación intuitiva**: Botón de volver visible y accesible
3. **Precios claros**: Desglose completo del costo
4. **Validación**: Botón de reserva se deshabilita si faltan datos
5. **Información completa**: Todas las características visibles
6. **Design consistency**: Usa mismos colores y estilos del inicio
7. **Mobile first**: Diseño optimizado para todos los tamaños
8. **Performance**: Carga asíncrona con `useAsyncData`

## 🔮 Próximas Mejoras Sugeridas

1. **Galería modal**: Click en imagen abre galería completa
2. **Calendario interactivo**: Ver disponibilidad en tiempo real
3. **Instant booking**: Reserva inmediata sin confirmación
4. **Reseñas**: Sistema de calificaciones y comentarios
5. **Precio dinámico**: Precios variables por hora/día/temporada
6. **Promociones**: Descuentos para reservas largas
7. **Favoritos**: Guardar espacios para después
8. **Comparación**: Comparar con otros espacios similares
