# macOS Add-on Fonts - Implementation Summary

## Quick Reference

**Task**: Extend existing macOS font import to support multiple catalog versions (Font5-Font8) instead of just Font6.

**Existing Code**: [`lib/fontist/import/macos.rb`](../lib/fontist/import/macos.rb:1) already works, just needs extension.

**Approach**: Use Plist gem (already a dependency) with simple data classes and version-specific parsers.

**Estimated Time**: 5-8 hours

## Core Changes Needed

### 1. Create Simple Data Structures (1-2 hours)

**New file**: `lib/fontist/macos/catalog/asset.rb`
```ruby
module Fontist::MacOS::Catalog
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
end
```

### 2. Create Version-Specific Parsers (1-2 hours)

**New files**: 
- `lib/fontist/macos/catalog/base_parser.rb`
- `lib/fontist/macos/catalog/font{5,6,7,8}_parser.rb`

```ruby
module Fontist::MacOS::Catalog
  class BaseParser
    def initialize(xml_path)
      @xml_path = xml_path
    end
    
    def parse
      plist = Plist.parse_xml(@xml_path)
      assets = plist["Assets"] || []
      assets.map { |data| Asset.new(data) }
    end
  end
  
  class Font5Parser < BaseParser; end
  class Font6Parser < BaseParser; end
  class Font7Parser < BaseParser; end
  class Font8Parser < BaseParser; end
end
```

### 3. Extend Import::Macos (1-2 hours)

**Modify**: [`lib/fontist/import/macos.rb`](../lib/fontist/import/macos.rb:1)

**Add these methods**:
```ruby
def self.available_catalogs
  [8, 7, 6, 5].map do |v|
    Dir.glob("/System/Library/AssetsV2/com_apple_MobileAsset_Font#{v}/*.xml").first
  end.compact
end

def self.import_all_versions
  available_catalogs.each { |path| new(path).call }
end

private

def detect_version(path)
  path.match(/Font(\d+)/)[1].to_i
end

def parse_catalog
  parser = case detect_version(@font_xml)
  when 5 then Catalog::Font5Parser
  when 6 then Catalog::Font6Parser
  when 7 then Catalog::Font7Parser
  when 8 then Catalog::Font8Parser
  end
  parser.new(@font_xml).parse
end

def links
  parse_catalog.map(&:download_url)
end
```

### 4. Update CI Workflow (1 hour)

**Modify**: [`.github/workflows/discover-fonts.yml`](../.github/workflows/discover-fonts.yml:1)

**Add to macos job**:
```yaml
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
      fi
    done
```

### 5. CLI Enhancement (1-2 hours)

**Modify**: [`lib/fontist/import_cli.rb`](../lib/fontist/import_cli.rb:55)

```ruby
desc "macos", "Create formulas for macOS on-demand fonts"
option :version, type: :numeric, desc: "Catalog version (5, 6, 7, or 8)"
option :all_versions, type: :boolean, desc: "Import from all available versions"
def macos
  handle_class_options(options)
  require_relative "import/macos"
  
  if options[:all_versions]
    Import::Macos.import_all_versions
  elsif options[:version]
    catalog = "/System/Library/AssetsV2/com_apple_MobileAsset_Font#{options[:version]}/com_apple_MobileAsset_Font#{options[:version]}.xml"
    Import::Macos.new(catalog).call
  else
    Import::Macos.new.call
  end
end

desc "macos-catalogs", "List available macOS font catalogs"
def macos_catalogs
  require_relative "import/macos"
  
  catalogs = Import::Macos.available_catalogs
  if catalogs.empty?
    Fontist.ui.say("No macOS font catalogs found")
  else
    Fontist.ui.say("Available catalogs:")
    catalogs.each do |path|
      version = path.match(/Font(\d+)/)[1]
      Fontist.ui.say("  Font#{version}: #{path}")
    end
  end
end
```

## Catalog Version Mapping

| Version | macOS Releases | Path Example |
|---------|----------------|--------------|
| Font5 | 10.13 (High Sierra), 10.14 (Mojave) | `/System/Library/AssetsV2/com_apple_MobileAsset_Font5/*.xml` |
| Font6 | 10.15 (Catalina), 11 (Big Sur) | `/System/Library/AssetsV2/com_apple_MobileAsset_Font6/*.xml` |
| Font7 | 12 (Monterey), 13 (Ventura), 14 (Sonoma) | `/System/Library/AssetsV2/com_apple_MobileAsset_Font7/*.xml` |
| Font8 | 15 (Sequoia), 26 (future) | `/System/Library/AssetsV2/com_apple_MobileAsset_Font8/*.xml` |

## File Structure

```
lib/fontist/
├── import/
│   └── macos.rb                    # MODIFY: Add version detection
├── macos/                          # NEW DIRECTORY
│   └── catalog/
│       ├── asset.rb                # NEW: Data class
│       ├── base_parser.rb          # NEW: Plist parser
│       ├── font5_parser.rb         # NEW: Font5 handler
│       ├── font6_parser.rb         # NEW: Font6 handler
│       ├── font7_parser.rb         # NEW: Font7 handler
│       └── font8_parser.rb         # NEW: Font8 handler

spec/fontist/
├── import/
│   └── macos_spec.rb               # MODIFY: Add version tests
└── macos/                          # NEW DIRECTORY
    └── catalog/
        ├── asset_spec.rb           # NEW
        ├── font5_parser_spec.rb    # NEW
        ├── font6_parser_spec.rb    # NEW
        ├── font7_parser_spec.rb    # NEW
        └── font8_parser_spec.rb    # NEW
```

## Testing Strategy

### Unit Tests
```ruby
# spec/fontist/macos/catalog/asset_spec.rb
RSpec.describe Fontist::MacOS::Catalog::Asset do
  it "parses asset data correctly"
  it "constructs download URL"
  it "handles missing PostScriptName"
end

# spec/fontist/macos/catalog/font6_parser_spec.rb
RSpec.describe Fontist::MacOS::Catalog::Font6Parser do
  it "parses Font6 XML"
  it "returns Asset objects"
  it "handles empty Assets array"
end
```

### Integration Tests
```ruby
# spec/fontist/import/macos_spec.rb
RSpec.describe Fontist::Import::Macos do
  describe ".available_catalogs" do
    it "finds all available catalogs"
  end
  
  describe ".import_all_versions" do
    it "imports from all versions"
  end
  
  describe "#detect_version" do
    it "extracts version from path"
  end
end
```

## CLI Usage Examples

```bash
# Import from default catalog (auto-detect latest)
fontist import macos

# Import from specific version
fontist import macos --version 7

# Import from all available versions
fontist import macos --all-versions

# List available catalogs
fontist macos-catalogs

# Example output:
# Available catalogs:
#   Font7: /System/Library/AssetsV2/com_apple_MobileAsset_Font7/com_apple_MobileAsset_Font7.xml
#   Font6: /System/Library/AssetsV2/com_apple_MobileAsset_Font6/com_apple_MobileAsset_Font6.xml
```

## Backward Compatibility

✅ **Fully backward compatible**:
- Existing `fontist import macos` works exactly as before
- Default behavior unchanged (uses first available catalog)
- All existing formulas remain valid
- No breaking changes to formula structure

## Dependencies

✅ **No new dependencies required**:
- `plist` gem already in Gemfile
- Uses only standard Ruby libraries
- Works with existing infrastructure

## Success Criteria

- [ ] Can detect all available catalog versions on system
- [ ] Can parse Font5, Font6, Font7, Font8 catalogs
- [ ] Generates valid formulas from all versions
- [ ] CLI commands work as documented
- [ ] All tests pass
- [ ] CI uploads catalog artifacts
- [ ] Backward compatible with existing code
- [ ] Documentation updated

## Implementation Order

1. **Start with CI** (easiest, provides data)
   - Update discover-fonts workflow
   - Get catalog artifacts from CI
   - Analyze actual XML structures

2. **Create data structures**
   - Asset class
   - Base parser
   - Version-specific parsers

3. **Extend Import::Macos**
   - Add version detection
   - Add multi-version support
   - Keep backward compatibility

4. **Update CLI**
   - Add new options
   - Add catalog listing command

5. **Documentation**
   - Update README
   - Add usage examples

## Key Design Decisions

1. **Use Plist, not Lutaml::Model**
   - Native macOS format
   - Already a dependency
   - Simple and proven

2. **Simple data class**
   - Not a full model
   - Just attribute accessors
   - Easy to maintain

3. **Version-specific parsers**
   - Handle schema differences
   - Future-proof
   - Clean separation

4. **Auto-detection with explicit override**
   - Convenience by default
   - Control when needed
   - Graceful fallback

## Next Steps After Architecture Approval

1. Update CI workflow (can do immediately)
2. Wait for CI artifacts to analyze schemas
3. Start implementation with Phase 1
4. Test on real macOS systems
5. Iterate based on findings

---

**Total Estimated Time**: 5-8 hours
**Complexity**: Low-Medium
**Risk**: Low (extends proven approach)
**Value**: High (supports all macOS versions)