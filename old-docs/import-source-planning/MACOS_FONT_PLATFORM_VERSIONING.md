# macOS Font Platform Versioning Implementation

## Problem Statement

Currently, macOS supplementary font formulas use a generic `platforms: ["macos"]` designation. However, Apple distributes fonts through version-specific catalogs:

- **Font7 catalog**: Compatible with macOS 10.11 (El Capitan) through macOS 15 (Sequoia 15.7)
- **Font8 catalog**: Compatible with macOS 26+ (Sequoia 15.8+)

The same font may exist in both catalogs with different download URLs and versions. We need to:

1. Properly bind formulas to their compatible macOS versions
2. Ensure only the latest version per catalog is imported
3. Prevent version conflicts when the same font exists in multiple catalogs
4. Allow fontist to select the correct formula based on user's macOS version

## Current State

### What Works
✅ Font import from both Font7 and Font8 catalogs
✅ Formula generation with complete metadata
✅ Beautiful CLI output with progress tracking
✅ Force/skip existing formula logic
✅ Font/style display with PostScript names

### What Needs Fixing
❌ All formulas have `platforms: ["macos"]` regardless of catalog version
❌ No way to distinguish Font7-compatible from Font8-compatible formulas
❌ Same font from different catalogs will overwrite each other
❌ No mechanism to select correct formula based on user's macOS version
❌ No way to indicate minimum macOS version requirement

## Architecture Proposal

### Option 1: Catalog-Based Platform Tags (RECOMMENDED)

Use catalog version as platform discriminator:

```yaml
# Font7 formulas (macOS 10.11-15)
platforms:
  - macos-font7

# Font8 formulas (macOS 26+)
platforms:
  - macos-font8
```

**Pros:**
- Direct mapping to Apple's catalog system
- Simple to implement and understand
- Clear separation of catalog-specific fonts
- Easy to extend for Font9, Font10, etc.

**Cons:**
- Less intuitive than OS version numbers
- Requires documentation of which catalog maps to which OS versions

### Option 2: Minimum macOS Version Attribute

Add a new formula attribute for minimum version:

```yaml
platforms:
  - macos
min_macos_version: "10.11"  # For Font7
min_macos_version: "26.0"   # For Font8
```

**Pros:**
- Intuitive and explicit
- Allows granular version requirements
- Backward compatible (old formulas without min_version work on all)

**Cons:**
- Requires changes to Formula model (add new attribute)
- Needs OS version detection logic
- More complex to implement

### Option 3: Version Range Platform Tags

Use explicit OS version ranges:

```yaml
# Font7
platforms:
  - macos-10.11
  - macos-12
  - macos-13
  - macos-14
  - macos-15

# Font8
platforms:
  - macos-26
```

**Pros:**
- Most explicit
- Self-documenting

**Cons:**
- Verbose and hard to maintain
- Apple's versioning is unpredictable (15.7 → 26)
- Requires updates when new OS versions are released

## Recommended Approach: Hybrid Solution

**Use catalog-based tags with metadata:**

```yaml
name: Al Bayan
description: Arabic font from macOS
homepage: https://support.apple.com/HT211240
platforms:
  - macos-font7
catalog_version: 7
min_macos_version: "10.11"
max_macos_version: "15.7"
resources:
  al_bayan_font7:
    source: apple_cdn
    urls:
      - https://updates.cdn-apple.com/.../Font7/...
```

**Benefits:**
- Clear platform tag indicates compatibility
- Catalog version documents source
- Min/max versions provide explicit ranges
- Can have separate formulas for Font7 and Font8 versions of same font

## Implementation Plan

### Phase 1: Formula Model Updates

1. **Update Formula class** ([`lib/fontist/formula.rb`](lib/fontist/formula.rb)):
   - Add `catalog_version` attribute
   - Add `min_macos_version` attribute
   - Add `max_macos_version` attribute
   - Update `compatible_with_platform?` to check macOS version

2. **Update platform detection** ([`lib/fontist/utils/system.rb`](lib/fontist/utils/system.rb)):
   - Add `macos_version` method to detect OS version
   - Parse version string (handle "10.15", "11.0", "26.0" formats)
   - Add `macos_catalog_version` to determine which catalog the OS uses

3. **Update platform tags**:
   - Support both `macos` (generic) and `macos-font7`/`macos-font8` (specific)
   - Make `compatible_with_platform?` smart about version matching

### Phase 2: Import Updates

1. **Update Macos importer** ([`lib/fontist/import/macos.rb`](lib/fontist/import/macos.rb)):
   - Detect catalog version from XML path
   - Set appropriate platform tags (`macos-font7` vs `macos-font8`)
   - Add catalog_version, min/max_macos_version to formulas
   - Handle version conflicts (latest within catalog wins)

2. **Update FormulaBuilder** ([`lib/fontist/import/formula_builder.rb`](lib/fontist/import/formula_builder.rb)):
   - Accept catalog metadata parameters
   - Include version information in generated formulas

### Phase 3: Formula Directory Structure

Organize formulas by catalog version to avoid conflicts:

```
formulas/
└── macos/
    ├── font7/           # macOS 10.11-15
    │   ├── al_bayan.yml
    │   └── apple_chancery.yml
    └── font8/           # macOS 26+
        ├── al_bayan.yml
        └── apple_chancery.yml
```

**OR** use suffixes:

```
formulas/
└── macos/
    ├── al_bayan_font7.yml
    ├── al_bayan_font8.yml
    ├── apple_chancery_font7.yml
    └── apple_chancery_font8.yml
```

### Phase 4: Selection Logic

1. **Update Formula.find** to prefer version-appropriate formulas:
   - On macOS 14: prefer `macos-font7` formulas
   - On macOS 26: prefer `macos-font8` formulas
   - Fall back to generic `macos` formulas

2. **Update FormulaPicker** to consider OS version compatibility

## Testing Strategy

1. Test on multiple macOS versions:
   - macOS 12 (Font7)
   - macOS 13 (Font7)
   - macOS 14 (Font7)
   - macOS 15.7 (Font7)
   - macOS 26 (Font8)

2. Test font installation:
   - Correct catalog used based on OS version
   - Fonts install successfully
   - No version conflicts

3. Test import process:
   - Both catalogs can be imported
   - Formulas don't overwrite each other
   - Correct platform tags assigned

## Migration Path

1. Import Font7 to `formulas/macos/font7/`
2. Import Font8 to `formulas/macos/font8/`
3. Update existing generic `macos` formulas gradually
4. Maintain backward compatibility with old formula structure

## Questions to Answer

1. Should we use directory structure or filename suffixes for organization?
2. How do we handle users on macOS versions we don't have catalogs for?
3. Should Font8 formulas fall back to Font7 if font not available?
4. Do we version formulas at import time or only store latest per catalog?

## Success Criteria

- [ ] Font7 and Font8 formulas coexist without conflicts
- [ ] Formulas have correct platform version tags
- [ ] Font installation selects appropriate catalog based on OS version
- [ ] Import process respects catalog versioning
- [ ] Documentation explains version compatibility
- [ ] Tests cover multi-version scenarios
- [ ] Backward compatibility maintained

## Priority

**HIGH** - This blocks proper Font8 adoption and causes formula conflicts

## Estimated Effort

- Formula model updates: 2-3 hours
- Import logic updates: 3-4 hours
- Selection logic: 2-3 hours
- Testing: 2-3 hours
- Documentation: 1-2 hours

**Total: 10-15 hours**

## Next Steps

1. Decide on platform tag format (`macos-font7` vs `macos-10.11+`)
2. Choose directory structure (subdirs vs suffixes)
3. Implement Formula model changes
4. Update import process
5. Test on multiple macOS versions
6. Update documentation