---
title: Font Concepts Overview
---

# Font Concepts

Understanding font terminology is essential for working with Fontist effectively. This section explains the core concepts and how they relate to Fontist, Fontisan, and Formulas.

## Core Hierarchy

```
Font Family (e.g., "Open Sans")
├── Font Style (e.g., "Regular", "Bold", "Italic")
│   ├── Font Weight (e.g., 400, 700)
│   └── Variable Font Axes (e.g., weight, width, slant)
│       └── Font File (physical file on disk)
│           ├── Font Format (OTF, TTF, PS)
│           └── Font Container (TTC, OTC, dfont)
```

## Topics

### [Fonts & Styles](/guide/concepts/fonts)
Font families, styles, and weights—the fundamental building blocks.

### [Variable Fonts](/guide/concepts/variable-fonts)
Modern variable fonts with adjustable axes for weight, width, and more.

### [Formats & Containers](/guide/concepts/formats)
File formats (TTF, OTF, WOFF) and container formats (TTC, dfont).

### [Licenses](/guide/concepts/licenses)
Font licensing and how Fontist handles license requirements.

### [Requirements](/guide/concepts/requirements)
Specifying what fonts your project needs via manifests.

## How Fontist, Fontisan, and Formulas Connect

```
┌─────────────────────────────────────────────────────────┐
│                      FONTIST                            │
├─────────────────────────────────────────────────────────┤
│  Font Requirements (Manifest)                           │
│         │                                               │
│         ▼                                               │
│  ┌──────────────┐     ┌──────────────┐                  │
│  │   Formulas   │────▶│   Downloads  │                  │
│  │ (Recipes)    │     │   & Installs │                  │
│  └──────────────┘     └──────────────┘                  │
│         │                    │                          │
│         ▼                    ▼                          │
│  ┌──────────────┐     ┌──────────────┐                  │
│  │ License      │     │ System Index │                  │
│  │ Management   │     │ (Detection)  │                  │
│  └──────────────┘     └──────────────┘                  │
│                              │                          │
│                              ▼                          │
│                    Returns Font Paths                   │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│                      FONTISAN                           │
├─────────────────────────────────────────────────────────┤
│  Input: Font files (from Fontist or elsewhere)          │
│         │                                               │
│         ▼                                               │
│  ┌──────────────┐     ┌──────────────┐                  │
│  │   Convert    │     │    Subset    │                  │
│  │  TTF↔OTF↔WOFF│     │  Glyphs only │                  │
│  └──────────────┘     └──────────────┘                  │
│         │                    │                          │
│         ▼                    ▼                          │
│  ┌──────────────┐     ┌──────────────┐                  │
│  │   Validate   │     │  Instantiate │                  │
│  │   Check      │     │  Variable→   │                  │
│  │   Issues     │     │  Static      │                  │
│  └──────────────┘     └──────────────┘                  │
│                              │                          │
│                              ▼                          │
│                    Output: Processed Fonts              │
└─────────────────────────────────────────────────────────┘
```

## Quick Reference

### File Extensions

| Extension | Meaning |
|-----------|---------|
| `.ttf` | TrueType Font |
| `.otf` | OpenType Font |
| `.ttc` | TrueType Collection |
| `.otc` | OpenType Collection |
| `.woff` | Web Open Font Format |
| `.woff2` | Web Open Font Format 2 |
| `.dfont` | macOS Data Fork Font |
| `.pfb` | PostScript Font Binary |

### Common Tasks

| Task | Tool | Command |
|------|------|---------|
| Install fonts | Fontist | `fontist install "Font Name"` |
| Check installed | Fontist | `fontist status "Font Name"` |
| Define requirements | Fontist | Create manifest.yml |
| Convert formats | Fontisan | `fontisan convert input.ttf output.woff2` |
| Subset glyphs | Fontisan | `fontisan subset font.ttf --glyphs "ABCabc"` |
| Create formula | Fontist | `fontist create-formula font.ttf` |
