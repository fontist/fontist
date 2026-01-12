# Import Cache Enhancement - Implementation Status

**Last Updated:** 2025-12-30

## Overview

Tracking implementation of import cache enhancement feature for Fontist formula building process. This separates import cache (for formula building) from user download cache (for font installation).

## Current Sprint

**Goal:** Complete import cache CLI arguments and verbose output
**Status:** In Progress

## Phase Status

### Phase 1: CLI Argument Support ⏳

#### 1.1 Add `--import-cache` Option
- [ ] `lib/fontist/import_cli.rb` - Add option to `macos` command
- [ ] `lib/fontist/import_cli.rb` - Add option to `google` command
- [ ] `lib/fontist/import_cli.rb` - Add option to `sil` command

#### 1.2 Update Importer Classes
- [ ] `lib/fontist/import/macos.rb` - Accept and use import_cache parameter
- [ ] `lib/fontist/import/google_fonts_importer.rb` - Accept and use import_cache parameter
- [ ] `lib/fontist/import/sil_import.rb` - Accept and use import_cache parameter

#### 1.3 Update CreateFormula
- [ ] `lib/fontist/import/create_formula.rb` - Use import_cache option if provided

### Phase 2: Enhanced Verbose Output ⏳

#### 2.1 Download Location Display
- [ ] `lib/fontist/utils/downloader.rb` - Show cache location in verbose mode

#### 2.2 Extraction Location Display
- [ ] `lib/fontist/import/recursive_extraction.rb` - Show extraction directory

#### 2.3 Cache Clear Notification
- [ ] Show when extraction cache is cleared

### Phase 3: Cache Management Commands ⏸️

#### 3.1 Add Cache CLI
- [ ] Update/create `lib/fontist/cache_cli.rb`
- [ ] Implement `clear-import` command
- [ ] Implement `info` command showing both caches

#### 3.2 Register Cache CLI
- [ ] `lib/fontist/cli.rb` - Register CacheCLI as subcommand

### Phase 4: Ruby API Support ⏸️

#### 4.1 Update Fontist Module
- [ ] `lib/fontist.rb` - Add `import_cache_path=` setter
- [ ] `lib/fontist.rb` - Update `import_cache_path` getter with precedence

#### 4.2 API Documentation
- [ ] Document Ruby API usage examples

### Phase 5: Documentation ⏸️

#### 5.1 Update README.adoc
- [ ] Add "Import Cache Management" section
- [ ] Document CLI options
- [ ] Document Ruby API
- [ ] Document environment variables

#### 5.2 Create Import Guide
- [ ] Create `docs/guide/import.md`
- [ ] Document import process
- [ ] Document cache management
- [ ] Add troubleshooting section

### Phase 6: Testing ⏸️

#### 6.1 Unit Tests
- [ ] `spec/fontist/cache_cli_spec.rb`
- [ ] Update `spec/fontist/import/macos_spec.rb`
- [ ] Update `spec/fontist/utils/cache_spec.rb`

#### 6.2 Integration Tests
- [ ] Test default cache behavior
- [ ] Test custom CLI cache
- [ ] Test custom API cache
- [ ] Test ENV var cache
- [ ] Test cache clear operations

## Completed Work ✅

### Core Implementation (2025-12-30)
- [x] `lib/fontist.rb` - Added `import_cache_path` method
- [x] `lib/fontist/utils/cache.rb` - Added `cache_path` parameter support
- [x] `lib/fontist/utils/downloader.rb` - Added `cache_path` parameter support
- [x] `lib/fontist/import/create_formula.rb` - Use import cache for downloads
- [x] `lib/fontist/import/macos.rb` - Display import cache in verbose mode
- [x] `lib/fontist/formula.rb` - Error handling for malformed formulas
- [x] `lib/fontist/index.rb` - Load formulas once for all indexes
- [x] `lib/fontist/indexes/index_mixin.rb` - Support pre-loaded formulas
- [x] `lib/fontist/import/formula_builder.rb` - Remove vacant_path logic
- [x] `lib/fontist/import/macos.rb` - Use FontFamilyName for formula naming
- [x] `lib/fontist/import/recursive_extraction.rb` - Verbose mode for file listing
- [x] `lib/fontist/utils/downloader.rb` - Verbose URL display
- [x] `lib/fontist/utils/cache.rb` - Improved cache messaging

## Known Issues

None currently

## Next Steps

1. Implement Phase 1.1 - Add CLI options
2. Implement Phase 1.2 - Update importers
3. Implement Phase 2 - Enhanced verbose output
4. Continue with remaining phases

## Dependencies

None - all work is self-contained within fontist

## Testing Notes

- Manual testing performed on macOS import
- All existing tests continue to pass
- New tests needed for cache management features

## Performance Impact

- Minimal - only affects import operations
- Separate cache prevents user cache pollution
- No impact on end-user font installation