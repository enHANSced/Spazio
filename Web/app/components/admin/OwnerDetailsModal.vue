<script setup lang="ts">
import type { OwnerDetails } from '../../services/admin.service'

interface Props {
  show: boolean
  ownerDetails: OwnerDetails | null
  loading?: boolean
}

defineProps<Props>()

const emit = defineEmits<{
  close: []
  viewSpace: [spaceId: string]
}>()

const formatDate = (dateString?: string) => {
  if (!dateString) return '-'
  const date = new Date(dateString)
  return date.toLocaleDateString('es-ES', {
    day: '2-digit',
    month: 'short',
    year: 'numeric'
  })
}

const formatCurrency = (value: number) => {
  return new Intl.NumberFormat('es-HN', {
    style: 'currency',
    currency: 'HNL'
  }).format(value)
}

const getSpaceImage = (images?: Array<{ url: string; publicId?: string }>) => {
  if (!images || images.length === 0) return null
  return images[0]?.url || null
}
</script>

<template>
  <Teleport to="body">
    <Transition
      enter-active-class="transition-opacity duration-200"
      leave-active-class="transition-opacity duration-200"
      enter-from-class="opacity-0"
      leave-to-class="opacity-0"
    >
      <div
        v-if="show"
        class="fixed inset-0 z-50 flex items-center justify-center p-4"
      >
        <!-- Backdrop -->
        <div 
          class="absolute inset-0 bg-black/50" 
          @click="emit('close')" 
        />
        
        <!-- Modal Content -->
        <div class="relative w-full max-w-4xl max-h-[90vh] overflow-hidden rounded-xl bg-white shadow-xl">
          <!-- Loading state -->
          <div v-if="loading" class="flex items-center justify-center py-20">
            <div class="flex items-center gap-3 text-slate-600">
              <div class="h-8 w-8 animate-spin rounded-full border-3 border-slate-300 border-t-rose-600" />
              <span class="text-sm font-medium">Cargando detalles...</span>
            </div>
          </div>

          <!-- Content -->
          <template v-else-if="ownerDetails">
            <!-- Header -->
            <div class="sticky top-0 z-10 flex items-start justify-between border-b border-slate-200 bg-white p-6">
              <div class="flex items-center gap-4">
                <div class="flex h-16 w-16 items-center justify-center rounded-full bg-purple-100">
                  <span class="material-symbols-outlined text-3xl text-purple-600">store</span>
                </div>
                <div>
                  <h2 class="text-xl font-bold text-[#111418]">
                    {{ ownerDetails.user.businessName || ownerDetails.user.name }}
                  </h2>
                  <p class="text-sm text-slate-600">{{ ownerDetails.user.email }}</p>
                  <div class="mt-1 flex items-center gap-2">
                    <span
                      class="inline-flex items-center gap-1 rounded-full px-2.5 py-0.5 text-xs font-semibold"
                      :class="ownerDetails.user.isVerified ? 'bg-green-100 text-green-700' : 'bg-amber-100 text-amber-700'"
                    >
                      <span class="material-symbols-outlined !text-[14px]">
                        {{ ownerDetails.user.isVerified ? 'verified' : 'pending' }}
                      </span>
                      {{ ownerDetails.user.isVerified ? 'Verificado' : 'Pendiente verificación' }}
                    </span>
                    <span
                      class="inline-flex items-center gap-1 rounded-full px-2.5 py-0.5 text-xs font-semibold"
                      :class="ownerDetails.user.isActive ? 'bg-green-100 text-green-700' : 'bg-slate-100 text-slate-600'"
                    >
                      {{ ownerDetails.user.isActive ? 'Activo' : 'Inactivo' }}
                    </span>
                  </div>
                </div>
              </div>
              <button
                class="rounded-lg p-2 text-slate-500 transition hover:bg-slate-100"
                @click="emit('close')"
              >
                <span class="material-symbols-outlined">close</span>
              </button>
            </div>

            <!-- Scrollable content -->
            <div class="max-h-[calc(90vh-120px)] overflow-y-auto p-6">
              <div class="space-y-6">
                <!-- Stats cards -->
                <div class="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
                  <div class="rounded-xl border border-slate-200 bg-white p-4 shadow-sm">
                    <div class="flex items-center justify-between">
                      <div>
                        <p class="text-xs text-slate-500">Espacios</p>
                        <p class="text-2xl font-bold text-[#111418]">{{ ownerDetails.spaceStats.total }}</p>
                        <p class="text-xs text-slate-500">
                          {{ ownerDetails.spaceStats.active }} activos
                        </p>
                      </div>
                      <div class="flex h-10 w-10 items-center justify-center rounded-full bg-purple-100">
                        <span class="material-symbols-outlined text-xl text-purple-600">apartment</span>
                      </div>
                    </div>
                  </div>

                  <div class="rounded-xl border border-slate-200 bg-white p-4 shadow-sm">
                    <div class="flex items-center justify-between">
                      <div>
                        <p class="text-xs text-slate-500">Reservas Totales</p>
                        <p class="text-2xl font-bold text-[#111418]">{{ ownerDetails.bookingStats.total }}</p>
                        <p class="text-xs text-slate-500">
                          {{ ownerDetails.bookingStats.confirmed }} confirmadas
                        </p>
                      </div>
                      <div class="flex h-10 w-10 items-center justify-center rounded-full bg-blue-100">
                        <span class="material-symbols-outlined text-xl text-blue-600">event</span>
                      </div>
                    </div>
                  </div>

                  <div class="rounded-xl border border-slate-200 bg-white p-4 shadow-sm">
                    <div class="flex items-center justify-between">
                      <div>
                        <p class="text-xs text-slate-500">Completadas</p>
                        <p class="text-2xl font-bold text-green-600">{{ ownerDetails.bookingStats.completed }}</p>
                        <p class="text-xs text-slate-500">
                          {{ ownerDetails.bookingStats.cancelled }} canceladas
                        </p>
                      </div>
                      <div class="flex h-10 w-10 items-center justify-center rounded-full bg-green-100">
                        <span class="material-symbols-outlined text-xl text-green-600">check_circle</span>
                      </div>
                    </div>
                  </div>

                  <div class="rounded-xl border border-slate-200 bg-white p-4 shadow-sm">
                    <div class="flex items-center justify-between">
                      <div>
                        <p class="text-xs text-slate-500">Ingresos Est.</p>
                        <p class="text-2xl font-bold text-emerald-600">
                          {{ formatCurrency(ownerDetails.bookingStats.totalRevenue) }}
                        </p>
                        <p class="text-xs text-slate-500">reservas confirmadas</p>
                      </div>
                      <div class="flex h-10 w-10 items-center justify-center rounded-full bg-emerald-100">
                        <span class="material-symbols-outlined text-xl text-emerald-600">payments</span>
                      </div>
                    </div>
                  </div>
                </div>

                <!-- Owner profile info -->
                <div class="rounded-xl border border-slate-200 bg-white p-5 shadow-sm">
                  <h3 class="mb-4 flex items-center gap-2 text-sm font-semibold text-[#111418]">
                    <span class="material-symbols-outlined text-lg text-slate-500">person</span>
                    Información del Propietario
                  </h3>
                  
                  <div class="grid gap-4 sm:grid-cols-2">
                    <div>
                      <p class="text-xs text-slate-500">Nombre completo</p>
                      <p class="text-sm font-medium text-[#111418]">{{ ownerDetails.user.name }}</p>
                    </div>
                    <div>
                      <p class="text-xs text-slate-500">Email</p>
                      <p class="text-sm font-medium text-[#111418]">{{ ownerDetails.user.email }}</p>
                    </div>
                    <div v-if="ownerDetails.user.businessName">
                      <p class="text-xs text-slate-500">Nombre del negocio</p>
                      <p class="text-sm font-medium text-[#111418]">{{ ownerDetails.user.businessName }}</p>
                    </div>
                    <div v-if="ownerDetails.user.phone">
                      <p class="text-xs text-slate-500">Teléfono</p>
                      <p class="text-sm font-medium text-[#111418]">{{ ownerDetails.user.phone }}</p>
                    </div>
                    <div v-if="ownerDetails.user.whatsappNumber">
                      <p class="text-xs text-slate-500">WhatsApp</p>
                      <p class="text-sm font-medium text-[#111418]">{{ ownerDetails.user.whatsappNumber }}</p>
                    </div>
                    <div>
                      <p class="text-xs text-slate-500">Fecha de registro</p>
                      <p class="text-sm font-medium text-[#111418]">{{ formatDate(ownerDetails.user.createdAt) }}</p>
                    </div>
                  </div>

                  <div v-if="ownerDetails.user.businessDescription" class="mt-4">
                    <p class="text-xs text-slate-500">Descripción del negocio</p>
                    <p class="mt-1 text-sm text-slate-600">{{ ownerDetails.user.businessDescription }}</p>
                  </div>

                  <!-- Social links -->
                  <div 
                    v-if="ownerDetails.user.instagram || ownerDetails.user.facebook || ownerDetails.user.linkedin"
                    class="mt-4 flex flex-wrap gap-3"
                  >
                    <a
                      v-if="ownerDetails.user.instagram"
                      :href="ownerDetails.user.instagram"
                      target="_blank"
                      rel="noopener noreferrer"
                      class="inline-flex items-center gap-1.5 rounded-full bg-gradient-to-r from-purple-500 to-pink-500 px-3 py-1.5 text-xs font-medium text-white transition hover:opacity-90"
                    >
                      <svg class="h-4 w-4" fill="currentColor" viewBox="0 0 24 24">
                        <path d="M12 2.163c3.204 0 3.584.012 4.85.07 3.252.148 4.771 1.691 4.919 4.919.058 1.265.069 1.645.069 4.849 0 3.205-.012 3.584-.069 4.849-.149 3.225-1.664 4.771-4.919 4.919-1.266.058-1.644.07-4.85.07-3.204 0-3.584-.012-4.849-.07-3.26-.149-4.771-1.699-4.919-4.92-.058-1.265-.07-1.644-.07-4.849 0-3.204.013-3.583.07-4.849.149-3.227 1.664-4.771 4.919-4.919 1.266-.057 1.645-.069 4.849-.069zm0-2.163c-3.259 0-3.667.014-4.947.072-4.358.2-6.78 2.618-6.98 6.98-.059 1.281-.073 1.689-.073 4.948 0 3.259.014 3.668.072 4.948.2 4.358 2.618 6.78 6.98 6.98 1.281.058 1.689.072 4.948.072 3.259 0 3.668-.014 4.948-.072 4.354-.2 6.782-2.618 6.979-6.98.059-1.28.073-1.689.073-4.948 0-3.259-.014-3.667-.072-4.947-.196-4.354-2.617-6.78-6.979-6.98-1.281-.059-1.69-.073-4.949-.073zm0 5.838c-3.403 0-6.162 2.759-6.162 6.162s2.759 6.163 6.162 6.163 6.162-2.759 6.162-6.163c0-3.403-2.759-6.162-6.162-6.162zm0 10.162c-2.209 0-4-1.79-4-4 0-2.209 1.791-4 4-4s4 1.791 4 4c0 2.21-1.791 4-4 4zm6.406-11.845c-.796 0-1.441.645-1.441 1.44s.645 1.44 1.441 1.44c.795 0 1.439-.645 1.439-1.44s-.644-1.44-1.439-1.44z"/>
                      </svg>
                      Instagram
                    </a>
                    <a
                      v-if="ownerDetails.user.facebook"
                      :href="ownerDetails.user.facebook"
                      target="_blank"
                      rel="noopener noreferrer"
                      class="inline-flex items-center gap-1.5 rounded-full bg-blue-600 px-3 py-1.5 text-xs font-medium text-white transition hover:bg-blue-700"
                    >
                      <svg class="h-4 w-4" fill="currentColor" viewBox="0 0 24 24">
                        <path d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z"/>
                      </svg>
                      Facebook
                    </a>
                    <a
                      v-if="ownerDetails.user.linkedin"
                      :href="ownerDetails.user.linkedin"
                      target="_blank"
                      rel="noopener noreferrer"
                      class="inline-flex items-center gap-1.5 rounded-full bg-sky-600 px-3 py-1.5 text-xs font-medium text-white transition hover:bg-sky-700"
                    >
                      <svg class="h-4 w-4" fill="currentColor" viewBox="0 0 24 24">
                        <path d="M20.447 20.452h-3.554v-5.569c0-1.328-.027-3.037-1.852-3.037-1.853 0-2.136 1.445-2.136 2.939v5.667H9.351V9h3.414v1.561h.046c.477-.9 1.637-1.85 3.37-1.85 3.601 0 4.267 2.37 4.267 5.455v6.286zM5.337 7.433c-1.144 0-2.063-.926-2.063-2.065 0-1.138.92-2.063 2.063-2.063 1.14 0 2.064.925 2.064 2.063 0 1.139-.925 2.065-2.064 2.065zm1.782 13.019H3.555V9h3.564v11.452zM22.225 0H1.771C.792 0 0 .774 0 1.729v20.542C0 23.227.792 24 1.771 24h20.451C23.2 24 24 23.227 24 22.271V1.729C24 .774 23.2 0 22.222 0h.003z"/>
                      </svg>
                      LinkedIn
                    </a>
                  </div>
                </div>

                <!-- Spaces list -->
                <div class="rounded-xl border border-slate-200 bg-white p-5 shadow-sm">
                  <h3 class="mb-4 flex items-center justify-between text-sm font-semibold text-[#111418]">
                    <span class="flex items-center gap-2">
                      <span class="material-symbols-outlined text-lg text-slate-500">apartment</span>
                      Espacios ({{ ownerDetails.spaces.length }})
                    </span>
                  </h3>

                  <div v-if="ownerDetails.spaces.length === 0" class="py-8 text-center">
                    <span class="material-symbols-outlined text-4xl text-slate-300">home_work</span>
                    <p class="mt-2 text-sm text-slate-500">Este propietario no tiene espacios registrados</p>
                  </div>

                  <div v-else class="space-y-3">
                    <div
                      v-for="space in ownerDetails.spaces"
                      :key="space.id"
                      class="flex items-center gap-4 rounded-lg border border-slate-100 p-3 transition hover:border-slate-200 hover:bg-slate-50"
                    >
                      <!-- Space image -->
                      <div class="h-16 w-20 flex-shrink-0 overflow-hidden rounded-lg bg-slate-100">
                        <img
                          v-if="getSpaceImage(space.images)"
                          :src="getSpaceImage(space.images) || ''"
                          :alt="space.name"
                          class="h-full w-full object-cover"
                        />
                        <div v-else class="flex h-full w-full items-center justify-center">
                          <span class="material-symbols-outlined text-2xl text-slate-400">image</span>
                        </div>
                      </div>

                      <!-- Space info -->
                      <div class="min-w-0 flex-1">
                        <p class="truncate text-sm font-semibold text-[#111418]">{{ space.name }}</p>
                        <div class="mt-1 flex flex-wrap items-center gap-2 text-xs text-slate-500">
                          <span v-if="space.city" class="flex items-center gap-1">
                            <span class="material-symbols-outlined !text-[14px]">location_on</span>
                            {{ space.city }}
                          </span>
                          <span class="flex items-center gap-1">
                            <span class="material-symbols-outlined !text-[14px]">group</span>
                            {{ space.capacity }} personas
                          </span>
                          <span v-if="space.pricePerHour" class="flex items-center gap-1">
                            <span class="material-symbols-outlined !text-[14px]">payments</span>
                            {{ formatCurrency(space.pricePerHour) }}/hr
                          </span>
                        </div>
                      </div>

                      <!-- Status & action -->
                      <div class="flex items-center gap-3">
                        <span
                          class="inline-flex rounded-full px-2 py-0.5 text-xs font-medium"
                          :class="space.isActive ? 'bg-green-100 text-green-700' : 'bg-slate-100 text-slate-600'"
                        >
                          {{ space.isActive ? 'Activo' : 'Inactivo' }}
                        </span>
                        <NuxtLink
                          :to="`/spaces/${space.id}`"
                          target="_blank"
                          class="rounded-lg p-2 text-slate-500 transition hover:bg-slate-100 hover:text-primary"
                          title="Ver espacio"
                        >
                          <span class="material-symbols-outlined text-lg">open_in_new</span>
                        </NuxtLink>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </template>

          <!-- Error state -->
          <div v-else class="py-12 text-center">
            <span class="material-symbols-outlined text-4xl text-slate-300">error</span>
            <p class="mt-2 text-sm text-slate-600">No se pudieron cargar los detalles</p>
          </div>
        </div>
      </div>
    </Transition>
  </Teleport>
</template>
