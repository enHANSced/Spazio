<template>
  <div class="space-y-4">
    <!-- Título y descripción -->
    <div class="flex items-center gap-2">
      <span class="material-symbols-outlined text-blue-600">schedule</span>
      <h3 class="text-base font-semibold text-gray-900">Horarios de operación</h3>
    </div>
    <p class="text-sm text-gray-600">Define cuándo tu espacio está disponible para reservas</p>

    <!-- Toggle de días completos o personalizados -->
    <div class="flex items-center gap-4 p-4 bg-gray-50 rounded-lg border border-gray-200">
      <label class="flex items-center gap-2 cursor-pointer">
        <input
          v-model="useCustomSchedule"
          type="checkbox"
          class="w-4 h-4 text-blue-600 border-gray-300 rounded focus:ring-blue-500"
        />
        <span class="text-sm font-medium text-gray-700">Configurar horarios por día</span>
      </label>
      <div v-if="!useCustomSchedule" class="ml-auto text-xs text-gray-500">
        Mismo horario todos los días
      </div>
    </div>

    <!-- Horario general (cuando no está personalizado) -->
    <div v-if="!useCustomSchedule" class="grid grid-cols-2 gap-4">
      <div>
        <label class="block text-sm font-medium text-gray-700 mb-2">
          <span class="flex items-center gap-2">
            <span class="material-symbols-outlined text-sm">wb_twilight</span>
            Apertura
          </span>
        </label>
        <div class="relative">
          <select
            v-model="generalSchedule.start"
            class="w-full px-4 py-2.5 pr-10 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors appearance-none bg-white cursor-pointer"
            @change="updateAllDays"
          >
            <option v-for="time in timeOptions" :key="time.value" :value="time.value">
              {{ time.label }}
            </option>
          </select>
          <span class="material-symbols-outlined absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 pointer-events-none">
            expand_more
          </span>
        </div>
      </div>

      <div>
        <label class="block text-sm font-medium text-gray-700 mb-2">
          <span class="flex items-center gap-2">
            <span class="material-symbols-outlined text-sm">bedtime</span>
            Cierre
          </span>
        </label>
        <div class="relative">
          <select
            v-model="generalSchedule.end"
            class="w-full px-4 py-2.5 pr-10 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors appearance-none bg-white cursor-pointer"
            @change="updateAllDays"
          >
            <option v-for="time in timeOptions" :key="time.value" :value="time.value">
              {{ time.label }}
            </option>
          </select>
          <span class="material-symbols-outlined absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 pointer-events-none">
            expand_more
          </span>
        </div>
      </div>
    </div>

    <!-- Horario personalizado por día -->
    <div v-else class="space-y-3">
      <div
        v-for="day in weekDays"
        :key="day.id"
        class="group relative p-4 border border-gray-200 rounded-lg hover:border-blue-200 hover:bg-blue-50/30 transition-all"
        :class="{
          'bg-blue-50/50 border-blue-300': day.isOpen,
          'bg-gray-50': !day.isOpen
        }"
      >
        <!-- Encabezado del día -->
        <div class="flex items-center justify-between mb-3">
          <div class="flex items-center gap-3">
            <label class="flex items-center cursor-pointer">
              <input
                v-model="day.isOpen"
                type="checkbox"
                class="w-5 h-5 text-blue-600 border-gray-300 rounded focus:ring-blue-500 cursor-pointer"
              />
            </label>
            <div>
              <span class="text-sm font-semibold text-gray-900">{{ day.name }}</span>
              <span v-if="!day.isOpen" class="ml-2 text-xs text-gray-500 italic">Cerrado</span>
            </div>
          </div>
          
          <!-- Vista previa del horario -->
          <div v-if="day.isOpen" class="flex items-center gap-2 text-sm text-gray-600">
            <span class="material-symbols-outlined text-sm text-blue-600">schedule</span>
            <span class="font-medium">{{ formatTime(day.start) }} - {{ formatTime(day.end) }}</span>
          </div>
        </div>

        <!-- Selectores de hora (solo si el día está abierto) -->
        <div v-if="day.isOpen" class="grid grid-cols-2 gap-3 pl-8">
          <div>
            <label class="block text-xs font-medium text-gray-600 mb-1.5">Apertura</label>
            <div class="relative">
              <select
                v-model="day.start"
                class="w-full px-3 py-2 pr-8 text-sm border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors appearance-none bg-white cursor-pointer"
              >
                <option v-for="time in timeOptions" :key="time.value" :value="time.value">
                  {{ time.label }}
                </option>
              </select>
              <span class="material-symbols-outlined absolute right-2 top-1/2 -translate-y-1/2 text-gray-400 pointer-events-none text-sm">
                expand_more
              </span>
            </div>
          </div>

          <div>
            <label class="block text-xs font-medium text-gray-600 mb-1.5">Cierre</label>
            <div class="relative">
              <select
                v-model="day.end"
                class="w-full px-3 py-2 pr-8 text-sm border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors appearance-none bg-white cursor-pointer"
              >
                <option v-for="time in timeOptions" :key="time.value" :value="time.value">
                  {{ time.label }}
                </option>
              </select>
              <span class="material-symbols-outlined absolute right-2 top-1/2 -translate-y-1/2 text-gray-400 pointer-events-none text-sm">
                expand_more
              </span>
            </div>
          </div>
        </div>

        <!-- Validación de horario -->
        <div v-if="day.isOpen && !isValidTimeRange(day.start, day.end)" class="mt-2 pl-8">
          <p class="text-xs text-red-600 flex items-center gap-1">
            <span class="material-symbols-outlined text-sm">error</span>
            La hora de cierre debe ser posterior a la de apertura
          </p>
        </div>
      </div>
    </div>

    <!-- Acciones rápidas -->
    <div v-if="useCustomSchedule" class="flex flex-wrap gap-2 pt-2">
      <button
        type="button"
        @click="applyWeekdaysSchedule"
        class="px-3 py-1.5 text-xs font-medium text-blue-700 bg-blue-50 hover:bg-blue-100 border border-blue-200 rounded-lg transition-colors"
      >
        <span class="flex items-center gap-1">
          <span class="material-symbols-outlined text-sm">today</span>
          Lunes a Viernes (8:00 - 18:00)
        </span>
      </button>
      <button
        type="button"
        @click="apply24Hours"
        class="px-3 py-1.5 text-xs font-medium text-green-700 bg-green-50 hover:bg-green-100 border border-green-200 rounded-lg transition-colors"
      >
        <span class="flex items-center gap-1">
          <span class="material-symbols-outlined text-sm">schedule_24</span>
          24 horas
        </span>
      </button>
      <button
        type="button"
        @click="closeAllDays"
        class="px-3 py-1.5 text-xs font-medium text-gray-700 bg-gray-100 hover:bg-gray-200 border border-gray-200 rounded-lg transition-colors"
      >
        <span class="flex items-center gap-1">
          <span class="material-symbols-outlined text-sm">close</span>
          Cerrar todos
        </span>
      </button>
    </div>

    <!-- Resumen -->
    <div class="p-3 bg-blue-50 border border-blue-200 rounded-lg">
      <div class="flex items-start gap-2">
        <span class="material-symbols-outlined text-blue-600 text-sm mt-0.5">info</span>
        <div class="text-xs text-blue-800">
          <p class="font-medium mb-1">Información importante:</p>
          <ul class="list-disc list-inside space-y-0.5 text-blue-700">
            <li>Los horarios definen cuándo los usuarios pueden hacer reservas</li>
            <li>Puedes desactivar días específicos si no operas ciertos días</li>
            <li>Los cambios se aplicarán a nuevas reservas</li>
          </ul>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
interface WorkingHours {
  start: string
  end: string
}

interface WeekDay {
  id: string
  name: string
  isOpen: boolean
  start: string
  end: string
}

interface Props {
  modelValue: WorkingHours | Record<string, WorkingHours>
}

interface Emits {
  (e: 'update:modelValue', value: WorkingHours | Record<string, WorkingHours>): void
}

const props = defineProps<Props>()
const emit = defineEmits<Emits>()

// Estado
const useCustomSchedule = ref(false)
const generalSchedule = ref<WorkingHours>({
  start: '08:00',
  end: '22:00'
})

// Días de la semana
const weekDays = ref<WeekDay[]>([
  { id: 'monday', name: 'Lunes', isOpen: true, start: '08:00', end: '22:00' },
  { id: 'tuesday', name: 'Martes', isOpen: true, start: '08:00', end: '22:00' },
  { id: 'wednesday', name: 'Miércoles', isOpen: true, start: '08:00', end: '22:00' },
  { id: 'thursday', name: 'Jueves', isOpen: true, start: '08:00', end: '22:00' },
  { id: 'friday', name: 'Viernes', isOpen: true, start: '08:00', end: '22:00' },
  { id: 'saturday', name: 'Sábado', isOpen: true, start: '08:00', end: '22:00' },
  { id: 'sunday', name: 'Domingo', isOpen: false, start: '08:00', end: '22:00' }
])

// Generar opciones de tiempo cada 30 minutos
const timeOptions = computed(() => {
  const options: Array<{ value: string; label: string }> = []
  for (let hour = 0; hour < 24; hour++) {
    for (let minute = 0; minute < 60; minute += 30) {
      const hourStr = hour.toString().padStart(2, '0')
      const minuteStr = minute.toString().padStart(2, '0')
      const value = `${hourStr}:${minuteStr}`
      
      // Formato 12 horas con AM/PM
      const hour12 = hour === 0 ? 12 : hour > 12 ? hour - 12 : hour
      const ampm = hour < 12 ? 'AM' : 'PM'
      const label = `${hour12}:${minuteStr} ${ampm}`
      
      options.push({ value, label })
    }
  }
  return options
})

// Formatear hora para mostrar
const formatTime = (time: string): string => {
  const [hourStr, minuteStr] = time.split(':')
  const hour = parseInt(hourStr || '0')
  const hour12 = hour === 0 ? 12 : hour > 12 ? hour - 12 : hour
  const ampm = hour < 12 ? 'AM' : 'PM'
  return `${hour12}:${minuteStr || '00'} ${ampm}`
}

// Validar rango de tiempo
const isValidTimeRange = (start: string, end: string): boolean => {
  const [startHour, startMin] = start.split(':').map(Number)
  const [endHour, endMin] = end.split(':').map(Number)
  const startMinutes = (startHour || 0) * 60 + (startMin || 0)
  const endMinutes = (endHour || 0) * 60 + (endMin || 0)
  return endMinutes > startMinutes
}

// Actualizar todos los días con el horario general
const updateAllDays = () => {
  weekDays.value.forEach(day => {
    if (day.isOpen) {
      day.start = generalSchedule.value.start
      day.end = generalSchedule.value.end
    }
  })
  emitValue()
}

// Aplicar horario de oficina (Lunes a Viernes)
const applyWeekdaysSchedule = () => {
  weekDays.value.forEach((day, index) => {
    if (index < 5) { // Lunes a Viernes
      day.isOpen = true
      day.start = '08:00'
      day.end = '18:00'
    } else { // Sábado y Domingo
      day.isOpen = false
    }
  })
  emitValue()
}

// Aplicar horario 24 horas
const apply24Hours = () => {
  weekDays.value.forEach(day => {
    day.isOpen = true
    day.start = '00:00'
    day.end = '23:30'
  })
  emitValue()
}

// Cerrar todos los días
const closeAllDays = () => {
  weekDays.value.forEach(day => {
    day.isOpen = false
  })
  emitValue()
}

// Emitir valor según el modo
const emitValue = () => {
  if (!useCustomSchedule.value) {
    // Modo simple: emitir solo start y end
    emit('update:modelValue', {
      start: generalSchedule.value.start,
      end: generalSchedule.value.end
    })
  } else {
    // Modo personalizado: emitir objeto con días
    const schedule: Record<string, WorkingHours> = {}
    weekDays.value.forEach(day => {
      if (day.isOpen) {
        schedule[day.id] = {
          start: day.start,
          end: day.end
        }
      }
    })
    emit('update:modelValue', schedule)
  }
}

// Watch para cambios en el switch de personalización
watch(useCustomSchedule, (newValue) => {
  if (!newValue) {
    // Si desactiva personalización, actualizar todos con el horario general
    updateAllDays()
  } else {
    // Si activa personalización, emitir el estado actual
    emitValue()
  }
})

// Watch para cambios en los días (cuando está personalizado)
watch(() => weekDays.value, () => {
  if (useCustomSchedule.value) {
    emitValue()
  }
}, { deep: true })

// Watch para cambios en el horario general
watch(generalSchedule, () => {
  if (!useCustomSchedule.value) {
    emitValue()
  }
}, { deep: true })

// Inicializar con valores del prop
onMounted(() => {
  const value = props.modelValue
  
  // Verificar si es un objeto con días (personalizado) o simple
  if (value && typeof value === 'object') {
    const keys = Object.keys(value)
    
    // Si tiene propiedades start y end directamente, es modo simple
    if ('start' in value && 'end' in value && typeof value.start === 'string' && typeof value.end === 'string') {
      useCustomSchedule.value = false
      generalSchedule.value = {
        start: value.start,
        end: value.end
      }
      // Actualizar todos los días con estos valores
      weekDays.value.forEach(day => {
        day.start = value.start as string
        day.end = value.end as string
      })
    } else {
      // Es modo personalizado con días
      useCustomSchedule.value = true
      const scheduleByDay = value as Record<string, WorkingHours>
      weekDays.value.forEach(day => {
        if (keys.includes(day.id)) {
          const daySchedule = scheduleByDay[day.id]
          if (daySchedule) {
            day.isOpen = true
            day.start = daySchedule.start
            day.end = daySchedule.end
          }
        } else {
          day.isOpen = false
        }
      })
    }
  }
})
</script>

<style scoped>
/* Animaciones suaves */
.group:hover {
  transform: translateY(-1px);
}

/* Estilos para los selectores */
select {
  background-image: none;
}

/* Animación para validaciones */
@keyframes shake {
  0%, 100% { transform: translateX(0); }
  25% { transform: translateX(-5px); }
  75% { transform: translateX(5px); }
}

.animate-shake {
  animation: shake 0.3s ease-in-out;
}
</style>
