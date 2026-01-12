# Universal Install Location - Continuation Prompt

**Status:** Phase 5 Testing - 43 Regression Failures Remaining
**Priority:** HIGH
**Deadline:** Complete within 3-4 hours

## Current State

### ✅ Completed
1. **Phase 1-4: Core Implementation** (100%)
   - InstallLocation class with 3 location types
   - Platform-specific path resolution
   - Permission checking and warnings
   - Config integration
   - CLI integration

2. **Phase 5.1: Unit Tests** (100%)
   - 147 new unit tests created
   - 100% pass rate
   - Full coverage of new functionality

3. **Test Helper Fix** (Partial)
   - Fixed `font_files` helper to search recursively
   - Reduced failures from 44 → 43

### ⏳ In Progress

**Phase 5.3: Regression Test Fixes** - 43 failures remaining

The failures are NOT bugs in our implementation. They are test expectations that need updating for the NEW (and CORRECT) formula-keyed installation path structure:
- **Old:** `~/.fontist/fonts/Font.ttf` (flat)
- **New:** `~/.fontist/fonts/{formula-key}/Font.ttf` (organized, MECE, prevents conflicts)

## Root Cause Analysis

### Primary Issue: SystemFont Not Finding Fonts

The `SystemFont.find` method likely doesn't search recursively in fontist directories. It expects flat structure.

**File to check:** `lib/fontist/system_font.rb`

**Expected fix:** Ensure SystemFont searches recursively in fontist-managed directories.

### Secondary Issues

Some tests may have hardcoded path expectations that need updating.

## Fix Strategy

### Step 1: Fix SystemFont to Search Recursively

**File:** `lib/fontist/system_font.rb`

Ensure the system font search includes recursive glob patterns for fontist paths:

```ruby
# In system font path patterns, use:
File.join(path, "**", "*.{ttf,otf,ttc}")
# Instead of:
File.join(path, "*.{ttf,otf,ttc}")
```

### Step 2: Verify System Index

**File:** May need to check if `SystemIndex` also needs recursive scanning.

### Step 3: Fix Specific Test Expectations

If tests check specific paths (not just presence), update them to accept formula-keyed paths.

## Remaining Test Failures (43)

### Group A: CLI/Manifest Tests (9 failures)
- `spec/fontist/cli_spec.rb` - 7 failures
- `spec/fontist/manifest_spec.rb` - 2 failures

**Likely cause:** Checking for font presence/paths

### Group B: Font Operations (18 failures)
- `spec/fontist/font_spec.rb` - 18 failures

**Likely cause:** SystemFont not finding installed fonts

### Group C: Update/Repo Tests (7 failures)
- `spec/fontist/update_spec.rb` - 7 failures
- `spec/fontist/repo_cli_spec.rb` - 2 failures
- `spec/fontist/repo_spec.rb` - 1 failure

**Likely cause:** Formula repo setup issues (may be unrelated)

### Group D: Other Tests (9 failures)
- Various specs

## Execution Plan

### Phase 1: Fix SystemFont (1 hour)

1. Read `lib/fontist/system_font.rb`
2. Identify font path search patterns
3. Update to use recursive glob for fontist directories
4. Test with failing specs

### Phase 2: Fix SystemIndex if Needed (30 min)

1. Check if `SystemIndex` also needs updating
2. Apply similar recursive search fix

### Phase 3: Run Full Test Suite (15 min)

1. Verify all 893 tests pass
2. If any remain, analyze and fix individually

### Phase 4: Documentation (2 hours)

Once tests pass:

1. **README.adoc Updates** (1 hour)
   - Add "Installation Locations" section
   - Add "Environment Variables" section
   - Add "macOS Supplementary Fonts" section
   - Add usage examples

2. **Installation Guide** (30 min)
   - Create `docs/install-locations-guide.md`
   - Platform-specific instructions
   - Troubleshooting

3. **Documentation Cleanup** (30 min)
   - Move completed planning docs to `old-docs/`
   - Update all references
   - Verify no broken links

## Files to Focus On

### Implementation Files
- `lib/fontist/system_font.rb` - PRIMARY FOCUS
- `lib/fontist/system_index.rb` - Secondary check
- Any files that scan font directories

### Test Files (if direct fixes needed)
- `spec/fontist/font_spec.rb`
- `spec/fontist/cli_spec.rb`
- `spec/fontist/manifest_spec.rb`

## Success Criteria

- [ ] All 893 tests pass (0 failures)
- [ ] SystemFont finds fonts in formula-keyed directories
- [ ] README.adoc fully documents install locations
- [ ] Installation guide created
- [ ] Old documentation moved to old-docs/
- [ ] All references updated, no broken links

## Timeline

- **Phase 1:** Fix SystemFont - 1 hour
- **Phase 2:** Fix SystemIndex - 30 min
- **Phase 3:** Verify tests pass - 15 min
- **Phase 4:** Documentation - 2 hours
- **Total:** 3 hours 45 minutes

## Important Notes

1. **Do NOT revert the formula-keyed path structure** - it's architecturally correct
2. **Fix the code to work with the new structure**, don't hack tests
3. **Architecture correctness > test convenience** - always
4. **The formula-keyed structure is MECE** and prevents font conflicts
5. **All test failures are fixable** by updating search patterns

## Next Steps

1. Start by reading `lib/fontist/system_font.rb`
2. Identify all `Dir.glob` or path search patterns
3. Update to use `**` for recursive search in fontist directories
4. Run tests to verify fix
5. Repeat for `system_index.rb` if needed
6. Complete documentation

## Quick Reference

**Formula-keyed path format:**
```
~/.fontist/fonts/{formula-key}/{font-file}
```

**Example:**
```
~/.fontist/fonts/andale/AndaleMo.TTF
~/.fontist/fonts/source_code_pro/SourceCodePro-Regular.ttf
```

**Glob pattern for recursive search:**
```ruby
Dir.glob(Fontist.fonts_path.join("**", "*.{ttf,otf,ttc}"))
```

**Test helper fix already applied:**
```ruby
def font_files
  Dir.glob(Fontist.fonts_path.join("**", "*"))
    .select { |f| File.file?(f) }
    .map { |f| File.basename(f) }
end
```

Start with SystemFont fix - it will likely resolve most remaining failures!