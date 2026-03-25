---
title: API Reference
---

# Fontist Ruby API

Fontist can be used as a Ruby library for programmatic font management.

## Overview

The Fontist Ruby API provides interfaces for:
- **Fontist::Font** — Find and install fonts
- **Fontist::Formula** — Access formula information
- **Fontist::Manifest** — Work with font manifests
- **Fontist::Fontconfig** — Integrate with fontconfig

## Installation

Add to your Gemfile:

```ruby
gem 'fontist'
```

Or install directly:

```bash
gem install fontist
```

## Quick Example

```ruby
require 'fontist'

# Find a font
paths = Fontist::Font.find("Open Sans")

# Install a font
paths = Fontist::Font.install("Open Sans", confirmation: "yes")
```

## Next Steps

- [Fontist::Font](/api/font) — Font installation and lookup
- [Fontist::Formula](/api/formula) — Formula information
- [Fontist::Manifest](/api/manifest) — Manifest handling
- [Fontist::Fontconfig](/api/fontconfig) — Fontconfig integration
- [Fontist::Errors](/api/errors) — Error handling
