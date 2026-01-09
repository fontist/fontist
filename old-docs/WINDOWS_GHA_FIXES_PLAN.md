# Windows GHA Test Fixes - Continuation Plan

**Created:** 2026-01-09
**Status:** Investigation Phase

## Executive Summary

Current state: 3 of 5 failure categories fixed (test infrastructure issues). Remaining 2 categories reveal real Windows compatibility bugs in font installation that require investigation and architectural fixes.

## Completed Fixes (Phase 1) ✅

### 1. FileOps Cleanup Permission Errors
- **Files:** `spec/fontist/utils/file_ops_spec.rb`
- **Fix:** Added `RSpec::Mocks.space.proxy_for(FileUtils).reset` before cleanup
- **Impact:** Fixes macOS, Ubuntu, and Windows cleanup issues

### 2. FileOps Stack Overflow
- **Files:** `spec/fontist/utils/file_ops_spec.rb`
- **Fix:** Used `and_wrap_original` for proper method wrapping
- **Impact:** Fixes Windows retry tests for `safe_cp_r` and `safe_mkdir_p`

### 3. Git Clone Directory Exists
- **Files:** `spec/support/fontist_helper.rb`
- **Fix:** Remove existing directory before Git.clone
- **Impact:** Fixes Windows Update spec

## Remaining Issues (Phase 2) 🔍

### Issue #1: Windows CLI Font Installation Failures

**Tests Failing:**
1. `Fontist::CLI#install with formula option formula from root dir`
2. `Fontist::CLI#install with formula option formula from subdir`
3. `Fontist::CLI#install with formula option with misspelled formula name suggested formula is chosen`

**Symptoms:**
- Tests expect `Fontist.ui.say` to be called with font paths
- Tests receive **0 calls** - no output produced
- Return status may still be 0 (success)

**Root Cause Analysis Needed:**

1. **Font Installation Path**
   - Are fonts actually being installed on Windows?
   - Check if files exist after installation
   - Verify Windows-specific path handling

2. **Output Generation**
   - Does `Fontist::CLI#install --formula` produce output on Windows?
   - Check if output is being redirected or suppressed
   - Verify UI.say is being called in the code path

3. **Path Formatting**
   - Windows uses backslashes in paths
   - Check if path normalization is happening
   - Verify regex patterns match Windows paths

**Investigation Steps:**

```ruby
# Add debug logging to CLI install:
# lib/fontist/cli.rb around formula installation

def install_formula(formula_name, options)
  puts "DEBUG: Installing formula #{formula_name}"
  paths = Fontist::Formula.install(formula_name, options)
  puts "DEBUG: Installation returned paths: #{paths.inspect}"

  paths.each do |path|
    puts "DEBUG: About to say: #{path}"
    Fontist.ui.say(path)
  end

  STATUS_SUCCESS
rescue => e
  puts "DEBUG: Error: #{e.class} - #{e.message}"
  raise
end
```

## Implementation Plan

### Phase 2.1: Investigation (Current)

**Files to Examine:**
1. `lib/fontist/cli.rb` - CLI install command
2. `lib/fontist/formula.rb` - Formula.install method
3. `lib/fontist/font_installer.rb` - Actual installation logic
4. `lib/fontist/utils/ui.rb` - Output methods
5. `spec/fontist/cli_spec.rb` - Test expectations

**Actions:**
1. ✅ Review CLI install --formula code path
2. ✅ Check Formula.install implementation
3. ✅ Verify FontInstaller.install returns paths correctly
4. ✅ Trace output generation on Windows
5. ✅ Add temporary debug output to identify where the flow breaks

### Phase 2.2: Root Cause Identification

**Hypothesis 1: Path Normalization Issues**
- Windows paths use backslashes
- Output might be normalizing paths differently
- Check if File.join vs Pathname affects output

**Hypothesis 2: Output Suppression**
- Check if Windows test environment redirects stdout/stderr
- Verify UI.say implementation on Windows
- Check if Thor's output handling differs on Windows

**Hypothesis 3: Installation Failure**
- Fonts might not actually install on Windows
- Check return value vs actual file existence
- Verify temp directory permissions on Windows

### Phase 2.3: Fix Implementation

**Strategy:**
1. Fix root cause (installation or output)
2. Ensure Windows path compatibility
3. Add Windows-specific tests if needed
4. Update documentation

**Files Likely to Change:**
- `lib/fontist/cli.rb`
- `lib/fontist/formula.rb`
- `lib/fontist/font_installer.rb`
- `lib/fontist/utils/ui.rb`
- `spec/fontist/cli_spec.rb` (if tests need adjustment)

### Phase 2.4: Verification

**Testing:**
1. Run failing tests locally on Windows (if available)
2. Push to GHA for full Windows matrix test
3. Verify all 68 examples pass on Windows
4. Ensure no regressions on macOS/Linux

## Architecture Principles

Following OOP and MECE principles:

1. **Separation of Concerns**
   - CLI handles user interaction
   - Formula handles installation logic
   - UI handles output formatting
   - Each layer should work correctly independently

2. **Windows Compatibility Layer**
   - Consider `Fontist::Utils::Platform` for OS-specific behavior
   - Avoid scattered `if windows?` checks
   - Centralize platform-specific logic

3. **Path Handling**
   - Use `Pathname` for consistent path operations
   - Normalize paths for output if needed
   - Keep internal paths as `Pathname` objects

## Success Criteria

- ✅ All 68 RSpec examples pass on Windows Server 2022 and 2025
- ✅ All tests pass on macOS 13, 14, 15, 26
- ✅ All tests pass on Ubuntu 22.04 and 24.04
- ✅ No test regressions introduced
- ✅ Code maintains OOP principles
- ✅ Windows compatibility properly documented

## Timeline

- **Phase 2.1 (Investigation):** 1-2 hours
- **Phase 2.2 (Root Cause):** 2-4 hours
- **Phase 2.3 (Implementation):** 4-6 hours
- **Phase 2.4 (Verification):** 1-2 hours

**Total Estimated:** 8-14 hours

## Next Steps

1. Add debug logging to CLI install command
2. Run tests with verbose output to capture what's happening
3. Compare Windows vs Unix code paths
4. Identify exact point where Windows behavior diverges
5. Implement architectural fix (not workaround)
6. Update tests if behavior change is intentional
7. Document Windows-specific considerations

## Notes

- Test infrastructure is now solid (Phase 1 fixes)
- Remaining issues are real bugs, not test issues
- Fixes must be architectural, not band-aids
- Must maintain cross-platform compatibility
- No lowering of test pass thresholds allowed