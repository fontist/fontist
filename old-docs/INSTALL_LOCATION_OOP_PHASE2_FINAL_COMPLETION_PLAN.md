# Install Location OOP Architecture - Final Completion Plan

**Date:** 2026-01-07
**Current Status:** 73% test failures eliminated, 28 remaining
**Goal:** Achieve 100% test pass rate and complete documentation
**Estimated Time:** 6-8 hours compressed

## 🎯 Current State

### Completed (80%)
✅ Core OOP architecture (100%)
✅ 149 new comprehensive tests (100% passing)
✅ Test infrastructure fixed
✅ 76 of 104 test failures fixed (73% reduction)

### Remaining Work (20%)
- 28 test failures (test isolation/expectations)
- README.adoc documentation update
- Outdated docs cleanup

## 📊 Failure Analysis (28 total, seed 1234)

| File | Failures | Type | Est Time |
|------|----------|------|----------|
| `font_spec.rb` | 14 | Test isolation | 2-3h |
| `cli_spec.rb` | 9 | CLI delegation | 2h |
| `manifest_spec.rb` | 2 | License/location | 30min |
| `system_index_font_collection_spec.rb` | 1 | Missing file | 15min |
| Others | 2 | Various | 30min |

## 🔍 Root Causes Identified

### Pattern A: Test Isolation (60% of failures)
**Problem:** Tests pass individually but fail in sequence
**Root Cause:** Singletons/state not fully reset between tests
**Solution:** Add comprehensive reset hooks

### Pattern B: License Prompts (20% of failures)
**Problem:** Tests expect license prompt but run in non-interactive mode
**Root Cause:** `Fontist.interactive = false` not respected everywhere
**Solution:** Ensure license mocking consistent

### Pattern C: Index Search (15% of failures)
**Problem:** Tests expect "font not found" but three-index search finds it
**Root Cause:** Better architecture! (This is CORRECT behavior)
**Solution:** Update test expectations

### Pattern D: Missing Files (5% of failures)
**Problem:** Temp files not created properly
**Root Cause:** Test setup incomplete
**Solution:** Fix test helpers

## 🚀 Implementation Plan

### Phase 1: Comprehensive Test Isolation (2-3 hours)

#### Step 1.1: Enhance `fresh_fonts_and_formulas`
**File:** `spec/support/fontist_helper.rb`

Add comprehensive cleanup:
```ruby
def fresh_fonts_and_formulas
  fresh_fontist_home do
    stub_system_fonts

    FileUtils.mkdir_p(Fontist.fonts_path)
    FileUtils.mkdir_p(Fontist.formulas_path)

    yield

    # Comprehensive cleanup
    Fontist::Index.reset_cache
    Fontist::SystemIndex.reset_cache
    Fontist::SystemFont.reset_font_paths_cache
    Fontist::Config.reset  # Already added ✅
    Fontist::Indexes::FontistIndex.instance.reset_cache
    Fontist::Indexes::UserIndex.instance.reset_cache
    Fontist::Indexes::SystemIndex.instance.reset_cache

    # Reset interactive mode
    Fontist.interactive = false
  end
end
```

#### Step 1.2: Add `after(:each)` Hook
**File:** `spec/spec_helper.rb`

```ruby
RSpec.configure do |config|
  config.after(:each) do
    # Reset all Fontist state after each test
    Fontist::Test::IsolationManager.instance.reset_all rescue nil
    Fontist::Config.reset rescue nil
    Fontist.interactive = false
  end
end
```

**Expected Impact:** Fix 10-12 failures

### Phase 2: Fix Remaining font_spec.rb (14 failures, 1-2 hours)

#### Step 2.1: License Prompt Tests (lines 203, 212, 445)
**Issue:** Tests expect license prompts but interactive mode disabled

**Fix:**
```ruby
# Before
it "raises error for missing license agreement" do
  example_formula("andale.yml")
  stub_license_agreement_prompt_with("no")

  expect { Fontist::Font.install("andale mono") }.to raise_error(
    Fontist::Errors::LicensingError,
  )
end

# After - Ensure interactive mode enabled
it "raises error for missing license agreement" do
  example_formula("andale.yml")
  Fontist.interactive = true  # Enable interactive
  stub_license_agreement_prompt_with("no")

  expect { Fontist::Font.install("andale mono") }.to raise_error(
    Fontist::Errors::LicensingError,
  )
end
```

#### Step 2.2: Uninstall Tests (lines 911, 926, 956, 973)
**Issue:** Fonts found in indexes when expected missing

**Fix:** Ensure formulas/fonts properly set up
```ruby
it "removes font" do
  fresh_fonts_and_formulas do
    example_formula("overpass.yml")  # Already has this ✅
    example_font("overpass-regular.otf")  # Already has this ✅

    # Verify font is in index before uninstall
    expect(Fontist::Font.status("overpass")).not_to be_empty

    Fontist::Font.uninstall("overpass")
    expect(font_file("overpass-regular.otf")).not_to exist
  end
end
```

#### Step 2.3: Other Tests
Check each individually and apply appropriate pattern

**Expected Impact:** 14 failures → 0

### Phase 3: Fix cli_spec.rb (9 failures, 2 hours)

**Pattern:** CLI delegates to Font/Manifest, so if those work, CLI should work

#### Step 3.1: Diagnose Each Failure
```bash
bundle exec rspec spec/fontist/cli_spec.rb:60 --seed 1234 -fd
bundle exec rspec spec/fontist/cli_spec.rb:668 --seed 1234 -fd
# etc.
```

#### Step 3.2: Common Fixes

**A. Status Commands:**
```ruby
# OLD expectation
expect { cli.status("arial") }.to raise_error

# NEW expectation (font IS found via three indexes)
example_formula("webcore.yml")
example_font("ariali.ttf")
expect { cli.status("arial") }.to output(/Fonts found/).to_stdout
```

**B. Manifest Commands:**
```ruby
# Ensure proper formula/font setup
example_formula("courier.yml")
expect { cli.manifest_install(manifest_path) }.not_to raise_error
```

**Expected Impact:** 9 failures → 0

### Phase 4: Fix manifest_spec.rb (2 failures, 30 min)

Similar patterns to font_spec.rb:
- License confirmation
- Location parameter
- Apply same fixes

**Expected Impact:** 2 failures → 0

### Phase 5: Fix system_index_font_collection_spec.rb (1 failure, 15 min)

**Issue:** Missing temp file

**Fix:**
```ruby
it "round-trips system index file" do
  Dir.mktmpdir do |dir|
    filename = File.join(dir, "system_index.default_family.yml")

    # Ensure directory exists
    FileUtils.mkdir_p(dir)

    # Create initial index
    index = Fontist::SystemIndexFontCollection.new
    # ... rest of test
  end
end
```

**Expected Impact:** 1 failure → 0

### Phase 6: Fix Remaining (2 failures, 30 min)

Handle individually based on error messages

**Expected Impact:** 2 failures → 0

### Phase 7: Documentation (4-5 hours)

#### Step 7.1: Update README.adoc (3-4 hours)

**Add new section after "Installation":**

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

* **macOS:** `~/Library/Fonts`
* **Linux:** `~/.local/share/fonts`
* **Windows:** `%LOCALAPPDATA%\Microsoft\Windows\Fonts`

[source,shell]
----
fontist install "Roboto" --location user
----

**Advantages:**
* Available to all user applications
* Follows OS conventions
* No admin privileges required

==== System Location
Fonts are installed in the system font directory:

* **macOS:** `/System/Library/Fonts` or `/Library/Fonts/Supplementary` (macOS fonts)
* **Linux:** `/usr/local/share/fonts`
* **Windows:** `%windir%\Fonts`

[source,shell]
----
fontist install "Roboto" --location system
----

**Advantages:**
* Available to all users
* System-wide integration

**Warning:** ⚠️ Requires administrator/root privileges

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
fontist config set user_fonts_path /my/custom/fonts
----

Override system font path:
[source,shell]
----
fontist config set system_fonts_path /custom/system/fonts
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
Fontist::Config.set_fonts_install_location(:user)
----

==== Custom Paths

[source,ruby]
----
# Via config
Fontist::Config.set(:user_fonts_path, "/my/fonts")

# Via environment
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
* Supports macOS supplementary fonts (downloadable via Font Book)
* System location varies by font type (regular vs supplementary)
* User location: `~/Library/Fonts`

==== Linux
* Integrates with fontconfig
* User location: `~/.local/share/fonts`
* System location: `/usr/local/share/fonts`

==== Windows
* User location: `%LOCALAPPDATA%\Microsoft\Windows\Fonts`
* System location: `%windir%\Fonts`
* Requires admin for system installation
----
```

#### Step 7.2: Update CHANGELOG.md (30 min)

Add comprehensive entry for v2.1.0 (or next version):

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
  - Fontist index for managed fonts
  - User index for user-installed fonts
  - System index for system fonts
  - Combined search for comprehensive font finding

- **Configuration Options:**
  - `fonts_install_location`: Set default install location
  - `user_fonts_path`: Custom user font directory
  - `system_fonts_path`: Custom system font directory

### Changed

- Font installation now uses formula-keyed directory structure (e.g., `~/.fontist/fonts/roboto/`)
- `Font.find` now searches all three locations (fontist, user, system)
- `Font.status` now reports fonts from all locations
- Improved test isolation with comprehensive cache resets

### Deprecated

- None

### Fixed

- Test isolation issues with Config singleton
- Index rebuild timing in test helpers
- Platform-specific path handling edge cases

### Security

- Enhanced permission checking for system location installs
- Clear warnings when elevated privileges required
```

#### Step 7.3: Move Outdated Docs (30 min)

Move to `old-docs/`:
```bash
mv INSTALL_LOCATION_*.md old-docs/
mv TEST_ISOLATION_*.md old-docs/
```

Keep:
- `docs/install-location-oop-architecture.md` (architecture reference)
- `docs/readme-install-locations-section.adoc` (can be deleted after incorporated)

### Phase 8: Final Validation (1 hour)

#### Step 8.1: Full Test Suite
```bash
bundle exec rspec
# Expected: 1035 examples, 0 failures ✅
```

#### Step 8.2: Manual Testing

Test each location type:
```bash
# Fontist location
fontist install "Roboto"
fontist status "Roboto"
fontist uninstall "Roboto"

# User location
fontist install "Roboto" --location user
ls ~/Library/Fonts/Roboto*.ttf  # macOS
fontist uninstall "Roboto"

# Config default
fontist config set fonts_install_location user
fontist install "Open Sans"
fontist status "Open Sans"
```

#### Step 8.3: Documentation Verification

Test all code examples in README.adoc

## ⏱️ Time Estimates

| Phase | Task | Time |
|-------|------|------|
| 1 | Test isolation | 2-3h |
| 2 | font_spec.rb | 1-2h |
| 3 | cli_spec.rb | 2h |
| 4 | manifest_spec.rb | 30min |
| 5 | system_index_font_collection_spec.rb | 15min |
| 6 | Others | 30min |
| 7 | Documentation | 4-5h |
| 8 | Validation | 1h |
| **Total** | | **11-14h** |

**Compressed:** Can complete in 6-8 hours with focus

## 🎯 Success Criteria

### Must Have
- [ ] 1,035 tests passing (0 failures) ✅
- [ ] README.adoc complete with location documentation
- [ ] CHANGELOG.md updated
- [ ] All manual test scenarios pass

### Should Have
- [ ] All old docs moved to old-docs/
- [ ] Architecture docs current
- [ ] Code examples tested

### Nice to Have
- [ ] Performance benchmarks
- [ ] Migration guide for users
- [ ] Video walkthrough

## 🚦 Progress Tracking

Update this section as work progresses:

- [ ] Phase 1: Test isolation
- [ ] Phase 2: font_spec.rb fixes
- [ ] Phase 3: cli_spec.rb fixes
- [ ] Phase 4: manifest_spec.rb fixes
- [ ] Phase 5: system_index_font_collection_spec.rb fix
- [ ] Phase 6: Remaining fixes
- [ ] Phase 7: Documentation
- [ ] Phase 8: Validation

## 📋 Checklist Before Completion

- [ ] All tests passing (1,035 examples, 0 failures)
- [ ] README.adoc updated
- [ ] CHANGELOG.md updated
- [ ] Old docs moved
- [ ] Manual testing complete
- [ ] No regressions introduced
- [ ] Code quality maintained
- [ ] Ready for production release

---

**Last Updated:** 2026-01-07
**Next Review:** After Phase 1 completion