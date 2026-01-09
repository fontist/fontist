# Windows Platform Fix - Phase 2-5 Continuation Prompt

**Purpose:** Complete 100% Windows test compatibility for Fontist (Phases 2-5)
**Current Status:** Phase 1 Complete (test infrastructure implemented)
**Remaining Work:** Phases 2-5 (file system, font detection, archives, docs)
**Timeline:** 6 days compressed (originally 7 days)
**Approach:** Extend existing architecture, maintain Unix 100% pass rate

---

## Context

Phase 1 of Windows platform fixes is complete. Test infrastructure with cross-platform path helpers has been implemented. We now need to complete the remaining 4 phases to achieve 100% Windows compatibility.

**Current State:**
- **Windows:** ~90% pass rate (569/633 tests) - Phase 1 should improve to ~95%
- **Unix:** 100% pass rate (all 6 platforms: Ubuntu 22/24, macOS 13/14/15, Arch)
- **Phase 1:** ✅ Test infrastructure complete (path helpers, VCR normalization)

**Key Principles:**
1. **Extend, Don't Duplicate**: Use existing [`Utils::System`](lib/fontist/utils/system.rb:1), [`InstallLocation`](lib/fontist/install_location.rb:1) architecture
2. **Windows-Conditional Code**: All Windows-specific code behind `if Fontist::Utils::System.user_os == :windows`
3. **Unix Regression Prevention**: CRITICAL - maintain 100% on all Unix platforms
4. **MECE Architecture**: Each phase addresses distinct failure categories
5. **OOP Principles**: Proper separation of concerns, single responsibility

---

## Phase 2: File System Compatibility (Days 1-2 of 6)

### Overview
**Goal:** Resolve ~15 failures related to file locking and cleanup
**Impact:** 95% → 97% pass rate (599 → 614 passing)
**Risk:** LOW - Windows-conditional code only

### Implementation Tasks

#### 2.1 Extend Utils::System with Platform Helpers
**File:** [`lib/fontist/utils/system.rb`](lib/fontist/utils/system.rb:61)

Add after `user_os` method:
```ruby
def self.windows?
  user_os == :windows
end

def self.macos?
  user_os == :macos
end

def self.linux?
  user_os == :linux
end

def self.path_separator
  windows? ? "\\" : "/"
end

def self.case_sensitive_filesystem?
  ![:windows, :macos].include?(user_os)
end
```

#### 2.2 Create FileOps Utility Module
**File:** `lib/fontist/utils/file_ops.rb` (NEW)

```ruby
module Fontist
  module Utils
    module FileOps
      # Safe file/directory deletion with Windows retry logic
      def self.safe_rm_rf(path, retries: 3)
        return FileUtils.rm_rf(path) unless System.windows?

        # Windows file locking retry with exponential backoff
        retries.times do |attempt|
          begin
            FileUtils.rm_rf(path)
            return true
          rescue Errno::EACCES, Errno::ENOTEMPTY => e
            if attempt < retries - 1
              sleep(0.1 * (attempt + 1))
              GC.start  # Force garbage collection
              next
            end
            raise
          end
        end
      end

      # Ensure file handles released before deletion
      def self.with_file_cleanup(path)
        yield
      ensure
        if System.windows?
          GC.start
          sleep(0.05)
        end
      end
    end
  end
end
```

#### 2.3 Create FileOps Spec
**File:** `spec/fontist/utils/file_ops_spec.rb` (NEW)

Test retry logic, Windows-specific behavior, error handling.

#### 2.4 Update InstallLocation Classes
**Files:**
- [`lib/fontist/install_locations/fontist_location.rb`](lib/fontist/install_locations/fontist_location.rb:1)
- [`lib/fontist/install_locations/system_location.rb`](lib/fontist/install_locations/system_location.rb:1)

Replace `FileUtils.rm_rf` with `Fontist::Utils::FileOps.safe_rm_rf`.

#### 2.5 Update FontInstaller
**File:** [`lib/fontist/font_installer.rb`](lib/fontist/font_installer.rb:1)

Use `FileOps.safe_rm_rf` for cleanup operations.

#### 2.6 Update Test Helpers
**File:** [`spec/support/fresh_home.rb`](spec/support/fresh_home.rb:1)

Use `FileOps.safe_rm_rf` with error suppression for test cleanup.

### Success Criteria
- [ ] Utils::System has platform helper methods
- [ ] FileOps module created with retry logic
- [ ] All install locations use safe file operations
- [ ] FontInstaller uses safe cleanup
- [ ] Test helpers use safe cleanup
- [ ] Windows CI: 614/633 passing (97%)
- [ ] Unix CI: 100% maintained (CRITICAL)

---

## Phase 3: Windows Font Detection (Days 3-4 of 6)

### Overview
**Goal:** Resolve ~12 failures related to font path detection
**Impact:** 97% → 99% pass rate (614 → 626 passing)
**Risk:** LOW - Configuration-based changes

### Implementation Tasks

#### 3.1 Update system.yml Configuration
**File:** [`lib/fontist/system.yml`](lib/fontist/system.yml:1)

Add Windows section:
```yaml
system:
  windows:
    paths:
      # System fonts
      - "C:/Windows/Fonts/**/*.{ttf,otf,ttc,otc}"
      - "C:/WINDOWS/Fonts/**/*.{ttf,otf,ttc,otc}"

      # User fonts
      - "{username}/AppData/Local/Microsoft/Windows/Fonts/**/*.{ttf,otf,ttc,otc}"

      # Program Files fonts
      - "C:/Program Files/Common Files/Microsoft/**/*.{ttf,otf,ttc,otc}"
      - "C:/Program Files (x86)/Common Files/Microsoft/**/*.{ttf,otf,ttc,otc}"
```

#### 3.2 Update SystemLocation for Windows
**File:** [`lib/fontist/install_locations/system_location.rb`](lib/fontist/install_locations/system_location.rb:1)

Add Windows font directory detection:
```ruby
def self.windows_font_directories
  [
    "C:/Windows/Fonts",
    "#{ENV['LOCALAPPDATA']}/Microsoft/Windows/Fonts"
  ].select { |dir| Dir.exist?(dir) }
end
```

Update `base_path` method to handle Windows paths.

#### 3.3 Optional: Windows Registry Integration
**File:** `lib/fontist/utils/windows_fonts.rb` (NEW - OPTIONAL)

Only create if registry-based detection needed:
```ruby
module Fontist
  module Utils
    class WindowsFonts
      REGISTRY_PATH = 'SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts'

      def self.registry_fonts
        return [] unless System.windows?
        # Implement if needed
        []
      end
    end
  end
end
```

#### 3.4 Update Font Detection Tests
**Files:** Font detection spec files

Update expectations for Windows font paths.

### Success Criteria
- [ ] system.yml has Windows font paths
- [ ] SystemLocation detects Windows fonts
- [ ] Font detection tests pass on Windows
- [ ] Windows CI: 626/633 passing (99%)
- [ ] Unix CI: 100% maintained (CRITICAL)

---

## Phase 4: Archive Extraction (Day 5 of 6)

### Overview
**Goal:** Resolve ~7 failures related to archive handling
**Impact:** 99% → 100% pass rate (626 → 633 passing)
**Risk:** MEDIUM - Depends on `excavate` gem behavior

### Investigation & Implementation

#### 4.1 Investigate Excavate Gem
**Task:** Test `excavate` gem on Windows
- Does it handle .exe installers correctly?
- Does it handle Windows paths correctly?
- Are there Windows-specific extraction issues?

#### 4.2 Conditional: Update Archive Extraction
**File:** [`lib/fontist/resources/archive_resource.rb`](lib/fontist/resources/archive_resource.rb:1) (ONLY IF NEEDED)

Add Windows-specific handling **only if excavate has issues**:
```ruby
def extract_with_platform_handling(archive, destination)
  if Fontist::Utils::System.windows?
    extract_windows(archive, destination)
  else
    Extract.new(archive, destination).extract
  end
end
```

#### 4.3 Update Extraction Tests
**Files:** Archive extraction spec files

Add Windows-specific test cases or mocks if needed.

### Success Criteria
- [ ] Excavate gem Windows behavior documented
- [ ] Archive extraction works on Windows
- [ ] All archive formats supported
- [ ] Windows CI: 633/633 passing (100%)
- [ ] Unix CI: 100% maintained (CRITICAL)

---

## Phase 5: Documentation & Cleanup (Day 6 of 6)

### Overview
**Goal:** Finalize documentation and clean up temporary files
**Impact:** Complete Windows support with proper docs
**Risk:** LOW - Documentation only

### Tasks

#### 5.1 Update README.adoc
**File:** [`README.adoc`](README.adoc:1)

Add Windows platform section:
```adoc
=== Windows Platform

Fontist fully supports Windows with the following features:

* Font paths use Windows path separators (backslash)
* System fonts detected in `C:\Windows\Fonts`
* User fonts in `%LOCALAPPDATA%\Microsoft\Windows\Fonts`
* Archive extraction supports `.exe` installers
* Full compatibility with Windows file system behavior

==== Known Considerations

* File locking may cause brief delays in cleanup operations
* Administrator privileges may be required for system font installation
* Use `--location=user` to avoid permission issues

==== Installation

[source,bash]
----
gem install fontist
----

Works on Ruby 2.7+ on Windows, Linux, and macOS.
```

#### 5.2 Move Temporary Documentation
**Task:** Move to `old-docs/`:
- `WINDOWS_PLATFORM_FIX_PLAN.md`
- `WINDOWS_PLATFORM_FIX_CONTINUATION_PLAN.md`
- `WINDOWS_SPECIFIC_ISSUES.md`
- Any other temporary Windows investigation docs

Keep:
- `WINDOWS_PLATFORM_FIX_STATUS.md` (as current status)
- Official documentation (README.adoc, docs/)

#### 5.3 Update CHANGELOG.md
**File:** [`CHANGELOG.md`](CHANGELOG.md:1)

Add Windows compatibility entry:
```markdown
## [Unreleased]

### Added
- Windows platform full compatibility (100% test pass rate)
- Cross-platform path handling in test suite
- Windows-specific file operation retry logic
- Windows font detection (system and user directories)
- Windows archive extraction support

### Fixed
- File locking issues on Windows
- Path separator handling on Windows
- Font detection on Windows
- Test suite compatibility with Windows
```

#### 5.4 Update Memory Bank
**File:** [`.kilocode/rules/memory-bank/context.md`](.kilocode/rules/memory-bank/context.md:1)

Update Known Issues section:
```markdown
## Known Issues

### Windows Platform (Separate Work Item)
- ✅ COMPLETED: 100% test pass rate achieved
- All 633 tests now pass on Windows
- Cross-platform compatibility fully implemented
```

### Success Criteria
- [ ] README.adoc has Windows section
- [ ] Temporary docs moved to old-docs/
- [ ] CHANGELOG.md updated
- [ ] Memory bank updated
- [ ] All documentation current and accurate
- [ ] Windows CI: 633/633 passing (100%)
- [ ] Unix CI: 100% maintained (100%)

---

## Implementation Workflow

### Before Starting Each Phase
1. Read detailed plan in [`WINDOWS_PLATFORM_FIX_CONTINUATION_PLAN.md`](WINDOWS_PLATFORM_FIX_CONTINUATION_PLAN.md:1)
2. Review [`WINDOWS_PLATFORM_FIX_STATUS.md`](WINDOWS_PLATFORM_FIX_STATUS.md:1)
3. Understand existing architecture
4. Plan implementation

### During Implementation
1. **One phase at a time** - Sequential execution
2. **Windows-conditional code** - All changes behind `if windows?`
3. **Write tests first** - TDD approach
4. **Update status tracker** - After each file
5. **Commit frequently** - One commit per logical change

### After Each Phase
1. **Run Windows CI** - Verify expected improvement
2. **Run Unix CI** - CRITICAL: Ensure 100% maintained
3. **Update status tracker** - Document results
4. **Commit** - Clear message: "Phase X: <description>"
5. **Proceed only if Unix 100%** - Otherwise rollback and fix

---

## Critical Success Factors

### 1. Unix Regression Prevention (MOST IMPORTANT)
After EVERY phase, run all 6 Unix platforms:
- Ubuntu 22.04
- Ubuntu 24.04
- macOS 13
- macOS 14
- macOS 15
- Arch Linux

**ALL must show 633/633 passing (100%)**

If ANY drop below 100%:
1. ❌ STOP IMMEDIATELY
2. ❌ Rollback the phase
3. ❌ Investigate regression
4. ❌ Fix before proceeding

### 2. Incremental Progress
Each phase should show measurable improvement:
- Phase 2: 599/633 (95%)
- Phase 3: 614/633 (97%)
- Phase 4: 626/633 (99%)
- Phase 5: 633/633 (100%) + docs

### 3. Code Quality
- No test skips or lowered thresholds
- Proper OOP architecture
- MECE structure
- Clean separation of concerns
- Single responsibility principle

### 4. Documentation
- Update official docs (README.adoc)
- Move temporary docs to old-docs/
- Keep status tracker current
- Update memory bank

---

## Key Files Reference

### Architecture
- [`lib/fontist/utils/system.rb`](lib/fontist/utils/system.rb:39) - Platform detection
- [`lib/fontist/install_location.rb`](lib/fontist/install_location.rb:1) - Base class
- [`lib/fontist/system.yml`](lib/fontist/system.yml:1) - Platform paths
- [`lib/fontist/font_installer.rb`](lib/fontist/font_installer.rb:1) - Installation logic

### Phase 1 Complete
- [`spec/support/path_helper.rb`](spec/support/path_helper.rb:1) - Path normalization ✅
- [`spec/support/windows_test_helper.rb`](spec/support/windows_test_helper.rb:1) - Windows setup ✅
- [`spec/spec_helper.rb`](spec/spec_helper.rb:46) - Helper integration ✅
- [`spec/support/vcr_setup.rb`](spec/support/vcr_setup.rb:30) - VCR normalization ✅

### Documentation
- [`WINDOWS_PLATFORM_FIX_CONTINUATION_PLAN.md`](WINDOWS_PLATFORM_FIX_CONTINUATION_PLAN.md:1) - Full plan
- [`WINDOWS_PLATFORM_FIX_STATUS.md`](WINDOWS_PLATFORM_FIX_STATUS.md:1) - Status tracker
- [`README.adoc`](README.adoc:1) - User documentation
- [`.kilocode/rules/memory-bank/`](.kilocode/rules/memory-bank/) - Memory bank

---

## Timeline (Compressed)

| Day | Phase | Goal | Expected Result |
|-----|-------|------|-----------------|
| 1-2 | Phase 2 | File system | 599 → 614 passing (97%) |
| 3-4 | Phase 3 | Font detection | 614 → 626 passing (99%) |
| 5 | Phase 4 | Archive extraction | 626 → 633 passing (100%) |
| 6 | Phase 5 | Documentation | 633 passing + docs ✅ |

**Total:** 6 days (compressed from original 7)

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
- [ ] Clean architecture (proper OOP, MECE)
- [ ] Comprehensive test coverage
- [ ] Clear, thorough documentation

---

## Getting Started

### Step 1: Verify Phase 1
```bash
# Ensure Phase 1 CI passed
# Windows: Should show ~599/633 (95%)
# Unix: Should show 633/633 (100%) on all 6 platforms
```

### Step 2: Start Phase 2
```bash
# Create feature branch if not already on one
git checkout -b windows-platform-fixes

# Create FileOps utility
# See Phase 2 section above
```

### Step 3: Implement Incrementally
- One file at a time
- Test after each change
- Update status tracker
- Commit frequently

---

## Questions or Issues?

If you encounter:
- **Unexpected failures:** Check if Windows-conditional
- **Unix regression:** STOP, rollback, investigate
- **Different failure counts:** Document in status tracker
- **Excavate gem issues:** Document, create minimal reproduction

---

**Status:** 📋 **Ready for Phase 2 Implementation**
**Next Action:** Implement FileOps utility module
**Target:** 100% Windows + Unix compatibility in 6 days
**Principle:** Extend existing architecture, maintain Unix quality

---

**Last Updated:** 2026-01-08
**Phase 1:** ✅ Complete
**Remaining:** Phases 2-5 (6 days)