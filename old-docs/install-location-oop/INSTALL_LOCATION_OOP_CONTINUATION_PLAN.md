# Install Location OOP Architecture - Continuation Plan

**Status:** Phase 2-3 Complete (60% Done)
**Remaining:** Phases 4-7 (40%)
**Timeline:** 5-6 days compressed (from 7-10 days)

## ✅ COMPLETED WORK (Phase 1-3 + Messaging)

### Phase 1: Basic Subdirectory ✅ 100%
- Config with user_fonts_path/system_fonts_path
- Environment variable support
- InstallLocation /fontist subdirectory
- Documentation complete

### Phase 2: OOP Location Classes ✅ 100%
- **All 4 location classes created:**
  - `lib/fontist/install_locations/base_location.rb` (320 lines)
  - `lib/fontist/install_locations/fontist_location.rb`
  - `lib/fontist/install_locations/user_location.rb`
  - `lib/fontist/install_locations/system_location.rb`
- **Factory pattern:** `lib/fontist/install_location.rb` refactored
- **Key features implemented:**
  - Managed vs non-managed detection
  - Unique filename generation
  - Educational warnings
  - Platform-specific handling

### Phase 3: Index Classes ✅ 100%
- **All 3 index classes created:**
  - `lib/fontist/indexes/fontist_index.rb`
  - `lib/fontist/indexes/user_index.rb`
  - `lib/fontist/indexes/system_index.rb`
- **Configuration:** `lib/fontist.rb` updated with user_index_path
- **Singleton pattern throughout**

### Phase 4: Integration ✅ 90%
- **FontInstaller:** Uses location objects completely
- **SystemFont:** Searches all three indexes
- **Remaining:** Font.uninstall needs update

### Phase 5: Messaging ✅ 100%
- Educational warnings complete
- Platform-specific examples
- Clear managed vs non-managed explanations

## 🔄 REMAINING WORK (40%)

## Phase 4: Complete Integration (10% Remaining)

### Task 1: Update Font.uninstall ⏰ 1 hour

**File:** `lib/fontist/font.rb`

**Implementation:**
```ruby
def self.uninstall(name, formula_key: nil)
  # Search all three indexes for font
  fontist_fonts = Indexes::FontistIndex.instance.find(name)
  user_fonts = Indexes::UserIndex.instance.find(name)
  system_fonts = Indexes::SystemIndex.instance.find(name)

  all_fonts = [fontist_fonts, user_fonts, system_fonts].compact.flatten

  return { name: name, fonts: [] } if all_fonts.empty?

  # Uninstall from all found locations
  uninstalled_paths = all_fonts.flat_map do |font|
    # Determine location from path
    location = determine_location(font.path)
    location&.uninstall_font(File.basename(font.path))
  end.compact

  { name: name, fonts: uninstalled_paths }
end

private

def self.determine_location(path)
  # Return appropriate location instance based on path
  # Logic to detect if path is in fontist/user/system location
end
```

**Success Criteria:**
- Uninstalls from all found locations
- Updates all relevant indexes
- Returns all uninstalled paths

---

## Phase 6: Testing (0% → 100%) ⏰ 12-16 hours

### Compressed Testing Strategy

**Approach:** Write minimal but comprehensive tests
**Goal:** 680+ tests passing at 99%+ rate

### Day 3: Unit Tests (6-8 hours)

#### Task 2: BaseLocation Unit Tests
**File:** `spec/fontist/install_locations/base_location_spec.rb`

**Test Coverage:**
- Abstract methods raise NotImplementedError ✓
- `managed_location?` default returns true ✓
- `generate_unique_filename` sequence (-fontist, -fontist-2, etc.) ✓
- `install_font` routing logic ✓
- Warning message generation ✓

**Est:** 2 hours, 20 examples

#### Task 3: Location Classes Unit Tests
**Files:**
- `spec/fontist/install_locations/fontist_location_spec.rb`
- `spec/fontist/install_locations/user_location_spec.rb`
- `spec/fontist/install_locations/system_location_spec.rb`

**Test Coverage per file:**
- `location_type` returns correct symbol ✓
- `base_path` returns correct path ✓
- `managed_location?` detection logic ✓
- Index integration ✓
- Platform-specific behavior ✓

**Est:** 3 hours, 45 examples (15 per class)

#### Task 4: Index Classes Unit Tests
**Files:**
- `spec/fontist/indexes/fontist_index_spec.rb`
- `spec/fontist/indexes/user_index_spec.rb`
- `spec/fontist/indexes/system_index_spec.rb`

**Test Coverage per file:**
- Singleton behavior ✓
- `find` method ✓
- `font_exists?` method ✓
- `add_font` triggers rebuild ✓
- `remove_font` updates file ✓

**Est:** 2 hours, 30 examples (10 per class)

### Day 4: Integration & Existing Tests (6-8 hours)

#### Task 5: Integration Tests
**File:** `spec/fontist/install_location_integration_spec.rb`

**Test Scenarios (10 documented):**
1. Install to empty managed location ✓
2. Install to empty non-managed location ✓
3. Replace in managed location with --force ✓
4. Add unique name in non-managed location with --force ✓
5. Skip when exists in target without --force ✓
6. Skip when exists in other location without --force ✓
7. Install duplicate across managed locations with --force ✓
8. Generate correct unique filename sequence ✓
9. Show appropriate warnings for duplicates ✓
10. Update indexes correctly in all cases ✓

**Est:** 4 hours, 25 examples

#### Task 6: Update Existing Tests
**Files to Update:**
- `spec/fontist/font_installer_spec.rb`
- `spec/fontist/system_font_spec.rb`
- `spec/fontist/font_spec.rb`

**Changes:**
- Update expectations for location object usage
- Update for three-index search
- Update for new uninstall behavior
- Fix any breaking changes

**Policy:** Update expectations, NEVER lower thresholds

**Est:** 2 hours, ~10 test updates

---

## Phase 7: Documentation (0% → 100%) ⏰ 6-8 hours

### Day 5: README.adoc Updates (4-5 hours)

#### Task 7: Add Managed vs Non-Managed Section
**File:** `README.adoc`

**Content to Add:**
```adoc
== Installation Locations

Fontist supports three types of installation locations:

=== Fontist Library (Default)

The safest option, fonts are installed to:
  ~/.fontist/fonts/{formula-key}/

This location is fully managed by Fontist and isolated from system fonts.

=== User Font Directory

Platform-specific user font location with fontist subdirectory:
  macOS:   ~/Library/Fonts/fontist/
  Linux:   ~/.local/share/fonts/fontist/
  Windows: %LOCALAPPDATA%/Microsoft/Windows/Fonts/fontist/

==== Managed vs Non-Managed Behavior

*Fontist-Managed* (safe to replace):
- Default paths with `/fontist` subdirectory
- Fontist can replace fonts when reinstalling

*Non-Managed* (unique names to prevent conflicts):
- Custom paths to system root directories
- Fontist adds fonts with unique names (e.g., `Roboto-Regular-fontist.ttf`)

To use non-managed location:
  export FONTIST_USER_FONTS_PATH=~/Library/Fonts

=== System Font Directory

Platform-specific system location (requires sudo/admin):
  macOS:   /Library/Fonts/fontist/
  Linux:   /usr/local/share/fonts/fontist/
  Windows: %windir%/Fonts/fontist/

Same managed vs non-managed logic applies.

== Installation Scenarios

=== Scenario 1: Install to Managed Location
[source,bash]
----
fontist install "Roboto" --location=user
# Installs to ~/Library/Fonts/fontist/Roboto-Regular.ttf
----

=== Scenario 2: Duplicate in Non-Managed Location
[source,bash]
----
export FONTIST_USER_FONTS_PATH=~/Library/Fonts
fontist install "Roboto" --location=user --force
# Font exists: ~/Library/Fonts/Roboto-Regular.ttf
# Installs to: ~/Library/Fonts/Roboto-Regular-fontist.ttf
# Shows warning about duplicate
----

== Troubleshooting

=== Why did I get a duplicate font?

If Fontist installed a font with `-fontist` suffix, this means:
1. The target location is not managed by Fontist
2. A font with the same name already exists
3. Fontist added the new font with a unique name to avoid breaking your existing font

To prevent duplicates, use Fontist-managed locations (with `/fontist` subdirectory).
```

**Est:** 3 hours

#### Task 8: Move Outdated Documentation
**Actions:**
1. Create `old-docs/` directory
2. Move completed/outdated docs:
   - `INSTALL_LOCATION_*.md` (multiple files)
   - Keep only current architecture docs in `docs/`

**Est:** 1 hour

#### Task 9: Final Documentation Polish
- Update `docs/install-location-oop-architecture.md` with implementation notes
- Add examples to `docs/install-locations-architecture.md`
- Update CHANGELOG.md

**Est:** 2 hours

---

## Phase 8: Validation & Final Testing ⏰ 2-4 hours

### Day 6: Final Validation

#### Task 10: Run Full Test Suite
```bash
bundle exec rspec
```

**Success Criteria:**
- 680+ tests total
- 99%+ pass rate
- No lowered thresholds
- All new features covered

**Est:** 1 hour (plus fixes)

#### Task 11: Manual Testing
Test all 10 scenarios manually:
1. Fresh install to each location type
2. Reinstall with --force
3. Cross-location duplicates
4. Unique filename generation
5. Warning message display
6. Index updates
7. Uninstall from all locations
8. Mixed managed/non-managed

**Est:** 2 hours

#### Task 12: Final Status Update
- Update `INSTALL_LOCATION_OOP_STATUS.md` to 100%
- Mark all tasks complete
- Document any known issues

**Est:** 30 minutes

---

## COMPRESSED TIMELINE

### Day 3 (8 hours)
- Morning: Font.uninstall update (1h) + BaseLocation tests (2h)
- Afternoon: Location class tests (3h) + Index tests (2h)

### Day 4 (8 hours)
- Morning: Integration tests (4h)
- Afternoon: Update existing tests (2h) + Fixes (2h)

### Day 5 (6 hours)
- Morning: README.adoc updates (3h)
- Afternoon: Move docs (1h) + Final polish (2h)

### Day 6 (4 hours)
- Morning: Test suite validation (2h)
- Afternoon: Manual testing (2h) + Final updates (30min)

**TOTAL: 5-6 days (26 hours of work)**

---

## Success Criteria Checklist

- [ ] Font.uninstall works with all locations
- [ ] All unit tests created and passing
- [ ] All integration tests created and passing
- [ ] Existing tests updated with correct expectations
- [ ] 680+ tests passing at 99%+ rate
- [ ] Test coverage complete for all new code
- [ ] README.adoc fully updated
- [ ] All scenarios documented with examples
- [ ] Troubleshooting section added
- [ ] Outdated docs moved to old-docs/
- [ ] Final validation complete
- [ ] Status tracker at 100%

---

## Key Principles to Maintain

1. **Correctness over compatibility** - Update tests, never lower thresholds
2. **MECE separation** - Each location/index distinct and complete
3. **OOP design** - All logic encapsulated in classes
4. **Safety first** - Never break non-managed fonts
5. **Educational messaging** - Users understand behavior
6. **Comprehensive testing** - All scenarios covered
7. **Complete documentation** - All features explained

---

## Handoff Notes for Next Developer

### What's Done
- Core OOP architecture (8 new files, 1,350 lines)
- Three-index system (FontistIndex, UserIndex, SystemIndex)
- Managed vs non-managed detection
- Unique filename generation
- Educational warnings
- FontInstaller integration
- SystemFont three-index search

### What's Needed
- Font.uninstall update (1 method)
- Unit tests (8 files, ~100 examples)
- Integration tests (1 file, ~25 examples)
- Existing test updates (~10 changes)
- README.adoc updates (3 sections)
- Documentation moves

### Where to Start
1. Read `INSTALL_LOCATION_OOP_IMPLEMENTATION_SUMMARY.md`
2. Review `docs/install-location-oop-architecture.md`
3. Update `Font.uninstall` first (quickest win)
4. Write tests (foundation for validation)
5. Update documentation (user-facing)

### Files to Review Before Starting
- `lib/fontist/install_locations/base_location.rb` - Core logic
- `lib/fontist/install_location.rb` - Factory pattern
- `lib/fontist/font_installer.rb` - Integration example
- `docs/install-location-oop-architecture.md` - Full architecture