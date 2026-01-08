# Google Fonts Multi-Format Integration - Final Architecture

## Summary

This document provides the final architecture plan for Google Fonts integration in Fontist, supporting multiple formats (TTF, VF, WOFF2) and formula generation from merged API + GitHub repository data.

## Architecture Overview

### Clean Separation of Concerns

```
                    ┌──────────────────────┐
                    │  FormulaImporter     │ ← High-level entry point
                    │  (Orchestrator)      │ ← Formula generation workflow
                    └──────────┬───────────┘
                               │
                               ▼
                    ┌──────────────────────┐
                    │     Database         │ ← Universal data merger
                    │  (Factory Pattern)   │ ← Builds from any sources
                    └──────────┬───────────┘
                               │
            ┌──────────────────┼──────────────────┐
            │                  │                  │
            ▼                  ▼                  ▼
    ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
    │     Api      │  │   Clients    │  │FormulaGenerator│
    │  (API only)  │  │ (4 types)    │  │              │
    └──────────────┘  └──────────────┘  └──────────────┘
```

### Four Core Components

#### 1. Api (API Operations Only)
**Purpose**: Access Google Fonts API data
**Scope**: 3 API endpoints (TTF, VF, WOFF2)
**Location**: [`lib/fontist/import/google/api.rb`](../lib/fontist/import/google/api.rb)

```ruby
# Always returns API-only data
Fontist::Import::Google::Api.items
Fontist::Import::Google::Api.database
Fontist::Import::Google::Api.variable_fonts_only
```

#### 2. GitHubRepoClient (GitHub Operations Only)
**Purpose**: Read Google Fonts GitHub repository
**Scope**: Local filesystem, METADATA.pb, licenses
**Location**: `lib/fontist/import/google/clients/github_repo_client.rb` (NEW)

```ruby
# Always reads from local filesystem
client = GitHubRepoClient.new(source_path: '/path/to/google/fonts')
client.fetch  # All families
client.fetch_family('Roboto')  # Single family
```

#### 3. Database (Universal Merger)
**Purpose**: Merge data from any combination of sources
**Scope**: API data + optional GitHub data
**Location**: `lib/fontist/import/google/database.rb` (REFACTOR from font_database.rb)

```ruby
# API only (current behavior)
db = Database.build_from_api(
  ttf_client: ttf, vf_client: vf, woff2_client: woff2
)

# API + GitHub (new behavior)
db = Database.build_from_all_sources(
  api_key: 'key',
  source_path: '/path/to/repo'
)

# Formula generation
formula = db.to_formula('Roboto')
```

#### 4. FormulaImporter (Workflow Orchestrator)
**Purpose**: High-level interface for formula generation
**Scope**: Complete workflow from sources to formulas
**Location**: `lib/fontist/import/google/formula_importer.rb` (NEW)

```ruby
# Generate formulas - simple, clear API
Fontist::Import::Google::FormulaImporter.generate(
  source_path: '/path/to/google/fonts',
  output_dir: './formulas',
  font_family: 'Roboto'  # optional
)
```

## Component Interactions

### Data Sources

**Google Fonts API (3 endpoints):**
- TTF: Font URLs for TrueType format
- VF: Variable font URLs + axes data
- WOFF2: Font URLs for WOFF2 format

**GitHub Repository (local):**
- METADATA.pb: Font metadata (protobuf)
- License files: OFL.txt, LICENSE.txt, etc.
- Description files: DESCRIPTION.en_us.html
- upstream.yaml: Repository URLs
- Font files: For OTF parsing

### Data Flow

```
┌─────────────────────┐    ┌──────────────────────────┐
│   Google Fonts API  │    │  Google Fonts GitHub     │
│   (3 endpoints)     │    │  Repository (local)      │
└──────────┬──────────┘    └──────────┬───────────────┘
           │                          │
           ▼                          ▼
    ┌──────────────┐         ┌──────────────────┐
    │ TtfClient    │         │ GitHubRepoClient │
    │ VfClient     │         │                  │
    │ Woff2Client  │         │                  │
    └──────┬───────┘         └────────┬─────────┘
           │                          │
           └────────────┬─────────────┘
                        ▼
                 ┌─────────────┐
                 │  Database   │
                 │  (merger)   │
                 └──────┬──────┘
                        │
                        ▼
                ┌───────────────┐
                │FontFamily     │
                │ (unified)     │
                │- API data     │
                │- GitHub data  │
                └───────┬───────┘
                        │
                        ▼
                ┌───────────────┐
                │FormulaGenerator│
                └───────┬───────┘
                        │
                        ▼
                  Formula YAML
```

## Implementation Plan

### Phase 1: Add GitHub Client (NEW)
- [ ] Create `GitHubRepoClient` class
- [ ] Create `GitHubFontFamily` model
- [ ] Parse METADATA.pb files
- [ ] Read licenses, descriptions, homepages
- [ ] Parse font files with Otf::FontFile
- [ ] Write comprehensive tests

### Phase 2: Extend FontFamily Model
- [ ] Add GitHub-specific attributes (designer, license_text, description, homepage)
- [ ] Add font_file_data attribute (for OTF parsing info)
- [ ] Update tests

### Phase 3: Refactor Database (RENAME + EXTEND)
- [ ] Rename from `font_database.rb` to `database.rb`
- [ ] Add factory methods: `build_from_api`, `build_from_all_sources`
- [ ] Extend merge logic to include GitHub data
- [ ] Add `to_formula(name)` and `to_formulas` methods
- [ ] Update all tests

### Phase 4: Create Formula Generator
- [ ] Create `FormulaGenerator` class
- [ ] Implement formula YAML generation
- [ ] Handle variable font axes in formulas
- [ ] Handle multiple file formats
- [ ] Write comprehensive tests

### Phase 5: Create Formula Importer
- [ ] Create `FormulaImporter` high-level class
- [ ] Implement `generate` workflow
- [ ] Add progress reporting
- [ ] Add error handling
- [ ] Write integration tests

### Phase 6: Integration
- [ ] Update `Api` class (ensure api-only behavior)
- [ ] Update CLI to use `FormulaImporter`
- [ ] Update existing tests
- [ ] Run full test suite

### Phase 7: Documentation
- [ ] Update README with new workflow
- [ ] Add usage examples
- [ ] Migration guide from old importer
- [ ] Architecture diagrams

## File Structure

```
lib/fontist/import/google/
├── api.rb                    # API operations only (UNCHANGED)
├── database.rb               # Universal merger (RENAMED from font_database.rb)
├── formula_importer.rb       # NEW: High-level orchestrator
├── formula_generator.rb      # NEW: Formula builder
├── metadata_parser.rb        # EXISTING: METADATA.pb parser
├── models/
│   ├── font_family.rb       # EXTENDED: Add GitHub fields
│   ├── font_variant.rb      # EXISTING
│   ├── axis.rb              # EXISTING
│   └── github_font_family.rb  # NEW: GitHub data model
└── clients/
    ├── api_endpoint.rb      # EXISTING: Base for API clients
    ├── ttf_client.rb        # EXISTING
    ├── vf_client.rb         # EXISTING
    ├── woff2_client.rb      # EXISTING
    └── github_repo_client.rb  # NEW: Reads local repo
```

## API Examples

### API Only (Current - Unchanged)

```ruby
# Get all fonts from API
families = Fontist::Import::Google::Api.items

# Filter variable fonts
<br>vf = Fontist::Import::Google::Api.variable_fonts_only

# Find specific font
roboto = Fontist::Import::Google::Api.font_by_name('Roboto')
```

### GitHub Only (New)

```ruby
# Read from local repository
client = Fontist::Import::Google::Clients::GitHubRepoClient.new(
  source_path: '/path/to/google/fonts'
)

# Get all families
families = client.fetch

# Get specific family
roboto_gh = client.fetch_family('Roboto')
puts roboto_gh.designer
puts roboto_gh.license_text
```

### Combined Database (New)

```ruby
# Build database from all sources
db = Fontist::Import::Google::Database.build_from_all_sources(
  api_key: 'your-key',
  source_path: '/path/to/google/fonts'
)

# Query unified data
roboto = db.font_by_name('Roboto')
puts roboto.designer          # From GitHub
puts roboto.axes.count        # From API (VF endpoint)
puts roboto.files['regular']  # URLs from API

# Generate formula
formula = db.to_formula('Roboto')
File.write('roboto.yml', YAML.dump(formula))
```

### Formula Generation (New - Simplest)

```ruby
# One-liner for formula generation
Fontist::Import::Google::FormulaImporter.generate(
  source_path: '/path/to/google/fonts',
  output_dir: './formulas'
)

# Single font
Fontist::Import::Google::FormulaImporter.generate(
  source_path: '/path/to/google/fonts',
  output_dir: './formulas',
  font_family: 'Roboto'
)
```

## CLI Usage

### Current Command (to be updated)

```bash
fontist import google \
  --source-path /path/to/google/fonts \
  --output-path ./formulas \
  --verbose
```

This will now use the new `FormulaImporter` internally!

## Why This Architecture Is Clean

### 1. Single Responsibility Principle
- `Api`: API operations
- `GitHubRepoClient`: GitHub operations
- `Database`: Data merging
- `FormulaImporter`: Workflow orchestration
- `FormulaGenerator`: Formula building

### 2. No Parameter Overloading
```ruby
# BAD (what we're avoiding)
Api.database(source_path: nil)  # Returns different types!

# GOOD (what we're doing)
Api.database                    # Always API data
Database.build_from_api(...)    # Explicitly API
Database.build_from_all_sources(...)  # Explicitly combined
```

### 3. Clear Intent

```ruby
# API data
Api.items

# GitHub data
GitHubRepoClient.new(...).fetch

# Combined
Database.build_from_all_sources(...)

# Formula generation
FormulaImporter.generate(...)
```

### 4. Easy Testing
- Mock API responses → test Api
- Mock filesystem → test GitHubRepoClient
- Mock both → test Database
- Mock Database → test FormulaImporter

### 5. Flexible Composition
Users can:
- Use API data alone
- Use GitHub data alone
- Combine as needed
- Generate formulas easily

## Next Steps

1. Review and approve this clean architecture
2. Implement Phase 1 (GitHubRepoClient)
3. Implement Phase 2-7 sequentially
4. Full integration testing
5. Documentation updates

## Key Decision: Namespace Clarity

✅ **`Api`** = API operations only
✅ **`Database`** = Universal data container
✅ **`FormulaImporter`** = Formula generation workflow
✅ **No ambiguous parameters** = Each method has one clear purpose

This architecture eliminates the "weird" parameter pattern and provides clear, unambiguous interfaces for all operations!