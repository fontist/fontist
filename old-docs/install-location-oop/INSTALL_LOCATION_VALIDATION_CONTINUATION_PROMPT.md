# Install Location Validation - Continuation Prompt

## Context

You are continuing work on the **Install Location Validation** feature for Fontist. The architecture has been designed and documented, and now needs complete implementation with comprehensive testing.

**Project**: Fontist - Font management tool  
**Feature**: Install location validation across CLI, Ruby API, and Manifest API  
**Status**: Architecture complete, implementation 20% complete  
**Priority**: HIGH - Complete within 4-6 hours

---

## What's Already Done ✅

### Architecture & Documentation
- ✅ Complete architecture documented in [`docs/install-locations-architecture.md`](docs/install-locations-architecture.md)
- ✅ User documentation ready in [`docs/readme-install-locations-section.adoc`](docs/readme-install-locations-section.adoc)
- ✅ [`InstallLocation`](lib/fontist/install_location.rb) class exists with basic validation
- ✅ Error message improved for invalid locations (lines 117-124)
- ✅ 147 unit tests for InstallLocation, 100% pass rate

### Core Concepts (CRITICAL TO UNDERSTAND)

**Two Separate Concepts:**

1. **Install Locations** (WHERE to install - user chooses ONE):
   - `fontist` - Fontist library at `~/.fontist/fonts/{formula-key}/` (customizable base via `FONTIST_PATH`)
   - `user` - Platform-specific user directory (no admin)
   - `system` - Platform-specific system directory (requires admin)
   - **NO custom paths supported** (e.g., `/my/custom/path` is INVALID)

2. **Font Search** (WHERE to find - ALWAYS all locations):
   - System font directories (automatic)
   - User font directories (automatic)
   - Fontist library (automatic)

**Key Implementation Point**: [`InstallLocation#parse_location_type`](lib/fontist/install_location.rb:105) already rejects invalid locations with a warning and falls back to `:fontist`.

---

## What Needs To Be Done ⚠️

### CRITICAL: Read These Files First
Before starting ANY task, read these files to understand the complete picture:

1. [`INSTALL_LOCATION_VALIDATION_PLAN.md`](INSTALL_LOCATION_VALIDATION_PLAN.md) - Complete implementation plan
2. [`INSTALL_LOCATION_VALIDATION_STATUS.md`](INSTALL_LOCATION_VALIDATION_STATUS.md) - Current status tracker
3. [`docs/install-locations-architecture.md`](docs/install-locations-architecture.md) - Architecture spec
4. [`INSTALL_LOCATION_ARCHITECTURE_SUMMARY.md`](INSTALL_LOCATION_ARCHITECTURE_SUMMARY.md) - High-level summary

### Implementation Tasks (In Order)

#### Sprint 1: Core Validation (2-3 hours) 🎯

**Task 1.1: CLI Validation**
- File: [`lib/fontist/cli.rb`](lib/fontist/cli.rb)
- Verify `--location` option passes correctly to `Font.install`
- Ensure error messages from `InstallLocation` are displayed
- Add tests in [`spec/fontist/cli_spec.rb`](spec/fontist/cli_spec.rb):
  ```ruby
  describe "install with --location" do
    it "accepts --location=fontist"
    it "accepts --location=user"
    it "accepts --location=system"
    it "rejects --location=invalid with error"
    it "rejects --location=/custom/path"
    it "shows helpful error message"
  end
  ```

**Task 1.2: Ruby API Validation**
- File: [`lib/fontist/font.rb`](lib/fontist/font.rb)
- Verify `Font.install(name, location: :user)` works
- Add validation before creating `InstallLocation`
- Document `location:` parameter in method comments
- Add tests in [`spec/fontist/font_spec.rb`](spec/fontist/font_spec.rb):
  ```ruby
  describe ".install with location parameter" do
    it "installs to fontist location"
    it "installs to user location"
    it "installs to system location"
    it "raises error for invalid location"
    it "raises error for custom path"
  end
  ```

**Task 1.3: Manifest API Validation**
- File: [`lib/fontist/manifest.rb`](lib/fontist/manifest.rb)
- Verify `manifest.install(location: :user)` works
- Ensure location is passed to each font installation
- Add tests in [`spec/fontist/manifest_spec.rb`](spec/fontist/manifest_spec.rb):
  ```ruby
  describe "install with location" do
    it "installs all fonts to user location"
    it "installs all fonts to system location"
    it "rejects invalid location"
  end
  ```

**Task 1.4: InstallLocation Enhancement**
- File: [`lib/fontist/install_location.rb`](lib/fontist/install_location.rb)
- Add `strict:` parameter to enable raising errors instead of warning
- Current behavior (lenient): logs error, falls back to `:fontist`
- New behavior (strict): raises `ArgumentError` for invalid location
- Add tests in [`spec/fontist/install_location_spec.rb`](spec/fontist/install_location.spec.rb)

#### Sprint 2: Testing & Debugging (1-2 hours) 🧪

**Task 2.1-2.4: Comprehensive Test Coverage**
- Add +50 tests across all specs
- Cover all validation scenarios
- Test all three valid locations
- Test invalid location rejection
- Test error messages

**Task 5.1-5.2: Integration & Debug**
- Run full test suite: `bundle exec rspec`
- Fix any failing tests
- Verify end-to-end workflows
- Check formula-keyed paths work correctly

#### Sprint 3: Documentation (1 hour) 📝

**Task 4.1: Update README.adoc**
- Copy content from [`docs/readme-install-locations-section.adoc`](docs/readme-install-locations-section.adoc)
- Update config section
- Add environment variable docs

**Task 4.2: Move Old Documentation**
- Create `old-docs/install-location-implementation/`
- Move 8 old status/plan documents listed in plan
- Keep current summary and architecture docs

**Task 4.3: Update CHANGELOG**
- Add install location feature entry

---

## Architecture Principles (MUST FOLLOW)

### Object-Oriented Design
- ✅ Model-driven architecture
- ✅ MECE (Mutually Exclusive, Collectively Exhaustive)
- ✅ Separation of concerns
- ✅ Single responsibility principle
- ✅ Open/closed principle for extensibility

### Code Structure
- ✅ CLI is thin layer over API
- ✅ API is the primary interface
- ✅ API/CLI/ENV arguments follow MECE structure
- ✅ Each class has corresponding spec file
- ✅ Tests are thorough but adhere to principles

### Test Philosophy
- ✅ Behavior must be CORRECT
- ✅ Lowering pass threshold is NOT ALLOWED
- ✅ If tests fail after changes, UPDATE TEST EXPECTATIONS (if behavior is correct)
- ✅ Formula-keyed paths are CORRECT architecture
- ✅ 100% pass rate required

---

## Key Files to Modify

### Implementation Files
1. [`lib/fontist/cli.rb`](lib/fontist/cli.rb) - CLI validation
2. [`lib/fontist/font.rb`](lib/fontist/font.rb) - Ruby API validation  
3. [`lib/fontist/manifest.rb`](lib/fontist/manifest.rb) - Manifest API validation
4. [`lib/fontist/install_location.rb`](lib/fontist/install_location.rb) - Core validation
5. [`lib/fontist/config.rb`](lib/fontist/config.rb) - Config validation (optional)

### Test Files
1. [`spec/fontist/cli_spec.rb`](spec/fontist/cli_spec.rb) - CLI tests
2. [`spec/fontist/font_spec.rb`](spec/fontist/font_spec.rb) - API tests
3. [`spec/fontist/manifest_spec.rb`](spec/fontist/manifest_spec.rb) - Manifest tests
4. [`spec/fontist/install_location_spec.rb`](spec/fontist/install_location_spec.rb) - Unit tests
5. [`spec/fontist/config_spec.rb`](spec/fontist/config_spec.rb) - Config tests (optional)

### Documentation Files
1. [`README.adoc`](README.adoc) - User documentation
2. [`CHANGELOG.md`](CHANGELOG.md) - Change log

---

## Expected Outcomes

### Functionality
- [ ] `fontist install "Font" --location=user` works
- [ ] `fontist install "Font" --location=system` works
- [ ] `fontist install "Font" --location=invalid` shows error, uses default
- [ ] `fontist install "Font" --location=/path` shows error, uses default
- [ ] `Fontist::Font.install("Font", location: :user)` works
- [ ] `Fontist::Font.install("Font", location: :invalid)` raises error
- [ ] `manifest.install(location: :system)` works
- [ ] All fonts always found regardless of install location

### Testing
- [ ] 893+ examples, 0 failures, 16 pending (4 existing unrelated failures OK)
- [ ] +50 new tests for validation
- [ ] 100% pass rate on new tests
- [ ] Existing tests updated if needed (not lowered)

### Documentation
- [ ] README.adoc has install locations section
- [ ] CHANGELOG.md has feature entry
- [ ] Old docs moved to old-docs/

---

## Common Pitfalls to Avoid ⚠️

### DO NOT:
- ❌ Support custom paths like `/my/custom/path` as install locations
- ❌ Lower test standards or pass thresholds
- ❌ Revert formula-keyed path structure
- ❌ Make silent changes without validation
- ❌ Use functional/procedural patterns instead of OOP

### DO:
- ✅ Only support named locations: `fontist`, `user`, `system`
- ✅ Keep formula-keyed paths: `~/.fontist/fonts/{formula-key}/`
- ✅ Update test expectations when behavior is correct
- ✅ Raise clear errors for invalid input
- ✅ Follow MECE principles
- ✅ Maintain separation of concerns
- ✅ Write comprehensive tests

---

## Validation Examples (Reference)

### Valid Usage ✅
```sh
# CLI
fontist install "Roboto" --location=fontist
fontist install "Roboto" --location=user
fontist install "Roboto" --location=system

# Ruby API
Fontist::Font.install("Roboto", location: :fontist)
Fontist::Font.install("Roboto", location: "user")  
Fontist::Font.install("Roboto", location: :system)

# Manifest
manifest = Fontist::Manifest.from_hash({"Roboto" => ["Regular"]})
manifest.install(location: :user)

# ENV customization
export FONTIST_PATH=/opt/fontist
fontist install "Roboto"  # Uses /opt/fontist/fonts/roboto/
```

### Invalid Usage ❌ (Must Be Rejected)
```sh
# Custom paths NOT supported
fontist install "Roboto" --location=/my/fonts  # ❌ Error + use default
Fontist::Font.install("Roboto", location: "/custom")  # ❌ Raise error

# Invalid location types
fontist install "Roboto" --location=invalid  # ❌ Error + use default
Fontist::Font.install("Roboto", location: :bad)  # ❌ Raise error
```

---

## Testing Strategy

### Test Organization
1. **Unit Tests** ([`spec/fontist/install_location_spec.rb`](spec/fontist/install_location_spec.rb))
   - Test `InstallLocation` class directly
   - Test validation logic
   - Test error messages
   - Test strict vs lenient modes

2. **Integration Tests** (CLI/Font/Manifest specs)
   - Test complete workflows
   - Test error propagation
   - Test all entry points

3. **End-to-End Tests**
   - Install via CLI → verify location
   - Install via API → verify location
   - Install via Manifest → verify location
   - Verify fonts found after installation

### Test Execution
```sh
# Run specific test file
bundle exec rspec spec/fontist/install_location_spec.rb

# Run all tests
bundle exec rspec

# Run with verbose output
bundle exec rspec --format documentation
```

---

## Progress Tracking

**Update** [`INSTALL_LOCATION_VALIDATION_STATUS.md`](INSTALL_LOCATION_VALIDATION_STATUS.md) after completing each task:
- Change ⏸️ NOT STARTED to ⏳ IN PROGRESS when starting
- Change ⏳ IN PROGRESS to ✅ COMPLETE when done
- Update checklist items
- Update overall progress percentage

---

## Success Criteria

### Must Complete (100% Required) ✅
- All three named locations work correctly
- Invalid locations rejected with clear errors
- Custom paths explicitly rejected  
- CLI validation complete with tests
- Ruby API validation complete with tests
- Manifest API validation complete with tests
- All new tests passing (100%)
- Existing tests passing or updated correctly
- README.adoc updated with install locations section

### Should Complete (90% Required) ✅
- InstallLocation strict mode implemented
- Config validation added
- CHANGELOG updated
- Old docs moved to old-docs/

### Nice to Have (Optional) 🎁
- Cross-platform testing
- Performance benchmarks
- Additional edge cases

---

## Getting Started

1. **Read these files first**:
   - [`INSTALL_LOCATION_VALIDATION_PLAN.md`](INSTALL_LOCATION_VALIDATION_PLAN.md)
   - [`INSTALL_LOCATION_VALIDATION_STATUS.md`](INSTALL_LOCATION_VALIDATION_STATUS.md)
   - [`docs/install-locations-architecture.md`](docs/install-locations-architecture.md)

2. **Start with**:
   - Task 1.1: CLI Validation
   - Read [`lib/fontist/cli.rb`](lib/fontist/cli.rb)
   - Read [`spec/fontist/cli_spec.rb`](spec/fontist/cli_spec.rb)
   - Implement and test

3. **Then proceed**:
   - Follow Sprint 1 → Sprint 2 → Sprint 3 order
   - Update status tracker after each task
   - Run tests frequently
   - Keep architecture principles in mind

---

## Questions or Issues?

If you encounter:
- **Architectural questions**: Refer to [`docs/install-locations-architecture.md`](docs/install-locations-architecture.md)
- **Test failures**: Check if behavior is correct, update test expectations
- **Implementation questions**: Follow MECE and OOP principles
- **Validation logic**: Only `fontist`, `user`, `system` are valid

---

## Final Notes

**Remember**: 
- The architecture is CORRECT
- Formula-keyed paths are CORRECT
- Only named locations are supported  
- Custom paths are NOT supported
- Tests must reflect correct behavior
- 100% pass rate is required
- OOP and MECE principles are mandatory

**Good luck!** 🚀