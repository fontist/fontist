// ... existing code ...
# Continue: macOS Platform Fix and Install Location Implementation

## Context

You are continuing implementation of critical macOS font framework platform versioning fixes and install location flexibility. All architecture and planning is complete - now execute the implementation.

## What Was Done

✅ **Planning Phase Complete:**
- Architecture designed (object-oriented, MECE, separation of concerns)
- Continuation plan created: `MACOS_PLATFORM_FIX_CONTINUATION_PLAN.md`
- Status tracker created: `MACOS_PLATFORM_FIX_STATUS.md`
- All design decisions documented

## What Needs to Be Done

Implement all phases from the continuation plan in order:

### Phase 1: Core Fixes (CRITICAL - Start Here)

**File:** `lib/fontist/macos_framework_metadata.rb`

Fix version mappings according to Apple's actual framework deployment:
- Font3: min_macos_version "10.12" (was "10.10")
- Font4: min_macos_version "10.13" (was "10.12")
- Font5: min_macos_version "10.14" (was "10.13")
- Font6: min "10.15", max "11.99" (was min "11.0", max "11.7")
- Font7: min "12.0", max "15.99" (was min "10.11", max "15.7")
- Add asset_path to each framework's metadata
- Add methods: asset_path(), system_install_path(), framework_for_macos()

**File:** `lib/fontist/utils/system.rb`

Replace `catalog_version_for_macos` (lines 88-103) to delegate to MacosFrameworkMetadata.

### Phase 2: Error Handling

**File:** `lib/fontist/errors.rb`

Add `UnsupportedMacOSVersionError` class with helpful message including:
- Detected version
- Supported frameworks table
- Override example
- Fontist-library option
- GitHub issues link

**File:** `lib/fontist/formula.rb`

Update `compatible_with_platform?` to raise error when version unsupported.

### Phase 3: Platform Override

**File:** `lib/fontist/utils/system.rb`

Add methods:
- `platform_override()` - read ENV
- `platform_override?()` - check if set
- `parse_platform_override()` - parse platform tag ONLY format
- Update `user_os()`, `macos_version()`, `catalog_version_for_macos()` to use override

### Phase 4: Install Location

**New File:** `lib/fontist/install_location.rb`

Create InstallLocation class with:
- `initialize(formula, location_type: nil)`
- `base_path()` - returns Pathname
- `font_path(filename)` - returns Pathname
- `system_install?()`, `fontist_library_install?()` - predicates
- Private: `system_path()`, `fontist_library_path()`

**File:** `lib/fontist/config.rb`

Add:
- `macos_fonts_location()` - read ENV/config/default
- `set_macos_fonts_location(location)` - save to config

**File:** `lib/fontist/font_installer.rb`

- Accept `location:` parameter
- Create InstallLocation instance
- Use `@location.font_path()` for install targets

**File:** `lib/fontist/font.rb`

- Accept `macos_fonts_location:` option
- Parse to symbol (:system or :fontist_library)
- Pass to FontInstaller

**File:** `lib/fontist/cli.rb`

- Add `--macos-fonts-location` option to install command
- Enum: ["system", "fontist-library"]

### Phase 5: Testing

Write comprehensive tests for all new functionality:
- Version mapping tests (all frameworks, including nil for 16-25)
- Platform override tests
- Install location tests
- Error message tests
- Integration tests

### Phase 6: Documentation

Update docs:
- README.adoc: Add macOS sections
- Create docs/macos-fonts-guide.md
- Move old docs to old-docs/

## Implementation Guidelines

### CRITICAL Rules

1. **Object-Oriented**: Use classes, not procedural helpers
2. **MECE**: Clear separation of concerns, no overlaps
3. **Single Responsibility**: Each class has one job
4. **API First**: All CLI options also available as API parameters and ENV vars
5. **Correctness Over Tests**: If tests fail, update test expectations (don't lower standards)

### ENV/CLI/API Parameter Structure (MECE)

For install location:
- ENV: `FONTIST_MACOS_FONTS_LOCATION="fontist-library"`
- CLI: `fontist install "Font" --macos-fonts-location=fontist-library`
- API: `Font.install("Font", macos_fonts_location: "fontist-library")`

For platform override:
- ENV: `FONTIST_PLATFORM_OVERRIDE="macos-font7"`
- (No CLI option - ENV only for override)

### Code Style

- Use 2 spaces for indentation
- Max 80 characters per line
- Models use Lutaml::Model
- Clear method names (no abbreviations)
- Comprehensive error messages

### Testing

- Every class has spec file
- Test all edge cases
- No mocking (test real behavior)
- Update test expectations if behavior changes (don't lower pass threshold)

## Execution Order

1. **Start with Phase 1** - Core fixes are foundation
2. **Then Phase 2** - Error handling enables safe testing
3. **Phase 3 and 4 in parallel** - Independent work streams
4. **Phase 5** - Comprehensive testing
5. **Phase 6** - Documentation last

## Success Criteria

All items in `MACOS_PLATFORM_FIX_STATUS.md` checked off:
- [ ] All framework versions correctly mapped
- [ ] Unsupported versions error with guidance
- [ ] Platform override works (platform tags only)
- [ ] System install to framework paths
- [ ] Fontist library install to formula-keyed paths
- [ ] All tests pass (617+ examples)
- [ ] Documentation complete

## Reference Files

- **Plan:** `MACOS_PLATFORM_FIX_CONTINUATION_PLAN.md` - Detailed implementation specs
- **Status:** `MACOS_PLATFORM_FIX_STATUS.md` - Track progress here
- **Current Code:**
  - `lib/fontist/macos_framework_metadata.rb` - Version mappings
  - `lib/fontist/utils/system.rb` - Platform detection
  - `lib/fontist/formula.rb` - Compatibility checks
  - `lib/fontist/font_installer.rb` - Installation logic

## Important Facts

- macOS 26 (Tahoe) is current (2026)
- Apple jumped from macOS 15 → 26 (no versions 16-25 exist)
- Cross-framework system installs fail (OS rejects them)
- Platform override is ONLY platform tags (e.g., "macos-font7")
- Default behavior unchanged (system install, auto-detect)

## Start Here

Begin with Phase 1.1: Fix `lib/fontist/macos_framework_metadata.rb`

Update the METADATA hash with correct version ranges, then add the new methods. Test using the validation script pattern from the plan.

Mark items complete in `MACOS_PLATFORM_FIX_STATUS.md` as you progress.
// ... existing code ...