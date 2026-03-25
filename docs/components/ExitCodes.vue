<script setup>
import exitCodes from '../.vitepress/data/exit-codes.json'
</script>

<template>
  <table>
    <thead>
      <tr><th>Code</th><th>Name</th><th>Description</th></tr>
    </thead>
    <tbody>
      <tr v-for="code in exitCodes.codes" :key="code.code">
        <td><code>{{ code.code }}</code></td>
        <td>{{ code.name }}</td>
        <td>{{ code.description }}</td>
      </tr>
    </tbody>
  </table>
</template>
