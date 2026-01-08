# macOS Add-on Fonts Architecture v2 (Revised)

## Executive Summary

**REVISED**: Fontist ALREADY has macOS add-on font support via [`lib/fontist/import/macos.rb`](../lib/fontist/import/macos.rb:1), which downloads fonts from Apple CDN and creates formulas. This document describes the **extension** to support multiple catalog versions (Font5-Font8) using **Plist parsing** (already in use).

## Current State (Existing Implementation)

### What Already Works

1. **`Import::Macos` class** ([`lib/fontist/import/macos.rb`](../lib/fontist/import/macos.rb:1))
   - Parses `/System/Library/AssetsV2/com_apple_MobileAsset_Font6/com_apple_MobileAsset_Font6.xml`
   - Extracts download URLs (`__BaseURL` + `__RelativePath`)
   - Downloads `.zip` files from Apple CDN
   - Uses `CreateFormula` to generate formulas

2. **180+ existing macOS formulas** ([`spec/fixtures/formulas/Formulas/macos/`](../spec/fixtures/formulas/Formulas/macos/))
   - Each formula has `platforms: [macos]` restriction
   - Downloads from `http://updates-http.cdn-apple.com/...`
   - Contains full license text (`requires_license_agreement`)
   - Uses standard formula structure with `resources` and `fonts`

3. **CLI command** ([`lib/fontist/import_cli.rb:55-59`](../lib/fontist/import_cli.rb:55))
   - `fontist import macos` - generates formulas from Font6 catalog

### Example Existing Formula

```yaml
---
platforms:
- macos
description: Impact
homepage: https://support.apple.com/en-om/HT211240#document
resources:
  Impact.zip:
    urls:
    - http://updates-http.cdn-apple.com/.../3c94f1412d7b13bcfcd207c06bb6abaff9e576cf.zip
    sha256: 37ffc38841f470232f93d356f4bc883fe008020a8d4b0a872acbf0c1325e0aef
    file_size: 83478
fonts:
- name: Impact
  styles:
  - family_name: Impact
    type: Regular
    post_script_name: Impact
    version: 5.00x
    font: Impact.ttf
extract: {}
requires_license_agreement: |
  For use on Apple-branded Systems
  [full Apple license text]
command: import macos
```

## Problem Statement

### Current Limitations

1. **Only supports Font6** (Catalina 10.15, Big Sur 11)
   - Hardcoded path: `/System/Library/AssetsV2/com_apple_MobileAsset_Font6/`
   - Doesn't support Font5 (High Sierra 10.13, Mojave 10.14)
   - Doesn't support Font7 (Monterey 12, Ventura 13, Sonoma 14)
   - Doesn't support Font8 (Sequoia 15, macOS 26)

2. **Uses simple Plist parsing**
   - Only extracts `__BaseURL` and `__RelativePath`
   - Doesn't validate XML structure
   - No type safety
   - Doesn't capture all metadata

3. **No version detection**
   - Manual selection of catalog file
   - No automatic version discovery

4. **No CI artifacts for catalogs**
   - Can't inspect catalog contents without macOS system
   - No historical tracking of catalog changes

## Proposed Solution

### 1. Multi-Version Catalog Support

Support all catalog versions with automatic detection:

```
Font5: macOS 10.13 (High Sierra), 10.14 (Mojave)
Font6: macOS 10.15 (Catalina), 11 (Big Sur)
Font7: macOS 12 (Monterey), 13 (Ventura), 14 (Sonoma)
Font8: macOS 15 (Sequoia), 26 (future)
```

### 2. Plist-Based Parsing (Existing Approach)

Continue using the `plist` gem (already a dependency):

**Benefits:**
- Already working in existing code
- Native macOS format
- Simple and proven
- No additional dependencies
- Ruby standard library support

### 3. Version-Specific Parsers (Minimal)

Handle schema differences between versions with simple adapter pattern:

```ruby
module Fontist
  module MacOS
    module Catalog
      # Simple data class for asset information
      class Asset
        attr_reader :base_url, :relative_path, :asset_type,
                    :postscript_names, :font_family, :display_name

        def initialize(data)
          @base_url = data["__BaseURL"]
          @relative_path = data["__RelativePath"]
          @asset_type = data["AssetType"]
          @postscript_names = Array(data["PostScriptName"])
          @font_family = data["FontFamily"]
          @display_name = data["DisplayName"]
        end

        def download_url
          base_url + relative_path
        end
      end

      # Base parser using Plist
      class BaseParser
        def initialize(xml_path)
          @xml_path = xml_path
          @version = detect_version(xml_path)
        end

        def parse
          data = Plist.parse_xml(@xml_path)
          assets = data["Assets"] || []

          assets.map { |asset_data| Asset.new(asset_data) }
        end

        private

        def detect_version(path)
          path.match(/Font(\d+)/)[1].to_i
        end
      end

      # Version-specific parsers if schemas differ
      class Font5Parser < BaseParser
        def parse
          # Handle Font5-specific schema if needed
          super
        end
      end

      class Font6Parser < BaseParser
        # Current implementation works as-is
      end

      class Font7Parser < BaseParser
        def parse
          # Handle Font7-specific schema if needed
          super
        end
      end

      class Font8Parser < BaseParser
        def parse
          # Handle Font8-specific schema if needed
          super
        end
      end
    end
  end
end
```

### 4. Enhanced Import Class

Extend [`Import::Macos`](../lib/fontist/import/macos.rb:1):

```ruby
module Fontist
  module Import
    class Macos
      # Current: hardcoded Font6
      # FONT_XML = "/System/Library/AssetsV2/com_apple_MobileAsset_Font6/..."

      # NEW: Auto-detect catalog version
      def self.available_catalogs
        [8, 7, 6, 5].map do |version|
          pattern = "/System/Library/AssetsV2/com_apple_MobileAsset_Font#{version}/*.xml"
          Dir.glob(pattern).first
        end.compact
      end

      def self.import_all_versions
        available_catalogs.each do |catalog_path|
          new(catalog_path).call
        end
      end

      def initialize(font_xml = nil)
        @font_xml = font_xml || self.class.available_catalogs.first
        @version = detect_version(@font_xml)
      end

      private

      def detect_version(path)
        path.match(/Font(\d+)/)[1].to_i
      end

      def parse_catalog
        parser_class = case @version
        when 5 then Catalog::Font5Parser
        when 6 then Catalog::Font6Parser
        when 7 then Catalog::Font7Parser
        when 8 then Catalog::Font8Parser
        else raise "Unsupported catalog version: #{@version}"
        end

        parser_class.new(@font_xml).parse
      end

      def links
        # Instead of: Plist.parse_xml(@font_xml)["Assets"].map { |x| x.values_at("__BaseURL", "__RelativePath").join }
        # Now: Use structured parser
        parse_catalog.map(&:download_url)
      end
    end
  end
end
```

### 5. CI Integration - Catalog Artifacts

Update [`.github/workflows/discover-fonts.yml`](../.github/workflows/discover-fonts.yml:1):

```yaml
jobs:
  discover-macos:
    name: macOS fonts
    runs-on: macos-${{ matrix.version }}
    strategy:
      matrix:
        version: [13, 14, 15]  # Ventura, Sonoma, Sequoia
    steps:
      - name: List Core System Fonts
        run: |
          echo "=== ALL FONTS IN /System/Library/Fonts/ ==="
          find /System/Library/Fonts/ -type f \( -name "*.ttf" -o -name "*.ttc" -o -name "*.otf" \) | sort

      - name: Find Asset Catalogs
        id: catalogs
        run: |
          echo "=== AVAILABLE ASSET CATALOGS ==="
          find /System/Library/AssetsV2/ -name "*.xml" -type f | sort

      - name: Upload Asset Catalogs
        uses: actions/upload-artifact@v4
        with:
          name: macos-${{ matrix.version }}-asset-catalogs
          path: /System/Library/AssetsV2/com_apple_MobileAsset_Font*/*.xml
          if-no-files-found: warn

      - name: Display Catalog Info
        run: |
          for xml in /System/Library/AssetsV2/com_apple_MobileAsset_Font*/*.xml; do
            if [ -f "$xml" ]; then
              echo "=== $xml ==="
              echo "Size: $(wc -c < "$xml") bytes"
              echo "Assets: $(grep -c '<key>Assets</key>' "$xml" || echo 0)"
              echo ""
            fi
          done
```

## Implementation Plan

### Phase 1: Catalog Structure and Parsers (1-2 hours)

**Files to create:**
```
lib/fontist/macos/
├── catalog/
│   ├── asset.rb                # Simple data class
│   ├── base_parser.rb          # Plist-based parser
│   ├── font5_parser.rb         # Font5 variant (if needed)
│   ├── font6_parser.rb         # Font6 (current)
│   ├── font7_parser.rb         # Font7 variant (if needed)
│   └── font8_parser.rb         # Font8 variant (future)

spec/fontist/macos/catalog/
├── asset_spec.rb
├── font5_parser_spec.rb
├── font6_parser_spec.rb
├── font7_parser_spec.rb
└── font8_parser_spec.rb
```

**Tasks:**
- [ ] Create `MacOS::Catalog::Asset` simple data class
- [ ] Create `MacOS::Catalog::BaseParser` using Plist
- [ ] Sample XML from each version (Font5, Font6, Font7, Font8)
- [ ] Identify schema differences between versions
- [ ] Create version-specific parsers (only if schemas differ)
- [ ] Write unit tests for  parser

**Success Criteria:**
- Can parse XML from all catalog versions using Plist
- Asset class properly captures all metadata
- Tests pass for sample data from each version
- No new dependencies needed (Plist already there)

### Phase 2: Enhanced Import System (1-2 hours)

**Files to modify:**
- [`lib/fontist/import/macos.rb`](../lib/fontist/import/macos.rb:1)

**Tasks:**
- [ ] Add `available_catalogs` class method
- [ ] Add `import_all_versions` class method
- [ ] Add `detect_version` private method
- [ ] Replace inline Plist parsing with structured parsers
- [ ] Add version-specific parser selection
- [ ] Update tests in `spec/fontist/import/macos_spec.rb`
- [ ] Test on real macOS system with multiple catalogs

**Success Criteria:**
- Auto-detects available catalog versions
- Correctly parses each version
- Generates valid formulas
- Backward compatible with existing Font6 formulas

### Phase 3: CLI Enhancements (1-2 hours)

**Files to modify:**
- [`lib/fontist/import_cli.rb`](../lib/fontist/import_cli.rb:1)

**Tasks:**
- [ ] Add `--version` option to `import macos` command
- [ ] Add `--all-versions` option
- [ ] Add `macos-catalogs` command to list available catalogs
- [ ] Update help text and documentation

**New Commands:**
```bash
# Import from specific version
fontist import macos --version 7

# Import from all available versions
fontist import macos --all-versions

# List available catalogs
fontist macos-catalogs
```

**Success Criteria:**
- Can import from specific versions
- Can import from all versions
- Clear error messages for unsupported versions

### Phase 4: CI Integration (1 hour)

**Files to modify:**
- [`.github/workflows/discover-fonts.yml`](../.github/workflows/discover-fonts.yml:1)

**Tasks:**
- [ ] Add matrix for macOS versions (13, 14, 15)
- [ ] Add step to upload asset catalogs as artifacts
- [ ] Add step to display catalog information
- [ ] Test workflow on multiple macOS versions

**Success Criteria:**
- Catalogs uploaded as artifacts
- Can download and inspect catalogs from CI
- Works on macOS 13, 14, 15

### Phase 5: Documentation (1 hour)

**Files to update:**
- [`README.adoc`](../README.adoc:1)
- This architecture document

**Tasks:**
- [ ] Document multi-version support
- [ ] Document new CLI options
- [ ] Add examples for each version
- [ ] Document catalog artifact retrieval
- [ ] Update existing macOS section

## Technical Details

### Catalog XML Structure (Font6 Example)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0">
  <dict>
    <key>Assets</key>
    <array>
      <dict>
        <key>AssetType</key>
        <string>com.apple.MobileAsset.Font6</string>

        <key>__BaseURL</key>
        <string>http://updates-http.cdn-apple.com/2019/ios/...</string>

        <key>__RelativePath</key>
        <string>com_apple_MobileAsset_Font6/3c94f1412d7b13bcfcd207c06bb6abaff9e576cf.zip</string>

        <key>PostScriptName</key>
        <array>
          <string>Impact</string>
        </array>

        <key>FontFamily</key>
        <string>Impact</string>

        <key>DisplayName</key>
        <string>Impact</string>
      </dict>
      <!-- More assets... -->
    </array>
  </dict>
</plist>
```

### Plist Parsing Implementation Example

```ruby
module Fontist
  module MacOS
    module Catalog
      # Simple data class for asset information
      class Asset
        attr_reader :base_url, :relative_path, :asset_type,
                    :postscript_names, :font_family, :display_name

        def initialize(data)
          @base_url = data["__BaseURL"]
          @relative_path = data["__RelativePath"]
          @asset_type = data["AssetType"]
          @postscript_names = Array(data["PostScriptName"])
          @font_family = data["FontFamily"]
          @display_name = data["DisplayName"]
        end

        def download_url
          "#{base_url}#{relative_path}"
        end
      end

      class Font6Parser
        def initialize(xml_path)
          @xml_path = xml_path
        end

        def parse
          # Use Plist gem (already a dependency)
          plist = Plist.parse_xml(@xml_path)

          assets = plist["Assets"] || []
          assets.map { |asset_data| Asset.new(asset_data) }
        end
      end
    end
  end
end

# Usage in Import::Macos
def links
  parser = Catalog::Font6Parser.new(@font_xml)
  parser.parse.map(&:download_url)
end
```

## Comparison: Before vs After

### Before (Current)
- ✅ Works for Font6 only
- ✅ Simple Plist parsing inline
- ✅ Generates formulas
- ❌ No Font5, Font7, Font8 support
- ❌ No structured data
- ❌ No reusability
- ❌ Hardcoded path

### After (Proposed)
- ✅ Supports Font5, Font6, Font7, Font8
- ✅ Plist parsing (same gem, structured)
- ✅ Simple Asset data class
- ✅ Auto-detection of versions
- ✅ CI artifacts for catalogs
- ✅ Version-specific handling
- ✅ Future-proof for Font9+
- ✅ No new dependencies

## Timeline

- **Phase 1**: Parsers (1-2 hours)
- **Phase 2**: Import System (1-2 hours)
- **Phase 3**: CLI (1-2 hours)
- **Phase 4**: CI Integration (1 hour)
- **Phase 5**: Documentation (1 hour)

**Total**: 5-8 hours of development time

---

**Status**: Architecture designed with Plist approach, awaiting approval to proceed with implementation.