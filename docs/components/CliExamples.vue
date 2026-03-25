<script setup>
import { computed } from 'vue'
const props = defineProps({
  command: { type: String, required: true }
})
import commands from '../.vitepress/data/cli-commands.json'
const cmd = computed(() => commands[props.command])
</script>

<template>
  <div v-if="cmd && cmd.examples">
    <div v-for="example in cmd.examples" :key="example.command" class="example">
      <p>{{ example.description }}</p>
      <pre><code>{{ example.command }}</code></pre>
    </div>
  </div>
</template>
