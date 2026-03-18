---
title: Fontist::Font
---

# Fontist::Font

The `Fontist::Font` is your go-to place to deal with any font using Fontist. This interface allows you to find a font or install a font.

## Overview

The Font class provides methods to:
- Find fonts installed on your system
- Install new fonts from supported sources
- List all supported fonts

It searches in operating system specific font directories and the fontist specific `~/.fontist` directory.

## Class Methods

### `.find(name)`

Find a font in your system.

**Parameters:**

| Param | Type | Description |
|-------|------|-------------|
| `name` | String | The name of the font to find |

**Returns:** `Array<String>` — Paths to the font files

**Raises:**
- `Fontist::Errors::UnsupportedFontError` — If the font is not supported
- May trigger display of installation instructions for the specific font

**Example:**

```ruby
paths = Fontist::Font.find("Calibri")
# => ["/Users/user/.fontist/fonts/calibri.ttf"]
```

---

### `.install(name, confirmation: "no")`

Install any supported font.

This interface first checks if you already have that font installed. If you do, it returns the paths. If you don't have the font but it is supported by Fontist, it will download the font, copy it to `~/.fontist` directory, and return the paths.

**Parameters:**

| Param | Type | Description |
|-------|------|-------------|
| `name` | String | The name of the font to install |
| `confirmation` | String | License confirmation, use `"yes"` to accept license |

**Returns:** `Array<String>` — Paths to the installed font files

**Raises:**
- `Fontist::Errors::UnsupportedFontError` — If the font is not supported
- `Fontist::Errors::LicensingError` — If license requires confirmation

**Example:**

```ruby
# Install with license acceptance
paths = Fontist::Font.install("Open Sans", confirmation: "yes")
# => ["/Users/user/.fontist/fonts/OpenSans-Regular.ttf"]

# Install without license acceptance (may fail for licensed fonts)
paths = Fontist::Font.install("Open Sans", confirmation: "no")
```

---

### `.all`

List all supported fonts.

This might be useful if you want to know the name of the font or the available styles.

**Parameters:** None

**Returns:** `Array<Fontist::FontModel>` — Model objects representing supported fonts

**Example:**

```ruby
fonts = Fontist::Font.all
fonts.each do |font|
  puts font.name
  puts font.styles
end
```

## See Also

- [Fontist::Formula](/api/formula) — Access formula information for fonts
- [Fontist::Manifest](/api/manifest) — Work with multiple fonts via manifest
- [Fontist::Errors](/api/errors) — Error handling
