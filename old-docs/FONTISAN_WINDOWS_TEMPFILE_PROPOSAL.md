# Proposal: Fix Windows Tempfile GC Issue in Fontisan

## Executive Summary

Fontisan currently has a critical issue on Windows where tempfiles created during `TrueTypeFont#to_file` operations are prematurely garbage collected, causing `Errno::EACCES` (Permission denied) errors. This issue only manifests during parallel/concurrent font processing.

This proposal outlines the root cause and provides a solution that will make fontisan fully compatible with Windows while maintaining cross-platform compatibility.

## Problem Description

### Symptoms

When fontisan is used in parallel/concurrent processing on Windows (e.g., multiple threads processing font collections), the following error occurs:

```
tempfile.rb:265:in `unlink': Permission denied @ apply2files - D:/a/_temp/font20251221-8692-jkgx0h.ttf (Errno::EACCES)
  from fontisan/utilities/checksum_calculator.rb:98:in `&'
  from fontisan/utilities/checksum_calculator.rb:98:in `calculate_checksum_from_io'
  from fontisan/utilities/checksum_calculator.rb:38:in `block in calculate_file_checksum'
  from fontisan/true_type_font.rb:583:in `update_checksum_adjustment_in_file'
  from fontisan/true_type_font.rb:264:in `to_file'
```

### Root Cause Analysis

The issue stems from how Ruby's `Tempfile` class interacts with Windows file locking:

1. **Tempfile Behavior**: Ruby's `Tempfile` automatically deletes the temporary file when the Tempfile object is garbage collected
2. **Windows File Locking**: Windows prevents deletion of files that were recently accessed, even after the file handle is closed
3. **GC Timing**: In multi-threaded environments, GC can run at any time, including while another thread is still processing the font
4. **Race Condition**: Tempfile goes out of scope → GC runs → tries to delete file → Windows blocks deletion → EACCES error

### Current Code Flow

```ruby
# In ChecksumCalculator#calculate_checksum_from_io
def calculate_checksum_from_io(io)
  tmpfile = Tempfile.new(["font", ".ttf"])
  tmpfile.binmode
  IO.copy_stream(io, tmpfile)
  tmpfile.close
  
  checksum = calculate_file_checksum(tmpfile.path)
  # tmpfile goes out of scope here
  # GC may run and try to delete it
  checksum
end
```

The `tmpfile` object is not kept alive beyond the method scope, making it eligible for GC immediately after the method returns. On Windows, if GC runs while the file is still locked by the OS, deletion fails.

## Proposed Solution

### Option 1: Keep Tempfile Reference (Recommended)

Modify the code to keep tempfile references alive until they're no longer needed:

```ruby
# In ChecksumCalculator class
def calculate_checksum_from_io(io)
  tmpfile = Tempfile.new(["font", ".ttf"])
  tmpfile.binmode
  IO.copy_stream(io, tmpfile)
  tmpfile.close
  
  checksum = calculate_file_checksum(tmpfile.path)
  
  # Keep tempfile alive to prevent premature GC on Windows
  # It will be cleaned up when this method's caller releases it
  [checksum, tmpfile]
end

# Caller adjusts to handle tuple
def update_checksum_adjustment_in_file(file_path)
  File.open(file_path, "rb+") do |io|
    checksum, tmpfile = calculate_checksum_from_io(io)
    # Use checksum...
    # tmpfile will be GC'd when this method exits
  end
end
```

**Pros:**
- Simple fix with minimal code changes
- Follows Ruby best practices for Tempfile usage
- Cross-platform compatible
- No performance impact

**Cons:**
- Requires API changes to methods that use tempfiles
- Callers need to be updated

### Option 2: Use Instance Variable Storage

Store tempfiles in an instance variable to keep them alive:

```ruby
class TrueTypeFont
  def initialize(...)
    # ...
    @temp_files = []
  end
  
  def to_file(path)
    # ... existing code ...
    
    # Store tempfile to keep it alive
    tmpfile = create_temp_file_for_checksum
    @temp_files << tmpfile
    
    # ... use tmpfile ...
  end
  
  # Tempfiles will be cleaned up when TrueTypeFont instance is GC'd
end
```

**Pros:**
- No API changes required
- Automatic cleanup when font object is destroyed
- Simple to implement

**Cons:**
- Holds tempfiles longer than necessary
- Slight memory overhead

### Option 3: Explicit Cleanup Method

Add explicit tempfile management:

```ruby
class ChecksumCalculator
  def initialize
    @tempfiles = []
  end
  
  def calculate_checksum_from_io(io)
    tmpfile = Tempfile.new(["font", ".ttf"])
    tmpfile.binmode
    IO.copy_stream(io, tmpfile)
    tmpfile.close
    
    @tempfiles << tmpfile  # Keep alive
    
    calculate_file_checksum(tmpfile.path)
  end
  
  def cleanup
    @tempfiles.clear  # Allow GC
  end
end

# Usage
calculator = ChecksumCalculator.new
checksum = calculator.calculate_checksum_from_io(io)
calculator.cleanup  # Explicit cleanup
```

**Pros:**
- Explicit control over lifecycle
- No API breaking changes
- Clear intent

**Cons:**
- Requires callers to remember cleanup
- More complex to use correctly

## Recommended Implementation

**Option 1 (Keep Tempfile Reference)** is the recommended approach because:

1. **Ruby Best Practice**: Explicitly keeping tempfile references is the documented best practice
2. **Clear Lifecycle**: Tempfile lifetime is explicit and bounded
3. **No Hidden State**: No instance variables holding onto resources
4. **Cross-Platform**: Works identically on all operating systems

## Implementation Details

### Files to Modify

1. **`lib/fontisan/utilities/checksum_calculator.rb`**
   - Modify `calculate_checksum_from_io` to return tuple `[checksum, tmpfile]`
   - Update documentation

2. **`lib/fontisan/true_type_font.rb`**
   - Update `update_checksum_adjustment_in_file` to handle tuple
   - Keep tempfile reference until method completes

### Code Changes

```ruby
# lib/fontisan/utilities/checksum_calculator.rb
module Fontisan
  module Utilities
    class ChecksumCalculator
      # Calculate checksum from an IO object
      # Returns: [Integer, Tempfile] - checksum and tempfile (kept alive for Windows compatibility)
      def self.calculate_checksum_from_io(io)
        tmpfile = Tempfile.new(["font", ".ttf"])
        tmpfile.binmode
        IO.copy_stream(io, tmpfile)
        tmpfile.close
        
        checksum = calculate_file_checksum(tmpfile.path)
        
        # Return both checksum and tempfile to keep it alive
        # This prevents Windows GC issues where tempfiles are deleted while in use
        [checksum, tmpfile]
      end
      
      # For backward compatibility, provide a method that handles cleanup
      def self.calculate_checksum_from_io_auto_cleanup(io)
        checksum, _tmpfile = calculate_checksum_from_io(io)
        # tempfile will be GC'd when it goes out of scope here
        checksum
      end
    end
  end
end

# lib/fontisan/true_type_font.rb
module Fontisan
  class TrueTypeFont
    def update_checksum_adjustment_in_file(file_path)
      File.open(file_path, "rb+") do |io|
        # Get checksum and keep tempfile alive
        checksum, tmpfile = Utilities::ChecksumCalculator.calculate_checksum_from_io(io)
        
        # ... use checksum to update file ...
        
        # tmpfile will be GC'd when this method exits, which is safe
        # because we're done using the file by then
      end
    end
  end
end
```

### Testing Requirements

1. **Windows-Specific Tests**
   - Parallel processing test with multiple threads
   - Stress test with many concurrent font operations
   - GC.start called explicitly to trigger cleanup

2. **Cross-Platform Tests**
   - Existing tests should continue to pass
   - No regression on macOS/Linux

3. **Example Test**

```ruby
RSpec.describe "Windows Tempfile Handling" do
  it "handles parallel font processing without EACCES errors" do
    font_paths = Dir.glob("spec/fixtures/*.ttc")
    
    threads = font_paths.map do |path|
      Thread.new do
        collection = Fontisan::TrueTypeCollection.from_file(path)
        collection.num_fonts.times do |i|
          font = collection.font(i, File.open(path, "rb"))
          
          tmpfile = Tempfile.new(["test", ".ttf"])
          font.to_file(tmpfile.path)
          tmpfile.close
          
          # Force GC to try to clean up tempfiles
          GC.start
        end
      end
    end
    
    expect { threads.each(&:join) }.not_to raise_error
  end
end
```

## Migration Path

### For Fontisan Maintainers

1. **Phase 1**: Implement Option 1 with backward compatibility method
2. **Phase 2**: Update internal uses to new API
3. **Phase 3**: Deprecate old API
4. **Phase 4**: Remove old API in next major version

### For Fontisan Users (like Fontist)

```ruby
# Old code (will break on Windows with parallel processing)
checksum = ChecksumCalculator.calculate_checksum_from_io(io)

# New code (works on all platforms)
checksum, tmpfile = ChecksumCalculator.calculate_checksum_from_io(io)
# Use checksum...
# tmpfile kept alive automatically
```

## Benefits

1. **Windows Compatibility**: Eliminates EACCES errors completely
2. **Cross-Platform**: Works identically on all OSes
3. **Ruby Best Practice**: Follows documented Tempfile usage patterns
4. **Performance**: No performance impact
5. **Reliability**: Eliminates race conditions in concurrent usage

## Risks & Mitigation

### Risk: API Breaking Change
**Mitigation**: Provide backward compatibility method for transition period

### Risk: Memory Impact
**Mitigation**: Tempfiles are still cleaned up automatically, just at the right time

### Risk: Increased Complexity
**Mitigation**: Clear documentation and examples provided

## Timeline Estimate

- **Research & Design**: Already done (this proposal)
- **Implementation**: 1-2 days
- **Testing**: 2-3 days (including Windows CI setup)
- **Documentation**: 1 day
- **Review & Release**: 1 week

Total: ~2 weeks for complete implementation and release

## References

1. [Ruby Tempfile Documentation](https://ruby-doc.org/stdlib-3.1.0/libdoc/tempfile/rdoc/Tempfile.html)
2. [Ruby Tempfile Best Practices](https://www.honeybadger.io/blog/ruby-tempfile/)
3. [Windows File Locking](https://learn.microsoft.com/en-us/windows/win32/fileio/file-caching)
4. [Fontist Issue Tracker](https://github.com/fontist/fontist) - Workaround implemented until fontisan is fixed

## Contact

For questions or discussion about this proposal:
- GitHub Issues: https://github.com/fontist/fontisan/issues
- Email: [maintainer contact]

---

**Status**: Proposal  
**Version**: 1.0  
**Date**: 2025-12-22  
**Author**: Fontist Team
