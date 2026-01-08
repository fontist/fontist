# macOS PostedDate Versioning - Corrected Architecture with Metadata Model

**Date**: 2025-12-26
**Status**: Architecture Revised - Ready for Review
**Complexity**: High
**Critical Fix**: Uses proper OOP with source-specific metadata models

---

## Architecture Error in Previous Plan

### ❌ What Was Wrong

Placing source-specific attributes at Formula top level:
```yaml
name: Al Bayan
posted_date: "2024-08-13"     # ❌ macOS-specific
source: "macos"                # ❌ pollutes formula model
macos_asset_id: "10m1360"      # ❌ macOS-only concern
```

**Problems:**
- Pollutes Formula model with source-specific fields
- Not extensible to other sources (Google, SIL)
- Violates separation of concerns
- Not MECE (Mutually Exclusive, Collectively Exhaustive)

### ✅ Correct Approach: Metadata Model

Use nested metadata structure with source-specific models:

```yaml
name: Al Bayan
metadata:
  source: macos
  macos:
    posted_date: "2024-08-13T18:11:00Z"
    asset_id: "10m1360"
    catalog_version: 7
```

**Benefits:**
- Formula model stays generic
- Source-specific data properly encapsulated
- Extensible to other sources
- Follows OOP principles
- Maintains MECE structure

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
  ├─ catalog_version: integer (still at top - affects platform compatibility)
  ├─ min_macos_version: string (still at top - affects platform compatibility)
  ├─ max_macos_version: string (still at top - affects platform compatibility)
  └─ metadata: FormulaMetadata  # NEW
       ├─ source: string ("manual" | "google" | "macos" | "sil")
       ├─ macos: MacosMetadata (optional, only if source == "macos")
       └─ google: GoogleMetadata (optional, only if source == "google")

MacosMetadata
  ├─ posted_date: string (ISO 8601)
  ├─ asset_id: string (Build identifier, e.g., "10m1360")
  └─ catalog_version: integer (duplicates top-level for metadata completeness)

GoogleMetadata (future)
  ├─ version: string (e.g., "v42")
  ├─ last_modified: string
  └─ api_version: string
```

### Why Keep catalog_version at Top Level?

`catalog_version`, `min_macos_version`, `max_macos_version` affect **platform compatibility** and formula selection logic, so they remain at top level alongside `platforms` array. They're not import metadata - they're runtime behavior specifications.

---

## Implementation Plan

### Phase 1: Create Metadata Models

#### 1.1 Create FormulaMetadata Model
**File**: `lib/fontist/formula_metadata.rb` (NEW)

```ruby
require "lutaml/model"

module Fontist
  # Base metadata for formulas
  class FormulaMetadata < Lutaml::Model::Serializable
    attribute :source, :string  # "manual", "google", "macos", "sil"
    attribute :macos, MacosMetadata
    attribute :google, GoogleMetadata

    key_value do
      map "source", to: :source
      map "macos", to: :macos
      map "google", to: :google
    end

    # Check if formula is from macOS import
    def macos?
      source == "macos" && !macos.nil?
    end

    # Check if formula is from Google Fonts
    def google?
      source == "google" && !google.nil?
    end

    # Check if formula was manually created
    def manual?
      source == "manual" || source.nil?
    end
  end

  # macOS-specific import metadata
  class MacosMetadata < Lutaml::Model::Serializable
    attribute :posted_date, :string   # ISO 8601 date
    attribute :asset_id, :string      # Build identifier
    attribute :catalog_version, :integer  # 7 or 8

    key_value do
      map "posted_date", to: :posted_date
      map "asset_id", to: :asset_id
      map "catalog_version", to: :catalog_version
    end

    # Check if this metadata is outdated compared to new posted_date
    def outdated?(new_posted_date)
      return false unless posted_date && new_posted_date

      Time.parse(posted_date) < Time.parse(new_posted_date)
    rescue StandardError
      false
    end
  end

  # Google Fonts-specific import metadata (future)
  class GoogleMetadata < Lutaml::Model::Serializable
    attribute :version, :string
    attribute :last_modified, :string
    attribute :api_version, :string

    key_value do
      map "version", to: :version
      map "last_modified", to: :last_modified
      map "api_version", to: :api_version
    end
  end
end
```

#### 1.2 Update Formula Model
**File**: `lib/fontist/formula.rb`

**Add metadata attribute** (after line 76):
```ruby
attribute :metadata, FormulaMetadata
```

**Add key_value mapping** (after line 103):
```ruby
map "metadata", to: :metadata
```

**Add convenience methods**:
```ruby
# Check if formula is from macOS import
def macos_source?
  metadata&.macos? || false
end

# Check if formula has outdated macOS metadata
def macos_outdated?(new_posted_date)
  return false unless macos_source?
  
  metadata.macos&.outdated?(new_posted_date) || false
end

# Get macOS posted date (for display/comparison)
def macos_posted_date
  metadata&.macos&.posted_date
end

# Get macOS asset ID
def macos_asset_id
  metadata&.macos&.asset_id
end
```

---

### Phase 2: Update FormulaBuilder

#### 2.1 Add Metadata Support to Builder
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
  metadata      # NEW
].freeze
```

**Add attr_writer**:
```ruby
attr_writer :catalog_version, :min_macos_version, :max_macos_version, :metadata
```

**Add getter**:
```ruby
def metadata
  @metadata
end
```

**Add convenience method to set macOS metadata**:
```ruby
def set_macos_metadata(posted_date:, asset_id:, catalog_version:)
  @metadata = Fontist::FormulaMetadata.new(
    source: "macos",
    macos: Fontist::MacosMetadata.new(
      posted_date: posted_date,
      asset_id: asset_id,
      catalog_version: catalog_version
    )
  )
end

def set_google_metadata(version:, last_modified:, api_version: "v1")
  @metadata = Fontist::FormulaMetadata.new(
    source: "google",
    google: Fontist::GoogleMetadata.new(
      version: version,
      last_modified: last_modified,
      api_version: api_version
    )
  )
end

def set_manual_metadata
  @metadata = Fontist::FormulaMetadata.new(source: "manual")
end
```

---

### Phase 3: Update CreateFormula

#### 3.1 Accept Metadata Parameters
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
               metadata: nil)  # NEW: Accept metadata object or params
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
  @metadata = metadata  # NEW
end
```

**Pass metadata to FormulaBuilder**:
```ruby
builder.catalog_version = @catalog_version if @catalog_version
builder.min_macos_version = @min_macos_version if @min_macos_version
builder.max_macos_version = @max_macos_version if @max_macos_version
builder.metadata = @metadata if @metadata  # NEW
```

**Remove** extract_font_version method (if present)

---

### Phase 4: Update Catalog Parsers

#### 4.1 Extract PostedDate in BaseParser
**File**: `lib/fontist/macos/catalog/base_parser.rb`

**Add method**:
```ruby
def posted_date
  # Extract postedDate from catalog root dict
  date_str = data["postedDate"]
  return nil unless date_str
  
  # Return as ISO 8601 string
  Time.parse(date_str).utc.iso8601
rescue StandardError => e
  Fontist.ui.warn("Could not parse postedDate: #{e.message}")
  nil
end
```

**Update assets method** to pass posted_date:
```ruby
def assets
  date = posted_date
  parse_assets.map { |asset_data| Asset.new(asset_data, posted_date: date) }
end
```

#### 4.2 Update Asset Class
**File**: `lib/fontist/macos/catalog/asset.rb`

**Update constructor**:
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
```

**Add package identity method**:
```ruby
# Returns unique package identifier for formula filename
def package_identifier
  # Use Build as primary identifier (e.g., "10M1360" -> "10m1360")
  return build.downcase if build
  
  # Fallback to hash of relative path
  require 'digest'
  Digest::SHA256.hexdigest(@relative_path)[0..15]
end
```

---

### Phase 5: Update Macos Importer

#### 5.1 Build Metadata Object
**File**: `lib/fontist/import/macos.rb`

**Update process_asset method**:
```ruby
# Build metadata object for macOS source
metadata = Fontist::FormulaMetadata.new(
  source: "macos",
  macos: Fontist::MacosMetadata.new(
    posted_date: asset.posted_date,
    asset_id: asset.package_identifier,
    catalog_version: @catalog_version
  )
)

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
  metadata: metadata  # NEW
).call
```

#### 5.2 Implement Versioned Filenames

**Add method**:
```ruby
def versioned_formula_name(asset, family_name)
  normalized_name = family_name.downcase.gsub(/[^a-z0-9]+/, '_')
  package_id = asset.package_identifier
  
  # Encode package version in filename
  "#{normalized_name}_#{package_id}.yml"
end
```

**Update expected_formula_path**:
```ruby
def expected_formula_path(asset, family_name)
  filename = versioned_formula_name(asset, family_name)
  formula_dir.join(filename)
rescue StandardError
  nil
end
```

---

### Phase 6: Update Other Importers

#### 6.1 Google Fonts Importer
**File**: `lib/fontist/import/google_fonts_importer.rb`

**Build Google metadata**:
```ruby
# When creating formula
metadata = Fontist::FormulaMetadata.new(
  source: "google",
  google: Fontist::GoogleMetadata.new(
    version: font_version,  # from API
    last_modified: last_modified,  # from API
    api_version: "v1"
  )
)

Fontist::Import::CreateFormula.new(
  # ... existing parameters
  metadata: metadata
).call
```

#### 6.2 SIL Importer
**File**: `lib/fontist/import/sil_import.rb`

**Set metadata**:
```ruby
metadata = Fontist::FormulaMetadata.new(source: "sil")

Fontist::Import::CreateFormula.new(
  # ... existing parameters
  metadata: metadata
).call
```

#### 6.3 Manual Formulas
Default to no metadata or `{source: "manual"}` when created manually

---

### Phase 7: Update Detection Logic

#### 7.1 Add Update Check
**File**: `lib/fontist/font.rb`

**Add method**:
```ruby
private

def check_macos_updates(formula, new_catalog_posted_date)
  return unless formula.macos_source?
  return unless new_catalog_posted_date
  
  if formula.macos_outdated?(new_catalog_posted_date)
    Fontist.ui.say("📦 Newer macOS font package available")
    Fontist.ui.say("   Posted: #{new_catalog_posted_date}")
    Fontist.ui.say("   Current: #{formula.macos_posted_date}")
    Fontist.ui.say("   Run 'fontist import macos' to update")
  end
end
```

---

### Phase 8: Testing

#### 8.1 Metadata Model Tests
**File**: `spec/fontist/formula_metadata_spec.rb` (NEW)

```ruby
RSpec.describe Fontist::FormulaMetadata do
  describe "#macos?" do
    it "returns true for macOS source with metadata" do
      metadata = described_class.new(
        source: "macos",
        macos: Fontist::MacosMetadata.new(
          posted_date: "2024-08-13T18:11:00Z",
          asset_id: "10m1360",
          catalog_version: 7
        )
      )
      expect(metadata.macos?).to be true
    end
    
    it "returns false for other sources" do
      metadata = described_class.new(source: "google")
      expect(metadata.macos?).to be false
    end
  end
end

RSpec.describe Fontist::MacosMetadata do
  describe "#outdated?" do
    it "detects outdated posted_date" do
      metadata = described_class.new(
        posted_date: "2024-01-01T00:00:00Z",
        asset_id: "10m1044",
        catalog_version: 7
      )
      expect(metadata.outdated?("2024-12-01T00:00:00Z")).to be true
    end
    
    it "returns false if dates equal" do
      date = "2024-12-01T00:00:00Z"
      metadata = described_class.new(
        posted_date: date,
        asset_id: "10m1360",
        catalog_version: 7
      )
      expect(metadata.outdated?(date)).to be false
    end
  end
end
```

#### 8.2 Formula Integration Tests
**File**: `spec/fontist/formula_spec.rb`

```ruby
describe "Metadata support" do
  it "loads macOS metadata from formula" do
    formula = Formula.from_file("macos/font7/al_bayan_10m1360.yml")
    expect(formula.metadata).not_to be_nil
    expect(formula.metadata.source).to eq("macos")
    expect(formula.metadata.macos.posted_date).to eq("2024-08-13T18:11:00Z")
    expect(formula.metadata.macos.asset_id).to eq("10m1360")
  end
  
  it "provides convenience methods for macOS metadata" do
    formula = Formula.from_file("macos/font7/al_bayan_10m1360.yml")
    expect(formula.macos_source?).to be true
    expect(formula.macos_posted_date).to eq("2024-08-13T18:11:00Z")
    expect(formula.macos_asset_id).to eq("10m1360")
  end
  
  it "handles formulas without metadata" do
    formula = Formula.from_file("legacy/arial.yml")
    expect(formula.metadata).to be_nil
    expect(formula.macos_source?).to be false
  end
end
```

---

## Example Formula After Implementation

```yaml
---
name: Al Bayan
description: Al Bayan is an Arabic font with a distinctive thick stroke...
homepage: https://support.apple.com/en-om/HT211240#document

# Platform compatibility (top-level because affects formula selection)
catalog_version: 7
min_macos_version: "10.11"
max_macos_version: "15.7"
platforms:
  - macos-font7

# Import metadata (source-specific, properly encapsulated)
metadata:
  source: macos
  macos:
    posted_date: "2024-08-13T18:11:00Z"
    asset_id: "10m1360"
    catalog_version: 7

resources:
  AlBayan_Font:
    urls:
      - https://mesu.apple.com/assets/com_apple_MobileAsset_Font7/.../AlBayan.pkg
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
      - family_name: Al Bayan
        type: Bold
        post_script_name: AlBayan-Bold
        full_name: Al Bayan Bold
        version: "13.0d3e1"

license_url: https://www.apple.com/legal/sla/
open_license: Apple Font License
```

### Example: Google Fonts Formula (Future)

```yaml
---
name: Roboto
description: Roboto is a neo-grotesque sans-serif typeface...
homepage: https://fonts.google.com/specimen/Roboto

# Import metadata (Google-specific)
metadata:
  source: google
  google:
    version: "v42"
    last_modified: "2024-12-01T10:00:00Z"
    api_version: "v1"

resources:
  # ... Google resources

fonts:
  # ... font styles
```

---

## Architecture Benefits

### ✅ Separation of Concerns
- Formula model stays generic
- Source-specific data properly encapsulated
- Easy to add new sources without modifying Formula

### ✅ Extensibility
- Adding new source (e.g., Adobe Fonts):
  ```ruby
  class AdobeMetadata < Lutaml::Model::Serializable
    attribute :product_id, :string
    attribute :version, :string
  end
  ```
- No changes to Formula model needed

### ✅ MECE Compliance
- Each source has exactly one metadata type
- No overlap between source-specific fields
- Collectively exhaustive for all sources

### ✅ OOP Principles
- Proper encapsulation
- Single Responsibility Principle
- Open/Closed Principle (open for extension, closed for modification)

### ✅ Type Safety
- Lutaml::Model provides serialization/deserialization
- Compile-time type checking for attributes
- Validation built-in

---

## Migration Path

### For Existing Formulas
1. Formulas without `metadata` attribute continue to work
2. `formula.metadata` returns `nil` for legacy formulas
3. Convenience methods (`macos_source?`) handle `nil` gracefully

### For New Imports
1. macOS importer creates `metadata` with macOS-specific data
2. Google importer creates `metadata` with Google-specific data
3. Manual formulas can omit `metadata` or set `{source: "manual"}`

---

## Questions for User

1. **Metadata Structure**: Is nested `metadata > macos/google` structure acceptable?
2. **Catalog Version Duplication**: OK to have `catalog_version` both at top-level (platform selection) and in `metadata.macos` (import tracking)?
3. **Versioned Filenames**: Still use `family_name_asset_id.yml` format (e.g., `al_bayan_10m1360.yml`)?
4. **Legacy Support**: Is `nil` metadata acceptable for existing formulas?
5. **Google Metadata**: What fields should `GoogleMetadata` track?

---

## Success Criteria

✅ **Clean Architecture**
- Formula model generic and reusable
- Source-specific data properly encapsulated
- No pollution of top-level attributes

✅ **Extensibility**
- Easy to add new sources (Adobe, SIL variants, etc.)
- No Formula model changes needed for new sources

✅ **Backward Compatibility**
- Legacy formulas work without metadata
- Graceful handling of nil metadata

✅ **Type Safety**
- Lutaml::Model serialization
- Proper model hierarchy

✅ **All Tests Pass**
- 617 existing tests still pass
- ~50 new tests for metadata
- Total: ~667 tests

---

## Implementation Order

1. **Phase 1**: Create metadata models (FormulaMetadata, MacosMetadata, GoogleMetadata)
2. **Phase 2**: Update Formula to accept metadata attribute
3. **Phase 3**: Update FormulaBuilder with metadata support
4. **Phase 4**: Update catalog parsers to extract PostedDate
5. **Phase 5**: Update macos importer to build metadata objects
6. **Phase 6**: Update other importers (google, sil)
7. **Phase 7**: Add update detection logic
8. **Phase 8**: Comprehensive testing
9. **Phase 9**: Documentation
10. **Phase 10**: Rollback font_version if still present

---

**Ready for review and implementation when approved.**