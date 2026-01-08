# Fontisan Validation Integration

## Overview

Fontist now uses Fontisan's `indexability` validation profile to detect and gracefully handle corrupt or invalid fonts during indexing operations. This prevents indexing failures and provides clear feedback about problematic fonts.

## What is Indexability Validation?

The `indexability` profile is a fast validation mode (<50ms per font) that checks essential font metadata required for indexing:

- Required tables presence (name, head, maxp, hhea)
- Name table version and family name
- PostScript name validity  
- Head table magic number and units per em
- Maxp table glyph count and metrics

## Integration Points

### 1. FontFile.from_path

All fonts loaded through [`FontFile.from_path`](../lib/fontist/font_file.rb) are validated before metadata extraction:

```ruby
font_file = Fontist::FontFile.from_path("/path/to/font.ttf")
# Raises Fontist::Errors::FontFileError if validation fails
```

**Validation happens automatically** - no code changes needed.

### 2. CollectionFile.from_path

TrueType Collections (`.ttc` files) are also validated:

```ruby
Fontist::CollectionFile.from_path("/path/to/fonts.ttc") do |collection|
  # Only valid collections will reach this block
end
# Raises Fontist::Errors::FontFileError if validation fails
```

### 3. System Font Indexing

During system font indexing, validation failures are tracked separately:

```ruby
# Validation failures are logged but don't stop indexing
stats = Fontist::IndexStats.new
index.rebuild(verbose: true, stats: stats)

# Check statistics
stats.validation_failures  # => 2
stats.errors              # => 5 (includes validation failures)
```

## Error Handling

### Error Messages

When a font fails validation, a descriptive error is raised:

```ruby
begin
  FontFile.from_path("corrupt.ttf")
rescue Fontist::Errors::FontFileError => e
  puts e.message
  # => "Font file failed indexability validation: table_validation: Table 'name' failed validation"
end
```

### During Indexing

Invalid fonts are skipped with debug-level logging:

```
Skipping corrupt/invalid font: Rupali_0.72.ttf
Validation failed: Font file failed indexability validation: table_validation: Table 'name' failed validation
```

### Statistics

The `IndexStats` class tracks validation failures separately:

```ruby
stats.summary
# => {
#   total_fonts: 1000,
#   parsed_fonts: 950,
#   cached_fonts: 45,
#   errors: 5,
#   validation_failures: 2,  # NEW
#   cache_hit_rate: "95%",
#   avg_time_per_font: 0.0234
# }
```

## Performance Impact

Validation adds minimal overhead:

- **Single font**: ~50ms additional time
- **System index (1000 fonts)**: ~50 seconds additional time
- **With caching**: No additional time on subsequent runs

The validation uses Fontisan's metadata-only loading mode, which is already optimized for indexing.

## Examples

### Example 1: Detecting Corrupt Fonts

```ruby
require 'fontist'

begin
  font = Fontist::FontFile.from_path("suspicious.ttf")
  puts "Font is valid: #{font.family}"
rescue Fontist::Errors::FontFileError => e
  if e.message.include?("indexability validation")
    puts "Font is corrupt or invalid"
    puts "Details: #{e.message}"
  else
    puts "Other error: #{e.message}"
  end
end
```

### Example 2: Building Index with Validation Stats

```ruby
require 'fontist'

# Rebuild system index with verbose output
stats = Fontist::IndexStats.new
Fontist::SystemIndex.system_index.rebuild(verbose: true, stats: stats)

# Check results
puts "Total fonts scanned: #{stats.total_fonts}"
puts "Successfully indexed: #{stats.parsed_fonts}"
puts "Validation failures: #{stats.validation_failures}"

if stats.validation_failures > 0
  puts "\nSome fonts were skipped due to validation failures."
  puts "Check debug logs for details."
end
```

### Example 3: Handling Collections

```ruby
require 'fontist'

# TTC files are validated before extraction
begin
  Fontist::CollectionFile.from_path("fonts.ttc") do |collection|
    collection.each do |font|
      puts "Font: #{font.family} - #{font.subfamily}"
    end
  end
rescue Fontist::Errors::FontFileError => e
  puts "Collection is invalid: #{e.message}"
end
```

## Testing

### Running Validation Tests

```bash
# Run validation-specific tests
bundle exec rspec spec/fontist/font_file_validation_spec.rb

# Run all tests
bundle exec rspec
```

### Test Coverage

- Valid font acceptance
- Corrupt font rejection
- Validation error messages
- Statistics tracking

## Implementation Details

### Files Modified

1. [`lib/fontist/font_file.rb`](../lib/fontist/font_file.rb)
   - Added validation before font loading
   - Validates using `Fontisan.validate(path, profile: :indexability)`

2. [`lib/fontist/collection_file.rb`](../lib/fontist/collection_file.rb)
   - Added validation before collection loading
   - Same validation as single fonts

3. [`lib/fontist/system_index.rb`](../lib/fontist/system_index.rb)
   - Added `validation_failures` tracking to `IndexStats`
   - Added `record_validation_failure` method
   - Updated error handling to distinguish validation failures
   - Added `print_validation_error` for clearer logging

### Validation Profile

The `indexability` profile is provided by Fontisan and includes these checks:

1. `required_tables` - Ensures essential tables are present
2. `name_version` - Name table version validation
3. `family_name` - Family name presence check
4. `postscript_name` - PostScript name format validation
5. `head_magic` - Font header magic number check
6. `units_per_em` - Units per em range validation
7. `num_glyphs` - Minimum glyph count verification
8. `reasonable_metrics` - Metrics sanity checks

All checks are **errors** (not warnings) and must pass for the font to be indexable.

## Troubleshooting

### Font Rejected During Installation

**Symptom**: Font installation fails with validation error

**Cause**: Font file is corrupt or has invalid metadata

**Solution**: 
1. Check if you can open the font in a font viewer
2. Try re-downloading the font
3. If the font works elsewhere, file a bug report with the font file

### Index Build Shows Validation Failures

**Symptom**: `fontist index rebuild --verbose` shows validation failures

**Cause**: System contains corrupt or incomplete font files

**Solution**:
1. Review debug logs to identify problematic fonts
2. Remove or fix corrupt fonts
3. Rebuild index: `fontist index rebuild --force`

### False Positives

**Symptom**: Valid-looking font rejected by validation

**Cause**: Font violates OpenType/TrueType specifications

**Solution**:
1. Verify font with external tools (e.g., FontForge, fonttools)
2. If truly valid, file an issue at https://github.com/fontist/fontisan
3. Temporarily exclude from indexing via `lib/fontist/exclude.yml`

## Related Documentation

- [Fontisan Validation Guide](https://github.com/fontist/fontisan#validation) - Full validation documentation
- [Font Indexing Architecture](./index.md) - How indexing works
- [System Font Detection](../README.adoc#system-fonts) - System font discovery

## Migration Notes

### Upgrading from Previous Versions

No code changes required! Validation is applied automatically. However:

1. **First index rebuild** may take slightly longer due to validation
2. **Corrupt fonts** will now be skipped instead of causing crashes
3. **Statistics** now include validation failure counts

### Backward Compatibility

- All existing APIs work unchanged
- Error handling remains the same (FontFileError)
- Index format unchanged

## Future Enhancements

Possible future improvements:

1. **Configurable validation** - Option to skip validation for trusted sources
2. **Validation reports** - Detailed reports of validation failures
3. **Auto-repair** - Attempt to fix minor issues automatically
4. **Profile selection** - Use different profiles for different purposes
