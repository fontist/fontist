# Continuation Prompt: Import Cache Enhancement

## Context

You are continuing work on the Fontist project's import cache enhancement feature. The core functionality has been implemented - imports now use a separate cache directory for formula building. Your task is to complete the remaining CLI arguments, verbose output enhancements, and cache management commands.

## What Has Been Completed

### Core Functionality ✅
1. **Separate import cache**: `Fontist.import_cache_path` returns `~/.fontist/import_cache` (or `$FONTIST_IMPORT_CACHE` if set)
2. **Cache class updated**: `Cache.new(cache_path:)` accepts custom cache location
3. **Downloader updated**: `Downloader.download(..., cache_path:)` accepts custom cache location
4. **Formula imports use import cache**: `CreateFormula` passes `Fontist.import_cache_path` to downloader
5. **Basic verbose output**: Import cache location shown in header when `--verbose` is used

### Bug Fixes ✅
1. Verbose mode only shows component files when requested
2. Download progress shows URL in verbose mode
3. Formula filename uses Build ID correctly (no number appending)
4. Formula naming uses FontFamilyName from plist (not style name)
5. Index rebuild handles malformed formulas gracefully
6. Formulas loaded once, errors shown once (not 3 times)

## Your Task

Complete the remaining 4 phases of import cache enhancement:

### Phase 1: CLI Arguments (PRIORITY 1)

Add `--import-cache` option to all import commands so users can specify custom cache location.

**Files to modify:**
1. `lib/fontist/import_cli.rb` - Add option to macos, google, sil commands
2. `lib/fontist/import/macos.rb` - Accept and use import_cache parameter
3. `lib/fontist/import/google_fonts_importer.rb` - Accept and use import_cache parameter
4. `lib/fontist/import/sil_import.rb` - Accept and use import_cache parameter
5. `lib/fontist/import/create_formula.rb` - Use import_cache from options if provided

**Example usage after completion:**
```bash
fontist import macos --plist catalog.xml --import-cache /custom/cache --verbose
```

### Phase 2: Enhanced Verbose Output (PRIORITY 2)

Show users exactly where files are being cached and extracted.

**Files to modify:**
1. `lib/fontist/utils/downloader.rb` - Show cache location when downloading
2. `lib/fontist/import/recursive_extraction.rb` - Show extraction directory
3. Add notification when extraction cache is cleared

**Expected verbose output:**
```
Downloading from: https://example.com/font.zip
  Cache location: /Users/user/.fontist/import_cache/abc123/font.zip
  Extracting to: /var/folders/.../temp_extraction_dir
  ...component files...
  Extraction cache cleared
```

### Phase 3: Cache Management Commands (PRIORITY 3)

Add commands to view and clear import cache.

**Files to create/modify:**
1. `lib/fontist/cache_cli.rb` - Add `clear-import` and `info` commands
2. `lib/fontist/cli.rb` - Register CacheCLI if not already registered

**New commands:**
```bash
fontist cache info              # Show both caches
fontist cache clear-import      # Clear import cache only
fontist cache clear             # Clear user download cache (existing)
```

### Phase 4: Ruby API & Documentation (PRIORITY 4)

Make import cache configurable via Ruby API and document everything.

**Files to modify:**
1. `lib/fontist.rb` - Add `import_cache_path=` setter with precedence logic
2. `README.adoc` - Add "Import Cache Management" section
3. Create `docs/guide/import.md` - Comprehensive import guide

**Ruby API example:**
```ruby
# Global setting
Fontist.import_cache_path = "/custom/import/cache"

# Per-import setting
Fontist::Import::Macos.new(
  plist_path,
  import_cache: "/custom/cache"
).call
```

## Implementation Guidelines

### Architecture Principles

1. **MECE Structure**: Import cache configuration sources in order of precedence:
   - API/CLI explicit parameter (highest)
   - Global `Fontist.import_cache_path=` setting
   - `FONTIST_IMPORT_CACHE` environment variable
   - Default: `~/.fontist/import_cache` (lowest)

2. **Separation of Concerns**:
   - CLI: Argument parsing only
   - Importers: Business logic only
   - Cache: Storage management only
   - Downloader: Network operations only

3. **Open/Closed Principle**:
   - Cache class accepts any path (extensible)
   - Downloader doesn't know about import vs download cache (flexible)
   - Easy to add new cache types in future

### Code Style

- Use 2 spaces for indentation
- Follow object-oriented principles
- Each class should have single responsibility
- Use Lutaml::Model for data structures
- Follow existing patterns in the codebase

### Testing

After implementation:
1. Run `bundle exec rspec` to ensure all tests pass
2. Manually test: `fontist import macos --plist catalog.xml --import-cache /tmp/test-cache --verbose`
3. Test cache commands: `fontist cache info`, `fontist cache clear-import`

## Files Reference

### Key Files to Understand

- `lib/fontist.rb` - Main module with configuration
- `lib/fontist/import_cli.rb` - CLI for import commands
- `lib/fontist/import/macos.rb` - macOS import implementation
- `lib/fontist/import/create_formula.rb` - Formula creation (uses downloader)
- `lib/fontist/utils/cache.rb` - Cache management
- `lib/fontist/utils/downloader.rb` - Download with caching

### Documentation Files

- `README.adoc` - Main documentation
- `docs/guide/*.md` - User guides
- `IMPORT_CACHE_CONTINUATION_PLAN.md` - Detailed implementation plan
- `IMPORT_CACHE_CONTINUATION_STATUS.md` - Implementation status tracker

## Success Criteria

Your implementation is complete when:

- [ ] `fontist import macos --import-cache /path` works
- [ ] `fontist import google --import-cache /path` works
- [ ] `fontist import sil --import-cache /path` works
- [ ] Verbose mode shows cache location, download path, extraction path
- [ ] `fontist cache clear-import` clears only import cache
- [ ] `fontist cache info` shows both caches with sizes
- [ ] Ruby API `Fontist.import_cache_path = "/path"` works
- [ ] Documentation in README.adoc is complete
- [ ] All existing tests still pass
- [ ] Manual testing confirms functionality

## Quick Start

1. Read this file and `IMPORT_CACHE_CONTINUATION_PLAN.md`
2. Check `IMPORT_CACHE_CONTINUATION_STATUS.md` for current status
3. Start with Phase 1 (CLI arguments) - most user-visible
4. Test after each phase
5. Update status file as you complete tasks
6. Proceed to next phase

## Important Notes

- **Do not break existing functionality** - all existing tests must pass
- **Follow existing patterns** - look at how current commands work
- **Be thorough** - this feature needs to work reliably for formula authors
- **Update documentation** - users need to know how to use this
- **Think architecturally** - solution should be clean and maintainable

## Questions?

If uncertain about implementation details:
1. Check existing code patterns (e.g., how `--output-path` works)
2. Look at `IMPORT_CACHE_CONTINUATION_PLAN.md` for detailed specs
3. Follow MECE principles for configuration precedence
4. Ask for clarification if needed

Good luck! This is important work that will improve the formula building experience.