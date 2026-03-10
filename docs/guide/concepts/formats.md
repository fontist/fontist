---
title: Formats & Containers
---

# Formats & Containers

Understanding font file formats and containers helps you work with fonts across different platforms and use cases.

## Font Formats

**Font Format** refers to the internal structure of the font file. Different formats have different capabilities.

### Comparison Table

| Format | Extension | Outlines | Features | Variable | Notes |
|--------|-----------|----------|----------|----------|-------|
| TrueType | `.ttf` | Quadratic Bézier | Full | Yes | Most common |
| OpenType (TT) | `.otf`, `.ttf` | Quadratic | Full | Yes | TrueType outlines |
| OpenType (CFF) | `.otf` | Cubic Bézier | Full | Yes (CFF2) | PostScript outlines |
| PostScript Type 1 | `.pfb`, `.pfa` | Cubic | Limited | No | Legacy, deprecated |
| WOFF | `.woff` | Any | Full | Yes | Compressed web font |
| WOFF2 | `.woff2` | Any | Full | Yes | Better compression |

### Outline Types

#### TrueType (Quadratic Bézier)

```
Points connected by quadratic curves
- Simpler math
- Faster rendering (historically)
- More points needed for complex curves
```

#### CFF/PostScript (Cubic Bézier)

```
Points connected by cubic curves
- More elegant curves
- Fewer points needed
- Professional typography standard
```

### OpenType Features

Modern fonts (TTF and OTF) support OpenType features:

```
OpenType Features:
├── Glyph substitution (GSUB)
│   ├── Ligatures (fi, fl → ﬁ, ﬂ)
│   ├── Small caps
│   ├── Numerals (lining, old-style, tabular)
│   └── Stylistic alternates
├── Glyph positioning (GPOS)
│   ├── Kerning
│   ├── Mark positioning
│   └── Cursor positioning
└── Layout scripts
    ├── Latin
    ├── Arabic
    ├── Devanagari
    └── Many more...
```

---

## Web Font Formats

### WOFF (Web Open Font Format)

- Compressed version of TTF/OTF
- ~40% smaller than original
- Supported in all modern browsers
- Contains same data as source format

### WOFF2

- Next-generation web font format
- ~30% smaller than WOFF
- Brotli compression
- Better for large font families

```bash
# Convert to WOFF2 with Fontisan
fontisan convert font.ttf font.woff2
```

---

## Font Containers

**Font Container** formats can hold multiple fonts in a single file, sharing common data to reduce file size.

### Container Types

| Container | Extension | Contents | Platform |
|-----------|-----------|----------|----------|
| TrueType Collection | `.ttc` | Multiple TTF fonts | Cross-platform |
| OpenType Collection | `.otc` | Multiple OTF fonts | Cross-platform |
| Data Fork Font | `.dfont` | Multiple fonts | macOS legacy |
| Font Suitcase | (no extension) | Multiple fonts | Classic Mac OS |

### When Containers Are Used

Containers reduce file size by sharing common tables:

```
# Separate files (duplicated tables)
font1.ttf (glyf, head, hmtx, loca...) = 200KB
font2.ttf (glyf, head, hmtx, loca...) = 200KB
Total: 400KB

# TTC container (shared tables)
fonts.ttc (shared: glyf, head...) = 300KB
Savings: 25%
```

### Common Container Files

| Font Family | Container | Fonts Included |
|-------------|-----------|----------------|
| Segoe UI | segoeui.ttc | Regular, Bold, Italic, Bold Italic |
| Arial | arial.ttf | Multiple weights |
| MS Gothic | msgothic.ttc | Regular, Bold |

---

## Working with Containers in Fontist

### Installation

```bash
# Fontist handles containers automatically
fontist install "Segoe UI"
```

### Status Check

```bash
fontist status "Segoe UI"
# Returns path to TTC and internal font name
```

### Ruby API

```ruby
# Returns container info
result = Fontist::Font.find("Segoe UI")
# => { paths: ["/path/to/segoeui.ttc"], full_name: "Segoe UI" }

# The full_name identifies the font within a TTC
```

---

## Working with Containers in Fontisan

### Extract from Container

```bash
# Extract individual font from TTC
fontisan extract segoeui.ttc --font "Segoe UI Bold" --output bold.ttf
```

### Create Container

```bash
# Create TTC from multiple TTFs
fontisan create-ttf regular.ttf bold.ttf italic.ttf --output family.ttc
```

---

## Format Conversion

### TTF ↔ OTF

```bash
# Convert TTF to OTF (changes outline type)
fontisan convert input.ttf output.otf

# Note: Outline conversion may affect rendering
```

### Desktop ↔ Web

```bash
# Create web fonts from desktop fonts
fontisan convert font.ttf font.woff
fontisan convert font.ttf font.woff2
```

### Lossless Operations

These operations preserve font data:
- TTF → WOFF → TTF (round-trip)
- OTF → WOFF2 → OTF (round-trip)
- Extract from TTC

Lossy operations:
- TTF → OTF (outline conversion)
- Subsetting (removes glyphs)
- Axis reduction (removes variable data)

---

## Platform Considerations

### macOS

- Supports TTF, OTF, TTC, OTC
- Legacy support for dfont
- Font Book handles all formats

### Windows

- Supports TTF, OTF, TTC
- Fonts in `C:\Windows\Fonts`
- Per-user fonts in AppData

### Linux

- Supports TTF, OTF, TTC
- Uses fontconfig for discovery
- Multiple font directories

---

## See Also

- [Fonts & Styles](/guide/concepts/fonts) - Basic font concepts
- [Variable Fonts](/guide/concepts/variable-fonts) - Modern variable fonts
- [Fontisan Documentation](https://www.fontist.org/fontisan/) - Format conversion tools
