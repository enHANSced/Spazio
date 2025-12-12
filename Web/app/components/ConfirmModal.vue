<script setup lang="ts">
interface Props {
  show: boolean
  title: string
  message: string
  confirmText?: string
  cancelText?: string
  variant?: 'danger' | 'warning' | 'info' | 'success'
  loading?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  confirmText: 'Confirmar',
  cancelText: 'Cancelar',
  variant: 'danger',
  loading: false
})

const emit = defineEmits<{
  confirm: []
  cancel: []
}>()

const variantStyles = {
  danger: {
    icon: 'warning',
    iconBg: 'bg-rose-100',
    iconColor: 'text-rose-600',
    buttonBg: 'bg-rose-600 hover:bg-rose-700 focus:ring-rose-500'
  },
  warning: {
    icon: 'error',
    iconBg: 'bg-amber-100',
    iconColor: 'text-amber-600',
    buttonBg: 'bg-amber-600 hover:bg-amber-700 focus:ring-amber-500'
  },
  info: {
    icon: 'info',
    iconBg: 'bg-blue-100',
    iconColor: 'text-blue-600',
    buttonBg: 'bg-blue-600 hover:bg-blue-700 focus:ring-blue-500'
  },
  success: {
    icon: 'check_circle',
    iconBg: 'bg-green-100',
    iconColor: 'text-green-600',
    buttonBg: 'bg-green-600 hover:bg-green-700 focus:ring-green-500'
  }
}

const currentStyle = computed(() => variantStyles[props.variant])
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
          @click="!loading && emit('cancel')"
        />

        <!-- Modal -->
        <Transition
          enter-active-class="transition-all duration-200"
          leave-active-class="transition-all duration-200"
          enter-from-class="opacity-0 scale-95"
          leave-to-class="opacity-0 scale-95"
        >
          <div
            v-if="show"
            class="relative w-full max-w-md rounded-xl bg-white p-6 shadow-xl"
          >
            <!-- Icon -->
            <div class="flex justify-center">
              <div
                class="flex h-12 w-12 items-center justify-center rounded-full"
                :class="currentStyle.iconBg"
              >
                <span
                  class="material-symbols-outlined text-2xl"
                  :class="currentStyle.iconColor"
                >
                  {{ currentStyle.icon }}
                </span>
              </div>
            </div>

            <!-- Content -->
            <div class="mt-4 text-center">
              <h3 class="text-lg font-semibold text-[#111418]">
                {{ title }}
              </h3>
              <p class="mt-2 text-sm text-slate-600">
                {{ message }}
              </p>
            </div>

            <!-- Actions -->
            <div class="mt-6 flex gap-3">
              <button
                type="button"
                class="flex-1 rounded-lg border border-slate-200 bg-white px-4 py-2.5 text-sm font-semibold text-slate-700 transition hover:bg-slate-50 focus:outline-none focus:ring-2 focus:ring-slate-200 disabled:opacity-50"
                :disabled="loading"
                @click="emit('cancel')"
              >
                {{ cancelText }}
              </button>
              <button
                type="button"
                class="flex flex-1 items-center justify-center gap-2 rounded-lg px-4 py-2.5 text-sm font-semibold text-white transition focus:outline-none focus:ring-2 focus:ring-offset-2 disabled:opacity-50"
                :class="currentStyle.buttonBg"
                :disabled="loading"
                @click="emit('confirm')"
              >
                <span
                  v-if="loading"
                  class="h-4 w-4 animate-spin rounded-full border-2 border-white/30 border-t-white"
                />
                {{ confirmText }}
              </button>
            </div>
          </div>
        </Transition>
      </div>
    </Transition>
  </Teleport>
</template>
