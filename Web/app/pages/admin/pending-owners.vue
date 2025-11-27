<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { adminService, type AdminUser } from '../../services/admin.service'
import { useToast } from '../../composables/useToast'

definePageMeta({
  layout: 'admin',
  middleware: 'admin'
})

useSeoMeta({
  title: 'Verificación de Propietarios - Admin Spazio',
  description: 'Aprobar o rechazar solicitudes de propietarios'
})

const toast = useToast()

const pendingOwners = ref<AdminUser[]>([])
const loading = ref(true)

// Modal state
const showConfirmModal = ref(false)
const confirmModalData = ref({
  title: '',
  message: '',
  variant: 'success' as 'danger' | 'warning' | 'info' | 'success',
  action: null as (() => Promise<void>) | null
})
const modalLoading = ref(false)

const loadPendingOwners = async () => {
  loading.value = true
  
  try {
    const response = await adminService.getPendingOwners()
    
    if (response.success) {
      pendingOwners.value = response.data
    } else {
      toast.error(response.message || 'Error al cargar solicitudes')
    }
  } catch (err: any) {
    toast.error(err.message || 'Error inesperado')
  } finally {
    loading.value = false
  }
}

const formatDate = (dateString?: string) => {
  if (!dateString) return '-'
  const date = new Date(dateString)
  return date.toLocaleDateString('es-ES', {
    day: '2-digit',
    month: 'long',
    year: 'numeric'
  })
}

const confirmVerify = (owner: AdminUser, approve: boolean) => {
  confirmModalData.value = {
    title: approve ? 'Aprobar Propietario' : 'Rechazar Solicitud',
    message: approve 
      ? `¿Deseas aprobar a "${owner.businessName || owner.name}" como propietario verificado? Podrá crear y gestionar espacios en la plataforma.`
      : `¿Deseas rechazar la solicitud de "${owner.businessName || owner.name}"? No podrá gestionar espacios hasta que sea aprobado.`,
    variant: approve ? 'success' : 'danger',
    action: async () => {
      const response = await adminService.verifyOwner(owner.id, approve)
      if (response.success) {
        toast.success(response.message || (approve ? 'Propietario aprobado' : 'Solicitud rechazada'))
        loadPendingOwners()
      } else {
        toast.error(response.message || 'Error al procesar solicitud')
      }
    }
  }
  showConfirmModal.value = true
}

const handleConfirm = async () => {
  if (confirmModalData.value.action) {
    modalLoading.value = true
    try {
      await confirmModalData.value.action()
    } finally {
      modalLoading.value = false
      showConfirmModal.value = false
    }
  }
}

onMounted(() => {
  loadPendingOwners()
})
</script>

<template>
  <div class="space-y-6">
    <!-- Header -->
    <div>
      <h1 class="text-2xl font-bold text-[#111418]">Verificación de Propietarios</h1>
      <p class="mt-1 text-sm text-slate-600">
        Revisa y aprueba las solicitudes de nuevos propietarios
      </p>
    </div>

    <!-- Loading -->
    <div v-if="loading" class="flex items-center justify-center py-12">
      <div class="flex items-center gap-3 text-slate-600">
        <div class="h-6 w-6 animate-spin rounded-full border-2 border-slate-300 border-t-rose-600" />
        <span class="text-sm font-medium">Cargando solicitudes...</span>
      </div>
    </div>

    <!-- Empty State -->
    <div
      v-else-if="pendingOwners.length === 0"
      class="rounded-xl border border-slate-200 bg-white p-12 text-center shadow-sm"
    >
      <div class="flex justify-center">
        <div class="flex h-16 w-16 items-center justify-center rounded-full bg-green-100">
          <span class="material-symbols-outlined text-3xl text-green-600">check_circle</span>
        </div>
      </div>
      <h3 class="mt-4 text-lg font-semibold text-[#111418]">No hay solicitudes pendientes</h3>
      <p class="mt-2 text-sm text-slate-600">
        Todas las solicitudes de propietarios han sido procesadas.
      </p>
      <NuxtLink
        to="/admin/users?role=owner"
        class="mt-6 inline-flex items-center gap-2 text-sm font-semibold text-rose-600 hover:underline"
      >
        <span class="material-symbols-outlined !text-[18px]">arrow_forward</span>
        Ver todos los propietarios
      </NuxtLink>
    </div>

    <!-- Pending Owners List -->
    <div v-else class="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
      <div
        v-for="owner in pendingOwners"
        :key="owner.id"
        class="rounded-xl border border-slate-200 bg-white p-5 shadow-sm transition hover:shadow-md"
      >
        <!-- Header -->
        <div class="flex items-start gap-4">
          <div class="flex h-12 w-12 flex-shrink-0 items-center justify-center rounded-full bg-amber-100">
            <span class="material-symbols-outlined text-2xl text-amber-600">pending</span>
          </div>
          <div class="min-w-0 flex-1">
            <h3 class="truncate text-base font-semibold text-[#111418]">
              {{ owner.businessName || owner.name }}
            </h3>
            <p class="truncate text-sm text-slate-600">{{ owner.name }}</p>
          </div>
        </div>

        <!-- Info -->
        <div class="mt-4 space-y-2">
          <div class="flex items-center gap-2 text-sm">
            <span class="material-symbols-outlined text-lg text-slate-400">mail</span>
            <span class="truncate text-slate-600">{{ owner.email }}</span>
          </div>
          
          <div v-if="owner.phone" class="flex items-center gap-2 text-sm">
            <span class="material-symbols-outlined text-lg text-slate-400">phone</span>
            <span class="text-slate-600">{{ owner.phone }}</span>
          </div>

          <div class="flex items-center gap-2 text-sm">
            <span class="material-symbols-outlined text-lg text-slate-400">calendar_today</span>
            <span class="text-slate-600">Registrado: {{ formatDate(owner.createdAt) }}</span>
          </div>
        </div>

        <!-- Description -->
        <div v-if="owner.businessDescription" class="mt-4">
          <p class="text-xs font-medium text-slate-500">Descripción del negocio:</p>
          <p class="mt-1 line-clamp-3 text-sm text-slate-600">
            {{ owner.businessDescription }}
          </p>
        </div>

        <!-- Actions -->
        <div class="mt-5 flex gap-3">
          <button
            class="flex flex-1 items-center justify-center gap-2 rounded-lg border border-rose-200 bg-white px-3 py-2 text-sm font-semibold text-rose-600 transition hover:bg-rose-50"
            @click="confirmVerify(owner, false)"
          >
            <span class="material-symbols-outlined !text-[18px]">close</span>
            Rechazar
          </button>
          <button
            class="flex flex-1 items-center justify-center gap-2 rounded-lg bg-green-600 px-3 py-2 text-sm font-semibold text-white transition hover:bg-green-700"
            @click="confirmVerify(owner, true)"
          >
            <span class="material-symbols-outlined !text-[18px]">check</span>
            Aprobar
          </button>
        </div>
      </div>
    </div>

    <!-- Info Card -->
    <div class="rounded-xl border border-blue-200 bg-blue-50 p-4">
      <div class="flex gap-3">
        <span class="material-symbols-outlined text-xl text-blue-600">info</span>
        <div>
          <h4 class="text-sm font-semibold text-blue-800">Sobre la verificación</h4>
          <p class="mt-1 text-sm text-blue-700">
            Los propietarios verificados pueden crear espacios, gestionar reservas y acceder al panel de propietarios.
            Rechazar una solicitud no elimina la cuenta, el usuario puede solicitar verificación nuevamente.
          </p>
        </div>
      </div>
    </div>

    <!-- Confirm Modal -->
    <ConfirmModal
      :show="showConfirmModal"
      :title="confirmModalData.title"
      :message="confirmModalData.message"
      :variant="confirmModalData.variant"
      :loading="modalLoading"
      :confirm-text="confirmModalData.variant === 'success' ? 'Aprobar' : 'Rechazar'"
      @confirm="handleConfirm"
      @cancel="showConfirmModal = false"
    />
  </div>
</template>
