# Install Location Test Fixes - Continuation Plan

**Created:** 2026-01-05
**Status:** ACTIVE
**Priority:** CRITICAL

## Problem Analysis

The Universal Install Location implementation introduced a **correct architectural change**: fonts are now installed to formula-keyed directories (`~/.fontist/fonts/{formula-key}/`) instead of a flat structure (`~/.fontist/fonts/`). This provides **better organization and isolation** between formulas.

**Root Cause:** 44 test failures are due to tests expecting the OLD flat structure. The NEW structure is architecturally superior (MECE, separation of concerns, prevents conflicts).

## Affected Test Files

Based on failure list:
1. `spec/fontist/cli_spec.rb` - 7 failures (manifest-install tests)
2. `spec/fontist/font_installer_spec.rb` - 1 failure
3. `spec/fontist/font_spec.rb` - 19 failures (install, uninstall, status, list tests)
4. `spec/fontist/formula_suggestion_spec.rb` - 1 failure
5. `spec/fontist/macos_import_source_spec.rb` - 3 failures
6. `spec/fontist/manifest_spec.rb` - 2 failures
7. `spec/fontist/repo_cli_spec.rb` - 2 failures
8. `spec/fontist/repo_spec.rb` - 1 failure
9. `spec/fontist/system_font_spec.rb` - 1 failure
10. `spec/fontist/update_spec.rb` - 7 failures

## Solution Strategy

### Phase 1: Update Test Helpers (CRITICAL)

**File:** `spec/support/fontist_helper.rb`

The `font_files` helper needs to:
1. Search recursively in `~/.fontist/fonts/` to find font files in formula subdirectories
2. OR accept an optional formula key parameter to search specific formula directory
3. Maintain backward compatibility for tests

**Implementation:**
```ruby
def font_files(formula_key = nil)
  base_path = Fontist.fonts_path

  if formula_key
    # Search in specific formula directory
    Dir.glob(base_path.join(formula_key, "**", "*"))
      .select { |f| File.file?(f) }
      .map { |f| File.basename(f) }
  else
    # Search recursively in all formula directories
    Dir.glob(base_path.join("**", "*"))
      .select { |f| File.file?(f) }
      .map { |f| File.basename(f) }
  end
end
```

### Phase 2: Fix Test Expectations

Update tests to either:
1. Use the updated `font_files` helper with formula key
2. Check the returned paths from install methods (already correct)
3. Update path expectations to include formula-key subdirectory

### Phase 3: Verify System Font Detection

Ensure `SystemFont` class can find fonts in the new structure:
- Check if it scans subdirectories correctly
- Update if needed to search recursively

### Phase 4: Update Formula-Related Tests

Tests that check formula behavior need to account for formula-keyed paths.

## Detailed Fix List

### Group A: font_installer_spec.rb (1 failure)
**Issue:** Line 16 uses `font_files` helper expecting flat structure
**Fix:** Update to use formula key or check returned paths

### Group B: font_spec.rb (19 failures)
**Issue:** Multiple tests use font_files helper or check specific paths
**Fixes:**
1. Update install tests to pass formula.key to font_files
2. Update uninstall tests similarly
3. Update status tests to check correct paths
4. Update list tests

### Group C: cli_spec.rb (7 failures)
**Issue:** Manifest install tests expect flat structure
**Fix:** Update manifest result checking to account for formula-keyed paths

### Group D: manifest_spec.rb (2 failures)
**Issue:** Same as CLI spec
**Fix:** Update path expectations

### Group E: Other specs (13 failures)
**Issue:** Various path-related expectations
**Fix:** Case-by-case updates

## Implementation Order

1. ✅ **Update font_files helper** - Fixes most issues
2. ✅ **Run tests to verify helper fix**
3. ✅ **Fix remaining individual test expectations**
4. ✅ **Verify SystemFont works with new structure**
5. ✅ **Run full test suite** - Target: 0 failures

## Timeline

- Phase 1: 30 minutes (helper update)
- Phase 2: 1 hour (test updates)
- Phase 3: 15 minutes (SystemFont verification)
- Phase 4: 15 minutes (final verification)
- **Total: 2 hours**

## Success Criteria

- [ ] All 893 examples pass
- [ ] 0 failures
- [ ] Formula-keyed paths work correctly
- [ ] Backward compatibility maintained where needed
- [ ] Architecture remains clean and MECE

## Notes

- The formula-keyed path structure is CORRECT and should NOT be reverted
- Tests must adapt to the improved architecture
- This follows the principle: "Architecture correctness > test convenience"