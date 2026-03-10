---
title: Font Requirements
---

# Font Requirements

A **Font Requirement** specifies what fonts your project needs. This is the core abstraction that powers Fontist manifests.

## What is a Font Requirement?

A font requirement tells Fontist:

> "I need these specific fonts in these specific styles. Do they exist? If not, install them. Return the paths."

### Requirement Components

A complete font requirement includes:

| Component | Example | Required |
|-----------|---------|----------|
| Font name | `"Open Sans"` | Yes |
| Styles | `Regular`, `Bold` | Optional |
| Format | `ttf`, `otf` | Optional |
| Source | Specific formula | Optional |

---

## Manifests: Requirements in YAML

A **manifest** is a YAML file listing font requirements:

```yaml
# manifest.yml
Open Sans:
  - Regular
  - Bold

Roboto Mono:
  - Regular

Fira Code: []  # All styles
```

### How Fontist Processes a Manifest

```
manifest.yml
      │
      ▼
┌─────────────────┐
│ Read YAML       │
│ Requirements    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ For each font:  │
│                 │
│ Check system    │──▶ Found? ──▶ Return paths
│ fonts index     │
└────────┬────────┘
         │ Not found
         ▼
┌─────────────────┐
│ Check Fontist   │──▶ Found? ──▶ Return paths
│ fonts directory │
└────────┬────────┘
         │ Not found
         ▼
┌─────────────────┐
│ Search formulas │──▶ Found? ──▶ Download & Install
└────────┬────────┘
         │
         ▼
    Return paths (or error)
```

---

## CLI Commands

### Install from Manifest

```bash
# Install all fonts in manifest
fontist manifest-install manifest.yml

# With license acceptance (for CI)
fontist manifest-install --accept-all-licenses manifest.yml
```

### Check Without Installing

```bash
# Check if fonts are available
fontist manifest-check manifest.yml

# Returns exit code:
# 0 = all fonts available
# 3 = some fonts missing
```

### Get Locations

```bash
# Get paths to fonts (install if needed)
fontist manifest-locations manifest.yml
```

---

## Manifest Format

### Basic Format

```yaml
Font Family Name:
  - Style 1
  - Style 2
```

### Examples

```yaml
# Single font, single style
Helvetica:
  - Regular

# Single font, multiple styles
Open Sans:
  - Regular
  - Bold
  - Italic
  - Bold Italic

# All available styles
Fira Code: []

# Multiple fonts
Roboto:
  - Regular
  - Bold

Roboto Mono:
  - Regular
```

### Finding Font Names

```bash
# Search available fonts
fontist list "Segoe"

# Check specific font
fontist status "Open Sans"
```

---

## Ruby API

### From Hash

```ruby
manifest_hash = {
  "Open Sans" => ["Regular", "Bold"],
  "Roboto Mono" => ["Regular"]
}

manifest = Fontist::Manifest.from_hash(manifest_hash)
```

### From YAML File

```ruby
manifest = Fontist::Manifest.from_file("fonts.yml")
```

### Install and Get Paths

```ruby
# Install fonts and get locations
locations = manifest.install(confirmation: "yes")

# Result structure:
{
  "Open Sans" => {
    "Regular" => {
      "full_name" => "Open Sans",
      "paths" => ["/path/to/OpenSans-Regular.ttf"]
    },
    "Bold" => {
      "full_name" => "Open Sans Bold",
      "paths" => ["/path/to/OpenSans-Bold.ttf"]
    }
  }
}
```

### Get Locations Only

```ruby
# Get paths without installing
locations = Fontist::Manifest.from_file("fonts.yml").locations
```

---

## Use Cases

### CI/CD Pipelines

Ensure fonts are available for document generation:

```yaml
# .github/workflows/docs.yml
- name: Install fonts
  run: |
    gem install fontist
    fontist manifest-install --accept-all-licenses fonts.yml

- name: Build PDFs
  run: bundle exec rake build:pdfs
```

### Team Development

Share font requirements across team:

```yaml
# Commit fonts.yml to repository
Source Sans Pro:
  - Regular
  - Bold
  - Italic

# New team member runs:
fontist manifest-install fonts.yml
```

### Document Publishing

Ensure Metanorma/Asciidoctor fonts:

```yaml
# fonts.yml for document publishing
Noto Serif:
  - Regular
  - Bold
  - Italic

Source Code Pro:
  - Regular
```

---

## Error Handling

### Missing Fonts

```bash
fontist manifest-check manifest.yml
# Exit code 3: Font not found
```

### License Required

```bash
fontist manifest-install manifest.yml
# Exit code 4: License needs acceptance

# Solution:
fontist manifest-install --accept-all-licenses manifest.yml
```

### Manifest Not Found

```bash
fontist manifest-install missing.yml
# Exit code 5: Manifest file not found
```

### Invalid YAML

```bash
fontist manifest-install invalid.yml
# Exit code 6: Manifest could not be read
```

---

## Integration with Other Tools

### Metanorma

Metanorma uses Fontist for font management:

```ruby
# In Metanorma configuration
fontist:
  manifest: fonts.yml
```

### Asciidoctor PDF

```yaml
# asciidoctor-pdf-theme.yml
font:
  catalog:
    Open Sans:
      normal: OpenSans-Regular.ttf
      bold: OpenSans-Bold.ttf
```

### Prawn (Ruby PDF)

```ruby
require 'fontist'

# Install font
paths = Fontist::Font.install("Open Sans", confirmation: "yes")

# Use in Prawn
Prawn::Document.generate("output.pdf") do
  font paths.first
  text "Hello, World!"
end
```

---

## Best Practices

### 1. Version Control Your Manifest

```bash
git add fonts.yml
git commit -m "Add font manifest"
```

### 2. Document Font Sources

```yaml
# fonts.yml
# Fonts for PDF generation
# License: All fonts are SIL OFL

Roboto:  # Google Fonts, OFL-1.1
  - Regular
  - Bold
```

### 3. Use Specific Styles

```yaml
# Good: Specific styles
Open Sans:
  - Regular
  - Bold

# Avoid: All styles when not needed
Open Sans: []  # Downloads everything
```

### 4. Handle Errors in Scripts

```bash
#!/bin/bash
set -e

# Install fonts, handle missing fonts
if ! fontist manifest-check fonts.yml; then
  echo "Some fonts not available"
  exit 1
fi

fontist manifest-install --accept-all-licenses fonts.yml
```

---

## See Also

- [Manifests Guide](/guide/manifests) - Detailed manifest documentation
- [CLI Reference: manifest](/cli/manifest) - Manifest commands
- [API: Fontist::Manifest](/api/manifest) - Ruby API
- [CI/CD Integration](/guide/ci) - Using Fontist in CI
