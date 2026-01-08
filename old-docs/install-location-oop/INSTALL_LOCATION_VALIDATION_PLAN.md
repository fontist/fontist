# Install Location Validation - Implementation Plan

## Objective

Implement complete validation for install locations across all entry points (CLI, Ruby API, Manifest) with comprehensive test coverage and proper error handling.

## Current State

### Completed
- ✅ Architecture documented ([`docs/install-locations-architecture.md`](docs/install-locations-architecture.md))
- ✅ User documentation created ([`docs/readme-install-locations-section.adoc`](docs/readme-install-locations-section.adoc))
- ✅ [`InstallLocation`](lib/fontist/install_location.rb) class with basic validation
- ✅ Error message improved for invalid locations

### Needs Implementation
- ❌ CLI validation for `--location` option
- ❌ Ruby API validation for `Font.install(location:)`
- ❌ Manifest API validation for `Manifest.install(location:)`
- ❌ Comprehensive specs for all validation paths
- ❌ Integration tests for CLI + API + Manifest
- ❌ Error handling for edge cases
- ❌ README.adoc update
- ❌ Documentation cleanup (move old docs)

## Implementation Tasks

### Phase 1: Core Validation Implementation (HIGH PRIORITY)

#### Task 1.1: CLI Validation
**File**: [`lib/fontist/cli.rb`](lib/fontist/cli.rb)

**Current State**: CLI accepts `--location` option but validation happens in `InstallLocation`

**Required Changes**:
1. Verify CLI passes location to `Font.install` correctly
2. Ensure error messages from `InstallLocation` are displayed properly
3. Add CLI-specific error handling for invalid locations
4. Test with: `fontist install "Font" --location=invalid`

**Acceptance Criteria**:
- Invalid location shows error and uses default
- Valid locations (`fontist`, `user`, `system`) work correctly
- Error message suggests valid options
- Exit code appropriate for error vs. success

#### Task 1.2: Ruby API Validation
**File**: [`lib/fontist/font.rb`](lib/fontist/font.rb)

**Current State**: `Font.install` accepts `location:` parameter

**Required Changes**:
1. Verify location parameter is passed to `InstallLocation`
2. Add validation before creating `InstallLocation`
3. Raise appropriate errors for invalid locations
4. Document location parameter in method comments

**Acceptance Criteria**:
```ruby
# Should work
Fontist::Font.install("Roboto", location: :fontist)
Fontist::Font.install("Roboto", location: "user")
Fontist::Font.install("Roboto", location: :system)

# Should reject with clear error
Fontist::Font.install("Roboto", location: "/custom/path")
Fontist::Font.install("Roboto", location: :invalid)
```

#### Task 1.3: Manifest API Validation
**File**: [`lib/fontist/manifest.rb`](lib/fontist/manifest.rb)

**Current State**: Manifest likely passes options to `Font.install`

**Required Changes**:
1. Verify manifest `install` method accepts `location:` parameter
2. Ensure location is passed to each font installation
3. Add validation for location parameter
4. Update manifest spec examples

**Acceptance Criteria**:
```ruby
manifest = Fontist::Manifest.from_hash({"Roboto" => ["Regular"]})

# Should work
manifest.install(location: :user)
manifest.install(location: "system")

# Should reject
manifest.install(location: "/custom/path")
```

#### Task 1.4: InstallLocation Validation Enhancement
**File**: [`lib/fontist/install_location.rb`](lib/fontist/install_location.rb)

**Current State**: Basic validation with fallback to `:fontist`

**Required Changes**:
1. Add option to raise error instead of silent fallback
2. Provide both strict and lenient validation modes
3. Improve error messages with context
4. Add validation helper method

**Proposed API**:
```ruby
# Lenient mode (current) - falls back with warning
location = InstallLocation.new(formula, location_type: "invalid")
# => logs error, uses :fontist

# Strict mode (new) - raises error
location = InstallLocation.new(formula, location_type: "invalid", strict: true)
# => raises ArgumentError
```

### Phase 2: Comprehensive Test Coverage (HIGH PRIORITY)

#### Task 2.1: InstallLocation Specs
**File**: [`spec/fontist/install_location_spec.rb`](spec/fontist/install_location_spec.rb)

**Current State**: 147 unit tests, 100% pass rate

**Required Additions**:
1. Test invalid location types
2. Test error messages
3. Test strict vs lenient mode
4. Test all three valid location types
5. Test platform-specific paths
6. Test FONTIST_PATH customization

**New Test Cases**:
```ruby
describe "#parse_location_type" do
  context "with invalid location" do
    it "falls back to fontist with warning"
    it "raises error in strict mode"
    it "provides helpful error message"
  end
  
  context "with custom path attempt" do
    it "rejects /custom/path"
    it "suggests using FONTIST_PATH"
  end
end
```

#### Task 2.2: CLI Integration Specs
**File**: [`spec/fontist/cli_spec.rb`](spec/fontist/cli_spec.rb)

**Required Additions**:
1. Test `--location=fontist`
2. Test `--location=user`
3. Test `--location=system`
4. Test `--location=invalid` (should error)
5. Test `--location=/custom/path` (should error)
6. Test error messages appear correctly
7. Test exit codes

**New Test Cases**:
```ruby
describe "install with --location" do
  context "valid locations" do
    it "accepts --location=fontist"
    it "accepts --location=user"
    it "accepts --location=system"
  end
  
  context "invalid locations" do
    it "rejects --location=invalid with error"
    it "rejects --location=/custom/path"
    it "shows helpful error message"
    it "returns error exit code"
  end
end
```

#### Task 2.3: Font API Specs
**File**: [`spec/fontist/font_spec.rb`](spec/fontist/font_spec.rb)

**Required Additions**:
1. Test `location: :fontist`
2. Test `location: :user`
3. Test `location: :system`
4. Test `location: :invalid` (should error)
5. Test `location: "/custom"` (should error)

**New Test Cases**:
```ruby
describe ".install with location parameter" do
  context "valid locations" do
    it "installs to fontist location"
    it "installs to user location"
    it "installs to system location"
  end
  
  context "invalid locations" do
    it "raises error for invalid symbol"
    it "raises error for custom path"
  end
end
```

#### Task 2.4: Manifest API Specs
**File**: [`spec/fontist/manifest_spec.rb`](spec/fontist/manifest_spec.rb)

**Required Additions**:
1. Test manifest install with `location: :user`
2. Test manifest install with `location: :system`
3. Test manifest install with invalid location
4. Test location applied to all fonts in manifest

**New Test Cases**:
```ruby
describe "install with location" do
  it "installs all fonts to user location"
  it "installs all fonts to system location"
  it "rejects invalid location"
end
```

### Phase 3: Edge Cases and Error Handling (MEDIUM PRIORITY)

#### Task 3.1: Permission Errors
1. Test system install without permissions
2. Test readonly filesystem scenarios
3. Provide helpful error messages

#### Task 3.2: Platform-Specific Validation
1. Test user/system paths on all platforms
2. Test platform detection errors
3. Test unsupported platform handling

#### Task 3.3: Config Validation
**File**: [`lib/fontist/config.rb`](lib/fontist/config.rb)

1. Add validation when setting `install_location` via config
2. Reject invalid values in config file
3. Test config validation

### Phase 4: Documentation and Cleanup (MEDIUM PRIORITY)

#### Task 4.1: Update README.adoc
**File**: [`README.adoc`](README.adoc)

1. Remove incorrect "Installation Locations" section (already done by user)
2. Copy content from [`docs/readme-install-locations-section.adoc`](docs/readme-install-locations-section.adoc)
3. Update config section to include `install_location`
4. Add environment variable documentation

#### Task 4.2: Move Old Documentation
Create [`old-docs/install-location-implementation/`](old-docs/install-location-implementation/) and move:
- `INSTALL_LOCATION_IMPLEMENTATION_STATUS.md`
- `INSTALL_LOCATION_TEST_FIXES_PLAN.md`  
- `INSTALL_LOCATION_CONTINUATION_PLAN.md`
- `INSTALL_LOCATION_CONTINUATION_PROMPT.md`
- `INSTALL_LOCATION_FINAL_CONTINUATION_PLAN.md`
- `INSTALL_LOCATION_FINAL_CONTINUATION_PROMPT.md`
- `INSTALL_LOCATION_FINAL_STATUS.md`
- `INSTALL_LOCATION_REFACTORING_SUMMARY.md`

Keep current:
- `INSTALL_LOCATION_ARCHITECTURE_SUMMARY.md` (summary)
- `docs/install-locations-architecture.md` (architecture)
- `docs/readme-install-locations-section.adoc` (for README)

#### Task 4.3: Update CHANGELOG
Add entry for install location feature

### Phase 5: Integration and Debugging (HIGH PRIORITY)

#### Task 5.1: End-to-End Testing
1. Test complete workflow: CLI → API → Installation → Discovery
2. Test all three location types end-to-end
3. Test error paths end-to-end
4. Verify fonts are found after installation regardless of location

#### Task 5.2: Debug Issues
1. Run full test suite
2. Fix any failing tests
3. Address any implementation bugs discovered
4. Verify formula-keyed paths work correctly

#### Task 5.3: Cross-Platform Verification
1. Test on macOS (if available)
2. Test on Linux (if available)
3. Test on Windows (if available)
4. Document any platform-specific issues

## Implementation Order

### Sprint 1 (Immediate - 2-3 hours)
1. Task 1.1: CLI Validation
2. Task 1.2: Ruby API Validation
3. Task 1.3: Manifest API Validation
4. Task 1.4: InstallLocation Enhancement
5. Task 2.1: InstallLocation Specs

### Sprint 2 (Next - 1-2 hours)
6. Task 2.2: CLI Integration Specs
7. Task 2.3: Font API Specs
8. Task 2.4: Manifest API Specs
9. Task 5.1: End-to-End Testing
10. Task 5.2: Debug Issues

### Sprint 3 (Final - 1 hour)
11. Task 4.1: Update README.adoc
12. Task 4.2: Move Old Documentation
13. Task 4.3: Update CHANGELOG
14. Final verification

## Success Criteria

### Functionality
- ✅ All three named locations work correctly
- ✅ Invalid locations are rejected with clear errors
- ✅ Custom paths are explicitly rejected
- ✅ FONTIST_PATH customization works
- ✅ Fonts are discoverable regardless of install location

### Code Quality
- ✅ Object-oriented design maintained
- ✅ MECE principle followed
- ✅ Separation of concerns preserved
- ✅ Proper error handling throughout

### Testing
- ✅ 100% pass rate on all tests
- ✅ Comprehensive coverage of validation scenarios
- ✅ Edge cases covered
- ✅ Integration tests passing

### Documentation
- ✅ README.adoc updated
- ✅ Architecture documented
- ✅ Old docs moved to old-docs/
- ✅ CHANGELOG updated

## Risk Areas

1. **Test Regressions**: Formula-keyed paths may cause test failures
   - Mitigation: Fix test expectations, not implementation
   
2. **Platform Differences**: Paths vary by OS
   - Mitigation: Platform-specific test conditions
   
3. **Permission Issues**: System installs need admin
   - Mitigation: Clear error messages, test with mocks

4. **Backward Compatibility**: Existing code may expect old behavior
   - Mitigation: Default to `fontist` location maintains compatibility