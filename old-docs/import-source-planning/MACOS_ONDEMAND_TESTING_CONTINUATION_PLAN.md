# macOS On-Demand Fonts Testing & Refinement Plan

## Executive Summary

The macOS on-demand fonts implementation is code-complete. This plan outlines local testing, refinement, and documentation finalization before production deployment.

**Status**: Ready for local testing and refinement
**Estimated Duration**: 2-3 hours
**Prerequisites**: macOS system with Font7/Font8 catalogs

---

## Phase 1: Local Testing Setup (30 minutes)

### 1.1 Environment Verification
```bash
# Verify Ruby environment
ruby -v  # Should be >= 2.7

# Install dependencies
bundle install

# Verify catalog availability
ls -la /System/Library/AssetsV2/com_apple_MobileAsset_Font*/

# Check catalog file sizes
find /System/Library/AssetsV2/ -name "*.xml" -exec ls -lh {} \;
```

### 1.2 List Available Catalogs
```bash
# Test new CLI command
bin/fontist import macos-catalogs

# Expected output:
# Available macOS Font Catalogs:
#   Font7: /System/Library/AssetsV2/...xml (47.7 MB)
#   Font8: /System/Library/AssetsV2/...xml (2.3 MB)
```

### 1.3 Verify Catalog Parsing
Create test script: `test/manual/test_catalog_parsing.rb`
```ruby
require_relative "../../lib/fontist"
require_relative "../../lib/fontist/macos/catalog/catalog_manager"

# Test catalog detection
catalogs = Fontist::Macos::Catalog::CatalogManager.available_catalogs
puts "Found #{catalogs.size} catalogs"

# Test parsing
catalogs.each do |path|
  parser = Fontist::Macos::Catalog::CatalogManager.parser_for(path)
  assets = parser.assets
  puts "#{File.basename(path)}: #{assets.size} assets"

  # Show first asset
  first = assets.first
  puts "  Sample: #{first.font_families.first}"
  puts "  URL: #{first.download_url}"
end
```

---

## Phase 2: Core Functionality Testing (1 hour)

### 2.1 Platform Validation Testing

**Test 1: Formula platform check**
```ruby
# test/manual/test_platform_validation.rb
require_relative "../../lib/fontist"

# Assume we have a macos-only formula
formula = Fontist::Formula.find_by_key("macos/al_bayan")

puts "Formula platforms: #{formula.platforms.inspect}"
puts "Current OS: #{Fontist::Utils::System.user_os}"
puts "Compatible? #{formula.compatible_with_platform?}"
puts "Message: #{formula.platform_restriction_message}"
```

**Test 2: PlatformMismatchError**
```ruby
# Create mock formula with macos platform
# Try to install on non-macOS (use VM or skip test on macOS)
begin
  # This should raise error on non-macOS
  Fontist::Font.install("Al Bayan")
rescue Fontist::Errors::PlatformMismatchError => e
  puts "✓ Platform error caught correctly"
  puts "  Message: #{e.message}"
end
```

### 2.2 Import Formula Generation

**Test 3: Import from Font7**
```bash
# Backup existing formulas
cp -r ~/.fontist/versions/v4/formulas/macos ~/.fontist/versions/v4/formulas/macos.backup

# Import Font7 (if available)
bin/fontist import macos --version 7

# Check generated formulas
ls -la ~/.fontist/versions/v4/formulas/macos/
head -n 20 ~/.fontist/versions/v4/formulas/macos/al_bayan.yml
```

**Test 4: Import from Font8**
```bash
bin/fontist import macos --version 8

# Verify Font8-specific filtering
# Check that only macOS-compatible fonts are included
```

**Test 5: Verify Formula Structure**
```ruby
# test/manual/test_formula_structure.rb
require "yaml"

formula_path = File.expand_path("~/.fontist/versions/v4/formulas/macos/al_bayan.yml")
formula = YAML.load_file(formula_path)

# Verify required fields
required = %w[name platforms resources fonts]
required.each do |field|
  raise "Missing #{field}" unless formula[field]
end

# Verify platform restriction
raise "Platform not set to macos" unless formula["platforms"] == ["macos"]

# Verify source
resource = formula["resources"].values.first
raise "Source not apple_cdn" unless resource["source"] == "apple_cdn"

puts "✓ Formula structure valid"
```

### 2.3 Font Installation Testing

**CRITICAL: Test on macOS only**

**Test 6: Apple CDN Download**
```ruby
# test/manual/test_apple_cdn_download.rb
require_relative "../../lib/fontist"
require_relative "../../lib/fontist/resources/apple_cdn_resource"

# Use a small font for testing
formula = Fontist::Formula.find_by_key("macos/al_bayan")
resource = formula.resources.first

apple_cdn = Fontist::Resources::AppleCDNResource.new(resource)

fonts_found = []
apple_cdn.files(["Al-Bayan.ttf"]) do |path|
  puts "✓ Downloaded: #{path}"
  fonts_found << path
end

raise "Font not downloaded" if fonts_found.empty?
```

**Test 7: System Directory Installation**
```bash
# WARNING: This modifies system directories
# Run with caution

# Install a test font
sudo bin/fontist install "Al Bayan"

# Verify installation location
find /System/Library/AssetsV2/ -name "Al-Bayan.ttf" 2>/dev/null

# Verify system recognition
fc-list | grep "Al Bayan"  # On Linux
# Or use Font Book on macOS
```

**Test 8: System Index Rebuild**
```ruby
# test/manual/test_system_index_rebuild.rb
require_relative "../../lib/fontist"

# Force rebuild
Fontist::SystemIndex.rebuild(verbose: true)

# Verify index includes new paths
system_index = Fontist::SystemIndex.system_index
fonts = system_index.fonts

# Check for PrivateFrameworks paths
private_fonts = fonts.select { |f| f.path.include?("PrivateFrameworks") }
puts "Found #{private_fonts.size} fonts in PrivateFrameworks"
```

### 2.4 Manifest Integration Testing

**Test 9: Manifest with macOS fonts**
Create test manifest: `test/fixtures/macos_manifest.yml`
```yaml
---
"Al Bayan":
  - Plain
"InaiMathi":
  - Regular
```

```ruby
# test/manual/test_manifest_install.rb
require_relative "../../lib/fontist"

manifest_path = "test/fixtures/macos_manifest.yml"
manifest = Fontist::Manifest.from_file(manifest_path)

begin
  result = manifest.install
  puts "✓ Manifest installation successful"
  result.fonts.each do |font|
    puts "  #{font.name}: #{font.styles.map(&:type).join(', ')}"
  end
rescue Fontist::Errors::PlatformMismatchError => e
  puts "✓ Platform error raised correctly (expected on non-macOS)"
  puts "  #{e.message}"
end
```

---

## Phase 3: Edge Cases & Error Handling (45 minutes)

### 3.1 Missing Catalog Handling
```ruby
# Simulate missing catalogs
# Move catalogs temporarily
catalogs = Fontist::Macos::Catalog::CatalogManager.available_catalogs
# Test should handle empty array gracefully
```

### 3.2 Network Failure Handling
```ruby
# Test with invalid URL
# Should fail gracefully with clear error
```

### 3.3 Permission Errors
```bash
# Test installation without sudo (if required)
# Should provide clear error message about permissions
```

### 3.4 Invalid Formula Testing
```ruby
# Test with formula missing required fields
# Test with formula having invalid source
# Test with formula having wrong platform
```

---

## Phase 4: RSpec Test Suite (45 minutes)

### 4.1 Create Unit Tests

**File: `spec/fontist/macos/catalog/asset_spec.rb`**
```ruby
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

  it "constructs download URL correctly" do
    expect(asset.download_url).to eq("https://updates.cdn-apple.com/fonts/AlBayan.zip")
  end

  it "extracts PostScript names" do
    expect(asset.postscript_names).to eq(["AlBayan"])
  end

  it "extracts font families" do
    expect(asset.font_families).to eq(["Al Bayan"])
  end
end
```

**File: `spec/fontist/errors_spec.rb` (enhance)**
```ruby
RSpec.describe Fontist::Errors::PlatformMismatchError do
  it "builds message with font name and platforms" do
    error = described_class.new("Test Font", ["macos"], :linux)

    expect(error.message).to include("Test Font")
    expect(error.message).to include("macos")
    expect(error.message).to include("linux")
  end
end
```

**File: `spec/fontist/formula_spec.rb` (enhance)**
```ruby
RSpec.describe Fontist::Formula do
  describe "#compatible_with_platform?" do
    context "with no platform restrictions" do
      let(:formula) { build_formula(platforms: nil) }

      it "is compatible with all platforms" do
        expect(formula.compatible_with_platform?(:macos)).to be true
        expect(formula.compatible_with_platform?(:linux)).to be true
      end
    end

    context "with macOS-only restriction" do
      let(:formula) { build_formula(platforms: ["macos"]) }

      it "is compatible with macOS" do
        expect(formula.compatible_with_platform?(:macos)).to be true
      end

      it "is not compatible with Linux" do
        expect(formula.compatible_with_platform?(:linux)).to be false
      end
    end
  end
end
```

### 4.2 Run Test Suite
```bash
# Run all tests
bundle exec rspec

# Run specific test files
bundle exec rspec spec/fontist/macos/
bundle exec rspec spec/fontist/formula_spec.rb
bundle exec rspec spec/fontist/errors_spec.rb

# Check for regressions
# All existing tests must pass
```

### 4.3 Fix Any Test Failures
- Analyze failure root causes
- Fix behavior (not expectations)
- Ensure architecture remains sound

---

## Phase 5: Documentation Updates (30 minutes)

### 5.1 Update README.adoc

Add section after existing macOS fonts section:

```adoc
== macOS On-Demand Fonts

Fontist supports automated installation of macOS on-demand fonts directly from Apple's CDN with platform validation.

=== Features

* Install 700+ macOS add-on fonts from Apple's CDN
* Platform validation prevents installation on incompatible systems
* Automatic system index updates after installation
* Support for Font7 (macOS Monterey/Ventura/Sonoma) and Font8 (macOS Sequoia)
* Manifest-based batch installation

[snip - see CONTINUATION_PLAN.md for full text]
```

### 5.2 Update CHANGELOG.md

```markdown
## [Unreleased]

### Added
- macOS on-demand font support with Apple CDN integration
- Platform validation for platform-specific fonts
- `fontist import macos --version` option for version-specific imports
- `fontist macos-catalogs` command to list available font catalogs
- System directory installation for macOS fonts
- Automatic system index rebuilding after installation

### Changed
- Enhanced `fontist import macos` with version options
- Extended system font paths to include PrivateFrameworks directories
```

### 5.3 Move Completed Documentation
```bash
# Move completed planning docs to old-docs
mv MACOS_ONDEMAND_FONTS_CONTINUATION_PLAN.md old-docs/
mv MACOS_ONDEMAND_FONTS_CONTINUATION_PROMPT.md old-docs/
mv MACOS_ONDEMAND_FONTS_STATUS.md old-docs/
```

---

## Phase 6: Refinement Based on Testing (flexible time)

### Issues to Watch For

1. **Permission Issues**
   - System directory writes may require sudo
   - Clear error messages needed

2. **Large Catalog Performance**
   - Font8 catalog is 2.3MB
   - Parsing should be efficient

3. **Network Timeouts**
   - Apple CDN downloads may be slow
   - Progress bars should work correctly

4. **Cache Issues**
   - Verify download caching works
   - Verify checksum validation

5. **Index Rebuild Performance**
   - System index rebuild should be fast
   - Locking should prevent race conditions

### Refinement Checklist

- [ ] All manual tests pass
- [ ] All RSpec tests pass
- [ ] Platform validation works correctly
- [ ] Error messages are clear and actionable
- [ ] Performance is acceptable
- [ ] Documentation is complete
- [ ] No security issues identified
- [ ] CLI UX is intuitive
- [ ] Edge cases handled gracefully

---

## Success Criteria

### Must Have
✅ All RSpec tests pass (no regressions)
✅ Manual tests on macOS succeed
✅ Platform validation prevents non-macOS installation
✅ Apple CDN downloads work
✅ System directory installation works
✅ Documentation complete

### Nice to Have
- Performance benchmarks documented
- Example formulas in repository
- User testimonials from testing
- Video demo of installation

---

## Next Steps After Testing

1. **Submit PR** to fontist/fontist repository
2. **Update formula repository** with macOS fonts
3. **Announce feature** to user community
4. **Monitor feedback** for first week
5. **Address issues** as they arise

---

## Risk Mitigation

### Risk: System Directory Write Failures
**Mitigation**: Fallback to user directory with warning

### Risk: Large Catalog Download Times
**Mitigation**: Progress indicators, caching strategy

### Risk: Platform Detection Edge Cases
**Mitigation**: Explicit override via environment variable

### Risk: Concurrent Installation Conflicts
**Mitigation**: File locking already implemented in SystemIndex

---

## Testing Checklist

```bash
# Copy this checklist and run through each item

## Environment Setup
- [ ] Ruby >= 2.7 installed
- [ ] Dependencies installed (bundle install)
- [ ] On macOS system (or have access to one)
- [ ] Font catalogs present in /System/Library/AssetsV2/

## CLI Testing
- [ ] `fontist macos-catalogs` lists available catalogs
- [ ] `fontist import macos` works (default)
- [ ] `fontist import macos --version 7` works (if Font7 available)
- [ ] `fontist import macos --version 8` works (if Font8 available)
- [ ] `fontist import macos --all-versions` works

## Installation Testing (macOS only)
- [ ] `fontist install "Al Bayan"` downloads and installs
- [ ] Font appears in /System/Library/AssetsV2/
- [ ] Font appears in Font Book
- [ ] System index includes new font
- [ ] `fontist list "Al Bayan"` shows installation

## Manifest Testing
- [ ] Create test manifest with macOS fonts
- [ ] `fontist manifest install manifest.yml` works on macOS
- [ ] Platform error raised on non-macOS (if testable)
- [ ] Multiple fonts install correctly

## Platform Validation Testing
- [ ] Platform-only formula rejects non-macOS installation
- [ ] Error message is clear and helpful
- [ ] No platform restriction allows all platforms

## RSpec Testing
- [ ] `bundle exec rspec` passes all tests
- [ ] No test regressions
- [ ] New tests for new functionality pass
- [ ] Coverage remains high

## Edge Cases
- [ ] Missing catalog handled gracefully
- [ ] Invalid formula handled gracefully
- [ ] Network error handled gracefully
- [ ] Permission error handled gracefully

## Code Quality
- [ ] `bundle exec rubocop` shows only acceptable issues
- [ ] No obvious security vulnerabilities
- [ ] Performance acceptable
- [ ] Memory usage acceptable

## Documentation
- [ ] README.adoc updated
- [ ] CHANGELOG.md updated
- [ ] Inline documentation clear
- [ ] Examples work correctly
```

---

**Document Status**: Testing & Refinement Plan
**Last Updated**: 2025-12-22 22:55 UTC+8
**Next Review**: After local testing completion