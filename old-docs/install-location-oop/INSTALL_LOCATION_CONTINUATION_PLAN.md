# Universal Install Location - Continuation Plan

## Overview

This plan covers completion of the Universal Install Location implementation, including comprehensive testing, documentation, and cleanup.

**Current Status:** Implementation Complete (85%)
**Remaining Work:** Testing (Phase 5), Documentation (Phase 6)
**Timeline:** 4-6 hours compressed

## Architecture Summary

### Three Universal Location Types

1. **fontist** (default): `~/.fontist/fonts/{formula-key}/`
   - Isolated, safe, no permissions
   
2. **user**: Platform-specific user directory
   - macOS: `~/Library/Fonts`
   - Linux: `~/.local/share/fonts`
   - Windows: `%USERPROFILE%\AppData\Local\Microsoft\Windows\Fonts`
   
3. **system**: Platform-specific system directory
   - macOS (regular): `/System/Library/Fonts`
   - macOS (supplementary): `/System/Library/Assets*/com_apple_MobileAsset_Font<N>/{asset_id}.asset/AssetData/`
   - Linux: `/usr/local/share/fonts`
   - Windows: `%windir%\Fonts`

## Phase 5: Comprehensive Testing (Priority: HIGH, Time: 3-4h)

### 5.1 Unit Tests

#### MacosFrameworkMetadata Tests
**File:** `spec/fontist/macos_framework_metadata_spec.rb`

```ruby
RSpec.describe Fontist::MacosFrameworkMetadata do
  describe ".framework_for_macos" do
    it "returns 3 for macOS 10.12" do
      expect(described_class.framework_for_macos("10.12")).to eq(3)
    end

    it "returns 4 for macOS 10.13" do
      expect(described_class.framework_for_macos("10.13")).to eq(4)
    end

    it "returns 5 for macOS 10.14" do
      expect(described_class.framework_for_macos("10.14")).to eq(5)
    end

    it "returns 5 for macOS 10.15" do
      expect(described_class.framework_for_macos("10.15")).to eq(5)
    end

    it "returns 6 for macOS 11.0" do
      expect(described_class.framework_for_macos("11.0")).to eq(6)
    end

    it "returns 7 for macOS 12.0" do
      expect(described_class.framework_for_macos("12.0")).to eq(7)
    end

    it "returns 7 for macOS 15.99" do
      expect(described_class.framework_for_macos("15.99")).to eq(7)
    end

    it "returns 8 for macOS 26.0" do
      expect(described_class.framework_for_macos("26.0")).to eq(8)
    end

    it "returns nil for unsupported versions (16-25)" do
      expect(described_class.framework_for_macos("16.0")).to be_nil
      expect(described_class.framework_for_macos("20.0")).to be_nil
      expect(described_class.framework_for_macos("25.0")).to be_nil
    end

    it "returns nil for ancient versions" do
      expect(described_class.framework_for_macos("10.11")).to be_nil
      expect(described_class.framework_for_macos("10.10")).to be_nil
    end
  end

  describe ".system_install_path" do
    it "returns correct path for each framework" do
      expect(described_class.system_install_path(3)).to include("Font3")
      expect(described_class.system_install_path(5)).to include("AssetsV2")
      expect(described_class.system_install_path(8)).to include("AssetsV2")
    end
  end
end
```

#### InstallLocation Tests
**File:** `spec/fontist/install_location_spec.rb`

```ruby
RSpec.describe Fontist::InstallLocation do
  let(:formula) { instance_double(Fontist::Formula, key: "test/font", macos_import?: false) }

  describe "location types" do
    it "defaults to fontist" do
      location = described_class.new(formula)
      expect(location.fontist_install?).to be true
    end

    it "accepts user location" do
      location = described_class.new(formula, location_type: :user)
      expect(location.user_install?).to be true
    end

    it "accepts system location" do
      location = described_class.new(formula, location_type: :system)
      expect(location.system_install?).to be true
    end
  end

  describe "#base_path" do
    context "with fontist location" do
      it "returns formula-keyed path" do
        location = described_class.new(formula, location_type: :fontist)
        expect(location.base_path.to_s).to include("test/font")
      end
    end

    context "with user location on macOS" do
      before do
        allow(Fontist::Utils::System).to receive(:user_os).and_return(:macos)
      end

      it "returns ~/Library/Fonts" do
        location = described_class.new(formula, location_type: :user)
        expect(location.base_path.to_s).to match(%r{Library/Fonts$})
      end
    end

    context "with user location on Linux" do
      before do
        allow(Fontist::Utils::System).to receive(:user_os).and_return(:linux)
      end

      it "returns ~/.local/share/fonts" do
        location = described_class.new(formula, location_type: :user)
        expect(location.base_path.to_s).to match(%r{\.local/share/fonts$})
      end
    end
  end

  describe "#permission_warning" do
    it "returns nil for fontist install" do
      location = described_class.new(formula, location_type: :fontist)
      expect(location.permission_warning).to be_nil
    end

    it "returns nil for user install" do
      location = described_class.new(formula, location_type: :user)
      expect(location.permission_warning).to be_nil
    end

    it "returns warning for system install" do
      location = described_class.new(formula, location_type: :system)
      expect(location.permission_warning).to include("WARNING")
      expect(location.permission_warning).to include("root/administrator")
    end
  end

  describe "#requires_elevated_permissions?" do
    it "returns false for fontist" do
      location = described_class.new(formula, location_type: :fontist)
      expect(location.requires_elevated_permissions?).to be false
    end

    it "returns false for user" do
      location = described_class.new(formula, location_type: :user)
      expect(location.requires_elevated_permissions?).to be false
    end

    it "returns true for system" do
      location = described_class.new(formula, location_type: :system)
      expect(location.requires_elevated_permissions?).to be true
    end
  end
end
```

#### Platform Override Tests
**File:** `spec/fontist/utils/system_platform_override_spec.rb`

```ruby
RSpec.describe Fontist::Utils::System do
  describe "platform override" do
    after do
      ENV.delete("FONTIST_PLATFORM_OVERRIDE")
    end

    describe ".parse_platform_override" do
      it "parses macos-font7" do
        ENV["FONTIST_PLATFORM_OVERRIDE"] = "macos-font7"
        result = described_class.parse_platform_override
        expect(result[:os]).to eq(:macos)
        expect(result[:framework]).to eq(7)
      end

      it "parses linux" do
        ENV["FONTIST_PLATFORM_OVERRIDE"] = "linux"
        result = described_class.parse_platform_override
        expect(result[:os]).to eq(:linux)
        expect(result[:framework]).to be_nil
      end

      it "returns nil for invalid format" do
        ENV["FONTIST_PLATFORM_OVERRIDE"] = "macos-10.15"
        result = described_class.parse_platform_override
        expect(result).to be_nil
      end
    end

    describe ".catalog_version_for_macos" do
      it "uses override when set" do
        ENV["FONTIST_PLATFORM_OVERRIDE"] = "macos-font7"
        expect(described_class.catalog_version_for_macos).to eq(7)
      end
    end
  end
end
```

### 5.2 Integration Tests

**File:** `spec/integration/install_location_spec.rb`

```ruby
RSpec.describe "Install Location Integration" do
  # Test end-to-end installation with different locations
  # Requires test formulas and fixtures
end
```

### 5.3 Regression Testing

- Run full test suite: `bundle exec rspec`
- Ensure 617+ examples still pass
- Update failing tests with new correct expectations
- Verify non-platform-tagged formulas still work

## Phase 6: Documentation (Priority: HIGH, Time: 1-2h)

### 6.1 Update README.adoc

**File:** `README.adoc`

Add new sections:

```asciidoc
== Installation Locations

Fontist supports three installation locations:

=== fontist (default, recommended)

Installs fonts to `~/.fontist/fonts/` in formula-keyed directories.

* Safe and isolated from system
* No permissions required
* Prevents conflicts between formulas

[source,bash]
----
fontist install "Roboto"  # Uses fontist location by default
----

=== user

Installs fonts to user-specific font directory:

* macOS: `~/Library/Fonts`
* Linux: `~/.local/share/fonts`
* Windows: `%USERPROFILE%\AppData\Local\Microsoft\Windows\Fonts`

[source,bash]
----
fontist install "Roboto" --install-location=user
----

=== system

Installs fonts to system-wide directory (requires admin permissions):

* macOS: `/System/Library/Fonts` (regular) or `/System/Library/Assets*/` (supplementary)
* Linux: `/usr/local/share/fonts`
* Windows: `%windir%\Fonts`

WARNING: System installation requires root/administrator permissions and shows a warning.

[source,bash]
----
fontist install "Roboto" --install-location=system
----

== Environment Variables

=== FONTIST_INSTALL_LOCATION

Set default installation location:

[source,bash]
----
export FONTIST_INSTALL_LOCATION="user"
fontist install "Roboto"  # Installs to user directory
----

Valid values: `fontist`, `user`, `system`

=== FONTIST_PLATFORM_OVERRIDE

Override platform detection (for Docker, CI, testing):

[source,bash]
----
export FONTIST_PLATFORM_OVERRIDE="macos-font7"
----

Valid values: `macos-font<N>`, `linux`, `windows`

== macOS Supplementary Fonts

Fontist supports installation of macOS supplementary fonts available through Font Book.

=== Supported macOS Versions

[cols="1,1,2"]
|===
|Framework |macOS Version |Description

|Font3 |10.12 |Sierra
|Font4 |10.13 |High Sierra
|Font5 |10.14-10.15 |Mojave, Catalina
|Font6 |10.15-11.99 |Catalina, Big Sur
|Font7 |12.0-15.99 |Monterey, Ventura, Sonoma, Sequoia
|Font8 |26.0+ |Tahoe and future
|===

NOTE: macOS versions 16-25 do not exist (Apple jumped from 15 to 26).

=== Unsupported Versions

If your macOS version is not supported, Fontist will show an error with:

* Table of supported frameworks
* Instructions for platform override
* Alternative installation to fontist library

[source,bash]
----
# Override for unsupported version
export FONTIST_PLATFORM_OVERRIDE="macos-font7"
fontist install "SF Pro" --install-location=fontist
----
```

### 6.2 Create Installation Guide

**File:** `docs/install-locations-guide.md`

Comprehensive guide with:
- Detailed explanation of each location type
- Platform-specific examples
- Permission requirements
- Troubleshooting section
- Best practices

### 6.3 Clean Up Documentation

**Move to old-docs/:**
1. `docs/macos-addon-fonts-implementation-summary.md`
2. `docs/macos-font-platform-versioning-architecture.md`
3. `MACOS_PLATFORM_FIX_CONTINUATION_PLAN.md`
4. `MACOS_PLATFORM_FIX_STATUS.md`
5. `MACOS_IMPORT_FIX_SUMMARY.md`

**Update references:**
- Search for links to moved documents
- Update to point to official README.adoc sections

## Compressed Timeline

| Phase | Parallel? | Time |
|-------|-----------|------|
| 5.1 Unit Tests | No | 2h |
| 5.2 Integration Tests | No | 1h |
| 5.3 Regression | No | 0.5h |
| 6.1 README Update | Yes (with 5.3) | 1h |
| 6.2 Guide Creation | Yes (with 5.3) | 0.5h |
| 6.3 Cleanup | Yes (with 6.1) | 0.5h |
| **Total** | | **4-5h** |

## Success Criteria

- [ ] All unit tests pass (100% of new code)
- [ ] Integration tests demonstrate end-to-end functionality
- [ ] Full test suite passes (617+ examples)
- [ ] README.adoc fully documents install locations
- [ ] Installation guide created
- [ ] Old documentation moved to old-docs/
- [ ] All references updated

## Implementation Notes

### Testing Strategy

1. **Isolate platform-specific code**: Mock `Utils::System.user_os`
2. **Test permission requirements**: Verify warnings shown
3. **Test path resolution**: All platforms covered
4. **Test ENV priority**: ENV > config > default

### Documentation Strategy

1. **User-focused**: Clear examples for common use cases
2. **Platform-specific**: Separate sections per platform
3. **Security-conscious**: Highlight permission requirements
4. **Troubleshooting**: Common issues and solutions

### Cleanup Strategy

1. **Preserve history**: Move to old-docs/, don't delete
2. **Update links**: Redirect to official documentation
3. **Clear references**: No broken links

## Risk Mitigation

- **Test failures**: Update expectations to match correct behavior
- **Breaking changes**: None - default behavior unchanged
- **Platform differences**: Comprehensive platform-specific tests
- **Permission issues**: Clear documentation and warnings

## Next Steps After Completion

1. **Git commit** with clear message
2. **Update CHANGELOG.md**
3. **Create PR** with comprehensive description
4. **Tag release** when merged
5. **Announce** new features to users