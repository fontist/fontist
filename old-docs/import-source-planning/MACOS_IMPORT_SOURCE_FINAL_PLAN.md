# macOS Import Source Architecture - Final Plan

**Date**: 2025-12-26
**Status**: Final Architecture - Ready for Implementation
**Complexity**: High
**Architecture**: Polymorphic import source classes with proper OOP

---

## Executive Summary

Based on user feedback, the architecture uses:
1. **`import_source` attribute** with polymorphic classes (MacosImportSource, GoogleImportSource)
2. **Directory structure**: `{import_source}/{name}_{differentiation_key}.yml`
3. **Manual formulas**: No import_source (nil)
4. **Version tracking**: Posted_date for macOS, git commit + API version for Google

---

## Revised Architecture

### Model Hierarchy

```
Formula
  ├─ name: string
  ├─ description: string
  ├─ resources: ResourceCollection
  ├─ fonts: FontCollection
  ├─ platforms: Array<string>
  ├─ catalog_version: integer (for platform compatibility)
  ├─ min_macos_version: string (for platform compatibility)
  ├─ max_macos_version: string (for platform compatibility)
  └─ import_source: ImportSource (polymorphic, nil for manual)
       │
       ├─ MacosImportSource
       │    └─ catalog_version: integer   # Framework version (7, 8)
       │    │
       │    └─ posted_date: string (ISO 8601)  # Catalog version within framework
       │    │
       │    └─ asset_id: string (Build, e.g., "10m1360")
       │
       ├─ GoogleImportSource
       │    ├─ commit_id: string (from google/fonts repo)
       │    ├─ api_version: string (e.g., "v1")
       │    ├─ last_modified: string (ISO 8601)
       │    └─ family_id: string (for differentiation)
       │
       └─ SilImportSource
            ├─ version: string
            └─ release_date: string
```

### Polymorphic Type Discrimination

Using Lutaml::Model's discriminator support:

```yaml
import_source:
  type: macos  # discriminator field
  posted_date: "2024-08-13T18:11:00Z"
  asset_id: "10m1360"
  catalog_version: 7
```

---

## Directory Structure

### Formula File Naming

```
formulas/
├── macos/                                    # Import source directory
│   ├── al_bayan_10m1360.yml                 # {name}_{asset_id}.yml
│   ├── al_bayan_10m1044.yml                 # Different version
│   └── adobe_arabic_10m1360.yml
├── google/                                   # Import source directory
│   ├── roboto_20241201abc123.yml            # {name}_{commit_id_short}.yml
│   ├── open_sans_20241115def456.yml
│   └── noto_sans_20241201abc123.yml
├── sil/                                      # Import source directory
│   ├── charis_6_200.yml                     # {name}_{version}.yml
│   └── gentium_6_101.yml
└── manual/                                   # Manual formulas (no import_source)
    ├── arial.yml                            # {name}.yml (no differentiation key)
    └── helvetica.yml
```

---

## Implementation Plan

### Phase 1: Create Import Source Models

#### 1.1 Create Base Import Source
**File**: `lib/fontist/import_source.rb` (NEW)

```ruby
require "lutaml/model"

module Fontist
  # Base class for import source tracking
  # Uses polymorphic deserialization via type discriminator
  class ImportSource < Lutaml::Model::Serializable
    # Type discriminator for polymorphism
    attribute :type, :string

    key_value do
      map "type", to: :type
    end

    # Factory method to create appropriate subclass from hash
    def self.from_hash(hash)
      return nil unless hash

      case hash["type"] || hash[:type]
      when "macos"
        MacosImportSource.from_hash(hash)
      when "google"
        GoogleImportSource.from_hash(hash)
      when "sil"
        SilImportSource.from_hash(hash)
      else
        raise "Unknown import source type: #{hash['type']}"
      end
    end

    # Each subclass implements differentiation_key
    def differentiation_key
      raise NotImplementedError, "Subclasses must implement differentiation_key"
    end

    # Check if this source is outdated
    def outdated?(new_source)
      raise NotImplementedError, "Subclasses must implement outdated?"
    end
  end
end
```

#### 1.2 Create MacosImportSource
**File**: `lib/fontist/macos_import_source.rb` (NEW)

```ruby
require_relative "import_source"

module Fontist
  # macOS MobileAsset Import Source
  #
  # Three versioning dimensions:
  # 1. Framework Version (Font7, Font8) - stored in Formula.catalog_version
  #    - Like Google's API version
  #    - Different schemas/parsers
  #    - Determines directory structure
  # 2. Catalog PostedDate - version of catalog within framework
  #    - Updates to font packages in that framework
  #    - Multiple catalogs can exist per framework
  # 3. Asset Build - individual font package version
  #    - Per-font identifier (e.g., "10M1360")
  class MacosImportSource < ImportSource
    attribute :posted_date, :string      # Catalog version: "2024-08-13T18:11:00Z"
    attribute :asset_id, :string         # Package build: "10m1360"
    # Note: framework_version (7, 8) stored in Formula.catalog_version

    key_value do
      map "type", to: :type, default: -> { "macos" }
      map "posted_date", to: :posted_date
      map "asset_id", to: :asset_id
    end

    # Returns the asset_id for filename differentiation
    def differentiation_key
      asset_id&.downcase
    end

    # Check if this macOS source is outdated by comparing posted_date
    # (catalog version within same framework)
    def outdated?(new_source)
      return false unless new_source.is_a?(MacosImportSource)
      return false unless posted_date && new_source.posted_date

      Time.parse(posted_date) < Time.parse(new_source.posted_date)
    rescue StandardError
      false
    end

    def to_s
      "macOS (posted: #{posted_date}, asset: #{asset_id})"
    end
  end
end
```

#### 1.3 Create GoogleImportSource
**File**: `lib/fontist/google_import_source.rb` (NEW)

```ruby
require_relative "import_source"

module Fontist
  class GoogleImportSource < ImportSource
    attribute :commit_id, :string        # Full git commit SHA from google/fonts
    attribute :api_version, :string      # e.g., "v1"
    attribute :last_modified, :string    # ISO 8601 from API
    attribute :family_id, :string        # For differentiation (optional)

    key_value do
      map "type", to: :type, default: -> { "google" }
      map "commit_id", to: :commit_id
      map "api_version", to: :api_version
      map "last_modified", to: :last_modified
      map "family_id", to: :family_id
    end

    # Returns short commit ID for filename differentiation
    def differentiation_key
      commit_id ? commit_id[0..7] : nil
    end

    # Check if this Google source is outdated
    def outdated?(new_source)
      return false unless new_source.is_a?(GoogleImportSource)
      return false unless commit_id && new_source.commit_id

      # Simple string comparison (lexicographic)
      # Could be enhanced with actual git commit time comparison
      commit_id != new_source.commit_id
    end

    def to_s
      "Google Fonts (commit: #{commit_id ? commit_id[0..7] : 'unknown'}, API: #{api_version})"
    end
  end
end
```

#### 1.4 Create SilImportSource
**File**: `lib/fontist/sil_import_source.rb` (NEW)

```ruby
require_relative "import_source"

module Fontist
  class SilImportSource < ImportSource
    attribute :version, :string          # e.g., "6.200"
    attribute :release_date, :string     # ISO 8601

    key_value do
      map "type", to: :type, default: -> { "sil" }
      map "version", to: :version
      map "release_date", to: :release_date
    end

    # Returns version for filename differentiation
    def differentiation_key
      version&.gsub(".", "_")  # "6.200" -> "6_200"
    end

    # Check if this SIL source is outdated
    def outdated?(new_source)
      return false unless new_source.is_a?(SilImportSource)
      return false unless version && new_source.version

      # Simple version string comparison
      version != new_source.version
    end

    def to_s
      "SIL (version: #{version})"
    end
  end
end
```

---

### Phase 2: Update Formula Model

#### 2.1 Add import_source Attribute
**File**: `lib/fontist/formula.rb`

**Add attribute** (after line 76):
```ruby
attribute :import_source, ImportSource
```

**Add key_value mapping** (after line 103):
```ruby
map "import_source", to: :import_source
```

**Add convenience methods**:
```ruby
# Check if formula is from macOS import
def macos_import?
  import_source.is_a?(MacosImportSource)
end

# Check if formula is from Google Fonts import
def google_import?
  import_source.is_a?(GoogleImportSource)
end

# Check if formula is from SIL import
def sil_import?
  import_source.is_a?(SilImportSource)
end

# Check if formula was manually created (no import source)
def manual_formula?
  import_source.nil?
end

# Get import source directory name
def import_source_dir
  return "manual" if manual_formula?

  case import_source
  when MacosImportSource
    "macos"
  when GoogleImportSource
    "google"
  when SilImportSource
    "sil"
  else
    "manual"
  end
end

# Get differentiation key for filename
def import_differentiation_key
  import_source&.differentiation_key
end

# Check if import source is outdated
def import_outdated?(new_import_source)
  return false if manual_formula?
  return false unless import_source

  import_source.outdated?(new_import_source)
end
```

---

### Phase 3: Update FormulaBuilder

#### 3.1 Add Import Source Support
**File**: `lib/fontist/import/formula_builder.rb`

**Add to FORMULA_ATTRIBUTES**:
```ruby
FORMULA_ATTRIBUTES = %i[
  name
  description
  homepage
  resources
  fonts
  extract
  instructions
  options
  requires_license_agreement
  open_license
  license_url
  license_required
  copyright
  digest
  command
  catalog_version
  min_macos_version
  max_macos_version
  import_source    # NEW
].freeze
```

**Add attr_writer and getter**:
```ruby
attr_writer :catalog_version, :min_macos_version, :max_macos_version, :import_source

def import_source
  @import_source
end
```

**Add helper methods**:
```ruby
def set_macos_import_source(posted_date:, asset_id:, catalog_version:)
  @import_source = Fontist::MacosImportSource.new(
    posted_date: posted_date,
    asset_id: asset_id,
    catalog_version: catalog_version
  )
end

def set_google_import_source(commit_id:, api_version: "v1", last_modified: nil, family_id: nil)
  @import_source = Fontist::GoogleImportSource.new(
    commit_id: commit_id,
    api_version: api_version,
    last_modified: last_modified,
    family_id: family_id
  )
end

def set_sil_import_source(version:, release_date: nil)
  @import_source = Fontist::SilImportSource.new(
    version: version,
    release_date: release_date
  )
end
```

---

### Phase 4: Update CreateFormula

#### 4.1 Accept Import Source Parameter
**File**: `lib/fontist/import/create_formula.rb`

**Update constructor**:
```ruby
def initialize(url,
               options = {},
               archive_path: nil,
               formula_dir: nil,
               name: nil,
               skip_fonts: [],
               keep_existing: false,
               catalog_version: nil,
               min_macos_version: nil,
               max_macos_version: nil,
               import_source: nil)  # NEW: Accept ImportSource object
  @url = url
  @options = options
  @archive_path = archive_path
  @formula_dir = formula_dir
  @given_name = name
  @skip_fonts = skip_fonts
  @keep_existing = keep_existing
  @catalog_version = catalog_version
  @min_macos_version = min_macos_version
  @max_macos_version = max_macos_version
  @import_source = import_source  # NEW
end
```

**Pass to FormulaBuilder**:
```ruby
builder.catalog_version = @catalog_version if @catalog_version
builder.min_macos_version = @min_macos_version if @min_macos_version
builder.max_macos_version = @max_macos_version if @max_macos_version
builder.import_source = @import_source if @import_source  # NEW
```

---

### Phase 5: Update Catalog Parsers

#### 5.1 Extract PostedDate in BaseParser
**File**: `lib/fontist/macos/catalog/base_parser.rb`

```ruby
def posted_date
  date_str = data["postedDate"]
  return nil unless date_str

  Time.parse(date_str).utc.iso8601
rescue StandardError => e
  Fontist.ui.warn("Could not parse postedDate: #{e.message}")
  nil
end
```

**Update assets method**:
```ruby
def assets
  date = posted_date
  parse_assets.map { |asset_data| Asset.new(asset_data, posted_date: date) }
end
```

#### 5.2 Update Asset Class
**File**: `lib/fontist/macos/catalog/asset.rb`

```ruby
attr_reader :base_url, :relative_path, :font_info, :build,
            :compatibility_version, :design_languages, :prerequisite,
            :posted_date  # NEW

def initialize(data, posted_date: nil)
  @base_url = data["__BaseURL"]
  @relative_path = data["__RelativePath"]
  @font_info = data["FontInfo4"] || []
  @build = data["Build"]
  @compatibility_version = data["_CompatibilityVersion"]
  @design_languages = data["FontDesignLanguages"] || []
  @prerequisite = data["Prerequisite"] || []
  @posted_date = posted_date  # NEW
end

# Returns Build identifier (lowercased for filename)
def asset_id
  build&.downcase
end

# Create MacosImportSource for this asset
def to_import_source(catalog_version)
  Fontist::MacosImportSource.new(
    posted_date: posted_date,
    asset_id: asset_id,
    catalog_version: catalog_version
  )
end
```

---

### Phase 6: Update Macos Importer

#### 6.1 Build Import Source and Versioned Filenames
**File**: `lib/fontist/import/macos.rb`

**Update process_asset method**:
```ruby
def process_asset(asset, current, total)
  return if asset.fonts.empty?

  family_name = asset.primary_family_name || "Unknown"
  fonts_count = asset.fonts.size

  # Progress indicator
  progress = "(#{current}/#{total})"
  percentage = ((current.to_f / total) * 100).round(1)

  Fontist.ui.say("#{Paint[progress, :white]} #{Paint["#{percentage}%", :yellow]} | #{Paint[family_name, :cyan, :bright]} #{Paint["(#{fonts_count} font#{fonts_count > 1 ? 's' : ''})", :black, :bright]}")

  # Generate versioned filename
  expected_path = versioned_formula_path(asset, family_name)

  if expected_path && File.exist?(expected_path)
    if @force
      @overwritten_count += 1
      Fontist.ui.say("  #{Paint['⚠', :yellow]} Overwriting existing formula: #{Paint[File.basename(expected_path), :yellow]}")
    else
      @skipped_count += 1
      Fontist.ui.say("  #{Paint['⊝', :yellow]} Skipped (already exists): #{Paint[File.basename(expected_path), :black, :bright]}")
      Fontist.ui.say("    #{Paint['ℹ', :blue]} Use #{Paint['--force', :cyan]} to overwrite existing formulas")
      return
    end
  end

  start_time = Time.now

  # Create import source
  import_source = asset.to_import_source(@catalog_version)

  path = Fontist::Import::CreateFormula.new(
    asset.download_url,
    platforms: platforms,
    homepage: homepage,
    requires_license_agreement: license,
    formula_dir: formula_dir,
    keep_existing: !@force,
    catalog_version: @catalog_version,
    min_macos_version: catalog_version_range[:min],
    max_macos_version: catalog_version_range[:max],
    import_source: import_source  # NEW
  ).call

  elapsed = Time.now - start_time
  formula_name = File.basename(path)

  # Read the generated formula to show fonts/styles
  show_formula_fonts(path)

  @success_count += 1
  Fontist.ui.say("  #{Paint['✓', :green]} Formula created: #{Paint[formula_name, :white]} #{Paint["(#{elapsed.round(2)}s)", :black, :bright]}")
rescue StandardError => e
  @failure_count += 1
  error_msg = e.message.length > 60 ? "#{e.message[0..60]}..." : e.message
  Fontist.ui.say("  #{Paint['✗', :red]} Failed: #{Paint[error_msg, :red]}")
end
```

**Add versioned filename method**:
```ruby
def versioned_formula_path(asset, family_name)
  normalized_name = family_name.downcase.gsub(/[^a-z0-9]+/, '_')
  asset_id = asset.asset_id

  # Format: {import_source}/{name}_{differentiation_key}.yml
  filename = "#{normalized_name}_#{asset_id}.yml"
  formula_dir.join(filename)
rescue StandardError
  nil
end
```

**Update formula_dir** to use import source directory:
```ruby
def formula_dir
  @formula_dir ||= if @custom_formulas_dir
                     Pathname.new(@custom_formulas_dir).tap do |path|
                       FileUtils.mkdir_p(path)
                     end
                   else
                     # Use macos directory (import source)
                     base_dir = Fontist.formulas_path.join("macos")
                     base_dir.tap do |path|
                       FileUtils.mkdir_p(path)
                     end
                   end
end
```

---

### Phase 7: Google Fonts Version Investigation

#### 7.1 Research Google Fonts Versioning

**Current Google Fonts API Response**:
```json
{
  "family": "Roboto",
  "variants": ["regular", "700"],
  "subsets": ["latin"],
  "version": "v30",
  "lastModified": "2023-05-02",
  "files": {
    "regular": "https://fonts.gstatic.com/s/roboto/v30/..."
  }
}
```

**Google Fonts GitHub Repository**:
- Repo: https://github.com/google/fonts
- Each font has metadata in `ofl/{font}/METADATA.pb`
- Commit history shows when fonts were updated

**Recommended Approach**:
1. Use `version` field from API (e.g., "v30")
2. Fetch last commit SHA from google/fonts repo for specific font
3. Use `lastModified` as fallback
4. Differentiation key: commit SHA short (8 chars)

#### 7.2 Update Google Fonts Importer
**File**: `lib/fontist/import/google_fonts_importer.rb`

```ruby
def import_font(family_name)
  # Fetch from API
  api_data = fetch_api_data(family_name)

  # Fetch commit info from GitHub (optional but recommended)
  commit_id = fetch_github_commit(family_name)

  # Create import source
  import_source = Fontist::GoogleImportSource.new(
    commit_id: commit_id || SecureRandom.hex(20),  # fallback to random if GitHub fails
    api_version: extract_api_version(api_data["version"]),  # "v30" -> "v30"
    last_modified: api_data["lastModified"],
    family_id: family_name.downcase.gsub(/\s+/, '_')
  )

  Fontist::Import::CreateFormula.new(
    # ... existing parameters
    import_source: import_source
  ).call
end

private

def fetch_github_commit(family_name)
  # Use GitHub API to get last commit for font directory
  font_dir = family_name.downcase.gsub(/\s+/, '')
  github_api_url = "https://api.github.com/repos/google/fonts/commits?path=ofl/#{font_dir}"

  response = HTTP.get(github_api_url)
  commits = JSON.parse(response.body)
  commits.first["sha"] if commits&.first
rescue StandardError => e
  Fontist.ui.warn("Could not fetch GitHub commit: #{e.message}")
  nil
end
```

---

### Phase 8: Update SIL Importer

#### 8.1 Add Import Source
**File**: `lib/fontist/import/sil_import.rb`

```ruby
def import_font(font_data)
  # Extract version from SIL data
  version = font_data["version"]
  release_date = font_data["release_date"]

  import_source = Fontist::SilImportSource.new(
    version: version,
    release_date: release_date
  )

  Fontist::Import::CreateFormula.new(
    # ... existing parameters
    import_source: import_source
  ).call
end
```

---

### Phase 9: Testing

#### 9.1 Import Source Model Tests
**File**: `spec/fontist/macos_import_source_spec.rb` (NEW)

```ruby
RSpec.describe Fontist::MacosImportSource do
  describe "#differentiation_key" do
    it "returns lowercased asset_id" do
      source = described_class.new(
        posted_date: "2024-08-13T18:11:00Z",
        asset_id: "10M1360",
        catalog_version: 7
      )
      expect(source.differentiation_key).to eq("10m1360")
    end
  end

  describe "#outdated?" do
    it "detects outdated posted_date" do
      old_source = described_class.new(posted_date: "2024-01-01T00:00:00Z", asset_id: "10m1044", catalog_version: 7)
      new_source = described_class.new(posted_date: "2024-12-01T00:00:00Z", asset_id: "10m1360", catalog_version: 7)

      expect(old_source.outdated?(new_source)).to be true
    end

    it "returns false if dates equal" do
      date = "2024-12-01T00:00:00Z"
      source1 = described_class.new(posted_date: date, asset_id: "10m1360", catalog_version: 7)
      source2 = described_class.new(posted_date: date, asset_id: "10m1360", catalog_version: 7)

      expect(source1.outdated?(source2)).to be false
    end
  end

  describe "serialization" do
    it "serializes to YAML correctly" do
      source = described_class.new(
        posted_date: "2024-08-13T18:11:00Z",
        asset_id: "10m1360",
        catalog_version: 7
      )

      yaml = source.to_yaml
      expect(yaml).to include("type: macos")
      expect(yaml).to include("posted_date: 2024-08-13T18:11:00Z")
      expect(yaml).to include("asset_id: 10m1360")
    end
  end
end
```

#### 9.2 Formula Integration Tests
**File**: `spec/fontist/formula_spec.rb`

```ruby
describe "Import source support" do
  it "loads macOS import source from formula" do
    formula = Formula.from_file("macos/al_bayan_10m1360.yml")
    expect(formula.import_source).to be_a(MacosImportSource)
    expect(formula.import_source.posted_date).to eq("2024-08-13T18:11:00Z")
    expect(formula.import_source.asset_id).to eq("10m1360")
  end

  it "provides convenience methods" do
    formula = Formula.from_file("macos/al_bayan_10m1360.yml")
    expect(formula.macos_import?).to be true
    expect(formula.google_import?).to be false
    expect(formula.manual_formula?).to be false
    expect(formula.import_source_dir).to eq("macos")
    expect(formula.import_differentiation_key).to eq("10m1360")
  end

  it "handles manual formulas without import source" do
    formula = Formula.from_file("manual/arial.yml")
    expect(formula.import_source).to be_nil
    expect(formula.manual_formula?).to be true
    expect(formula.import_source_dir).to eq("manual")
  end
end
```

---

## Example Formulas After Implementation

### macOS Import Source

```yaml
---
name: Al Bayan
description: Al Bayan is an Arabic font...
homepage: https://support.apple.com/en-om/HT211240#document

# Framework version (Font7) - for platform compatibility & directory
catalog_version: 7
min_macos_version: "10.11"
max_macos_version: "15.7"
platforms:
  - macos-font7

# Import source tracking
# - Framework version (7) is at catalog_version above
# - posted_date is the catalog version within Font7 framework
# - asset_id is the package build identifier
import_source:
  type: macos
  posted_date: "2024-08-13T18:11:00Z"  # Catalog version
  asset_id: "10m1360"                   # Package build

resources:
  AlBayan_Font:
    urls:
      - https://mesu.apple.com/assets/.../AlBayan.pkg
    sha256: 558fac4e25f...
    file_size: 412345

fonts:
  - name: Al Bayan
    styles:
      - family_name: Al Bayan
        type: Plain
        post_script_name: AlBayan
        full_name: Al Bayan Plain
        version: "13.0d3e1"
```

**Filename**: `formulas/macos/font7/al_bayan_10m1360.yml`
**Directory**: Framework version determines subdirectory (font7/, font8/)
**Filename**: Asset ID provides differentiation

### Google Fonts Import Source

```yaml
---
name: Roboto
description: Roboto is a neo-grotesque sans-serif...
homepage: https://fonts.google.com/specimen/Roboto

# Import source tracking
import_source:
  type: google
  commit_id: "abc1234567890def1234567890abcdef12345678"
  api_version: "v30"
  last_modified: "2023-05-02"
  family_id: "roboto"

resources:
  # ... Google resources

fonts:
  # ... font styles
```

**Filename**: `formulas/google/roboto_abc12345.yml`

### Manual Formula (No Import Source)

```yaml
---
name: Arial
description: Arial is a sans-serif typeface...
homepage: https://www.microsoft.com/typography/fonts/family.aspx?FID=1

# No import_source (manual formula)

resources:
  # ... resources

fonts:
  # ... font styles
```

**Filename**: `formulas/manual/arial.yml`

---

## Directory Structure After Implementation

```
formulas/macos/
├── font7/                              # Framework version 7 (Font7)
│   ├── al_bayan_10m1360.yml           # Posted 2024-08-13, Build 10M1360
│   ├── al_bayan_10m1044.yml           # Posted 2024-06-01, Build 10M1044 (older catalog)
│   ├── adobe_arabic_10m1360.yml
│   └── damascus_10m1360.yml
│
└── font8/                              # Framework version 8 (Font8)
    ├── al_bayan_10m1732.yml           # Posted 2025-08-05, Build 10M1732
    ├── adobe_arabic_10m1732.yml
    └── damascus_10m1732.yml
```

**Note**: Same font can exist in both font7/ and font8/ directories because they come from different framework versions (different schemas, different macOS compatibility).

---

## Implementation Phases

1. **Phase 1**: Create import source models (MacosImportSource, GoogleImportSource, SilImportSource)
2. **Phase 2**: Update Formula with import_source attribute
3. **Phase 3**: Update FormulaBuilder
4. **Phase 4**: Update CreateFormula
5. **Phase 5**: Update catalog parsers (BaseParser, Asset)
6. **Phase 6**: Update macos importer with versioned filenames
7. **Phase 7**: Research and update Google Fonts importer
8. **Phase 8**: Update SIL importer
9. **Phase 9**: Comprehensive testing
10. **Phase 10**: Documentation

---

## Success Criteria

✅ **Clean Polymorphic Architecture**
- ImportSource base class with proper subclasses
- Type-safe serialization via Lutaml::Model
- No top-level pollution of Formula model

✅ **Proper Differentiation**
- macOS: `{name}_{asset_id}.yml`
- Google: `{name}_{commit_short}.yml`
- SIL: `{name}_{version}.yml`
- Manual: `{name}.yml` (no differentiation)

✅ **Directory Structure**
- Import source directories: macos/, google/, sil/, manual/
- Clear separation by source

✅ **Backward Compatibility**
- Manual formulas work without import_source
- nil import_source handled gracefully

✅ **Version Tracking**
- macOS: Posted date from catalog
- Google: GitHub commit ID + API version
- SIL: Release version

✅ **All Tests Pass**
- 617 existing tests still pass
- ~60 new tests for import sources
- Total: ~677 tests

---

## Next Steps

1. **Confirm Google Fonts approach**: Verify commit ID fetching from google/fonts repo
2. **Begin implementation**: Start with Phase 1 (import source models)
3. **Test incrementally**: After each phase
4. **Document as we go**: Update README with examples

---

**Ready for implementation when approved.**