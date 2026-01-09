# Windows Platform Fix Plan

## Purpose

Architectural plan to resolve Windows-specific test failures and achieve 100% cross-platform compatibility for Fontist.

## Current Status

| Platform | Test Pass Rate | Failures | Status |
|----------|---------------|----------|--------|
| **Unix (Ubuntu, macOS, Arch)** | 100% | 0 | ✅ Production Ready |
| **Windows** | 90% | 64 | ⚠️ Needs Work |

**Goal:** Achieve 100% test pass rate on Windows through architectural solutions, not test workarounds.

---

## Architecture Principles

### 1. Object-Oriented Design
- Create Windows-specific adapter classes
- Use composition over inheritance
- Encapsulate Windows behavior in dedicated classes

### 2. Separation of Concerns
- Path handling separate from business logic
- File system operations abstracted
- Platform detection centralized

### 3. MECE (Mutually Exclusive, Collectively Exhaustive)
- Each failure category addressed once
- No overlap between fixes
- All Windows issues covered

### 4. Extensibility
- Open for new platforms
- Closed for modification of existing adapters
- Strategy pattern for platform-specific behavior

---

## Problem Analysis

### Windows Failure Categories (MECE)

| Category | Count | Percentage | Root Cause |
|----------|-------|------------|-------------|
| **Path Handling** | ~20 | 31% | Case sensitivity, path separators, temp directory issues |
| **File System Behavior** | ~15 | 23% | File locking, directory creation, permissions |
| **Font APIs** | ~12 | 19% | Font metadata extraction, TTC handling |
| **Test Environment** | ~10 | 16% | Temp directory cleanup, process isolation |
| **Archive Extraction** | ~7 | 11% | Windows-specific archive formats, permissions |

**Total:** 64 failures across 5 mutually exclusive categories

---

## Architectural Solution

### Phase 1: Platform Abstraction Layer (Foundation)

**Objective:** Create abstraction layer for cross-platform operations

#### 1.1 Platform Strategy Pattern

```ruby
# lib/fontist/platform/strategy.rb
module Fontist
  module Platform
    class Strategy
      def self.current
        @current ||= case Utils::System.user_os
        when :windows
          WindowsStrategy.new
        when :macos
          MacOSStrategy.new
        when :linux
          LinuxStrategy.new
        end
      end

      def path_separator
        raise NotImplementedError
      end

      def case_sensitive?
        raise NotImplementedError
      end

      def temp_dir_base
        raise NotImplementedError
      end
    end
  end
end
```

#### 1.2 Concrete Strategies

```ruby
# lib/fontist/platform/windows_strategy.rb
module Fontist
  module Platform
    class WindowsStrategy < Strategy
      def path_separator
        "\\"
      end

      def case_sensitive?
        false
      end

      def temp_dir_base
        # Windows-specific temp directory handling
        ENV.fetch("TEMP", "C:\\Windows\\Temp")
      end

      def normalize_path(path)
        # Windows path normalization
        path.gsub("/", "\\")
      end
    end
  end
end
```

#### 1.3 Path Utility Adapter

```ruby
# lib/fontist/utils/path_adapter.rb
module Fontist
  module Utils
    class PathAdapter
      def self.join(*parts)
        strategy = Fontist::Platform::Strategy.current
        parts = parts.map { |p| normalize_part(p, strategy) }
        parts.join(strategy.path_separator)
      end

      def self.normalize_part(part, strategy)
        return part if strategy.case_sensitive?
        part.downcase
      end

      def self.match?(pattern, path)
        strategy = Fontist::Platform::Strategy.current
        if strategy.case_sensitive?
          File.fnmatch(pattern, path)
        else
          File.fnmatch(pattern.downcase, path.downcase)
        end
      end
    end
  end
end
```

### Phase 2: File System Abstraction

**Objective:** Encapsulate Windows-specific file system behavior

#### 2.1 File System Adapter

```ruby
# lib/fontist/utils/filesystem_adapter.rb
module Fontist
  module Utils
    class FilesystemAdapter
      def self.create_temp_dir(base: nil)
        strategy = Fontist::Platform::Strategy.current
        base ||= strategy.temp_dir_base

        Dir.mktmpdir("fontist-", base)
      rescue Errno::EEXIST => e
        # Windows-specific temp directory handling
        handle_temp_dir_conflict(e)
      end

      def self.cleanup_temp_dir(dir)
        # Platform-aware cleanup
        FileUtils.rm_rf(dir)
      rescue => e
        # Handle Windows file locking issues
        handle_cleanup_error(e)
      end

      private

      def self.handle_temp_dir_conflict(error)
        # Windows-specific conflict resolution
        # Implementation...
      end

      def self.handle_cleanup_error(error)
        # Windows-specific cleanup error handling
        # Implementation...
      end
    end
  end
end
```

### Phase 3: Font API Abstraction

**Objective:** Abstract Windows-specific font API differences

#### 3.1 Font Metadata Adapter

```ruby
# lib/fontist/utils/font_metadata_adapter.rb
module Fontist
  module Utils
    class FontMetadataAdapter
      def self.extract_metadata(file_path)
        strategy = Fontist::Platform::Strategy.current

        case strategy
        when Fontist::Platform::WindowsStrategy
          extract_windows_metadata(file_path)
        else
          extract_unix_metadata(file_path)
        end
      end

      private

      def self.extract_windows_metadata(file_path)
        # Windows-specific font metadata extraction
        # Handle TTC/OTC differences
        # Handle font API quirks
      end

      def self.extract_unix_metadata(file_path)
        # Standard fontisan extraction
        Fontist::Import::FontMetadataExtractor.extract(file_path)
      end
    end
  end
end
```

### Phase 4: Test Environment Improvements

**Objective:** Fix Windows-specific test environment issues

#### 4.1 Enhanced Test Helper

```ruby
# spec/support/windows_test_helper.rb
module Spec
  module WindowsTestHelper
    def self.setup_test_environment
      return unless windows?

      # Windows-specific test setup
      configure_temp_cleanup
      configure_path_normalization
      configure_file_locking_handling
    end

    def self.windows?
      Fontist::Utils::System.user_os == :windows
    end

    private

    def self.configure_temp_cleanup
      # Ensure temp directories are properly cleaned
      # Handle Windows file locking
    end

    def self.configure_path_normalization
      # Normalize all paths in tests
      # Use case-insensitive matching
    end

    def self.configure_file_locking_handling
      # Handle Windows file locking in tests
      # Ensure proper cleanup
    end
  end
end
```

---

## Implementation Status Tracker

### Phase 1: Platform Abstraction Layer

| Task | Status | File | Notes |
|------|--------|------|-------|
| Define Strategy base class | ⏸️ Pending | `lib/fontist/platform/strategy.rb` | Abstract interface for platform strategies |
| Implement WindowsStrategy | ⏸️ Pending | `lib/fontist/platform/windows_strategy.rb` | Windows-specific path and temp handling |
| Implement MacOSStrategy | ⏸️ Pending | `lib/fontist/platform/macos_strategy.rb` | macOS-specific behavior |
| Implement LinuxStrategy | ⏸️ Pending | `lib/fontist/platform/linux_strategy.rb` | Linux-specific behavior |
| Create PathAdapter utility | ⏸️ Pending | `lib/fontist/utils/path_adapter.rb` | Cross-platform path operations |
| Update existing code to use PathAdapter | ⏸️ Pending | Multiple files | Replace File.join with PathAdapter.join |

### Phase 2: File System Abstraction

| Task | Status | File | Notes |
|------|--------|------|-------|
| Create FilesystemAdapter | ⏸️ Pending | `lib/fontist/utils/filesystem_adapter.rb` | Platform-aware file operations |
| Implement Windows temp dir handling | ⏸️ Pending | `lib/fontist/utils/filesystem_adapter.rb` | Handle Windows temp conflicts |
| Implement Windows cleanup handling | ⏸️ Pending | `lib/fontist/utils/filesystem_adapter.rb` | Handle file locking issues |
| Update test helpers to use FilesystemAdapter | ⏸️ Pending | `spec/support/fresh_home.rb` | Use adapter for temp dir creation |
| Fix update_spec.rb temp dir issues | ⏸️ Pending | `spec/fontist/update_spec.rb` | Use FilesystemAdapter |

### Phase 3: Font API Abstraction

| Task | Status | File | Notes |
|------|--------|------|-------|
| Create FontMetadataAdapter | ⏸️ Pending | `lib/fontist/utils/font_metadata_adapter.rb` | Platform-aware metadata extraction |
| Implement Windows metadata extraction | ⏸️ Pending | `lib/fontist/utils/font_metadata_adapter.rb` | Handle Windows font API quirks |
| Implement Unix metadata extraction | ⏸️ Pending | `lib/fontist/utils/font_metadata_adapter.rb` | Use existing fontisan |
| Update FontMetadataExtractor to use adapter | ⏸️ Pending | `lib/fontist/import/font_metadata_extractor.rb` | Use adapter pattern |
| Fix font_spec.rb font API tests | ⏸️ Pending | `spec/fontist/font_spec.rb` | Use adapter in tests |

### Phase 4: Test Environment Improvements

| Task | Status | File | Notes |
|------|--------|------|-------|
| Create WindowsTestHelper | ⏸️ Pending | `spec/support/windows_test_helper.rb` | Windows-specific test setup |
| Implement Windows test setup | ⏸️ Pending | `spec/support/windows_test_helper.rb` | Configure temp cleanup, paths, locking |
| Update spec_helper.rb to call WindowsTestHelper | ⏸️ Pending | `spec/spec_helper.rb` | Setup for Windows tests |
| Fix cli_spec.rb path tests | ⏸️ Pending | `spec/fontist/cli_spec.rb` | Use case-insensitive matching |
| Fix system_index_spec.rb race condition | ⏸️ Pending | `spec/fontist/system_index_spec.rb` | Handle Windows timing |

### Phase 5: Archive Extraction Improvements

| Task | Status | File | Notes |
|------|--------|------|-------|
| Investigate Windows archive extraction failures | ⏸️ Pending | Research | Identify root cause |
| Create ArchiveAdapter | ⏸️ Pending | `lib/fontist/utils/archive_adapter.rb` | Platform-aware archive handling |
| Implement Windows-specific archive handling | ⏸️ Pending | `lib/fontist/utils/archive_adapter.rb` | Handle Windows archive formats |
| Update Extract class to use adapter | ⏸️ Pending | `lib/fontist/extract.rb` | Use adapter pattern |
| Fix archive extraction tests | ⏸️ Pending | `spec/fontist/extract_spec.rb` | Use adapter in tests |

---

## Implementation Order

### Priority 1: Foundation (Days 1-2)
1. Create platform strategy pattern (Phase 1)
2. Implement PathAdapter utility
3. Update critical path operations

**Expected Impact:** Resolves ~20 path handling failures

### Priority 2: File System (Days 3-4)
1. Create FilesystemAdapter
2. Implement Windows temp dir handling
3. Update test helpers

**Expected Impact:** Resolves ~15 file system failures

### Priority 3: Font APIs (Days 5-6)
1. Create FontMetadataAdapter
2. Implement Windows metadata extraction
3. Update font extraction code

**Expected Impact:** Resolves ~12 font API failures

### Priority 4: Test Environment (Days 7-8)
1. Create WindowsTestHelper
2. Update spec_helper.rb
3. Fix specific test failures

**Expected Impact:** Resolves ~10 test environment failures

### Priority 5: Archive Extraction (Days 9-10)
1. Investigate archive issues
2. Create ArchiveAdapter
3. Update extraction code

**Expected Impact:** Resolves ~7 archive extraction failures

---

## Testing Strategy

### Unit Tests
- Each adapter class has dedicated spec
- Mock platform strategy for cross-platform testing
- Test both Windows and Unix paths

### Integration Tests
- Test with actual Windows environment
- Verify temp directory cleanup
- Verify path normalization

### Regression Tests
- Ensure Unix platforms continue to pass
- No performance degradation
- Backward compatibility maintained

---

## Success Criteria

### Functional
- ✅ All 64 Windows test failures resolved
- ✅ 100% pass rate on Windows
- ✅ Unix platforms remain at 100%

### Architectural
- ✅ Platform abstraction layer in place
- ✅ All platform-specific code encapsulated
- ✅ No hardcoded Windows checks in business logic
- ✅ Extensible to new platforms

### Quality
- ✅ All new code has specs
- ✅ RuboCop clean
- ✅ No performance regression
- ✅ Clear separation of concerns

---

## Risk Mitigation

### Risk 1: Breaking Unix Platforms
**Mitigation:**
- Extensive Unix platform testing
- Feature flags for new adapters
- Gradual rollout

### Risk 2: Performance Degradation
**Mitigation:**
- Benchmark before/after
- Profile critical paths
- Optimize hot paths

### Risk 3: Increased Complexity
**Mitigation:**
- Clear documentation
- Simple adapter interfaces
- Minimal changes to existing code

---

## Timeline Estimate

| Phase | Duration | Dependencies |
|-------|----------|--------------|
| Phase 1: Platform Abstraction | 2 days | None |
| Phase 2: File System | 2 days | Phase 1 |
| Phase 3: Font APIs | 2 days | Phase 1 |
| Phase 4: Test Environment | 2 days | Phases 1-3 |
| Phase 5: Archive Extraction | 2 days | Phase 1 |

**Total:** 10 days for complete Windows platform fix

---

## Next Steps

1. **Review and approve** this architectural plan
2. **Create feature branch** for Windows fixes
3. **Implement Phase 1** (Platform Abstraction Layer)
4. **Test on Windows** CI/CD
5. **Iterate** through remaining phases
6. **Achieve 100% Windows pass rate**

---

## Related Documentation

- [`WINDOWS_SPECIFIC_ISSUES.md`](WINDOWS_SPECIFIC_ISSUES.md) - Detailed failure analysis
- [`CROSS_PLATFORM_TEST_FIXES_FINAL_REPORT.md`](CROSS_PLATFORM_TEST_FIXES_FINAL_REPORT.md) - Overall cross-platform effort
- [`CROSS_PLATFORM_SUCCESS_SUMMARY.md`](CROSS_PLATFORM_SUCCESS_SUMMARY.md) - Unix platform success

---

**Status:** ⏸️ Planning Complete, Awaiting Approval
**Last Updated:** 2026-01-08
**Owner:** Fontist Team