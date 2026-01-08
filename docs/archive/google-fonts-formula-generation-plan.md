# Google Fonts Formula Generation Architecture Plan

## Problem Statement

We need to merge data from two sources to create complete Fontist formulas for Google Fonts:

1. **Google Fonts GitHub Repository** (local checkout of https://github.com/google/fonts)
   - METADATA.pb files (font metadata from protobuf)
   - License files (OFL.txt, LICENSE.txt, etc.)
   - Description files (DESCRIPTION.en_us.html)
   - upstream.yaml (repository URLs)
   - Actual font files (for parsing with Otf::FontFile)

2. **Google Fonts API** (3 endpoints via HTTPS)
   - TTF endpoint: Standard font file URLs
   - VF endpoint: Variable font URLs + axes data
   - WOFF2 endpoint: WOFF2 format URLs

**Goal**: Create a clean architecture that merges both sources and generates Fontist formulas with complete information.

## Current Architecture Analysis

### Existing Components

**API Side** (Already Implemented):
```
lib/fontist/import/google/
├── models/
│   ├── font_family.rb     # API data model
│   ├── font_variant.rb    # Variant with URL
│   └── axis.rb            # VF axes
├── clients/
│   ├── ttf_client.rb      # Fetches TTF URLs
│   ├── vf_client.rb       # Fetches VF URLs + axes
│   └── woff2_client.rb    # Fetches WOFF2 URLs
├── font_database.rb       # Merges 3 API endpoints
└── api.rb                 # Facade
```

**GitHub Repo Side** (Existing):
```
lib/fontist/import/
├── google_fonts_importer.rb   # Reads local repo
├── google/
│   └── metadata_parser.rb     # Parses METADATA.pb
├── otf/
│   └── font_file.rb           # Parses OTF/TTF files
└── formula_builder.rb         # Builds formulas
```

### Data Flow Issues

**Problem**: Two separate pipelines with no integration
- API pipeline: API → Clients → FontDatabase → Api
- GitHub pipeline: Local repo → GoogleFontsImporter → FormulaBuilder

**Missing**: A unified layer that merges both sources before formula generation.

## Proposed Architecture

### Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    Formula Generation                        │
│                  (FormulaGenerator)                          │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
              ┌──────────────────┐
              │  FontDatabase    │
              │  (API + GitHub)  │
              │  Unified Source  │
              └──────────────────┘
                       ▲
                       │
            ┌──────────┴──────────┐
            │                     │
            ▼                     ▼
┌────────────────────┐   ┌──────────────────┐
│   API Clients      │   │ GitHubRepoClient │
│  (TTF, VF, WOFF2)  │   │ (reads local)    │
└────────────────────┘   └──────────────────┘
         │                        │
         ▼                        ▼
┌─────────────────────┐   ┌───────────────────┐
│  Google Fonts API   │   │  GitHub Repo      │
│  (3 endpoints)      │   │  (local checkout) │
└─────────────────────┘   └───────────────────┘
```

### Proposed Layers

#### 1. Clients Layer Enhancement

**Add GitHubRepoClient** at `lib/fontist/import/google/clients/github_repo_client.rb`:

```ruby
module Fontist
  module Import
    module Google
      module Clients
        # Client for reading Google Fonts GitHub repository
        class GitHubRepoClient
          attr_reader :source_path

          def initialize(source_path:)
            @source_path = source_path
            validate!
          end

          # Fetch all font families from local repo
          def fetch
            list_all_fonts.map do |family_name|
              fetch_family(family_name)
            end
          end

          # Fetch specific font family
          def fetch_family(family_name)
            font_dir = find_font_directory(family_name)
            return nil unless font_dir

            parse_family_data(font_dir)
          end

          private

          def parse_family_data(font_dir)
            metadata = parse_metadata(font_dir)

            GitHubFontFamily.new(
              family: metadata.name,
              designer: metadata.designer,
              license: metadata.license,
              license_text: read_license(font_dir),
              description: read_description(font_dir),
              homepage: read_homepage(font_dir),
              font_files: parse_font_files(font_dir, metadata),
              metadata_pb_path: File.join(font_dir, "METADATA.pb")
            )
          end

          def parse_font_files(font_dir, metadata)
            metadata.font_files.map do |font_info|
              file_path = File.join(font_dir, font_info[:filename])

              {
                filename: font_info[:filename],
                path: file_path,
                otf_data: Otf::FontFile.new(file_path),
                github_url: github_raw_url(file_path)
              }
            end
          end

          def github_raw_url(local_path)
            relative = local_path.sub("#{@source_path}/", "")
            "https://raw.githubusercontent.com/google/fonts/main/#{relative}"
          end

          # ... helper methods
        end
      end
    end
  end
end
```

**Create GitHubFontFamily model** at `lib/fontist/import/google/models/github_font_family.rb`:

```ruby
module Fontist
  module Import
    module Google
      module Models
        # Represents font family data from GitHub repository
        class GitHubFontFamily < Lutaml::Model::Serializable
          attribute :family, :string
          attribute :designer, :string
          attribute :license, :string
          attribute :license_text, :string
          attribute :description, :string
          attribute :homepage, :string
          attribute :metadata_pb_path, :string
          attribute :font_files, :string, collection: true  # Array of hashes

          def to_h
            # Convert to hash for merging
          end
        end
      end
    end
  end
end
```

#### 2. FontDatabase Layer (Refactored)

**Refactor FontDatabase** at `lib/fontist/import/google/font_database.rb`:

```ruby
module Fontist
  module Import
    module Google
      # Unified database merging API data and GitHub repository data
      class FontDatabase
        attr_reader :api_database, :github_data

        def initialize(api_database:, github_client:)
          @api_database = api_database
          @github_client = github_client
          @github_data = index_github_data
          @merged_families = merge_all_data
        end

        # Returns enhanced font families with both API and GitHub data
        def all_fonts
          @merged_families.values
        end

        # Find specific family
        def font_by_name(family_name)
          @merged_families[family_name]
        end

        # Generate formula for a family
        def to_formula(family_name)
          family = font_by_name(family_name)
          return nil unless family

          FormulaGenerator.new(family).generate
        end

        # Generate all formulas
        def to_formulas
          all_fonts.map { |family| to_formula(family.family) }
        end

        private

        def index_github_data
          # Fetch and index by family name
          @github_client.fetch.each_with_object({}) do |gh_family, hash|
            hash[gh_family.family] = gh_family
          end
        end

        def merge_all_data
          merged = {}

          # Start with API data as base
          @api_database.all_fonts.each do |api_family|
            merged[api_family.family] = merge_family_data(
              api_family,
              @github_data[api_family.family]
            )
          end

          # Add GitHub-only families (if any)
          @github_data.each do |family_name, gh_family|
            next if merged.key?(family_name)

            merged[family_name] = merge_family_data(nil, gh_family)
          end

          merged
        end

        def merge_family_data(api_family, gh_family)
          EnhancedFontFamily.new(
            # API data
            family: api_family&.family || gh_family.family,
            category: api_family&.category,
            subsets: api_family&.subsets || [],
            version: api_family&.version,
            last_modified: api_family&.last_modified,
            axes: api_family&.axes || [],

            # GitHub data
            designer: gh_family&.designer,
            license: gh_family&.license,
            license_text: gh_family&.license_text,
            description: gh_family&.description,
            homepage: gh_family&.homepage,

            # Merged file data
            font_files: merge_font_files(api_family, gh_family),

            # Sources
            api_data: api_family,
            github_data: gh_family
          )
        end

        def merge_font_files(api_family, gh_family)
          # Merge file information from both sources
          # - URLs from API
          # - OTF data from GitHub repo
          # - GitHub raw URLs as fallback

          files = {}

          # Process API files
          api_family&.files&.each do |variant, url|
            files[variant] = {
              variant: variant,
              ttf_url: url,
              format: :ttf
            }
          end

          # Add WOFF2 URLs
          if api_family
            woff2_files = @api_database.woff2_files_for(api_family.family)
            woff2_files&.each do |variant, url|
              files[variant] ||= { variant: variant }
              files[variant][:woff2_url] = url
            end
          end

          # Add GitHub data (OTF info, github URLs)
          gh_family&.font_files&.each do |gh_file|
            variant = determine_variant(gh_file)
            files[variant] ||= { variant: variant }
            files[variant].merge!(
              filename: gh_file[:filename],
              github_url: gh_file[:github_url],
              otf_data: gh_file[:otf_data],
              local_path: gh_file[:path]
            )
          end

          files.values
        end

        def determine_variant(gh_file)
          # Extract variant name from filename or OTF data
          # e.g., "Roboto-Bold.ttf" → "Bold"
        end
      end
    end
  end
end
```

**Refactor FontFamily model** at `lib/fontist/import/google/models/font_family.rb`:

```ruby
module Fontist
  module Import
    module Google
      module Models
        # Font family with both API and GitHub data
        class FontFamily < Lutaml::Model::Serializable
          # From API
          attribute :family, :string
          attribute :category, :string
          attribute :subsets, :string, collection: true
          attribute :version, :string
          attribute :last_modified, :string
          attribute :axes, Axis, collection: true

          # From GitHub
          attribute :designer, :string
          attribute :license, :string
          attribute :license_text, :string
          attribute :description, :string
          attribute :homepage, :string

          # Merged
          attribute :font_files, :string, collection: true  # Enhanced file data

          # Source tracking (for debugging/reference)
          attribute :has_api_data, :boolean
          attribute :has_github_data, :boolean

          def variable_font?
            axes && !axes.empty?
          end

          def has_github_data?
            !github_data.nil?
          end

          def has_api_data?
            !api_data.nil?
          end
        end
      end
    end
  end
end
```

#### 3. Formula Generation Layer

**Create FormulaGenerator** at `lib/fontist/import/google/formula_generator.rb`:

```ruby
module Fontist
  module Import
    module Google
      # Generates Fontist formula from FontFamily
      class FormulaGenerator
        def initialize(font_family)
          @family = font_family
        end

        def generate
          {
            name: formula_name,
            description: @family.description,
            homepage: @family.homepage || default_homepage,
            resources: generate_resources,
            fonts: generate_fonts,
            extract: generate_extract_operations,
            copyright: @family.license_text,
            license_url: license_url,
            open_license: open_license?
          }
        end

        def save(output_dir)
          formula_path = File.join(output_dir, "#{formula_name}.yml")
          File.write(formula_path, YAML.dump(generate))
          formula_path
        end

        private

        def formula_name
          @family.family.downcase.gsub(/\s+/, '_')
        end

        def generate_resources
          # Build resource hash with URLs from API
          primary_files = {}

          @family.font_files.each do |file|
            primary_files[file[:filename]] = {
              urls: [
                file[:ttf_url],        # From API TTF endpoint
                file[:github_url]      # From GitHub as fallback
              ].compact
            }
          end

          primary_files
        end

        def generate_fonts
          # Group files by font name
          fonts_by_name = @family.font_files.group_by do |file|
            file[:otf_data]&.font_name || extract_name_from_filename(file[:filename])
          end

          fonts_by_name.map do |font_name, files|
            {
              name: font_name,
              styles: files.map { |f| generate_style(f) }
            }
          end
        end

        def generate_style(file)
          otf = file[:otf_data]

          style = {
            family_name: otf&.family_name || @family.family,
            type: otf&.type || extract_type_from_filename(file[:filename]),
            full_name: otf&.full_name,
            post_script_name: otf&.post_script_name,
            version: otf&.version || @family.version,
            description: otf&.description,
            font: file[:filename]
          }

          # Add variable font axes if present
          if @family.variable_font? && file[:format] == :vf
            style[:axes] = @family.axes.map do |axis|
              {
                tag: axis.tag,
                min: axis.start,
                max: axis.end
              }
            end
          end

          style
        end

        def generate_extract_operations
          # No extraction needed for Google Fonts (direct download)
          nil
        end

        def default_homepage
          "https://fonts.google.com/specimen/#{@family.family.gsub(/\s+/, '+')}"
        end

        def license_url
          case @family.license
          when /OFL/i
            "https://scripts.sil.org/OFL"
          when /Apache/i
            "https://www.apache.org/licenses/LICENSE-2.0"
          else
            nil
          end
        end

        def open_license?
          @family.license =~ /(OFL|Apache|UFL)/i
        end
      end
    end
  end
end
```

#### 4. Updated API Facade

**Extend Api class** at `lib/fontist/import/google/api.rb`:

```ruby
module Fontist
  module Import
    module Google
      class Api
        class << self
          # Existing methods...

          # NEW: Enhanced database with GitHub data
          def enhanced_database(source_path:)
            @enhanced_database ||= build_enhanced_database(source_path)
          end

          # NEW: Generate formulas
          def generate_formulas(source_path:, output_dir:, font_family: nil)
            db = enhanced_database(source_path: source_path)

            if font_family
              generate_single_formula(db, font_family, output_dir)
            else
              generate_all_formulas(db, output_dir)
            end
          end

          private

          def build_enhanced_database(source_path)
            github_client = Clients::GitHubRepoClient.new(source_path: source_path)

            EnhancedFontDatabase.new(
              api_database: database,
              github_client: github_client
            )
          end

          def generate_single_formula(db, family_name, output_dir)
            formula = db.to_formula(family_name)
            return nil unless formula

            FormulaGenerator.new(formula).save(output_dir)
          end

          def generate_all_formulas(db, output_dir)
            db.all_fonts.map do |family|
              generate_single_formula(db, family.family, output_dir)
            end.compact
          end
        end
      end
    end
  end
end
```

## Implementation Plan

### Phase 1: Clients Layer Extension
1. Create `GitHubRepoClient` class
2. Create `GitHubFontFamily` model
3. Write tests for GitHub repo reading
4. Ensure backward compatibility with existing `GoogleFontsImporter`

### Phase 2: Enhanced Database Layer
1. Create `EnhancedFontFamily` model
2. Create `EnhancedFontDatabase` class
3. Implement data merging logic
4. Write comprehensive tests for merging

### Phase 3: Formula Generation
1. Create `FormulaGenerator` class
2. Implement `to_formula` method
3. Handle variable fonts axes in formulas
4. Write tests with real data

### Phase 4: API Integration
1. Extend `Api` facade with enhanced methods
2. Update CLI to use new architecture
3. Write integration tests
4. Update documentation

### Phase 5: Migration
1. Deprecate old `GoogleFontsImporter`
2. Update existing importers to use new architecture
3. Migrate GitHub Actions workflows
4. Update README with new workflow

## Usage Examples

### Generate Single Formula

```ruby
require 'fontist/import/google/api'

# Generate formula for Roboto
Fontist::Import::Google::Api.generate_formulas(
  source_path: '/path/to/google/fonts',
  output_dir: '~/.fontist/formulas/Formulas/google',
  font_family: 'Roboto'
)
```

### Generate All Formulas

```ruby
# Generate all formulas
Fontist::Import::Google::Api.generate_formulas(
  source_path: '/path/to/google/fonts',
  output_dir: '~/.fontist/formulas/Formulas/google'
)
```

### Access Unified Data

```ruby
# Get database with both API and GitHub data
db = Fontist::Import::Google::Api.database(
  source_path: '/path/to/google/fonts'
)

# Get specific font with all data
roboto = db.font_by_name('Roboto')
puts roboto.designer          # From GitHub
puts roboto.license_text      # From GitHub
puts roboto.axes.count        # From API (VF endpoint)
puts roboto.font_files.first[:ttf_url]    # From API
puts roboto.font_files.first[:woff2_url]  # From API
puts roboto.font_files.first[:github_url] # From GitHub
```

## Advantages of This Architecture

1. **Clean Separation**: Each layer has a single responsibility
   - Clients: Fetch data from sources
   - Database: Merge and query
   - Generator: Transform to formula format

2. **Reusability**: Components can be used independently
   - Use API data without GitHub
   - Use GitHub data without API
   - Generate formulas from any source

3. **Testability**: Each layer can be tested in isolation
   - Mock API responses
   - Mock GitHub repo structure
   - Test formula generation separately

4. **Extensibility**: Easy to add new sources
   - Add new clients (e.g., font CDN)
   - Extend merging logic
   - Customize formula generation

5. **Backward Compatible**: Existing code continues to work
   - Old `GoogleFontsImporter` still functions
   - Gradual migration path
   - No breaking changes

## Migration from Current Importer

The new architecture is designed to eventually replace `GoogleFontsImporter`:

**Old way:**
```ruby
importer = GoogleFontsImporter.new(
  source_path: '/path/to/google/fonts',
  output_path: './formulas'
)
importer.import
```

**New way:**
```ruby
Fontist::Import::Google::Api.generate_formulas(
  source_path: '/path/to/google/fonts',
  output_dir: './formulas'
)
```

**Benefits of new way:**
- Access to API data (multiple formats, axes)
- Better error handling
- More complete formulas
- Unified architecture

## Next Steps

1. Review and approve this architecture plan
2. Implement Phase 1 (GitHubRepoClient)
3. Verify data merging works correctly
4. Implement formula generation
5. Test with real Google Fonts data
6. Update documentation and workflows