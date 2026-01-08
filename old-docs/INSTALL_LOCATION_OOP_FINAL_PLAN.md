# Install Location OOP - Final Completion Plan

**Created:** 2026-01-07 12:46 UTC+8
**Target:** Fix all 12 remaining test failures + Complete documentation
**Estimated Time:** 6-8 hours compressed

---

## 🎯 Mission

Complete the Install Location OOP feature by:
1. Fixing ALL 12 remaining test failures (no compromises)
2. Adding comprehensive user documentation
3. Updating CHANGELOG
4. Organizing documentation files

---

## Phase 1: Fix All Test Failures (4-6 hours)

### Step 1.1: Fix Integration Test (1-2 hours)

**File:** `spec/fontist/font_spec.rb:292`
**Test:** "with existing font name returns the existing font paths"

**Current Behavior:**
```ruby
font = "Courier New"
Fontist::Font.install(font, confirmation: "yes")  # Installs 4 styles
font_paths = Fontist::Font.install(font, confirmation: "yes")
expect(font_paths.count).to be > 3  # FAILS: gets 1, expects 4+
```

**Diagnostic Steps:**
1. Check what `SystemFont.find("Courier New")` returns after installation
2. Verify if Font.install returns early when fonts exist
3. Check if Font.install should return ALL family styles or just requested style

**Possible Solutions:**

**Option A:** SystemFont.find needs to return all family styles
```ruby
# In lib/fontist/system_font.rb
def self.find_styles(font_name, style = nil)
  # If no style specified, return ALL styles in family
  results = []
  results += Indexes::FontistIndex.instance.find(font_name, style) || []
  results += Indexes::UserIndex.instance.find(font_name, style) || []
  results += Indexes::SystemIndex.instance.find(font_name, style) || []

  # If style is nil, get all styles for this font family
  if style.nil? && results.any?
    font_family = results.first.family_name
    # Get all styles for this family...
  end

  results.empty? ? nil : results.uniq { |f| f.path }
end
```

**Option B:** Test expectation is wrong
- Courier.yml has 4 styles, but installation by font name might only install requested style
- Update test to expect count == 1 (the style that was actually requested)

**Decision Criteria:**
- Check behavior in production code
- Verify what user would expect when requesting "Courier New"
- Maintain backward compatibility

### Step 1.2: Fix Manifest Tests (2-3 hours)

**Files:** `spec/fontist/cli_spec.rb` lines 647, 668, 696, 752, 920, 953, 976

**Common Pattern:**
Most manifest tests likely fail because:
1. They don't use formula-keyed `example_font()` setup
2. Path expectations don't match formula-keyed structure
3. Manifest processing might need formula structure awareness

**Fix Strategy:**

1. **Read each failing test** to understand setup and expectation
2. **Update test setup** if using old flat structure
3. **Update assertions** for formula-keyed paths
4. **Verify manifest code** handles formula structure

**Example Fix Pattern:**
```ruby
# Before (if using old flat structure):
it "contains one font" do
  example_font("Roboto-Regular.ttf")  # Now creates formula-keyed path
  # Rest of test...
end

# After:
it "contains one font" do
  example_font("Roboto-Regular.ttf")  # Already fixed in helper
  result = Fontist::CLI.start(["manifest-locations", manifest])
  # Update path expectations if needed
  expect(result).to include("roboto/Roboto-Regular.ttf")  # formula-keyed
end
```

### Step 1.3: Fix CLI List/Status Tests (1 hour)

**Files:** `spec/fontist/cli_spec.rb` lines 541, 551, 60, 461

**Fix Approach:**
1. Run each test individually with `-fd` flag
2. Compare expected vs actual output
3. Update test assertions to match OOP architecture behavior
4. Verify exit codes match actual implementation

**Common Issues:**
- Output format changes
- Path format changes (formula-keyed)
- Exit codes might have changed

### Step 1.4: Verify All Tests Pass (30 min)

```bash
# Full suite with seed
bundle exec rspec --seed 1234

# Full suite without seed (ensure no order dependency)
bundle exec rspec

# Target: 1,035 examples, 0 failures, 18 pending
```

---

## Phase 2: Documentation (3-4 hours)

### Step 2.1: Update README.adoc (2-3 hours)

**Location:** After "Installation" section

**Content Structure:**
```adoc
== Font Installation Locations

Fontist supports three installation locations for fonts:

=== Location Types

==== Fontist Library (Default)

Fonts are installed in `~/.fontist/fonts/` organized by formula:

[source,shell]
----
fontist install "Roboto"  # Installs to ~/.fontist/fonts/roboto/
----

**Advantages:**
* Isolated from system fonts
* Easy to manage and uninstall
* Works without admin privileges
* Formula-keyed organization

==== User Location

Fonts are installed in the user's font directory:

* **macOS:** `~/Library/Fonts/fontist/`
* **Linux:** `~/.local/share/fonts/fontist/`
* **Windows:** `%LOCALAPPDATA%\Microsoft\Windows\Fonts\fontist\`

[source,shell]
----
fontist install "Roboto" --location user
----

==== System Location

Fonts are installed in the system font directory (requires admin):

* **macOS:** `/Library/Fonts/fontist/`
* **Linux:** `/usr/local/share/fonts/fontist/`
* **Windows:** `%windir%\Fonts\fontist\`

[source,shell]
----
sudo fontist install "Roboto" --location system  # Linux/macOS
fontist install "Roboto" --location system       # Windows (as admin)
----

=== Configuration

==== Set Default Location

Via config file:
[source,shell]
----
fontist config set fonts_install_location user
----

Via environment variable:
[source,shell]
----
export FONTIST_INSTALL_LOCATION=user
fontist install "Roboto"  # Installs to user location
----

==== Custom Paths

Override user font path:
[source,shell]
----
export FONTIST_USER_FONTS_PATH=/my/custom/fonts
fontist install "Roboto" --location user
----

Override system font path:
[source,shell]
----
export FONTIST_SYSTEM_FONTS_PATH=/custom/system/fonts
fontist install "Roboto" --location system
----

=== Ruby API

==== Install to Specific Location

[source,ruby]
----
require 'fontist'

# Install to fontist library (default)
Fontist::Font.install("Roboto", confirmation: "yes")

# Install to user location
Fontist::Font.install("Roboto", confirmation: "yes", location: :user)

# Install to system location (requires privileges)
Fontist::Font.install("Roboto", confirmation: "yes", location: :system)
----

==== Set Default Location

[source,ruby]
----
# Via config
Fontist::Config.set_fonts_install_location(:user)

# Via environment (before loading Fontist)
ENV["FONTIST_INSTALL_LOCATION"] = "user"
----

==== Custom Paths

[source,ruby]
----
# Via config
Fontist::Config.set(:user_fonts_path, "/my/fonts")

# Via environment (before loading Fontist)
ENV["FONTIST_USER_FONTS_PATH"] = "/my/fonts"
----

=== Font Discovery

Fontist searches for fonts in all three locations:

1. **Fontist library** (`~/.fontist/fonts/`)
2. **User fonts** (platform-specific user directory)
3. **System fonts** (platform-specific system directories)

[source,ruby]
----
# Find font in any location
paths = Fontist::Font.find("Roboto")
# Returns paths from all locations where font is installed
----

=== Platform-Specific Notes

==== macOS
* Supports macOS supplementary fonts
* User location: `~/Library/Fonts/fontist/`
* System requires admin for `/Library/Fonts/fontist/`

==== Linux
* Integrates with fontconfig
* User location: `~/.local/share/fonts/fontist/`
* System requires root for `/usr/local/share/fonts/fontist/`

==== Windows
* User location: `%LOCALAPPDATA%\Microsoft\Windows\Fonts\fontist\`
* System location: `%windir%\Fonts\fontist\`
* System requires admin privileges
----
```

### Step 2.2: Update CHANGELOG.md (30 min)

**Add entry for v2.1.0:**

```markdown
## [2.1.0] - 2026-01-XX

### Added

- **Font Installation Locations:** Complete OOP architecture for flexible font installation
  - Three location types: fontist (default), user, system
  - Per-installation location control via `--location` flag
  - Default location configuration via `fonts_install_location`
  - Custom path support for user and system locations
  - Platform-specific location handling (macOS, Linux, Windows)

- **Three-Index Font Search:** Enhanced font discovery across all locations
  - Fontist index for managed fonts (`~/.fontist/fonts/`)
  - User index for user-installed fonts
  - System index for system fonts
  - Combined search for comprehensive font finding

- **Configuration Options:**
  - `fonts_install_location`: Set default install location (:fontist, :user, :system)
  - `user_fonts_path`: Custom user font directory
  - `system_fonts_path`: Custom system font directory
  - Environment variables: `FONTIST_INSTALL_LOCATION`, `FONTIST_USER_FONTS_PATH`, `FONTIST_SYSTEM_FONTS_PATH`

### Changed

- Font installation now uses formula-keyed directory structure (e.g., `~/.fontist/fonts/roboto/`)
- `Font.find` now searches all three locations (fontist, user, system)
- `Font.status` now reports fonts from all locations
- Improved test isolation with comprehensive cache resets
- ENV-based test stubbing for user/system paths

### Fixed

- Test isolation issues with Config singleton
- Index rebuild timing in test helpers
- Platform-specific path handling edge cases
- Cross-test pollution from real directory access

### Internal

- 7 new OOP location classes (BaseLocation, FontistLocation, UserLocation, SystemLocation)
- 3 new singleton index classes (FontistIndex, UserIndex, SystemIndex)
- Factory pattern for location creation (InstallLocation.create)
- MECE separation of concerns across location and index management
- 149 new comprehensive tests for location and index functionality
```

### Step 2.3: Cleanup Documentation (30 min)

```bash
# Create old-docs directory
mkdir -p old-docs

# Move completed work documentation
mv INSTALL_LOCATION_OOP_PHASE2_*.md old-docs/
mv INSTALL_LOCATION_OOP_CONTINUATION_*.md old-docs/
mv TEST_ISOLATION_*.md old-docs/
mv AGGRESSIVE_*.md old-docs/
mv CONTINUATION_PROMPT_*.md old-docs/
mv FONTISAN_*.md old-docs/
mv IMPORT_*.md old-docs/
mv MACOS_*.md old-docs/
mv LOCATION_*.md old-docs/

# Keep current work docs
# - INSTALL_LOCATION_OOP_FINAL_STATUS.md
# - INSTALL_LOCATION_OOP_FINAL_PLAN.md
# - INSTALL_LOCATION_OOP_FINAL_PROMPT.md (to be created)
# - docs/install-location-oop-architecture.md (reference doc)
```

---

## Phase 3: Final Validation (1 hour)

### Step 3.1: Test All Code Examples (30 min)

Test each code example from README.adoc:

```bash
# CLI examples
fontist install "Roboto" --location user
fontist install "Roboto" --location system
export FONTIST_INSTALL_LOCATION=user
fontist install "Arial"

# Config examples
fontist config set fonts_install_location user
fontist config get fonts_install_location
```

### Step 3.2: Manual Testing Scenarios (30 min)

1. Install font to fontist location
2. Install same font to user location
3. Find font (should return both paths)
4. Uninstall from one location
5. Find again (should return remaining path)
6. Install with custom path
7. Verify integration

---

## Success Criteria

### Must Have ✅

- [ ] All 1,035 tests passing (0 failures)
- [ ] README.adoc has complete location documentation
- [ ] CHANGELOG.md updated for v2.1.0
- [ ] All code examples tested and working
- [ ] Old docs moved to old-docs/

### Should Have ✅

- [ ] No regressions in existing features
- [ ] Architecture docs current
- [ ] Clean git status

### Nice to Have

- [ ] Performance benchmarks
- [ ] Migration guide for users
- [ ] Video walkthrough

---

## Timeline Estimate

| Phase | Task | Time |
|-------|------|------|
| 1.1 | Fix integration test | 1-2h |
| 1.2 | Fix manifest tests | 2-3h |
| 1.3 | Fix CLI tests | 1h |
| 1.4 | Verify all pass | 30min |
| 2.1 | README.adoc | 2-3h |
| 2.2 | CHANGELOG.md | 30min |
| 2.3 | Cleanup docs | 30min |
| 3.1 | Test examples | 30min |
| 3.2 | Manual testing | 30min |
| **TOTAL** | | **8-11h** |

**Compressed:** 6-8 hours with focused work

---

## Key Principles

1. **Correctness over speed** - Fix tests properly, don't lower thresholds
2. **OOP first** - Maintain architectural integrity
3. **MECE** - Clear separation of concerns
4. **Test everything** - Comprehensive coverage
5. **Document thoroughly** - User-facing clarity

---

## Risk Mitigation

### If Integration Test is Complex
- Budget extra 1-2 hours
- May need to update SystemFont.find logic
- Document decision clearly

### If Manifest Tests Have Deep Issues
- Might indicate manifest code needs updating
- Budget extra time for code fixes
- Ensure backward compatibility

### If Behind Schedule
- Prioritize test fixes over documentation polish
- Can refine documentation in follow-up
- But never compromise on test correctness

---

**Next Developer:** Start with Phase 1.1, fix tests systematically, then proceed to documentation. No shortcuts!