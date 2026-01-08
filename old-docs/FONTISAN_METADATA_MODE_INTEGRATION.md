# Fontisan Metadata Mode Integration Plan
# Target: Achieve < 30 seconds cold build (currently ~180s)

**Status:** Ready to implement
**Fontisan:** ✅ Updated with metadata load mode
**Fontist:** Needs integration
**Expected Gain:** 3-6x speedup (180s → 30-60s)

## What Changed in Fontisan

Fontisan now supports a **metadata-only mode** that parses only the essential name table entries, skipping all other tables (GSUB, GPOS, kern, etc.).

Expected API (confirm with fontisan documentation):
```ruby
# Old way (slow - parses everything):
font = Fontisan::FontFile.new(path)

# New way (fast - metadata only):
font = Fontisan::FontFile.new(path, mode: :metadata)
# OR
font = Fontisan::FontFile.new(path, metadata_only: true)
```

## Step-by-Step Integration Guide

### Step 1: Update fontist.gemspec

Update fontisan dependency to the new version with metadata mode:

```ruby
# fontist.gemspec
spec.add_dependency "fontisan", "~> 0.2"  # or whatever version has metadata mode
```

Then run:
```bash
bundle update fontisan
```

### Step 2: Update FontFile.from_path

**File:** `lib/fontist/font_file.rb`

**Current code:**
```ruby
def self.from_path(path)
  fontisan_file = Fontisan::FontFile.new(path)

  new.tap do |file|
    file.path = path
    file.family = fontisan_file.family_name
    file.full_name = fontisan_file.full_name
    file.subfamily = fontisan_file.subfamily_name
    file.post_script_name = fontisan_file.post_script_name
    file.preferred_family_name = fontisan_file.preferred_family_name
    file.preferred_subfamily_name = fontisan_file.preferred_subfamily_name
  end
end
```

**Updated code (use metadata mode):**
```ruby
def self.from_path(path)
  # CRITICAL CHANGE: Use metadata mode for 3-6x speedup!
  # Adjust the parameter based on fontisan's actual API
  fontisan_file = Fontisan::FontFile.new(path, mode: :metadata)
  # OR: fontisan_file = Fontisan::FontFile.new(path, metadata_only: true)

  new.tap do |file|
    file.path = path
    file.family = fontisan_file.family_name
    file.full_name = fontisan_file.full_name
    file.subfamily = fontisan_file.subfamily_name
    file.post_script_name = fontisan_file.post_script_name
    file.preferred_family_name = fontisan_file.preferred_family_name
    file.preferred_subfamily_name = fontisan_file.preferred_subfamily_name
  end
end
```

### Step 3: Update CollectionFile (for TTC files)

**File:** `lib/fontist/collection_file.rb`

**Current code:**
```ruby
def self.from_path(path, &block)
  fontisan_collection = Fontisan::CollectionFile.new(path)

  fontisan_collection.fonts.each do |fontisan_font|
    # ... process each font ...
  end
end
```

**Updated code:**
```ruby
def self.from_path(path, &block)
  # Use metadata mode for TTC files too!
  fontisan_collection = Fontisan::CollectionFile.new(path, mode: :metadata)
  # OR: fontisan_collection = Fontisan::CollectionFile.new(path, metadata_only: true)

  fontisan_collection.fonts.each do |fontisan_font|
    # ... process each font ...
  end
end
```

### Step 4: Check Import/Create Formula Usage

**Files to review:**
- `lib/fontist/import/font_metadata_extractor.rb`
- `lib/fontist/import/otf/font_file.rb`

These files use fontisan for **formula creation**, not indexing. They may need FULL parsing to extract complete metadata for formulas. We should keep them using full mode:

```ruby
# lib/fontist/import/font_metadata_extractor.rb
def extract(path)
  # Formula creation needs FULL metadata, NOT metadata mode
  fontisan_file = Fontisan::FontFile.new(path)  # Full parsing
  # ... extract complete metadata ...
end
```

**DO NOT change import code to metadata mode** - it needs complete information!

### Step 5: Test the Integration

```bash
# Clear the index
bundle exec exe/fontist index clear

# Rebuild with the new fontisan metadata mode
time bundle exec exe/fontist index rebuild --verbose

# Expected result: 30-60 seconds (down from 180s!)
```

### Step 6: Run Full Test Suite

```bash
# Ensure nothing broke
bundle exec rspec

# Pay special attention to:
bundle exec rspec spec/fontist/font_file_spec.rb
bundle exec rspec spec/fontist/collection_file_spec.rb
bundle exec rspec spec/fontist/system_index_spec.rb
```

### Step 7: Benchmark and Document

```bash
# Benchmark multiple times to get average
for i in {1..3}; do
  fontist index clear
  echo "Run $i:"
  time fontist index rebuild --verbose
done

# Document the results
```

## Expected Results

### Performance Targets

| Phase | Time | Speedup | Status |
|-------|------|---------|--------|
| Baseline (full parsing) | 180s | 1x | Before |
| **With metadata mode** | **40-60s** | **3-4x** | Expected |
| If combined with string opts | **30-40s** | **5-6x** | Possible |
| **Target** | **< 30s** | **6x** | ✓ |

### What to Verify

✅ **Cold build < 60s** (ideally < 30s)
✅ **All tests passing**
✅ **Same font metadata extracted**
✅ **No regressions in font detection**
✅ **Import/formula creation still works** (uses full mode)

## Troubleshooting

### If metadata mode API is different

Check fontisan's README or source code:
```bash
cd /Users/mulgogi/src/fontist/fontisan
cat README.md | grep -A 10 metadata
# OR
git log --oneline | head -20  # Check recent commits
# OR
less lib/fontisan/font_file.rb  # Check the actual API
```

Possible API variations:
- `Fontisan::FontFile.new(path, mode: :metadata)`
- `Fontisan::FontFile.new(path, metadata_only: true)`
- `Fontisan::FontFile.new(path, minimal: true)`
- `Fontisan::FontFile.new(path, tables: [:name])`

### If performance gain is less than expected

1. **Profile again** to confirm fontisan is using metadata mode:
   ```bash
   bin/profile_cold_build
   # Check if GSUB/GPOS/kern tables are still being parsed
   ```

2. **Check fontisan version:**
   ```bash
   bundle list | grep fontisan
   # Ensure it's the version with metadata mode
   ```

3. **Verify metadata mode is actually being used:**
   ```ruby
   # Add debug logging temporarily
   fontisan_file = Fontisan::FontFile.new(path, mode: :metadata)
   puts "Fontisan mode: #{fontisan_file.instance_variable_get(:@mode)}"
   ```

### If tests fail

1. **Check if metadata mode returns same data:**
   ```ruby
   full = Fontisan::FontFile.new(path)
   metadata = Fontisan::FontFile.new(path, mode: :metadata)

   puts "Family: #{full.family_name} vs #{metadata.family_name}"
   puts "Same? #{full.family_name == metadata.family_name}"
   ```

2. **Ensure import code still uses full mode:**
   - Formula creation needs complete metadata
   - Only indexing should use metadata mode

## Files to Modify

### Required Changes
1. `fontist.gemspec` - Update fontisan version
2. `lib/fontist/font_file.rb` - Add metadata mode to `from_path`
3. `lib/fontist/collection_file.rb` - Add metadata mode to TTC handling

### Do NOT Change (Keep Full Parsing)
1. `lib/fontist/import/font_metadata_extractor.rb` - Formula creation
2. `lib/fontist/import/otf/font_file.rb` - Formula creation
3. Any other import/formula creation code

### Documentation Updates
1. `README.adoc` - Update performance numbers
2. `CHANGELOG.md` - Document the speedup
3. Update any performance claims

## Testing Checklist

- [ ] Update fontisan dependency version
- [ ] Bundle update successful
- [ ] Added metadata mode to `FontFile.from_path`
- [ ] Added metadata mode to `CollectionFile.from_path`
- [ ] Verified import code still uses full mode
- [ ] All tests passing
- [ ] Cold build < 60 seconds (ideally < 30s)
- [ ] Lukewarm build still ~2s (file caching working)
- [ ] Font detection accuracy unchanged
- [ ] Formula creation still works
- [ ] Documentation updated

## Success Criteria

### Performance
- [x] Lukewarm builds < 3s (already achieved with file caching)
- [ ] **Cold builds < 30s** (achievable with metadata mode)
- [ ] No performance regression in other features

### Quality
- [ ] All tests passing (617 examples)
- [ ] No behavior changes (same fonts detected)
- [ ] Import/formula creation unaffected
- [ ] Documentation updated

### Production Ready
- [ ] Tested on macOS, Linux, Windows
- [ ] Performance gains documented
- [ ] Changelog updated
- [ ] Ready for release

## Example Test Run

```bash
$ fontist index clear
System font index cleared: /Users/user/.fontist/system_index.default_family.yml

$ time fontist index rebuild --verbose
Rebuilding system font index from scratch...
--------------------------------------------------------------------------------
⠇ 2056/2056 ...Library/Fonts/Zapfino.ttf

================================================================================
Index Build Statistics:
================================================================================
  Total time:          35.20 seconds     # ← Target achieved!
  Total fonts:         2056
  Parsed fonts:        2056
  Cached fonts:        0
  Cache hit rate:      0.0%
  Errors:              0
  Avg time per font:   0.0171 seconds    # ← 5x faster than before!
================================================================================
System font index rebuilt successfully

real    0m35.891s   # ← SUCCESS! Under 60s, close to 30s target
user    0m34.123s
sys     0m1.456s
```

## Next Steps After Integration

1. **Benchmark thoroughly** - Run multiple times, document results
2. **Update documentation** - README performance claims
3. **Update CHANGELOG** - Document the improvement
4. **Consider release** - This is a major performance win
5. **Monitor for issues** - Watch for any edge cases

## Conclusion

Integrating fontisan's metadata mode is **straightforward** and will provide **massive performance gains** (3-6x speedup). The changes are minimal, focused, and low-risk since:

- Only 2-3 files need modification
- Import/formula code unchanged
- File caching already working (90x lukewarm speedup)
- All existing tests should continue to pass
- Backward compatible (same data extracted)

**Estimated implementation time:** 1-2 hours
**Expected outcome:** Cold build < 30-60 seconds (from 180s)

Let's do this! 🚀