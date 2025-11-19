<script setup lang="ts">
import { useAuthStore } from '../../stores/auth'

definePageMeta({
  layout: 'owner',
  middleware: 'owner'
})

useSeoMeta({
  title: 'Verificación Pendiente - Spazio',
  description: 'Tu cuenta de propietario está pendiente de verificación'
})

const authStore = useAuthStore()
</script>

<template>
  <div class="flex min-h-full items-center justify-center">
    <div class="w-full max-w-2xl rounded-2xl bg-white p-8 shadow-lg ring-1 ring-black/5">
      <div class="text-center">
        <!-- Icon -->
        <div class="mx-auto flex h-16 w-16 items-center justify-center rounded-full bg-amber-100">
          <span class="material-symbols-outlined text-4xl text-amber-600">pending</span>
        </div>

        <!-- Title -->
        <h1 class="mt-6 text-3xl font-bold text-[#111418]">
          Verificación Pendiente
        </h1>

        <!-- Description -->
        <p class="mt-4 text-base text-slate-600">
          Tu cuenta de propietario está siendo revisada por nuestro equipo. Este proceso puede tardar entre 24 y 48 horas.
        </p>

        <!-- Info Box -->
        <div class="mt-8 rounded-xl bg-slate-50 p-6 text-left">
          <h2 class="text-sm font-semibold uppercase tracking-wide text-slate-500">
            Información de tu cuenta
          </h2>
          
          <dl class="mt-4 space-y-3">
            <div class="flex justify-between">
              <dt class="text-sm text-slate-600">Nombre del negocio:</dt>
              <dd class="text-sm font-semibold text-[#111418]">
                {{ authStore.user?.businessName || 'No especificado' }}
              </dd>
            </div>
            
            <div class="flex justify-between">
              <dt class="text-sm text-slate-600">Email de contacto:</dt>
              <dd class="text-sm font-semibold text-[#111418]">
                {{ authStore.user?.email }}
              </dd>
            </div>
            
            <div class="flex justify-between">
              <dt class="text-sm text-slate-600">Estado:</dt>
              <dd class="inline-flex items-center gap-1.5 rounded-full bg-amber-100 px-3 py-1 text-xs font-semibold text-amber-700">
                <span class="h-1.5 w-1.5 rounded-full bg-amber-500"></span>
                Pendiente de verificación
              </dd>
            </div>
          </dl>
        </div>

        <!-- Instructions -->
        <div class="mt-6 rounded-xl border border-blue-100 bg-blue-50 p-4">
          <div class="flex items-start gap-3">
            <span class="material-symbols-outlined text-2xl text-blue-600">info</span>
            <div class="flex-1 text-left">
              <h3 class="text-sm font-semibold text-blue-900">¿Qué sigue?</h3>
              <p class="mt-1 text-sm text-blue-700">
                Una vez que tu cuenta sea verificada, recibirás un correo electrónico de confirmación y podrás comenzar a crear y gestionar tus espacios.
              </p>
            </div>
          </div>
        </div>

        <!-- Actions -->
        <div class="mt-8 flex flex-col gap-3 sm:flex-row sm:justify-center">
          <NuxtLink
            to="/"
            class="inline-flex items-center justify-center gap-2 rounded-xl bg-slate-100 px-6 py-3 text-sm font-semibold text-slate-700 transition hover:bg-slate-200"
          >
            <span class="material-symbols-outlined text-xl">home</span>
            Ir al inicio
          </NuxtLink>
          
          <button
            class="inline-flex items-center justify-center gap-2 rounded-xl bg-primary px-6 py-3 text-sm font-semibold text-white transition hover:bg-primary/90"
            @click="authStore.logout(); navigateTo('/auth/login')"
          >
            <span class="material-symbols-outlined text-xl">logout</span>
            Cerrar sesión
          </button>
        </div>

        <!-- Support -->
        <p class="mt-8 text-sm text-slate-500">
          ¿Tienes preguntas? Contáctanos a
          <a href="mailto:soporte@spazio.com" class="font-semibold text-primary hover:underline">
            soporte@spazio.com
          </a>
        </p>
      </div>
    </div>
  </div>
</template>
