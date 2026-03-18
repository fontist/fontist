<template>
  <ClientOnly>
    <Teleport to=".VPHero > .container">
      <div class="within-hero__slot-container">
        <slot />
      </div>
    </Teleport>
  </ClientOnly>
</template>

<style>
.within-hero__slot-container {
  order: 2;
}

.VPHero > .container > .main {
  width: unset;
  flex-shrink: unset;
}

.VPHero > .container {
  gap: 32px;
}

@media (min-width: 960px) {
  .VPHero > .container {
    gap: 64px;
  }
}
</style>
