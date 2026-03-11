<script setup>
defineProps({
  title: {
    type: String,
    default: 'Terminal'
  }
})
</script>

<template>
  <div class="hero-code-block">
    <div class="code-header">
      <span class="dot"></span>
      <span class="dot"></span>
      <span class="dot"></span>
      <span class="code-title">{{ title }}</span>
    </div>
    <div class="code-content"><slot /></div>
  </div>
</template>

<style scoped>
.hero-code-block {
  background: var(--vp-c-bg-soft);
  border: 1px solid var(--vp-c-divider);
  border-radius: 12px;
  overflow: hidden;
  box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06);
  max-width: 550px;
  width: 100%;
  font-size: 0.85rem;
}

@media (max-width: 768px) {
  .hero-code-block {
    max-width: 100%;
    font-size: 0.8rem;
  }
}

.code-header {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.75rem 1rem;
  background: var(--vp-c-bg-alt);
  border-bottom: 1px solid var(--vp-c-divider);
}

.dot {
  width: 12px;
  height: 12px;
  border-radius: 50%;
  flex-shrink: 0;
}

.dot:nth-child(1) { background: #ff5f56; }
.dot:nth-child(2) { background: #ffbd2e; }
.dot:nth-child(3) { background: #28c840; }

.code-title {
  margin-left: auto;
  font-size: 0.8rem;
  color: var(--vp-c-text-3);
}

.code-content {
  margin: 0;
  padding: 1.25rem;
  font-family: var(--vp-font-family-mono);
  font-size: inherit;
  line-height: 1.7;
  overflow-x: auto;
  -webkit-overflow-scrolling: touch;
}

.code-content :deep(.line) {
  display: block;
}

.code-content :deep(.prompt) {
  color: var(--vp-c-brand-1);
  font-weight: 500;
}

.code-content :deep(.success) {
  color: #28c840;
}

.code-content :deep(.comment) {
  color: var(--vp-c-text-3);
  font-style: italic;
}

.code-content :deep(.cmd) {
  font-weight: 600;
}
</style>
