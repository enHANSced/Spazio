<script setup lang="ts">
import { computed } from 'vue'
import type { Space } from '../types/space'

const props = defineProps<{ space: Space }>()

const ownerName = computed(() => props.space.owner?.businessName || props.space.owner?.name || 'Propietario verificado')

const usageBadge = computed(() => {
  if (props.space.capacity >= 80) return 'Eventos masivos'
  if (props.space.capacity >= 40) return 'Equipos grandes'
  if (props.space.capacity >= 15) return 'Reuniones colaborativas'
  return 'Sesiones privadas'
})

const relativeUpdatedAt = computed(() => {
  const updatedAt = props.space.updatedAt || props.space.createdAt
  if (!updatedAt) return 'Hace instantes'

  const target = new Date(updatedAt)
  const diffMs = Date.now() - target.getTime()
  const diffHours = Math.round(diffMs / 3_600_000)
  if (Number.isNaN(diffHours) || diffHours <= 0) return 'Hace instantes'
  if (diffHours < 24) return `Actualizado hace ${diffHours}h`
  const diffDays = Math.round(diffHours / 24)
  return `Actualizado hace ${diffDays}d`
})

const description = computed(() => {
  if (props.space.description?.length) return props.space.description
  return 'Espacio listo para recibir tus equipos y eventos. Incluye servicios básicos y soporte del propietario.'
})
</script>

<template>
  <article
    class="group flex h-full flex-col justify-between rounded-2xl border border-slate-200 bg-white/90 p-5 shadow-sm transition hover:-translate-y-1 hover:border-primary/40 hover:shadow-lg"
  >
    <div>
      <div class="flex items-center justify-between text-xs font-medium text-slate-500">
        <span class="inline-flex items-center gap-1 rounded-full bg-primary/10 px-3 py-1 text-primary">
          <span class="material-symbols-outlined text-base">event_available</span>
          {{ usageBadge }}
        </span>
        <span>{{ relativeUpdatedAt }}</span>
      </div>

      <h3 class="mt-4 text-xl font-semibold text-[#111418]">{{ space.name }}</h3>
      <p class="mt-2 text-sm leading-relaxed text-slate-600">
        {{ description }}
      </p>
    </div>

    <dl class="mt-6 grid grid-cols-2 gap-4 text-sm">
      <div class="rounded-xl bg-slate-50 p-3">
        <dt class="text-slate-500">Capacidad</dt>
        <dd class="text-lg font-semibold text-[#111418]">{{ space.capacity }} personas</dd>
      </div>
      <div class="rounded-xl bg-slate-50 p-3">
        <dt class="text-slate-500">Propietario</dt>
        <dd class="text-base font-semibold text-[#111418]">{{ ownerName }}</dd>
      </div>
    </dl>

    <div class="mt-6 flex items-center justify-between">
      <div class="flex items-center gap-2 text-sm text-slate-500">
        <span class="material-symbols-outlined text-base text-primary">location_on</span>
        <span>Disponibilidad inmediata</span>
      </div>
      <button
        type="button"
        class="inline-flex items-center gap-1 rounded-xl bg-primary/90 px-4 py-2 text-sm font-semibold text-white shadow-md transition hover:bg-primary"
      >
        Explorar
        <span class="material-symbols-outlined text-base">trending_flat</span>
      </button>
    </div>
  </article>
</template>
