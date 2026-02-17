# Fontist v5 Schema Implementation Plan

## Overview

This document outlines the implementation plan for Formula Schema v5 with
multi-format font support. The architecture uses **v5-only classes** -
migration from v4 to v5 is handled by a separate migration script.

## Architecture

### Core Principle: v5 Only

All formula classes now use v5 schema with:
- `schema_version: 5` (default)
- Format metadata on resources (`format`, `variable_axes`)
- Format metadata on styles (`formats`, `variable_font`, `variable_axes`)

### Class Hierarchy

```
Formula (v5 only)
├── schema_version: 5
├── resources: ResourceCollection
│   └── Resource
│       ├── format: string
│       └── variable_axes: array
├── fonts: FontModel[]
│   └── styles: FontStyle[]
│       ├── formats: array
│       ├── variable_font: boolean
│       └── variable_axes: array
└── font_collections: FontCollection[]
```

## Files Modified/Created

### Core Classes (v5 only)

| File | Description |
|------|-------------|
| `lib/fontist/formula.rb` | v5 formula with schema_version, format support |
| `lib/fontist/resource.rb` | Resource with format/variable_axes |
| `lib/fontist/resource_collection.rb` | Resource collection |
| `lib/fontist/font_style.rb` | FontStyle with formats/variable_font/variable_axes |
| `lib/fontist/font_model.rb` | FontModel using FontStyle |
| `lib/fontist/font_collection.rb` | FontCollection using FontModel |

### Services

| File | Description |
|------|-------------|
| `lib/fontist/format_spec.rb` | FormatSpec model |
| `lib/fontist/format_matcher.rb` | Format matching service |
| `lib/fontist/font_finder.rb` | Font discovery by capabilities |

### Removed Files

All v4-specific files removed - migration handled by script:
- `lib/fontist/formula_v4.rb` (deleted)
- `lib/fontist/formula_v5.rb` (deleted)
- `lib/fontist/resource_v4.rb` (deleted)
- `lib/fontist/resource_v5.rb` (deleted)
- `lib/fontist/font_style_v4.rb` (deleted)
- `lib/fontist/font_style_v5.rb` (deleted)
- `lib/fontist/font_style_base.rb` (deleted)
- etc.

## Current Status

- [x] FormatSpec model
- [x] FormatMatcher service
- [x] FontFinder service
- [x] CLI options for format selection
- [x] Import CLI --schema-version option
- [x] Simplified to v5-only classes (no v4 classes)
- [x] All 77 core tests passing
- [ ] Run imports for formulas repository
- [ ] Create v4→v5 migration script

## Migration Strategy

v4 formulas will be converted to v5 using a migration script that:
1. Reads v4 formula YAML
2. Adds `schema_version: 5`
3. Detects format from file extensions
4. Detects variable fonts from filename patterns
5. Outputs v5 formula YAML

## Next Steps

1. Run formula imports with v5 schema:
   ```bash
   fontist import google --schema-version=5 --output-path=./Formulas/google --force
   fontist import macos --schema-version=5 --output-path=./Formulas/macos --force
   fontist import sil --schema-version=5 --output-path=./Formulas/sil --force
   ```

2. Create v4→v5 migration script for existing formulas

3. Run full test suite to verify all functionality works with v5

## Breaking Changes

- v4 formulas are no longer supported directly
- Migration script required to convert v4 formulas to v5
- All formulas must have `schema_version: 5`
