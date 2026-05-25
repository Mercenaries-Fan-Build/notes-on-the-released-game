<template>
  <div class="flex h-screen flex-col">
    <AppNavbar />
    <main class="flex-1 overflow-hidden">
      <router-view />
    </main>
  </div>
</template>

<script setup>
import AppNavbar from './components/AppNavbar.vue'
</script>
