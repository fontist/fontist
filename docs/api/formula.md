---
title: Fontist::Formula
---

# Fontist::Formula

The `fontist` gem internally uses the `Fontist::Formula` interface to find a registered formula or fonts supported by any formula. Unless you need to do anything with formulas directly, you shouldn't need to work with this interface.

## Overview

Formulas contain the metadata and installation instructions for fonts. Each formula describes:
- Font names and styles available
- Download sources
- License information
- Extraction and installation steps

## Class Methods

### `.find(font_name)`

Find a registered formula by font name. This interface takes a font name as an argument and looks through each of the registered formulas that offer this font installation.

**Parameters:**

| Param | Type | Description |
|-------|------|-------------|
| `font_name` | String | The name of the font to find a formula for |

**Returns:** `Fontist::Formula` — The formula object for the font

**Example:**

```ruby
formula = Fontist::Formula.find("Calibri")
# => #<Fontist::Formula @name="calibri", ...>

# Access formula properties
puts formula.fonts
puts formula.license
```

---

### `.find_fonts(font_name)`

List font styles supported by a formula. Normally, each font name can be associated with multiple styles or collections (e.g., `regular`, `bold`, `italic`).

**Parameters:**

| Param | Type | Description |
|-------|------|-------------|
| `font_name` | String | The name of the font to find styles for |

**Returns:** `Array<Fontist::Font>` — List of font objects with their styles

**Example:**

```ruby
fonts = Fontist::Formula.find_fonts("Calibri")
fonts.each do |font|
  puts "#{font.name} - #{font.style}"
end
# Calibri - Regular
# Calibri - Bold
# Calibri - Italic
```

---

### `.all`

List all registered font formulas. This might be useful if you want to know the name of the formula or what type of fonts can be installed using that formula.

**Parameters:** None

**Returns:** `Array<Fontist::Formula>` — Model objects representing all registered formulas

**Example:**

```ruby
formulas = Fontist::Formula.all
formulas.each do |formula|
  puts formula.name
  puts formula.fonts.map(&:name)
end
```

## Formula Properties

When you retrieve a formula object, you can access various properties:

| Property | Type | Description |
|----------|------|-------------|
| `name` | String | The formula identifier |
| `fonts` | Array | List of fonts provided by this formula |
| `license` | String | License information |
| `homepage` | String | URL to font homepage |
| `description` | String | Description of the font |

## See Also

- [Fontist::Font](/api/font) — Font installation and lookup
- [Fontist::Manifest](/api/manifest) — Work with multiple fonts
