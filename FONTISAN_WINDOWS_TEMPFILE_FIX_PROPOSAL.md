# Fontisan Windows Tempfile GC Fix Proposal

**For:** Fontisan Gem Maintainers  
**From:** Fontist Team  
**Date:** 2026-01-08  
**Priority:** High (breaking Windows tests)  

## Executive Summary

Fontisan 0.2.7 has a critical Windows-specific bug where internal tempfiles in `ChecksumCalculator` are prematurely garbage collected, causing `Errno::EACCES` errors. This breaks font collection processing on Windows.

## Problem Details

### Error Stack Trace

```
D:/a/_temp/rubyinstaller-3.1.7-1-x64/lib/ruby/3.1.0/tempfile.rb:265:in `unlink': Permission denied @ apply2files - D:/a/_temp/font20260108-7572-atu1k2.ttf (Errno::EACCES)
  from D:/a/_temp/rubyinstaller-3.1.7-1-x64/lib/ruby/3.1.0/tempfile.rb:265:in `call'
  from D:/a/fontist/fontist/vendor/bundle/ruby/3.1.0/gems/fontisan-0.2.7/lib/fontisan/utilities/checksum_calculator.rb:99:in `+'
  from D:/a/fontist/fontist/vendor/bundle/ruby/3.1.0/gems/fontisan-0.2.7/lib/fontisan/utilities/checksum_calculator.rb:99:in `calculate_checksum_from_io'
```

### Root Cause

1. **Location**: `lib/fontisan/utilities/checksum_calculator.rb:99` 
2. **Method**: `calculate_checksum_from_io`
3. **Issue**: Tempfile created internally goes out of scope before Windows releases file lock
4. **Result**: GC finalizer tries to delete file → Windows denies permission → crash

### Affected Workflow

```
TrueTypeCollection.font(index, io)
  └─> TrueTypeFont.to_file(path)
      └─> update_checksum_adjustment_in_file(path)
          └─> ChecksumCalculator.calculate_checksum_from_io(io)
              └─> Creates tempfile
              └─> Tempfile goes out of scope
              └─> GC runs → tries to delete → EACCES
```

## Proposed Solution

### Approach: Return Tempfile to Caller

Modify `ChecksumCalculator#calculate_checksum_from_io` to return both the checksum AND the tempfile, allowing the caller to control tempfile lifecycle.

### Code Changes

#### File: `lib/fontisan/utilities/checksum_calculator.rb`

```ruby
# BEFORE (current - fails on Windows)
def calculate_checksum_from_io(io)
  tmpfile = Tempfile.new(["font", ".ttf"])
  tmpfile.binmode
  IO.copy_stream(io, tmpfile)
  tmpfile.close
  
  checksum = calculate_file_checksum(tmpfile.path)
  checksum  # tmpfile goes out of scope → GC may delete it
end

# AFTER (proposed - works on Windows)
def calculate_checksum_from_io(io)
  tmpfile = Tempfile.new(["font", ".ttf"])
  tmpfile.binmode
  IO copy_stream(io, tmpfile)
  tmpfile.close
  
  checksum = calculate_file_checksum(tmpfile.path)
  
  # Return both checksum and tempfile
  # Caller must keep tempfile alive to prevent Windows GC issues
  [checksum, tmpfile]
end

# For backward compatibility (optional)
def calculate_checksum_from_io_auto_cleanup(io)
  checksum, _tmpfile = calculate_checksum_from_io(io)
  checksum
  # _tmpfile will be GC'd here, may fail on Windows but maintains old API
end
```

#### File: `lib/fontisan/true_type_font.rb`

```ruby
# BEFORE
def update_checksum_adjustment_in_file(file_path)
  File.open(file_path, "rb+") do |io|
    checksum = Utilities::ChecksumCalculator.calculate_checksum_from_io(io)
    # ... use checksum ...
  end
end

# AFTER
def update_checksum_adjustment_in_file(file_path)
  File.open(file_path, "rb+") do |io|
    # Keep tempfile alive during entire operation
    checksum, tmpfile = Utilities::ChecksumCalculator.calculate_checksum_from_io(io)
    # ... use checksum ...
    # tmpfile safely deleted when method exits
  end
end
```

## Why This Works

1. **Controlled Lifecycle**: Tempfile stays alive until method completes
2. **Windows Safe**: File locks released before GC tries deletion
3. **Ruby Best Practice**: Explicit tempfile management is recommended approach
4. **Cross-Platform**: Works identically on all OSes

## Testing Requirements

### Windows-Specific Test

```ruby
RSpec.describe "Windows Tempfile GC", :windows do
  it "processes TTC collection without EACCES errors" do
    collection = Fontisan::TrueTypeCollection.from_file("test.ttc")
    
    # Process all fonts
    collection.num_fonts.times do |i|
      File.open("test.ttc", "rb") do |io|
        font = collection.font(i, io)
        font.to_file("output_#{i}.ttf")
      end
      
      # Force GC to trigger cleanup
      GC.start
    end
    
    # Should complete without errors
  end
end
```

### Regression Tests

- Existing tests should pass unchanged
- No performance degradation
- macOS/Linux behavior unchanged

## Alternative Solutions Considered

### Alternative 1: Platform-Specific GC.disable

**Rejected**: Disabling GC is a sledgehammer approach and impacts overall performance

###

 Alternative 2: Instance Variable Storage

**Rejected**: Hidden state makes lifecycle unclear and can cause memory leaks

### Alternative 3: unlink_on_close = false

**Rejected**: Leaves cleanup burden on caller and can leak temp files if not handled properly

## Implementation Checklist

- [ ] Update `ChecksumCalculator#calculate_checksum_from_io` to return tuple
- [ ] Update `TrueTypeFont#update_checksum_adjustment_in_file` to handle tuple
- [ ] Add backward compatibility method (optional)
- [ ] Update documentation with new API
- [ ] Add Windows-specific regression tests
- [ ] Verify all existing tests pass
- [ ] Update CHANGELOG with breaking change note
- [ ] Release as minor version bump (e.g., 0.3.0)

## Impact Assessment

### Breaking Changes

- `calculate_checksum_from_io` now returns `[checksum, tmpfile]` instead of just `checksum`
- Callers must update to destructure the return value

### Migration

```ruby
# Old code
checksum = ChecksumCalculator.calculate_checksum_from_io(io)

# New code
checksum, _tmpfile = ChecksumCalculator.calculate_checksum_from_io(io)
# Or just use first element
checksum = ChecksumCalculator.calculate_checksum_from_io(io).first
```

## References

- [Ruby Tempfile Documentation](https://ruby-doc.org/stdlib-3.1.0/libdoc/tempfile/rdoc/Tempfile.html)
- [Windows File Locking Behavior](https://learn.microsoft.com/en-us/windows/win32/fileio/file-caching)
- [Ruby GC Documentation](https://ruby-doc.org/core-3.1.0/GC.html)
- [GitHub Linguist Similar Fix](https://github.com/github-linguist/linguist/commit/a595c22006166d1198dc0588fd47807f5db8476a)

## Timeline

- **Implementation**: 1-2 days
- **Testing**: 1-2 days (Windows CI required)
- **Review**: 1-3 days
- **Release**: Within 1 week

## Support

Fontist team is ready to:
- Test pre-release versions
- Provide Windows CI infrastructure if needed
- Validate the fix resolves our test suite failures

## Contact

- **Repository**: https://github.com/fontist/fontist
- **Issue**: [To be created after proposal review]
- **Priority**: High - blocking our Windows CI

---

**This proposal based on existing document**: `old-docs/FONTISAN_WINDOWS_TEMPFILE_PROPOSAL.md`
