# macOS Add-on Fonts Architecture

## Overview

This document describes the architecture for implementing automatic installation of macOS add-on fonts through Fontist. macOS provides hundreds of fonts that are licensed for use on macOS but require on-demand download from Apple's servers. Currently, users must manually download these through Font Book. This implementation will automate that process.

## Problem Statement

### Current Limitations
1. macOS ships with ~700 add-on fonts that require manual download via Font Book
2. These fonts are not installable through Fontist despite being system-licensed
3. No programmatic way to discover available and installed add-on fonts
4. Command-line workflows cannot automate font acquisition

### User Stories
- **Developer**: "I need SF Mono font for my IDE but don't want to open Font Book"
- **CI/CD Pipeline**: "I need to ensure specific fonts are installed before running tests"
- **Document Processor**: "I need to install fonts required by a document without user interaction"

## Technical Background

### macOS Asset System
macOS uses a content delivery system for on-demand resources:

**Asset Catalog Location**:
```
/System/Library/AssetsV2/com_apple_MobileAsset_Font{version}/
  ├── com_apple_MobileAsset_Font{version}.xml  # Catalog of all available fonts
  └── {asset-id}.asset/                        # Installed font assets
      └── AssetData/
          └── *.{ttf,ttc,otf,otc}              # Actual font files
```

**Version Numbers**:
- macOS 10.15 (Catalina): `Font3`
- macOS 11.0 (Big Sur): `Font4`
- macOS 12.0+ (Monterey+): `Font5`, `Font6`, `Font7`

**XML Structure** (simplified):
```xml
<plist>
  <dict>
    <key>Assets</key>
    <array>
      <dict>
        <key>AssetType</key>
        <string>com.apple.MobileAsset.Font7</string>
        
        <key>__RelativePath</key>
        <string>PreinstalledAssets/{asset-hash}.asset</string>
        
        <key>PostScriptName</key>
        <array>
          <string>SFMono-Regular</string>
          <string>SFMono-Bold</string>
        </array>
        
        <key>FontFamily</key>
        <string>SF Mono</string>
        
        <key>DisplayName</key>
        <string>SF Mono</string>
        
        <key>__AssetDefaultGarbageCollectionBehavior</key>
        <string>NeverCollected</string>
      </dict>
    </array>
  </dict>
</plist>
```

### System Installation Command
```bash
# Install font by PostScript name
softwareupdate --install-rosetta # (not the right command, need research)

# Apple's fontrestore utility (undocumented)
/System/Library/Frameworks/CoreText.framework/Versions/A/Resources/fontrestore
```

Note: The exact command-line interface for installing individual fonts programmatically needs research. Font Book likely uses private APIs.

## Architectural Design

### Core Design Principles

1. **Object-Oriented Architecture**: Each concept gets its own class with clear responsibilities
2. **Resource Pattern**: Follow existing `ArchiveResource` and `GoogleResource` patterns
3. **Formula-Based**: Represent each font family as a formula
4. **Platform-Specific**: Only available on macOS
5. **System Integration**: Use native macOS tools, no private APIs
6. **Non-Intrusive**: Fonts installed to system location, not `~/.fontist`

### Component Architecture

```
┌─────────────────────────────────────────────────────┐
│              User Interfaces                         │
│  ┌──────────────┐      ┌──────────────┐            │
│  │  CLI         │      │ Ruby API     │            │
│  │  fontist     │      │ Fontist::    │            │
│  │  macos-*     │      │ MacOS::*     │            │
│  └──────┬───────┘      └──────┬───────┘            │
└─────────┼────────────────────┼─────────────────────┘
          │                    │
┌─────────┼────────────────────┼─────────────────────┐
│         │   Core Logic       │                     │
│  ┌──────▼──────┐      ┌──────▼────────┐           │
│  │ Font        │      │ Formula       │           │
│  │  .install() │      │  .find()      │           │
│  └──────┬──────┘      └───────────────┘           │
│         │                                           │
│  ┌──────▼──────────────────┐                       │
│  │ FontInstaller           │                       │
│  │  - Detects source type  │                       │
│  │  - Delegates to Resource│                       │
│  └──────┬──────────────────┘                       │
└─────────┼───────────────────────────────────────────┘
          │
┌─────────┼───────────────────────────────────────────┐
│         │  Resource Layer                           │
│  ┌──────▼────────────────────────────┐             │
│  │ Resources::MacOSAssetResource     │             │
│  │  - files(source_names, &block)    │             │
│  │  - Triggers system installation   │             │
│  │  - Waits for completion           │             │
│  │  - Returns installed paths        │             │
│  └──────┬────────────────────────────┘             │
└─────────┼───────────────────────────────────────────┘
          │
┌─────────┼───────────────────────────────────────────┐
│         │  macOS Integration Layer                  │
│  ┌──────▼──────────┐      ┌────────────────┐       │
│  │ MacOS::         │      │ MacOS::        │       │
│  │ AssetCatalog    │      │ AssetInstaller │       │
│  │  - parse_xml()  │      │  - install()   │       │
│  │  - find_assets()│      │  - installed? │       │
│  └─────────────────┘      └────────────────┘       │
│                                                      │
│  ┌─────────────────┐                                │
│  │ MacOS::         │                                │
│  │ AssetFont       │                                │
│  │  (Lutaml Model) │                                │
│  └─────────────────┘                                │
└──────────────────────────────────────────────────────┘
```

### Class Design

#### 1. `Fontist::MacOS::AssetFont` (Model)

**Purpose**: Represents a font asset from the macOS catalog

**Implementation**:
```ruby
module Fontist
  module MacOS
    class AssetFont < Lutaml::Model::Serializable
      attribute :asset_id, :string           # Unique asset identifier
      attribute :asset_type, :string         # e.g., "com.apple.MobileAsset.Font7"
      attribute :relative_path, :string      # Path within AssetsV2
      attribute :font_family, :string        # e.g., "SF Mono"
      attribute :display_name, :string       # User-friendly name
      attribute :postscript_names, :string, collection: true  # All PS names in asset
      attribute :collection_behavior, :string # Garbage collection setting
      attribute :version, :string            # Asset version
      
      # Derived properties
      def installed?
        File.exist?(installation_path)
      end
      
      def installation_path
        # /System/Library/AssetsV2/.../#{asset_id}.asset/AssetData
        base = "/System/Library/AssetsV2"
        "#{base}/#{asset_type}/#{relative_path}"
      end
      
      def font_files
        return [] unless installed?
        Dir.glob("#{installation_path}/AssetData/*.{ttf,ttc,otf,otc}")
      end
    end
  end
end
```

**Key Design Decisions**:
- Uses Lutaml::Model for consistency with rest of codebase
- Immutable data from system catalog
- Provides helper methods for common queries
- No installation logic (separation of concerns)

---

#### 2. `Fontist::MacOS::AssetCatalog` (Parser/Repository)

**Purpose**: Parse XML catalog and provide query interface

**Implementation**:
```ruby
module Fontist
  module MacOS
    class AssetCatalog
      class << self
        def instance
          @instance ||= new
        end
        
        # High-level query methods
        def find_by_family(family_name)
          instance.find_by_family(family_name)
        end
        
        def find_by_postscript_name(ps_name)
          instance.find_by_postscript_name(ps_name)
        end
        
        def all_assets
          instance.all_assets
        end
      end
      
      def initialize
        @catalog_path = detect_catalog_path
        @assets = parse_catalog
      end
      
      def find_by_family(family_name)
        @assets.select { |a| a.font_family.casecmp?(family_name) }
      end
      
      def find_by_postscript_name(ps_name)
        @assets.find do |a|
          a.postscript_names.any? { |n| n.casecmp?(ps_name) }
        end
      end
      
      def all_assets
        @assets
      end
      
      private
      
      def detect_catalog_path
        # Search for catalog in order of preference
        patterns = [
          "/System/Library/AssetsV2/com_apple_MobileAsset_Font7/*.xml",
          "/System/Library/AssetsV2/com_apple_MobileAsset_Font6/*.xml",
          "/System/Library/AssetsV2/com_apple_MobileAsset_Font5/*.xml",
          "/System/Library/AssetsV2/com_apple_MobileAsset_Font4/*.xml",
          "/System/Library/AssetsV2/com_apple_MobileAsset_Font3/*.xml",
        ]
        
        patterns.each do |pattern|
          paths = Dir.glob(pattern)
          return paths.first unless paths.empty?
        end
        
        raise Errors::MacOSAssetCatalogNotFound,
              "Could not find macOS font asset catalog"
      end
      
      def parse_catalog
        require "plist"
        
        plist = Plist.parse_xml(@catalog_path)
        assets_data = plist.dig("Assets") || []
        
        assets_data.map do |asset_dict|
          parse_asset(asset_dict)
        end.compact
      end
      
      def parse_asset(asset_dict)
        # Only process font assets
        return unless asset_dict["AssetType"]&.include?("Font")
        
        AssetFont.new(
          asset_id: extract_asset_id(asset_dict["__RelativePath"]),
          asset_type: asset_dict["AssetType"],
          relative_path: asset_dict["__RelativePath"],
          font_family: asset_dict["FontFamily"],
          display_name: asset_dict["DisplayName"],
          postscript_names: Array(asset_dict["PostScriptName"]),
          collection_behavior: asset_dict["__AssetDefaultGarbageCollectionBehavior"],
          version: asset_dict["OSVersion"]
        )
      end
      
      def extract_asset_id(relative_path)
        # Extract ID from path like "PreinstalledAssets/{id}.asset"
        File.basename(relative_path, ".asset")
      end
    end
  end
end
```

**Key Design Decisions**:
- Singleton pattern for catalog (only parse once per process)
- Lazy loading of catalog data
- Version detection automatically finds newest catalog
- Pure Ruby parsing using `plist` gem (already in use)
- Case-insensitive searches for user convenience

---

#### 3. `Fontist::MacOS::AssetInstaller` (System Integration)

**Purpose**: Trigger and verify system font installation

**Implementation**:
```ruby
module Fontist
  module MacOS
    class AssetInstaller
      def initialize(asset_font, options = {})
        @asset = asset_font
        @timeout = options[:timeout] || 300  # 5 minutes default
        @no_progress = options[:no_progress] || false
      end
      
      def install
        raise Errors::NotMacOSError unless Utils::System.user_os == :macos
        
        return @asset.font_files if @asset.installed?
        
        trigger_installation
        wait_for_installation
        verify_installation
        
        @asset.font_files
      end
      
      private
      
      def trigger_installation
        Fontist.ui.say("Requesting installation of #{@asset.display_name} from macOS...")
        
        # Strategy 1: Try fontrestore (if available)
        if fontrestore_available?
          install_via_fontrestore
        # Strategy 2: Try softwareupdate (research needed)
        elsif softwareupdate_supports_fonts?
          install_via_softwareupdate
        # Strategy 3: Guide user to Font Book
        else
          raise Errors::MacOSAssetManualInstallRequired.new(@asset)
        end
      end
      
      def fontrestore_available?
        fontrestore_path = "/System/Library/Frameworks/CoreText.framework/" \
                          "Versions/A/Resources/fontrestore"
        File.exist?(fontrestore_path) && File.executable?(fontrestore_path)
      end
      
      def install_via_fontrestore
        # This may require sudo or may not work on newer macOS
        # Research needed for exact command syntax
        command = "fontrestore default -n"  # Placeholder
        
        result = Helpers.run(command)
        unless result.success?
          raise Errors::MacOSAssetInstallationFailed,
                "fontrestore command failed: #{result.stderr}"
        end
      end
      
      def softwareupdate_supports_fonts?
        # Research needed: does softwareupdate support individual font installation?
        false
      end
      
      def install_via_softwareupdate
        # Placeholder for future implementation
        raise NotImplementedError
      end
      
      def wait_for_installation
        start_time = Time.now
        
        loop do
          return if @asset.installed?
          
          elapsed = Time.now - start_time
          if elapsed > @timeout
            raise Errors::MacOSAssetInstallationTimeout.new(@asset, @timeout)
          end
          
          show_progress(elapsed) unless @no_progress
          sleep 2
        end
      end
      
      def show_progress(elapsed)
        dots = "." * (elapsed.to_i / 2)
        Fontist.ui.print("\rWaiting for installation#{dots}")
      end
      
      def verify_installation
        unless @asset.installed?
          raise Errors::MacOSAssetInstallationFailed,
                "Installation completed but font not found at expected location"
        end
        
        Fontist.ui.say("\n#{@asset.display_name} installed successfully")
      end
    end
  end
end
```

**Key Design Decisions**:
- Multiple installation strategies with fallback
- Timeout protection (installation shouldn't hang forever)
- Progress indication during wait
- Verification step ensures installation succeeded
- Error handling for each failure mode

---

#### 4. `Fontist::Resources::MacOSAssetResource` (Resource Implementation)

**Purpose**: Integrate macOS assets into Formula/FontInstaller workflow

**Implementation**:
```ruby
module Fontist
  module Resources
    class MacOSAssetResource
      def initialize(resource, options = {})
        @resource = resource
        @options = options
      end
      
      def files(source_names)
        # source_names are PostScript names from formula
        source_names.flat_map do |ps_name|
          install_and_yield_font(ps_name, &Proc.new)
        end
      end
      
      private
      
      def install_and_yield_font(ps_name)
        asset = find_asset(ps_name)
        installer = MacOS::AssetInstaller.new(asset, @options)
        
        installed_paths = installer.install
        
        installed_paths.map do |path|
          # Yield each font file to the block
          # Unlike archive extraction, these stay in system location
          yield path if block_given?
          path
        end
      end
      
      def find_asset(ps_name)
        asset = MacOS::AssetCatalog.find_by_postscript_name(ps_name)
        
        unless asset
          raise Errors::MacOSAssetNotFound,
                "macOS asset for '#{ps_name}' not found in system catalog"
        end
        
        asset
      end
    end
  end
end
```

**Key Design Decisions**:
- Follows same interface as `ArchiveResource` and `GoogleResource`
- `files` method yields paths to installed fonts
- Fonts remain in system location (not copied to ~/.fontist)
- Each PostScript name triggers separate installation check
- Block-based API matches existing resource pattern

---

#### 5. `Fontist::FontInstaller` Extension

**Changes Required**:
```ruby
module Fontist
  class FontInstaller
    # Existing code...
    
    def resource
      resource_class = case @formula.source
                       when "google"
                         Resources::GoogleResource
                       when "macos_asset"  # NEW
                         Resources::MacOSAssetResource
                       else
                         Resources::ArchiveResource
                       end
      
      resource_class.new(resource_options, no_progress: @no_progress)
    end
    
    # NEW: Override for macOS assets
    def install_font_file(source)
      # For macOS assets, fonts stay in system location
      return source if @formula.source == "macos_asset"
      
      # Original logic for archive/google fonts
      target = Fontist.fonts_path.join(target_filename(File.basename(source))).to_s
      FileUtils.mv(source, target)
      target
    end
  end
end
```

**Key Design Decisions**:
- Minimal changes to existing code
- New resource type: `macos_asset`
- Fonts remain in system location (no copy)
- Backward compatible with existing formulas

---

### Formula Structure

macOS add-on fonts will use a new formula structure:

```yaml
---
name: SF Mono
description: Apple's monospaced font for developers
homepage: https://developer.apple.com/fonts/
open_license: |-
  Apple Font License
  This font is licensed by Apple Inc. for use on macOS systems.
  
platforms:
  - macos

resources:
  sf_mono:
    source: macos_asset
    postscript_names:
      - SFMono-Regular
      - SFMono-Bold
      - SFMono-Medium
      - SFMono-Light
      - SFMono-Semibold
      - SFMono-Heavy
    family: SF Mono

fonts:
  - name: SF Mono
    styles:
      - family_name: SF Mono
        type: Regular
        post_script_name: SFMono-Regular
      - family_name: SF Mono
        type: Bold
        post_script_name: SFMono-Bold
      # ... more styles
```

**Key Attributes**:
- `source: macos_asset` - Triggers MacOSAssetResource
- `postscript_names` - List of fonts to request from system
- `platforms: [macos]` - Only available on macOS
- No `urls` or `sha256` (not downloaded from web)
- `family` - Used to query asset catalog

---

### Import Tool

**Purpose**: Generate formulas from macOS asset catalog

**Implementation**:
```ruby
module Fontist
  module Import
    class MacOSAssetImporter
      def self.import(options = {})
        new(options).import
      end
      
      def initialize(options = {})
        @output_path = options[:output_path] || "./Formulas/macos"
        @catalog = MacOS::AssetCatalog.instance
      end
      
      def import
        FileUtils.mkdir_p(@output_path)
        
        @catalog.all_assets.each do |asset|
          next if asset.installed?  # Skip pre-installed fonts
          
          formula = build_formula(asset)
          save_formula(formula, asset)
        end
      end
      
      private
      
      def build_formula(asset)
        FormulaBuilder.new.tap do |builder|
          builder.name = asset.display_name
          builder.description = "macOS add-on font: #{asset.font_family}"
          builder.homepage = "https://support.apple.com/guide/font-book/"
          builder.open_license = "Apple Font License for macOS"
          builder.platforms = ["macos"]
          
          builder.add_resource(
            name: normalize_name(asset.font_family),
            source: "macos_asset",
            postscript_names: asset.postscript_names,
            family: asset.font_family
          )
          
          builder.add_fonts_from_postscript_names(
            asset.font_family,
            asset.postscript_names
          )
        end
      end
      
      def save_formula(formula, asset)
        filename = "#{normalize_name(asset.font_family)}.yml"
        path = File.join(@output_path, filename)
        
        File.write(path, formula.to_yaml)
        Fontist.ui.say("Generated: #{path}")
      end
      
      def normalize_name(name)
        name.downcase.gsub(/\s+/, "_").gsub(/[^a-z0-9_]/, "")
      end
    end
  end
end
```

---

### CLI Commands

**New Commands**:

```bash
# List all available macOS add-on fonts
fontist macos list

# List installed macOS add-on fonts
fontist macos list --installed

# Show details about a specific font
fontist macos info "SF Mono"

# Install a macOS add-on font
fontist install "SF Mono"  # Works automatically

# Import all macOS fonts to formulas
fontist import macos-assets
```

**CLI Implementation**:
```ruby
module Fontist
  class CLI < Thor
    desc "macos SUBCOMMAND", "Manage macOS add-on fonts"
    subcommand "macos", Fontist::CLI::MacOS
  end
  
  module CLI
    class MacOS < Thor
      desc "list", "List macOS add-on fonts"
      option :installed, type: :boolean, desc: "Show only installed fonts"
      def list
        catalog = Fontist::MacOS::AssetCatalog.instance
        assets = catalog.all_assets
        
        assets = assets.select(&:installed?) if options[:installed]
        
        assets.each do |asset|
          status = asset.installed? ? "[INSTALLED]" : "[AVAILABLE]"
          puts "#{status} #{asset.display_name}"
        end
      end
      
      desc "info FONT", "Show information about a macOS font"
      def info(font_name)
        catalog = Fontist::MacOS::AssetCatalog.instance
        assets = catalog.find_by_family(font_name)
        
        if assets.empty?
          puts "Font '#{font_name}' not found in macOS catalog"
          return
        end
        
        assets.each do |asset|
          puts "Family: #{asset.font_family}"
          puts "Display Name: #{asset.display_name}"
          puts "Installed: #{asset.installed?}"
          puts "PostScript Names:"
          asset.postscript_names.each { |ps| puts "  - #{ps}" }
        end
      end
    end
  end
end
```

---

## Error Handling

**New Error Classes**:

```ruby
module Fontist
  module Errors
    class MacOSAssetError < GeneralError; end
    
    class MacOSAssetCatalogNotFound < MacOSAssetError
      def initialize
        super("macOS font asset catalog not found. " \
              "This feature requires macOS 10.15 or later.")
      end
    end
    
    class MacOSAssetNotFound < MacOSAssetError
      def initialize(ps_name)
        super("Font '#{ps_name}' not found in macOS asset catalog")
      end
    end
    
    class MacOSAssetInstallationFailed < MacOSAssetError
      def initialize(asset, message = nil)
        msg = "Failed to install #{asset.display_name}"
        msg += ": #{message}" if message
        super(msg)
      end
    end
    
    class MacOSAssetInstallationTimeout < MacOSAssetError
      def initialize(asset, timeout)
        super("Installation of #{asset.display_name} timed out after #{timeout} seconds")
      end
    end
    
    class MacOSAssetManualInstallRequired < MacOSAssetError
      def initialize(asset)
        super(<<~MSG)
          Cannot automatically install #{asset.display_name}.
          
          Please install manually using Font Book:
          1. Open Font Book (/Applications/Font Book.app)
          2. Search for "#{asset.font_family}"
          3. Click the download button
          
          Once installed, run fontist again.
        MSG
      end
    end
    
    class NotMacOSError < MacOSAssetError
      def initialize
        super("macOS asset fonts are only available on macOS")
      end
    end
  end
end
```

---

## Testing Strategy

### Unit Tests

```ruby
# spec/fontist/macos/asset_font_spec.rb
RSpec.describe Fontist::MacOS::AssetFont do
  it "detects installation status"
  it "returns correct installation path"
  it "lists font files when installed"
end

# spec/fontist/macos/asset_catalog_spec.rb
RSpec.describe Fontist::MacOS::AssetCatalog do
  it "parses catalog XML"
  it "finds fonts by family name"
  it "finds fonts by PostScript name"
  it "detects catalog version"
end

# spec/fontist/macos/asset_installer_spec.rb
RSpec.describe Fontist::MacOS::AssetInstaller do
  it "skips installation if already installed"
  it "triggers system installation"
  it "waits for installation completion"
  it "times out if installation takes too long"
  it "verifies installation succeeded"
end

# spec/fontist/resources/macos_asset_resource_spec.rb
RSpec.describe Fontist::Resources::MacOSAssetResource do
  it "yields installed font paths"
  it "raises error if font not in catalog"
  it "handles multiple PostScript names"
end
```

### Integration Tests

```ruby
# spec/integration/macos_font_spec.rb
RSpec.describe "macOS font installation", skip_unless: :macos do
  it "installs SF Mono font"
  it "finds installed font via SystemFont"
  it "handles already installed fonts"
  it "works with fontist install command"
end
```

### Manual Testing Checklist

- [ ] Test on macOS 12 (Monterey)
- [ ] Test on macOS 13 (Ventura)
- [ ] Test on macOS 14 (Sonoma)
- [ ] Test on macOS 15 (Sequoia)
- [ ] Verify SF Mono installation
- [ ] Verify NY Times font installation
- [ ] Test with Font Book closed
- [ ] Test with Font Book open
- [ ] Test timeout behavior
- [ ] Test error messages
- [ ] Verify formulas generated correctly
- [ ] Test CLI commands

---

## Implementation Phases

### Phase 1: Core Infrastructure (MVP)
- [ ] `MacOS::AssetFont` model
- [ ] `MacOS::AssetCatalog` parser
- [ ] `MacOS::AssetInstaller` with manual fallback
- [ ] Basic error handling
- [ ] Unit tests

**Deliverable**: Can parse catalog and display available fonts

### Phase 2: Resource Integration
- [ ] `Resources::MacOSAssetResource`
- [ ] `FontInstaller` extension
- [ ] Formula structure definition
- [ ] Integration tests

**Deliverable**: Can trigger installation (may require manual Font Book interaction)

### Phase 3: Formula Generation
- [ ] `Import::MacOSAssetImporter`
- [ ] Generate formulas for all assets
- [ ] Commit to formula repository

**Deliverable**: All macOS fonts available via fontist

### Phase 4: CLI Commands
- [ ] `fontist macos list`
- [ ] `fontist macos info`
- [ ] `fontist import macos-assets`
- [ ] Documentation

**Deliverable**: Complete user-facing features

### Phase 5: Automation Research
- [ ] Research `fontrestore` usage
- [ ] Research `softwareupdate` capabilities
- [ ] Investigate Font Book private APIs
- [ ] Attempt programmatic installation

**Deliverable**: Automated installation if possible

---

## Open Questions

### Technical Research Needed

1. **Installation Command**:
   - What is the official way to trigger font installation?
   - Does `softwareupdate` support individual fonts?
   - Can `fontrestore` be used without sudo?
   - Are there security restrictions?

2. **Permissions**:
   - Does installation require admin privileges?
   - What happens with System Integrity Protection (SIP)?
   - Can installation happen in non-interactive mode?

3. **Notification**:
   - How do we know when installation completes?
   - Is there a system notification we can listen to?
   - File system watching vs. polling?

4. **Version Compatibility**:
   - Do catalog formats differ between macOS versions?
   - Are asset IDs stable across versions?
   - What about beta/preview releases?

### Design Decisions

1. Should we copy fonts to `~/.fontist` or leave in system location?
   - **Recommendation**: Leave in system location
   - **Reasoning**: These are system fonts, moving them may break system expectations

2. Should installation require user interaction?
   - **Phase 1**: User must use Font Book (safer)
   - **Phase 2+**: Attempt automation (research needed)

3. How do we handle formulas for different macOS versions?
   - **Option A**: Single formula with version detection
   - **Option B**: Version-specific formulas
   - **Recommendation**: Single formula, runtime detection

4. Should we generate one formula per font family or one per asset?
   - **Recommendation**: One per font family (matches Google Fonts pattern)
   - **Reasoning**: More intuitive for users

---

## Dependencies

### New Gem Dependencies
- `plist` (~> 3.0) - Already in use, no new dependency

### System Requirements
- macOS 10.15 (Catalina) or later
- Read access to `/System/Library/AssetsV2/`
- Potentially admin privileges for installation

---

## Documentation Requirements

### User Documentation

**README.adoc additions**:
```adoc
== macOS Add-on Fonts

Fontist can install macOS add-on fonts that require on-demand download.

=== Listing Available Fonts

[source,shell]
----
$ fontist macos list
[AVAILABLE] SF Mono
[INSTALLED] New York
[AVAILABLE] SF Arabic
...
----

=== Installing Fonts

[source,shell]
----
$ fontist install "SF Mono"
Requesting installation of SF Mono from macOS...
SF Mono installed successfully
----

=== Supported Fonts

Over 700 fonts are available, including:
- SF Mono (monospaced developer font)
- SF Arabic, SF Compact, etc.
- New York (serif font)
- And many more...
```

### Developer Documentation

- Architecture document (this file)
- Code examples for each class
- Formula format specification
- Testing guide

---

## Success Metrics

### Must Have (MVP)
- [ ] Parse macOS asset catalog successfully
- [ ] Detect installed fonts correctly
- [ ] Trigger installation (manual fallback acceptable)
- [ ] Generate valid formulas
- [ ] Pass all unit tests
- [ ] Works on at least one macOS version

### Should Have (Phase 2)
- [ ] Automated installation (no Font Book interaction)
- [ ] Support macOS 12-15
- [ ] CLI commands functional
- [ ] Complete formula repository

### Nice to Have (Future)
- [ ] Background installation monitoring
- [ ] Batch installation
- [ ] Installation progress reporting
- [ ] Font preview in CLI

---

## Related Issues

- https://github.com/fontist/fontist/issues/293 - macOS on-demand fonts
- https://github.com/fontist/fontist/issues/363 - Additional macOS fonts

---

## References

- [Font Book User Guide](https://support.apple.com/guide/font-book/)
- [macOS Asset System](https://developer.apple.com/documentation/foundation/nsasset)
- [Property List Programming Guide](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/PropertyLists/)