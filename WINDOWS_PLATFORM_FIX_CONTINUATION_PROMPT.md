# Windows Platform Fix - Implementation Continuation Prompt

**Purpose:** Achieve 100% Windows test pass rate for Fontist
**Current Status:** 90% (569/633 tests passing, 64 failures)
**Goal:** 100% (633/633 tests passing, 0 failures)
**Timeline:** 8 days
**Approach:** Leverage existing architecture, not parallel systems

---

## Context

The Fontist project has achieved 100% test pass rate on all 6 Unix platforms (Ubuntu 22/24, macOS 13/14/15, Arch Linux) following successful cross-platform fixes documented in [`CROSS_PLATFORM_TEST_FIXES_FINAL_REPORT.md`](CROSS_PLATFORM_TEST_FIXES_FINAL_REPORT.md:1).

Windows platform currently has ~64 test failures that are well-categorized and understood. These are NOT production bugs but rather platform-specific test infrastructure and compatibility issues.

**Key Documents:**
- **Plan:** [`WINDOWS_PLATFORM_FIX_CONTINUATION_PLAN.md`](WINDOWS_PLATFORM_FIX_CONTINUATION_PLAN.md:1) - Complete implementation plan
- **Status:** [`WINDOWS_PLATFORM_FIX_STATUS.md`](WINDOWS_PLATFORM_FIX_STATUS.md:1) - Track implementation progress
- **Analysis:** [`WINDOWS_SPECIFIC_ISSUES.md`](WINDOWS_SPECIFIC_ISSUES.md:1) - Detailed failure categorization
- **Original Plan:** [`WINDOWS_PLATFORM_FIX_PLAN.md`](WINDOWS_PLATFORM_FIX_PLAN.md:1) - Initial architectural thinking

---

## Your Mission

Implement the Windows platform fixes following the **revised continuation plan** that integrates with Fontist's existing architecture. Work through 5 phases sequentially, achieving incremental progress toward 100% Windows compatibility.

### Critical Principles

1. **Extend, Don't Duplicate**
   - Use existing [`Utils::System`](lib/fontist/utils/system.rb:39), [`InstallLocation`](lib/fontist/install_location.rb:1), [`system.yml`](lib/fontist/system.yml:1)
   - Don't create parallel Strategy pattern or adapters
   - Simple `if windows?` checks are clearer than complex abstractions

2. **Test Normalization, Not Production Abstraction**
   - Most path issues are test expectations, not production bugs
   - Production code already handles paths correctly via Ruby's `File` class
   - Focus on test helpers, not production path wrappers

3. **Minimal Unix Changes**
   - Unix platforms are 100% - don't risk regression
   - All changes should be Windows-conditional or test-only
   - Test Unix platforms after EVERY phase

4. **MECE Implementation**
   - Each fix addresses exactly one failure category
   - No overlap between fixes
   - All 64 failures covered across 5 phases

---

## Implementation Phases

### Phase 1: Test Infrastructure (Days 1-2) - CRITICAL

**Goal:** Resolve ~30 failures (path handling + test environment)
**Impact:** 90% → 95% pass rate
**Risk:** LOW (test-only changes)

**Key Files to Create:**
1. `spec/support/path_helper.rb` - Path normalization for tests
2. `spec/support/windows_test_helper.rb` - Windows test setup

**Key Files to Modify:**
1. `spec/spec_helper.rb` - Include both helpers
2. ~20 spec files - Use `expect_path` instead of `expect(...).to eq(...)`
3. `spec/support/vcr_setup.rb` - Normalize Windows paths

**Implementation Guide:**
```ruby
# 1. Create spec/support/path_helper.rb
module PathHelper
  def normalize_test_path(path)
    path.to_s.tr('\\', '/').sub(/^[A-Z]:/, '')
  end

  def expect_path(actual, expected)
    expect(normalize_test_path(actual)).to eq(normalize_test_path(expected))
  end
end

# 2. Update spec files
# Before:
expect(font_path).to eq("/Users/user/.fontist/fonts/courier.ttf")

# After:
expect_path(font_path, "/Users/user/.fontist/fonts/courier.ttf")
```

**Success Criteria:**
- [ ] PathHelper created with `normalize_test_path` and `expect_path`
- [ ] WindowsTestHelper created with Windows setup
- [ ] spec_helper.rb includes both helpers
- [ ] ~20 spec files updated to use `expect_path`
- [ ] VCR cassette paths normalized
- [ ] Windows CI shows ~30 fewer failures (target: 599/633 passing)
- [ ] Unix CI remains at 100% (CRITICAL)

**See:** [`WINDOWS_PLATFORM_FIX_CONTINUATION_PLAN.md`](WINDOWS_PLATFORM_FIX_CONTINUATION_PLAN.md:1) Section "Phase 1" for complete details.

---

### Phase 2: File System Compatibility (Days 3-4) - HIGH

**Goal:** Resolve ~15 failures (file locking, cleanup)
**Impact:** 95% → 97% pass rate
**Risk:** LOW (Windows-conditional code)

**Key Files to Create:**
1. `lib/fontist/utils/file_ops.rb` - Safe file operations with retry
2. `spec/fontist/utils/file_ops_spec.rb` - Test retry logic

**Key Files to Modify:**
1. `lib/fontist/utils/system.rb` - Add `windows?`, `path_separator`, `case_sensitive_filesystem?`
2. `lib/fontist/install_locations/fontist_location.rb` - Use `FileOps.safe_rm_rf`
3. `lib/fontist/install_locations/system_location.rb` - Use `FileOps.safe_rm_rf`
4. `lib/fontist/font_installer.rb` - Safe cleanup
5. `spec/support/fresh_home.rb` - Safe cleanup

**Implementation Guide:**
```ruby
# 1. Extend lib/fontist/utils/system.rb
def self.windows?
  user_os == :windows
end

def self.path_separator
  windows? ? "\\" : "/"
end

# 2. Create lib/fontist/utils/file_ops.rb
module Fontist::Utils::FileOps
  def self.safe_rm_rf(path, retries: 3)
    return FileUtils.rm_rf(path) unless System.windows?

    retries.times do |attempt|
      FileUtils.rm_rf(path)
      return true
    rescue Errno::EACCES => e
      sleep(0.1 * (attempt + 1)) if attempt < retries - 1
      GC.start
    end
  end
end

# 3. Update install locations
def cleanup_directory(dir)
  Fontist::Utils::FileOps.safe_rm_rf(dir)
end
```

**Success Criteria:**
- [ ] Utils::System extended with platform helpers
- [ ] FileOps utility created with Windows retry logic
- [ ] All InstallLocation classes use FileOps
- [ ] FontInstaller uses safe cleanup
- [ ] Test helpers use safe cleanup
- [ ] Windows CI shows ~15 fewer failures (target: 614/633 passing)
- [ ] Unix CI remains at 100% (CRITICAL)

**See:** [`WINDOWS_PLATFORM_FIX_CONTINUATION_PLAN.md`](WINDOWS_PLATFORM_FIX_CONTINUATION_PLAN.md:1) Section "Phase 2" for complete details.

---

### Phase 3: Windows Font Detection (Days 5-6) - MEDIUM

**Goal:** Resolve ~12 failures (font path detection)
**Impact:** 97% → 99% pass rate
**Risk:** LOW (configuration-based)

**Key Files to Modify:**
1. `lib/fontist/system.yml` - Add Windows font paths
2. `lib/fontist/install_locations/system_location.rb` - Windows font directories
3. Font detection tests

**Implementation Guide:**
```yaml
# Update lib/fontist/system.yml
system:
  windows:
    paths:
      - "C:/Windows/Fonts/**/*.{ttf,otf,ttc,otc}"
      - "{username}/AppData/Local/Microsoft/Windows/Fonts/**/*.{ttf,otf,ttc,otc}"
```

```ruby
# Update lib/fontist/install_locations/system_location.rb
def self.windows_font_directories
  [
    "C:/Windows/Fonts",
    "#{ENV['LOCALAPPDATA']}/Microsoft/Windows/Fonts"
  ].select { |dir| Dir.exist?(dir) }
end
```

**Success Criteria:**
- [ ] system.yml has correct Windows font paths
- [ ] SystemLocation detects Windows fonts
- [ ] Font detection tests pass on Windows
- [ ] Windows CI shows ~12 fewer failures (target: 626/633 passing)
- [ ] Unix CI remains at 100% (CRITICAL)

**See:** [`WINDOWS_PLATFORM_FIX_CONTINUATION_PLAN.md`](WINDOWS_PLATFORM_FIX_CONTINUATION_PLAN.md:1) Section "Phase 3" for complete details.

---

### Phase 4: Archive Extraction (Day 7) - MEDIUM

**Goal:** Resolve ~7 failures (archive handling)
**Impact:** 99% → 100% pass rate
**Risk:** MEDIUM (depends on `excavate` gem)

**Key Actions:**
1. Investigate `excavate` gem behavior on Windows
2. Add Windows-specific extraction handling if needed
3. Update extraction tests

**Implementation depends on findings:**
- If `excavate` works correctly → minimal changes
- If `excavate` has issues → add Windows-specific handling or file bug

**Success Criteria:**
- [ ] Excavate gem Windows behavior documented
- [ ] Archive extraction works on Windows
- [ ] All archive formats supported
- [ ] Windows CI shows ~7 fewer failures (target: 633/633 passing)
- [ ] Unix CI remains at 100% (CRITICAL)

**See:** [`WINDOWS_PLATFORM_FIX_CONTINUATION_PLAN.md`](WINDOWS_PLATFORM_FIX_CONTINUATION_PLAN.md:1) Section "Phase 4" for complete details.

---

### Phase 5: Final Cleanup & Documentation (Day 8) - MEDIUM

**Goal:** Documentation + any remaining fixes
**Impact:** Complete Windows support
**Risk:** LOW

**Key Files to Modify:**
1. `README.adoc` - Add Windows platform section
2. `.kilocode/rules/memory-bank/context.md` - Update Known Issues
3. `CHANGELOG.md` - Document Windows fixes

**Move to `old-docs/`:**
- Temporary Windows investigation notes
- Completed work reports
- Any other temporary documentation

**Success Criteria:**
- [ ] All 633 tests pass on Windows (100%)
- [ ] README.adoc has Windows section
- [ ] Temporary docs moved to old-docs/
- [ ] Memory bank updated
- [ ] CHANGELOG updated
- [ ] Unix CI remains at 100% (CRITICAL)

**See:** [`WINDOWS_PLATFORM_FIX_CONTINUATION_PLAN.md`](WINDOWS_PLATFORM_FIX_CONTINUATION_PLAN.md:1) Section "Phase 5" for complete details.

---

## Implementation Workflow

### Before Starting Each Phase

1. Read the detailed phase plan in [`WINDOWS_PLATFORM_FIX_CONTINUATION_PLAN.md`](WINDOWS_PLATFORM_FIX_CONTINUATION_PLAN.md:1)
2. Review current status in [`WINDOWS_PLATFORM_FIX_STATUS.md`](WINDOWS_PLATFORM_FIX_STATUS.md:1)
3. Understand the existing architecture (see Key Files below)
4. Plan your implementation approach

### During Implementation

1. Follow OOP principles - extend existing classes, don't duplicate
2. Keep changes focused - one phase at a time
3. Write tests for all new code
4. Use `if windows?` for platform-specific code
5. Update [`WINDOWS_PLATFORM_FIX_STATUS.md`](WINDOWS_PLATFORM_FIX_STATUS.md:1) as you progress

### After Each Phase

1. Run Windows CI - verify expected failure reduction
2. Run Unix CI - ensure 100% pass rate maintained (CRITICAL)
3. Update [`WINDOWS_PLATFORM_FIX_STATUS.md`](WINDOWS_PLATFORM_FIX_STATUS.md:1) with results
4. Commit with clear message: "Phase X: <description>"
5. Proceed to next phase only if Unix platforms still at 100%

---

## Key Files to Understand

### Architecture
- [`lib/fontist/utils/system.rb`](lib/fontist/utils/system.rb:1) - Platform detection (lines 39-61)
- [`lib/fontist/install_location.rb`](lib/fontist/install_location.rb:1) - Base class for install locations
- [`lib/fontist/install_locations/fontist_location.rb`](lib/fontist/install_locations/fontist_location.rb:1) - Fontist-managed fonts
- [`lib/fontist/install_locations/system_location.rb`](lib/fontist/install_locations/system_location.rb:1) - System fonts
- [`lib/fontist/system.yml`](lib/fontist/system.yml:1) - Platform-specific paths
- [`lib/fontist/system_font.rb`](lib/fontist/system_font.rb:1) - Font detection

### Recent Work
- [`CROSS_PLATFORM_TEST_FIXES_FINAL_REPORT.md`](CROSS_PLATFORM_TEST_FIXES_FINAL_REPORT.md:1) - Unix platform fixes
- [`FONTISAN_MIGRATION_SUMMARY.md`](FONTISAN_MIGRATION_SUMMARY.md:1) - Pure Ruby font parsing
- [`GOOGLE_FONTS_IMPORT_COMPLETION.md`](GOOGLE_FONTS_IMPORT_COMPLETION.md:1) - Recent import work

### Testing
- [`spec/spec_helper.rb`](spec/spec_helper.rb:1) - RSpec configuration
- [`spec/support/vcr_setup.rb`](spec/support/vcr_setup.rb:1) - VCR configuration
- [`spec/support/fresh_home.rb`](spec/support/fresh_home.rb:1) - Test environment setup

---

## Critical Success Factors

### 1. Unix Regression Prevention
**MOST IMPORTANT:** Unix platforms (Ubuntu, macOS, Arch) MUST remain at 100% throughout.

After EVERY phase:
```bash
# Run Unix CI
# All 6 platforms must show: ✅ 633/633 passing (100%)
```

If ANY Unix platform drops below 100%:
1. **STOP IMMEDIATELY**
2. Rollback the phase changes
3. Identify the regression
4. Fix the regression before proceeding
5. **Never sacrifice Unix quality for Windows**

### 2. Test-First Approach
- Test helpers before production changes
- Verify on Windows CI after each change
- Don't skip tests or lower thresholds

### 3. Follow Existing Patterns
- Don't create new Strategy classes when `if windows?` suffices
- Extend existing `Utils::System` instead of new platform layer
- Use `InstallLocation` architecture instead of new adapters
- Update `system.yml` instead of hardcoding paths

### 4. Clear Communication
- Update [`WINDOWS_PLATFORM_FIX_STATUS.md`](WINDOWS_PLATFORM_FIX_STATUS.md:1) daily
- Document any deviations from plan
- Note any unexpected findings
- Track blockers immediately

---

## Expected Timeline

| Day | Phase | Goal | Expected Result |
|-----|-------|------|-----------------|
| 1-2 | Phase 1 | Test infrastructure | 569 → 599 passing (95%) |
| 3-4 | Phase 2 | File system | 599 → 614 passing (97%) |
| 5-6 | Phase 3 | Font detection | 614 → 626 passing (99%) |
| 7 | Phase 4 | Archive extraction | 626 → 633 passing (100%) |
| 8 | Phase 5 | Documentation | 633 passing + docs ✅ |

---

## Success Metrics

### Minimum Acceptable
- [ ] Windows: 100% test pass rate (633/633)
- [ ] Unix: 100% test pass rate maintained (all 6 platforms)
- [ ] RuboCop clean
- [ ] Documentation updated

### Ideal
- [ ] All above PLUS:
- [ ] Fast test execution (no performance regression)
- [ ] Clean architecture (no hacky workarounds)
- [ ] Comprehensive test coverage
- [ ] Clear documentation

---

## Getting Started

### Step 1: Review Context
```bash
# Read these documents in order:
1. WINDOWS_PLATFORM_FIX_CONTINUATION_PLAN.md (complete plan)
2. WINDOWS_PLATFORM_FIX_STATUS.md (status tracker)
3. WINDOWS_SPECIFIC_ISSUES.md (failure analysis)
4. CROSS_PLATFORM_TEST_FIXES_FINAL_REPORT.md (Unix fixes)
```

### Step 2: Understand Current State
```bash
# Review key architecture files:
lib/fontist/utils/system.rb          # Platform detection
lib/fontist/install_location.rb      # Install location base
lib/fontist/system.yml                # Platform paths
spec/spec_helper.rb                   # Test configuration
```

### Step 3: Start Phase 1
```bash
# Create feature branch
git checkout -b windows-platform-fixes

# Create first test helper
# See Phase 1 in WINDOWS_PLATFORM_FIX_CONTINUATION_PLAN.md
```

### Step 4: Implement Incrementally
- One phase at a time
- Test after each change
- Update status tracker
- Commit frequently

---

## Questions or Issues?

If you encounter:
- **Unexpected test failures:** Check if change is Windows-conditional
- **Unix regression:** STOP, rollback, investigate
- **Different failure counts:** Document in status tracker
- **Excavate gem issues:** Document and create minimal reproduction

Refer to:
- Detailed plan: [`WINDOWS_PLATFORM_FIX_CONTINUATION_PLAN.md`](WINDOWS_PLATFORM_FIX_CONTINUATION_PLAN.md:1)
- Status tracker: [`WINDOWS_PLATFORM_FIX_STATUS.md`](WINDOWS_PLATFORM_FIX_STATUS.md:1)
- Memory bank: [`.kilocode/rules/memory-bank/`](.kilocode/rules/memory-bank/)

---

## Final Note

This is a **well-planned, incremental approach** to achieving 100% Windows compatibility. The plan is conservative and realistic - execution should be straightforward if you follow the phases sequentially and maintain Unix platform quality throughout.

**Remember:**
- Extend existing patterns, don't create new ones
- Test helpers solve most issues, not production abstractions
- Unix platforms are SACRED - 100% must be maintained
- MECE structure ensures all failures are addressed

**Let's achieve 100% cross-platform compatibility! 🚀**

---

**Status:** 📋 **Ready for Implementation**
**Next Action:** Start Phase 1 - Create test helpers
**Target:** 100% Windows compatibility in 8 days