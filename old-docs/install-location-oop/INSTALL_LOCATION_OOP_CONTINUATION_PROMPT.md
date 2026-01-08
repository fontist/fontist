# Continuation Prompt: Install Location OOP Architecture - Phase 4-7 Implementation

## Context

You are continuing work on Fontist, a Ruby font management library. The task is to complete the object-oriented architecture for install locations with index ownership, managed vs non-managed location handling, and comprehensive user messaging.

## What Has Been Completed (60%)

### Phase 1-3: Core Architecture ✅ 100% COMPLETE

**8 New Files Created (~1,350 lines):**
1. `lib/fontist/install_locations/base_location.rb` - Abstract base class with complete managed vs non-managed logic
2. `lib/fontist/install_locations/fontist_location.rb` - Fontist library location (always managed)
3. `lib/fontist/install_locations/user_location.rb` - User location (conditional managed)
4. `lib/fontist/install_locations/system_location.rb` - System location (conditional managed + macOS special handling)
5. `lib/fontist/indexes/fontist_index.rb` - Singleton index for fontist library fonts
6. `lib/fontist/indexes/user_index.rb` - Singleton index for user location fonts
7. `lib/fontist/indexes/system_index.rb` - Singleton index for system fonts
8. `INSTALL_LOCATION_OOP_IMPLEMENTATION_SUMMARY.md` - Detailed status documentation

**4 Files Modified:**
1. `lib/fontist/install_location.rb` - Refactored to factory pattern
2. `lib/fontist/font_installer.rb` - Integrated with location objects
3. `lib/fontist/system_font.rb` - Three-index search implementation
4. `lib/fontist.rb` - Added user_index_path configuration

**Key Features Implemented:**
- ✅ Managed vs non-managed location detection
- ✅ Unique filename generation (`-fontist`, `-fontist-2`, etc.)
- ✅ Educational warning messages
- ✅ Factory pattern for location creation
- ✅ Three separate indexes (MECE separation)
- ✅ Platform-specific path handling
- ✅ FontInstaller integration
- ✅ SystemFont three-index search

### Phase 4: Integration ✅ 90% COMPLETE

**Remaining Task:**
- Update `lib/fontist/font.rb` uninstall method to work with all three locations

## What Needs to Be Done (40%)

### Phase 4: Complete Integration (10% remaining)

#### Task 1: Update Font.uninstall ⏰ 1 hour

**File:** `lib/fontist/font.rb`

**Requirements:**
1. Search all three indexes for the font
2. Uninstall from all found locations
3. Update all relevant indexes
4. Return all uninstalled paths

**Implementation Approach:**
```ruby
def self.uninstall(name, formula_key: nil)
  # Search all three indexes
  results = []
  results += Indexes::FontistIndex.instance.find(name) || []
  results += Indexes::UserIndex.instance.find(name) || []
  results += Indexes::SystemIndex.instance.find(name) || []
  
  return { name: name, fonts: [] } if results.empty?
  
  # Uninstall from each location
  uninstalled = results.flat_map do |font|
    location = determine_location_from_path(font.path)
    location&.uninstall_font(File.basename(font.path))
  end.compact
  
  { name: name, fonts: uninstalled }
end

private

def self.determine_location_from_path(path)
  # Return appropriate location instance based on path prefix
  # Check if path starts with Fontist.fonts_path, user path, or system path
end
```

### Phase 6: Testing (0% → 100%) ⏰ 12-16 hours

**Critical:** Tests must validate correctness. Update expectations as needed, NEVER lower pass thresholds.

#### Unit Tests to Create (8 files, ~100 examples)

1. **`spec/fontist/install_locations/base_location_spec.rb`**
   - Test abstract methods raise NotImplementedError
   - Test `generate_unique_filename` sequence
   - Test `install_font` routing (managed vs non-managed)
   - Test warning message generation
   - **20 examples, 2 hours**

2. **`spec/fontist/install_locations/fontist_location_spec.rb`**
   - Test `location_type` returns `:fontist`
   - Test `base_path` includes formula key
   - Test `managed_location?` always true
   - Test index integration
   - **15 examples, 1 hour**

3. **`spec/fontist/install_locations/user_location_spec.rb`**
   - Test `location_type` returns `:user`
   - Test `base_path` with default (has /fontist)
   - Test `base_path` with custom path
   - Test `managed_location?` detection logic
   - Test platform-specific paths
   - **15 examples, 1 hour**

4. **`spec/fontist/install_locations/system_location_spec.rb`**
   - Test `location_type` returns `:system`
   - Test `requires_elevated_permissions?` returns true
   - Test permission warning message content
   - Test `managed_location?` detection
   - Test macOS supplementary font handling
   - **15 examples, 1 hour**

5. **`spec/fontist/indexes/fontist_index_spec.rb`**
   - Test singleton behavior
   - Test `find` method
   - Test `font_exists?`
   - Test `add_font` triggers rebuild
   - Test `remove_font` updates file
   - **10 examples, 45 minutes**

6. **`spec/fontist/indexes/user_index_spec.rb`**
   - Same as fontist_index_spec
   - Test with custom user paths
   - **10 examples, 45 minutes**

7. **`spec/fontist/indexes/system_index_spec.rb`**
   - Same as fontist_index_spec
   - Test with system paths
   - **10 examples, 45 minutes**

8. **`spec/fontist/install_location_integration_spec.rb`**
   - Test all 10 documented scenarios
   - Test managed location replacement
   - Test non-managed unique naming
   - Test cross-location search
   - Test warning messages
   - Test index updates
   - **25 examples, 4 hours**

#### Existing Tests to Update (~10 test files)

1. **`spec/fontist/font_installer_spec.rb`**
   - Update expectations for location object usage
   - Test nil returns for skipped fonts

2. **`spec/fontist/system_font_spec.rb`**
   - Update expectations for three-index search
   - Test combined results

3. **`spec/fontist/font_spec.rb`**
   - Update for new uninstall behavior

**Policy:** Update test expectations to match correct behavior. NEVER lower pass rate thresholds.

### Phase 7: Documentation (0% → 100%) ⏰ 6-8 hours

#### Task 7: Update README.adoc (4 hours)

**Add Sections:**

1. **Installation Locations** (after existing installation section)
   - Explain three location types
   - Document managed vs non-managed behavior
   - Show customization options

2. **Installation Scenarios** (new section)
   - Scenario 1: Install to managed location
   - Scenario 2: Duplicate in non-managed location
   - Scenario 3: Cross-location install
   - Scenario 4: Reinstall with --force
   - Include code examples for each

3. **Troubleshooting** (new section)
   - "Why did I get a duplicate font?"
   - "How to prevent duplicates?"
   - "What are managed locations?"

**See:** `INSTALL_LOCATION_OOP_CONTINUATION_PLAN.md` for detailed content

#### Task 8: Move Outdated Documentation (1 hour)

1. Create `old-docs/` directory
2. Move completed/outdated files:
   - `INSTALL_LOCATION_ARCHITECTURE_SUMMARY.md`
   - `INSTALL_LOCATION_CONTINUATION_PLAN.md`
   - `INSTALL_LOCATION_CONTINUATION_PROMPT.md`
   - `INSTALL_LOCATION_FINAL_*.md`
   - `INSTALL_LOCATION_IMPLEMENTATION_STATUS.md`
   - `INSTALL_LOCATION_REFACTORING_SUMMARY.md`
   - Keep only current docs in `docs/`

#### Task 9: Final Documentation Polish (2 hours)

- Update `docs/install-location-oop-architecture.md` with implementation notes
- Add examples to `docs/install-locations-architecture.md`
- Update `CHANGELOG.md` with new features

### Phase 8: Validation (⏰ 2-4 hours)

#### Task 10: Run Full Test Suite
```bash
bundle exec rspec
```

**Success Criteria:**
- 680+ tests total
- 99%+ pass rate
- All new features covered

#### Task 11: Manual Testing
Test all 10 scenarios manually across platforms

#### Task 12: Final Status Update
- Mark all tasks complete in `INSTALL_LOCATION_OOP_STATUS.md`
- Document any known issues

## Architecture Documentation

**Read Before Starting:**
1. [`docs/install-location-oop-architecture.md`](docs/install-location-oop-architecture.md:1) - Complete architecture design
2. [`INSTALL_LOCATION_OOP_IMPLEMENTATION_SUMMARY.md`](INSTALL_LOCATION_OOP_IMPLEMENTATION_SUMMARY.md:1) - Current status
3. [`INSTALL_LOCATION_OOP_CONTINUATION_PLAN.md`](INSTALL_LOCATION_OOP_CONTINUATION_PLAN.md:1) - Detailed tasks

**Key Files to Review:**
- [`lib/fontist/install_locations/base_location.rb`](lib/fontist/install_locations/base_location.rb:1) - Core logic
- [`lib/fontist/install_location.rb`](lib/fontist/install_location.rb:1) - Factory pattern
- [`lib/fontist/font_installer.rb`](lib/fontist/font_installer.rb:1) - Integration example

## Critical Implementation Notes

### MECE Principle
- Each location type is mutually exclusive
- Each location owns exactly one index
- No overlapping responsibilities

### Object-Oriented Design
- All file operations go through location objects
- Indexes are owned by locations (composition)
- Factory pattern for location creation
- Strategy pattern for managed vs non-managed

### Safety First
- **NEVER** replace fonts in non-managed locations
- **ALWAYS** use unique names for non-managed duplicates
- **ALWAYS** warn user about duplicates with educational messages
- **ALWAYS** show both old and new file paths

### Testing Philosophy

From project rules:

> The *correctness of architecture* and *correctness of implementation* is of
> utmost importance: even if specs and tests fail or regress, it is okay because
> we are on the right path, and a regression may mean that those tests need to
> be updated to the new and accurate expectations.

**This means:**
- Expect some existing tests to fail after changes
- Update test expectations to match new correct behavior
- Add new tests for new functionality
- Never lower pass rate thresholds to make tests pass
- Fix code or update tests, never compromise

## Success Criteria

When complete:

- [ ] Font.uninstall works with all three locations
- [ ] All unit tests created and passing (8 new files)
- [ ] All integration tests created and passing
- [ ] Existing tests updated with correct expectations
- [ ] 680+ tests passing at 99%+ rate
- [ ] README.adoc fully updated with examples
- [ ] All scenarios documented
- [ ] Troubleshooting section added
- [ ] Outdated docs moved to old-docs/
- [ ] Final validation complete

## Compressed Timeline

**Total: 5-6 days (26 hours)**

- **Day 3 (8 hours):** Font.uninstall + Unit tests
- **Day 4 (8 hours):** Integration tests + Update existing tests
- **Day 5 (6 hours):** README.adoc + Move docs
- **Day 6 (4 hours):** Validation + Manual testing

## Getting Started

1. **Switch to code mode:** Ready to implement
2. **Read architecture docs:** Understand the design
3. **Start with Font.uninstall:** Quick win (1 hour)
4. **Write unit tests:** Foundation for validation (8 hours)
5. **Integration tests:** Verify scenarios (4 hours)
6. **Update README:** User-facing documentation (4 hours)
7. **Validate:** Ensure everything works (2-4 hours)

## Questions to Consider

1. Is Font.uninstall searching all three indexes?
2. Does the uninstall determine location correctly from path?
3. Are all test scenarios covered comprehensively?
4. Do warning messages educate users effectively?
5. Is README.adoc clear for new users?
6. Are all outdated docs moved to old-docs/?

## Final Notes

- Focus on correctness over speed
- Update test expectations as needed
- NEVER lower test pass thresholds
- Document breaking changes
- Ensure MECE separation
- Follow OOP principles strictly

The architecture is solid and 60% complete. The remaining work is primarily testing and documentation. Focus on comprehensive test coverage and clear user documentation.

Good luck! 🚀