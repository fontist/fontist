---
title: Variable Fonts
---

# Variable Fonts

**Variable Fonts** (OpenType 1.8+) contain multiple styles in a single file through named **axes**. Instead of separate files for each weight, one file can contain all variations.

## Why Variable Fonts?

### Before: Static Fonts

```
fonts/
├── Roboto-Thin.ttf        (100)
├── Roboto-Light.ttf       (300)
├── Roboto-Regular.ttf     (400)
├── Roboto-Medium.ttf      (500)
├── Roboto-Bold.ttf        (700)
└── Roboto-Black.ttf       (900)

Total: 6 files, ~1.2MB
```

### After: Variable Font

```
fonts/
└── RobotoFlex-VF.ttf

Total: 1 file, ~800KB
```

---

## Standard Axes

Variable fonts use **axes** to define adjustable properties:

| Axis Tag | Name | Description | Range |
|----------|------|-------------|-------|
| `wght` | Weight | Stroke thickness | 100-900 |
| `wdth` | Width | Horizontal compression | 25%-200% |
| `slnt` | Slant | Oblique angle | -15° to 0° |
| `ital` | Italic | Italic variation | 0 or 1 |
| `opsz` | Optical Size | Size optimization | 8pt-144pt |

### Weight Axis (`wght`)

The most common axis, replacing multiple static weights:

```css
/* CSS usage */
font-weight: 400;  /* Regular */
font-weight: 700;  /* Bold */
font-weight: 543;  /* Any value in range */
```

### Width Axis (`wdth`)

Controls horizontal compression/extension:

```css
font-stretch: 100%;  /* Normal */
font-stretch: 75%;   /* Condensed */
font-stretch: 125%;  /* Extended */
```

### Optical Size Axis (`opsz`)

Optimizes glyphs for different sizes:

```css
font-optical-sizing: auto;
/* or manually: */
font-variation-settings: 'opsz' 12;
```

---

## Custom Axes

Fonts can define custom axes beyond the standard five:

| Axis Tag | Name | Description |
|----------|------|-------------|
| `GRAD` | Grade | Weight change without width adjustment |
| `XTRA` | X-height | Adjust x-height |
| `XOPQ` | X Optical | Horizontal stroke adjustment |
| `YOPQ` | Y Optical | Vertical stroke adjustment |
| `ROTL` | Rotation | Glyph rotation |
| `CASL` | Casual | Formal to casual variation |

### Example: Roboto Flex

Roboto Flex is a highly customizable variable font:

```
RobotoFlex-VF.ttf
├── wght axis: 100 → 900    (weight)
├── wdth axis: 25% → 151%   (width)
├── GRAD axis: -200 → 150   (grade)
├── XTRA axis: 323 → 608    (x-height)
├── XOPQ axis: 27 → 175     (x optical)
├── YOPQ axis: 25 → 135     (y optical)
├── YTFI axis: 560 → 788    (y-fit)
├── YTLC axis: 416 → 570    (lowercase)
├── YTUC axis: 528 → 760    (uppercase)
└── YTAS axis: 649 → 854    (ascender)
```

---

## Using Variable Fonts

### In Fontist

```bash
# Variable fonts install like any other font
fontist install "Roboto Flex"

# The single VF file replaces multiple static files
fontist status "Roboto Flex"
```

### In CSS

```css
/* Basic usage */
.element {
  font-family: "Roboto Flex";
  font-weight: 450;
}

/* Advanced control */
.element {
  font-variation-settings:
    'wght' 450,
    'GRAD' 50,
    'XTRA' 500;
}
```

### In Fontisan

Fontisan provides variable font operations:

- **Instantiate** - Create static instances from variable fonts
- **Subset axes** - Reduce axis ranges to needed values
- **Axis analysis** - Report available axes and ranges

```bash
# Create a static instance at weight 450
fontisan instantiate RobotoFlex-VF.ttf --wght 450

# Subset to only weight range 400-700
fontisan subset-axes RobotoFlex-VF.ttf --wght 400-700
```

---

## Named Instances

Variable fonts can define **named instances** - preset combinations of axis values:

| Instance Name | wght | wdth |
|--------------|------|------|
| Light | 300 | 100 |
| Regular | 400 | 100 |
| Bold | 700 | 100 |
| Condensed Bold | 700 | 75 |

These appear as separate fonts in some applications.

---

## Variable Fonts vs Static Fonts

| Aspect | Static | Variable |
|--------|--------|----------|
| Files | Multiple | Single |
| File size | Larger total | Smaller total |
| Weight options | Fixed set | Continuous |
| CSS control | Limited | Fine-grained |
| Browser support | Universal | Modern browsers |
| PDF embedding | Simple | Requires care |

---

## Detecting Variable Fonts

### Using Fontist

```bash
fontist status --verbose
# Shows if installed fonts are variable
```

### Using Fontisan

```bash
fontisan analyze font.ttf
# Reports axes, ranges, and named instances
```

---

## See Also

- [Fonts & Styles](/guide/concepts/fonts) - Basic font concepts
- [Formats & Containers](/guide/concepts/formats) - File formats explained
- [Fontisan Documentation](https://www.fontist.org/fontisan/) - Variable font operations
