# Google Fonts Integration - Final Architecture

## Ultra-Simple Design

### ONE Class + 4 Data Sources

```
          ┌────────────────────────┐
          │      Database          │  ← Single entry point
          │                        │
          │  .build(api_key,       │
          │         source_path)   │
          │                        │
          │  - all_fonts()         │
          │  - to_formula(name)    │
          │  - save_formulas(dir)  │
          └────────────┬───────────┘
                       │
        ┌──────────────┼──────────────┬──────────┐
        ▼              ▼              ▼          ▼
    Data Source 1  Data Source 2  Data Source 3  Data Source 4

    TtfClient      VfClient       Woff2Client    GitHubRepoClient
    (API: URLs)    (API: VF+axes) (API: WOFF2)   (Repo: metadata)

    All 4 are EQUAL data sources!
```

## Core Concept: Data Sources

All clients are actually **data sources** that provide different information:

**Data Source 1: TTF (API)**
- Provides: Font file URLs in TTF format
- Access: API endpoint without capability parameter

**Data Source 2: VF (API)**
- Provides: Variable font URLs + axes data
- Access: API endpoint with `capability=VF`

**Data Source 3: WOFF2 (API)**
- Provides: Font file URLs in WOFF2 format
- Access: API endpoint with `capability=WOFF2`

**Data Source 4: GitHub (Filesystem)**
- Provides: Metadata, licenses, descriptions, OTF data
- Access: Local filesystem (METADATA.pb files)

## The Database Class

**Location**: `lib/fontist/import/google/database.rb`

```ruby
module Fontist
  module Import
    module Google
      class Database
        class << self
          def build(api_key:, source_path:)
            new(
              ttf_source: DataSources::Ttf.new(api_key: api_key),
              vf_source: DataSources::Vf.new(api_key: api_key),
              woff2_source: DataSources::Woff2.new(api_key: api_key),
              github_source: DataSources::Github.new(source_path: source_path)
            )
          end
        end

        def initialize(ttf_source:, vf_source:, woff2_source:, github_source:)
          @sources = {
            ttf: ttf_source.fetch,
            vf: vf_source.fetch,
            woff2: woff2_source.fetch,
            github: github_source.fetch
          }

          @families = merge_all_sources(@sources)
        end

        # Query
        def all_fonts
          @families.values
        end

        def font_by_name(name)
          @families[name]
        end

        def by_category(category)
          all_fonts.select { |f| f.category == category }
        end

        def variable_fonts_only
          all_fonts.select(&:variable_font?)
        end

        # Generate formula
        def to_formula(family_name)
          family = font_by_name(family_name)
          return nil unless family

          build_formula_yaml(family)
        end

        # Save formulas
        def save_formulas(output_dir, family: nil)
          families = family ? [font_by_name(family)] : all_fonts

          FileUtils.mkdir_p(output_dir)

          families.compact.map do |f|
            formula = to_formula(f.family)
            path = File.join(output_dir, "#{formula_filename(f)}.yml")
            File.write(path, YAML.dump(formula))
            path
          end
        end

        private

        def merge_all_sources(sources)
          # Merge all 4 sources into unified FontFamily objects
        end

        def build_formula_yaml(family)
          # Build Fontist formula from FontFamily
        end
      end
    end
  end
end
```

## File/Directory Structure

```
lib/fontist/import/google/
├── database.rb              # THE main class
├── models/
│   ├── font_family.rb       # Unified data model
│   ├── axis.rb              # VF axes
│   └── font_variant.rb      # Variant info
└── data_sources/            # All 4 data sources (formerly "clients/")
    ├── base.rb              # Base class (common HTTP, caching)
    ├── ttf.rb               # Source 1: TTF URLs
    ├── vf.rb                # Source 2: VF URLs + axes
    ├── woff2.rb             # Source 3: WOFF2 URLs
    └── github.rb            # Source 4: Local repo metadata
```

## Usage Example

```ruby
require 'fontist/import/google/database'

# Build database from all 4 sources
db = Fontist::Import::Google::Database.build(
  api_key: 'AIzaSy...',
  source_path: '/Users/me/google/fonts'
)

# Query merged data
puts "Total fonts: #{db.all_fonts.count}"

roboto = db.font_by_name('Roboto')
puts "Designer: #{roboto.designer}"           # From GitHub
puts "Category: #{roboto.category}"           # From API
puts "Variable: #{roboto.variable_font?}"     # From API (VF source)
puts "Axes: #{roboto.axes.map(&:tag).join}"  # From API (VF source)

# Generate formulas
db.save_formulas('./formulas')                    # All formulas
db.save_formulas('./formulas', family: 'Roboto')  # One formula
```

## Implementation Plan

### Current Status ✅
- 3 API data sources (TTF, VF, WOFF2) implemented
- Models (FontFamily, Axis, FontVariant)
- Database merges 3 API sources
- 188 tests passing

### To Implement
1. **Add 4th data source**: `data_sources/github.rb`
2. **Extend FontFamily model**: Add GitHub fields (designer, license_text, description, homepage, font_file_data)
3. **Extend Database class**:
   - Merge all 4 sources
   - Add `to_formula(name)` method
   - Add `save_formulas(dir)` method
4. **Refactor directory**: Rename `clients/` → `data_sources/`
5. **Update tests**: Test 4-source merging and formula generation

## Why This Is The Simplest

**Only ONE public interface:**
→ Database

**All 4 sources are equals:**
→ Ttf, Vf, Woff2, Github (all in `data_sources/`)

**No wrapper classes:**
→ No Api, No FormulaImporter, No FormulaGenerator

**Just methods:**
→ `to_formula()` is a method on Database
→ `save_formulas()` is a method on Database

## Key Insight

The term **"data source"** clarifies the design:
- They're not specifically "API clients"
- They're sources of data (3 from API, 1 from GitHub)
- Database treats all 4 equally
- Clean, symmetric design

Ready to implement!