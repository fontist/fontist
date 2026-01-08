# Install Location OOP - Continuation Plan
**Created:** 2026-01-07 17:33 UTC+8
**Status:** 14 failures remaining (50% reduction achieved)
**Target:** Complete all remaining work in 3-4 hours

---

## 🎯 Current State

### Test Results
- **Total Examples:** 1,035
- **Failures:** 14 (down from 28)
- **Pending:** 18
- **Pass Rate:** 98.6%

### Completed Work
✅ Test isolation infrastructure (ENV stubbing for user/system paths)
✅ OOP architecture (7 classes, 1,680+ lines)
✅ 149 new tests (100% passing)
✅ 50% of original failures fixed

### Critical Infrastructure in Place
- `spec/spec_helper.rb` - Comprehensive after(:each) cleanup
- `spec/support/fontist_helper.rb` - ENV stubbing for paths
- `spec/support/fresh_home.rb` - Shared context with isolation

---

## 📊 Remaining Failures (14 total)

### Category A: font_spec.rb (4 failures)
```
rspec ./spec/fontist/font_spec.rb:292  # existing font paths
rspec ./spec/fontist/font_spec.rb:926  # uninstall removes font
rspec ./spec/fontist/font_spec.rb:956  # uninstall partial
rspec ./spec/fontist/font_spec.rb:973  # uninstall preferred family
```

**Root Cause:** Fonts not found in FontistIndex after `example_font()` call

### Category B: cli_spec.rb (9 failures)
```
rspec ./spec/fontist/cli_spec.rb:60   # index corruption
rspec ./spec/fontist/cli_spec.rb:461  # status not installed
rspec ./spec/fontist/cli_spec.rb:647  # manifest location regular
rspec ./spec/fontist/cli_spec.rb:668  # manifest location bold
rspec ./spec/fontist/cli_spec.rb:696  # manifest location two fonts
rspec ./spec/fontist/cli_spec.rb:752  # manifest location not installed
rspec ./spec/fontist/cli_spec.rb:920  # manifest install two fonts
rspec ./spec/fontist/cli_spec.rb:953  # manifest install no style
rspec ./spec/fontist/cli_spec.rb:976  # manifest install by name
```

**Root Cause:** Same as Category A - index state issues

### Category C: system_index_font_collection_spec.rb (1 failure)
```
rspec ./spec/fontist/system_index_font_collection_spec.rb:6  # round-trip
```

**Root Cause:** Missing temp file creation

---

## 🔬 Debugging Strategy

### Step 1: Understand Index State (30 min)
Run diagnostic test to see what's happening:

```ruby
# Add to failing test
it "uninstall test" do
  fresh_fonts_and_formulas do
    example_formula("overpass.yml")
    example_font("overpass-regular.otf")

    # DIAGNOSTIC OUTPUT
    puts "Font path: #{Fontist.fonts_path}"
    puts "Font files: #{Dir.glob(Fontist.fonts_path.join('**', '*')).join(', ')}"
    puts "Index path: #{Fontist.fontist_index_path}"
    puts "Index exists: #{File.exist?(Fontist.fontist_index_path)}"

    index = Fontist::Indexes::FontistIndex.instance
    fonts = index.find("overpass", nil)
    puts "Fonts in index: #{fonts.inspect}"

    # Original test
    Fontist::Font.uninstall("overpass")
  end
end
```

**Expected findings:**
- Fonts ARE copied to temp directory
- Index file IS created
- BUT fonts not appearing in index results

**Likely issues:**
1. Path structure mismatch (flat vs formula-keyed)
2. Index caching old paths
3. Rebuild not completing before query

### Step 2: Fix Path Structure (1 hour)
Based on diagnostic output, fix one of these:

**Option A:** If paths don't match
```ruby
# In fontist_helper.rb
def example_font(filename)
  # Determine if we need formula-keyed structure
  formula_key = determine_formula_key_from_filename(filename)
  if formula_key
    target_dir = Fontist.fonts_path.join(formula_key)
    FileUtils.mkdir_p(target_dir)
    example_font_to(filename, target_dir)
  else
    example_font_to(filename, Fontist.fonts_path)
  end

  # Force synchronous rebuild
  Fontist::Indexes::FontistIndex.instance.rebuild(verbose: false)
end
```

**Option B:** If index not updating
```ruby
# Force complete reset
def example_font(filename)
  example_font_to(filename, Fontist.fonts_path)

  # Reset singleton completely
  Fontist::Indexes::FontistIndex.instance_variable_set(:@instance, nil)
  # Rebuild from scratch
  Fontist::Indexes::FontistIndex.instance.rebuild
end
```

**Option C:** If timing issue
```ruby
# Add explicit wait
def example_font(filename)
  example_font_to(filename, Fontist.fonts_path)
  Fontist::Indexes::FontistIndex.instance.rebuild

  # Wait for file to be written
  index_path = Fontist.fontist_index_path
  sleep 0.1 until File.exist?(index_path) && File.size(index_path) > 0
end
```

### Step 3: Apply Fix to All Helpers (30 min)
Once pattern is identified, apply to:
- `example_font()`
- `example_font_to_system()`
- `example_font_to_fontist()`

### Step 4: Fix system_index_font_collection_spec.rb (15 min)
```ruby
it "round-trips system index file" do
  Dir.mktmpdir do |dir|
    filename = File.join(dir, "system_index.default_family.yml")

    # Ensure directory exists
    FileUtils.mkdir_p(dir)

    # Create index
    index = Fontist::SystemIndexFontCollection.new
    # ... rest of test
  end
end
```

---

## 📝 Documentation Updates (3-4 hours)

### Phase 1: README.adoc (2-3 hours)

Add comprehensive section after "Installation":

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

* **macOS:** `/Library/Fonts/fontist/`
* **Linux:** `/usr/local/share/fonts/fontist/`
* **Windows:** `%windir%\Fonts\fontist\`

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

# Via environment
ENV["FONTIST_INSTALL_LOCATION"] = "user"
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
* User location: `~/Library/Fonts/fontist/`

==== Linux

* Integrates with fontconfig
* User location: `~/.local/share/fonts/fontist/`
* System location: `/usr/local/share/fonts/fontist/`

==== Windows

* User location: `%LOCALAPPDATA%\Microsoft\Windows\Fonts\fontist\`
* System location: `%windir%\Fonts\fontist\`
* Requires admin for system installation
----
```

### Phase 2: CHANGELOG.md (30 min)

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
  - Environment variable support: `FONTIST_INSTALL_LOCATION`, `FONTIST_USER_FONTS_PATH`, `FONTIST_SYSTEM_FONTS_PATH`

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

- 7 new OOP location classes
- 3 new singleton index classes
- Factory pattern for location creation
- MECE separation of concerns
- 149 new comprehensive tests
```

### Phase 3: Cleanup (30 min)

Move to `old-docs/`:
```bash
mv INSTALL_LOCATION_OOP_*.md old-docs/
mv TEST_ISOLATION_*.md old-docs/
mv AGGRESSIVE_*.md old-docs/
mv CONTINUATION_PROMPT_*.md old-docs/
mv FONTISAN_*.md old-docs/
mv MACOS_*.md old-docs/
mv IMPORT_*.md old-docs/
```

Keep:
```
docs/install-location-oop-architecture.md  # Architecture reference
README.adoc                                # Main docs
CHANGELOG.md                               # Version history
```

---

## ⏱️ Compressed Timeline

### Session 1: Fix Tests (2-3 hours)
1. **Diagnostic** (30min) - Understand index state
2. **Fix Pattern** (1h) - Identify and fix root cause
3. **Apply Fix** (30min) - Update all helpers
4. **Verify** (30min) - Run full test suite
5. **Fix Stragglers** (30min) - Handle any edge cases

**Milestone:** 1,035 examples, 0 failures ✅

### Session 2: Documentation (3-4 hours)
1. **README.adoc** (2-3h) - Add location documentation
2. **CHANGELOG.md** (30min) - Version 2.1.0 entry
3. **Cleanup** (30min) - Move old docs
4. **Validation** (30min) - Test all examples
5. **Final Review** (30min) - Quality check

**Milestone:** Complete documentation ✅

### Total: 5-7 hours compressed

---

## 🎯 Success Criteria

### Must Have
- [ ] All 1,035 tests passing (0 failures)
- [ ] README.adoc with complete location documentation
- [ ] CHANGELOG.md updated for v2.1.0
- [ ] All code examples tested and working
- [ ] Old docs moved to old-docs/

### Should Have
- [ ] Manual testing completed (8 scenarios)
- [ ] Architecture docs current
- [ ] No regressions in existing features

### Nice to Have
- [ ] Performance benchmarks
- [ ] Migration guide for users
- [ ] Video walkthrough

---

## 💡 Key Principles

1. **Correctness over speed** - Don't lower thresholds
2. **OOP first** - Maintain architectural integrity
3. **MECE** - Clear separation of concerns
4. **Test everything** - Comprehensive coverage
5. **Document thoroughly** - Future-proof

---

## 🚀 Next Developer: Start Here

1. Read `INSTALL_LOCATION_OOP_CONTINUATION_STATUS.md`
2. Run diagnostic test (see Debugging Strategy above)
3. Fix root cause in `spec/support/fontist_helper.rb`
4. Verify with `bundle exec rspec --seed 1234`
5. Update documentation per plan above
6. Move old docs to `old-docs/`
7. Final validation and manual testing

**The foundation is solid. Just debug and document!**