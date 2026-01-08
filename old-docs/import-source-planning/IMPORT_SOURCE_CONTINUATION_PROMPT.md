# Import Source Implementation - Continuation Prompt

**Architecture**: Corrected - Framework metadata separated from formulas
**Timeline**: Compressed - 2-3 days for deadline
**Status Files**: 
- Plan: [`IMPORT_SOURCE_IMPLEMENTATION_PLAN.md`](IMPORT_SOURCE_IMPLEMENTATION_PLAN.md:1)
- Status: [`IMPORT_SOURCE_IMPLEMENTATION_STATUS.md`](IMPORT_SOURCE_IMPLEMENTATION_STATUS.md:1)
- Architecture: [`MACOS_IMPORT_SOURCE_CORRECTED_ARCHITECTURE.md`](MACOS_IMPORT_SOURCE_CORRECTED_ARCHITECTURE.md:1)

---

## Critical Architecture Requirements

### 1. NO Source-Specific Metadata in Formula

**WRONG** ❌:
```yaml
# Formula
name: Al Bayan
catalog_version: 7              # ❌ Framework metadata in formula
min_macos_version: "10.11"      # ❌ Framework metadata in formula
max_macos_version: "15.7"       # ❌ Framework metadata in formula
```

**CORRECT** ✅:
```yaml
# Formula
name: Al Bayan
platforms:
  - macos
import_source:
  type: macos
  framework_version: 7
  posted_date: "2024-08-13T18:11:00Z"
  asset_id: "10m1360"
```

### 2. Framework Metadata Stored Externally

**File**: `lib/fontist/macos_framework_metadata.yml`
```yaml
frameworks:
  7:
    min_macos_version: "10.11"
    max_macos_version: "15.7"
    parser_class: "Fontist::Macos::Catalog::Font7Parser"
  8:
    min_macos_version: "26.0"
    max_macos_version: null
    parser_class: "Fontist::Macos::Catalog::Font8Parser"
```

### 3. Polymorphic ImportSource Classes

```ruby
ImportSource (base)
  ├─ MacosImportSource
  │    ├─ framework_version: integer (7, 8)
  │    ├─ posted_date: string
  │    └─ asset_id: string
  ├─ GoogleImportSource
  │    ├─ commit_id: string
  │    ├─ api_version: string
  │    ├─ last_modified: string
  │    └─ family_id: string
  └─ SilImportSource
       ├─ version: string
       └─ release_date: string
```

---

## Implementation Instructions

### Phase 1: Core Models

#### Create ImportSource Base Class

**File**: `lib/fontist/import_source.rb`

```ruby
require "lutaml/model"

module Fontist
  class ImportSource < Lutaml::Model::Serializable
    attribute :type, :string
    
    key_value do
      map "type", to: :type
    end
    
    # Factory method for polymorphic deserialization
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
    
    # Abstract: Return differentiation key for filename
    def differentiation_key
      raise NotImplementedError
    end
    
    # Abstract: Check if outdated compared to new source
    def outdated?(new_source)
      raise NotImplementedError
    end
  end
end
```

#### Create MacosImportSource

**File**: `lib/fontist/macos_import_source.rb`

```ruby
require_relative "import_source"
require_relative "macos_framework_metadata"

module Fontist
  class MacosImportSource < ImportSource
    attribute :framework_version, :integer
    attribute :posted_date, :string
    attribute :asset_id, :string
    
    key_value do
      map "type", to: :type, default: -> { "macos" }
      map "framework_version", to: :framework_version
      map "posted_date", to: :posted_date
      map "asset_id", to: :asset_id
    end
    
    def differentiation_key
      asset_id&.downcase
    end
    
    def outdated?(new_source)
      return false unless new_source.is_a?(MacosImportSource)
      return false unless posted_date && new_source.posted_date
      
      Time.parse(posted_date) < Time.parse(new_source.posted_date)
    rescue StandardError
      false
    end
    
    def min_macos_version
      MacosFrameworkMetadata.min_macos_version(framework_version)
    end
    
    def max_macos_version
      MacosFrameworkMetadata.max_macos_version(framework_version)
    end
    
    def compatible_with_macos?(macos_version)
      MacosFrameworkMetadata.compatible_with_macos?(framework_version, macos_version)
    end
    
    def to_s
      "macOS Font#{framework_version} (posted: #{posted_date}, asset: #{asset_id})"
    end
  end
end
```

#### Create Framework Metadata

**File**: `lib/fontist/macos_framework_metadata.yml`

```yaml
---
frameworks:
  7:
    min_macos_version: "10.11"
    max_macos_version: "15.7"
    parser_class: "Fontist::Macos::Catalog::Font7Parser"
    description: "Font7 framework (macOS Monterey, Ventura, Sonoma)"
  8:
    min_macos_version: "26.0"
    max_macos_version: null
    parser_class: "Fontist::Macos::Catalog::Font8Parser"
    description: "Font8 framework (macOS Sequoia+)"
```

**File**: `lib/fontist/macos_framework_metadata.rb`

```ruby
require "yaml"

module Fontist
  class MacosFrameworkMetadata
    METADATA_FILE = File.expand_path("macos_framework_metadata.yml", __dir__).freeze
    
    class << self
      def metadata
        @metadata ||= YAML.load_file(METADATA_FILE)["frameworks"]
      end
      
      def min_macos_version(framework_version)
        metadata.dig(framework_version, "min_macos_version")
      end
      
      def max_macos_version(framework_version)
        metadata.dig(framework_version, "max_macos_version")
      end
      
      def compatible_with_macos?(framework_version, macos_version)
        min_version = min_macos_version(framework_version)
        max_version = max_macos_version(framework_version)
        
        return false unless min_version
        
        version = Gem::Version.new(macos_version)
        min = Gem::Version.new(min_version)
        
        return false if version < min
        return true unless max_version
        
        max = Gem::Version.new(max_version)
        version <= max
      end
    end
  end
end
```

#### Create GoogleImportSource and SilImportSource

Follow similar pattern to MacosImportSource. See [`MACOS_IMPORT_SOURCE_CORRECTED_ARCHITECTURE.md`](MACOS_IMPORT_SOURCE_CORRECTED_ARCHITECTURE.md:1) for complete specifications.

---

### Phase 2: Formula Integration

#### Update Formula Model

**File**: `lib/fontist/formula.rb`

**REMOVE these attributes**:
```ruby
# DELETE THESE
attribute :catalog_version, :integer
attribute :min_macos_version, :string
attribute :max_macos_version, :string
```

**ADD import_source**:
```ruby
attribute :import_source, ImportSource

key_value do
  # ... existing mappings ...
  map "import_source", to: :import_source
end

# Convenience methods
def macos_import?
  import_source.is_a?(MacosImportSource)
end

def google_import?
  import_source.is_a?(GoogleImportSource)
end

def manual_formula?
  import_source.nil?
end

def compatible_with_current_platform?
  return true unless macos_import?
  
  current_macos = Utils::System.macos_version
  import_source.compatible_with_macos?(current_macos)
end
```

#### Update FormulaBuilder

**File**: `lib/fontist/import/formula_builder.rb`

**REMOVE from FORMULA_ATTRIBUTES**:
```ruby
# DELETE THESE
:catalog_version,
:min_macos_version,
:max_macos_version,
```

**ADD**:
```ruby
FORMULA_ATTRIBUTES = %i[
  # ... existing ...
  import_source    # NEW
].freeze

attr_writer :import_source

def import_source
  @import_source
end

def set_macos_import_source(framework_version:, posted_date:, asset_id:)
  @import_source = Fontist::MacosImportSource.new(
    framework_version: framework_version,
    posted_date: posted_date,
    asset_id: asset_id
  )
end
```

---

### Phase 3: Catalog Parsers

#### Update BaseParser

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

def framework_version
  # Extract from filename: com_apple_MobileAsset_Font7.xml -> 7
  File.basename(@xml_path).match(/Font(\d+)/)[1].to_i
end

def assets
  pdate = posted_date
  fver = framework_version
  parse_assets.map { |asset_data| Asset.new(asset_data, posted_date: pdate, framework_version: fver) }
end
```

#### Update Asset

**File**: `lib/fontist/macos/catalog/asset.rb`

```ruby
attr_reader :posted_date, :framework_version  # ADD

def initialize(data, posted_date: nil, framework_version: nil)
  # ... existing code ...
  @posted_date = posted_date
  @framework_version = framework_version
end

def asset_id
  build&.downcase
end

def to_import_source
  Fontist::MacosImportSource.new(
    framework_version: framework_version,
    posted_date: posted_date,
    asset_id: asset_id
  )
end
```

---

### Phase 4: Macos Importer

**File**: `lib/fontist/import/macos.rb`

```ruby
def process_asset(asset, current, total)
  # ... existing progress display ...
  
  # Build import source
  import_source = asset.to_import_source
  
  # Generate versioned path
  expected_path = versioned_formula_path(asset, family_name)
  
  # Check if exists ...
  
  path = Fontist::Import::CreateFormula.new(
    asset.download_url,
    platforms: ["macos"],
    homepage: homepage,
    requires_license_agreement: license,
    formula_dir: formula_dir,
    keep_existing: !@force,
    import_source: import_source  # NEW
  ).call
end

def versioned_formula_path(asset, family_name)
  normalized = family_name.downcase.gsub(/[^a-z0-9]+/, '_')
  filename = "#{normalized}_#{asset.asset_id}.yml"
  formula_dir.join(filename)
end

def formula_dir
  @formula_dir ||= if @custom_formulas_dir
                     Pathname.new(@custom_formulas_dir)
                   else
                     framework_version = detect_framework_version
                     base = Fontist.formulas_path.join("macos")
                     framework_version ? base.join("font#{framework_version}") : base
                   end.tap { |path| FileUtils.mkdir_p(path) }
end

def detect_framework_version
  basename = File.basename(@catalog_path, ".xml")
  match = basename.match(/Font(\d+)/)
  match ? match[1].to_i : nil
end
```

---

### Testing Requirements

#### Write Comprehensive Tests

Each class needs:
1. Unit tests for serialization/deserialization
2. Tests for all methods
3. Edge case coverage

**Example test structure**:
```ruby
RSpec.describe Fontist::MacosImportSource do
  describe "#differentiation_key" do
    it "returns lowercased asset_id"
  end
  
  describe "#outdated?" do
    it "detects outdated posted_date"
    it "returns false if dates equal"
  end
  
  describe "serialization" do
    it "serializes to YAML correctly"
    it "deserializes from YAML correctly"
  end
end
```

#### Run Tests After Each Phase

```bash
bundle exec rspec
```

All 617 existing tests MUST pass. New tests should bring total to ~677.

---

### Cleanup Requirements

#### Remove Old Implementation

**Search and remove**:
1. `font_version` - anywhere it appears
2. `catalog_version` - from Formula (keep in tests/metadata where appropriate)
3. `min_macos_version` - from Formula top-level
4. `max_macos_version` - from Formula top-level

**Files to check**:
- lib/fontist/formula.rb
- lib/fontist/import/formula_builder.rb
- lib/fontist/import/create_formula.rb
- spec/**/*_spec.rb

---

### Documentation Requirements

#### Update README.adoc

Add sections:
1. Import Source architecture
2. Framework metadata
3. Versioned filenames
4. Example formulas

**Example content**:
```adoc
=== Import Source Architecture

Fontist tracks the source and version of imported formulas using a polymorphic
`import_source` attribute.

==== macOS Fonts

macOS supplementary fonts use three versioning dimensions:

Framework Version:: Font7, Font8 - determines schema and parser
Catalog PostedDate:: Version of catalog within framework
Asset Build:: Individual package identifier

[source,yaml]
----
import_source:
  type: macos
  framework_version: 7
  posted_date: "2024-08-13T18:11:00Z"
  asset_id: "10m1360"
----
```

#### Create Architecture Docs

**File**: `docs/import-source-architecture.md`

Document:
- Design decisions
- Class hierarchy
- Framework metadata approach
- Versioned filename strategy

---

### Archive Old Documentation

Move to `old-docs/`:
- MACOS_POSTED_DATE_VERSIONING_PLAN.md
- MACOS_FONT_PLATFORM_VERSIONING_*.md
- Any other temporary planning docs

Keep only:
- IMPORT_SOURCE_IMPLEMENTATION_PLAN.md
- IMPORT_SOURCE_IMPLEMENTATION_STATUS.md
- MACOS_IMPORT_SOURCE_CORRECTED_ARCHITECTURE.md

---

## Critical Success Criteria

### Architecture
- ✅ NO source-specific metadata in Formula top-level
- ✅ Framework metadata in external YAML
- ✅ Polymorphic ImportSource classes
- ✅ MECE structure throughout

### Functionality
- ✅ Versioned filenames work: `{name}_{key}.yml`
- ✅ Directory structure correct: `macos/font7/`, `macos/font8/`
- ✅ Platform compatibility via framework metadata
- ✅ Update detection via `outdated?()`

### Tests
- ✅ All 617 existing tests pass
- ✅ ~60 new tests pass
- ✅ Total: ~677 tests at 100% pass rate

### Documentation
- ✅ README.adoc updated
- ✅ Architecture documented
- ✅ Migration guide created
- ✅ Old docs archived

---

## Implementation Principles

### Correctness Over Speed
- Architecture correctness is paramount
- Never compromise on proper OOP
- Tests may need updating for correct behavior
- Regressions indicate tests need fixing, not code

### MECE at All Levels
- Mutually Exclusive: No overlap in responsibilities
- Collectively Exhaustive: All cases covered
- Each class has one clear purpose

### Full Object-Oriented
- No functional programming patterns
- No procedural code
- Proper inheritance and polymorphism
- Encapsulation at all levels

---

## Work Approach

1. **Work phase-by-phase** as defined in plan
2. **Test after each phase** - don't accumulate untested code
3. **Update status file** after each phase completion
4. **Ask for clarification** if architecture unclear
5. **Don't compromise** on correctness for speed

---

## Questions to Ask If Stuck

1. Is this source-specific data? → Should be in ImportSource
2. Is this framework metadata? → Should be in external YAML
3. Is this formula behavior? → Should be in Formula
4. Am I following OOP principles? → Check separation of concerns
5. Is this MECE? → Check for overlap or gaps

---

## Final Notes

This is a **compressed timeline** implementation (2-3 days). Focus on:
1. Getting architecture correct first time
2. Testing thoroughly at each phase
3. No shortcuts or compromises
4. Clean, maintainable code

The architecture is finalized and correct. Implementation should be straightforward following this prompt and the referenced documents.

---

**START WITH PHASE 1: Core Models**

Begin by creating the ImportSource base class and three subclasses, along with the framework metadata system. Test thoroughly before moving to Phase 2.

Good luck! 🚀