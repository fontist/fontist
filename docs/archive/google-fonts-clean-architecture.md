# Google Fonts Clean Architecture (Revised)

## Problem with Previous Design

Having `Api.database(source_path: ...)` is problematic because:
1. `Api` should be for API operations only, not filesystem
2. Optional parameters that change return types are confusing
3. Mixes concerns - API data vs GitHub repository data

## Clean Architecture Solution

### Principle: Separation of Concerns

```
┌──────────────────────────────────────────────────────────┐
│              FormulaImporter                              │
│  High-level orchestrator for formula generation          │
│  Usage: FormulaImporter.generate(...)                    │
└────────────────────┬─────────────────────────────────────┘
                     │
                     ▼
            ┌──────────────────┐
            │  Database        │
            │  (Build from     │
            │   4 sources)     │
            └──────────────────┘
                     ▲
                    / \
                   /   \
                  /     \
     ┌───────────/       \───────────┐
     │                               │
     ▼                               ▼
┌─────────────┐            ┌──────────────────┐
│  Api        │            │ GitHubRepoClient │
│  (API only) │            │ (GitHub only)    │
└─────────────┘            └──────────────────┘
     │                               │
     ▼                               ▼
API Clients (3)              GitHub Repository
```

### Component Responsibilities

**1. Api (API Operations Only)**
```ruby
# ONLY for API data
Fontist::Import::Google::Api.items              # API data
Fontist::Import::Google::Api.database           # API-only database
Fontist::Import::Google::Api.variable_fonts_only
```

**2. GitHubRepoClient (GitHub Operations Only)**
```ruby
# ONLY for GitHub repository data
client = GitHubRepoClient.new(source_path: '...')
client.fetch                    # All families from repo
client.fetch_family('Roboto')   # Single family
```

**3. Database (Unified Builder)**
```ruby
# Build from all sources (4 clients)
database = Database.build(
  ttf_client: ttf_client,
  vf_client: vf_client,
  woff2_client: woff2_client,
  github_client: github_client
)

# Or shortcut
database = Database.build_from_all_sources(
  api_key: 'key',
  source_path: '/path/to/repo'
)
```

**4. FormulaImporter (High-Level Orchestrator)**
```ruby
# Simple interface for formula generation
Fontist::Import::Google::FormulaImporter.generate(
  source_path: '/path/to/google/fonts',
  output_dir: './formulas',
  font_family: 'Roboto'  # optional
)
```

## Revised Class Structure

### 1. Api (Unchanged - API Only)

Location: `lib/fontist/import/google/api.rb`

```ruby
module Fontist
  module Import
    module Google
      class Api
        class << self
          # Returns API-only database (3 endpoints merged)
          def database
            @database ||= build_api_database
          end

          def items
            database.all_fonts
          end

          # ... other API-only methods

          private

          def build_api_database
            Database<br>.build_from_api(
              ttf_client: ttf_client,
              vf_client: vf_client,
              woff2_client: woff2_client
            )
          end
        end
      end
    end
  end
end
```

### 2. Database (Refactored - Universal Builder)

Location: `lib/fontist/import/google/database.rb` (rename from font_database.rb)

```ruby
module Fontist
  module Import
    module Google
      class Database
        class << self
          # Build from API clients only (current implementation)
          def build_from_api(ttf_client:, vf_client:, woff2_client:)
            new(
              ttf_data: ttf_client.fetch,
              vf_data: vf_client.fetch,
              woff2_data: woff2_client.fetch,
              github_data: nil
            )
          end

          # Build from all sources (API + GitHub)
          def build_from_all_sources(api_key:, source_path:)
            new(
              ttf_data: Clients::TtfClient.new(api_key: api_key).fetch,
              vf_data: Clients::VfClient.new(api_key: api_key).fetch,
              woff2_data: Clients::Woff2Client.new(api_key: api_key).fetch,
              github_data: Clients::GitHubRepoClient.new(source_path: source_path).fetch
            )
          end
        end

        def initialize(ttf_data:, vf_data:, woff2_data:, github_data: nil)
          @ttf_data = ttf_data
          @vf_data = vf_data
          @woff2_data = woff2_data
          @github_data = github_data ? index_by_family(github_data) : {}

          @families = merge_all_sources
        end

        # Query methods
        def all_fonts
          @families.values
        end

        def font_by_name(name)
          @families[name]
        end

        # NEW: Formula generation
        def to_formula(family_name)
          family = font_by_name(family_name)
          return nil unless family

          FormulaGenerator.new(family).generate
        end

        def to_formulas
          all_fonts.map { |f| to_formula(f.family) }.compact
        end

        private

        def merge_all_sources
          # Merge API data (existing logic)
          api_merged = merge_api_data

          # Add GitHub data if present
          return api_merged if @github_data.empty?

          merge_with_github(api_merged)
        end

        def merge_api_data
          # Current implementation (TTF, VF, WOFF2)
          # ...
        end

        def merge_with_github(api_families)
          api_families.each do |name, family|
            gh_data = @github_data[name]
            next unless gh_data

            # Enhance family with GitHub data
            family.designer = gh_data.designer
            family.license_text = gh_data.license_text
            family.description = gh_data.description
            family.homepage = gh_data.homepage
            family.font_file_data = gh_data.font_files  # For OTF parsing
          end

          api_families
        end
      end
    end
  end
end
```

### 3. FormulaImporter (NEW - High-Level Orchestrator)

Location: `lib/fontist/import/google/formula_importer.rb`

```ruby
module Fontist
  module Import
    module Google
      # High-level interface for generating Google Fonts formulas
      class FormulaImporter
        def self.generate(source_path:, output_dir:, font_family: nil, api_key: nil)
          new(source_path, output_dir, font_family, api_key).generate
        end

        def initialize(source_path, output_dir, font_family = nil, api_key = nil)
          @source_path = source_path
          @output_dir = output_dir
          @font_family = font_family
          @api_key = api_key || Fontist.google_fonts_key
        end

        def generate
          # Build unified database
          database = Database.build_from_all_sources(
            api_key: @api_key,
            source_path: @source_path
          )

          # Generate formulas
          if @font_family
            generate_single(database, @font_family)
          else
            generate_all(database)
          end
        end

        private

        def generate_single(database, family_name)
          formula = database.to_formula(family_name)
          return nil unless formula

          save_formula(formula, family_name)
        end

        def generate_all(database)
          FileUtils.mkdir_p(@output_dir)

          results = { successful: 0, failed: 0, errors: [] }

          database.all_fonts.each do |family|
            formula = database.to_formula(family.family)
            if formula
              save_formula(formula, family.family)
              results[:successful] += 1
            else
              results[:failed] += 1
              results[:errors] << { font: family.family, error: "Failed to generate formula" }
            end
          end

          results
        end

        def save_formula(formula, family_name)
          filename = "#{family_name.downcase.gsub(/\s+/, '_')}.yml"
          path = File.join(@output_dir, filename)

          File.write(path, YAML.dump(formula))
          path
        end
      end
    end
  end
end
```

## Usage Examples

### API Data Only (No GitHub)

```ruby
# Use Api for API-only operations
api_database = Fontist::Import::Google::Api.database
variable_fonts = api_database.variable_fonts_only
```

### GitHub Data Only

```ruby
# Use GitHubRepoClient for repo-only operations
github_client = Fontist::Import::Google::Clients::GitHubRepoClient.new(
  source_path: '/path/to/google/fonts'
)
families = github_client.fetch
```

### Combined Data + Formula Generation

```ruby
# Use FormulaImporter for the full workflow
Fontist::Import::Google::FormulaImporter.generate(
  source_path: '/path/to/google/fonts',
  output_dir: './formulas',
  font_family: 'Roboto'  # optional
)
```

### Advanced: Build Database Manually

```ruby
# Build database from all sources
database = Fontist::Import::Google::Database.build_from_all_sources(
  api_key: 'your-key',
  source_path: '/path/to/google/fonts'
)

# Query the unified database
roboto = database.font_by_name('Roboto')
puts roboto.designer          # From GitHub
puts roboto.axes.count        # From API
puts roboto.license_text      # From GitHub

# Generate formula
formula = database.to_formula('Roboto')
```

## Class Diagram

```
┌──────────────────────────────┐
│     FormulaImporter          │  ← High-level orchestrator
│  .generate(source_path, ...) │  ← Main entry point
└──────────────┬───────────────┘
               │ uses
               ▼
┌──────────────────────────────┐
│         Database             │  ← Universal builder
│  .build_from_api(...)        │  ← API only
│  .build_from_all_sources(..) │  ← API + GitHub
│  .to_formula(name)           │  ← Generate formula
└──────────────┬───────────────┘
               │ uses
     ┌─────────┼─────────┐
     ▼         ▼         ▼
┌────────┐ ┌────────┐ ┌──────────────┐
│  Api   │ │Clients │ │FormulaGenerator│
│        │ │(4 types)│ │              │
└────────┘ └────────┘ └──────────────┘
```

## Benefits of This Design

### 1. Clear Separation of Concerns
- `Api`: API operations only
- `GitHubRepoClient`: GitHub repo reading only
- `Database`: Unified data merging
- `FormulaImporter`: High-level workflow orchestration

### 2. Flexible Usage
```ruby
# API only
Api.items

# GitHub only
GitHubRepoClient.new(...).fetch

# Combined
Database.build_from_all_sources(...)

# Formula generation
FormulaImporter.generate(...)
```

### 3. No Weird Parameters
- `Api.database` - always returns API-only database
- `Database.build_from_all_sources(...)` - clearly states it needs all sources
- `FormulaImporter.generate(...)` - clearly a formula generation operation

### 4. Backward Compatible
- Existing `Api` interface unchanged
- Can be used with or without GitHub data
- Gradual adoption path

## Migration Path

### Current Code
```ruby
# API only (works today)
families = Fontist::Import::Google::Api.items
```

### New Formula Generation
```ruby
# Generate formulas (NEW)
Fontist::Import::Google::FormulaImporter.generate(
  source_path: '/path/to/google/fonts',
  output_dir: './formulas'
)
```

### Advanced Usage
```ruby
# Build unified database (NEW)
db = Fontist::Import::Google::Database.build_from_all_sources(
  api_key: 'key',
  source_path: '/path/to/repo'
)

# Access merged data
font = db.font_by_name('Roboto')
puts font.designer        # From GitHub
puts font.axes.count      # From API

# Generate formula
formula = db.to_formula('Roboto')
```

## Implementation Order

1. **Add GitHubRepoClient** to Clients layer
2. **Add GitHubFontFamily model** for GitHub data
3. **Refactor FontFamily model** to include GitHub fields
4. **Extend Database** with GitHub merging + `to_formula` methods
5. **Create FormulaGenerator** class
6. **Create FormulaImporter** as high-level API
7. **Update CLI** to use FormulaImporter
8. **Deprecate old GoogleFontsImporter**

## Key Points

✅ **Api stays pure** - API operations only, no filesystem
✅ **Database is universal** - Can build from API only OR API+GitHub
✅ **FormulaImporter is clear** - Obviously for formula generation
✅ **No weird parameters** - Each method has one clear purpose
✅ **Backward compatible** - Existing code unaffected
✅ **Easy to test** - Each component independently testable

This architecture is much cleaner and follows proper separation of concerns!