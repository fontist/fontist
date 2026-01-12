# macOS Add-on Fonts - Implementation Plan

## Overview

This document provides a step-by-step implementation plan for adding macOS add-on font support to Fontist. The architecture is documented in [`macos-addon-fonts-architecture.md`](macos-addon-fonts-architecture.md:1), and visual diagrams are in [`macos-addon-fonts-diagram.md`](macos-addon-fonts-diagram.md:1).

## Prerequisites

Before starting implementation:
- [x] Architecture designed and documented
- [x] Visual diagrams created
- [ ] User review and approval of architecture
- [ ] Access to macOS system for testing
- [ ] Understanding of existing Fontist architecture

## Implementation Phases

### Phase 1: Core Models and Parsing (MVP)
**Goal**: Parse macOS asset catalog and model the data

**Estimated Effort**: 4-6 hours

#### 1.1 Create AssetFont Model
**File**: `lib/fontist/macos/asset_font.rb`

**Tasks**:
- [ ] Create `Fontist::MacOS` module
- [ ] Define `AssetFont` class inheriting from `Lutaml::Model::Serializable`
- [ ] Add attributes: asset_id, asset_type, relative_path, font_family, display_name, postscript_names, collection_behavior, version
- [ ] Implement `installed?` method
- [ ] Implement `installation_path` method
- [ ] Implement `font_files` method
- [ ] Add unit tests in `spec/fontist/macos/asset_font_spec.rb`

**Success Criteria**:
- All tests pass
- Model correctly represents asset data
- Installation detection works correctly

#### 1.2 Create AssetCatalog Parser
**File**: `lib/fontist/macos/asset_catalog.rb`

**Tasks**:
- [ ] Create `AssetCatalog` class
- [ ] Implement singleton pattern
- [ ] Add `detect_catalog_path` method (searches Font3-Font7)
- [ ] Add `parse_catalog` method using `plist` gem
- [ ] Add `parse_asset` helper method
- [ ] Implement `find_by_family(name)` method
- [ ] Implement `find_by_postscript_name(name)` method
- [ ] Implement `all_assets` method
- [ ] Add unit tests in `spec/fontist/macos/asset_catalog_spec.rb`

**Success Criteria**:
- Can parse real macOS catalog XML
- Returns `AssetFont` instances
- Case-insensitive searches work
- Handles missing catalog gracefully

#### 1.3 Add Error Classes
**File**: `lib/fontist/errors.rb`

**Tasks**:
- [ ] Add `MacOSAssetError` base class
- [ ] Add `MacOSAssetCatalogNotFound` error
- [ ] Add `MacOSAssetNotFound` error
- [ ] Add `MacOSAssetInstallationFailed` error
- [ ] Add `MacOSAssetInstallationTimeout` error
- [ ] Add `MacOSAssetManualInstallRequired` error
- [ ] Add `NotMacOSError` error

**Success Criteria**:
- All error messages are clear and actionable
- Errors provide helpful guidance to users

#### 1.4 Update System Configuration
**File**: `lib/fontist/system.yml`

**Tasks**:
- [x] Already includes `/System/Library/AssetsV2/` path
- [ ] Verify path pattern matches installed assets
- [ ] Test on multiple macOS versions

**Success Criteria**:
- System font detection includes installed add-on fonts
- No duplicate paths

---

### Phase 2: Installation Infrastructure
**Goal**: Trigger and verify font installation

**Estimated Effort**: 6-8 hours

#### 2.1 Create AssetInstaller
**File**: `lib/fontist/macos/asset_installer.rb`

**Tasks**:
- [ ] Create `AssetInstaller` class
- [ ] Add initialization with asset and options
- [ ] Implement `install` method (main entry point)
- [ ] Implement `trigger_installation` method
- [ ] Research and implement installation strategies:
  - [ ] Strategy 1: `fontrestore` command
  - [ ] Strategy 2: `softwareupdate` command (if supported)
  - [ ] Strategy 3: Manual fallback with clear instructions
- [ ] Implement `wait_for_installation` with timeout
- [ ] Implement `show_progress` method
- [ ] Implement `verify_installation` method
- [ ] Add unit tests in `spec/fontist/macos/asset_installer_spec.rb`
- [ ] Add integration test (requires macOS)

**Research Needed**:
- Exact command syntax for `fontrestore`
- Whether `softwareupdate` supports individual fonts
- Security requirements (sudo, SIP, etc.)
- How to detect installation completion

**Success Criteria**:
- Can trigger installation (even if requires manual step)
- Correctly detects when installation completes
- Handles timeouts gracefully
- Provides clear error messages

#### 2.2 Create MacOSAssetResource
**File**: `lib/fontist/resources/macos_asset_resource.rb`

**Tasks**:
- [ ] Create `Resources::MacOSAssetResource` class
- [ ] Implement `initialize(resource, options)`
- [ ] Implement `files(source_names, &block)` method
- [ ] Implement `install_and_yield_font(ps_name)` helper
- [ ] Implement `find_asset(ps_name)` helper
- [ ] Add unit tests in `spec/fontist/resources/macos_asset_resource_spec.rb`

**Success Criteria**:
- Follows same interface as `ArchiveResource` and `GoogleResource`
- Correctly delegates to `AssetInstaller`
- Handles multiple PostScript names
- Block-based API works correctly

#### 2.3 Extend FontInstaller
**File**: `lib/fontist/font_installer.rb`

**Tasks**:
- [ ] Add `macos_asset` case to `resource` method
- [ ] Override `install_font_file` to handle system location
- [ ] Update tests in `spec/fontist/font_installer_spec.rb`

**Success Criteria**:
- Detects `source: macos_asset` in formulas
- Creates `MacOSAssetResource` instance
- Fonts remain in system location (not copied)
- Backward compatible with existing formulas

---

### Phase 3: Formula Support
**Goal**: Define formula structure and enable formula-based installation

**Estimated Effort**: 4-5 hours

#### 3.1 Extend Formula Model
**File**: `lib/fontist/formula.rb`

**Tasks**:
- [ ] Verify `Resource` class supports `source` attribute
- [ ] Add `postscript_names` attribute to `Resource` if needed
- [ ] Add `family` attribute to `Resource` if needed
- [ ] Update tests

**Success Criteria**:
- Formula YAML with `source: macos_asset` parses correctly
- All new attributes serialize/deserialize properly

#### 3.2 Create Example Formulas
**Directory**: `spec/fixtures/formulas/Formulas/macos/`

**Tasks**:
- [ ] Create `sf_mono.yml` formula
- [ ] Create `ny_times.yml` formula (or another common add-on font)
- [ ] Validate formula structure
- [ ] Test formula loading
- [ ] Test installation via formula

**Example Formula Structure**:
```yaml
---
name: SF Mono
description: Apple's monospaced font for developers
homepage: https://developer.apple.com/fonts/
open_license: Apple Font License for macOS

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
```

**Success Criteria**:
- Formula validates against schema
- Can be loaded via `Formula.from_file`
- Installation works end-to-end

---

### Phase 4: Formula Generation
**Goal**: Automatically generate formulas for all macOS add-on fonts

**Estimated Effort**: 5-7 hours

#### 4.1 Create Formula Builder
**File**: `lib/fontist/import/macos_asset_importer.rb`

**Tasks**:
- [ ] Create `Import::MacOSAssetImporter` class
- [ ] Implement `import` method (main entry point)
- [ ] Implement `build_formula(asset)` method
- [ ] Implement `save_formula(formula, asset)` method
- [ ] Implement `normalize_name(name)` helper
- [ ] Add tests in `spec/fontist/import/macos_asset_importer_spec.rb`

**Success Criteria**:
- Generates valid formulas for all available assets
- Formulas follow consistent naming convention
- Skips pre-installed fonts
- Handles special characters in font names

#### 4.2 Generate All Formulas
**Tasks**:
- [ ] Run importer on real macOS system
- [ ] Review generated formulas for correctness
- [ ] Commit formulas to formula repository
- [ ] Create PR to fontist/formulas repository

**Success Criteria**:
- ~700 formulas generated
- All formulas are valid YAML
- Formulas can be loaded by Fontist
- No duplicate formulas

---

### Phase 5: CLI Integration
**Goal**: Add user-facing commands

**Estimated Effort**: 3-4 hours

#### 5.1 Create MacOS Subcommand
**File**: `lib/fontist/cli/macos.rb`

**Tasks**:
- [ ] Create `CLI::MacOS` class inheriting from Thor
- [ ] Implement `list` command with `--installed` option
- [ ] Implement `info FONT` command
- [ ] Add help text and descriptions
- [ ] Add tests in `spec/fontist/cli/macos_spec.rb`

#### 5.2 Register Subcommand
**File**: `lib/fontist/cli.rb`

**Tasks**:
- [ ] Add `macos` subcommand to main CLI
- [ ] Update help text

#### 5.3 Add Import Command
**File**: `lib/fontist/cli.rb` or specialized importer CLI

**Tasks**:
- [ ] Add `import macos-assets` command
- [ ] Add options for output path, etc.
- [ ] Add tests

**Success Criteria**:
- Commands work as documented
- Help text is clear
- Error messages are actionable
- Integration tests pass

---

### Phase 6: Documentation and Testing
**Goal**: Complete documentation and test coverage

**Estimated Effort**: 3-4 hours

#### 6.1 Update User Documentation
**File**: `README.adoc`

**Tasks**:
- [ ] Add "macOS Add-on Fonts" section
- [ ] Document `fontist macos list` command
- [ ] Document `fontist macos info` command
- [ ] Add installation examples
- [ ] List notable fonts available

#### 6.2 Add Developer Documentation
**Files**: Various

**Tasks**:
- [ ] Add code comments to all classes
- [ ] Document public APIs with YARD
- [ ] Add examples to class documentation

#### 6.3 Test Coverage
**Tasks**:
- [ ] Ensure all unit tests pass
- [ ] Add integration tests (macOS-only)
- [ ] Test on macOS 12, 13, 14, 15
- [ ] Test error paths
- [ ] Test timeout scenarios
- [ ] Manual testing checklist

**Testing Checklist**:
- [ ] Install fresh font (not previously installed)
- [ ] Install already-installed font (should skip)
- [ ] List all fonts
- [ ] List installed fonts only
- [ ] Show info for specific font
- [ ] Test timeout behavior
- [ ] Test error messages
- [ ] Verify formulas are correct
- [ ] Test with Font Book closed
- [ ] Test with Font Book open

---

### Phase 7: Polish and Release
**Goal**: Final polish and release preparation

**Estimated Effort**: 2-3 hours

#### 7.1 Code Review
**Tasks**:
- [ ] Self-review all code
- [ ] Check for code smells
- [ ] Ensure MECE principles followed
- [ ] Verify OOP design
- [ ] Run Rubocop
- [ ] Fix any style issues

#### 7.2 Performance Testing
**Tasks**:
- [ ] Test catalog parsing performance
- [ ] Test installation timeout is reasonable
- [ ] Ensure no memory leaks

#### 7.3 Release
**Tasks**:
- [ ] Update CHANGELOG.md
- [ ] Bump version number
- [ ] Create release notes
- [ ] Submit PR to fontist/fontist
- [ ] Submit PR to fontist/formulas (if formulas ready)

---

## File Structure

Expected new files:

```
lib/fontist/
├── macos/
│   ├── asset_font.rb           # NEW
│   ├── asset_catalog.rb        # NEW
│   └── asset_installer.rb      # NEW
├── resources/
│   └── macos_asset_resource.rb # NEW
├── import/
│   └── macos_asset_importer.rb # NEW
├── cli/
│   └── macos.rb                # NEW
├── errors.rb                   # MODIFIED (7 new error classes)
├── font_installer.rb           # MODIFIED (macos_asset case)
└── formula.rb                  # VERIFY (may need attributes)

spec/fontist/
├── macos/
│   ├── asset_font_spec.rb      # NEW
│   ├── asset_catalog_spec.rb   # NEW
│   └── asset_installer_spec.rb # NEW
├── resources/
│   └── macos_asset_resource_spec.rb # NEW
├── import/
│   └── macos_asset_importer_spec.rb # NEW
├── cli/
│   └── macos_spec.rb           # NEW
└── integration/
    └── macos_font_spec.rb      # NEW

spec/fixtures/formulas/Formulas/macos/
├── sf_mono.yml                 # NEW
└── ny_times.yml                # NEW

docs/
├── macos-addon-fonts-architecture.md      # CREATED
├── macos-addon-fonts-diagram.md           # CREATED
└── macos-addon-fonts-implementation-plan.md # THIS FILE
```

---

## Dependencies

### Existing Dependencies (No Changes)
- `plist` (~> 3.0) - Already used, perfect for XML parsing
- `lutaml-model` (~> 0.7) - Used for all models
- All other existing dependencies

### System Requirements
- macOS 10.15 (Catalina) or later
- Read access to `/System/Library/AssetsV2/`
- Potentially admin privileges for installation (TBD)

---

## Testing Strategy

### Unit Tests
- All classes have corresponding spec files
- Mock system interactions
- Use VCR for any API calls (if applicable)
- Test error conditions
- Coverage target: 95%+

### Integration Tests
- Marked with `skip_unless: :macos`
- Test real catalog parsing
- Test real font installation (if automated)
- Test CLI commands end-to-end

### Manual Testing
- Test on multiple macOS versions
- Test with different fonts
- Test error scenarios
- Verify user experience

---

## Open Research Questions

### Priority 1 (Blocking)
1. **How to trigger installation programmatically?**
   - Does `fontrestore` work without sudo?
   - Does `softwareupdate` support individual fonts?
   - Are there private APIs we can use safely?
   - Fallback: Guide user to Font Book

2. **How to detect installation completion?**
   - File system watching?
   - Polling with timeout?
   - System notifications?

### Priority 2 (Important)
3. **What are the exact catalog formats across macOS versions?**
   - Test on 12, 13, 14, 15
   - Are asset IDs stable?
   - Do PostScript names change?

4. **Are there security restrictions?**
   - SIP (System Integrity Protection)?
   - Code signing requirements?
   - User permissions needed?

### Priority 3 (Nice to Have)
5. **Can we provide better progress feedback?**
   - Real-time progress from system?
   - Estimated time remaining?

6. **How do we handle beta/preview releases?**
   - Different catalog locations?
   - Asset availability?

---

## Risk Mitigation

### Technical Risks

**Risk**: Cannot automate installation
- **Mitigation**: Implement manual fallback with clear instructions
- **Impact**: Medium (users can still install via Font Book)

**Risk**: Catalog format changes between macOS versions
- **Mitigation**: Test on multiple versions, handle parsing errors gracefully
- **Impact**: High (breaks feature on new macOS)

**Risk**: System Integrity Protection blocks access
- **Mitigation**: Request appropriate permissions, provide clear error messages
- **Impact**: High (cannot read catalog)

**Risk**: Installation command requires sudo
- **Mitigation**: Detect requirement, prompt user clearly
- **Impact**: Medium (reduces automation value)

### Process Risks

**Risk**: Large number of formulas (~700) to maintain
- **Mitigation**: Automate formula generation, set up CI for validation
- **Impact**: Medium (maintenance burden)

**Risk**: Breaking changes to existing Fontist functionality
- **Mitigation**: Comprehensive testing, careful FontInstaller changes
- **Impact**: High (regression in existing features)

---

## Success Criteria

### Must Have (MVP)
- [x] Architecture documented
- [ ] Parse macOS asset catalog
- [ ] Detect installed fonts
- [ ] Trigger installation (manual fallback OK)
- [ ] Generate valid formulas
- [ ] Unit tests pass
- [ ] Works on at least macOS 13+

### Should Have
- [ ] Automated installation (no Font Book)
- [ ] CLI commands functional
- [ ] Integration tests pass
- [ ] Documentation complete
- [ ] Formula repository updated

### Nice to Have
- [ ] Progress reporting
- [ ] Batch installation
- [ ] Support for macOS 12
- [ ] Installation time estimates

---

## Next Steps

1. **Review Architecture** - User should review and approve design
2. **Start Phase 1** - Begin with core models and parsing
3. **Test on Real System** - Use actual macOS for development
4. **Iterate** - Adjust design based on implementation learnings
5. **Switch to Code Mode** - Begin implementation after approval

---

## Questions for User

Before starting implementation:

1. Do you want to start with Phase 1 (core models) or a different phase?
2. Should we prioritize automated installation or accept manual fallback?
3. Do you have access to macOS 12, 13, 14, and 15 for testing?
4. Should formulas go in main repository or separate macos/ directory?
5. Any concerns with the proposed architecture?