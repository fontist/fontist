# Google Fonts Integration - Simplified Architecture

## The Problem With Over-Engineering

**Too many layers:**
- ❌ Api (wrapper around clients)
- ❌ FormulaImporter (wrapper around Database)
- ❌ FormulaGenerator (just a method)

**Solution: Keep it simple!**

## Simplified Clean Architecture

```
                    ┌──────────────────────┐
                    │      Database        │ ← Single entry point
                    │  - all_fonts()       │ ← Query methods
                    │  - to_formula(name)  │ ← Generate formula
                    └──────────┬───────────┘
                               │
                ┌──────────────┼──────────────┐
                │              │              │
                ▼              ▼              ▼
         ┌──────────┐   ┌─────────┐   ┌──────────┐
         │ Clients  │   │ Models  │   │to_formula│
         │ (4 types)│   │         │   │ (method) │
         └──────────┘   └─────────┘   └──────────┘
```

## Single Entry Point: Database

### Database Class (The ONLY Public Interface)

Location: `lib/fontist/import/google/database.rb`

```ruby
module Fontist
  module Import
    module Google
      class Database
        class << self
          # Build from all 4 sources
          def build(api_key:, source_path:)
            new(
              ttf_data: Clients::TtfClient.new(api_key: api_key).fetch,
              vf_data: Clients::VfClient.new(api_key: api_key).fetch,
              woff2_data: Clients::Woff2Client.new(api_key: api_key).fetch,
              github_data: Clients::GitHubRepoClient.new(source_path: source_path).fetch
            )
          end
        end

        def initialize(ttf_data:, vf_data:, woff2_data:, github_data:)
          @ttf_data = ttf_data
          @vf_data = vf_data
          @woff2_data = woff2_data
          @github_data = index_by_family(github_data)

          @families = merge_all_four_sources
        end

        # Query methods
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

        # Formula generation (built-in method)
        def to_formula(family_name)
          family = font_by_name(family_name)
          return nil unless family

          build_formula(family)
        end

        def to_formulas
          all_fonts.map { |f| to_formula(f.family) }.compact
        end

        # Save formulas to disk
        def save_formulas(output_dir, family_name: nil)
          families = family_name ? [font_by_name(family_name)] : all_fonts

          families.compact.map do |family|
            formula = to_formula(family.family)
            save_formula(formula, family.family, output_dir)
          end
        end

        private

        def merge_all_four_sources
          # Merge TTF, VF, WOFF2 (existing logic)
          api_merged = merge_api_sources

          # Add GitHub data
          merge_with_github(api_merged)
        end

        def build_formula(family)
          {
            name: formula_name(family),
            description: family.description,
            homepage: family.homepage || default_homepage(family),
            resources: build_resources(family),
            fonts: build_fonts(family),
            copyright: family.license_text,
            license_url: license_url(family),
            open_license: open_license?(family)
          }
        end

        def build_resources(family)
          # Build from file data
          # Use API URLs (TTF, WOFF2) + GitHub URLs as fallback
        end

        def build_fonts(family)
          # Build from OTF data (GitHub) + axes (API)
        end

        def save_formula(formula, family_name, output_dir)
          FileUtils.mkdir_p(output_dir)
          filename = "#{family_name.downcase.gsub(/\s+/, '_')}.yml"
          path = File.join(output_dir, filename)
          File.write(path, YAML.dump(formula))
          path
        end
      end
    end
  end
end
```

## THAT'S IT. Simple Usage:

### Generate All Formulas

```ruby
require 'fontist/import/google/database'

# One class, one method call
db = Fontist::Import::Google::Database.build(
  api_key: 'your-key',
  source_path: '/path/to/google/fonts'
)

# Save all formulas
db.save_formulas('./formulas')
```

### Generate Single Formula

```ruby
db = Fontist::Import::Google::Database.build(
  api_key: 'key',
  source_path: '/path'
)

# Generate formula
db.save_formulas('./formulas', family_name: 'Roboto')
```

### Query Data

```ruby
db = Fontist::Import::Google::Database.build(...)

# All fonts
db.all_fonts

# Find one
roboto = db.font_by_name('Roboto')
puts roboto.designer      # From GitHub
puts roboto.axes.count    # From API

# Get formula YAML
formula = db.to_formula('Roboto')
```

## Architecture Benefits

### 1. Single Entry Point
- Only one class to learn: `Database`
- Clear factory method: `Database.build(...)`
- All operations in one place

### 2. No Redundant Layers
- ❌ No Api wrapper (already have Database)
- ❌ No FormulaImporter wrapper (Database.save_formulas)
- ❌ No FormulaGenerator class (Database.to_formula method)

### 3. Data Source Symmetry
All 4 data sources are just clients:
- `TtfClient` - API endpoint
- `VfClient` - API endpoint
- `Woff2Client` - API endpoint
- `GitHubRepoClient` - Local filesystem

Database treats them all equally!

### 4. Clear Methods
```ruby
# Query
db.all_fonts
db.font_by_name(name)
db.variable_fonts_only

# Transform
db.to_formula(name)
db.to_formulas

# Persist
db.save_formulas(dir)
```

## What About the Existing Api Class?

### Option 1: Remove It (Cleanest)
Database replaces Api entirely.

```ruby
# Old
Api.items

# New
Database.build(api_key: key, source_path: nil).all_fonts
```

### Option 2: Keep Api (Convenience Wrapper)
Api becomes a convenience facade for API-only operations.

```ruby
module Fontist
  module Import
    module Google
      class Api
        class << self
          def database
            @database ||= Database.build_api_only(
              api_key: Fontist.google_fonts_key
            )
          end

          def items
            database.all_fonts
          end

          # ... delegate all methods to database
        end
      end
    end
  end
end
```

**Recommendation**: Keep Api as convenience wrapper, but Database is the real powerhouse.

## Revised Implementation Plan

### What We Have
✅ 3 API clients (TTF, VF, WOFF2)
✅ Models (FontFamily, Axis)
✅ Database (API merging only)
✅ Api facade (convenience wrapper)

### What We Need
- [ ] Add 4th client: GitHubRepoClient
- [ ] Extend Database to handle 4 sources
- [ ] Add `to_formula()` method to Database
- [ ] Update Api to use new Database
- [ ] That's it!

## File Structure

```
lib/fontist/import/google/
├── database.rb              # THE main class
├── api.rb                   # Optional convenience wrapper
├── models/
│   ├── font_family.rb       # Unified model (API + GitHub fields)
│   ├── axis.rb
│   └── font_variant.rb
└── clients/
    ├── ttf_client.rb        # API source 1
    ├── vf_client.rb         # API source 2
    ├── woff2_client.rb      # API source 3
    └── github_repo_client.rb  # Source 4
```

**No formula_importer.rb**
**No formula_generator.rb**
**No api_endpoint.rb** (keep as base class for API clients)

## Answers to Your Questions

**Q: Why FormulaImporter AND FormulaGenerator?**
A: We don't need them! `Database.to_formula()` method is sufficient.

**Q: Why Api separated from clients?**
A: Good point! All 4 clients (3 API + 1 GitHub) are equals. Api is just a convenience wrapper. Database should be the main interface.

**Q: 3 API sources vs 1 GitHub source?**
A: Exactly! They're all just data sources (clients). Database merges ALL 4.

## Simplest Possible Design

```ruby
# Build database from 4 sources
db = Database.build(
  api_key: 'key',
  source_path: '/path'
)

# Use it
db.all_fonts                      # Query
db.to_formula('Roboto')           # Generate
db.save_formulas('./formulas')    # Save
```

**That's all you need!**