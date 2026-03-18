<script setup>
import { computed } from 'vue'
const props = defineProps({
  command: { type: String, required: true }
})
import commands from '../.vitepress/data/cli-commands.json'
const cmd = computed(() => commands[props.command])
</script>

<template>
  <div v-if="cmd" class="cli-command">
    <p class="description">{{ cmd.description }}</p>
    <pre class="syntax"><code>{{ cmd.syntax }}</code></pre>

    <h3 v-if="cmd.arguments && cmd.arguments.length">Arguments</h3>
    <table v-if="cmd.arguments && cmd.arguments.length">
      <thead><tr><th>Name</th><th>Required</th><th>Description</th></tr></thead>
      <tbody>
        <tr v-for="arg in cmd.arguments" :key="arg.name">
          <td><code>{{ arg.name }}</code></td>
          <td>{{ arg.required ? 'Yes' : 'No' }}</td>
          <td>{{ arg.description }}</td>
        </tr>
      </tbody>
    </table>

    <h3 v-if="cmd.options && cmd.options.length">Options</h3>
    <table v-if="cmd.options && cmd.options.length">
      <thead><tr><th>Option</th><th>Alias</th><th>Type</th><th>Description</th></tr></thead>
      <tbody>
        <tr v-for="opt in cmd.options" :key="opt.name">
          <td><code>--{{ opt.name }}</code></td>
          <td><code v-if="opt.alias">-{{ opt.alias }}</code></td>
          <td>{{ opt.type }}</td>
          <td>{{ opt.description }}</td>
        </tr>
      </tbody>
    </table>

    <h3 v-if="cmd.examples && cmd.examples.length">Examples</h3>
    <div v-if="cmd.examples && cmd.examples.length" class="examples">
      <div v-for="example in cmd.examples" :key="example.command" class="example">
        <p>{{ example.description }}</p>
        <pre><code>{{ example.command }}</code></pre>
      </div>
    </div>

    <p v-if="cmd.related && cmd.related.length" class="related">
      <strong>Related:</strong>
      <span v-for="rel in cmd.related" :key="rel">
        <a :href="`/cli/${rel}`">{{ rel }}</a>{{ rel !== cmd.related[cmd.related.length-1] ? ', ' : '' }}
      </span>
    </p>
  </div>
</template>

<style scoped>
.cli-command .syntax {
  margin: 1rem 0;
}
.example {
  margin: 0.5rem 0;
}
.example p {
  margin: 0;
  font-weight: 500;
}
.example pre {
  margin: 0.25rem 0;
  padding: 0.75rem;
  background: var(--vp-code-block-bg);
  border-radius: 4px;
}
.related {
  margin-top: 1.5rem;
}
</style>
