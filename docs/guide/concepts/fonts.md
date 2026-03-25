---
title: Fonts, Styles & Weights
---

# Fonts, Styles & Weights

Understanding the relationship between font families, styles, and weights is fundamental to working with Fontist.

## Font Family

A **Font Family** is a collection of related fonts that share a common design. When you ask Fontist to install "Open Sans", you're requesting a font family.

```
Open Sans (Family)
├── Open Sans Regular
├── Open Sans Bold
├── Open Sans Italic
└── Open Sans Bold Italic
```

### In Fontist

```bash
# Install a font family
fontist install "Open Sans"

# List fonts in a family
fontist list "Open Sans"
```

### In Fontisan

Fontisan processes entire font families, providing:
- Format conversion for all styles
- Subsetting across the family
- Validation of family consistency

---

## Font Style

A **Font Style** is a specific variation within a font family, typically defined by weight and italic/roman distinction.

### Common Styles

| Style | Weight | Italic |
|-------|--------|--------|
| Regular (Roman) | 400 | No |
| Italic | 400 | Yes |
| Bold | 700 | No |
| Bold Italic | 700 | Yes |
| Light | 300 | No |
| Medium | 500 | No |
| Black | 900 | No |

### Style Naming Conventions

Fonts use various naming conventions:

```
Full Name:      "Open Sans Bold Italic"
Family Name:    "Open Sans"
Style:          "Bold Italic"
PostScript Name: "OpenSans-BoldItalic"
```

### In Fontist

```bash
# Install specific styles (via manifest)
fontist manifest-install fonts.yml
```

```yaml
# fonts.yml
Open Sans:
  - Bold
  - Italic
```

---

## Font Weight

**Font Weight** is a numeric value representing the thickness of characters. The CSS/OpenType standard defines 9 weight values:

| Value | Name | Common Use |
|-------|------|------------|
| 100 | Thin | Headlines |
| 200 | Extra Light | Display |
| 300 | Light | Body text (large) |
| 400 | Regular/Normal | Body text |
| 500 | Medium | Emphasis |
| 600 | Semi Bold | Subheadings |
| 700 | Bold | Strong emphasis |
| 800 | Extra Bold | Headlines |
| 900 | Black | Display |

### Weight in Fontist Manifests

```yaml
# Request by style name
Roboto:
  - Bold      # Weight 700
  - Medium    # Weight 500

# Fontist returns paths to these specific weights
```

### Weight vs Variable Fonts

With static fonts, each weight is a separate file:

```
Roboto-Regular.ttf    (weight 400)
Roboto-Medium.ttf     (weight 500)
Roboto-Bold.ttf       (weight 700)
```

With variable fonts, weight becomes a continuous axis:

```
# Variable font with weight axis 100-900
RobotoFlex-VF.ttf
  └── wght axis: 100 → 900 (any value)
```

See [Variable Fonts](/guide/concepts/variable-fonts) for more details.

---

## Finding Font Names

To use a font with Fontist, you need to know its name:

```bash
# Search for a font
fontist list "Segoe"

# Check if a font is installed
fontist status "Open Sans"
```

### Name Matching

Fontist matches names flexibly:
- `"Open Sans"` matches the family
- `"Open Sans Bold"` matches a specific style
- `"OpenSans-Bold"` matches PostScript name

---

## See Also

- [Variable Fonts](/guide/concepts/variable-fonts) - Continuous weight and style axes
- [Formats & Containers](/guide/concepts/formats) - File formats explained
- [Requirements](/guide/concepts/requirements) - Specifying fonts in manifests
- [Manifests Guide](/guide/manifests) - Working with font manifests
