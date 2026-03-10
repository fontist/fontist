---
title: Quick Start
---

# Quick Start

Get up and running with Fontist in 5 minutes. This guide walks through installing a font, checking its status, and using it in a manifest.

## Step 1: Install a Font

Install your first font using the `install` command:

```sh
fontist install "Fira Code"
```

Some fonts may require you to accept license terms. Use the `--accept-all-licenses` flag to skip prompts (useful for CI):

```sh
fontist install "Fira Code" --accept-all-licenses
```

## Step 2: Check Installation Status

Verify the font was installed correctly:

```sh
fontist status
```

This shows all installed fonts and their paths:

```
Fira Code
  Regular: ~/.fontist/fonts/FiraCode-Regular.ttf
  Bold: ~/.fontist/fonts/FiraCode-Bold.ttf
```

To see all available fonts (installed and installable):

```sh
fontist list
```

## Step 3: Use a Manifest

Manifests let you define project fonts in a YAML file for reproducible installations.

Create a `fonts.yml` file:

```yaml
Fira Code:
Open Sans:
Roboto:
```

Install all fonts from the manifest:

```sh
fontist manifest install fonts.yml
```

Get the installation paths for manifest fonts:

```sh
fontist manifest locations fonts.yml
```

This outputs a YAML structure with font paths, which can be used in your build scripts or applications.

## What's Next?

- [Manifests Guide](/guide/manifests) - Deep dive into manifest format and use cases
- [Formulas Guide](/guide/formulas) - Learn how Fontist finds and downloads fonts
- [CLI Reference](/cli/) - Explore all available commands
- [Ruby API](/api/) - Use Fontist programmatically from Ruby
