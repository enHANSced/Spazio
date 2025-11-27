<script setup lang="ts">
import { ref, watch, onMounted } from 'vue'
import { adminService, type AdminUser, type Pagination } from '../../../services/admin.service'
import { useToast } from '../../../composables/useToast'

definePageMeta({
  layout: 'admin',
  middleware: 'admin'
})

useSeoMeta({
  title: 'Gestión de Usuarios - Admin Spazio',
  description: 'Administrar usuarios del sistema'
})

const toast = useToast()

// State
const users = ref<AdminUser[]>([])
const pagination = ref<Pagination | null>(null)
const loading = ref(true)
const currentPage = ref(1)
const limit = ref(10)

// Filters
const searchQuery = ref('')
const roleFilter = ref('')
const statusFilter = ref('')

// Modal state
const showConfirmModal = ref(false)
const confirmModalData = ref({
  title: '',
  message: '',
  variant: 'danger' as 'danger' | 'warning' | 'info' | 'success',
  action: null as (() => Promise<void>) | null
})
const modalLoading = ref(false)

// Edit modal
const showEditModal = ref(false)
const editingUser = ref<AdminUser | null>(null)
const editForm = ref({
  name: '',
  role: '' as 'user' | 'owner' | 'admin',
  isVerified: false
})
const editLoading = ref(false)

const loadUsers = async () => {
  loading.value = true
  
  try {
    const params: any = {
      page: currentPage.value,
      limit: limit.value
    }

    if (searchQuery.value) params.search = searchQuery.value
    if (roleFilter.value) params.role = roleFilter.value
    if (statusFilter.value === 'active') params.isActive = true
    if (statusFilter.value === 'inactive') params.isActive = false

    const response = await adminService.getUsers(params)
    
    if (response.success) {
      users.value = response.data
      pagination.value = response.pagination
    } else {
      toast.error(response.message || 'Error al cargar usuarios')
    }
  } catch (err: any) {
    toast.error(err.message || 'Error inesperado')
  } finally {
    loading.value = false
  }
}

// Debounce search
let searchTimeout: ReturnType<typeof setTimeout>
watch(searchQuery, () => {
  clearTimeout(searchTimeout)
  searchTimeout = setTimeout(() => {
    currentPage.value = 1
    loadUsers()
  }, 300)
})

watch([roleFilter, statusFilter], () => {
  currentPage.value = 1
  loadUsers()
})

const handlePageChange = (page: number) => {
  currentPage.value = page
  loadUsers()
}

const getRoleBadgeClass = (role: string) => {
  switch (role) {
    case 'admin':
      return 'bg-rose-100 text-rose-700'
    case 'owner':
      return 'bg-purple-100 text-purple-700'
    default:
      return 'bg-blue-100 text-blue-700'
  }
}

const getRoleLabel = (role: string) => {
  const labels: Record<string, string> = {
    admin: 'Admin',
    owner: 'Propietario',
    user: 'Usuario'
  }
  return labels[role] || role
}

const formatDate = (dateString?: string) => {
  if (!dateString) return '-'
  const date = new Date(dateString)
  return date.toLocaleDateString('es-ES', {
    day: '2-digit',
    month: 'short',
    year: 'numeric'
  })
}

// Toggle active
const confirmToggleActive = (user: AdminUser) => {
  const action = user.isActive ? 'desactivar' : 'activar'
  confirmModalData.value = {
    title: `${user.isActive ? 'Desactivar' : 'Activar'} Usuario`,
    message: `¿Estás seguro de que deseas ${action} a "${user.name}"? ${user.isActive ? 'No podrá acceder al sistema.' : 'Podrá acceder nuevamente al sistema.'}`,
    variant: user.isActive ? 'danger' : 'success',
    action: async () => {
      const response = await adminService.toggleUserActive(user.id)
      if (response.success) {
        toast.success(response.message || 'Usuario actualizado')
        loadUsers()
      } else {
        toast.error(response.message || 'Error al actualizar usuario')
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

// Edit user
const openEditModal = (user: AdminUser) => {
  editingUser.value = user
  editForm.value = {
    name: user.name,
    role: user.role,
    isVerified: user.isVerified
  }
  showEditModal.value = true
}

const handleEditSubmit = async () => {
  if (!editingUser.value) return

  editLoading.value = true
  try {
    const response = await adminService.updateUser(editingUser.value.id, editForm.value)
    if (response.success) {
      toast.success('Usuario actualizado correctamente')
      showEditModal.value = false
      loadUsers()
    } else {
      toast.error(response.message || 'Error al actualizar')
    }
  } catch (err: any) {
    toast.error(err.message || 'Error inesperado')
  } finally {
    editLoading.value = false
  }
}

onMounted(() => {
  loadUsers()
})
</script>

<template>
  <div class="space-y-6">
    <!-- Header -->
    <div class="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
      <div>
        <h1 class="text-2xl font-bold text-[#111418]">Gestión de Usuarios</h1>
        <p class="mt-1 text-sm text-slate-600">
          Administra todos los usuarios registrados en el sistema
        </p>
      </div>
    </div>

    <!-- Filters -->
    <div class="rounded-xl border border-slate-200 bg-white p-4 shadow-sm">
      <div class="grid gap-4 sm:grid-cols-4">
        <!-- Search -->
        <div class="sm:col-span-2">
          <label class="mb-1 block text-xs font-medium text-slate-600">Buscar</label>
          <div class="relative">
            <span class="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-xl text-slate-400">
              search
            </span>
            <input
              v-model="searchQuery"
              type="text"
              placeholder="Buscar por nombre o email..."
              class="w-full rounded-lg border border-slate-200 py-2 pl-10 pr-4 text-sm focus:border-rose-500 focus:outline-none focus:ring-1 focus:ring-rose-500"
            />
          </div>
        </div>

        <!-- Role filter -->
        <div>
          <label class="mb-1 block text-xs font-medium text-slate-600">Rol</label>
          <select
            v-model="roleFilter"
            class="w-full rounded-lg border border-slate-200 px-3 py-2 text-sm focus:border-rose-500 focus:outline-none focus:ring-1 focus:ring-rose-500"
          >
            <option value="">Todos los roles</option>
            <option value="user">Usuarios</option>
            <option value="owner">Propietarios</option>
            <option value="admin">Administradores</option>
          </select>
        </div>

        <!-- Status filter -->
        <div>
          <label class="mb-1 block text-xs font-medium text-slate-600">Estado</label>
          <select
            v-model="statusFilter"
            class="w-full rounded-lg border border-slate-200 px-3 py-2 text-sm focus:border-rose-500 focus:outline-none focus:ring-1 focus:ring-rose-500"
          >
            <option value="">Todos</option>
            <option value="active">Activos</option>
            <option value="inactive">Inactivos</option>
          </select>
        </div>
      </div>
    </div>

    <!-- Table -->
    <div class="overflow-hidden rounded-xl border border-slate-200 bg-white shadow-sm">
      <!-- Loading -->
      <div v-if="loading" class="flex items-center justify-center py-12">
        <div class="flex items-center gap-3 text-slate-600">
          <div class="h-6 w-6 animate-spin rounded-full border-2 border-slate-300 border-t-rose-600" />
          <span class="text-sm font-medium">Cargando usuarios...</span>
        </div>
      </div>

      <!-- Empty -->
      <div v-else-if="users.length === 0" class="py-12 text-center">
        <span class="material-symbols-outlined text-4xl text-slate-300">group_off</span>
        <p class="mt-2 text-sm text-slate-600">No se encontraron usuarios</p>
      </div>

      <!-- Table content -->
      <template v-else>
        <div class="overflow-x-auto">
          <table class="w-full">
            <thead class="border-b border-slate-200 bg-slate-50">
              <tr>
                <th class="px-4 py-3 text-left text-xs font-semibold uppercase text-slate-600">
                  Usuario
                </th>
                <th class="px-4 py-3 text-left text-xs font-semibold uppercase text-slate-600">
                  Rol
                </th>
                <th class="px-4 py-3 text-left text-xs font-semibold uppercase text-slate-600">
                  Estado
                </th>
                <th class="px-4 py-3 text-left text-xs font-semibold uppercase text-slate-600">
                  Verificación
                </th>
                <th class="px-4 py-3 text-left text-xs font-semibold uppercase text-slate-600">
                  Registro
                </th>
                <th class="px-4 py-3 text-right text-xs font-semibold uppercase text-slate-600">
                  Acciones
                </th>
              </tr>
            </thead>
            <tbody class="divide-y divide-slate-100">
              <tr
                v-for="user in users"
                :key="user.id"
                class="transition hover:bg-slate-50"
              >
                <td class="px-4 py-3">
                  <div class="flex items-center gap-3">
                    <div class="flex h-10 w-10 flex-shrink-0 items-center justify-center rounded-full bg-slate-100">
                      <span class="material-symbols-outlined text-xl text-slate-600">person</span>
                    </div>
                    <div>
                      <p class="text-sm font-semibold text-[#111418]">{{ user.name }}</p>
                      <p class="text-xs text-slate-500">{{ user.email }}</p>
                    </div>
                  </div>
                </td>
                <td class="px-4 py-3">
                  <span
                    class="inline-flex rounded-full px-2.5 py-1 text-xs font-semibold"
                    :class="getRoleBadgeClass(user.role)"
                  >
                    {{ getRoleLabel(user.role) }}
                  </span>
                </td>
                <td class="px-4 py-3">
                  <span
                    class="inline-flex items-center gap-1 rounded-full px-2.5 py-1 text-xs font-semibold"
                    :class="user.isActive ? 'bg-green-100 text-green-700' : 'bg-slate-100 text-slate-600'"
                  >
                    <span class="h-1.5 w-1.5 rounded-full" :class="user.isActive ? 'bg-green-500' : 'bg-slate-400'" />
                    {{ user.isActive ? 'Activo' : 'Inactivo' }}
                  </span>
                </td>
                <td class="px-4 py-3">
                  <span
                    v-if="user.role === 'owner'"
                    class="inline-flex items-center gap-1 text-xs font-medium"
                    :class="user.isVerified ? 'text-green-600' : 'text-amber-600'"
                  >
                    <span class="material-symbols-outlined !text-[16px]">
                      {{ user.isVerified ? 'verified' : 'pending' }}
                    </span>
                    {{ user.isVerified ? 'Verificado' : 'Pendiente' }}
                  </span>
                  <span v-else class="text-xs text-slate-400">-</span>
                </td>
                <td class="px-4 py-3">
                  <span class="text-sm text-slate-600">{{ formatDate(user.createdAt) }}</span>
                </td>
                <td class="px-4 py-3">
                  <div class="flex items-center justify-end gap-2">
                    <button
                      class="rounded-lg p-2 text-slate-600 transition hover:bg-slate-100"
                      title="Editar usuario"
                      @click="openEditModal(user)"
                    >
                      <span class="material-symbols-outlined text-xl">edit</span>
                    </button>
                    <button
                      v-if="user.role !== 'admin'"
                      class="rounded-lg p-2 transition"
                      :class="user.isActive ? 'text-rose-600 hover:bg-rose-50' : 'text-green-600 hover:bg-green-50'"
                      :title="user.isActive ? 'Desactivar' : 'Activar'"
                      @click="confirmToggleActive(user)"
                    >
                      <span class="material-symbols-outlined text-xl">
                        {{ user.isActive ? 'person_off' : 'person_add' }}
                      </span>
                    </button>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <!-- Pagination -->
        <div v-if="pagination" class="border-t border-slate-200 px-4 py-3">
          <AdminPagination
            :current-page="pagination.page"
            :total-pages="pagination.totalPages"
            :total="pagination.total"
            :limit="pagination.limit"
            @page-change="handlePageChange"
          />
        </div>
      </template>
    </div>

    <!-- Confirm Modal -->
    <ConfirmModal
      :show="showConfirmModal"
      :title="confirmModalData.title"
      :message="confirmModalData.message"
      :variant="confirmModalData.variant"
      :loading="modalLoading"
      @confirm="handleConfirm"
      @cancel="showConfirmModal = false"
    />

    <!-- Edit Modal -->
    <Teleport to="body">
      <Transition
        enter-active-class="transition-opacity duration-200"
        leave-active-class="transition-opacity duration-200"
        enter-from-class="opacity-0"
        leave-to-class="opacity-0"
      >
        <div
          v-if="showEditModal"
          class="fixed inset-0 z-50 flex items-center justify-center p-4"
        >
          <div class="absolute inset-0 bg-black/50" @click="!editLoading && (showEditModal = false)" />
          
          <div class="relative w-full max-w-md rounded-xl bg-white p-6 shadow-xl">
            <h3 class="text-lg font-semibold text-[#111418]">Editar Usuario</h3>
            <p class="mt-1 text-sm text-slate-600">{{ editingUser?.email }}</p>

            <form class="mt-6 space-y-4" @submit.prevent="handleEditSubmit">
              <div>
                <label class="mb-1 block text-sm font-medium text-slate-700">Nombre</label>
                <input
                  v-model="editForm.name"
                  type="text"
                  class="w-full rounded-lg border border-slate-200 px-3 py-2 text-sm focus:border-rose-500 focus:outline-none focus:ring-1 focus:ring-rose-500"
                  required
                />
              </div>

              <div>
                <label class="mb-1 block text-sm font-medium text-slate-700">Rol</label>
                <select
                  v-model="editForm.role"
                  class="w-full rounded-lg border border-slate-200 px-3 py-2 text-sm focus:border-rose-500 focus:outline-none focus:ring-1 focus:ring-rose-500"
                >
                  <option value="user">Usuario</option>
                  <option value="owner">Propietario</option>
                  <option value="admin">Administrador</option>
                </select>
              </div>

              <div v-if="editForm.role === 'owner'" class="flex items-center gap-3">
                <input
                  id="isVerified"
                  v-model="editForm.isVerified"
                  type="checkbox"
                  class="h-4 w-4 rounded border-slate-300 text-rose-600 focus:ring-rose-500"
                />
                <label for="isVerified" class="text-sm text-slate-700">
                  Propietario verificado
                </label>
              </div>

              <div class="flex gap-3 pt-4">
                <button
                  type="button"
                  class="flex-1 rounded-lg border border-slate-200 bg-white px-4 py-2.5 text-sm font-semibold text-slate-700 transition hover:bg-slate-50"
                  :disabled="editLoading"
                  @click="showEditModal = false"
                >
                  Cancelar
                </button>
                <button
                  type="submit"
                  class="flex flex-1 items-center justify-center gap-2 rounded-lg bg-rose-600 px-4 py-2.5 text-sm font-semibold text-white transition hover:bg-rose-700 disabled:opacity-50"
                  :disabled="editLoading"
                >
                  <span
                    v-if="editLoading"
                    class="h-4 w-4 animate-spin rounded-full border-2 border-white/30 border-t-white"
                  />
                  Guardar
                </button>
              </div>
            </form>
          </div>
        </div>
      </Transition>
    </Teleport>
  </div>
</template>
