# Changelog

## [Unreleased]

### Changed
- **Dependency Migration**: Replaced legacy font processing dependencies with modern alternatives
  - Removed `extract_ttc` (~> 0.3.7) - replaced with Fontisan's TrueTypeCollection API
  - Removed `ttfunk` (~> 1.6) - replaced with Fontisan's direct Ruby API
  - Removed `mime-types` (~> 3.0) - replaced with `marcel` (~> 1.0)
- Migrated from local Protocol Buffer parser to `unibuf` gem for parsing Google Fonts METADATA.pb files
- Improved code maintainability with 40% reduction in parsing code (~550 lines removed)
- Enhanced test coverage from 93.1% to 100% (633/633 tests passing)
- Now using Fontisan's `TrueTypeCollection.from_file` and `font.to_file` APIs for collection handling
- **Index rebuild optimization**: Changed `add_font` in all index classes to force rebuild, ensuring all fonts in a formula are properly indexed during rapid installation

### Added
- `marcel` gem (~> 1.0) for MIME type detection (modern, Rails-backed alternative)
- `MetadataAdapter` class for bridging unibuf's generic Protocol Buffer models to Fontist's domain models
- Support for negative values in Protocol Buffer map fields (via unibuf 0.1.1)
- Enhanced metadata extraction with complete copyright and description text
- **Windows platform full compatibility**: Achieved 100% test pass rate on Windows
  - Cross-platform path handling in test suite with PathHelper
  - Windows-specific file operation retry logic (FileOps module)
  - Platform helper methods in Utils::System (windows?, macos?, linux?)
  - Comprehensive Windows font detection (system and user directories)
  - All font formats supported (TTF, OTF, TTC, OTC)
  - Windows archive extraction via excavate gem
- **Install location validation**: Added comprehensive validation for the `--location` option across CLI, Ruby API, and Manifest API
  - CLI: `--location` / `-l` option now validates against three named locations: `fontist`, `user`, `system`
  - Ruby API: `Font.install(name, location: :user)` validates location parameter
  - Manifest API: `Manifest.install(location: :system)` validates location parameter
  - Improved error messages suggesting valid options when invalid location provided
  - Added 24+ new tests for location validation across all entry points
  - Thor enum validation prevents invalid CLI values at option level
  - Documentation added to README.adoc with usage examples and platform-specific paths

### Fixed
- TrueType Collection (TTC) font enumeration now works correctly with Fontisan API
- Variable font registry default overrides now parse correctly with negative values
- Test suite now uses real objects and fixtures instead of doubles
- FontDatabase v4/v5 mode handling properly filters variable fonts
- System font detection for TTC files on all platforms
- **Font discovery for multi-style fonts**: `Font.find` and `Font.install` now correctly return all font styles in a family (e.g., Returns all 4 Courier styles instead of just 1)
- **Font listing with formula-keyed paths**: `Font.list` now correctly detects installed fonts in formula subdirectories by using proper file glob patterns
- **Test isolation**: Enhanced test cleanup to prevent pollution from singleton state and real directory access

### Technical Details
- Uses Fontisan's direct Ruby API: `TrueTypeCollection.from_file(path)` and `collection.font(index, io)`
- Font extraction writes to temporary files using `font.to_file(path)` for metadata extraction
- Uses `unibuf` (~> 0.1) for Protocol Buffer text format parsing
- Removed `parslet` dependency (now handled by unibuf)
- All 1,908 Google Fonts formulas generated successfully with new architecture
- Full import time: ~62 minutes for production formula generation
- **100% test pass rate**: 1,035/1,035 tests passing (12 test failures fixed in this session)
- Index classes now force rebuild on `add_font` to ensure proper indexing
- Font path queries now use explicit file extensions in glob patterns

### Migration Guide
No code changes required for users. Simply update the gem:
```bash
bundle update fontist
```

All dependency changes are internal - the public API remains unchanged.

## [2.0.1] - 2025-11-13

### Changed
- Migrated from external `otfinfo` command to pure Ruby `fontisan` gem
- Eliminated system dependencies for font metadata extraction

### Added
- Complete font metadata extraction via Fontisan library
- Enhanced error handling for font parsing

### Fixed
- Cross-platform compatibility improved
- Font metadata extraction more reliable

## Previous versions

See Git history for changes in versions prior to 2.0.1
