---
title: Fontist::Manifest
---

# Fontist::Manifest

The `Fontist::Manifest` interface allows you to work with multiple fonts at once using a manifest format.

## Overview

Manifests are useful when you need to:
- Find locations of multiple fonts in one operation
- Install multiple fonts from a single definition
- Integrate with build systems or configuration files

## Global Options

Fontist can be switched to use preferred family names. This format was used prior to v1.10.

```ruby
Fontist.preferred_family = true
```

## Manifest Format

The manifest format is a Hash (or YAML) with font names as keys and an array of styles as values:

```ruby
{
  "Segoe UI" => ["Regular", "Bold"],
  "Roboto Mono" => ["Regular"]
}
```

## Class Methods

### `.from_yaml(yaml_string)`

Create a manifest from a YAML string.

**Parameters:**

| Param | Type | Description |
|-------|------|-------------|
| `yaml_string` | String | YAML formatted manifest content |

**Returns:** `Fontist::Manifest` — Manifest object

**Example:**

```ruby
yaml = <<~YAML
  Segoe UI:
    - Regular
    - Bold
  Roboto Mono:
    - Regular
YAML

manifest = Fontist::Manifest.from_yaml(yaml)
```

---

### `.from_hash(hash)`

Create a manifest from a Hash.

**Parameters:**

| Param | Type | Description |
|-------|------|-------------|
| `hash` | Hash | Manifest hash with font names and styles |

**Returns:** `Fontist::Manifest` — Manifest object

**Example:**

```ruby
manifest = Fontist::Manifest.from_hash({
  "Segoe UI" => ["Regular", "Bold"],
  "Roboto Mono" => ["Regular"]
})
```

---

### `.from_file(path)`

Create a manifest from a YAML file.

**Parameters:**

| Param | Type | Description |
|-------|------|-------------|
| `path` | String | Path to the YAML manifest file |

**Returns:** `Fontist::Manifest` — Manifest object

**Example:**

Given a `manifest.yml` file:

```yaml
---
Segoe UI:
  - Regular
  - Bold
Roboto Mono:
  - Regular
```

```ruby
manifest = Fontist::Manifest.from_file("manifest.yml")
```

## Instance Methods

### `.locations`

Get font locations from the manifest.

**Returns:** `Hash` — Nested hash with font paths and names

**Example:**

```ruby
manifest = Fontist::Manifest.from_hash({
  "Segoe UI" => ["Regular", "Bold"]
})
locations = manifest.locations

# Returns:
# {
#   "Segoe UI" => {
#     "Regular" => {
#       "full_name" => "Segoe UI",
#       "paths" => ["/Users/user/.fontist/fonts/SEGOEUI.TTF"]
#     },
#     "Bold" => {
#       "full_name" => "Segoe UI Bold",
#       "paths" => ["/Users/user/.fontist/fonts/SEGOEUIB.TTF"]
#     }
#   }
# }
```

---

### `.install(confirmation: "no")`

Install fonts from the manifest and return their locations.

**Parameters:**

| Param | Type | Description |
|-------|------|-------------|
| `confirmation` | String | License confirmation, use `"yes"` to accept license |

**Returns:** `Hash` — Nested hash with font paths and names

**Example:**

```ruby
manifest = Fontist::Manifest.from_file("manifest.yml")
locations = manifest.install(confirmation: "yes")

# Returns installed font locations:
# {
#   "Segoe UI" => {
#     "Regular" => {
#       "full_name" => "Segoe UI",
#       "paths" => ["/Users/user/.fontist/fonts/SEGOEUI.TTF"]
#     },
#     "Bold" => {
#       "full_name" => "Segoe UI Bold",
#       "paths" => ["/Users/user/.fontist/fonts/SEGOEUIB.TTF"]
#     }
#   },
#   "Roboto Mono" => {
#     "Regular" => {
#       "full_name" => "Roboto Mono Regular",
#       "paths" => ["/Users/user/.fontist/fonts/RobotoMono-VariableFont_wght.ttf"]
#     }
#   }
# }
```

## Return Value Structure

The return value from `locations` or `install` is a nested Hash:

```ruby
{
  "Font Name" => {
    "Style Name" => {
      "full_name" => "Full Font Name",  # String or nil if not found
      "paths" => ["/path/to/font.ttf"]   # Array of paths, empty if not found
    }
  }
}
```

The `full_name` field is useful to choose a specific font in a font collection file (TTC).

## See Also

- [Fontist::Font](/api/font) — Individual font installation
- [Fontist::Formula](/api/formula) — Formula information
