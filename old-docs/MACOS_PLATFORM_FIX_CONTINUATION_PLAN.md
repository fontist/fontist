// ... existing code ...
# macOS Platform Fix and Install Location - Continuation Plan

## Overview

This plan implements critical fixes for macOS font framework platform versioning and adds install location flexibility.

**Key Deliverables:**
1. Fix MacosFrameworkMetadata version ranges (Apple's table)
2. Platform tag override support (ENV: `FONTIST_PLATFORM_OVERRIDE="macos-font7"`)
3. Unsupported platform error handling with helpful guidance
4. Install location options: system vs fontist library (ENV/CLI: `--macos-fonts-location`)
5. Formula-keyed installation paths to prevent conflicts

**Timeline:** 12-16 hours (compressed to 8-10 hours with parallel work)

## Architecture Principles

- **Object-Oriented**: Use classes for InstallLocation, not procedural helpers
- **MECE**: Clear separation: Config, InstallLocation, FontInstaller, Error handling
- **Single Responsibility**: Each class has one job
- **Open/Closed**: Extensible for future frameworks (Font9, Font10)
- **API First**: CLI is thin layer over API (all options also in ENV)

## Phase 1: Core Fixes (Priority: CRITICAL, Time: 2-3h)

### 1.1 Fix MacosFrameworkMetadata

**File**: `lib/fontist/macos_framework_metadata.rb`

**Changes:**
```ruby
METADATA = {
  3 => {
    "min_macos_version" => "10.12",  # WAS: "10.10" - WRONG
    "max_macos_version" => "10.12",
    "asset_path" => "/System/Library/Assets",
    # ... rest unchanged
  },
  4 => {
    "min_macos_version" => "10.13",  # WAS: "10.12" - OVERLAPPED
    "max_macos_version" => "10.13",
    "asset_path" => "/System/Library/Assets",
    # ... rest unchanged
  },
  5 => {
    "min_macos_version" => "10.14",  # WAS: "10.13" - WRONG
    "max_macos_version" => "10.15",
    "asset_path" => "/System/Library/AssetsV2",
    # ... rest unchanged
  },
  6 => {
    "min_macos_version" => "10.15",  # WAS: "11.0" - MISSING CATALINA
    "max_macos_version" => "11.99",  # WAS: "11.7" - TOO RESTRICTIVE
    "asset_path" => "/System/Library/AssetsV2",
    # ... rest unchanged
  },
  7 => {
    "min_macos_version" => "12.0",   # WAS: "10.11" - COMPLETELY WRONG
    "max_macos_version" => "15.99",  # WAS: "15.7" - Apple jumped to 26 after 15
    "asset_path" => "/System/Library/AssetsV2",
    # ... rest unchanged
  },
  8 => {
    # CORRECT - no changes needed
  }
}.freeze

# ADD: System path methods
def self.asset_path(framework_version)
  metadata.dig(framework_version, "asset_path")
end

def self.system_install_path(framework_version)
  base = asset_path(framework_version)
  return nil unless base
  "#{base}/com_apple_MobileAsset_Font#{framework_version}"
end
```

### 1.2 Fix Utils::System.catalog_version_for_macos

**File**: `lib/fontist/utils/system.rb`

**Replace method** (lines 88-103):
```ruby
def self.catalog_version_for_macos
  version = macos_version
  return nil unless version

  # Use MacosFrameworkMetadata as single source of truth
  require_relative "../macos_framework_metadata"
  MacosFrameworkMetadata.framework_for_macos(version)
end
```

**Rationale:** Current implementation hardcodes Font7/Font8, ignores Font3-6. This delegates to metadata for MECE structure.

## Phase 2: Error Handling (Priority: HIGH, Time: 1-2h)

### 2.1 Add UnsupportedMacOSVersionError

**File**: `lib/fontist/errors.rb`

**Add after line 100+:**
```ruby
class UnsupportedMacOSVersionError < GeneralError
  def initialize(detected_version, available_frameworks)
    super(build_message(detected_version, available_frameworks))
  end

  private

  def build_message(version, frameworks)
    <<~MSG
      Unsupported macOS version: #{version}

      Your macOS version is not supported by any font framework.

      Supported frameworks:
      #{format_frameworks(frameworks)}

      Options:

      1. Override platform (if you know your framework):
         export FONTIST_PLATFORM_OVERRIDE="macos-font<N>"
         Example: export FONTIST_PLATFORM_OVERRIDE="macos-font7"

      2. Install to Fontist library (works with any override):
         fontist install "Font Name" --macos-fonts-location=fontist-library

      Note: Non-macOS-platform-tagged fonts work normally.

      Report issues: https://github.com/fontist/fontist/issues
    MSG
  end

  def format_frameworks(frameworks)
    frameworks.map do |num, meta|
      min = meta["min_macos_version"]
      max = meta["max_macos_version"] || "+"
      "  Font#{num}: #{min}-#{max} (#{meta['description']})"
    end.join("\n")
  end
end
```

### 2.2 Update Formula Compatibility Check

**File**: `lib/fontist/formula.rb`

**Modify** `compatible_with_platform?` method (around line 261):
```ruby
def compatible_with_platform?(platform = nil)
  # ... existing OS detection ...

  # For macOS platform-tagged formulas
  if target == "macos" && macos_import?
    current_macos = Utils::System.macos_version
    return true unless current_macos

    # Check framework support
    framework = Utils::System.catalog_version_for_macos
    if framework.nil?
      raise Errors::UnsupportedMacOSVersionError.new(
        current_macos,
        MacosFrameworkMetadata.metadata
      )
    end

    return import_source.compatible_with_macos?(current_macos)
  end

  true
end
```

## Phase 3: Platform Override (Priority: HIGH, Time: 2h)

### 3.1 Add Platform Override Support

**File**: `lib/fontist/utils/system.rb`

**Add methods** (before `user_os` method):
```ruby
# Platform override from environment (ONLY platform tags supported)
def self.platform_override
  ENV["FONTIST_PLATFORM_OVERRIDE"]
end

def self.platform_override?
  !platform_override.nil?
end

# Parse platform override (ONLY platform tag format)
# Returns: { os: Symbol, framework: Integer } or { os: Symbol } or nil
def self.parse_platform_override
  override = platform_override
  return nil unless override

  # "macos-font7" => { os: :macos, framework: 7 }
  if match = override.match(/^(macos|linux|windows)-font(\d+)$/)
    return { os: match[1].to_sym, framework: match[2].to_i }
  end

  # "linux" or "windows" => { os: Symbol }
  if override.match?(/^(macos|linux|windows)$/)
    return { os: override.to_sym, framework: nil }
  end

  # Invalid format
  Fontist.ui.warn(
    "Invalid FONTIST_PLATFORM_OVERRIDE: #{override}\n" \
    "Supported: 'macos-font<N>', 'linux', 'windows'"
  )
  nil
end
```

### 3.2 Update user_os with Override

**Modify** `user_os` method:
```ruby
def self.user_os
  if platform_override?
    parsed = parse_platform_override
    return parsed[:os] if parsed
  end

  # Existing detection...
  @user_os ||= begin
    # ... unchanged ...
  end
end
```

### 3.3 Update macos_version with Override

**Modify** `macos_version` method:
```ruby
def self.macos_version
  if platform_override?
    parsed = parse_platform_override
    if parsed && parsed[:framework]
      require_relative "../macos_framework_metadata"
      return MacosFrameworkMetadata.min_macos_version(parsed[:framework])
    end
  end

  return nil unless user_os == :macos

  # Existing detection...
  @macos_version ||= begin
    # ... unchanged ...
  end
end
```

### 3.4 Update catalog_version_for_macos with Override

**Modify** method:
```ruby
def self.catalog_version_for_macos
  if platform_override?
    parsed = parse_platform_override
    return parsed[:framework] if parsed && parsed[:framework]
  end

  version = macos_version
  return nil unless version

  require_relative "../macos_framework_metadata"
  MacosFrameworkMetadata.framework_for_macos(version)
end
```

## Phase 4: Install Location (Priority: HIGH, Time: 3-4h)

### 4.1 Create InstallLocation Class

**New file**: `lib/fontist/install_location.rb`

```ruby
module Fontist
  # Manages installation location for fonts
  # - System: /System/Library/Assets.../com_apple_MobileAsset_Font<N>/
  # - Fontist Library: ~/.fontist/fonts/<formula-key>/
  class InstallLocation
    attr_reader :formula, :location_type

    def initialize(formula, location_type: nil)
      @formula = formula
      @location_type = location_type || Config.macos_fonts_location
    end

    # Returns base installation directory
    def base_path
      case location_type
      when :system
        system_path
      when :fontist_library
        fontist_library_path
      else
        raise ArgumentError, "Unknown location: #{location_type}"
      end
    end

    # Returns full path for font file
    def font_path(filename)
      base_path.join(filename)
    end

    def system_install?
      location_type == :system
    end

    def fontist_library_install?
      location_type == :fontist_library
    end

    private

    def system_path
      return nil unless formula.macos_import?

      framework = formula.import_source.framework_version
      return nil unless framework

      base = MacosFrameworkMetadata.system_install_path(framework)
      raise "No system path for framework #{framework}" unless base

      Pathname.new(base)
    end

    def fontist_library_path
      # Formula-keyed: macos/font7/sf_pro => ~/.fontist/fonts/macos/font7/sf_pro/
      Fontist.fonts_path.join(formula.key)
    end
  end
end
```

### 4.2 Update Config

**File**: `lib/fontist/config.rb`

**Add methods**:
```ruby
# Gets macOS fonts installation location
# Priority: ENV > config file > default ("system")
def self.macos_fonts_location
  value = ENV["FONTIST_MACOS_FONTS_LOCATION"] ||
          user_config.dig("macos_fonts_location") ||
          "system"

  case value.downcase
  when "system"
    :system
  when "fontist-library", "fontist_library"
    :fontist_library
  else
    Fontist.ui.warn("Invalid FONTIST_MACOS_FONTS_LOCATION: #{value}")
    :system
  end
end

# Sets macOS fonts installation location in config file
def self.set_macos_fonts_location(location)
  config = user_config
  config["macos_fonts_location"] = location.to_s.tr("_", "-")
  save_user_config(config)
end
```

### 4.3 Update FontInstaller

**File**: `lib/fontist/font_installer.rb`

**Modify initialize**:
```ruby
def initialize(formula, font_name: nil, no_progress: false, location: nil)
  @formula = formula
  @font_name = font_name
  @no_progress = no_progress
  @location = InstallLocation.new(formula, location_type: location)
end
```

**Update install_fonts method** (find where fonts are copied):
```ruby
def install_fonts(source_dir, fonts, confirmation)
  fonts.map do |font_file|
    basename = File.basename(font_file)
    target = @location.font_path(basename)

    # Ensure directory exists
    FileUtils.mkdir_p(target.dirname)

    # Copy font
    FileUtils.cp(font_file, target)

    target.to_s
  end
end
```

### 4.4 Update Font Class

**File**: `lib/fontist/font.rb`

**Add to initialize**:
```ruby
def initialize(options = {})
  # ... existing ...
  @macos_fonts_location = parse_location(options[:macos_fonts_location])
end
```

**Add helper**:
```ruby
private

def parse_location(value)
  return nil unless value

  case value.to_s.downcase
  when "system"
    :system
  when "fontist-library", "fontist_library"
    :fontist_library
  else
    Fontist.ui.warn("Invalid location: #{value}")
    nil
  end
end
```

**Update font_installer**:
```ruby
def font_installer(formula)
  options = {
    no_progress: @no_progress,
    location: @macos_fonts_location
  }

  if @by_formula
    FontInstaller.new(formula, **options)
  else
    FontInstaller.new(formula, font_name: @name, **options)
  end
end
```

### 4.5 Update CLI

**File**: `lib/fontist/cli.rb`

**Add option to install command**:
```ruby
option :macos_fonts_location,
       type: :string,
       enum: ["system", "fontist-library"],
       desc: "macOS fonts install location"
```

**Pass to Font.install**:
```ruby
Font.install(
  font,
  # ... existing options ...
  macos_fonts_location: options[:macos_fonts_location]
)
```

## Phase 5: Testing (Priority: HIGH, Time: 3-4h)

### 5.1 Version Mapping Tests

**File**: `spec/fontist/macos_framework_metadata_spec.rb`

Test all version mappings, including nil for 16-25.

### 5.2 Platform Override Tests

**File**: `spec/fontist/utils/system_platform_override_spec.rb`

Test override parsing, version derivation, framework detection.

### 5.3 Install Location Tests

**File**: `spec/fontist/install_location_spec.rb`

Test system vs fontist-library paths, formula-keyed structure.

### 5.4 Error Tests

**File**: `spec/fontist/errors_spec.rb`

Test UnsupportedMacOSVersionError message includes all required elements.

## Phase 6: Documentation (Priority: MEDIUM, Time: 1-2h)

### 6.1 Update README.adoc

Add sections:
- macOS Supplementary Fonts
- Supported macOS Versions (table)
- Installation Locations
- Platform Override
- Unsupported Versions

### 6.2 Create docs/macos-fonts-guide.md

Comprehensive guide covering all features.

### 6.3 Move Old Docs

Move to `old-docs/`:
- `docs/macos-addon-fonts-implementation-summary.md`
- `docs/macos-font-platform-versioning-architecture.md`

## Compressed Timeline

| Phase | Parallel? | Time |
|-------|-----------|------|
| 1. Core Fixes | No | 2-3h |
| 2. Error Handling | No (depends on 1) | 1-2h |
| 3+4. Override + Location | Yes (parallel) | 3-4h |
| 5. Testing | No (depends on 2,3,4) | 3-4h |
| 6. Documentation | Yes (parallel with 5) | 1-2h |
| **Total** | | **8-10h** |

## Implementation Order

1. **Core fixes first** (Phase 1) - Critical foundation
2. **Error handling** (Phase 2) - Enables safe testing
3. **Override + Location in parallel** (Phase 3+4)
4. **Testing + Docs in parallel** (Phase 5+6)

## Success Criteria

- [ ] All framework versions correctly mapped
- [ ] Unsupported versions show helpful error
- [ ] Platform override works (tag format only)
- [ ] System install to correct framework paths
- [ ] Fontist library install to formula-keyed paths
- [ ] Non-platform-tagged formulas unaffected
- [ ] All tests pass (617+ examples)
- [ ] Documentation complete and accurate

## Risk Mitigation

- **Breaking changes**: Default behavior unchanged (system install)
- **Test regression**: Update expectations, don't lower standards
- **Formula conflicts**: Formula-keyed paths prevent collisions
- **Cross-framework**: Only works with fontist-library location
// ... existing code ...