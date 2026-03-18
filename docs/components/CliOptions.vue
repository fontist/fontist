<script setup>
import { computed } from 'vue'
const props = defineProps({
  command: { type: String, required: true }
})
import commands from '../.vitepress/data/cli-commands.json'
const cmd = computed(() => commands[props.command])
</script>

<template>
  <div v-if="cmd">
    <table>
      <thead>
        <tr><th>Option</th><th>Alias</th><th>Type</th><th>Description</th></tr>
      </thead>
      <tbody>
        <tr v-for="opt in cmd.options" :key="opt.name">
          <td><code>--{{ opt.name }}</code></td>
          <td><code v-if="opt.alias">-{{ opt.alias }}</code></td>
          <td>{{ opt.type }}</td>
          <td>{{ opt.description }}</td>
        </tr>
      </tbody>
    </table>
  </div>
</template>
