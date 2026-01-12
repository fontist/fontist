# Install Location OOP Architecture Plan

## Overview

This document describes the object-oriented architecture for install locations where each location type (fontist, user, system) owns and manages its own font index, preventing duplicate installations and providing clean separation of concerns.

## Core Principles

1. **Index Ownership**: Each location type owns and manages its own index
2. **Guard Pattern**: Locations guard against duplicate installations
3. **Encapsulation**: Font discovery, installation, and removal are encapsulated within location objects
4. **MECE**: Each location is Mutually Exclusive and Collectively Exhaustive

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                     Font.install()                           │
│                           │                                   │
│                           ▼                                   │
│              ┌──────────────────────┐                        │
│              │  InstallLocation     │                        │
│              │  (Factory/Facade)    │                        │
│              └──────────┬───────────┘                        │
│                         │                                     │
│         ┌───────────────┼───────────────┐                   │
│         ▼               ▼               ▼                    │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐        │
│  │   Fontist    │ │     User     │ │    System    │        │
│  │   Location   │ │   Location   │ │   Location   │        │
│  └──────┬───────┘ └──────┬───────┘ └──────┬───────┘        │
│         │                │                │                  │
│         │ owns           │ owns           │ owns            │
│         ▼                ▼                ▼                  │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐        │
│  │   Fontist    │ │     User     │ │    System    │        │
│  │    Index     │ │    Index     │ │    Index     │        │
│  └──────────────┘ └──────────────┘ └──────────────┘        │
└─────────────────────────────────────────────────────────────┘
```

## Class Structure

### 1. Base Location Class

```ruby
# lib/fontist/install_locations/base_location.rb
module Fontist
  module InstallLocations
    class BaseLocation
      attr_reader :formula

      def initialize(formula)
        @formula = formula
      end

      # Abstract methods (must be implemented by subclasses)
      def base_path
        raise NotImplementedError
      end

      def location_type
        raise NotImplementedError
      end

      # Shared interface methods
      def font_path(filename)
        base_path.join(filename)
      end

      def install_font(source_path, target_filename)
        # Check if font already exists at this location
        return nil if font_exists?(target_filename)

        target = font_path(target_filename)
        FileUtils.mkdir_p(target.dirname)
        FileUtils.cp(source_path, target)

        # Update this location's index
        index.add_font(target.to_s)

        target.to_s
      end

      def uninstall_font(filename)
        target = font_path(filename)
        return nil unless File.exist?(target)

        File.delete(target)

        # Update this location's index
        index.remove_font(target.to_s)

        target.to_s
      end

      def font_exists?(filename)
        path = font_path(filename).to_s
        index.font_exists?(path)
      end

      def find_fonts(font_name, style = nil)
        index.find(font_name, style)
      end

      def requires_elevated_permissions?
        false
      end

      def permission_warning
        nil
      end

      protected

      def index
        # Each subclass provides its own index
        raise NotImplementedError
      end
    end
  end
end
```

### 2. Fontist Location

```ruby
# lib/fontist/install_locations/fontist_location.rb
module Fontist
  module InstallLocations
    class FontistLocation < BaseLocation
      def location_type
        :fontist
      end

      def base_path
        Fontist.fonts_path.join(formula.key)
      end

      protected

      def index
        @index ||= FontistIndex.instance
      end
    end
  end
end
```

### 3. User Location

```ruby
# lib/fontist/install_locations/user_location.rb
module Fontist
  module InstallLocations
    class UserLocation < BaseLocation
      def location_type
        :user
      end

      def base_path
        custom_path = Config.user_fonts_path
        return Pathname.new(File.expand_path(custom_path)) if custom_path

        default_user_path.join("fontist")
      end

      protected

      def index
        @index ||= UserIndex.instance
      end

      private

      def default_user_path
        case Utils::System.user_os
        when :macos
          Pathname.new(File.expand_path("~/Library/Fonts"))
        when :linux
          Pathname.new(File.expand_path("~/.local/share/fonts"))
        when :windows
          appdata = ENV["LOCALAPPDATA"] || File.expand_path("~/AppData/Local")
          Pathname.new(appdata).join("Microsoft/Windows/Fonts")
        else
          raise "Unsupported platform: #{Utils::System.user_os}"
        end
      end
    end
  end
end
```

### 4. System Location

```ruby
# lib/fontist/install_locations/system_location.rb
module Fontist
  module InstallLocations
    class SystemLocation < BaseLocation
      def location_type
        :system
      end

      def base_path
        custom_path = Config.system_fonts_path
        return Pathname.new(File.expand_path(custom_path)) if custom_path

        case Utils::System.user_os
        when :macos
          macos_system_path
        when :linux
          Pathname.new("/usr/local/share/fonts").join("fontist")
        when :windows
          windows_dir = ENV["windir"] || ENV["SystemRoot"] || "C:/Windows"
          Pathname.new(windows_dir).join("Fonts/fontist")
        else
          raise "Unsupported platform: #{Utils::System.user_os}"
        end
      end

      def requires_elevated_permissions?
        true
      end

      def permission_warning
        <<~WARNING
          ⚠️  WARNING: Installing to system font directory

          This requires root/administrator permissions and may affect your system.

          Installation will fail if you don't have sufficient permissions.

          Recommended alternatives:
          - Use default (fontist): Safe, isolated, no permissions needed
          - Use --location=user: Install to your user font directory

          Continue with system installation? (Ctrl+C to cancel)
        WARNING
      end

      protected

      def index
        @index ||= SystemIndex.instance
      end

      private

      def macos_system_path
        if formula.macos_import?
          macos_supplementary_path
        else
          Pathname.new("/Library/Fonts").join("fontist")
        end
      end

      def macos_supplementary_path
        # Special handling for macOS supplementary fonts
        framework = framework_version
        unless framework
          raise "Cannot determine framework version for macOS supplementary font"
        end

        base = MacosFrameworkMetadata.system_install_path(framework)
        unless base
          raise "No system path available for framework #{framework}"
        end

        asset_id = formula.import_source.asset_id
        unless asset_id
          raise "Asset ID required for macOS supplementary font installation"
        end

        Pathname.new(base)
          .join("#{asset_id}.asset")
          .join("AssetData")
      end

      def framework_version
        if formula.macos_import?
          formula.import_source.framework_version
        else
          Utils::System.catalog_version_for_macos
        end
      end
    end
  end
end
```

### 5. Location Factory

```ruby
# lib/fontist/install_location.rb (refactored)
module Fontist
  class InstallLocation
    def self.create(formula, location_type: nil)
      type = parse_location_type(location_type)

      case type
      when :fontist
        InstallLocations::FontistLocation.new(formula)
      when :user
        InstallLocations::UserLocation.new(formula)
      when :system
        InstallLocations::SystemLocation.new(formula)
      else
        raise ArgumentError, "Unknown location type: #{type}"
      end
    end

    def self.all_locations(formula)
      [
        InstallLocations::FontistLocation.new(formula),
        InstallLocations::UserLocation.new(formula),
        InstallLocations::SystemLocation.new(formula)
      ]
    end

    private

    def self.parse_location_type(value)
      return Config.fonts_install_location if value.nil?

      case value.to_s.downcase.tr("_", "-")
      when "fontist", "fontist-library"
        :fontist
      when "user"
        :user
      when "system"
        :system
      else
        Fontist.ui.error("Invalid install location: '#{value}'. Using default: fontist")
        :fontist
      end
    end
  end
end
```

### 6. Index Classes

Each index class manages fonts for its specific location:

```ruby
# lib/fontist/indexes/fontist_index.rb
module Fontist
  module Indexes
    class FontistIndex
      include Singleton

      def initialize
        @collection = SystemIndexFontCollection.from_file(
          path: Fontist.fontist_index_path,
          paths_loader: -> { fontist_font_paths }
        )
      end

      def find(font_name, style = nil)
        @collection.find(font_name, style)
      end

      def font_exists?(path)
        @collection.fonts.any? { |f| f.path == path }
      end

      def add_font(path)
        # Add font to index, rebuild if needed
        @collection.reset_verification!
        @collection.index
      end

      def remove_font(path)
        # Remove font from index
        @collection.fonts.delete_if { |f| f.path == path }
        @collection.to_file(Fontist.fontist_index_path)
      end

      def rebuild(verbose: false)
        @collection.rebuild(verbose: verbose)
      end

      private

      def fontist_font_paths
        Dir.glob(Fontist.fonts_path.join("**", "*.{ttf,otf,ttc,otc}"))
      end
    end
  end
end
```

```ruby
# lib/fontist/indexes/user_index.rb
module Fontist
  module Indexes
    class UserIndex
      include Singleton

      def initialize
        @collection = SystemIndexFontCollection.from_file(
          path: Fontist.user_index_path,
          paths_loader: -> { user_font_paths }
        )
      end

      def find(font_name, style = nil)
        @collection.find(font_name, style)
      end

      def font_exists?(path)
        @collection.fonts.any? { |f| f.path == path }
      end

      def add_font(path)
        @collection.reset_verification!
        @collection.index
      end

      def remove_font(path)
        @collection.fonts.delete_if { |f| f.path == path }
        @collection.to_file(Fontist.user_index_path)
      end

      def rebuild(verbose: false)
        @collection.rebuild(verbose: verbose)
      end

      private

      def user_font_paths
        location = InstallLocations::UserLocation.new(nil)
        base = location.base_path
        Dir.glob(base.join("**", "*.{ttf,otf,ttc,otc}"))
      end
    end
  end
end
```

```ruby
# lib/fontist/indexes/system_index.rb
module Fontist
  module Indexes
    class SystemIndex
      include Singleton

      def initialize
        @collection = SystemIndexFontCollection.from_file(
          path: Fontist.system_index_path,
          paths_loader: -> { system_font_paths }
        )
      end

      def find(font_name, style = nil)
        @collection.find(font_name, style)
      end

      def font_exists?(path)
        @collection.fonts.any? { |f| f.path == path }
      end

      def add_font(path)
        @collection.reset_verification!
        @collection.index
      end

      def remove_font(path)
        @collection.fonts.delete_if { |f| f.path == path }
        @collection.to_file(Fontist.system_index_path)
      end

      def rebuild(verbose: false)
        @collection.rebuild(verbose: verbose)
      end

      private

      def system_font_paths
        SystemFont.load_system_font_paths
      end
    end
  end
end
```

### 7. Updated SystemFont

```ruby
# lib/fontist/system_font.rb (updated)
module Fontist
  class SystemFont
    def self.find(font_name)
      styles = find_styles(font_name)
      return unless styles

      styles.map(&:path)
    end

    def self.find_styles(font_name, style = nil)
      # Search across all three indexes
      results = []

      results += Indexes::FontistIndex.instance.find(font_name, style) || []
      results += Indexes::UserIndex.instance.find(font_name, style) || []
      results += Indexes::SystemIndex.instance.find(font_name, style) || []

      results.empty? ? nil : results.uniq { |f| f.path }
    end

    # ... keep existing methods for system_config, load_system_font_paths, etc.
  end
end
```

### 8. Updated FontInstaller

```ruby
# lib/fontist/font_installer.rb (updated)
module Fontist
  class FontInstaller
    attr_reader :location

    def initialize(formula, font_name: nil, no_progress: false, location: nil)
      @formula = formula
      @font_name = font_name
      @no_progress = no_progress
      @location = InstallLocation.create(formula, location_type: location)
    end

    def install(confirmation:)
      raise_platform_error unless platform_compatible?
      raise_fontist_version_error unless supported_version?
      raise_licensing_error unless license_is_accepted?(confirmation)

      install_font
    end

    private

    def install_font
      fonts_paths = do_install_font
      fonts_paths.empty? ? nil : fonts_paths
    end

    def do_install_font
      Fontist.ui.say(%(Installing from formula "#{@formula.key}".))

      Array.new.tap do |fonts_paths|
        resource.files(source_files) do |path|
          if font_file?(path)
            target_filename = target_filename(File.basename(path)) || File.basename(path)

            # Use location object to handle installation
            installed_path = @location.install_font(path, target_filename)

            if installed_path
              fonts_paths << installed_path
              Fontist.ui.say("Installed: #{installed_path}") if @location.location_type != :fontist
            else
              Fontist.ui.say("Skipped (already exists): #{target_filename}")
            end
          end
        end
      end
    end

    # ... rest of the implementation
  end
end
```

## Index File Structure

Maintain current naming convention with addition of user index:

```
~/.fontist/
├── fontist_index.default_family.yml      # Fontist-managed fonts
├── fontist_index.preferred_family.yml
├── user_index.default_family.yml         # NEW: User location fonts
├── user_index.preferred_family.yml       # NEW: User location fonts
├── system_index.default_family.yml       # System location fonts (platform fonts)
├── system_index.preferred_family.yml
└── fonts/
    └── {formula-key}/
        └── *.ttf
```

## Installation Behavior

### Location Types: Managed vs Non-Managed

**Fontist-Managed Locations** (safe to replace fonts):
- Fontist library: `~/.fontist/fonts/{formula-key}/`
- User default: `~/Library/Fonts/fontist/` (subdirectory)
- System default: `/Library/Fonts/fontist/` (subdirectory)

**Non-Managed Locations** (never replace existing fonts):
- Custom user root: `~/Library/Fonts/` (when `FONTIST_USER_FONTS_PATH=~/Library/Fonts`)
- Custom system root: `/Library/Fonts/` (when `FONTIST_SYSTEM_FONTS_PATH=/Library/Fonts`)
- Any location containing system-installed or user-installed fonts not managed by Fontist

### Installation Decision Matrix

#### Without `--force`

| Font Location | Target Location | Action | Message |
|---------------|-----------------|--------|---------|
| Nowhere | Any | ✅ Install | "Installing font to {location}" |
| Target (managed) | Same | ⏭️ Skip | "Font already installed in {location}" |
| Target (non-managed) | Same | ⏭️ Skip | "Font already exists at {path}" |
| Other managed | Different managed | ⏭️ Skip | "Font exists in {other_location}, use --force to duplicate" |
| Other non-managed | Different | ⏭️ Skip | "Font exists at {path}, use --force to install anyway" |

#### With `--force`

| Existing Font Location | Target Location | Target is Managed? | Action | Warning |
|------------------------|-----------------|-------------------|--------|---------|
| Target (managed) | Same managed | Yes | 🔄 Replace | None (safe) |
| Target (non-managed) | Same non-managed | No | ➕ Add with unique name | ⚠️ Duplicate created |
| Other managed | Different managed | Yes | ✅ Install duplicate | None (intentional) |
| Other non-managed | Managed | Yes | ✅ Install duplicate | "Font also exists at {other_path}" |
| Other (any) | Non-managed | No | ➕ Add with unique name | ⚠️ Duplicate created at both locations |

### Detailed Scenarios

#### Scenario 1: Font in system root, installing to default user location (managed)

```bash
# Existing: /Library/Fonts/Roboto-Regular.ttf (system root, non-managed)
# Target: ~/Library/Fonts/fontist/Roboto-Regular.ttf (user managed)

fontist install "Roboto" --location=user --force
# → Installs to ~/Library/Fonts/fontist/Roboto-Regular.ttf
# → Message: "Installed font to user location
#            Note: Font also exists at /Library/Fonts/Roboto-Regular.ttf"
```

**Rationale**: Different locations (root vs subdirectory), safe to have both.

#### Scenario 2: Font in system root, installing to custom system root (non-managed)

```bash
# Existing: /Library/Fonts/Roboto-Regular.ttf (system root)
# Custom config: FONTIST_SYSTEM_FONTS_PATH=/Library/Fonts
# Target: /Library/Fonts/Roboto-Regular.ttf (same location, non-managed)

fontist install "Roboto" --location=system --force
# → Installs to /Library/Fonts/Roboto-Regular-fontist.ttf (non-duplicating name)
# → Warning: "⚠️  DUPLICATE FONT INSTALLED
#             Font 'Roboto Regular' already exists at:
#               /Library/Fonts/Roboto-Regular.ttf (existing system font)
#
#             Fontist installed a duplicate with unique name at:
#               /Library/Fonts/Roboto-Regular-fontist.ttf (new install)
#
#             You can manually delete the old font file if you want to use
#             only the Fontist-managed version."
```

**Rationale**: Never overwrite fonts in non-managed locations to avoid breaking system.

#### Scenario 3: Font in user managed subdirectory, reinstalling to same location

```bash
# Existing: ~/Library/Fonts/fontist/Roboto-Regular.ttf (user managed)
# Target: ~/Library/Fonts/fontist/Roboto-Regular.ttf (same managed location)

fontist install "Roboto" --location=user --force
# → Replaces ~/Library/Fonts/fontist/Roboto-Regular.ttf
# → Message: "Reinstalled font to user location"
```

**Rationale**: Fontist manages this location, safe to replace (e.g., updating to newer version).

#### Scenario 4: Font in fontist library, installing to user location

```bash
# Existing: ~/.fontist/fonts/roboto/Roboto-Regular.ttf (fontist library)
# Target: ~/Library/Fonts/fontist/Roboto-Regular.ttf (user managed)

fontist install "Roboto" --location=user --force
# → Installs to ~/Library/Fonts/fontist/Roboto-Regular.ttf
# → Message: "Installed font to user location
#            Note: Font also exists in fontist library"
```

**Rationale**: User explicitly wants duplicate in different location (both managed).

#### Scenario 5: Font in user root, installing to custom user root

```bash
# Existing: ~/Library/Fonts/Roboto-Regular.ttf (user root, non-managed)
# Custom config: FONTIST_USER_FONTS_PATH=~/Library/Fonts
# Target: ~/Library/Fonts/Roboto-Regular.ttf (same non-managed location)

fontist install "Roboto" --location=user --force
# → Installs to ~/Library/Fonts/Roboto-Regular-fontist.ttf
# → Warning: "⚠️  DUPLICATE FONT INSTALLED
#             Font 'Roboto Regular' already exists at:
#               ~/Library/Fonts/Roboto-Regular.ttf (existing user font)
#
#             Fontist installed a duplicate with unique name at:
#               ~/Library/Fonts/Roboto-Regular-fontist.ttf (new install)
#
#             You can manually delete the old font file if needed."
```

**Rationale**: Respect existing user fonts, add with unique name to avoid conflicts.

### Non-Duplicating Filename Strategy

When installing to a non-managed location where a font with the same name exists:

1. **Check for existing file**: `Roboto-Regular.ttf` exists
2. **Generate unique name**: Try these in order:
   - `Roboto-Regular-fontist.ttf` (preferred suffix)
   - `Roboto-Regular-fontist-2.ttf` (if first already exists)
   - `Roboto-Regular-fontist-3.ttf` (and so on)
3. **Install with unique name**
4. **Show warning** with both paths

### Implementation Logic

```ruby
class BaseLocation
  def install_font(source_path, target_filename)
    target = font_path(target_filename)

    # Check if font exists
    if font_exists?(target_filename)
      if managed_location?
        # Safe to replace in managed locations
        replace_font(source_path, target)
      else
        # Non-managed: use unique name
        unique_target = generate_unique_filename(target_filename)
        install_with_warning(source_path, unique_target, original_path: target)
      end
    else
      # New installation
      simple_install(source_path, target)
    end
  end

  def managed_location?
    # Override in subclasses based on configuration
    true  # Default locations are managed
  end

  def generate_unique_filename(filename)
    base = File.basename(filename, File.extname(filename))
    ext = File.extname(filename)

    # Try -fontist suffix first
    candidate = "#{base}-fontist#{ext}"
    return candidate unless File.exist?(font_path(candidate))

    # Try numbered suffixes
    counter = 2
    loop do
      candidate = "#{base}-fontist-#{counter}#{ext}"
      return candidate unless File.exist?(font_path(candidate))
      counter += 1
    end
  end

  def install_with_warning(source, target, original_path:)
    FileUtils.cp(source, target)

    Fontist.ui.warn(<<~WARNING)
      ⚠️  DUPLICATE FONT INSTALLED

      Font already exists at:
        #{original_path} (existing font)

      Fontist installed a duplicate with unique name at:
        #{target} (new install)

      You can manually delete the old font file if you want to use
      only the Fontist-managed version.
    WARNING

    index.add_font(target.to_s)
    target.to_s
  end
end

class UserLocation < BaseLocation
  def managed_location?
    # If user customized path to root directory, it's non-managed
    !Config.user_fonts_path || uses_fontist_subdirectory?
  end

  def uses_fontist_subdirectory?
    base_path.to_s.end_with?('/fontist')
  end
end

class SystemLocation < BaseLocation
  def managed_location?
    # Special case: macOS supplementary fonts are always managed by OS
    return true if formula.macos_import?

    # If user customized path to root directory, it's non-managed
    !Config.system_fonts_path || uses_fontist_subdirectory?
  end

  def uses_fontist_subdirectory?
    base_path.to_s.end_with?('/fontist')
  end
end

class FontistLocation < BaseLocation
  def managed_location?
    # Fontist library is always managed
    true
  end
end
```

### Summary of Key Rules

1. **Managed locations** (default fontist subdirectories):
   - ✅ Safe to replace with `--force`
   - ⏭️ Skip without `--force`

2. **Non-managed locations** (custom root directories):
   - ➕ Add with unique name when forced
   - ⚠️ Always show warning about duplicate
   - ❌ Never overwrite existing fonts

3. **Cross-location duplicates**:
   - ⏭️ Skip without `--force`
   - ✅ Install if forced and different managed locations
   - ➕ Add with unique name if forced to non-managed location

4. **User safety**:
   - Never break existing system/user fonts
   - Always inform user about duplicates
   - Provide clear paths for manual cleanup

### Testing Scenarios

Test matrix must cover:

1. ✅ Install to empty managed location
2. ✅ Install to empty non-managed location
3. ✅ Replace in managed location with `--force`
4. ✅ Add unique name in non-managed location with `--force`
5. ✅ Skip when exists in target without `--force`
6. ✅ Skip when exists in other location without `--force`
7. ✅ Install duplicate across managed locations with `--force`
8. ✅ Generate correct unique filename sequence
9. ✅ Show appropriate warnings for duplicates
10. ✅ Update indexes correctly in all cases

## Installation Flow

```
Font.install("Roboto", location: :user)
    │
    ▼
InstallLocation.create(formula, :user)
    │
    ▼
UserLocation instance created
    │
    ▼
FontInstaller.install()
    │
    ▼
For each font file:
    │
    ├──> UserLocation.font_exists?(filename)
    │       │
    │       ├──> UserIndex.find(path)
    │       │
    │       ▼
    │    If exists: Skip (return nil)
    │    If not exists:
    │       │
    │       ▼
    ├──> UserLocation.install_font(source, target)
    │       │
    │       ├──> Copy file to user location
    │       ├──> UserIndex.add_font(path)
    │       │       │
    │       │       └──> Rebuild user index
    │       │
    │       └──> Return installed path
    │
    └──> Collect all installed paths
```

## Uninstallation Flow

```
Font.uninstall("Roboto")
    │
    ▼
Search for font across all indexes
    │
    ├──> FontistIndex.find("Roboto")
    ├──> UserIndex.find("Roboto")
    └──> SystemIndex.find("Roboto")
    │
    ▼
For each found font:
    │
    ├──> Determine location from path
    │       │
    │       └──> Get appropriate Location instance
    │
    ├──> Location.uninstall_font(filename)
    │       │
    │       ├──> Delete physical file
    │       ├──> Index.remove_font(path)
    │       │       │
    │       │       └──> Update index file
    │       │
    │       └──> Return deleted path
    │
    └──> Collect all deleted paths
```

## Configuration Methods

Add to `Fontist` module:

```ruby
# lib/fontist.rb
module Fontist
  def self.user_index_path
    root_path.join("user_index.#{index_formula_type}.yml")
  end

  # Existing system_index_path now points to platform fonts only
  # Existing fontist_index_path points to fontist-managed fonts
end
```

## Testing Strategy

### 1. Unit Tests for Location Classes

```ruby
# spec/fontist/install_locations/fontist_location_spec.rb
RSpec.describe Fontist::InstallLocations::FontistLocation do
  let(:formula) { instance_double(Fontist::Formula, key: "roboto") }
  let(:location) { described_class.new(formula) }

  describe "#location_type" do
    it "returns :fontist" do
      expect(location.location_type).to eq(:fontist)
    end
  end

  describe "#base_path" do
    it "returns formula-keyed path" do
      expect(location.base_path.to_s).to include("roboto")
    end
  end

  describe "#install_font" do
    # Test installation logic
  end

  describe "#font_exists?" do
    # Test duplicate detection
  end
end
```

### 2. Integration Tests

```ruby
# spec/fontist/install_location_integration_spec.rb
RSpec.describe "Install Location Integration" do
  context "when installing to user location" do
    it "creates index entry" do
      # Test index is updated
    end

    it "skips if font already exists" do
      # Test duplicate prevention
    end
  end

  context "when installing to system location" do
    it "requires elevated permissions" do
      # Test permission checks
    end
  end
end
```

### 3. Index Tests

```ruby
# spec/fontist/indexes/user_index_spec.rb
RSpec.describe Fontist::Indexes::UserIndex do
  describe "#font_exists?" do
    # Test font existence checking
  end

  describe "#add_font" do
    # Test adding fonts to index
  end

  describe "#remove_font" do
    # Test removing fonts from index
  end
end
```

## Migration Strategy

### Phase 1: Create New Classes (Non-Breaking)
1. Create `InstallLocations::BaseLocation` and subclasses
2. Create `Indexes::FontistIndex`, `UserIndex`, `SystemIndex`
3. Add `user_index_path` configuration
4. All new classes coexist with old code

### Phase 2: Update Installation Flow
1. Update `FontInstaller` to use location objects
2. Keep backward compatibility with existing index methods
3. Test thoroughly with existing formulas

### Phase 3: Update Search Flow
1. Update `SystemFont.find_styles` to search all three indexes
2. Ensure backward compatibility

### Phase 4: Deprecate Old Code (Future)
1. Mark old `SystemIndex` static methods as deprecated
2. Provide migration guide
3. Remove in next major version

## Benefits

1. **Clear Ownership**: Each location owns its index
2. **Duplicate Prevention**: Checking target location before installation
3. **MECE**: Clear separation between fontist, user, and system fonts
4. **Testability**: Easy to test each location in isolation
5. **Extensibility**: Easy to add new location types
6. **Encapsulation**: Index management hidden within location objects
7. **Thread Safety**: Singleton indexes prevent concurrency issues

## Open Questions

1. Should uninstallation search all locations or only a specific one?
   - **Recommendation**: Search all, delete from all found locations

2. Should `Font.find()` prefer fonts from specific locations?
   - **Recommendation**: No preference, return all found fonts

3. How to handle index rebuild for all locations?
   - **Recommendation**: Add `Fontist::Index.rebuild_all` helper

## Summary

This architecture provides:
- ✅ OOP structure with clear responsibilities
- ✅ Index ownership by location type
- ✅ Duplicate prevention through guard pattern
- ✅ Backward compatible migration path
- ✅ Comprehensive test coverage plan
- ✅ MECE separation of concerns