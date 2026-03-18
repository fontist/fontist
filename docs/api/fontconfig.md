---
title: Fontist::Fontconfig
---

# Fontist::Fontconfig

Fontist supports integration with Fontconfig via the Ruby interface.

## Overview

Fontconfig is a system for customizing and configuring font access. Fontist can update Fontconfig to detect fontist-managed fonts, allowing applications that use Fontconfig to find fonts installed by Fontist.

## Class Methods

### `.update`

Update Fontconfig to let it detect fontist fonts.

**Parameters:** None

**Returns:** `Boolean` — Success status

**Example:**

```ruby
Fontist::Fontconfig.update
# => true
```

This makes fonts installed by Fontist visible to applications that use Fontconfig for font discovery.

---

### `.remove(force: false)`

Disable detection of fontist fonts in Fontconfig.

**Parameters:**

| Param | Type | Description |
|-------|------|-------------|
| `force` | Boolean | If true, do not fail if no config exists |

**Returns:** `Boolean` — Success status

**Raises:** Error if config doesn't exist and `force` is `false`

**Example:**

```ruby
# Remove fontconfig integration
Fontist::Fontconfig.remove

# Remove without failing if config doesn't exist
Fontist::Fontconfig.remove(force: true)
```

## Typical Usage

A common workflow when working with Fontconfig integration:

```ruby
# Install a font
Fontist::Font.install("Open Sans", confirmation: "yes")

# Update Fontconfig to detect the new font
Fontist::Fontconfig.update

# Now applications using Fontconfig can find the font
```

When you no longer need Fontist fonts to be visible:

```ruby
# Remove Fontconfig integration
Fontist::Fontconfig.remove
```

## See Also

- [Fontist::Font](/api/font) — Font installation
- [Fontconfig CLI Reference](/cli/fontconfig) — Command-line interface
