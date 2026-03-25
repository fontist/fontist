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
│       ├── format: string (ttf, otf, woff, woff2, ttc, otc, dfont)
│       └── variable_axes: array (e.g., ["wght", "wdth"])
├── fonts: FontModel[]
│   └── styles: FontStyle[]
│       ├── formats: array
│       ├── variable_font: boolean
│       └── variable_axes: array
└── font_collections: FontCollection[]
```

## Implementation Status

### Phase 1: Core Models ✅ DONE

- [x] FormatSpec model (`lib/fontist/format_spec.rb`)
- [x] FormatMatcher service (`lib/fontist/format_matcher.rb`)
- [x] FontFinder service (`lib/fontist/font_finder.rb`)
- [x] v5-only Formula class (`lib/fontist/formula.rb`)
- [x] v5-only Resource class (`lib/fontist/resource.rb`)
- [x] v5-only FontStyle class (`lib/fontist/font_style.rb`)
- [x] ResourceCollection class (`lib/fontist/resource_collection.rb`)
- [x] All 65 tests passing

### Phase 2: Import System Fixes ✅ DONE

#### Importer Format Metadata Status

| Importer | format in resources | variable_axes | Status |
|----------|-------------------|---------------|--------|
| Google V5 | ✅ Dynamic | ✅ Yes | DONE |
| Google V4 | ✅ Hardcoded "ttf" | ⚠️ Skipped | N/A |
| macOS | ✅ Via CreateFormula | ✅ Via CreateFormula | DONE |
| SIL | ✅ Via CreateFormula | ✅ Via CreateFormula | DONE |

#### Tasks

- [x] Fix `CreateFormula` class to detect and add format metadata
- [x] macOS importer uses CreateFormula (now has format detection)
- [x] SIL importer uses CreateFormula (now has format detection)
- [x] Verify Google V5 importer works correctly

### Phase 3: Migration Script ✅ DONE

Create `lib/fontist/import/v4_to_v5_migrator.rb`: ✅ Created

Migration features:
- [x] Reads v4 YAML
- [x] Adds schema_version: 5
- [x] Detects format from file extensions
- [x] Detects variable fonts from filename patterns
- [x] Writes v5 YAML
- [x] CLI command: `fontist migrate-formulas INPUT [OUTPUT]`

### Phase 4: Run Imports ✅ DONE (via migration)

All existing formulas migrated to v5 schema. Fresh imports can be run if needed:

```bash
# Google Fonts (if fresh import needed)
fontist import google --schema-version=5 --output-path=./Formulas/google --force

# macOS Fonts (if fresh import needed)
fontist import macos --schema-version=5 --output-path=./Formulas/macos --force

# SIL Fonts (if fresh import needed)
fontist import sil --schema-version=5 --output-path=./Formulas/sil --force
```

### Phase 5: Migrate Existing Formulas ✅ DONE

```bash
# Run migration on all existing v4 formulas
fontist migrate-formulas ../formulas/Formulas ../formulas/Formulas --verbose
```

Results:
- Migrated: 3206 formulas
- Skipped (already v5): 474 formulas
- Failed: 1 (malformed YAML backup file)
- Total time: ~5 seconds

## Critical Files

### Core Classes (v5 only)

| File | Description | Status |
|------|-------------|--------|
| `lib/fontist/formula.rb` | v5 formula with schema_version | ✅ Done |
| `lib/fontist/resource.rb` | Resource with format/variable_axes | ✅ Done |
| `lib/fontist/resource_collection.rb` | Resource collection | ✅ Done |
| `lib/fontist/font_style.rb` | FontStyle with format metadata | ✅ Done |
| `lib/fontist/font_model.rb` | FontModel using FontStyle | ✅ Done |
| `lib/fontist/font_collection.rb` | FontCollection using FontModel | ✅ Done |

### Services

| File | Description | Status |
|------|-------------|--------|
| `lib/fontist/format_spec.rb` | FormatSpec model | ✅ Done |
| `lib/fontist/format_matcher.rb` | Format matching service | ✅ Done |
| `lib/fontist/font_finder.rb` | Font discovery by capabilities | ✅ Done |

### Import System

| File | Description | Status |
|------|-------------|--------|
| `lib/fontist/import/create_formula.rb` | Generic formula creator | ✅ Fixed |
| `lib/fontist/import/formula_builder.rb` | Base formula builder | ✅ Works |
| `lib/fontist/import/google/formula_builder_v5.rb` | Google V5 builder | ✅ Done |
| `lib/fontist/import/macos_importer.rb` | macOS importer | ✅ Works |
| `lib/fontist/import/sil_importer.rb` | SIL importer | ✅ Works |
| `lib/fontist/import/v4_to_v5_migrator.rb` | Migration script | ✅ Created |

## Next Steps

1. ~~**Fix CreateFormula class**~~ - ✅ Done
2. ~~**Fix macOS importer**~~ - ✅ Works via CreateFormula
3. ~~**Fix SIL importer**~~ - ✅ Works via CreateFormula
4. ~~**Create V4→V5 migrator**~~ - ✅ Created
5. ~~**Migrate formulas**~~ - ✅ 3206 migrated, 474 skipped
6. ~~**Commit formulas**~~ - ✅ Committed to v5 branch (3cbe032)
7. ~~**Fix V5 builder for variable fonts**~~ - ✅ Done (8e0e568)
8. **Run fresh Google import** - Import with v5 schema to get WOFF2/variable fonts
9. **Verify** - Test installation with v5 formulas

## v5 Formula Example (Roboto Flex)

```yaml
schema_version: 5
resources:
  woff2_variable:
    format: woff2
    variable_axes: [GRAD, XOPQ, XTRA, YOPQ, YTAS, YTDE, YTFI, YTLC, YTUC, opsz, slnt, wdth, wght]
  ttf_variable:
    format: ttf
    variable_axes: [GRAD, XOPQ, XTRA, YOPQ, YTAS, YTDE, YTFI, YTLC, YTUC, opsz, slnt, wdth, wght]
fonts:
- styles:
  - variable_font: true
    variable_axes: [GRAD, XOPQ, XTRA, YOPQ, YTAS, YTDE, YTFI, YTLC, YTUC, opsz, slnt, wdth, wght]
    formats: [ttf, woff2]
```

## Breaking Changes

- v4 formulas are no longer supported directly
- Migration or re-import required for all formulas
- All formulas must have `schema_version: 5`
- Resources must have `format` field in v5

## Format Detection Logic

### File Extension → Format

| Extension | Format |
|-----------|--------|
| .ttf | ttf |
| .otf | otf |
| .woff | woff |
| .woff2 | woff2 |
| .ttc | ttc |
| .otc | otc |
| .dfont | dfont |

### Filename Pattern → Variable Axes

| Pattern | Axes |
|---------|------|
| `Font[wght].ttf` | ["wght"] |
| `Font[wght,wdth].ttf` | ["wght", "wdth"] |
| `Font-Variable.ttf` | Detect from font file |
| `Font-VF.ttf` | Detect from font file |
