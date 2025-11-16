<template>
  <div class="min-h-screen bg-background-light text-[#111418]">
    <header class="border-b border-slate-200 bg-white/80 backdrop-blur">
      <div class="mx-auto flex max-w-6xl items-center justify-between px-6 py-4">
        <NuxtLink to="/" class="text-2xl font-bold text-primary">Spazio</NuxtLink>
        <slot name="header" />
      </div>
    </header>
    <main class="mx-auto max-w-6xl px-6 py-10">
      <slot />
    </main>
  </div>
</template>
