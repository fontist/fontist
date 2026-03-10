---
title: Getting Started
---

# Getting Started

Fontist is a cross-platform font manager that installs fonts with a single command. It works consistently across macOS, Windows, and Linux, making it ideal for local development and CI/CD pipelines.

## Overview

Fontist provides a unified API for installing and managing fonts across different operating systems. Instead of manually downloading fonts and placing them in system folders, you can use `fontist install` to manage fonts programmatically.

Fontist uses a **formula repository** to locate and download fonts. The main repository includes Google Fonts, SIL Fonts, macOS fonts, and many others.

## Key Concepts

- **[Font Concepts](/guide/concepts/)**: Understand fonts, styles, weights, formats, containers, variable fonts, and licenses.
- **Formulas**: YAML files that describe where to download fonts and how to install them. Formulas are maintained in the [fontist/formulas](https://github.com/fontist/formulas) repository.
- **Manifests**: YAML files that specify which fonts your project needs. Manifests enable reproducible font installations across teams and CI environments.
- **Locations**: Fonts can be installed to Fontist's own directory, the user's fonts folder, or system-wide (with appropriate permissions).

## Quick Start

Install Fontist via RubyGems:

```sh
gem install fontist
```

Install your first font:

```sh
fontist install "Fira Code"
```

Check installed fonts:

```sh
fontist status
```

## Next Steps

- [Installation Guide](/guide/installation) - Detailed installation instructions and platform-specific notes
- [Quick Start Tutorial](/guide/quick-start) - A 5-minute guide to get up and running
- [CLI Reference](/cli/) - Complete command documentation
