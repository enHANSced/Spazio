<script setup lang="ts">
definePageMeta({
  middleware: 'auth'
})

const { user, logout } = useAuth()
</script>

<template>
  <section class="space-y-6">
    <header>
      <p class="text-sm uppercase tracking-wide text-slate-500">Bienvenido</p>
      <h1 class="text-3xl font-semibold text-[#111418]">Hola, {{ user?.name ?? 'Usuario' }}</h1>
      <p class="text-base text-slate-600">Este dashboard es un placeholder mientras construimos el resto de la experiencia.</p>
    </header>

    <div class="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
      <h2 class="text-xl font-semibold text-[#111418]">Estado de tu cuenta</h2>
      <dl class="mt-4 grid gap-4 sm:grid-cols-2">
        <div class="rounded-xl bg-slate-50 p-4">
          <dt class="text-sm text-slate-500">Correo</dt>
          <dd class="text-lg font-medium text-[#111418]">{{ user?.email }}</dd>
        </div>
        <div class="rounded-xl bg-slate-50 p-4">
          <dt class="text-sm text-slate-500">Rol</dt>
          <dd class="text-lg font-medium capitalize text-[#111418]">{{ user?.role }}</dd>
        </div>
      </dl>

      <button
        type="button"
        class="mt-6 inline-flex items-center justify-center rounded-lg border border-primary/30 px-5 py-2.5 text-sm font-semibold text-primary hover:bg-primary/5"
        @click="logout"
      >
        Cerrar sesión
      </button>
    </div>
  </section>
</template>
