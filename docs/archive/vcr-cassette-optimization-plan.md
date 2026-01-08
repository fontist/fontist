# VCR Cassette Optimization Plan

## Problem

Current VCR cassettes contain ALL 1400+ Google Fonts, resulting in:
- **550+ MB total size** (ttf: 239MB, vf: 157MB, woff2: 162MB)
- **6+ minute test runtime** (just loading YAML)
- **Unnecessary data** - tests don't need all fonts

## Solution: Cherry-Pick Representative Samples

Keep only **10-15 carefully selected fonts** that cover all test scenarios.

## Font Selection Criteria

### Required Coverage

1. **Standard TTF fonts** (non-variable)
   - Example: ABeeZee, Roboto

2. **Variable fonts with standard axes** (wght, wdth, slnt)
   - Example: Advent Pro (wght + wdth), Roboto Flex

3. **Variable fonts with custom axes**
   - Example: AR One Sans (ARRR axis)

4. **Different categories**
   - sans-serif: Roboto
   - serif: Noto Serif
   - monospace: Roboto Mono
   - display: Comfortaa

5. **Fonts in multiple formats**
   - Available in TTF, VF, and WOFF2

6. **Edge cases**
   - Very long family names
   - Special characters in names
   - Many variants (regular, bold, italic, etc.)

## Recommended Sample Fonts (15 fonts)

### Group 1: Standard Fonts (3 fonts)
1. **ABeeZee** - Simple sans-serif, 2 variants
2. **Roboto** - Popular, many variants, all formats
3. **Noto Serif** - Serif category

### Group 2: Variable Fonts (5 fonts)
4. **Advent Pro** - VF with wght + wdth axes
5. **Roboto Flex** - VF with multiple standard axes
6. **AR One Sans** - VF with custom axis (ARRR)
7. **Afacad Flux** - VF with wght axis
8. **Comfortaa** - VF, display category

### Group 3: Monospace (1 font)
9. **Roboto Mono** - Monospace category, VF support

### Group 4: Edge Cases (3 fonts)
10. **Noto Sans JP** - Non-Latin script
11. **Material Icons** - Icon font
12. **Long Family Name Example** - If exists

### Group 5: Format Testing (3 fonts)
13. **Font only in TTF** - If exists
14. **Font only in WOFF2** - If exists
15. **Font with version mismatch** - If exists

## Implementation Steps

### Step 1: Identify Font Positions in Current Cassettes

```bash
# Find positions of our selected fonts in cassettes
ruby -e "
require 'yaml'
cassette = YAML.load_file('spec/cassettes/google_fonts/ttf_endpoint.yml')
items = cassette.dig('http_interactions', 0, 'response', 'body', 'string')
data = JSON.parse(items)

selected = ['ABeeZee', 'Roboto', 'Noto Serif', 'Advent Pro',
            'Roboto Flex', 'AR One Sans', 'Afacad Flux', 'Comfortaa',
            'Roboto Mono', 'Noto Sans JP', 'Material Icons']

data['items'].each_with_index do |item, idx|
  if selected.include?(item['family'])
    puts \"#{idx}: #{item['family']}\"
  end
end
"
```

### Step 2: Extract Selected Fonts

Create script `temp-test/trim_cassettes.rb`:

```ruby
require 'yaml'
require 'json'

SELECTED_FONTS = [
  'ABeeZee', 'Roboto', 'Noto Serif', 'Advent Pro',
  'Roboto Flex', 'AR One Sans', 'Afacad Flux', 'Comfortaa',
  'Roboto Mono', 'Noto Sans JP', 'Material Icons'
].freeze

def trim_cassette(input_file, output_file)
  puts "Processing #{input_file}..."

  # Load cassette
  cassette = YAML.load_file(input_file)

  # Extract response body
  response_str = cassette.dig('http_interactions', 0, 'response', 'body', 'string')
  data = JSON.parse(response_str)

  # Filter to selected fonts
  original_count = data['items'].size
  data['items'] = data['items'].select { |item| SELECTED_FONTS.include?(item['family']) }
  new_count = data['items'].size

  puts "  Reduced from #{original_count} to #{new_count} fonts"

  # Update cassette with filtered data
  cassette['http_interactions'][0]['response']['body']['string'] = JSON.pretty_generate(data)

  # Save trimmed cassette
  File.write(output_file, YAML.dump(cassette))

  # Show file size reduction
  old_size = File.size(input_file) / 1024.0 / 1024.0
  new_size = File.size(output_file) / 1024.0 / 1024.0
  puts "  Size: #{old_size.round(1)}MB → #{new_size.round(1)}MB"
end

# Process all three cassettes
trim_cassette(
  'spec/cassettes/google_fonts/ttf_endpoint.yml',
  'spec/cassettes/google_fonts/ttf_endpoint_trimmed.yml'
)

trim_cassette(
  'spec/cassettes/google_fonts/vf_endpoint.yml',
  'spec/cassettes/google_fonts/vf_endpoint_trimmed.yml'
)

trim_cassette(
  'spec/cassettes/google_fonts/woff2_endpoint.yml',
  'spec/cassettes/google_fonts/woff2_endpoint_trimmed.yml'
)

puts "\nTrimmed cassettes created!"
puts "Now:"
puts "1. Verify trimmed cassettes work: bundle exec rspec spec/fontist/import/google/"
puts "2. If tests pass, replace original cassettes:"
puts "   mv spec/cassettes/google_fonts/ttf_endpoint_trimmed.yml spec/cassettes/google_fonts/ttf_endpoint.yml"
puts "   mv spec/cassettes/google_fonts/vf_endpoint_trimmed.yml spec/cassettes/google_fonts/vf_endpoint.yml"
puts "   mv spec/cassettes/google_fonts/woff2_endpoint_trimmed.yml spec/cassettes/google_fonts/woff2_endpoint.yml"
```

### Step 3: Run Trimming Script

```bash
cd /Users/mulgogi/src/fontist/fontist
ruby temp-test/trim_cassettes.rb
```

### Step 4: Verify Tests Still Pass

```bash
bundle exec rspec spec/fontist/import/google/ --format progress
```

Should complete in **< 30 seconds** instead of 6 minutes!

### Step 5: Replace Original Cassettes

```bash
# Backup originals first
mkdir -p spec/cassettes/google_fonts/backup
mv spec/cassettes/google_fonts/*_endpoint.yml spec/cassettes/google_fonts/backup/

# Use trimmed versions
mv spec/cassettes/google_fonts/*_trimmed.yml spec/cassettes/google_fonts/
rename 's/_trimmed//' spec/cassettes/google_fonts/*_trimmed.yml
```

### Step 6: Clean Up *_sample.yml Files

The `*_sample.yml` files (also 550+MB) should be removed:

```bash
# These are duplicates that didn't trim correctly
ls -lh spec/cassettes/google_fonts/*sample*
# Remove them after trimming is done
```

## Expected Results

### File Size Reduction
- **Before**: 550+ MB (1400+ fonts)
- **After**: ~2-5 MB (10-15 fonts)
- **Reduction**: 99% smaller

### Test Performance Improvement
- **Before**: ~6 minutes
- **After**: ~10-30 seconds
- **Improvement**: 12-36x faster

### Test Coverage
- ✅ All scenarios still tested
- ✅ Variable fonts with axes
- ✅ Standard fonts
- ✅ Multiple formats
- ✅ Different categories
- ✅ Edge cases

## Why These Specific Fonts?

### Roboto
- Most popular Google Font
- Multiple variants
- Available in all 3 formats
- Good baseline

### Advent Pro
- Variable font with 2 axes (wght, wdth)
- Tests multi-axis support

### AR One Sans
- Custom axis (ARRR)
- Tests custom axis handling

### Roboto Mono
- Monospace category
- Variable font
- Different use case

### Noto Serif
- Serif category
- Tests category diversity

### AFacad Flux / Comfortaa
- Display fonts
- Variable fonts
- Additional test coverage

## Alternative: JSON Fixtures Instead of VCR

If trimming doesn't work well, create static JSON fixtures:

```
spec/fixtures/google_fonts/
├── ttf_sample.json      # 10 fonts from TTF endpoint
├── vf_sample.json       # 10 fonts from VF endpoint
└── woff2_sample.json    # 10 fonts from WOFF2 endpoint
```

Then update tests to use fixtures instead of VCR:

```ruby
let(:ttf_data) do
  JSON.parse(File.read('spec/fixtures/google_fonts/ttf_sample.json'))
end
```

This would be even faster (no HTTP simulation overhead).

## Recommendation

**Proceed with Step 2-6:**
1. Create and run `trim_cassettes.rb` script
2. Verify tests pass with trimmed cassettes
3. Replace original cassettes
4. Delete unnecessary `*_sample.yml` files
5. Commit the smaller, faster cassettes

**Expected outcome**: Test suite runs in <30 seconds with full coverage!