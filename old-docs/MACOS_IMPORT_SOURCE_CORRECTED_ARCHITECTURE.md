# macOS Import Source - Correct Architecture

**Date**: 2025-12-27
**Status**: Architecture Corrected
**Critical Fix**: Framework metadata stored separately, not in Formula

---

## Critical Corrections

### ❌ WRONG (Previous Approach)
```yaml
# Formula
name: Al Bayan
catalog_version: 7              # ❌ Framework metadata in formula
min_macos_version: "10.11"      # ❌ Framework metadata in formula
max_macos_version: "15.7"       # ❌ Framework metadata in formula
```

### ✅ CORRECT (New Approach)
```yaml
# Formula - NO framework metadata
name: Al Bayan
platforms:
  - macos
import_source:
  type: macos
  framework_version: 7          # ✅ Framework version in import source
  posted_date: "2024-08-13"
  asset_id: "10m1360"
```

```yaml
# Separate file: lib/fontist/macos_framework_metadata.yml
frameworks:
  7:
    min_macos_version: "10.11"
    max_macos_version: "15.7"
  8:
    min_macos_version: "26.0"
    max_macos_version: null
```

---

## Architecture

### Formula Model (Simplified)

```ruby
Formula
  ├─ name: string
  ├─ description: string
  ├─ resources: ResourceCollection
  ├─ fonts: FontCollection
  ├─ platforms: Array<string>        # Generic: ["macos"]
  └─ import_source: ImportSource     # Contains framework_version
```

**NO** `catalog_version`, `min_macos_version`, `max_macos_version` in Formula!

### MacosImportSource

```ruby
class MacosImportSource < ImportSource
  attribute :framework_version, :integer   # 7, 8
  attribute :posted_date, :string          # Catalog date
  attribute :asset_id, :string             # Package build
end
```

### Framework Metadata (External)

**File**: `lib/fontist/macos_framework_metadata.yml`

```yaml
frameworks:
  7:
    min_macos_version: "10.11"
    max_macos_version: "15.7"
    parser_class: "Font7Parser"
  8:
    min_macos_version: "26.0"
    max_macos_version: null
    parser_class: "Font8Parser"
```

---

## Implementation

### 1. Create Framework Metadata File

**File**: `lib/fontist/macos_framework_metadata.yml` (NEW)

```yaml
---
# macOS MobileAsset Framework Metadata
# Maps framework version to macOS compatibility
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

### 2. Create Framework Metadata Class

**File**: `lib/fontist/macos_framework_metadata.rb` (NEW)

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
      
      def parser_class(framework_version)
        metadata.dig(framework_version, "parser_class")
      end
      
      def description(framework_version)
        metadata.dig(framework_version, "description")
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

### 3. Update MacosImportSource

**File**: `lib/fontist/macos_import_source.rb`

```ruby
require_relative "import_source"
require_relative "macos_framework_metadata"

module Fontist
  class MacosImportSource < ImportSource
    attribute :framework_version, :integer   # 7, 8
    attribute :posted_date, :string          # "2024-08-13T18:11:00Z"
    attribute :asset_id, :string             # "10m1360"
    
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
    
    # Get minimum macOS version for this framework
    def min_macos_version
      MacosFrameworkMetadata.min_macos_version(framework_version)
    end
    
    # Get maximum macOS version for this framework
    def max_macos_version
      MacosFrameworkMetadata.max_macos_version(framework_version)
    end
    
    # Check if compatible with specific macOS version
    def compatible_with_macos?(macos_version)
      MacosFrameworkMetadata.compatible_with_macos?(framework_version, macos_version)
    end
    
    def to_s
      "macOS Font#{framework_version} (posted: #{posted_date}, asset: #{asset_id})"
    end
  end
end
```

### 4. Simplified Formula Model

**File**: `lib/fontist/formula.rb`

```ruby
# REMOVED: catalog_version, min_macos_version, max_macos_version
attribute :import_source, ImportSource

# Platform compatibility checked via import_source
def compatible_with_current_platform?
  return true unless macos_import?
  
  current_macos = Utils::System.macos_version
  import_source.compatible_with_macos?(current_macos)
end

def macos_import?
  import_source.is_a?(MacosImportSource)
end
```

### 5. Update Macos Importer

**File**: `lib/fontist/import/macos.rb`

```ruby
def process_asset(asset, current, total)
  # ... existing code ...
  
  # Detect framework version from catalog path
  framework_version = detect_framework_version
  
  # Create import source with framework version
  import_source = MacosImportSource.new(
    framework_version: framework_version,
    posted_date: asset.posted_date,
    asset_id: asset.asset_id
  )
  
  path = Fontist::Import::CreateFormula.new(
    asset.download_url,
    platforms: ["macos"],  # Generic platform
    homepage: homepage,
    requires_license_agreement: license,
    formula_dir: formula_dir,
    keep_existing: !@force,
    import_source: import_source
  ).call
end

def detect_framework_version
  # Extract from catalog path: com_apple_MobileAsset_Font7.xml -> 7
  basename = File.basename(@catalog_path, ".xml")
  match = basename.match(/Font(\d+)/)
  match ? match[1].to_i : nil
end

def formula_dir
  @formula_dir ||= if @custom_formulas_dir
                     Pathname.new(@custom_formulas_dir)
                   else
                     # Directory: macos/font{N}/
                     framework_version = detect_framework_version
                     base = Fontist.formulas_path.join("macos")
                     framework_version ? base.join("font#{framework_version}") : base
                   end.tap { |path| FileUtils.mkdir_p(path) }
end
```

---

## Example Formula (Corrected)

```yaml
---
name: Al Bayan
description: Al Bayan is an Arabic font...
homepage: https://support.apple.com/en-om/HT211240#document

# Generic platform
platforms:
  - macos

# Import source with framework version
import_source:
  type: macos
  framework_version: 7
  posted_date: "2024-08-13T18:11:00Z"
  asset_id: "10m1360"

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

**Path**: `formulas/macos/font7/al_bayan_10m1360.yml`

---

## Platform Compatibility Check

```ruby
# Old (WRONG) - per-formula min/max versions
formula.min_macos_version  # ❌ Doesn't exist
formula.max_macos_version  # ❌ Doesn't exist

# New (CORRECT) - external metadata
formula.import_source.framework_version  # => 7
formula.import_source.min_macos_version  # => "10.11" (from metadata file)
formula.import_source.max_macos_version  # => "15.7" (from metadata file)
formula.import_source.compatible_with_macos?("15.0")  # => true
```

---

## Directory Structure

```
lib/fontist/
├── macos_framework_metadata.yml    # Framework -> macOS version mapping
├── macos_framework_metadata.rb     # Metadata loader class
├── import_source.rb                # Base class
├── macos_import_source.rb          # macOS-specific
├── google_import_source.rb         # Google-specific
└── sil_import_source.rb            # SIL-specific

formulas/macos/
├── font7/                          # Framework 7 formulas
│   ├── al_bayan_10m1360.yml
│   └── ...
└── font8/                          # Framework 8 formulas
    ├── al_bayan_10m1732.yml
    └── ...
```

---

## Benefits

✅ **Separation of Concerns**: Framework metadata not in formulas
✅ **Single Source of Truth**: One file defines framework versions
✅ **Easy Updates**: Change framework metadata without touching formulas
✅ **MECE**: Framework data separate from import data
✅ **Scalable**: Add Font9, Font10 without formula changes

---

## Summary of Changes

### Removed from Formula:
- ❌ `catalog_version`
- ❌ `min_macos_version`
- ❌ `max_macos_version`

### Added:
- ✅ `macos_framework_metadata.yml` - External framework metadata
- ✅ `MacosFrameworkMetadata` class - Metadata loader
- ✅ `framework_version` in MacosImportSource
- ✅ Methods to query framework metadata from import source

### Formula Now Contains:
- Name, description, resources, fonts (unchanged)
- `platforms: ["macos"]` (generic)
- `import_source` with framework_version

---

**This is the correct architecture. Framework metadata stored separately, not per-formula.**