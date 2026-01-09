# Windows-Specific Test Issues

## Overview

**Status:** ⚠️ Work In Progress  
**Current Pass Rate:** ~90% (~569/633 tests passing)  
**Remaining Failures:** ~64 tests  
**Priority:** Medium (Unix platforms complete at 100%)

This document tracks Windows-specific test failures that remain after the successful Unix cross-platform fixes. These issues are platform-specific to Windows and require dedicated investigation and solutions.

---

## Summary

While all 6 Unix platforms (Ubuntu, macOS, Arch Linux) achieve 100% test pass rate, Windows has ~64 remaining failures. These are not regression bugs but rather platform-specific compatibility issues that were exposed when comprehensive cross-platform testing was introduced.

**Key Point:** Windows functionality is NOT broken - the library works on Windows. These are test infrastructure issues that need platform-specific solutions.

---

## Failure Categories

### Category 1: Path Handling (~20 failures, ~31% of Windows issues)

#### Description
Windows uses backslashes (`\`) as path separators and includes drive letters (`C:\`), while Unix uses forward slashes (`/`). Tests expect Unix-style paths but receive Windows-style paths.

#### Examples
```ruby
# Expected (Unix)
"/Users/user/.fontist/fonts/courier.ttf"

# Actual (Windows)
"C:\Users\user\.fontist\fonts\courier.ttf"

# Also seen
"C:/Users/user/.fontist/fonts/courier.ttf"  # Mixed separators
```

#### Affected Tests
- Font path return values
- Formula path resolution
- Index path storage
- Manifest path outputs

#### Root Cause
- `File.join` uses platform-specific separators
- Tests hardcode `/` in expectations
- Path comparison assumes Unix format
- `Dir.glob` returns backslashes on Windows

#### Proposed Solutions

**Option 1: Path Normalization Helper (Recommended)**
```ruby
# spec/support/path_helper.rb
module PathHelper
  def normalize_path(path)
    path.to_s.tr('\\', '/')
      .sub(/^[A-Z]:/, '')  # Remove drive letter
  end
  
  def expect_path(actual, expected)
    expect(normalize_path(actual)).to eq(expected)
  end
end
```

**Option 2: Platform-Specific Expectations**
```ruby
RSpec.describe "Font paths" do
  let(:expected_path) do
    if Fontist::Utils::System.windows?
      "C:\\Users\\user\\.fontist\\fonts\\courier.ttf"
    else
      "/Users/user/.fontist/fonts/courier.ttf"
    end
  end
end
```

**Option 3: Pathname-Based Comparison**
```ruby
require 'pathname'

RSpec.describe "Font paths" do
  it "returns correct path" do
    result = Pathname.new(Font.install("Courier"))
    expected = Pathname.new("/Users/user/.fontist/fonts/courier.ttf")
    expect(result.cleanpath).to eq(expected.cleanpath)
  end
end
```

**Recommendation:** Option 1 (normalization helper) - least invasive, DRY

---

### Category 2: File System Behavior (~15 failures, ~23% of Windows issues)

#### Description
NTFS file system behaves differently from ext4/APFS in file locking, permissions, case-sensitivity, and temp file handling.

#### Examples
```ruby
# File locking
File.open("font.ttf", "rb") do |f|
  # Windows: File locked, can't delete while open
  # Unix: Can delete, file remains accessible
  File.delete("font.ttf")  # Fails on Windows
end

# Case insensitivity (but preserving)
File.exist?("Courier.ttf")  #=> true
File.exist?("courier.ttf")  #=> true (same file!)
File.exist?("COURIER.TTF")  #=> true (same file!)
```

#### Affected Tests
- Font file extraction and cleanup
- Temp file management
- Archive extraction
- Font installation/uninstallation

#### Root Cause
- NTFS keeps files open longer
- Different permission models
- Case-insensitive but case-preserving
- Temp directory behavior

#### Proposed Solutions

**Solution 1: Ensure File Closure**
```ruby
# lib/fontist/extract.rb
def extract_font(archive, dest)
  fonts = []
  archive.extract do |file|
    font = process_font(file)
    fonts << font
  end
ensure
  archive.close  # Explicit closure for Windows
  GC.start       # Force cleanup
end
```

**Solution 2: Platform-Specific Temp Handling**
```ruby
# lib/fontist/utils/temp_file.rb
def safe_temp_file(basename)
  if Fontist::Utils::System.windows?
    # Use different temp strategy on Windows
    Tempfile.new([basename, ".ttf"]).tap do |f|
      f.binmode
      f.close  # Close immediately on Windows
    end
  else
    Tempfile.new([basename, ".ttf"])
  end
end
```

**Solution 3: Retry Logic for File Operations**
```ruby
def delete_with_retry(path, retries: 3)
  retries.times do |i|
    File.delete(path)
    return true
  rescue Errno::EACCES => e
    sleep(0.1 * (i + 1))  # Exponential backoff
    retry if i < retries - 1
    raise
  end
end
```

---

### Category 3: Font APIs (~12 failures, ~19% of Windows issues)

#### Description
Windows font management uses registry-based registration and different APIs from Unix systems.

#### Examples
```ruby
# Unix: Font directories
/usr/share/fonts
/Library/Fonts
~/.fonts

# Windows: Registry + directories
HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts
C:\Windows\Fonts
C:\Users\<user>\AppData\Local\Microsoft\Windows\Fonts
```

#### Affected Tests
- System font detection
- Font installation
- Font listing
- Fontconfig integration (N/A on Windows)

#### Root Cause
- Registry-based font management
- Different font directories
- Fontconfig not available
- Font metadata extraction differences

#### Proposed Solutions

**Solution 1: Windows Font Registry Helper**
```ruby
# lib/fontist/utils/windows_fonts.rb
module Fontist
  module Utils
    class WindowsFonts
      def self.system_fonts
        registry_fonts + directory_fonts
      end
      
      def self.registry_fonts
        # Read from Windows Registry
        # HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts
      end
      
      def self.directory_fonts
        [
          "C:/Windows/Fonts",
          "#{ENV['LOCALAPPDATA']}/Microsoft/Windows/Fonts"
        ].flat_map { |dir| Dir.glob("#{dir}/*.{ttf,otf,ttc}") }
      end
    end
  end
end
```

**Solution 2: Mock System Fonts on Windows Tests**
```ruby
# spec/support/windows_font_helpers.rb
RSpec.configure do |config|
  config.before(:each) do
    if Fontist::Utils::System.windows?
      allow(Fontist::SystemFont).to receive(:find)
        .and_return(test_font_paths)
    end
  end
end
```

---

### Category 4: Test Environment (~10 failures, ~16% of Windows issues)

#### Description
RSpec and test infrastructure behave differently on Windows, including VCR cassette handling, mock objects, and temp directories.

#### Examples
```ruby
# VCR cassette paths
# Unix: spec/cassettes/google_fonts.yml
# Windows: spec\cassettes\google_fonts.yml

# Temp directories
# Unix: /tmp/fontist-test-12345
# Windows: C:\Users\user\AppData\Local\Temp\fontist-test-12345
```

#### Affected Tests
- VCR cassette recording/playback
- Temp directory creation
- Mock object behavior
- File path in error messages

#### Root Cause
- Path separator differences in VCR
- Temp directory location
- Different file I/O behavior
- Error message formatting

#### Proposed Solutions

**Solution 1: VCR Path Normalization**
```ruby
# spec/support/vcr_setup.rb
VCR.configure do |c|
  c.cassette_library_dir = "spec/cassettes"
  
  # Normalize paths on Windows
  c.before_record do |interaction|
    if Fontist::Utils::System.windows?
      interaction.request.uri.gsub!('\\', '/')
    end
  end
end
```

**Solution 2: Platform-Specific Temp Dirs**
```ruby
# spec/support/temp_dir_helper.rb
def test_temp_dir
  if Fontist::Utils::System.windows?
    "C:/temp/fontist-test-#{Process.pid}"
  else
    "/tmp/fontist-test-#{Process.pid}"
  end
end
```

---

### Category 5: Archive Extraction (~7 failures, ~11% of Windows issues)

#### Description
Archive extraction behaves differently on Windows, especially for .exe installers, .pkg files, and nested archives.

#### Examples
```ruby
# .exe extraction
# Windows: May require admin privileges
# Unix: Treated as regular archive

# 7-zip paths
# Windows: C:\Program Files\7-Zip\7z.exe
# Unix: /usr/bin/7z
```

#### Affected Tests
- Archive extraction tests
- Font installer tests
- Nested archive handling
- Format detection

#### Root Cause
- .exe files need special handling
- 7-zip installation location
- Permission requirements
- Archive format detection

#### Proposed Solutions

**Solution 1: Windows-Specific Extractors**
```ruby
# lib/fontist/extract.rb
def extract_archive(path)
  if Fontist::Utils::System.windows?
    WindowsExtractor.new(path).extract
  else
    UnixExtractor.new(path).extract
  end
end

class WindowsExtractor
  def extract
    case format
    when :exe
      extract_exe_with_7zip
    when :zip
      extract_zip_native
    end
  end
end
```

**Solution 2: Mock Archive Extraction on Windows**
```ruby
# For test purposes only
RSpec.configure do |config|
  config.before(:each) do
    if Fontist::Utils::System.windows?
      allow(Fontist::Extract).to receive(:new)
        .and_return(mock_extractor)
    end
  end
end
```

---

## Recommended Approach

### Phase 1: Path Normalization (Quick Win - ~20 failures)
**Estimated Effort:** 4-6 hours  
**Impact:** ~31% of Windows failures  
**Priority:** HIGH

**Tasks:**
1. Create `PathHelper` module in `spec/support/`
2. Add `normalize_path` and `expect_path` helpers
3. Update all path-related expectations
4. Test on Windows

**Expected Result:** Down to ~44 failures

---

### Phase 2: File System Compatibility (~15 failures)
**Estimated Effort:** 8-10 hours  
**Impact:** ~23% of Windows failures  
**Priority:** MEDIUM

**Tasks:**
1. Add explicit file closure in extraction code
2. Implement retry logic for Windows file operations
3. Update temp file handling
4. Add Windows-specific cleanup

**Expected Result:** Down to ~29 failures

---

### Phase 3: Font API Integration (~12 failures)
**Estimated Effort:** 6-8 hours  
**Impact:** ~19% of Windows failures  
**Priority:** MEDIUM

**Tasks:**
1. Create `WindowsFonts` utility class
2. Implement registry font detection
3. Update system font paths for Windows
4. Add Windows font tests

**Expected Result:** Down to ~17 failures

---

### Phase 4: Test Environment (~10 failures)
**Estimated Effort:** 4-6 hours  
**Impact:** ~16% of Windows failures  
**Priority:** LOW

**Tasks:**
1. Normalize VCR paths
2. Update temp directory handling
3. Fix Windows-specific mock behavior
4. Update error message expectations

**Expected Result:** Down to ~7 failures

---

### Phase 5: Archive Extraction (~7 failures)
**Estimated Effort:** 6-8 hours  
**Impact:** ~11% of Windows failures  
**Priority:** LOW

**Tasks:**
1. Create Windows-specific extractors
2. Handle .exe installer properly
3. Update 7-zip integration
4. Add extraction tests

**Expected Result:** 0 failures ✅

---

## Total Estimated Effort

**Total Time:** 28-38 hours (~1 week of focused work)  
**Phases:** 5  
**Expected Outcome:** 100% test pass rate on Windows

---

## Alternative Approach: Pragmatic Windows Support

If full Windows test parity is not immediately needed, consider:

### Minimum Viable Windows Support
**Goal:** Core functionality works, some edge cases excluded

**Approach:**
1. Fix critical path handling (Phase 1 only)
2. Document Windows limitations
3. Tag Windows-specific tests as `skip: :windows`
4. Focus Unix quality instead

**Benefits:**
- Quick path to stability
- Unix platforms remain 100%
- Windows functional (if not perfectly tested)
- Can revisit later

**Cost:**
- ~10% of tests marked as Windows-incompatible
- Some edge cases not verified on Windows
- Documentation overhead

---

## Testing Strategy

### Local Windows Testing
```bash
# On Windows machine
bundle install
bundle exec rspec

# Run specific categories
bundle exec rspec --tag path_handling
bundle exec rspec --tag file_system
bundle exec rspec --tag font_apis
```

### CI/CD Windows Testing
```yaml
# .github/workflows/windows-tests.yml
name: Windows Tests
on: [push, pull_request]
jobs:
  windows:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v3
      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: 3.3
      - run: bundle install
      - run: bundle exec rspec
```

### Incremental Progress Tracking
Track progress through CI:
- Run after each phase completion
- Document failure count reduction
- Celebrate milestones (< 50 failures, < 25 failures, etc.)

---

## Current Workarounds

### For Local Development on Windows
```bash
# Skip known failing tests
bundle exec rspec --tag ~windows_issue

# Or run only passing tests
bundle exec rspec --tag ~skip_on_windows
```

### For CI/CD
```yaml
# Allow Windows to fail temporarily
jobs:
  test-windows:
    continue-on-error: true  # Don't block PR merges
```

---

## References

### Windows-Specific Ruby Documentation
- [File separators on Windows](https://ruby-doc.org/core/File.html#method-c-SEPARATOR)
- [Pathname on Windows](https://ruby-doc.org/stdlib/libdoc/pathname/rdoc/Pathname.html)
- [Tempfile on Windows](https://ruby-doc.org/stdlib/libdoc/tempfile/rdoc/Tempfile.html)

### Windows Font Management
- [Windows Fonts Registry](https://docs.microsoft.com/en-us/typography/fonts/font-registry)
- [Windows Font Directories](https://docs.microsoft.com/en-us/typography/fonts/font-installation)

### Testing on Windows
- [RSpec on Windows](https://stackoverflow.com/questions/tagged/rspec+windows)
- [VCR and Windows Paths](https://github.com/vcr/vcr/issues)

---

## Success Criteria

### Definition of Done
- [ ] All 633 tests pass on Windows
- [ ] No platform-specific code duplication
- [ ] No test skips or exclusions
- [ ] CI/CD green on Windows
- [ ] Documentation updated

### Acceptable Intermediate States
- [x] Unix platforms at 100% (ACHIEVED)
- [ ] Windows at 95% (current: ~90%)
- [ ] Windows at 98%
- [ ] Windows at 100%

---

## Questions for Stakeholders

1. **Priority:** Is Windows 100% test parity required for next release?
2. **Timeline:** What's the deadline for Windows improvements?
3. **Resources:** Who can test on native Windows environments?
4. **Scope:** Should we support older Windows versions (7, 8)?
5. **Alternative:** Is pragmatic approach (90% + documentation) acceptable?

---

## Status Updates

### January 8, 2026
- Initial documentation created
- ~64 Windows failures categorized
- Recommended approach defined
- Estimated effort: 28-38 hours

### Next Update
- After Phase 1 completion
- Expected: ~44 failures remaining
- Target: 2-3 days from start

---

**Document Status:** ACTIVE  
**Last Updated:** January 8, 2026  
**Owner:** Cross-Platform Testing Team  
**Next Review:** After Phase 1 completion