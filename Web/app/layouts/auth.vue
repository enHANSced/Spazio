<template>
  <div class="relative min-h-screen bg-background-light dark:bg-background-dark">
    <div
      class="pointer-events-none absolute inset-0 bg-gradient-to-br from-primary/10 via-transparent to-primary/20"
      aria-hidden="true"
    />
    <div class="relative z-10 flex min-h-screen items-center justify-center px-4 py-10">
      <slot />
    </div>
  </div>
</template>
