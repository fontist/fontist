# Windows Platform Fix - Revised Continuation Plan

**Status:** 🎯 Ready for Implementation
**Based On:** Architectural review of existing Fontist patterns
**Goal:** Achieve 100% Windows test pass rate (64 failures → 0 failures)
**Timeline:** 8 days (compressed from original 10-day estimate)
**Approach:** Leverage existing architecture, not parallel systems

---

## Architectural Principles

### Core Philosophy
1. **Extend, Don't Duplicate**: Use existing [`Utils::System`](lib/fontist/utils/system.rb:39), [`InstallLocation`](lib/fontist/install_location.rb:1), [`system.yml`](lib/fontist/system.yml:1)
2. **Test Normalization Over Production Abstraction**: Most issues are test expectations, not production bugs
3. **Platform Checks Over Platform Classes**: Simple `if windows?` clearer than Strategy pattern
4. **Minimal Unix Changes**: Unix platforms are 100% - don't risk regression

### Integration Points
- **Platform Detection**: Extend `Fontist::Utils::System` (lines 39-61)
- **File System**: Extend `InstallLocation` subclasses
- **Font Paths**: Update `system.yml` configuration
- **Font Metadata**: ✅ Already cross-platform via `fontisan` gem

---

## Phase 1: Test Infrastructure (Days 1-2)

**Priority:** CRITICAL
**Impact:** ~30 failures (47% of Windows issues)
**Risk:** LOW - Test-only changes

### 1.1 Path Normalization Helper

**File:** `spec/support/path_helper.rb` (NEW)

```ruby
# spec/support/path_helper.rb
module PathHelper
  # Normalize paths for cross-platform test assertions
  def normalize_test_path(path)
    path.to_s
        .tr('\\', '/')           # Windows backslashes to forward slashes
        .sub(/^[A-Z]:/, '')      # Remove drive letters (C:)
        .gsub(/\/+/, '/')        # Normalize multiple slashes
  end

  # Cross-platform path expectation
  def expect_path(actual, expected)
    expect(normalize_test_path(actual)).to eq(normalize_test_path(expected))
  end

  # Cross-platform path array expectation
  def expect_paths(actual_array, expected_array)
    actual_normalized = actual_array.map { |p| normalize_test_path(p) }
    expected_normalized = expected_array.map { |p| normalize_test_path(p) }
    expect(actual_normalized).to match_array(expected_normalized)
  end
end
```

**Usage Example:**
```ruby
# Before (fails on Windows)
expect(font_path).to eq("/Users/user/.fontist/fonts/courier.ttf")

# After (works on all platforms)
expect_path(font_path, "/Users/user/.fontist/fonts/courier.ttf")
```

### 1.2 Windows Test Helper

**File:** `spec/support/windows_test_helper.rb` (NEW)

```ruby
# spec/support/windows_test_helper.rb
module WindowsTestHelper
  def self.setup
    return unless windows?

    configure_vcr_paths
    configure_temp_directories
    configure_file_locking_tolerance
  end

  def self.windows?
    Fontist::Utils::System.user_os == :windows
  end

  private

  def self.configure_vcr_paths
    # Normalize VCR cassette paths on Windows
    VCR.configure do |c|
      c.before_record do |interaction|
        if windows?
          interaction.request.uri.gsub!('\\', '/')
        end
      end
    end
  end

  def self.configure_temp_directories
    # Use Windows-appropriate temp directory
    ENV['TMPDIR'] ||= ENV['TEMP'] || 'C:/Windows/Temp'
  end

  def self.configure_file_locking_tolerance
    # Add retry logic for file locking issues
    # (implementation in Phase 2)
  end
end
```

### 1.3 Update spec_helper.rb

**File:** `spec/spec_helper.rb` (MODIFY)

```ruby
# Near top of file, after bundler setup
require "bundler/setup"

# Load test helpers
require_relative "support/path_helper"
require_relative "support/windows_test_helper"

# ... existing code ...

RSpec.configure do |config|
  # Include path helper in all specs
  config.include PathHelper

  # Setup Windows-specific configuration
  config.before(:suite) do
    WindowsTestHelper.setup if WindowsTestHelper.windows?
  end

  # ... existing configuration ...
end
```

### 1.4 Update Path Expectations in Specs

**Files to Modify:** (~20 spec files)
- `spec/fontist/font_spec.rb`
- `spec/fontist/cli_spec.rb`
- `spec/fontist/manifest_spec.rb`
- `spec/fontist/indexes/*_spec.rb`
- All specs with path assertions

**Pattern:**
```ruby
# Before
expect(result).to eq("/path/to/font.ttf")

# After
expect_path(result, "/path/to/font.ttf")
```

### 1.5 Fix VCR Cassette Path Handling

**File:** `spec/support/vcr_setup.rb` (MODIFY)

```ruby
VCR.configure do |c|
  c.cassette_library_dir = "spec/cassettes"

  # Normalize all paths on Windows
  c.before_record do |interaction|
    if Fontist::Utils::System.user_os == :windows?
      # Normalize request URI
      interaction.request.uri.gsub!('\\', '/')

      # Normalize response body paths if present
      if interaction.response.body.is_a?(String)
        interaction.response.body.gsub!('\\', '/')
      end
    end
  end

  # ... existing configuration ...
end
```

**Deliverables:**
- [ ] `spec/support/path_helper.rb` created
- [ ] `spec/support/windows_test_helper.rb` created
- [ ] `spec/spec_helper.rb` updated
- [ ] ~20 spec files updated with `expect_path`
- [ ] VCR setup normalized for Windows
- [ ] Tests run on Windows CI

**Success Criteria:**
- Path-related test failures reduced from ~20 to ~0
- Test environment failures reduced from ~10 to ~5
- No Unix regression

---

## Phase 2: File System Compatibility (Days 3-4)

**Priority:** HIGH
**Impact:** ~15 failures (23% of Windows issues)
**Risk:** LOW - Isolated Windows-specific code

### 2.1 Extend Utils::System

**File:** `lib/fontist/utils/system.rb` (MODIFY lines 61-78)

```ruby
# Add after user_os method (around line 65)

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
  # Windows and macOS are case-insensitive
  # Linux and Unix are case-sensitive
  ![:windows, :macos].include?(user_os)
end
```

### 2.2 Add File Operation Retry Logic

**File:** `lib/fontist/utils/file_ops.rb` (NEW)

```ruby
# lib/fontist/utils/file_ops.rb
module Fontist
  module Utils
    module FileOps
      # Delete file/directory with Windows retry logic
      def self.safe_rm_rf(path, retries: 3)
        return FileUtils.rm_rf(path) unless System.windows?

        # Windows-specific retry for file locking
        retries.times do |attempt|
          begin
            FileUtils.rm_rf(path)
            return true
          rescue Errno::EACCES, Errno::ENOTEMPTY => e
            if attempt < retries - 1
              sleep(0.1 * (attempt + 1))  # Exponential backoff
              GC.start  # Force garbage collection to release handles
              next
            end
            raise
          end
        end
      end

      # Ensure file is closed before deletion
      def self.with_file_cleanup(path)
        yield
      ensure
        if System.windows?
          GC.start  # Force handle release
          sleep(0.05)  # Brief pause for Windows
        end
      end
    end
  end
end
```

### 2.3 Update InstallLocation Classes

**File:** `lib/fontist/install_locations/fontist_location.rb` (MODIFY)

```ruby
# Replace FileUtils.rm_rf with safe version
def cleanup_directory(dir)
  return unless Dir.exist?(dir)

  Fontist::Utils::FileOps.safe_rm_rf(dir)
end

# Add explicit file closure for Windows
def install_font_file(source, destination)
  Fontist::Utils::FileOps.with_file_cleanup(source) do
    FileUtils.cp(source, destination)
  end
end
```

**File:** `lib/fontist/install_locations/system_location.rb` (MODIFY)

Similar changes for system location cleanup.

### 2.4 Update Font Installer

**File:** `lib/fontist/font_installer.rb` (MODIFY)

```ruby
# Ensure proper cleanup on Windows
def cleanup_temp_files
  return unless @temp_files

  @temp_files.each do |file|
    Fontist::Utils::FileOps.safe_rm_rf(file)
  end

  @temp_files = []
end
```

### 2.5 Update Test Temp Directory Handling

**File:** `spec/support/fresh_home.rb` (MODIFY)

```ruby
def clean_home_directory
  return unless Dir.exist?(@home_path)

  # Use safe cleanup for Windows
  Fontist::Utils::FileOps.safe_rm_rf(@home_path)
rescue => e
  # Log but don't fail tests on cleanup issues
  warn "Warning: Could not clean temp directory: #{e.message}"
end
```

**Deliverables:**
- [ ] `lib/fontist/utils/file_ops.rb` created
- [ ] `lib/fontist/utils/system.rb` extended
- [ ] `lib/fontist/install_locations/fontist_location.rb` updated
- [ ] `lib/fontist/install_locations/system_location.rb` updated
- [ ] `lib/fontist/font_installer.rb` updated
- [ ] `spec/support/fresh_home.rb` updated
- [ ] Tests run on Windows CI

**Success Criteria:**
- File system failures reduced from ~15 to ~0
- No file locking errors on Windows
- No Unix regression

---

## Phase 3: Windows Font Detection (Days 5-6)

**Priority:** MEDIUM
**Impact:** ~12 failures (19% of Windows issues)
**Risk:** LOW - Configuration-based changes

### 3.1 Update system.yml Configuration

**File:** `lib/fontist/system.yml` (MODIFY windows section)

```yaml
system:
  windows:
    paths:
      # Windows system fonts
      - "C:/Windows/Fonts/**/*.{ttf,otf,ttc,otc}"
      - "C:/WINDOWS/Fonts/**/*.{ttf,otf,ttc,otc}"

      # Windows user fonts
      - "{username}/AppData/Local/Microsoft/Windows/Fonts/**/*.{ttf,otf,ttc,otc}"

      # Program Files fonts (common locations)
      - "C:/Program Files/Common Files/Microsoft/**/*.{ttf,otf,ttc,otc}"
      - "C:/Program Files (x86)/Common Files/Microsoft/**/*.{ttf,otf,ttc,otc}"
```

### 3.2 Add Windows Registry Font Detection (Optional)

**File:** `lib/fontist/utils/windows_fonts.rb` (NEW - Optional)

```ruby
# lib/fontist/utils/windows_fonts.rb
# OPTIONAL: Only if registry-based detection needed
module Fontist
  module Utils
    class WindowsFonts
      REGISTRY_PATH = 'SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts'

      def self.registry_fonts
        return [] unless System.windows?
        return [] unless registry_available?

        # Implementation using Win32::Registry if needed
        # For now, rely on file system scanning
        []
      end

      def self.registry_available?
        require 'win32/registry'
        true
      rescue LoadError
        false
      end
    end
  end
end
```

### 3.3 Update SystemLocation for Windows

**File:** `lib/fontist/install_locations/system_location.rb` (MODIFY)

```ruby
# Add Windows-specific font directory detection
def self.font_directories
  case Fontist::Utils::System.user_os
  when :windows
    windows_font_directories
  when :macos
    macos_font_directories
  when :linux
    linux_font_directories
  end
end

def self.windows_font_directories
  [
    "C:/Windows/Fonts",
    "#{ENV['LOCALAPPDATA']}/Microsoft/Windows/Fonts"
  ].select { |dir| Dir.exist?(dir) }
end
```

**Deliverables:**
- [ ] `lib/fontist/system.yml` updated with Windows paths
- [ ] `lib/fontist/install_locations/system_location.rb` updated
- [ ] `lib/fontist/utils/windows_fonts.rb` created (optional)
- [ ] Font detection tests updated
- [ ] Tests run on Windows CI

**Success Criteria:**
- Font API failures reduced from ~12 to ~0
- Windows system fonts properly detected
- No Unix regression

---

## Phase 4: Archive Extraction (Days 7-8)

**Priority:** LOW-MEDIUM
**Impact:** ~7 failures (11% of Windows issues)
**Risk:** MEDIUM - Depends on `excavate` gem behavior

### 4.1 Investigate Excavate Gem

**Task:** Test `excavate` gem on Windows
- Does it handle .exe installers correctly?
- Does it handle Windows paths correctly?
- Are there Windows-specific extraction issues?

### 4.2 Add Windows-Specific Extraction Handling (If Needed)

**File:** `lib/fontist/resources/archive_resource.rb` (MODIFY - if needed)

```ruby
# Only if excavate has Windows issues
def extract_with_platform_handling(archive, destination)
  if Fontist::Utils::System.windows?
    extract_windows(archive, destination)
  else
    extract_unix(archive, destination)
  end
end

def extract_windows(archive, destination)
  # Windows-specific extraction logic if needed
  # Might need explicit file closure, path normalization
end
```

### 4.3 Update Archive Extraction Tests

**Files:** `spec/fontist/extract_spec.rb`, related specs

- Add Windows-specific test cases
- Mock extraction if `excavate` has issues
- Ensure proper cleanup

**Deliverables:**
- [ ] Excavate gem Windows behavior investigated
- [ ] Archive extraction updated (if needed)
- [ ] Extraction tests updated
- [ ] Tests run on Windows CI

**Success Criteria:**
- Archive extraction failures reduced from ~7 to ~0
- All archive formats work on Windows
- No Unix regression

---

## Phase 5: Final Cleanup & Documentation (Day 8)

**Priority:** MEDIUM
**Impact:** Remaining failures + documentation
**Risk:** LOW

### 5.1 Fix Remaining Failures

- Review any remaining Windows failures
- Apply targeted fixes based on root cause
- Ensure no quick workarounds - proper solutions only

### 5.2 Update Documentation

**File:** `README.adoc` (MODIFY - Windows section)

Add Windows-specific guidance:
```adoc
=== Windows Platform

Fontist fully supports Windows with the following considerations:

* Font paths use Windows-style backslashes (`\`)
* System fonts detected in `C:\Windows\Fonts`
* User fonts in `%LOCALAPPDATA%\Microsoft\Windows\Fonts`
* Archive extraction supports `.exe` installers

Known limitations:
* File locking may cause slight delays in cleanup operations
* Administrator privileges may be required for some font installations
```

### 5.3 Move Temporary Documentation

Move to `old-docs/`:
- Any temporary cross-platform fix documentation
- Windows investigation notes
- Completed work reports that are now in official docs

### 5.4 Update Memory Bank

**File:** `.kilocode/rules/memory-bank/context.md`

Update "Known Issues" section to reflect Windows completion.

**Deliverables:**
- [ ] All Windows test failures resolved (0 failures)
- [ ] README.adoc updated
- [ ] Temporary docs moved to old-docs/
- [ ] Memory bank updated
- [ ] CHANGELOG.md updated

**Success Criteria:**
- 100% test pass rate on Windows
- Documentation current
- No Unix regression

---

## Success Metrics

### Phase Completion Tracking

| Phase | Days | Failures Fixed | Cumulative Pass Rate |
|-------|------|----------------|---------------------|
| Start | - | 0 | 90% (569/633) |
| Phase 1 | 1-2 | ~30 | 95% (599/633) |
| Phase 2 | 3-4 | ~15 | 97% (614/633) |
| Phase 3 | 5-6 | ~12 | 99% (626/633) |
| Phase 4 | 7 | ~7 | 100% (633/633) |
| Phase 5 | 8 | Documentation | 100% + Docs |

### Final Success Criteria

- [x] Unix platforms remain at 100% (no regression)
- [ ] Windows platform reaches 100% (64 failures → 0)
- [ ] All new code has RSpec tests
- [ ] RuboCop clean
- [ ] Documentation updated
- [ ] Memory bank current

---

## Risk Mitigation

### Risk 1: Breaking Unix Platforms
**Mitigation:**
- All changes in Phase 1-2 are test-only or Windows-conditional
- Extensive Unix CI testing after each phase
- Feature flags for gradual rollout (if needed)

### Risk 2: Excavate Gem Issues
**Mitigation:**
- Investigation first (Phase 4.1)
- Mock extraction if needed
- File bug with excavate maintainers

### Risk 3: Performance Regression
**Mitigation:**
- Profile before/after
- Windows-specific code only executes on Windows
- No performance-critical path changes

---

## Implementation Notes

### Code Quality Standards

1. **No Test Skips**: Don't use `skip` or `pending` - fix properly
2. **No Hardcoded Paths**: Use configuration and platform detection
3. **Comprehensive Tests**: Every new method has specs
4. **Clear Documentation**: Comment Windows-specific code
5. **MECE Structure**: Each fix addresses one category

### Testing Strategy

1. **Local Development**: Test on Windows machine
2. **CI/CD**: Windows GitHub Actions runner
3. **Unix Regression**: Ubuntu + macOS + Arch CI
4. **Cross-Platform**: All platforms in CI matrix

### Git Workflow

1. Feature branch: `windows-platform-fixes`
2. One commit per phase
3. Each commit passes Unix CI
4. Final PR with all phases

---

## Timeline

**Total:** 8 days (160 hours compressed to focused implementation)

- **Day 1-2:** Phase 1 (Test Infrastructure) - 30 failures fixed
- **Day 3-4:** Phase 2 (File System) - 15 failures fixed
- **Day 5-6:** Phase 3 (Font Detection) - 12 failures fixed
- **Day 7:** Phase 4 (Archive Extraction) - 7 failures fixed
- **Day 8:** Phase 5 (Final Cleanup) - Documentation + remaining

**Deadline:** 8 days from start

---

**Status:** 📋 **Plan Complete - Ready for Implementation**
**Next Step:** Create implementation status tracker
**Last Updated:** 2026-01-08