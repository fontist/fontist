# Continuation Prompt: macOS On-Demand Font Installation

## Context

You are implementing macOS on-demand font installation support for Fontist, a Ruby-based font management tool. This feature allows users to specify macOS-exclusive fonts in manifests and have them automatically installed from Apple's CDN with proper platform validation.

## Current State

**Completed**:
- ✅ Architecture designed and documented
- ✅ Implementation plan created (4 phases, ~4.5 hours)
- ✅ Status tracker created
- ✅ GitHub Actions workflow updated to collect Font7/Font8 catalogs

**What exists**:
- [`lib/fontist/import/macos.rb`](lib/fontist/import/macos.rb:1) - Imports Font6 only (legacy)
- [`lib/fontist/manifest.rb`](lib/fontist/manifest.rb:1) - Manifest installation
- [`lib/fontist/font_installer.rb`](lib/fontist/font_installer.rb:1) - Font installation
- [`lib/fontist/formula.rb`](lib/fontist/formula.rb:1) - Formula model with platforms attribute
- [`lib/fontist/system.yml`](lib/fontist/system.yml:1) - System font paths
- 180+ macOS formulas in [`spec/fixtures/formulas/Formulas/macos/`](spec/fixtures/formulas/Formulas/macos/)

**What's needed**:
- Parse Font7/Font8 catalogs (Apple's XML format)
- Download fonts from Apple CDN (https://updates.cdn-apple.com/)
- Install to macOS system directories
- Validate platform compatibility before installation
- Update system index to recognize new fonts
- CLI commands for catalog management

## Documentation References

**READ THESE FIRST**:
1. [`MACOS_ONDEMAND_FONTS_CONTINUATION_PLAN.md`](MACOS_ONDEMAND_FONTS_CONTINUATION_PLAN.md:1) - Complete implementation plan with code examples
2. [`MACOS_ONDEMAND_FONTS_STATUS.md`](MACOS_ONDEMAND_FONTS_STATUS.md:1) - Detailed task checklist and progress
3. [`docs/macos-addon-fonts-architecture-v2.md`](docs/macos-addon-fonts-architecture-v2.md:1) - Architecture overview
4. [`.kilocode/rules/memory-bank/`](.kilocode/rules/memory-bank/) - Project architecture and principles

## Goal

Enable users to:
```yaml
# manifest.yml
---
"Al Bayan":
  - Plain
"Baloo Da 2":
  - Regular
```

```bash
$ fontist manifest install manifest.yml
# On macOS: Downloads from Apple CDN, installs to system directory
# On Linux/Windows: Raises clear error about platform-only licensing
```

## Core Architecture

### 1. Catalog Parsing (Plist-based)
```
lib/fontist/macos/catalog/
├── asset.rb              # Data class: download_url, postscript_names, font_families
├── base_parser.rb        # Plist.parse_xml wrapper
├── font7_parser.rb       # Inherits BaseParser (no filtering needed)
├── font8_parser.rb       # Inherits BaseParser (filters PlatformDelivery)
└── catalog_manager.rb    # Auto-detect catalogs, coordinate parsers
```

**Key Principle**: Use existing `plist` gem (already a dependency), NOT Lutaml::Model

### 2. Resource Handler
```
lib/fontist/resources/
└── apple_cdn_resource.rb  # Download from Apple CDN, extract, yield fonts
```

Routes through `FontInstaller#resource` based on `formula.source == "apple_cdn"`

### 3. Platform Validation
```ruby
# lib/fontist/formula.rb
def compatible_with_platform?(platform = nil)
  target = platform || Utils::System.user_os.to_s
  platforms.nil? || platforms.empty? || platforms.include?(target)
end
```

Raises `PlatformMismatchError` with clear message listing required platforms.

### 4. System Installation
```ruby
# lib/fontist/font_installer.rb
def install_to_system_directory(source)
  # Install to: /System/Library/AssetsV2/com_apple_MobileAsset_Font*/
  #             [asset-id].asset/AssetData/
  target_dir = macos_asset_directory
  FileUtils.cp(source, target_dir.join(File.basename(source)))

  # Update system index immediately
  Fontist::SystemIndex.rebuild
end
```

### 5. System Index Enhancement
```yaml
# lib/fontist/system.yml - Add new paths
macos:
  paths:
    # ... existing paths ...
    - /System/Library/PrivateFrameworks/FontServices.framework/Resources/Fonts/Subsets/**/**.{ttf,ttc,otf}
    - /System/Library/PrivateFrameworks/FontServices.framework/Resources/Fonts/ApplicationSupport/**/**.{ttf,ttc,otf}
```

## Implementation Phases

### Phase 1: Data Structures & Catalog Parsing (1.5 hours) - **START HERE**

**Goal**: Create classes to parse Font7/Font8 XML catalogs

**Files to create**:
1. `lib/fontist/macos/catalog/asset.rb` - Asset data class
2. `lib/fontist/macos/catalog/base_parser.rb` - Base parser using Plist
3. `lib/fontist/macos/catalog/font7_parser.rb` - Font7 specific
4. `lib/fontist/macos/catalog/font8_parser.rb` - Font8 with PlatformDelivery filter
5. `lib/fontist/macos/catalog/catalog_manager.rb` - Coordinator

**Key implementation details** (full code in CONTINUATION_PLAN.md):
```ruby
# asset.rb
class Asset
  attr_reader :base_url, :relative_path, :font_info

  def download_url
    "#{@base_url}#{@relative_path}"
  end

  def postscript_names
    @font_info.map { |info| info["PostScriptFontName"] }.compact
  end
end

# font8_parser.rb - Override to filter
def parse_assets
  super.select { |asset| macos_compatible?(asset) }
end

def macos_compatible?(asset)
  platform_delivery = asset["PlatformDelivery"]
  return true if platform_delivery.nil?

  platform_delivery.any? { |p| p.include?("macOS") && p != "macOS-invisible" }
end
```

**Tests first** (TDD approach):
- Create spec files for each class
- Run specs to confirm behavior
- Fix implementation if needed

**Verification**:
```bash
bundle exec rspec spec/fontist/macos/catalog/
bundle exec rubocop lib/fontist/macos/
```

**Schema Reference** (from provided XMLs):
- Font7: Uses `_CompatibilityVersion: 2`, all fonts macOS-compatible
- Font8: Uses `_CompatibilityVersion: 5`, has `PlatformDelivery` array requiring filtering

### Phase 2: Resource Handler & Installation (1.5 hours)

**Goal**: Download from Apple CDN and install to system directories

**Files to create/modify**:
1. `lib/fontist/resources/apple_cdn_resource.rb` - NEW
2. `lib/fontist/font_installer.rb` - ENHANCE
3. `lib/fontist/formula.rb` - ADD platform methods
4. `lib/fontist/errors.rb` - ADD PlatformMismatchError

**Key additions**:
```ruby
# apple_cdn_resource.rb
def files(source_files)
  download_archive do |archive_path|
    extract_archive(archive_path) do |temp_dir|
      find_fonts(temp_dir, source_files).each { |path| yield path }
    end
  end
end

# font_installer.rb
def install(confirmation:)
  raise_platform_error unless platform_compatible?
  # ... existing code ...
end

def install_font_file(source)
  if @formula.source == "apple_cdn"
    install_to_system_directory(source)
  else
    install_to_fontist_directory(source)
  end
end
```

**Critical**: System installation requires proper directory structure:
```
/System/Library/AssetsV2/
└── com_apple_MobileAsset_Font8/
    └── [sha256-hash].asset/
        └── AssetData/
            └── Font.ttf
```

### Phase 3: Manifest Integration & System Index (1 hour)

**Goal**: Enable manifest-based installation with platform validation

**Files to modify**:
1. `lib/fontist/manifest.rb` - ADD platform validation
2. `lib/fontist/system.yml` - ADD PrivateFrameworks paths
3. `lib/fontist/system_index.rb` - ADD rebuild method

**Key enhancement**:
```ruby
# manifest.rb - ManifestFont class
def install(confirmation: "no", hide_licenses: false, no_progress: false)
  validate_platform_compatibility!  # NEW

  Fontist::Font.install(
    name,
    force: true,
    confirmation: confirmation,
    hide_licenses: hide_licenses,
    no_progress: no_progress,
  )
rescue Fontist::Errors::PlatformMismatchError => e
  Fontist.ui.error(e.message)
  raise
end
```

### Phase 4: CLI & Documentation (30 minutes)

**Goal**: Add CLI commands and document feature

**Files to modify**:
1. `lib/fontist/import_cli.rb` - ENHANCE macos command, ADD macos-catalogs
2. `README.adoc` - ADD macOS On-Demand Fonts section
3. `CHANGELOG.md` - DOCUMENT feature

**New CLI commands**:
```bash
fontist import macos              # Import latest (Font8)
fontist import macos --version 7  # Import Font7
fontist import macos --all-versions  # Import all
fontist macos-catalogs            # List available catalogs
```

## Core Principles (CRITICAL)

### Architecture Principles
- **Pure OOP**: Every concept is a class with single responsibility
- **MECE**: Mutually exclusive, collectively exhaustive
- **Separation of Concerns**: Data, parsing, importing, CLI all separate
- **Open/Closed**: Version-specific parsers extend BaseParser
- **DRY**: Reuse BaseParser, Asset class across versions

### Technical Constraints
- **Use Plist gem** (NOT Lutaml::Model) - It's native macOS format, already a dependency
- **No new dependencies** - Everything needed is already in gemspec
- **100% backward compatibility** - Existing `fontist import macos` must work unchanged
- **All tests must pass** - No regressions allowed

### Quality Standards
- Run `bundle exec rubocop` after each phase - must be clean
- Write tests FIRST for each class (TDD approach)
- Every class needs a corresponding spec file
- Tests must be thorough and follow principles
- **If specs fail, fix the BEHAVIOR not the expectations**

## Implementation Strategy

### Start Order
1. **Phase 1 FIRST** - Catalog parsing provides foundation
2. **Phase 2** - Resource handler builds on Phase 1
3. **Phase 3** - Manifest integration uses Phase 1 & 2
4. **Phase 4** - CLI and docs wrap everything

### Testing Strategy
- **Unit test** each class individually
- **Integration test** the full manifest install flow
- **Manual test** CLI commands on real macOS (if available)
- **Explicitly verify** backward compatibility

### Error Handling
- Graceful handling of missing catalogs
- Clear error messages identifying which component failed
- Don't fail entire operation if one font fails

## Success Criteria

**Technical**:
- [ ] Parse Font7 and Font8 catalogs correctly
- [ ] Download fonts from Apple CDN
- [ ] Install to system directories with proper structure
- [ ] Platform validation works (rejects on non-macOS)
- [ ] System index updates after installation
- [ ] All existing tests pass (617+ specs)
- [ ] All new tests pass
- [ ] Rubocop clean

**Functional**:
- [ ] `fontist manifest install` works for macOS fonts on macOS
- [ ] Platform errors are clear when run on non-macOS
- [ ] `fontist import macos` generates formulas from catalogs
- [ ] `fontist macos-catalogs` lists available catalogs
- [ ] Installed fonts immediately available system-wide

**Quality**:
- [ ] OOP principles maintained
- [ ] MECE architecture
- [ ] Proper tests for all classes
- [ ] Clear error messages
- [ ] Documentation accurate and helpful

**Readiness Criteria**:
- All architecture is complete.
- The plan is detailed with clear code examples.
- The success criteria are defined and understood.

## Common Pitfalls to Avoid

❌ **DON'T**:
- Use Lutaml::Model for catalog parsing (use Plist instead)
- Add new gem dependencies
- Break backward compatibility
- Lower test expectations to make them pass
- Use hardcoded paths
- Repeat code across version parsers

✅ **DO**:
- Use Plist gem for parsing XML catalogs
- Keep Asset as simple data class with attr_readers
- Maintain full backward compatibility
- Fix behavior when tests fail, not expectations
- Use inheritance for version parsers (DRY)
- Test on real macOS system if available

## Data Format Examples

### Font7 Asset (simplified)
```xml
<dict>
  <key>Build</key>
  <string>10M1360</string>
  <key>FontCompatibilityVersions</key>
  <array><integer>2</integer></array>
  <key>FontInfo4</key>
  <array>
    <dict>
      <key>PostScriptFontName</key>
      <string>AlBayan</string>
      <key>FontFamilyName</key>
      <string>Al Bayan</string>
      <key>FontStyleName</key>
      <string>Plain</string>
    </dict>
  </array>
  <key>__BaseURL</key>
  <string>https://updates.cdn-apple.com/2022/mobileassets/...</string>
  <key>__RelativePath</key>
  <string>com_apple_MobileAsset_Font7/701405507c8753373648c7a6541608e32ed089ec.zip</string>
</dict>
```

### Font8 Asset (simplified)
```xml
<dict>
  <key>AssetType</key>
  <string>com.apple.MobileAsset.Font8</string>
  <key>Build</key>
  <string>10M11177</string>
  <key>FontCompatibilityVersions</key>
  <array><integer>5</integer></array>
  <key>FontInfo4</key>
  <array>
    <dict>
      <key>PostScriptFontName</key>
      <string>BalooDa2-Regular</string>
      <key>PlatformDelivery</key>
      <array>
        <string>iOS-download</string>
        <string>macOS-download</string>
      </array>
    </dict>
  </array>
  <key>__BaseURL</key>
  <string>https://updates.cdn-apple.com/2025/mobileassets/...</string>
  <key>__RelativePath</key>
  <string>com_apple_MobileAsset_Font8/7bcec970f2355a0d2fe5f133daf80647dcc682ef.zip</string>
</dict>
```

**Note**: Font8 requires filtering by `PlatformDelivery` - only include assets with "macOS" in platform delivery array.

## Example Formula Output

```yaml
# formulas/macos/al_bayan.yml
name: Al Bayan
description: Arabic font with elegant calligraphic style
homepage: https://support.apple.com/en-us/HT211240
platforms:
  - macos
resources:
  al_bayan:
    source: apple_cdn
    urls:
      - https://updates.cdn-apple.com/2022/mobileassets/.../701405507c8753373648c7a6541608e32ed089ec.zip
    sha256:
      - abc123def456...
    file_size: 1234567
fonts:
  - name: Al Bayan
    styles:
      - family_name: Al Bayan
        type: Plain
        font: Al-Bayan.ttf
        post_script_name: AlBayan
open_license: Apple Font License
```

## Next Actions

1. **Read all documentation**:
   - [`MACOS_ONDEMAND_FONTS_CONTINUATION_PLAN.md`](MACOS_ONDEMAND_FONTS_CONTINUATION_PLAN.md:1)
   - [`MACOS_ONDEMAND_FONTS_STATUS.md`](MACOS_ONDEMAND_FONTS_STATUS.md:1)

2. **Update status tracker**:
   - Mark Phase 1 as "In Progress"
   - Update checklist as you complete tasks

3. **Start Phase 1 implementation**:
   - Create `lib/fontist/macos/catalog/` directory
   - Implement Asset class (with spec first)
   - Implement BaseParser (with spec first)
   - Implement Font7Parser and Font8Parser
   - Implement CatalogManager
   - Run all specs and Rubocop

4. **After Phase 1**:
   - Update status tracker
   - Proceed to Phase 2

## Environment

- **Ruby Version**: 2.7+ (tested up to 3.3)
- **Platform**: Cross-platform (but feature is macOS-only)
- **Repository**: `/Users/mulgogi/src/fontist/fontist`
- **Test Command**: `bundle exec rspec`
- **Lint Command**: `bundle exec rubocop`

## Important Files

### Read Before Starting
- [`lib/fontist/import/macos.rb`](lib/fontist/import/macos.rb:1) - Current Font6 implementation
- [`lib/fontist/manifest.rb`](lib/fontist/manifest.rb:1) - Manifest handling
- [`lib/fontist/font_installer.rb`](lib/fontist/font_installer.rb:1) - Font installation
- [`lib/fontist/formula.rb`](lib/fontist/formula.rb:1) - Formula model
- [`lib/fontist/system.yml`](lib/fontist/system.yml:1) - System paths

### Catalog Files (Provided)
- `com_apple_MobileAsset_Font7.xml` - 48,813 lines
- `com_apple_MobileAsset_Font8.xml` - 2.3MB (truncated in display)

## Questions to Answer During Implementation

1. **Do Font7/Font8 have identical schemas?**
   - Font7: No PlatformDelivery field
   - Font8: Has PlatformDelivery requiring filtering

2. **Where should fonts be installed?**
   - `/System/Library/AssetsV2/com_apple_MobileAsset_Font*/[asset-id].asset/AssetData/`

3. **How to handle permissions?**
   - Detect write permissions, provide clear error if denied
   - Consider fallback to user directory if system fails

## Code Quality Reminders

- **OOP**: Each class has single responsibility
- **MECE**: No overlap, no gaps
- **DRY**: Reuse BaseParser logic
- **Tests**: Write before implementation (TDD)
- **Backward Compat**: Test explicitly
- **Rubocop**: Clean before each commit

---

**Ready to start implementation at Phase 1**. All architecture is complete, plan is detailed, success criteria are clear. Begin by creating the catalog parsing infrastructure, working test-first (TDD), ensuring quality at each step.