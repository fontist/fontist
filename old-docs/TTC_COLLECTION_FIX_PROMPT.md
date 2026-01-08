# Continuation Prompt: TTC Collection Font Handling Fix

## Context

You are continuing work on the Fontist project to fix TrueType Collection (TTC) font parsing failures during macOS font import. The import cache enhancement has been completed successfully. Your task is to implement robust TTC handling so that 350+ macOS collection fonts can be properly imported into formulas.

## What Has Been Completed

### Import Cache Enhancement ✅
1. All import commands support `--import-cache` option
2. Verbose output shows cache locations and extraction paths
3. Cache management commands working (`cache info`, `cache clear-import`)
4. Ruby API supports `Fontist.import_cache_path=`
5. Complete documentation in README.adoc

### Bug Fixes ✅
1. String to Pathname conversion in CreateFormula
2. Cache.cache_path accessor added
3. UI.say argument errors fixed

## Current Problem

When importing macOS supplementary fonts, approximately 350 out of 535 fonts fail with:

```
Fontisan brief info failed for .../HiraginoSans-W2.ttc:
Unknown font type in collection (sfnt version: 0x74746366)
  ✗ Failed: No font found
```

**Root Cause:** The fontisan gem's `brief_info` method cannot parse certain TTC file variants, causing formula generation to fail even though font files are present.

**Impact:** 65.4% of macOS fonts cannot be imported into formulas.

## Your Task

Implement comprehensive TTC collection handling with proper fallback mechanisms:

### Phase 1: Graceful Error Handling (PRIORITY 1)

Update collection file handling to gracefully skip unparseable collections instead of failing completely.

**Files to modify:**
1. `lib/fontist/import/files/collection_file.rb` - Wrap brief_info in error handling
2. `lib/fontist/import/recursive_extraction.rb` - Catch and log collection errors, continue processing
3. `lib/fontist/import/macos.rb` - Track and report different failure types

**Expected behavior:**
- Collections that parse successfully → Process normally
- Collections that fail to parse → Log warning, skip gracefully, continue to next font
- Report breakdown: successful, skipped collections, other failures

### Phase 2: Robust TTC Extraction (PRIORITY 2)

Implement fallback extraction for unparseable TTC files using extract_ttc gem.

**Files to create:**
1. `lib/fontist/import/files/ttc_extractor.rb` - Extract individual fonts from collection

**Files to modify:**
1. `lib/fontist/import/files/collection_file.rb` - Use extractor as fallback when brief_info fails
2. `lib/fontist/import/otf/font_file.rb` - May need enhancements for extracted fonts

**Implementation strategy:**
```ruby
# In CollectionFile.from_path:
1. Try Fontisan::Font.brief_info (fast path)
2. If fails, extract individual fonts with extract_ttc
3. Parse each extracted font with Fontisan::Font.full_info
4. Build collection from successfully parsed fonts
5. Return collection if any fonts parsed, nil otherwise
```

### Phase 3: Enhanced Error Reporting (PRIORITY 3)

Provide detailed feedback about import results.

**Files to modify:**
1. `lib/fontist/import/macos.rb` - Track failure categories
2. `lib/fontist/import/recursive_extraction.rb` - Expose skipped files count
3. `lib/fontist/import/macos.rb` - Display comprehensive summary

**Enhanced summary format:**
```
Import Summary:
  Total packages:     535
  ✓ Successful:      450 (84.1%)
  ⊝ Skipped:         1   (0.2%) (already exists)
  ✗ Failed:          84  (15.7%)
    - TTC parsing:   50 (fallback extraction may help)
    - Download:      20
    - Other:         14
```

### Phase 4: Testing & Validation (PRIORITY 4)

Ensure all changes work correctly and no regressions.

**Files to create/update:**
1. `spec/fontist/import/files/ttc_extractor_spec.rb` - Test extractor
2. `spec/fontist/import/files/collection_file_spec.rb` - Test fallback logic
3. Run full test suite - ensure no regressions
4. Manual test with macOS Font7 catalog - verify higher success rate

## Implementation Guidelines

### Architecture Principles

1. **Error Handling Hierarchy:**
   - Try: Primary method (brief_info)
   - Fallback: Alternative method (extract + parse)
   - Skip: Gracefully skip with warning
   - Fail: Only for critical unrecoverable errors

2. **Separation of Concerns:**
   - Detection: FontDetector identifies file types
   - Parsing: CollectionFile/FontFile parse fonts
   - Extraction: TtcExtractor handles collection splitting
   - Orchestration: RecursiveExtraction coordinates process

3. **MECE Structure - Collection States:**
   - Parseable by brief_info → Use brief_info (fast)
   - Not parseable but extractable → Extract & parse individually
   - Not extractable → Skip with warning, continue
   - Critical error → Report and stop this file only

### Code Style

- Use 2 spaces for indentation
- Follow object-oriented principles
- Each class has single responsibility
- Use Lutaml::Model for data structures (where applicable)
- Comprehensive error handling with meaningful messages

### Performance Considerations

- Brief_info is fast (~10ms), prefer it when it works
- Extraction is slower (~100-200ms), use only as fallback
- Don't extract same file multiple times
- Clean up temporary files after extraction

## Files Reference

### Key Files to Understand

#### Collection Handling
- `lib/fontist/import/files/collection_file.rb` - TTC file parsing
- `lib/fontist/import/files/font_detector.rb` - File type detection
- `lib/fontist/import/recursive_extraction.rb` - Extraction orchestration

#### Font Parsing
- `lib/fontist/import/otf/font_file.rb` - Individual font parsing
- `lib/fontist/import/font_metadata_extractor.rb` - Metadata extraction

#### Import Flow
- `lib/fontist/import/macos.rb` - macOS import orchestration
- `lib/fontist/import/create_formula.rb` - Formula creation
- `lib/fontist/import/formula_builder.rb` - Formula assembly

### External Dependencies

- **fontisan** (~> 0.1) - Font metadata extraction
  - `Fontisan::Font.brief_info(path)` - Fast collection parsing (may fail)
  - `Fontisan::Font.full_info(path)` - Detailed font parsing (more robust)

- **extract_ttc** (~> 0.3.7) - TTC extraction
  - Already in Gemfile
  - Used to split TTC into individual fonts

## Success Criteria

Your implementation is complete when:

- [ ] TTC files parse successfully using brief_info OR fallback extraction
- [ ] Import success rate >90% (currently 34.4%)
- [ ] Detailed error reporting shows failure breakdown
- [ ] No regressions in TTF/OTF parsing
- [ ] All existing tests pass
- [ ] New tests cover TTC handling scenarios
- [ ] Manual test shows dramatic improvement:
  ```bash
  fontist import macos --plist catalog.xml --verbose
  # Should show 450+ successes instead of 184
  ```

## Testing Strategy

### Manual Testing

```bash
# Test with Font7 catalog
bundle exec fontist import macos \
  --plist com_apple_MobileAsset_Font7.xml \
  --output-path ./test-formulas \
  --verbose

# Expect to see:
# - Higher success count (450+ instead of 184)
# - Clear warnings for unparseable collections
# - Detailed summary with failure breakdown
```

### Automated Testing

```bash
# Run full test suite
bundle exec rspec

# Should maintain 99%+ pass rate
# Should have new specs for TTC handling
```

## Important Notes

### Error Handling Philosophy
- **Don't crash** - One bad font shouldn't stop entire import
- **Be informative** - Tell user what went wrong and why
- **Be actionable** - Provide guidance on next steps
- **Fail gracefully** - Continue processing remaining fonts

### Code Quality
- Follow existing patterns in the codebase
- Maintain MECE structure
- Ensure separation of concerns
- Write comprehensive tests

### Performance
- Fast path first (brief_info)
- Slow path only when needed (extraction)
- Clean up temporary files
- Don't re-extract same file

## Quick Start

1. Read TTC_COLLECTION_FIX_PLAN.md for detailed architecture
2. Check TTC_COLLECTION_FIX_STATUS.md for current state
3. Start with Phase 1 (Graceful Degradation) - quick win
4. Implement Phase 2 (Robust Extraction) - complete fix
5. Add Phase 3 (Error Reporting) - polish
6. Test thoroughly before completion

## Expected Outcome

After implementation:
```bash
$ fontist import macos --plist catalog.xml --verbose

Import Summary:
  Total packages:     535
  ✓ Successful:      480 (89.7%)
  ⊝ Skipped:         5   (0.9%) (already exists)
  ✗ Failed:          50  (9.3%)
    - TTC parsing:   30 (fontisan limitation)
    - Download:      15
    - Other:         5

  💡 Note: Some TTC parsing errors are due to fontisan gem limitations.
      These will be addressed in future fontisan updates.
```

Good luck! This is important work to support the full macOS font catalog.