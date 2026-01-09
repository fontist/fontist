# Continuation Prompt: Complete Windows GHA Compatibility Fixes

## Context

You are continuing work on fixing Windows compatibility issues in the Fontist Ruby gem. Phase 1 (test infrastructure fixes) is complete with 3 of 5 failure categories resolved. Phase 2 requires investigating and fixing real Windows compatibility bugs in font installation.

## What's Been Completed

### Phase 1: Test Infrastructure Fixes ✅

1. **FileOps Cleanup Permission Errors** - Fixed across all platforms
   - File: `spec/fontist/utils/file_ops_spec.rb`
   - Solution: Reset RSpec mocks before cleanup in `after` blocks

2. **FileOps Stack Overflow** - Fixed Windows retry tests
   - File: `spec/fontist/utils/file_ops_spec.rb`
   - Solution: Used `and_wrap_original` for proper method wrapping

3. **Git Clone Directory Exists** - Fixed Windows Update spec
   - File: `spec/support/fontist_helper.rb`
   - Solution: Remove existing directory before Git.clone

### Test Results After Phase 1

- **macOS (4 versions):** 617/617 passing ✅
- **Ubuntu (2 versions):** 617/617 passing ✅
- **Arch Linux:** 617/617 passing ✅
- **Windows Server 2022/2025:** 614/617 passing ⚠️ (3 failures remain)

## Current Task: Phase 2 - Fix Windows CLI Output Issues

### The Problem

Three CLI tests are failing on Windows only:

```ruby
# spec/fontist/cli_spec.rb

1) Fontist::CLI#install with formula option formula from root dir
   - Expects: Fontist.ui.say called with /AndaleMo\.TTF/i
   - Actual: Fontist.ui.say called 0 times

2) Fontist::CLI#install with formula option formula from subdir
   - Same symptoms as #1

3) Fontist::CLI#install with formula option with misspelled formula name
   - Expects: Fontist.ui.say called with /texgyrechorus-mediumitalic\.otf/i
   - Actual: Fontist.ui.say called 0 times
```

**Key Observation:** Tests receive **0 calls** to `ui.say`, meaning no output is produced at all during font installation on Windows.

### Investigation Plan

Follow these steps systematically:

#### Step 1: Add Debug Logging

Add temporary debug output to trace the code path:

```ruby
# lib/fontist/cli.rb - around line 100-120 in install command with --formula option

def install_formula_command(formula_name, options)
  $stderr.puts "DEBUG[CLI]: Installing formula: #{formula_name}"
  $stderr.puts "DEBUG[CLI]: Options: #{options.inspect}"

  paths = Fontist::Formula.install(formula_name, options)
  $stderr.puts "DEBUG[CLI]: Returned paths: #{paths.inspect}"
  $stderr.puts "DEBUG[CLI]: Paths class: #{paths.class}"

  if paths.nil? || paths.empty?
    $stderr.puts "DEBUG[CLI]: WARNING - No paths returned!"
  else
    paths.each do |path|
      $stderr.puts "DEBUG[CLI]: Processing path: #{path.inspect}"
      $stderr.puts "DEBUG[CLI]: About to call ui.say with: #{path}"
      Fontist.ui.say(path)
      $stderr.puts "DEBUG[CLI]: ui.say completed"
    end
  end

  STATUS_SUCCESS
rescue => e
  $stderr.puts "DEBUG[CLI]: Exception: #{e.class} - #{e.message}"
  $stderr.puts "DEBUG[CLI]: Backtrace: #{e.backtrace.first(5).join("\n")}"
  raise
end
```

#### Step 2: Run Tests with Debug Output

```bash
# On Windows, run:
bundle exec rspec spec/fontist/cli_spec.rb:295 --format documentation 2>&1 | tee debug.log

# Look for DEBUG lines to understand:
# - Is Formula.install being called?
# - Does it return paths?
# - Are paths in the correct format?
# - Does ui.say get called?
```

#### Step 3: Check Path Format

Windows uses backslashes. Verify path handling:

```ruby
# Investigate in:
# - lib/fontist/formula.rb (Formula.install)
# - lib/fontist/font_installer.rb (actual installation)

# Check if paths are:
# - Returned as String or Pathname?
# - Using forward slashes or backslashes?
# - Normalized for display?
```

#### Step 4: Verify Installation Actually Happens

```ruby
# Add to test or debug code:
after_installation do
  expected_file = File.join(Fontist.fonts_path, "andale", "AndaleMo.TTF")
  $stderr.puts "DEBUG: Checking if file exists: #{expected_file}"
  $stderr.puts "DEBUG: File exists? #{File.exist?(expected_file)}"

  if File.exist?(expected_file)
    $stderr.puts "DEBUG: File size: #{File.size(expected_file)}"
  else
    $stderr.puts "DEBUG: Available files in fonts_path:"
    Dir.glob(File.join(Fontist.fonts_path, "**", "*")).each do |f|
      $stderr.puts "DEBUG:   - #{f}"
    end
  end
end
```

### Likely Root Causes (Hypotheses)

**Hypothesis 1: Path Format Mismatch**
- Windows paths use `C:\Users\...` with backslashes
- Output might be normalizing differently
- Check if `File.join` vs `Pathname#join` affects output

**Hypothesis 2: Installation Failure**
- Fonts might not actually install on Windows
- Check return value vs actual file existence
- Verify Windows permissions on temp directories

**Hypothesis 3: Output Redirection**
- Windows test environment might redirect stdout/stderr
- Check Thor's output handling on Windows
- Verify `Fontist.ui.say` implementation

**Hypothesis 4: Exception Swallowing**
- Error might be caught and suppressed
- Check rescue blocks in installation chain
- Verify error handling doesn't hide failures

### Architecture Requirements

When implementing the fix, adhere to these principles:

1. **Separation of Concerns**
   - CLI handles user interaction
   - Formula handles installation orchestration
   - FontInstaller handles file operations
   - UI handles output formatting

2. **Platform Compatibility**
   - Don't scatter `if windows?` checks throughout code
   - Consider creating `Fontist::Utils::PathHelper` for path normalization
   - Centralize platform-specific behavior

3. **Path Handling**
   - Use `Pathname` internally for consistency
   - Normalize paths for display without changing internals
   - Ensure cross-platform compatibility

### Testing Strategy

1. **Local Testing**
   - If possible, test on actual Windows machine
   - Use Windows Subsystem for Linux (WSL) is NOT Windows
   - Rely on GitHub Actions for Windows Server 2022/2025

2. **Debug Logging**
   - Add extensive debug logging first
   - Push to GHA to see Windows behavior
   - Analyze logs to identify exact failure point

3. **Incremental Fixes**
   - Fix one issue at a time
   - Verify each fix doesn't break Unix platforms
   - Keep changes minimal and focused

### Files to Examine

**Primary:**
- `lib/fontist/cli.rb` - Command-line interface
- `lib/fontist/formula.rb` - Formula installation
- `lib/fontist/font_installer.rb` - Actual installation logic
- `lib/fontist/utils/ui.rb` - Output methods

**Supporting:**
- `lib/fontist/utils/system.rb` - Platform detection
- `lib/fontist/utils/file_ops.rb` - File operations
- `spec/fontist/cli_spec.rb` - Test expectations

### Success Criteria

- ✅ All 617 RSpec examples pass on Windows Server 2022 and 2025
- ✅ All tests continue to pass on macOS (4 versions)
- ✅ All tests continue to pass on Ubuntu and Arch
- ✅ No test thresholds lowered
- ✅ Code follows OOP and MECE principles
- ✅ Windows compatibility documented

### Deliverables

1. **Code Fixes**
   - Implement architectural solution (not band-aids)
   - Ensure cross-platform compatibility
   - Maintain separation of concerns

2. **Tests**
   - Verify all 617 examples pass on all platforms
   - Add Windows-specific tests if needed
   - Update test expectations if behavior intentionally changed

3. **Documentation**
   - Update `README.adoc` with Windows notes if applicable
   - Update `CHANGELOG.md` with fixes
   - Document any Windows-specific considerations

4. **Cleanup**
   - Remove debug logging
   - Move temporary docs to `old-docs/`
   - Update memory bank if significant

## Resources

**Plans:**
- `WINDOWS_GHA_FIXES_PLAN.md` - Detailed investigation and implementation plan
- `WINDOWS_GHA_IMPLEMENTATION_STATUS.md` - Current status tracker
- `TODO.windows-gha.md` - Original failure report

**GitHub Actions:**
- `.github/workflows/test-and-release.yml` - Main CI/CD workflow
- `.github/workflows/discover-fonts.yml` - Font discovery workflow (updated with Windows matrix)

**Memory Bank:**
- `.kilocode/rules/memory-bank/` - Project context and architecture

## Next Steps

1. Add debug logging as described in Step 1
2. Push to GitHub to trigger Windows CI
3. Analyze debug output from GHA logs
4. Identify the exact point where Windows behavior diverges
5. Implement the architectural fix
6. Verify across all platforms
7. Update documentation
8. Move this continuation prompt to old-docs/

## Important Notes

- **Do not lower test pass thresholds** - Fix the actual bugs
- **Follow OOP principles** - No scattered if (windows?) checks
- **Maintain backward compatibility** - Don't break existing functionality
- **Test on all platforms** - Windows fix must not break Unix
- **Document Windows-specific behavior** - Help future developers

Good luck! The test infrastructure is solid now (Phase 1), so Phase 2 is about finding and fixing the real Windows bug in font installation output.