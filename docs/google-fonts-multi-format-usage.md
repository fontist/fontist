# Google Fonts Multi-Format API Usage Guide

This guide explains how to use the new multi-format Google Fonts API integration in Fontist, which provides access to TTF, Variable Fonts (VF), and WOFF2 formats.

## Overview

The Google Fonts API integration now fetches data from three endpoints and merges them into a unified database:

1. **TTF Endpoint** - Standard TrueType fonts
2. **VF Endpoint** - Variable fonts with axes information
3. **WOFF2 Endpoint** - WOFF2 format files

## Quick Start

```ruby
require 'fontist'
require 'fontist/import/google/api'

# Get all font families (includes TTF, VF, and WOFF2 data)
families = Fontist::Import::Google::Api.items
puts "Total families: #{families.count}"

# Access unified database
db = Fontist::Import::Google::Api.database
```

## Basic Operations

### Get All Fonts

```ruby
# Returns array of FontFamily objects
all_fonts = Fontist::Import::Google::Api.items

# Iterate through fonts
all_fonts.each do |font|
  puts "#{font.family} (#{font.category})"
end
```

### Find Specific Font

```ruby
# Find by familia name
roboto = Fontist::Import::Google::Api.font_by_name("Roboto")

if roboto
  puts "Family: #{roboto.family}"
  puts "Category: #{roboto.category}"
  puts "Variants: #{roboto.variants.join(', ')}"
  puts "Version: #{roboto.version}"
  puts "Last Modified: #{roboto.last_modified}"
end
```

### Filter by Category

```ruby
# Get all sans-serif fonts
sans_serif = Fontist::Import::Google::Api.by_category("sans-serif")
puts "Sans-serif fonts: #{sans_serif.count}"

# Get all monospace fonts
monospace = Fontist::Import::Google::Api.by_category("monospace")
```

## Variable Fonts

### Get Variable Fonts Only

```ruby
# Returns only fonts with variable font axes
variable_fonts = Fontist::Import::Google::Api.variable_fonts_only
puts "Variable fonts: #{variable_fonts.count}"

variable_fonts.each do |font|
  puts "\n#{font.family}"
  font.axes.each do |axis|
    puts "  #{axis.tag}: #{axis.start} to #{axis.end}"
  end
end
```

### Check if Font is Variable

```ruby
font = Fontist::Import::Google::Api.font_by_name("Roboto Flex")

if font&.variable_font?
  puts "#{font.family} is a variable font with #{font.axes.count} axes"

  # Access specific axes
  weight_axes = font.weight_axes
  width_axes = font.width_axes
  slant_axes = font.slant_axes
  custom_axes = font.custom_axes
end
```

### Working with Axes

```ruby
font = Fontist::Import::Google::Api.font_by_name("Advent Pro")

if font&.variable_font?
  font.axes.each do |axis|
    puts "Axis: #{axis.tag}"
    puts "  Range: #{axis.start} - #{axis.end}"
    puts "  Type: #{axis.description}"

    # Check axis type
    puts "  Weight axis" if axis.weight_axis?
    puts "  Width axis" if axis.width_axis?
    puts "  Slant axis" if axis.slant_axis?
    puts "  Custom axis" if axis.custom_axis?
  end

  # Find specific axis
  weight_axis = font.axis_by_tag("wght")
  if weight_axis
    puts "Weight range: #{weight_axis.range.inspect}"
  end
end
```

## Multiple Formats (TTF and WOFF2)

### Check Available Formats

```ruby
db = Fontist::Import::Google::Api.database

# Fonts with TTF format
ttf_fonts = db.fonts_with_ttf
puts "Fonts with TTF: #{ttf_fonts.count}"

# Fonts with WOFF2 format
woff2_fonts = db.fonts_with_woff2
puts "Fonts with WOFF2: #{woff2_fonts.count}"

# Fonts with both formats
both_formats = db.fonts_with_both_formats
puts "Fonts with both: #{both_formats.count}"
```

### Access Format-Specific URLs

```ruby
db = Fontist::Import::Google::Api.database

# Get TTF URLs for a font
ttf_files = db.ttf_files_for("Roboto")
ttf_files.each do |variant, url|
  puts "#{variant}: #{url}"
end

# Get WOFF2 URLs for a font
woff2_files = db.woff2_files_for("Roboto")
woff2_files.each do |variant, url|
  puts "#{variant}: #{url}"
end
```

### Font Files Structure

```ruby
font = Fontist::Import::Google::Api.font_by_name("Roboto")

# The files hash contains TTF URLs by default
font.files.each do |variant, url|
  puts "#{variant} (TTF): #{url}"
end

# Access both formats via database
db = Fontist::Import::Google::Api.database
ttf = db.ttf_files_for("Roboto")
woff2 = db.woff2_files_for("Roboto")
```

## Advanced Queries

### Get Statistics

```ruby
# Overall statistics
stats = Fontist::Import::Google::Api.fonts_count
puts "Total fonts: #{stats[:total]}"
puts "Variable fonts: #{stats[:variable]}"
puts "Static fonts: #{stats[:static]}"

# Database-level statistics
db = Fontist::Import::Google::Api.database
puts "Categories: #{db.categories.join(', ')}"
```

### Filter Static Fonts

```ruby
# Get only static (non-variable) fonts
static_fonts = Fontist::Import::Google::Api.static_fonts_only
puts "Static fonts: #{static_fonts.count}"
```

### Access Raw Endpoint Data

```ruby
# For debugging or advanced use cases
ttf_data = Fontist::Import::Google::Api.ttf_data
vf_data = Fontist::Import::Google::Api.vf_data
woff2_data = Fontist::Import::Google::Api.woff2_data

puts "TTF endpoint: #{ttf_data.count} fonts"
puts "VF endpoint: #{vf_data.count} fonts"
puts "WOFF2 endpoint: #{woff2_data.count} fonts"
```

## Caching

### Clear Cache

```ruby
# Clear all caches (database and client caches)
Fontist::Import::Google::Api.clear_cache

# Data will be re-fetched on next access
families = Fontist::Import::Google::Api.items
```

### Cache Behavior

- API responses are cached at the client level
- Database is built once and cached
- Call `clear_cache` to force refresh from API

## FontFamily Model

The [`FontFamily`](../lib/fontist/import/google/models/font_family.rb) model provides:

```ruby
font = Fontist::Import::Google::Api.font_by_name("Roboto")

# Basic attributes
font.family          # "Roboto"
font.category        # "sans-serif"
font.version         # "v30"
font.last_modified   # "2022-09-22"

# Variants and subsets
font.variants        # ["regular", "italic", "700", ...]
font.subsets         # ["latin", "latin-ext", ...]

# Files (TTF URLs by default)
font.files           # {"regular" => "url", ...}

# Variable font support
font.variable_font?  # true/false
font.axes            # Array of Axis objects (if VF)

# Helper methods
font.variant_names   # Array of variant names
font.file_urls       # Array of file URLs
font.variant_exists?("700")  # Check if variant exists
font.variant_url("regular")  # Get URL for variant
```

## Axis Model

The [`Axis`](../lib/fontist/import/google/models/axis.rb) model for variable fonts:

```ruby
axis = font.axes.first

# Attributes
axis.tag             # "wght", "wdth", "slnt", etc.
axis.start           # Minimum value (e.g., 100)
axis.end             # Maximum value (e.g., 900)

# Helper methods
axis.weight_axis?    # Check if weight axis
axis.width_axis?     # Check if width axis
axis.slant_axis?     # Check if slant axis
axis.custom_axis?    # Check if custom axis
axis.range           # [start, end]
axis.description     # Human-readable description
```

## Error Handling

```ruby
begin
  families = Fontist::Import::Google::Api.items
rescue StandardError => e
  puts "Error fetching fonts: #{e.message}"
end

# Check if font exists
font = Fontist::Import::Google::Api.font_by_name("NonExistent")
if font.nil?
  puts "Font not found"
end
```

## Example: List Variable Fonts with Axes

```ruby
require 'fontist/import/google/api'

puts "Variable Fonts with Axes\n"
puts "=" * 60

Fontist::Import::Google::Api.variable_fonts_only.each do |font|
  puts "\n#{font.family}"
  puts "  Category: #{font.category}"
  puts "  Variants: #{font.variants.count}"
  puts "  Axes:"

  font.axes.each do |axis|
    type = if axis.weight_axis?
             "Weight"
           elsif axis.width_axis?
             "Width"
           elsif axis.slant_axis?
             "Slant"
           else
             "Custom (#{axis.tag})"
           end

    puts "    - #{type}: #{axis.start} to #{axis.end}"
  end
end
```

## Example: Download Fonts by Category

```ruby
require 'fontist/import/google/api'
require 'net/http'
require 'fileutils'

# Get all monospace fonts
monospace_fonts = Fontist::Import::Google::Api.by_category("monospace")

# Create download directory
download_dir = "fonts/monospace"
FileUtils.mkdir_p(download_dir)

monospace_fonts.each do |font|
  puts "Downloading #{font.family}..."

  font.files.each do |variant, url|
    filename = "#{font.family.gsub(' ', '_')}-#{variant}.ttf"
    filepath = File.join(download_dir, filename)

    # Download file
    uri = URI(url)
    response = Net::HTTP.get_response(uri)

    if response.is_a?(Net::HTTPSuccess)
      File.binwrite(filepath, response.body)
      puts "  ✓ #{filename}"
    else
      puts "  ✗ Failed to download #{filename}"
    end
  end
end

puts "\nDownload complete!"
```

## Architecture

The implementation consists of four layers:

### 1. Models Layer
- [`FontFamily`](../lib/fontist/import/google/models/font_family.rb) - Represents font families
- [`FontVariant`](../lib/fontist/import/google/models/font_variant.rb) - Represents font variants
- [`Axis`](../lib/fontist/import/google/models/axis.rb) - Represents variable font axes

### 2. Clients Layer
- [`TtfClient`](../lib/fontist/import/google/clients/ttf_client.rb) - Fetches TTF data
- [`VfClient`](../lib/fontist/import/google/clients/vf_client.rb) - Fetches VF data with axes
- [`Woff2Client`](../lib/fontist/import/google/clients/woff2_client.rb) - Fetches WOFF2 data

### 3. Database Layer
- [`FontDatabase`](../lib/fontist/import/google/font_database.rb) - Merges data from all endpoints

### 4. API Layer
- [`Api`](../lib/fontist/import/google/api.rb) - Public facade for accessing fonts

## Configuration

Set your Google Fonts API key:

```ruby
# Via environment variable
ENV['GOOGLE_FONTS_KEY'] = 'your-api-key'

# Or configure Fontist
Fontist.google_fonts_key = 'your-api-key'
```

## Testing

See [`spec/fontist/import/google/`](../spec/fontist/import/google/) for comprehensive test examples.

Run tests:
```bash
bundle exec rspec spec/fontist/import/google/
```

All 188 tests pass successfully! ✅

## Additional Resources

- [Google Fonts Developer API](https://developers.google.com/fonts/docs/developer_api)
- [Variable Fonts Guide](https://web.dev/variable-fonts/)
- [Architecture Plan](google-fonts-api-architecture.md)
- [API Analysis](../temp-test/api_analysis.md)
- [Implementation Summary](../temp-test/implementation_summary.md)