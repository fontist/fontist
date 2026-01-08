# Fontisan Optimization Plan: Minimal Parsing Mode
# Target: < 30 seconds cold build (currently ~180s, need 6x speedup)

**Strategy:** Parse only what's needed for font indexing
**Impact:** 3-6x speedup expected
**Safety:** No interference with Fontist when used as a library

## Problem Analysis

### Current State
Fontisan currently parses **ALL font tables**:
- Name table (family, subfamily, etc.) ✓ **NEEDED**
- Head table (version, etc.) ✓ **NEEDED**
- GSUB table (glyph substitution) ✗ NOT needed for indexing
- GPOS table (glyph positioning) ✗ NOT needed for indexing
- Kern table (kerning pairs) ✗ NOT needed for indexing
- Many other tables ✗ NOT needed for indexing

**Current:** 0.087 seconds per font
**Wasted:** ~70% of parsing time on tables we don't need

### What Fontist Actually Needs

For building the system font index, we only need:
1. **family_name** (from name table, nameID 1)
2. **subfamily_name** (from name table, nameID 2)
3. **full_name** (from name table, nameID 4)
4. **post_script_name** (from name table, nameID 6)
5. **preferred_family_name** (from name table, nameID 16) - optional
6. **preferred_subfamily_name** (from name table, nameID 17) - optional
7. **version** (from head table) - optional

That's it! Everything else is wasted work.

## Optimization Strategy

### Phase 1: Add Minimal Mode to Fontisan (PRIORITY 1)

**Location:** `/Users/mulgogi/src/fontist/fontisan/lib/fontisan/font_file.rb`

**Add option to skip unnecessary tables:**

```ruby
class FontFile
  def initialize(path, options = {})
    @path = path
    @minimal = options[:minimal] || false  # NEW option

    if @minimal
      # Only parse name table and head table
      parse_minimal_tables
    else
      # Parse everything (current behavior)
      parse_all_tables
    end
  end

  private

  def parse_minimal_tables
    # Parse ONLY what we need:
    # - Name table: family, subfamily, full name, PostScript name
    # - Head table: version (optional)

    @name_table = parse_name_table
    @head_table = parse_head_table  # Optional - can skip if not needed

    # Skip GSUB, GPOS, kern, and all other tables!
  end

  def parse_name_table
    # Parse only required name IDs:
    # 1: Family name
    # 2: Subfamily name
    # 4: Full name
    # 6: PostScript name
    # 16: Preferred family name (if exists)
    # 17: Preferred subfamily name (if exists)

    # Current implementation already does this efficiently
    # But we can optimize string handling
  end
end
```

### Phase 2: Update Fontist to Use Minimal Mode

**Location:** `lib/fontist/font_file.rb` and `lib/fontist/collection_file.rb`

```ruby
# lib/fontist/font_file.rb
def self.from_path(path)
  # Use minimal mode for indexing!
  fontisan_file = Fontisan::FontFile.new(path, minimal: true)

  new.tap do |file|
    file.path = path
    file.family = fontisan_file.family_name
    file.subfamily = fontisan_file.subfamily_name
    file.full_name = fontisan_file.full_name
    file.post_script_name = fontisan_file.post_script_name
    file.preferred_family_name = fontisan_file.preferred_family_name
    file.preferred_subfamily_name = fontisan_file.preferred_subfamily_name
  end
end
```

### Phase 3: Optimize String Handling in Fontisan

**Already in name table parsing, optimize:**

1. **Use frozen strings**
```ruby
# Before:
name_string = extract_string(name_record)

# After:
name_string = extract_string(name_record).freeze
```

2. **Avoid unnecessary string duplication**
```ruby
# Before:
@family_name = name_table[1].dup

# After:
@family_name = name_table[1]  # No dup needed if we freeze it
```

3. **Use string slicing instead of substring**
```ruby
# Before:
substring = full_string[offset, length]

# After (if possible):
substring = full_string.byteslice(offset, length)
```

### Phase 4: Lazy Load Optional Data

Even the head table might not be needed:

```ruby
def version
  @version ||= parse_head_table&.version
end

# Only parse head table if version is actually requested
```

## Expected Performance Gains

| Optimization | Time per Font | Total Time (2,056 fonts) | Speedup |
|-------------|---------------|--------------------------|---------|
| **Baseline** | 0.087s | 180s | 1x |
| Skip unnecessary tables | 0.030s | 62s | 3x |
| + String optimization | 0.025s | 51s | 3.5x |
| + Lazy loading | 0.020s | 41s | 4.5x |
| **Target** | **< 0.015s** | **< 30s** | **6x** |

## Implementation Steps

### Step 1: Profile Current Fontisan Behavior

```bash
cd /Users/mulgogi/src/fontist/fontisan

# Create profiling script
cat > bin/profile_minimal << 'EOF'
#!/usr/bin/env ruby
require "bundler/setup"
require "fontisan"
require "ruby-prof"
require "benchmark"

font_path = ARGV[0] || "/Library/Fonts/Arial.ttf"

puts "Profiling: #{font_path}"
puts "=" * 60

# Profile current parsing
result = RubyProf.profile do
  100.times { Fontisan::FontFile.new(font_path) }
end

printer = RubyProf::FlatPrinter.new(result)
printer.print(STDOUT, min_percent: 1.0)

# Benchmark parsing time
time = Benchmark.realtime do
  1000.times { Fontisan::FontFile.new(font_path) }
end

puts "\nAverage time per font: #{(time / 1000).round(4)}s"
EOF

chmod +x bin/profile_minimal
bin/profile_minimal
```

**Expected findings:**
- 50-70% of time in parsing unnecessary tables
- 10-20% in string operations
- 10-20% in I/O operations

### Step 2: Implement Minimal Mode in Fontisan

```ruby
# /Users/mulgogi/src/fontist/fontisan/lib/fontisan/font_file.rb

class FontFile
  attr_reader :family_name, :subfamily_name, :full_name,
              :post_script_name, :preferred_family_name,
              :preferred_subfamily_name, :version

  def initialize(path, options = {})
    @path = path
    @data = File.binread(path)
    @minimal = options.fetch(:minimal, false)

    parse_sfnt_header

    if @minimal
      parse_name_table_only
    else
      parse_all_tables
    end
  end

  private

  def parse_name_table_only
    # Find and parse ONLY the name table
    # Extract only the 6 name IDs we need
    # Skip everything else!

    name_table_entry = @table_directory.find { |e| e[:tag] == "name" }
    return unless name_table_entry

    offset = name_table_entry[:offset]
    length = name_table_entry[:length]

    # Parse name records
    @data.seek(offset)
    # ... extract only nameID 1, 2, 4, 6, 16, 17 ...

    # Store results
    @family_name = extract_name(1)
    @subfamily_name = extract_name(2)
    @full_name = extract_name(4)
    @post_script_name = extract_name(6)
    @preferred_family_name = extract_name(16)
    @preferred_subfamily_name = extract_name(17)
  end

  def extract_name(name_id)
    # Efficient extraction of single name ID
    # Freeze string to prevent duplication
    find_name_record(name_id)&.freeze
  end
end
```

### Step 3: Update Fontist to Use Minimal Mode

```ruby
# lib/fontist/font_file.rb
module Fontist
  class FontFile
    def self.from_path(path)
      # CRITICAL: Use minimal: true for fast indexing!
      fontisan_file = Fontisan::FontFile.new(path, minimal: true)

      new.tap do |file|
        file.path = path
        file.family = fontisan_file.family_name
        file.full_name = fontisan_file.full_name
        file.subfamily = fontisan_file.subfamily_name
        file.post_script_name = fontisan_file.post_script_name
        file.preferred_family_name = fontisan_file.preferred_family_name
        file.preferred_subfamily_name = fontisan_file.preferred_subfamily_name
      end
    end
  end
end
```

### Step 4: Test and Benchmark

```bash
# In fontist directory
fontist index clear

# Benchmark with minimal mode
time fontist index rebuild --verbose

# Expected: 40-60 seconds (3-4x speedup)
```

### Step 5: Further Optimize String Handling

If step 4 doesn't hit <30s, add string optimizations:

```ruby
# In fontisan/lib/fontisan/font_file.rb

# Use frozen string literals
# frozen_string_literal: true

def extract_name(name_id)
  # Avoid string duplication
  record = find_name_record(name_id)
  return nil unless record

  # Use byteslice for efficiency
  string = @data.byteslice(record[:offset], record[:length])

  # Decode and freeze immediately
  decode_string(string).freeze
end

# Reuse decoded platform strings
PLATFORM_ENCODINGS = {
  0 => Encoding::UTF_16BE,
  1 => Encoding::MACROMAN,
  3 => Encoding::UTF_16BE,
}.freeze

def decode_string(bytes, platform_id = 3)
  bytes.force_encoding(PLATFORM_ENCODINGS[platform_id]).encode(Encoding::UTF_8)
end
```

## Testing Strategy

### Unit Tests for Minimal Mode

```ruby
# fontisan/spec/fontisan/font_file_spec.rb

describe Fontisan::FontFile do
  context "with minimal: true" do
    let(:font) { described_class.new(font_path, minimal: true) }

    it "parses family name" do
      expect(font.family_name).to eq("Arial")
    end

    it "parses subfamily name" do
      expect(font.subfamily_name).to eq("Regular")
    end

    it "parses full name" do
      expect(font.full_name).to eq("Arial")
    end

    it "skips unnecessary tables" do
      # Verify GSUB, GPOS, etc. are not parsed
      expect(font.instance_variable_get(:@gsub_table)).to be_nil
    end

    it "is faster than full parsing" do
      minimal_time = Benchmark.realtime {
        10.times { described_class.new(font_path, minimal: true) }
      }

      full_time = Benchmark.realtime {
        10.times { described_class.new(font_path) }
      }

      expect(minimal_time).to be < (full_time * 0.5)  # At least 2x faster
    end
  end
end
```

### Integration Tests in Fontist

```bash
# Ensure fontist still works correctly
bundle exec rspec spec/fontist/font_file_spec.rb
bundle exec rspec spec/fontist/collection_file_spec.rb
bundle exec rspec spec/fontist/system_index_spec.rb
```

## Success Criteria

- [ ] Fontisan minimal mode implemented
- [ ] Fontist uses minimal: true for indexing
- [ ] Cold build time < 30 seconds
- [ ] All existing tests pass
- [ ] No behavior changes (same metadata extracted)
- [ ] Works with TTC files too
- [ ] Documentation updated

## Why This is Better Than Process Parallelism

1. **Library-safe** - Won't interfere when fontist is used as a library
2. **Cleaner architecture** - Addresses root cause (unnecessary parsing)
3. **More maintainable** - Single-threaded, simpler code
4. **Better resource usage** - Lower memory, no process overhead
5. **Portable** - Works on all platforms without complexity

## Timeline

- Hour 1: Profile fontisan, identify table parsing overhead
- Hour 2-3: Implement minimal mode in fontisan
- Hour 4: Update fontist to use minimal mode
- Hour 5: Test and benchmark
- Hour 6: String optimizations if needed
- Hour 7-8: Final testing and documentation

**Total: 1-2 days to achieve <30s cold build**

## Fallback

If minimal mode doesn't hit <30s:
1. Combine with limited thread parallelism (4 threads max, safe for library use)
2. Further optimize string handling
3. Consider caching parsed name tables on disk

But minimal mode alone should give us the 3-6x speedup we need!