# TTC Collection Font Handling - Fix Plan

## Overview

This document outlines the plan to fix TrueType Collection (TTC) font parsing issues during macOS font import. The current implementation encounters fontisan parsing errors for certain TTC files, preventing formula generation.

## Current Status

### Problem
When importing macOS supplementary fonts, TTC files fail with:
```
Fontisan brief info failed for .../HiraginoSans-W2.ttc:
Unknown font type in collection (sfnt version: 0x74746366)
```

### Impact
- Approximately 350+ macOS fonts fail to import
- Results in "No font found" error even though fonts are present
- Affects fonts like: Hiragino Sans, YuGothic, STHeiti, etc.

### Root Cause
The fontisan gem's brief_info method cannot parse certain TTC file variants. The collection file handling in fontist needs fallback mechanisms.

## Architecture Analysis

### Current Flow
```
RecursiveExtraction
    ↓
Files::FontDetector.detect(path)
    ↓
:collection detected
    ↓
Files::CollectionFile.from_path(path)
    ↓
Fontisan::Font.brief_info(path) → FAILS
    ↓
No fonts extracted, formula empty
```

### Desired Flow
```
RecursiveExtraction
    ↓
Files::FontDetector.detect(path)
    ↓
:collection detected
    ↓
Files::CollectionFile.from_path(path)
    ↓
Try: Fontisan::Font.brief_info(path)
    ↓ (if fails)
Fallback: Extract individual fonts from collection
    ↓
Create FontFile for each extracted font
    ↓
Formula generation succeeds
```

## Implementation Plan

### Phase 1: Robust TTC Handling (PRIORITY: CRITICAL)

#### 1.1 Enhanced Error Handling in CollectionFile

**Files to modify:**
- `lib/fontist/import/files/collection_file.rb`

**Changes:**
1. Wrap `Fontisan::Font.brief_info` in error handling
2. On failure, extract individual fonts using `extract_ttc` gem
3. Parse each extracted font individually
4. Return collection with properly parsed fonts

**Implementation:**
```ruby
class CollectionFile
  def self.from_path(path, name_prefix: nil)
    # Try brief_info first (fast path)
    info = safe_brief_info(path)
    return build_from_brief_info(info, path, name_prefix) if info

    # Fallback: extract and parse individual fonts
    extract_and_parse_fonts(path, name_prefix)
  end

  private

  def self.safe_brief_info(path)
    Fontisan::Font.brief_info(path)
  rescue StandardError => e
    Fontist.ui.debug("Brief info failed for #{path}: #{e.message}")
    nil
  end

  def self.extract_and_parse_fonts(path, name_prefix)
    # Use extract_ttc to extract individual fonts
    # Parse each with Fontisan::Font.full_info
    # Build collection from parsed fonts
  end
end
```

#### 1.2 Collection Extraction Utility

**Files to create:**
- `lib/fontist/import/files/ttc_extractor.rb`

**Purpose:**
- Extract individual fonts from TTC files
- Handle extraction errors gracefully
- Provide clean interface for CollectionFile

**Implementation:**
```ruby
module Fontist
  module Import
    module Files
      class TtcExtractor
        def initialize(ttc_path)
          @ttc_path = ttc_path
        end

        def extract_fonts
          Dir.mktmpdir do |tmpdir|
            # Use extract_ttc gem to split collection
            extracted_paths = extract_to_directory(tmpdir)

            # Parse each font
            extracted_paths.map do |font_path|
              Fontisan::Font.full_info(font_path)
            end
          end
        rescue StandardError => e
          Fontist.ui.error("Failed to extract TTC: #{e.message}")
          []
        end

        private

        def extract_to_directory(dir)
          # Implementation using extract_ttc gem
        end
      end
    end
  end
end
```

### Phase 2: Graceful Degradation (PRIORITY: HIGH)

#### 2.1 Skip Unparseable Fonts with Warning

**Files to modify:**
- `lib/fontist/import/recursive_extraction.rb`

**Changes:**
1. Catch collection parsing errors
2. Log detailed warning with file path
3. Continue processing other fonts
4. Track skipped files for summary report

**Implementation:**
```ruby
def match_font(path)
  case Files::FontDetector.detect(path)
  when :font
    file = Otf::FontFile.new(path, name_prefix: @name_prefix)
    @font_files << file unless already_exist?(file)
  when :collection
    collection = Files::CollectionFile.from_path(path, name_prefix: @name_prefix)
    if collection && collection.fonts.any?
      @collection_files << collection
    else
      @skipped_files ||= []
      @skipped_files << { path: path, reason: "Could not parse collection" }
      Fontist.ui.debug("Skipping unparseable collection: #{path}")
    end
  end
rescue StandardError => e
  @skipped_files ||= []
  @skipped_files << { path: path, reason: e.message }
  Fontist.ui.debug("Error processing font #{path}: #{e.message}")
end

attr_reader :skipped_files
```

### Phase 3: Enhanced Formula Builder (PRIORITY: MEDIUM)

#### 3.1 Handle Empty Font Collections

**Files to modify:**
- `lib/fontist/import/formula_builder.rb`

**Changes:**
1. Check if font_files and collection_files are both empty
2. Provide informative error message
3. Suggest troubleshooting steps

**Implementation:**
```ruby
def validate_fonts!
  if font_files.empty? && font_collection_files.empty?
    if extractor_has_skipped_files?
      raise Errors::FontExtractError,
        "No fonts could be parsed. #{skipped_count} files were skipped. " \
        "This may indicate fontisan compatibility issues with certain TTC variants."
    else
      raise Errors::FontExtractError, "No fonts found in archive"
    end
  end
end
```

### Phase 4: Improved Error Reporting (PRIORITY: MEDIUM)

#### 4.1 Detailed Import Summary

**Files to modify:**
- `lib/fontist/import/macos.rb`

**Changes:**
1. Track different failure types (download, parsing, extraction)
2. Display breakdown in summary
3. Provide actionable guidance

**Enhanced Summary:**
```
Import Summary:
  Total packages:     535
  ✓ Successful:      184 (34.4%)
  ⊝ Skipped:         1   (0.2%) (already exists)
  ✗ Failed:          350 (65.4%)
    - Download errors:    5
    - TTC parsing errors: 340
    - Other errors:       5

  💡 Tip: TTC parsing errors may be resolved in future fontisan updates.
      Subscribe to: https://github.com/fontist/fontisan/issues
```

### Phase 5: Fontisan Integration Improvements (PRIORITY: LOW)

#### 5.1 Report Issue to Fontisan

**Actions:**
1. Create detailed issue at fontist/fontisan repository
2. Include sample TTC files that fail
3. Document sfnt version: 0x74746366 incompatibility
4. Provide test cases

#### 5.2 Alternative TTC Parser

**Future consideration:**
- Implement fallback using ttfunk gem for TTC files
- Use fontisan for regular TTF/OTF files
- Maintain architecture flexibility

## Testing Strategy

### Unit Tests

**Files to create/update:**
- `spec/fontist/import/files/ttc_extractor_spec.rb`
- `spec/fontist/import/files/collection_file_spec.rb` (update)

**Test scenarios:**
1. TTC file that fontisan can parse (happy path)
2. TTC file that fontisan cannot parse (fallback path)
3. Corrupted TTC file (error handling)
4. Empty collection (validation)

### Integration Tests

**Test scenarios:**
1. Import catalog with mixed TTF and TTC files
2. Import catalog with only problematic TTC files
3. Verify error reporting accuracy
4. Verify skipped file tracking

## Success Criteria

- [ ] TTC files parse successfully OR gracefully degrade with clear errors
- [ ] Formula generation succeeds when individual fonts can be extracted
- [ ] Detailed error reporting for unparseable collections
- [ ] No regression in TTF/OTF parsing
- [ ] All existing tests continue to pass
- [ ] New tests cover TTC handling scenarios

## Implementation Order

1. **Phase 2** (Graceful Degradation) - Immediate fix, prevents crashes
2. **Phase 1** (Robust TTC Handling) - Long-term solution
3. **Phase 4** (Error Reporting) - Better user experience
4. **Phase 5** (Fontisan Integration) - Upstream fix
5. **Phase 3** (Formula Builder) - Polish

## Dependencies

### Gems
- `extract_ttc` (~> 0.3.7) - Already in Gemfile
- `fontisan` (~> 0.1) - Already in Gemfile

### External
- May need fontisan gem update to fix TTC parsing
- Consider contributing fix to fontisan upstream

## Architecture Principles

### Separation of Concerns
- Detection: `FontDetector` identifies file types
- Parsing: `CollectionFile` / `FontFile` parse fonts
- Extraction: `RecursiveExtraction` orchestrates process
- Building: `FormulaBuilder` creates formulas

### Error Handling Hierarchy
1. **Try**: Primary method (fontisan brief_info)
2. **Fallback**: Alternative method (extract and parse individually)
3. **Graceful Degradation**: Skip with detailed warning
4. **Error**: Only if truly unrecoverable

### MECE Structure
Collection handling states:
1. Parseable by brief_info → Use brief_info (fastest)
2. Not parseable but extractable → Extract and parse individually
3. Not extractable → Skip with warning, continue processing
4. Critical error → Report and stop processing this file only

## Estimated Effort

- Phase 1: 3-4 hours (implementation + testing)
- Phase 2: 1-2 hours (error handling + logging)
- Phase 3: 1 hour (validation logic)
- Phase 4: 1-2 hours (reporting enhancements)
- Phase 5: Ongoing (upstream collaboration)

Total: ~8 hours for comprehensive fix

## Risk Mitigation

### Performance
- Extraction is slower than brief_info
- Cache extracted fonts to minimize re-extraction
- Only extract when brief_info fails

### Compatibility
- Keep brief_info as primary method
- Fallback maintains backward compatibility
- No breaking changes to API

### Data Quality
- Validate extracted fonts match collection
- Compare font counts between methods
- Log discrepancies for investigation

## Open Questions

1. Should we cache individual font extractions from collections?
2. Should we report TTC parsing issues to fontisan automatically?
3. What's the acceptable failure rate for TTC files?
4. Should we provide option to skip TTC files entirely?

## Next Steps

1. Implement Phase 2 (graceful degradation) - quick win
2. Test with problematic catalog
3. Gather data on failure patterns
4. Implement Phase 1 based on data
5. Report findings to fontisan project