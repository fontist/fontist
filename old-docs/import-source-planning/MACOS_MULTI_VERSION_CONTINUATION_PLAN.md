# macOS Multi-Version Font Support - Continuation Plan

## Project Overview

**Goal**: Extend Fontist's existing macOS font import to support multiple catalog versions (Font5-Font8) instead of only Font6.

**Current State**: 
- [`lib/fontist/import/macos.rb`](lib/fontist/import/macos.rb:1) works for Font6 only
- 180+ formulas already exist in [`spec/fixtures/formulas/Formulas/macos/`](spec/fixtures/formulas/Formulas/macos/)
- Uses `plist` gem (already a dependency)

**Architecture**: See [`docs/macos-addon-fonts-architecture-v2.md`](docs/macos-addon-fonts-architecture-v2.md:1)

## Implementation Phases (Compressed Timeline)

### Phase 1: CI Enhancement - Get Catalog Samples (IMMEDIATE - 30min)

**Priority**: CRITICAL - Provides data for all other work

**Files to Modify**:
- `.github/workflows/discover-fonts.yml`

**Changes**:
```yaml
jobs:
  discover-macos:
    strategy:
      matrix:
        version: [13, 14, 15]  # Ventura, Sonoma, Sequoia
    
    steps:
      - name: Find and Display Catalogs
        run: |
          echo "=== Available Font Catalogs ==="
          find /System/Library/AssetsV2/ -name "*.xml" -type f | sort
          for xml in /System/Library/AssetsV2/com_apple_MobileAsset_Font*/*.xml; do
            [ -f "$xml" ] && echo "$(basename $xml): $(wc -c < "$xml") bytes, $(grep -c Assets "$xml" || echo 0) assets"
          done
      
      - name: Upload Catalogs
        uses: actions/upload-artifact@v4
        with:
          name: macos-${{ matrix.version }}-catalogs
          path: /System/Library/AssetsV2/com_apple_MobileAsset_Font*/*.xml
```

**Success Criteria**:
- [ ] Workflow runs on macOS 13, 14, 15
- [ ] Catalogs uploaded as artifacts
- [ ] Can download and inspect catalog XMLs

### Phase 2: Core Data Structures (1 hour)

**Priority**: HIGH - Foundation for everything else

**New Files**:
```
lib/fontist/macos/catalog/
├── asset.rb           # Simple data class
├── base_parser.rb     # Plist-based parser
├── font5_parser.rb
├── font6_parser.rb
├── font7_parser.rb
└── font8_parser.rb
```

**Implementation**:

1. **`lib/fontist/macos/catalog/asset.rb`**:
```ruby
module Fontist
  module MacOS
    module Catalog
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
  end
end
```

2. **`lib/fontist/macos/catalog/base_parser.rb`**:
```ruby
require "plist"

module Fontist
  module MacOS
    module Catalog
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
    end
  end
end
```

3. **Version-specific parsers** (inherit from BaseParser, override if schemas differ)

**Tests**:
```
spec/fontist/macos/catalog/
├── asset_spec.rb
├── base_parser_spec.rb
├── font5_parser_spec.rb
├── font6_parser_spec.rb
├── font7_parser_spec.rb
└── font8_parser_spec.rb
```

**Success Criteria**:
- [ ] Asset class properly extracts all fields
- [ ] BaseParser parses Font6 XML correctly
- [ ] All tests pass
- [ ] No new dependencies needed

### Phase 3: Enhanced Import System (1 hour)

**Priority**: HIGH - Core functionality

**Files to Modify**:
- `lib/fontist/import/macos.rb`

**Changes**:

1. Add class methods for version management:
```ruby
def self.available_catalogs
  [8, 7, 6, 5].map do |version|
    pattern = "/System/Library/AssetsV2/com_apple_MobileAsset_Font#{version}/*.xml"
    Dir.glob(pattern).first
  end.compact
end

def self.import_all_versions
  available_catalogs.each do |catalog_path|
    Fontist.ui.say("Importing from #{File.basename(File.dirname(catalog_path))}...")
    new(catalog_path).call
  end
end
```

2. Add version detection:
```ruby
def initialize(font_xml = nil)
  @font_xml = font_xml || self.class.available_catalogs.first
  raise "No macOS font catalogs found" unless @font_xml
  @version = detect_version(@font_xml)
end

private

def detect_version(path)
  path.match(/Font(\d+)/)[1].to_i
end
```

3. Replace inline parsing with structured parser:
```ruby
def parse_catalog
  parser_class = case @version
  when 5 then Catalog::Font5Parser
  when 6 then Catalog::Font6Parser
  when 7 then Catalog::Font7Parser
  when 8 then Catalog::Font8Parser
  else
    raise "Unsupported catalog version: #{@version}"
  end
  
  parser_class.new(@font_xml).parse
end

def links
  parse_catalog.map(&:download_url)
end
```

**Tests to Update**:
- `spec/fontist/import/macos_spec.rb`

**Success Criteria**:
- [ ] Auto-detects available catalogs
- [ ] Can import from specific version
- [ ] Can import from all versions
- [ ] Backward compatible (existing behavior preserved)
- [ ] All tests pass

### Phase 4: CLI Enhancement (30min)

**Priority**: MEDIUM - User-facing features

**Files to Modify**:
- `lib/fontist/import_cli.rb`

**Changes**:

1. Enhance existing `macos` command:
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
```

2. Add new command for listing catalogs:
```ruby
desc "macos-catalogs", "List available macOS font catalogs"
def macos_catalogs
  require_relative "import/macos"
  
  catalogs = Import::Macos.available_catalogs
  if catalogs.empty?
    Fontist.ui.say("No macOS font catalogs found on this system")
  else
    Fontist.ui.say("Available macOS font catalogs:")
    catalogs.each do |path|
      version = path.match(/Font(\d+)/)[1]
      Fontist.ui.say("  Font#{version}: #{path}")
    end
  end
end
```

**Success Criteria**:
- [ ] `fontist import macos` works (backward compatible)
- [ ] `fontist import macos --version 7` works
- [ ] `fontist import macos --all-versions` works
- [ ] `fontist macos-catalogs` lists available catalogs
- [ ] Help text clear and accurate

### Phase 5: Documentation (30min)

**Priority**: MEDIUM - User communication

**Files to Update**:
- `README.adoc` - Add macOS multi-version section
- Move temporary docs to `old-docs/`

**Changes to README.adoc**:

Add new section:
```adoc
=== macOS On-Demand Fonts (Multiple Versions)

Fontist can import and install macOS on-demand fonts from multiple system versions.

==== Supported Versions

[cols="1,2,3"]
|===
|Version |macOS Releases |Path

|Font5
|10.13 (High Sierra), 10.14 (Mojave)
|`/System/Library/AssetsV2/com_apple_MobileAsset_Font5/`

|Font6
|10.15 (Catalina), 11 (Big Sur)
|`/System/Library/AssetsV2/com_apple_MobileAsset_Font6/`

|Font7
|12 (Monterey), 13 (Ventura), 14 (Sonoma)
|`/System/Library/AssetsV2/com_apple_MobileAsset_Font7/`

|Font8
|15 (Sequoia), 26 (future)
|`/System/Library/AssetsV2/com_apple_MobileAsset_Font8/`
|===

==== Usage

.Import from auto-detected latest version
[source,shell]
----
fontist import macos
----

.Import from specific version
[source,shell]
----
fontist import macos --version 7
----

.Import from all available versions
[source,shell]
----
fontist import macos --all-versions
----

.List available catalogs
[source,shell]
----
fontist macos-catalogs
# Available macOS font catalogs:
#   Font7: /System/Library/AssetsV2/com_apple_MobileAsset_Font7/...
#   Font6: /System/Library/AssetsV2/com_apple_MobileAsset_Font6/...
----
```

**Files to Move**:
```
docs/macos-addon-fonts-architecture.md → old-docs/
docs/macos-addon-fonts-diagram.md → old-docs/
docs/macos-addon-fonts-implementation-plan.md → old-docs/
```

**Keep**:
- `docs/macos-addon-fonts-architecture-v2.md` (final architecture)
- `docs/macos-addon-fonts-implementation-summary.md` (quick ref)

**Success Criteria**:
- [ ] README.adoc updated with multi-version support
- [ ] Examples clear and accurate
- [ ] Old working docs moved to old-docs/
- [ ] Architecture docs organized

## Testing Strategy

### Unit Tests
```ruby
# spec/fontist/macos/catalog/asset_spec.rb
RSpec.describe Fontist::MacOS::Catalog::Asset do
  let(:data) do
    {
      "__BaseURL" => "http://example.com/",
      "__RelativePath" => "path/to/font.zip",
      "AssetType" => "com.apple.MobileAsset.Font6",
      "PostScriptName" => ["Impact"],
      "FontFamily" => "Impact",
      "DisplayName" => "Impact"
    }
  end
  
  it "initializes with data hash" do
    asset = described_class.new(data)
    expect(asset.base_url).to eq("http://example.com/")
    expect(asset.relative_path).to eq("path/to/font.zip")
  end
  
  it "constructs download URL" do
    asset = described_class.new(data)
    expect(asset.download_url).to eq("http://example.com/path/to/font.zip")
  end
  
  it "handles array of PostScript names" do
    asset = described_class.new(data)
    expect(asset.postscript_names).to eq(["Impact"])
  end
end

# spec/fontist/macos/catalog/base_parser_spec.rb
RSpec.describe Fontist::MacOS::Catalog::BaseParser do
  let(:xml_path) { "spec/fixtures/macos/Font6_sample.xml" }
  
  it "parses XML and returns Asset objects" do
    parser = described_class.new(xml_path)
    assets = parser.parse
    
    expect(assets).to all(be_a(Fontist::MacOS::Catalog::Asset))
    expect(assets).not_to be_empty
  end
  
  it "handles empty Assets array" do
    # Test with empty catalog
  end
end
```

### Integration Tests
```ruby
# spec/fontist/import/macos_spec.rb
RSpec.describe Fontist::Import::Macos do
  describe ".available_catalogs" do
    it "returns array of catalog paths" do
      catalogs = described_class.available_catalogs
      expect(catalogs).to be_an(Array)
    end
  end
  
  describe "#detect_version" do
    it "extracts version from path" do
      macos = described_class.new
      version = macos.send(:detect_version, "/path/to/Font7/catalog.xml")
      expect(version).to eq(7)
    end
  end
end
```

## Quality Gates

### Before Each Phase
- [ ] All existing tests pass
- [ ] Rubocop passes with no new violations
- [ ] Architecture principles maintained (OOP, MECE, separation of concerns)

### Before Completion
- [ ] All new tests pass
- [ ] Integration tests pass on real macOS
- [ ] Documentation complete and accurate
- [ ] Backward compatibility verified
- [ ] No regressions in existing formulas

## Risk Mitigation

### Schema Differences Risk
**Risk**: Font5/7/8 may have different schemas than Font6
**Mitigation**: 
- Phase 1 provides real samples
- Version-specific parsers can override as needed
- BaseParser handles common case

### Backward Compatibility Risk
**Risk**: Breaking existing users
**Mitigation**:
- Default behavior unchanged
- All existing tests must pass
- Existing formulas remain valid

### Platform Availability Risk
**Risk**: Not all versions available on all systems
**Mitigation**:
- Auto-detection finds what's available
- Graceful handling of missing catalogs
- Clear error messages

## Success Criteria (Overall)

- [ ] Can import from Font5, Font6, Font7, Font8
- [ ] Auto-detects available versions
- [ ] CLI has version-specific options
- [ ] All tests pass (100% of working tests)
- [ ] Backward compatible
- [ ] Documentation complete
- [ ] CI provides catalog artifacts
- [ ] No new dependencies
- [ ] Maintains OOP principles
- [ ] MECE architecture
- [ ] Proper separation of concerns

## Timeline (Compressed)

| Phase | Duration | Dependencies |
|-------|----------|--------------|
| Phase 1: CI | 30min | None - DO FIRST |
| Phase 2: Data Structures | 1h | Phase 1 (for samples) |
| Phase 3: Import | 1h | Phase 2 |
| Phase 4: CLI | 30min | Phase 3 |
| Phase 5: Docs | 30min | All above |

**Total**: 3.5 hours (compressed from original 5-8 hours)

## Implementation Order (Parallel Where Possible)

1. **Immediate**: Phase 1 (CI) - can run independently
2. **After CI artifacts**: Phase 2 (analyze schemas, build data structures)
3. **Parallel**: Phase 3 (import) + Phase 4 (CLI) can partially overlap
4. **Final**: Phase 5 (documentation) after all features working

## Definition of Done

✅ **Feature Complete**:
- All 5 phases implemented
- Tests passing
- Documentation updated

✅ **Quality**:
- Rubocop clean
- OOP principles maintained
- MECE architecture
- Proper separation of concerns

✅ **User Ready**:
- CLI commands working
- Clear error messages
- Examples in documentation
- Backward compatible

✅ **Production Ready**:
- CI passing
- All tests green
- No regressions
- Ready for release