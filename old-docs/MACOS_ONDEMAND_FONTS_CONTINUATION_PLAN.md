# macOS On-Demand Fonts Implementation Plan

## Executive Summary

Implement full support for macOS on-demand fonts, allowing users to:
1. Specify macOS fonts in manifests (e.g., "Al Bayan", "Baloo Da 2")
2. Install fonts directly from Apple's CDN to system directories
3. Validate platform compatibility before installation
4. Auto-update system index to recognize newly installed fonts
5. Inform users when fonts are platform-specific

**Target Completion**: 4 compressed phases (~4 hours total)

## Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                  User Manifest                           │
│  fonts:                                                  │
│    "Al Bayan": ["Plain"]  # macOS-only font             │
└────────────────┬────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────┐
│           Fontist::Manifest.install                      │
│  1. Check system fonts                                   │
│  2. Find formula via FontIndex                           │
│  3. Validate platform compatibility                      │
└────────────────┬────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────┐
│         Fontist::Formula (macOS/al_bayan.yml)           │
│  name: Al Bayan                                          │
│  platforms: [macos]  ← Platform restriction             │
│  resources:                                              │
│    - source: apple_cdn                                   │
│      urls: [https://updates.cdn-apple.com/...]          │
└────────────────┬────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────┐
│        Resources::AppleCDNResource                       │
│  1. Download .zip from Apple CDN                         │
│  2. Extract fonts                                        │
│  3. Install to macOS system directory                    │
└────────────────┬────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────┐
│  /System/Library/AssetsV2/com_apple_MobileAsset_Font*/  │
│    .asset/AssetData/                                     │
│      Al-Bayan.ttf  ← Installed font                     │
└────────────────┬────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────┐
│     Fontist::SystemIndex.rebuild                         │
│  Scan new paths, cache font metadata                     │
└─────────────────────────────────────────────────────────┘
```

## Core Design Principles

### 1. Platform-Aware Formula Model
```ruby
class Formula < Lutaml::Model::Serializable
  attribute :platforms, :string, collection: true  # ["macos", "linux", "windows"]

  def compatible_with_platform?(platform = nil)
    target = platform || Utils::System.user_os
    platforms.nil? || platforms.empty? || platforms.include?(target.to_s)
  end

  def platform_restriction_message
    return nil if compatible_with_platform?

    "This font is only available for: #{platforms.join(', ')}. " \
    "Current platform: #{Utils::System.user_os}"
  end
end
```

### 2. Apple CDN Resource Handler
```ruby
# lib/fontist/resources/apple_cdn_resource.rb
module Fontist
  module Resources
    class AppleCDNResource
      def initialize(resource_options, no_progress: false)
        @options = resource_options
        @no_progress = no_progress
      end

      def files(source_files)
        download_and_extract do |extracted_path|
          find_fonts_in(extracted_path, source_files).each do |font_path|
            yield font_path
          end
        end
      end

      private

      def download_and_extract
        archive_path = download_from_apple_cdn
        extract_to_temp(archive_path) do |temp_dir|
          yield temp_dir
        end
      end

      def install_directory
        # Install to proper macOS AssetData directory
        base = "/System/Library/AssetsV2"
        version = detect_font_version  # Font7 or Font8
        asset_id = generate_asset_identifier

        Pathname.new(base)
          .join("com_apple_MobileAsset_Font#{version}")
          .join("#{asset_id}.asset")
          .join("AssetData")
      end
    end
  end
end
```

### 3. Manifest Platform Validation
```ruby
# lib/fontist/manifest.rb - ManifestFont enhancement
class ManifestFont < Lutaml::Model::Serializable
  def install(confirmation: "no", hide_licenses: false, no_progress: false)
    font_formula = Fontist::Formula.find(name)

    # Platform validation before installation
    unless font_formula.compatible_with_platform?
      raise Fontist::Errors::PlatformMismatchError.new(
        name,
        font_formula.platforms,
        Fontist::Utils::System.user_os
      )
    end

    Fontist::Font.install(
      name,
      force: true,
      confirmation: confirmation,
      hide_licenses: hide_licenses,
      no_progress: no_progress,
    )
  end
end
```

### 4. System Index Enhancement
```ruby
# lib/fontist/system.yml - Add PrivateFrameworks paths
macos:
  paths:
    - /Library/Fonts/**/**.{ttf,ttc}
    - /System/Library/Fonts/**/**.{ttf,ttc}
    - /Users/{username}/Library/Fonts/**.{ttf,ttc}
    - /Applications/Microsoft**/Contents/Resources/**/**.{ttf,ttc}
    - /System/Library/AssetsV2/com_apple_MobileAsset_Font*/*.asset/AssetData/**.{ttf,ttc,otf,otc}
    # NEW: PrivateFrameworks paths
    - /System/Library/PrivateFrameworks/FontServices.framework/Resources/Fonts/Subsets/**/**.{ttf,ttc,otf}
    - /System/Library/PrivateFrameworks/FontServices.framework/Resources/Fonts/ApplicationSupport/**/**.{ttf,ttc,otf}
```

## Implementation Phases

### Phase 1: Data Structures & Catalog Parsing (1.5 hours)

**Goal**: Parse Font7/Font8 catalogs and create structured data models

#### 1.1 Create Catalog Parser Architecture
```
lib/fontist/macos/catalog/
├── asset.rb              # Data class for font asset
├── base_parser.rb        # Plist.parse_xml wrapper
├── font7_parser.rb       # Font7-specific parser
├── font8_parser.rb       # Font8-specific (filters PlatformDelivery)
└── catalog_manager.rb    # Auto-detect and coordinate parsers
```

**Key Implementation**:

`lib/fontist/macos/catalog/asset.rb`:
```ruby
module Fontist
  module Macos
    module Catalog
      class Asset
        attr_reader :base_url, :relative_path, :font_info, :build,
                    :compatibility_version, :design_languages, :prerequisite

        def initialize(data)
          @base_url = data["__BaseURL"]
          @relative_path = data["__RelativePath"]
          @font_info = data["FontInfo4"] || []
          @build = data["Build"]
          @compatibility_version = data["_CompatibilityVersion"]
          @design_languages = data["FontDesignLanguages"] || []
          @prerequisite = data["Prerequisite"] || []
        end

        def download_url
          "#{@base_url}#{@relative_path}"
        end

        def fonts
          @font_info.map { |info| FontInfo.new(info) }
        end

        def postscript_names
          fonts.map(&:postscript_name).compact
        end

        def font_families
          fonts.map(&:font_family_name).compact.uniq
        end
      end

      class FontInfo
        attr_reader :postscript_name, :font_family_name, :font_style_name,
                    :preferred_family_name, :preferred_style_name

        def initialize(data)
          @postscript_name = data["PostScriptFontName"]
          @font_family_name = data["FontFamilyName"]
          @font_style_name = data["FontStyleName"]
          @preferred_family_name = data["PreferredFamilyName"]
          @preferred_style_name = data["PreferredStyleName"]
        end

        def display_names
          @data["DisplayNames"] || {}
        end

        def macos_compatible?(data)
          platform_delivery = data["PlatformDelivery"]
          return true if platform_delivery.nil?

          platform_delivery.any? do |platform|
            platform.include?("macOS") && platform != "macOS-invisible"
          end
        end
      end
    end
  end
end
```

`lib/fontist/macos/catalog/base_parser.rb`:
```ruby
module Fontist
  module Macos
    module Catalog
      class BaseParser
        attr_reader :xml_path

        def initialize(xml_path)
          @xml_path = xml_path
          @data = nil
        end

        def assets
          parse_assets.map { |asset_data| Asset.new(asset_data) }
        end

        def catalog_version
          # Extract from filename: com_apple_MobileAsset_Font7.xml
          File.basename(@xml_path).match(/Font(\d+)/)[1].to_i
        end

        private

        def parse_assets
          data["Assets"] || []
        end

        def data
          @data ||= Plist.parse_xml(File.read(@xml_path))
        end
      end
    end
  end
end
```

`lib/fontist/macos/catalog/font8_parser.rb`:
```ruby
module Fontist
  module Macos
    module Catalog
      class Font8Parser < BaseParser
        private

        # Override to filter macOS-compatible assets only
        def parse_assets
          super.select { |asset| macos_compatible?(asset) }
        end

        def macos_compatible?(asset)
          platform_delivery = asset["PlatformDelivery"]
          return true if platform_delivery.nil?

          platform_delivery.any? do |platform|
            platform.include?("macOS") && platform != "macOS-invisible"
          end
        end
      end
    end
  end
end
```

`lib/fontist/macos/catalog/catalog_manager.rb`:
```ruby
module Fontist
  module Macos
    module Catalog
      class CatalogManager
        CATALOG_BASE_PATH = "/System/Library/AssetsV2"

        def self.available_catalogs
          Dir.glob("#{CATALOG_BASE_PATH}/com_apple_MobileAsset_Font*/*.xml")
             .sort
        end

        def self.parser_for(catalog_path)
          version = detect_version(catalog_path)

          case version
          when 7
            Font7Parser.new(catalog_path)
          when 8
            Font8Parser.new(catalog_path)
          else
            raise "Unsupported Font catalog version: #{version}"
          end
        end

        def self.detect_version(catalog_path)
          File.basename(catalog_path).match(/Font(\d+)/)[1].to_i
        end

        def self.all_assets
          available_catalogs.flat_map do |catalog_path|
            parser_for(catalog_path).assets
          end
        end
      end
    end
  end
end
```

#### 1.2 Enhance Import::Macos
```ruby
# lib/fontist/import/macos.rb
module Fontist
  module Import
    class Macos
      def initialize(catalog_path: nil, version: nil)
        @catalog_path = catalog_path || auto_detect_catalog(version)
      end

      def call
        parser = Macos::Catalog::CatalogManager.parser_for(@catalog_path)

        parser.assets.each do |asset|
          create_formula_from_asset(asset)
        end

        Fontist::Index.rebuild
        Fontist.ui.success("Created #{parser.assets.size} formulas.")
      end

      private

      def auto_detect_catalog(version)
        catalogs = Macos::Catalog::CatalogManager.available_catalogs

        if version
          catalogs.find { |path| path.include?("Font#{version}") }
        else
          # Prefer latest version
          catalogs.last
        end
      end

      def create_formula_from_asset(asset)
        # Generate one formula per asset (may contain multiple fonts)
        formula_data = FormulaBuilder.build_from_asset(asset)

        formula_path = Fontist.formulas_path
          .join("macos")
          .join("#{sanitize_name(asset.font_families.first)}.yml")

        FileUtils.mkdir_p(formula_path.dirname)
        File.write(formula_path, formula_data.to_yaml)

        Fontist.ui.success("Formula created: #{formula_path}")
      end

      def sanitize_name(name)
        name.downcase.gsub(/[^a-z0-9]+/, "_")
      end
    end
  end
end
```

**Tests to Create**:
- `spec/fontist/macos/catalog/asset_spec.rb`
- `spec/fontist/macos/catalog/base_parser_spec.rb`
- `spec/fontist/macos/catalog/font7_parser_spec.rb`
- `spec/fontist/macos/catalog/font8_parser_spec.rb`
- `spec/fontist/macos/catalog/catalog_manager_spec.rb`

**Verification**:
```bash
bundle exec rspec spec/fontist/macos/catalog/
bundle exec rubocop lib/fontist/macos/
```

---

### Phase 2: Resource Handler & Installation (1.5 hours)

**Goal**: Implement Apple CDN download and system directory installation

#### 2.1 Create AppleCDNResource
```ruby
# lib/fontist/resources/apple_cdn_resource.rb
module Fontist
  module Resources
    class AppleCDNResource
      def initialize(resource_options, no_progress: false)
        @options = resource_options
        @no_progress = no_progress
      end

      def files(source_files)
        archive_path = download_archive

        extract_archive(archive_path) do |extracted_dir|
          find_fonts(extracted_dir, source_files).each do |font_path|
            yield font_path
          end
        end
      end

      private

      def download_archive
        url = @options.urls.first
        cache_path = Utils::Cache.file_path(url)

        return cache_path if File.exist?(cache_path)

        Fontist.ui.say("Downloading from Apple CDN...")
        Utils::Downloader.download(
          url,
          cache_path,
          sha256: @options.sha256&.first,
          progress_bar: !@no_progress
        )

        cache_path
      end

      def extract_archive(archive_path)
        Dir.mktmpdir do |temp_dir|
          Fontist.ui.say("Extracting fonts...")
          Excavate::Archive.new(archive_path).extract(temp_dir)
          yield temp_dir
        end
      end

      def find_fonts(dir, source_files)
        source_files.flat_map do |filename|
          Dir.glob("#{dir}/**/#{filename}")
        end
      end
    end
  end
end
```

#### 2.2 Enhance FontInstaller
```ruby
# lib/fontist/font_installer.rb - Add platform validation
class FontInstaller
  def install(confirmation:)
    raise_platform_error unless platform_compatible?
    raise_fontist_version_error unless supported_version?
    raise_licensing_error unless license_is_accepted?(confirmation)

    install_font
  end

  private

  def platform_compatible?
    @formula.compatible_with_platform?
  end

  def raise_platform_error
    raise Fontist::Errors::PlatformMismatchError,
          @formula.platform_restriction_message
  end

  def resource
    case @formula.source
    when "google"
      Resources::GoogleResource.new(resource_options, no_progress: @no_progress)
    when "apple_cdn"
      Resources::AppleCDNResource.new(resource_options, no_progress: @no_progress)
    else
      Resources::ArchiveResource.new(resource_options, no_progress: @no_progress)
    end
  end

  def install_font_file(source)
    if @formula.source == "apple_cdn"
      install_to_system_directory(source)
    else
      install_to_fontist_directory(source)
    end
  end

  def install_to_system_directory(source)
    # macOS system installation
    target_dir = macos_asset_directory
    FileUtils.mkdir_p(target_dir)

    target = target_dir.join(File.basename(source))
    FileUtils.cp(source, target)

    # Update system index after installation
    Fontist::SystemIndex.rebuild

    target.to_s
  end

  def install_to_fontist_directory(source)
    target = Fontist.fonts_path.join(target_filename(File.basename(source))).to_s
    FileUtils.mv(source, target)
    target
  end

  def macos_asset_directory
    # Install to: /System/Library/AssetsV2/com_apple_MobileAsset_Font*/
    # Generate unique asset identifier
    asset_id = Digest::SHA256.hexdigest(@formula.key)[0..39]
    version = detect_catalog_version

    Pathname.new("/System/Library/AssetsV2")
      .join("com_apple_MobileAsset_Font#{version}")
      .join("#{asset_id}.asset")
      .join("AssetData")
  end

  def detect_catalog_version
    # Extract from formula metadata or default to 8
    @formula.resources.first.metadata&.dig("catalog_version") || 8
  end
end
```

#### 2.3 Add Platform Validation to Formula
```ruby
# lib/fontist/formula.rb - Enhance Formula class
class Formula < Lutaml::Model::Serializable
  def compatible_with_platform?(platform = nil)
    target = platform || Utils::System.user_os.to_s

    # No platform restrictions = compatible with all
    return true if platforms.nil? || platforms.empty?

    platforms.include?(target)
  end

  def platform_restriction_message
    return nil if compatible_with_platform?

    current = Utils::System.user_os
    "Font '#{name}' is only available for: #{platforms.join(', ')}. " \
    "Your current platform is: #{current}. " \
    "This font cannot be installed on your system."
  end

  def requires_system_installation?
    source == "apple_cdn" && platforms&.include?("macos")
  end
end
```

#### 2.4 Create PlatformMismatchError
```ruby
# lib/fontist/errors.rb - Add new error class
module Errors
  class PlatformMismatchError < GeneralError
    attr_reader :font_name, :required_platforms, :current_platform

    def initialize(font_name, required_platforms, current_platform)
      @font_name = font_name
      @required_platforms = Array(required_platforms)
      @current_platform = current_platform

      super(build_message)
    end

    def build_message
      "Font '#{font_name}' is only available for: #{required_platforms.join(', ')}. " \
      "Your current platform is: #{current_platform}. " \
      "This font is licensed exclusively for the specified platform(s) and " \
      "cannot be installed on your system."
    end
  end
end
```

**Tests to Create**:
- `spec/fontist/resources/apple_cdn_resource_spec.rb`
- `spec/fontist/font_installer_spec.rb` (enhance with platform tests)
- `spec/fontist/formula_spec.rb` (add platform validation tests)
- `spec/fontist/errors_spec.rb` (add PlatformMismatchError tests)

**Verification**:
```bash
bundle exec rspec spec/fontist/resources/apple_cdn_resource_spec.rb
bundle exec rspec spec/fontist/font_installer_spec.rb
```

---

### Phase 3: Manifest Integration & System Index (1 hour)

**Goal**: Enable manifest-based macOS font installation with platform validation

#### 3.1 Enhance ManifestFont
```ruby
# lib/fontist/manifest.rb
class ManifestFont < Lutaml::Model::Serializable
  def install(confirmation: "no", hide_licenses: false, no_progress: false)
    validate_platform_compatibility!

    Fontist::Font.install(
      name,
      force: true,
      confirmation: confirmation,
      hide_licenses: hide_licenses,
      no_progress: no_progress,
    )
  rescue Fontist::Errors::PlatformMismatchError => e
    # Re-raise with manifest context
    Fontist.ui.error(e.message)
    raise
  end

  private

  def validate_platform_compatibility!
    formula = Fontist::Formula.find(name)
    return if formula.nil?

    unless formula.compatible_with_platform?
      raise Fontist::Errors::PlatformMismatchError.new(
        name,
        formula.platforms,
        Fontist::Utils::System.user_os
      )
    end
  end
end
```

#### 3.2 Update system.yml
```yaml
# lib/fontist/system.yml
system:
  macos:
    paths:
      - /Library/Fonts/**/**.{ttf,ttc}
      - /System/Library/Fonts/**/**.{ttf,ttc}
      - /Users/{username}/Library/Fonts/**.{ttf,ttc}
      - /Applications/Microsoft**/Contents/Resources/**/**.{ttf,ttc}
      - /System/Library/AssetsV2/com_apple_MobileAsset_Font*/*.asset/AssetData/**.{ttf,ttc,otf,otc}
      # NEW: PrivateFrameworks font directories
      - /System/Library/PrivateFrameworks/FontServices.framework/Resources/Fonts/Subsets/**/**.{ttf,ttc,otf}
      - /System/Library/PrivateFrameworks/FontServices.framework/Resources/Fonts/ApplicationSupport/**/**.{ttf,ttc,otf}
```

#### 3.3 Enhance SystemIndex
```ruby
# lib/fontist/system_index.rb - Add rebuild hook
class SystemIndex
  def self.rebuild
    # Clear cache
    @index = nil

    # Rebuild index
    new.build_index

    Fontist.ui.success("System font index rebuilt successfully.")
  end

  def self.auto_rebuild_if_needed
    # Check if new fonts were added to system directories
    current_count = count_system_fonts
    cached_count = load_cached_count

    if current_count != cached_count
      Fontist.ui.say("New system fonts detected. Rebuilding index...")
      rebuild
      save_cached_count(current_count)
    end
  end

  private

  def self.count_system_fonts
    # Count fonts in all system directories
    system_paths.sum do |pattern|
      Dir.glob(pattern).count
    end
  end

  def self.system_paths
    # Load from system.yml based on current OS
    config = YAML.load_file(
      File.expand_path("system.yml", __dir__)
    )

    os_config = config["system"][Utils::System.user_os.to_s]
    os_config["paths"]
  end
end
```

**Tests to Create**:
- `spec/fontist/manifest_spec.rb` (enhance with platform tests)
- `spec/fontist/system_index_spec.rb` (add rebuild tests)
- Integration test: `spec/integration/macos_ondemand_spec.rb`

**Verification**:
```bash
# Test platform validation
bundle exec rspec spec/fontist/manifest_spec.rb

# Test system index updates
bundle exec rspec spec/fontist/system_index_spec.rb
```

---

### Phase 4: CLI & Documentation (30 minutes)

**Goal**: Add CLI commands and document the feature

#### 4.1 Enhance ImportCLI
```ruby
# lib/fontist/import_cli.rb
class ImportCLI < Thor
  desc "macos [OPTIONS]", "Import macOS on-demand fonts"
  option :version, type: :numeric, desc: "Import specific Font version (7 or 8)"
  option :all_versions, type: :boolean, desc: "Import all available versions"
  option :catalog_path, type: :string, desc: "Path to specific catalog XML"
  def macos
    if options[:all_versions]
      import_all_macos_versions
    else
      import_specific_macos_version
    end
  end

  desc "macos-catalogs", "List available macOS font catalogs"
  def macos_catalogs
    catalogs = Fontist::Macos::Catalog::CatalogManager.available_catalogs

    if catalogs.empty?
      Fontist.ui.error("No macOS font catalogs found.")
      Fontist.ui.say("Expected location: /System/Library/AssetsV2/")
      return
    end

    Fontist.ui.say("Available macOS Font Catalogs:")
    catalogs.each do |catalog_path|
      version = Fontist::Macos::Catalog::CatalogManager.detect_version(catalog_path)
      size = File.size(catalog_path)

      Fontist.ui.say("  Font#{version}: #{catalog_path} (#{format_bytes(size)})")
    end
  end

  private

  def import_all_macos_versions
    catalogs = Fontist::Macos::Catalog::CatalogManager.available_catalogs

    catalogs.each do |catalog_path|
      version = Fontist::Macos::Catalog::CatalogManager.detect_version(catalog_path)
      Fontist.ui.say("Importing Font#{version}...")

      Fontist::Import::Macos.new(catalog_path: catalog_path).call
    end
  end

  def import_specific_macos_version
    catalog_path = if options[:catalog_path]
                     options[:catalog_path]
                   else
                     find_catalog_by_version(options[:version])
                   end

    Fontist::Import::Macos.new(catalog_path: catalog_path).call
  end

  def find_catalog_by_version(version)
    catalogs = Fontist::Macos::Catalog::CatalogManager.available_catalogs

    if version
      catalogs.find { |path| path.include?("Font#{version}") } ||
        raise("Font#{version} catalog not found")
    else
      catalogs.last || raise("No macOS font catalogs found")
    end
  end

  def format_bytes(bytes)
    if bytes < 1024
      "#{bytes} B"
    elsif bytes < 1024 * 1024
      "#{(bytes / 1024.0).round(1)} KB"
    else
      "#{(bytes / (1024.0 * 1024)).round(1)} MB"
    end
  end
end
```

#### 4.2 Update README.adoc
```adoc
== macOS On-Demand Fonts

Fontist provides full support for macOS on-demand fonts (Font7 and Font8 catalogs), allowing automated installation of Apple's downloadable font collection.

=== Features

* Install 700+ macOS add-on fonts directly from Apple's CDN
* Platform validation ensures fonts are only installed on compatible systems
* Automatic system index updates after installation
* Manifest-based batch installation
* Support for Font7 (macOS Monterey/Ventura/Sonoma) and Font8 (macOS Sequoia)

=== Platform Compatibility

macOS on-demand fonts are *exclusively licensed for macOS* and cannot be installed on other platforms. Fontist validates platform compatibility before installation and provides clear error messages if a font is requested on an incompatible system.

[source,yaml]
----
# manifest.yml
---
"Al Bayan":
  - Plain
"Baloo Da 2":
  - Regular
  - Bold
----

If this manifest is run on Linux or Windows:
[source,bash]
----
$ fontist manifest install manifest.yml
Error: Font 'Al Bayan' is only available for: macos.
Your current platform is: linux.
This font is licensed exclusively for the specified platform(s) and cannot be installed on your system.
----

=== Installation from Manifest

[source,bash]
----
# Install macOS fonts specified in manifest
$ fontist manifest install fonts.yml

# On macOS: Downloads from Apple CDN and installs to system directory
# On other OS: Raises platform compatibility error
----

=== Formula Management

==== List Available Catalogs

[source,bash]
----
$ fontist macos-catalogs
Available macOS Font Catalogs:
  Font7: /System/Library/AssetsV2/com_apple_MobileAsset_Font7/com_apple_MobileAsset_Font7.xml (47.7 MB)
  Font8: /System/Library/AssetsV2/com_apple_MobileAsset_Font8/com_apple_MobileAsset_Font8.xml (2.3 MB)
----

==== Import Font Formulas

[source,bash]
----
# Import latest version (Font8)
$ fontist import macos

# Import specific version
$ fontist import macos --version 7

# Import all available versions
$ fontist import macos --all-versions

# Import from custom catalog file
$ fontist import macos --catalog-path /path/to/catalog.xml
----

=== System Integration

After installation, macOS on-demand fonts are:

1. *Installed to system directories*: `/System/Library/AssetsV2/com_apple_MobileAsset_Font*/`
2. *Indexed automatically*: System font index is rebuilt to recognize new fonts
3. *Available system-wide*: All applications can access the fonts immediately

=== Installation Directories

macOS on-demand fonts are installed to official Apple system directories:

[source]
----
/System/Library/AssetsV2/
└── com_apple_MobileAsset_Font8/
    └── [asset-id].asset/
        └── AssetData/
            ├── Font1.ttf
            ├── Font2.ttf
            └── ...
----

Additional font paths scanned by Fontist:
- `/System/Library/PrivateFrameworks/FontServices.framework/Resources/Fonts/Subsets/`
- `/System/Library/PrivateFrameworks/FontServices.framework/Resources/Fonts/ApplicationSupport/`

=== Example Workflow

[source,bash]
----
# 1. List available macOS fonts
$ fontist list "Al Bayan"
Font not found locally.
Available for download: Al Bayan (macOS only)

# 2. Install via manifest
$ cat > macos-fonts.yml << EOF
---
"Al Bayan":
  - Plain
"Baloo Da 2":
  - Regular
EOF

$ fontist manifest install macos-fonts.yml
Downloading from Apple CDN...
Installing fonts to system directory...
Updating system font index...
Successfully installed 2 fonts.

# 3. Verify installation
$ fontist list "Al Bayan"
Al Bayan:
  Plain: /System/Library/AssetsV2/.../Al-Bayan.ttf
----

=== Platform-Specific Manifests

For cross-platform projects, use platform-specific manifests:

[source,yaml]
----
# macos-fonts.yml (macOS only)
---
"Al Bayan":
  - Plain
"InaiMathi":
  - Regular

# linux-fonts.yml (Linux alternative fonts)
---
"Noto Sans Arabic":
  - Regular
"Noto Sans Tamil":
  - Regular
----

[source,bash]
----
# Install based on platform
if [ "$(uname)" = "Darwin" ]; then
  fontist manifest install macos-fonts.yml
else
  fontist manifest install linux-fonts.yml
fi
----

=== Technical Details

==== Font Catalog Versions

[cols="1,1,2"]
|===
|Version |macOS Release |Compatibility

|Font7
|Monterey (12), Ventura (13), Sonoma (14)
|CompatibilityVersion: 2

|Font8
|Sequoia (15)
|CompatibilityVersion: 5
|===

==== Formula Example

[source,yaml]
----
name: Al Bayan
description: Arabic font with elegant calligraphic style
homepage: https://support.apple.com/en-us/HT211240
platforms:
  - macos
resources:
  al_bayan:
    source: apple_cdn
    urls:
      - https://updates.cdn-apple.com/2022/mobileassets/.../com_apple_MobileAsset_Font7/701405507c8753373648c7a6541608e32ed089ec.zip
    sha256:
      - abc123...
    file_size: 1234567
fonts:
  - name: Al Bayan
    styles:
      - family_name: Al Bayan
        type: Plain
        font: Al-Bayan.ttf
        post_script_name: AlBayan
open_license: Apple Font License
----
```

**Documentation Files to Create/Update**:
- `README.adoc` - Add macOS On-Demand Fonts section
- `docs/guide/macos-fonts.md` - Detailed guide
- `CHANGELOG.md` - Document new feature

**Verification**:
```bash
# CLI tests
bundle exec rspec spec/fontist/import_cli_spec.rb

# Integration test
bundle exec rspec spec/integration/macos_ondemand_spec.rb
```

---

## Success Criteria

### Technical Requirements
- [ ] Parse Font7 and Font8 catalogs correctly
- [ ] Download fonts from Apple CDN
- [ ] Install to correct system directories
- [ ] Platform validation works (rejects on non-macOS)
- [ ] System index updates after installation
- [ ] All existing tests pass (backward compatibility)
- [ ] All new tests pass
- [ ] Rubocop clean

### Functional Requirements
- [ ] Manifest installation works for macOS fonts
- [ ] Platform error messages are clear and helpful
- [ ] CLI commands work: `macos`, `macos-catalogs`
- [ ] Formula generation from catalogs successful
- [ ] Installed fonts are immediately available system-wide

### Quality Requirements
- [ ] OOP architecture maintained
- [ ] MECE principles followed
- [ ] Proper separation of concerns
- [ ] Comprehensive test coverage
- [ ] Clear documentation with examples

## Testing Strategy

### Unit Tests
```ruby
# spec/fontist/macos/catalog/asset_spec.rb
RSpec.describe Fontist::Macos::Catalog::Asset do
  let(:asset_data) do
    {
      "__BaseURL" => "https://updates.cdn-apple.com/",
      "__RelativePath" => "fonts/AlBayan.zip",
      "FontInfo4" => [
        {
          "PostScriptFontName" => "AlBayan",
          "FontFamilyName" => "Al Bayan",
          "FontStyleName" => "Plain"
        }
      ]
    }
  end

  subject(:asset) { described_class.new(asset_data) }

  it "extracts download URL" do
    expect(asset.download_url).to eq("https://updates.cdn-apple.com/fonts/AlBayan.zip")
  end

  it "extracts PostScript names" do
    expect(asset.postscript_names).to eq(["AlBayan"])
  end

  it "groups fonts by family" do
    expect(asset.font_families).to eq(["Al Bayan"])
  end
end
```

### Integration Tests
```ruby
# spec/integration/macos_ondemand_spec.rb
RSpec.describe "macOS On-Demand Font Installation", type: :integration do
  let(:manifest_content) do
    <<~YAML
      ---
      "Al Bayan":
        - Plain
    YAML
  end

  let(:manifest_path) { Tempfile.new(["manifest", ".yml"]).path }

  before do
    File.write(manifest_path, manifest_content)
  end

  context "on macOS" do
    it "installs font from Apple CDN" do
      skip "Test requires macOS" unless Fontist::Utils::System.macos?

      manifest = Fontist::Manifest.from_file(manifest_path)
      response = manifest.install

      expect(response.fonts.first.name).to eq("Al Bayan")
      expect(response.fonts.first.styles.first.paths).not_to be_empty
    end
  end

  context "on non-macOS" do
    it "raises platform mismatch error" do
      skip "Test requires non-macOS" if Fontist::Utils::System.macos?

      manifest = Fontist::Manifest.from_file(manifest_path)

      expect { manifest.install }.to raise_error(
        Fontist::Errors::PlatformMismatchError,
        /only available for: macos/
      )
    end
  end
end
```

## Risk Management

### Risk 1: System Directory Permissions
**Issue**: Writing to `/System/Library/` may require elevated permissions
**Mitigation**:
- Check write permissions before installation
- Provide clear error messages with sudo instructions
- Consider alternative installation to user directories if system fails

### Risk 2: Font Catalog Changes
**Issue**: Apple may change catalog format in future macOS versions
**Mitigation**:
- Version-specific parsers (easy to add Font9, Font10, etc.)
- Graceful fallback to BaseParser
- Clear version detection logic

### Risk 3: Platform Detection Accuracy
**Issue**: Edge cases in platform detection (e.g., Hackintosh)
**Mitigation**:
- Use `Fontist::Utils::System.user_os` (already battle-tested)
- Allow manual override via environment variable
- Document platform requirements clearly

### Risk 4: Backward Compatibility
**Issue**: Changes may break existing functionality
**Mitigation**:
- All existing tests must pass
- New features are additive, not destructive
- Font6 support maintained via existing code path

## Next Steps After Completion

1. **Monitor GitHub Actions** for catalog artifacts
2. **Download Font7/Font8 XMLs** to local machine
3. **Analyze schemas** for any missed fields
4. **Generate test formulas** for popular macOS fonts
5. **Test on real macOS** system
6. **Update formulas repository** with macOS fonts
7. **Announce feature** to users

## Compressed Timeline

| Phase | Duration | Deliverables |
|-------|----------|--------------|
| Phase 1 | 1.5 hours | Catalog parsers, Asset models, Tests |
| Phase 2 | 1.5 hours | AppleCDNResource, Platform validation, System install |
| Phase 3 | 1 hour    | Manifest integration, system.yml update, System index |
| Phase 4 | 30 min    | CLI commands, README documentation |
| **Total** | **4.5 hours** | **Complete feature** |

## Commands to Run After Each Phase

```bash
# After Phase 1
bundle exec rspec spec/fontist/macos/catalog/
bundle exec rubocop lib/fontist/macos/

# After Phase 2
bundle exec rspec spec/fontist/resources/apple_cdn_resource_spec.rb
bundle exec rspec spec/fontist/font_installer_spec.rb
bundle exec rubocop lib/fontist/resources/

# After Phase 3
bundle exec rspec spec/fontist/manifest_spec.rb
bundle exec rspec spec/fontist/system_index_spec.rb
bundle exec rubocop lib/fontist/

# After Phase 4
bundle exec rspec
bundle exec rubocop
```