---
title: Font Licenses
---

# Font Licenses

**Font Licenses** define how fonts can be used, modified, and distributed. Fontist tracks license requirements and prompts for acceptance when needed.

## License Types

### Open Source Licenses

| License | Install | Embed | Modify | Commercial | Notes |
|---------|---------|-------|--------|------------|-------|
| SIL OFL 1.1 | ✅ | ✅ | ✅ | ✅ | Most common for fonts |
| Apache 2.0 | ✅ | ✅ | ✅ | ✅ | Google Fonts default |
| MIT | ✅ | ✅ | ✅ | ✅ | Permissive |
| GPLv2 | ✅ | ⚠️ | ✅ | ❌ | Copyleft |
| LGPL | ✅ | ✅ | ⚠️ | ✅ | Linking exception |

### Proprietary Licenses

| License Type | Install | Embed | Modify | Commercial |
|--------------|---------|-------|--------|------------|
| Freeware | ✅ | Varies | ❌ | Varies |
| Shareware | ⚠️ | ❌ | ❌ | ❌ |
| Commercial | ⚠️ | ⚠️ | ❌ | ⚠️ |
| Bundle-only | ✅ | ✅ | ❌ | ✅ |

---

## SIL Open Font License (OFL)

The most common open-source font license, created specifically for fonts.

### Key Points

- **Free to use** - No cost for any use
- **Free to share** - Redistribute freely
- **Free to modify** - Create derivative works
- **Reserved Font Name** - Some fonts restrict use of original name
- **Bundle allowed** - Include in software packages

### OFL in Practice

```yaml
# Example OFL font in formula
name: open-sans
license:
  type: OFL-1.1
  url: https://scripts.sil.org/OFL
  requires_confirmation: false
```

---

## Proprietary Fonts

Some fonts require license acceptance before installation.

### Fontist License Handling

```bash
# Fontist shows license requirements
fontist install "Calibri"

# Output:
# This font requires license acceptance.
# License: Microsoft Software License
# View license? [y/N]
```

### Accepting Licenses

```bash
# For CI/CD, accept all licenses
fontist install --accept-all-licenses "Calibri"
```

### In Manifests

```yaml
# Manifest with license handling
Calibri:
  - Regular
  - Bold

# Install with license acceptance
# fontist manifest-install --accept-all-licenses manifest.yml
```

---

## License Metadata in Formulas

Formulas include license information:

```yaml
name: example-font
description: Example font with license info
homepage: https://example.com/font

copyright:
  - Copyright (c) 2026 Example Foundry

license:
  type: OFL-1.1
  url: https://scripts.sil.org/OFL
  requires_confirmation: false

# OR for proprietary:
license:
  type: Proprietary
  url: https://example.com/license
  requires_confirmation: true
  text: |
    END USER LICENSE AGREEMENT
    ...
```

---

## Fontist License Error Handling

### Exit Code 4: Licensing Error

When a font requires license acceptance but it wasn't provided:

```bash
fontist install "Some Commercial Font"
# Exit code: 4
# Error: License confirmation required
```

### Handling in Scripts

```bash
#!/bin/bash
fontist install "Font Name"
case $? in
  0) echo "Success" ;;
  4) echo "License required, accepting..."
      fontist install --accept-all-licenses "Font Name"
      ;;
  *) echo "Error: $?" ;;
esac
```

### In Ruby

```ruby
begin
  Fontist::Font.install("Font Name")
rescue Fontist::Errors::LicensingError
  # Handle license requirement
  Fontist::Font.install("Font Name", confirmation: "yes")
end
```

---

## Embedding Rights

### What is Font Embedding?

Embedding includes the font inside a document (PDF, EPUB, etc.) rather than requiring the recipient to have it installed.

### Embedding Types

| Type | Description |
|------|-------------|
| Installable | Font can be installed and used |
| Editable | Font can be embedded for editing |
| Preview & Print | Font can be embedded for viewing only |
| Restricted | No embedding allowed |

### Checking Embedding Rights

```bash
# Fontisan can report embedding rights
fontisan analyze font.ttf --embedding
```

---

## Common Font Sources & Licenses

| Source | License | Notes |
|--------|---------|-------|
| Google Fonts | OFL-1.1, Apache-2.0 | Free, open source |
| Adobe Fonts | Proprietary | Subscription required |
| Monotype | Proprietary | Commercial licenses |
| System fonts | Varies | OS license applies |
| Microsoft ClearType | Proprietary | Windows bundle |

---

## Best Practices

### For Projects

1. **Document font licenses** in your project
2. **Use OFL fonts** when possible
3. **Verify embedding rights** before PDF generation
4. **Keep license files** alongside fonts

### For CI/CD

1. **Use `--accept-all-licenses`** carefully
2. **Document which fonts** you use
3. **Audit license compliance** periodically
4. **Consider commercial alternatives** for proprietary fonts

### Example: Documenting Font Usage

```yaml
# fonts.yml with license documentation
# Project: My Documentation
# Generated: 2026-03-10

Roboto:  # OFL-1.1 - https://fonts.google.com/specimen/Roboto
  - Regular
  - Bold

Source Code Pro:  # OFL-1.1 - https://fonts.google.com/specimen/Source+Code+Pro
  - Regular
```

---

## See Also

- [Requirements](/guide/concepts/requirements) - Specifying font needs
- [Formulas Guide](/guide/formulas) - How formulas work
- [Exit Codes](/cli/exit-codes) - License error (code 4)
- [SIL OFL](https://scripts.sil.org/OFL) - Open Font License
