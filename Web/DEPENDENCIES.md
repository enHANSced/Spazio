# Dependencias Planeadas - Spazio Web

Este archivo documenta las dependencias que se instalarán progresivamente conforme se desarrolle el proyecto.

## Estado Actual

### ✅ Instaladas
- `nuxt` (^4.2.1) - Framework principal
- `vue` (^3.5.24) - Vue 3
- `vue-router` (^4.6.3) - Routing (incluido en Nuxt)

## Dependencias por Instalar

### 🔴 Prioridad Alta (Core)

#### 1. Pinia - Estado Global
```bash
npm install pinia @pinia/nuxt
```
**Uso:** Gestión de estado global (auth, spaces, bookings)

#### 2. TailwindCSS - Estilos
```bash
npx nuxi module add @nuxtjs/tailwindcss
```
**Uso:** Framework CSS para diseño responsive

#### 3. Vuelidate - Validación
```bash
npm install @vuelidate/core @vuelidate/validators
```
**Uso:** Validación de formularios client-side

### 🟡 Prioridad Media (Features)

#### 4. FullCalendar - Calendario
```bash
npm install @fullcalendar/core @fullcalendar/vue3 @fullcalendar/daygrid @fullcalendar/timegrid @fullcalendar/interaction
```
**Uso:** Visualización y gestión de reservas en calendario

#### 5. Vue Toastification - Notificaciones
```bash
npm install vue-toastification@next
```
**Uso:** Toast notifications para feedback al usuario

#### 6. VueUse - Utilidades Vue
```bash
npm install @vueuse/core @vueuse/nuxt
```
**Uso:** Composables útiles pre-construidos

### 🟢 Prioridad Baja (Mejoras)

#### 7. Day.js - Manejo de Fechas
```bash
npm install dayjs
```
**Uso:** Formateo y manipulación de fechas/horas

#### 8. Zod - Validación de Schemas
```bash
npm install zod
```
**Uso:** Validación de tipos en runtime + TypeScript

#### 9. Nuxt Icon - Iconos
```bash
npx nuxi module add @nuxt/icon
```
**Uso:** Biblioteca de iconos unificada

## Dev Dependencies

### Testing (Futuro)
```bash
npm install -D vitest @vue/test-utils happy-dom @nuxt/test-utils
npm install -D @playwright/test
```

### Linting
```bash
npm install -D eslint @nuxt/eslint-config typescript-eslint
npm install -D prettier eslint-config-prettier
```

## Orden de Instalación Recomendado

1. **Fase 1 - Setup Base:**
   - Pinia (estado)
   - TailwindCSS (estilos)
   - Vuelidate (validación)

2. **Fase 2 - Features Core:**
   - Vue Toastification (notificaciones)
   - Day.js (fechas)
   - VueUse (utilidades)

3. **Fase 3 - Features Avanzadas:**
   - FullCalendar (calendario)
   - Nuxt Icon (iconos)
   - Zod (validación avanzada)

4. **Fase 4 - Quality:**
   - ESLint + Prettier (linting)
   - Vitest + Playwright (testing)

## Notas Importantes

### ⚠️ Antes de Instalar
- Verificar que el backend esté corriendo
- Tener Node.js v18+ instalado
- Limpiar caché si hay problemas: `rm -rf node_modules package-lock.json && npm install`

### 📝 Después de Instalar
- Actualizar `nuxt.config.ts` con módulos
- Crear archivos de configuración si es necesario
- Actualizar este documento con versiones instaladas
- Probar que todo funcione: `npm run dev`

### 🔗 Enlaces de Documentación
- Pinia: https://pinia.vuejs.org/
- TailwindCSS: https://tailwindcss.com/
- Vuelidate: https://vuelidate-next.netlify.app/
- FullCalendar: https://fullcalendar.io/docs/vue
- Vue Toastification: https://vue-toastification.maronato.dev/
- VueUse: https://vueuse.org/
- Day.js: https://day.js.org/
- Zod: https://zod.dev/

## Comandos Útiles

```bash
# Ver dependencias instaladas
npm list --depth=0

# Actualizar dependencias
npm update

# Verificar vulnerabilidades
npm audit

# Limpiar y reinstalar
rm -rf node_modules package-lock.json
npm install

# Ver tamaño del bundle
npx nuxi analyze
```
