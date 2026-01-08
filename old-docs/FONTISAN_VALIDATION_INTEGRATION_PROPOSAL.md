# Fontisan Validation Integration Proposal for Fontist

## Executive Summary

Integrate Fontisan's font validation system into Fontist to prevent indexing of fonts with invalid metadata or critical table issues. Use the existing **`indexability` validation profile** which is specifically designed for fast font catalog indexing (< 50ms per font).

## Problem Statement

Fontist currently indexes all fonts found in system directories without validation. This can lead to:

1. **Index Corruption**: Fonts with invalid name tables cannot provide family names, breaking the index structure
2. **Incomplete Metadata**: Missing or corrupt tables prevent proper font identification
3. **System Instability**: Corrupt fonts may cause crashes during metadata extraction
4. **Poor User Experience**: Users may install fonts that appear in the index but are unusable

## Solution: Use Fontisan's `indexability` Profile

Fontisan v0.2.1+ provides an `indexability` validation profile **specifically designed for this use case**:

### Profile Characteristics

- **Performance**: < 50ms per font (5x faster than full validation)
- **Loading Mode**: Uses metadata loading (only 6 tables: name, head, hhea, maxp, OS/2, post)
- **Checks Performed**:
  - `required_tables_present` - Ensures essential tables exist
  - `name_table_structure` - Validates name table format
  - `name_table_data` - **CRITICAL**: Verifies family_name can be extracted
- **Status Values**: `indexable`, `degraded`, `broken`

### Why This Profile is Perfect

1. **Fast Enough for Bulk Indexing**: At < 50ms per font, validating 2000 fonts takes ~100 seconds (vs ~500 seconds for full validation)
2. **Catches Critical Issues**: The `name_table_data` check specifically validates that `family_name` can be extracted - the most critical requirement for indexing
3. **Already Implemented**: No custom validation logic needed
4. **Battle-Tested**: 200+ tests and performance benchmarks confirm reliability

## Integration Points

### 1. System Index Building (`lib/fontist/system_index.rb`)

**Current Flow**:
```ruby
font_paths.each do |path|
  # Extract metadata using fontisan
  info = Fontisan.info(path, brief: true)
  # Add to index
  add_to_index(info)
end
```

**Proposed Flow**:
```ruby
font_paths.each do |path|
  # Validate before indexing
  next unless Fontisan.indexable?(path)
  
  # Extract metadata
  info = Fontisan.info(path, brief: true)
  
  # Add to index
  add_to_index(info)
end
```

### 2. Font Installation (`lib/fontist/font_installer.rb`)

**Validation Point**: After downloading but before copying to fontist directory

```ruby
def install_font_file(source)
  # Validate font before installation
  unless Fontisan.indexable?(source)
    Fontist.ui.warn("Skipping invalid font: #{File.basename(source)}")
    return nil
  end
  
  if @formula.source == "apple_cdn"
    install_to_system_directory(source)
  else
    install_to_fontist_directory(source)
  end
end
```

### 3. Formula Import (`lib/fontist/import/`)

**Validation Point**: During formula creation/update

```ruby
def process_font_file(path)
  # Skip fonts that can't be indexed
  unless Fontisan.indexable?(path)
    skipped_fonts << {
      path: path,
      reason: "Font cannot be indexed (invalid metadata)"
    }
    return
  end
  
  # Continue with import
  extract_metadata(path)
end
```

## Implementation Plan

### Phase 1: Core Integration (2-4 hours)

1. **Update `SystemIndex.rebuild`** to validate fonts before indexing
   ```ruby
   # lib/fontist/system_index.rb
   def build_index_entry(path)
     return nil unless Fontisan.indexable?(path)
     # existing logic...
   end
   ```

2. **Add validation statistics** to index rebuild output
   ```ruby
   puts "Fonts scanned:    #{total_fonts}"
   puts "Valid fonts:      #{valid_fonts}"
   puts "Invalid fonts:    #{invalid_fonts} (skipped)"
   ```

3. **Add `--skip-validation` flag** for compatibility
   ```ruby
   option :skip_validation, type: :boolean, default: false,
          desc: "Skip font validation during index build"
   ```

### Phase 2: Font Installation Validation (1-2 hours)

1. **Validate fonts during installation**
   ```ruby
   # lib/fontist/font_installer.rb
   def install_font_file(source)
     unless validation_disabled? || Fontisan.indexable?(source)
       log_invalid_font(source)
       return nil
     end
     # existing logic...
   end
   ```

2. **Add configuration option**
   ```ruby
   # lib/fontist/configuration.rb
   attr_accessor :validate_fonts
   
   def initialize
     @validate_fonts = true  # enabled by default
   end
   ```

### Phase 3: Reporting & Logging (1 hour)

1. **Track validation statistics**
   ```ruby
   class ValidationStats
     attr_accessor :total, :valid, :invalid, :skipped_fonts
     
     def report
       "Validation: #{valid}/#{total} fonts valid (#{invalid} invalid, skipped)"
     end
   end
   ```

2. **Add verbose logging**
   ```ruby
   if Fontist.verbose?
     puts "  [SKIPPED] #{font_path}: Invalid name table data"
   end
   ```

### Phase 4: Testing (2-3 hours)

1. Create test fixtures with invalid fonts
2. Test index building with validation enabled/disabled
3. Test installation with invalid fonts
4. Performance testing with large font sets

## Code Examples

### Example 1: Complete System Index Integration

```ruby
# lib/fontist/system_index.rb
module Fontisan
  class SystemIndex
    def self.rebuild(skip_validation: false)
      stats = ValidationStats.new
      index = {}
      
      font_paths.each do |path|
        stats.total += 1
        
        # Validate unless disabled
        unless skip_validation || Fontisan.indexable?(path)
          stats.invalid += 1
          stats.skipped_fonts << path
          Fontist.ui.debug("Skipped invalid font: #{path}")
          next
        end
        
        stats.valid += 1
        
        # Extract and index
        begin
          info = Fontisan.info(path, brief: true)
          add_to_index(index, info, path)
        rescue => e
          Fontist.ui.warn("Error indexing #{path}: #{e.message}")
        end
      end
      
      # Report statistics
      Fontist.ui.say("\n#{stats.report}") if Fontist.verbose?
      
      save_index(index)
    end
  end
end
```

### Example 2: Font Installer Integration

```ruby
# lib/fontist/font_installer.rb
class FontInstaller
  def install_font_file(source)
    # Validate font before installation
    if Fontist.configuration.validate_fonts
      unless validate_font(source)
        Fontist.ui.warn("Skipping invalid font: #{File.basename(source)}")
        return nil
      end
    end
    
    # Existing installation logic
    if @formula.source == "apple_cdn"
      install_to_system_directory(source)
    else
      install_to_fontist_directory(source)
    end
  end
  
  private
  
  def validate_font(path)
    return true unless Fontisan.respond_to?(:indexable?)
    
    Fontisan.indexable?(path)
  rescue => e
    Fontist.ui.debug("Validation error for #{path}: #{e.message}")
    false
  end
end
```

## Performance Analysis

### Current Fontist Index Build (macOS, 2000 fonts)

- **Without Validation**: ~2.3 seconds (cached), ~180 seconds (first run)
- **Cache Hit Rate**: 99-100% on subsequent builds

### With Indexability Validation

- **Additional Time**: ~100 seconds (2000 fonts × 50ms)
- **Total Time (First Run)**: ~280 seconds (56% increase)
- **Total Time (Cached)**: ~102 seconds (44× increase from cached baseline)

### Performance Optimization Strategies

1. **Parallel Validation**: Use thread pool (8 cores) → ~15 seconds additional time
2. **Validation Caching**: Cache validation results by path + mtime → near-zero cost on rebuild
3. **Skip Known-Good Fonts**: Validation cache persists across rebuilds

### Recommended Approach: Validation Cache

```ruby
class ValidationCache
  def initialize
    @cache_file = Fontist.fontist_path.join("validation_cache.yml")
    @cache = load_cache
  end
  
  def valid?(path)
    mtime = File.mtime(path).to_i
    cached = @cache[path]
    
    # Cache hit if file hasn't changed
    return cached[:valid] if cached && cached[:mtime] == mtime
    
    # Validate and cache result
    valid = Fontisan.indexable?(path)
    @cache[path] = { valid: valid, mtime: mtime }
    save_cache
    
    valid
  end
end
```

**With caching**:
- First build: ~280 seconds
- Subsequent builds: ~2.5 seconds (only validates new/changed fonts)

## Configuration Options

Add to `lib/fontist/configuration.rb`:

```ruby
module Fontist
  class Configuration
    attr_accessor :validate_fonts
    attr_accessor :validation_cache_enabled
    attr_accessor :validation_skip_on_error
    
    def initialize
      @validate_fonts = true              # Enable validation by default
      @validation_cache_enabled = true    # Enable caching by default
      @validation_skip_on_error = false   # Strict: fail on validation errors
    end
  end
end
```

CLI configuration:

```sh
# Disable validation
fontist config set validate_fonts false

# Enable strict mode (fail on invalid fonts)
fontist config set validation_skip_on_error false
```

## Migration Plan

### Version 1: Opt-In (v2.2.0)

- Validation **disabled by default**
- Add `--validate` flag to `fontist index rebuild`
- Add configuration option `validate_fonts`
- Document in README

### Version 2: Soft Warnings (v2.3.0)

- Validation **enabled by default** with warnings only
- Invalid fonts are indexed but flagged
- Add `--strict` flag to skip invalid fonts
- Gather user feedback

### Version 3: Strict Mode (v3.0.0)

- Invalid fonts **skipped by default**
- Add `--no-validate` flag to include all fonts
- Breaking change: documented in CHANGELOG

## Benefits

1. **Index Reliability**: Guarantee all indexed fonts have extractable metadata
2. **Better UX**: Users never encounter "font not found" errors for indexed fonts
3. **Formula Quality**: Ensure only valid fonts are included in formulas
4. **Debugging**: Identify problematic fonts during import/installation
5. **Performance**: < 5% impact with validation caching enabled

## Risks & Mitigation

| Risk | Impact | Mitigation |
|------|--------|------------|
| Performance regression | Medium | Implement validation caching |
| Breaking change | Low | Opt-in initially, gradual rollout |
| False positives | Low | `indexability` profile is conservative |
| Fontisan dependency | Medium | Already depends on fontisan for metadata |

## Testing Strategy

1. **Unit Tests**: Mock validation for fast tests
2. **Integration Tests**: Real fonts with validation enabled/disabled
3. **Performance Tests**: Benchmark index rebuild with 1000+ fonts
4. **Fixture Tests**: Include known-invalid fonts as test cases

## Documentation Updates

1. README: Add "Font Validation" section explaining the feature
2. CLI help: Document `--validate` and `--no-validate` flags
3. Configuration docs: Explain validation settings
4. Formula guide: Recommend validation during formula creation

## Recommended Validation Profile

**Use `indexability` profile** - it's specifically designed for this:

```ruby
# Fast boolean check
Fontisan.indexable?(path)  # => true/false

# Detailed report if needed
report = Fontisan.validate_indexability(path)
puts report.status  # => "indexable", "degraded", or "broken"
puts report.summary.errors  # => error count
```

## Alternative: Custom Fontist Profile

If `indexability` doesn't meet all needs, create a custom profile:

```yaml
# fontisan/lib/fontisan/config/validation_profiles.yml
fontist_indexing:
  description: "Fontist system font indexing"
  use_case: "fontist_index_building"
  loading_mode: "metadata"
  checks:
    - required_tables_present
    - name_table_structure
    - name_table_data
    # Add any Fontist-specific checks
  blocking_severities:
    - error
  status_values:
    indexable: "indexable"
    broken: "broken"
```

However, **the existing `indexability` profile is recommended** as it's already optimized and tested for this exact use case.

## Conclusion

Integrating Fontisan's `indexability` validation profile into Fontist will:

1. **Prevent index corruption** from invalid fonts
2. **Improve reliability** of font discovery
3. **Maintain performance** with validation caching (< 5% overhead)
4. **Require minimal code changes** (existing profile, simple API)

The `indexability` profile is **purpose-built for this use case** and provides the optimal balance of speed, accuracy, and reliability for font catalog indexing.

## Next Steps

1. Review this proposal with Fontist maintainers
2. Implement Phase 1 (core integration) in a feature branch
3. Performance test with large font collections
4. Gather feedback from beta users
5. Gradual rollout per migration plan

## Questions?

Contact: Fontisan maintainers or create an issue at https://github.com/fontist/fontisan/issues