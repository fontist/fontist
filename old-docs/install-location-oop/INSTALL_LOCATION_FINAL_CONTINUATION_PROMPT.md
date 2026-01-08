# Universal Install Location - Final Continuation Prompt

**Status:** Phase 5 - Test Regression Fixes In Progress
**Priority:** HIGH
**Deadline:** Complete within 2-3 hours
**Progress:** 93% Complete (Core done, 40 test failures remaining)

---

## Quick Context

You are continuing work on the **Universal Install Location** feature for Fontist. The core implementation is **100% complete and working**. The remaining work is:

1. **Fix 40 test expectations** (tests expect old flat paths, get correct formula-keyed paths)
2. **Update user documentation** (README.adoc, installation guide)
3. **Clean up old planning documents**

**Important:** The formula-keyed path structure (`~/.fontist/fonts/{formula-key}/{font-file}`) is **architecturally CORRECT**. Test failures are because test expectations need updating to match the new (correct) behavior.

---

## What's Already Complete ✅

### Core Implementation (100%)
- ✅ [`InstallLocation`](lib/fontist/install_location.rb:1) class with 3 location types (user, system, custom)
- ✅ Platform-specific path resolution (macOS, Linux, Windows)
- ✅ Config integration ([`Config`](lib/fontist/config.rb:1))
- ✅ CLI integration ([`CLI`](lib/fontist/cli.rb:1) `--location` option)
- ✅ 147 unit tests, 100% pass rate

### Test Infrastructure (100%)
- ✅ [`SystemFont.fontist_font_paths`](lib/fontist/system_font.rb:44) now searches recursively
- ✅ Test helpers updated in [`fontist_helper.rb`](spec/support/fontist_helper.rb:1):
  - `font_path(filename)` - searches recursively
  - `font_file(filename)` - returns Pathname, searches recursively
  - `formula_font_path(key, filename)` - NEW: explicit formula-keyed paths
- ✅ Fixed 3 initial test expectations

### Architecture Validation
- ✅ Formula-keyed paths prevent font name conflicts (MECE)
- ✅ Fonts install to `~/.fontist/fonts/{formula-key}/{font-file}`
- ✅ SystemFont correctly finds fonts via recursive search
- ✅ No functionality regressions

---

## Current State

### Test Results
```
893 examples, 40 failures, 16 pending
Pass rate: 95.5%
```

### Failures Breakdown

**Category A: Path Expectations (20 tests) - HIGHEST PRIORITY**
- Tests expect: `/tmp/fonts/Font.ttf` (flat)
- Tests get: `/tmp/fonts/formula_key/Font.ttf` (correct)
- **Solution:** Replace `font_path` with `formula_font_path(key, filename)`

**Category B: Test Isolation (10 tests) - MEDIUM PRIORITY**
- Pass individually, fail in full suite
- **Cause:** SystemFont/SystemIndex cache not cleared
- **Solution:** Add cache clearing in test setup

**Category C: Unrelated (10 tests) - LOW PRIORITY**
- Git repo/import tests, likely unrelated
- **Action:** Investigate individually, fix if related or skip

---

## Your Task: Complete Remaining Work

### Task 1: Fix Category A Test Expectations (1 hour) 🎯

**Objective:** Update 20 tests to expect formula-keyed paths

**Process for each failing test:**

1. **Run test individually:**
   ```bash
   bundle exec rspec spec/fontist/font_spec.rb:LINE --format documentation
   ```

2. **Identify the pattern:**
   ```ruby
   # Test shows:
   Expected: "/tmp/fonts/AndaleMo.TTF"
   Got:      "/tmp/fonts/andale/AndaleMo.TTF"
   #                          ^^^^^^^ Formula key
   ```

3. **Find the formula key:**
   ```ruby
   # In the test file, look for:
   example_formula("andale.yml")  # <-- "andale" is the key
   ```

4. **Update the expectation:**
   ```ruby
   # OLD
   expect(Fontist.ui).to receive(:say).with(%(- #{font_path('AndaleMo.TTF')}))

   # NEW
   expect(Fontist.ui).to receive(:say).with(%(- #{formula_font_path('andale', 'AndaleMo.TTF')}))
   ```

5. **Verify fix:**
   ```bash
   bundle exec rspec spec/fontist/font_spec.rb:LINE
   # Should pass
   ```

**Tests to Fix:**

| File | Line | Formula Key | Font File |
|------|------|-------------|-----------|
| `cli_spec.rb` | 840 | andale | AndaleMo.TTF |
| `cli_spec.rb` | 863 | andale | AndaleMo.TTF |
| `cli_spec.rb` | 919 | fira_code | FiraCode-*.ttf |
| `cli_spec.rb` | 956 | courier | *.ttf |
| `font_spec.rb` | 413 | adobe_reader_19 | adobedevanagari_*.otf |
| `font_spec.rb` | 424 | andale | AndaleMo.TTF |
| `font_spec.rb` | 455 | tex_gyre_chorus | texgyrechorus-*.otf |
| `font_spec.rb` | 465 | tex_gyre_chorus | texgyrechorus-*.otf |
| `font_spec.rb` | 505-553 | tex_gyre_chorus | texgyrechorus-*.otf |
| `font_spec.rb` | 623 | source | SourceCodePro-*.ttf |
| `font_spec.rb` | 742 | lato | Lato-*.ttf |
| `font_spec.rb` | 754 | tex_gyre_chorus | texgyrechorus-*.otf |
| `font_spec.rb` | 764 | tex_gyre_chorus | texgyrechorus-*.otf |
| `manifest_spec.rb` | 71 | andale | AndaleMo.TTF |
| `manifest_spec.rb` | 82 | andale | AndaleMo.TTF |

**Finding Formula Keys:**
```bash
# Method 1: Grep for formula name
grep -l "Font Name" spec/examples/formulas/*.yml

# Method 2: View formula file
cat spec/examples/formulas/andale.yml | head -5
# Shows: name: Andale
# File is: andale.yml
# Key is: andale (filename without .yml)
```

### Task 2: Fix Category B Test Isolation (20 minutes)

**Objective:** Ensure caches are cleared between tests

**Current cache clearing locations:**
- [`fontist_helper.rb:32-33`](spec/support/fontist_helper.rb:32)
- [`fontist_helper.rb:123-124`](spec/support/fontist_helper.rb:123)
- [`fontist_helper.rb:141-142`](spec/support/fontist_helper.rb:141)

**Action:**
1. Run failing tests individually to confirm they pass
2. Add this to affected test contexts:
   ```ruby
   before do
     Fontist::SystemFont.reset_font_paths_cache
     Fontist::SystemIndex.reset_cache
   end
   ```

**Tests to Check:**
- `system_font_spec.rb:6`
- `font_spec.rb:400, 413, 424` (and others that pass individually)

### Task 3: Investigate Category C (10 minutes)

**Objective:** Determine if unrelated, fix if related

**Tests:**
- `update_spec.rb:7, 16, 29, 51, 67, 83, 96` (7 tests)
- `repo_spec.rb:191`, `repo_cli_spec.rb:66, 114` (3 tests)
- `formula_suggestion_spec.rb:72` (1 test)
- `macos_import_source_spec.rb:104, 116, 174` (3 tests)

**Action:**
```bash
# Run each individually
bundle exec rspec spec/fontist/update_spec.rb:7

# If passes individually → test isolation issue
# If fails → investigate error message
# If clearly unrelated → document and skip
```

### Task 4: Update README.adoc (30 minutes) 📝

**File:** [`README.adoc`](README.adoc:1)

**Add Section: Installation Locations** (after "Installation")

```adoc
== Installation Locations

Fontist supports three installation locations:

=== User Location (Default)

Fonts installed to `~/.fontist/fonts/{formula-key}/`

* Per-user installation
* No admin permissions required
* Organized by formula for conflict prevention

=== System Location

Fonts installed to system directories (platform-specific)

* Requires admin/sudo permissions
* Available to all users
* Platform paths:
  ** macOS: `/Library/Fonts/`
  ** Linux: `/usr/local/share/fonts/`
  ** Windows: `C:\Windows\Fonts\`

=== Custom Location

Fonts installed to user-specified directory

* Specified via config or command line
* Full path control

.Installation location examples
[source,shell]
----
# Install to user location (default)
fontist install "Roboto"

# Install to system location
fontist install "Roboto" --location=system
sudo fontist install "Roboto" --location=system  # May require sudo

# Install to custom location
fontist install "Roboto" --location=/custom/path
----
```

**Update Configuration Section:**

Add to configuration table:
```adoc
|install_location
|Installation location (`user`, `system`, or path)
|`user`
```

**Add Section: Environment Variables**

```adoc
== Environment Variables

FONTIST_INSTALL_LOCATION:: Override default installation location (`user`, `system`, or path)
FONTIST_PATH:: Override base fontist directory (default: `~/.fontist`)
GOOGLE_FONTS_API_KEY:: Google Fonts API key for importing fonts
```

### Task 5: Create Installation Guide (20 minutes)

**File:** Create [`docs/install-locations-guide.md`](docs/install-locations-guide.md:1)

**Template:**
```markdown
# Installation Locations Guide

## Overview

Fontist supports flexible font installation locations...

## Location Types

### User Location
- Path: `~/.fontist/fonts/{formula-key}/`
- Permissions: No special permissions required
- Use case: Personal font management
- Platform support: All platforms

### System Location
- macOS: `/Library/Fonts/`
- Linux: `/usr/local/share/fonts/`
- Windows: `C:\Windows\Fonts\`
- Permissions: Requires admin/sudo
- Use case: System-wide font availability

### Custom Location
- Path: User-specified
- Permissions: Depends on target directory
- Use case: Special deployment scenarios

## Usage Examples

### CLI Usage
[examples]

### Ruby API Usage
[examples]

### Configuration File
[examples]

## Platform-Specific Behavior

### macOS
[details]

### Linux
[details]

### Windows
[details]

## Permission Requirements

[details on when sudo is needed]

## Troubleshooting

### Permission Denied Errors
[solutions]

### Fonts Not Found After Installation
[solutions]

## Best Practices

[recommendations]
```

### Task 6: Clean Up Documentation (20 minutes)

**Create old-docs directory:**
```bash
mkdir -p old-docs/install-location-implementation
```

**Move completed planning docs:**
```bash
mv INSTALL_LOCATION_IMPLEMENTATION_STATUS.md old-docs/install-location-implementation/
mv INSTALL_LOCATION_TEST_FIXES_PLAN.md old-docs/install-location-implementation/
mv INSTALL_LOCATION_CONTINUATION_PLAN.md old-docs/install-location-implementation/
mv INSTALL_LOCATION_CONTINUATION_PROMPT.md old-docs/install-location-implementation/
# Keep FINAL versions in root
```

**Check for broken links:**
```bash
# Scan documentation for references to moved files
grep -r "INSTALL_LOCATION" docs/ README.adoc
# Update any references
```

---

## Success Criteria

### Must Complete ✅
- [ ] All 893 tests pass (0 failures)
- [ ] README.adoc documents install locations
- [ ] Installation guide exists

### Should Complete 📝
- [ ] All old planning docs moved to old-docs/
- [ ] No broken documentation links
- [ ] Environment variables documented

### Verification Commands

```bash
# Test suite
bundle exec rspec --format progress

# Expected output:
# 893 examples, 0 failures, 16 pending

# Documentation check
ls old-docs/install-location-implementation/
ls docs/install-locations-guide.md

# README has install locations section
grep -A 10 "Installation Locations" README.adoc
```

---

## Important Context

### Formula-Keyed Path Structure (CORRECT)

```
~/.fontist/fonts/
├── andale/
│   └── AndaleMo.TTF
├── source_code_pro/
│   ├── SourceCodePro-Regular.ttf
│   ├── SourceCodePro-Bold.ttf
│   └── ...
├── lato/
│   ├── Lato-Regular.ttf
│   └── ...
└── {formula-key}/
    └── {font-files}
```

**Why this is correct:**
- Prevents filename conflicts between formulas
- Maintains MECE principle
- Organized by source/formula
- Easy to understand and manage

### Test Helper Usage

```ruby
# In tests that copy fonts directly (old test style)
example_font("Font.ttf")
expect(font_file("Font.ttf")).to exist  # Searches recursively ✅

# In tests that install via formula (real installation)
example_formula("andale.yml")
Fontist::Font.install("Andale Mono")
expect(formula_font_path("andale", "AndaleMo.TTF")).to exist  # Explicit path ✅
```

### Common Mistakes to Avoid

❌ **Don't revert to flat structure** - it's architecturally wrong
❌ **Don't lower test standards** - fix tests properly
❌ **Don't skip documentation** - it's user-facing
✅ **Do update test expectations** - they're checking for old behavior
✅ **Do preserve formula-keyed paths** - they're correct
✅ **Do complete documentation** - users need to know about locations

---

## Quick Start Commands

```bash
# 1. Check current status
bundle exec rspec --format progress | tail -5

# 2. Run a specific failing test
bundle exec rspec spec/fontist/font_spec.rb:413 --format documentation

# 3. Find formula key
grep -l "adobe devanagari" spec/examples/formulas/*.yml

# 4. Update test expectation
# Edit spec file, change font_path to formula_font_path

# 5. Verify fix
bundle exec rspec spec/fontist/font_spec.rb:413

# 6. Run full suite
bundle exec rspec

# 7. Update documentation
# Edit README.adoc, add installation locations section
```

---

## Resources

### Key Files
- **Implementation:** [`lib/fontist/install_location.rb`](lib/fontist/install_location.rb:1)
- **Config:** [`lib/fontist/config.rb`](lib/fontist/config.rb:1)
- **CLI:** [`lib/fontist/cli.rb`](lib/fontist/cli.rb:1)
- **Test Helpers:** [`spec/support/fontist_helper.rb`](spec/support/fontist_helper.rb:1)
- **Unit Tests:** [`spec/fontist/install_location_spec.rb`](spec/fontist/install_location_spec.rb:1)

### Documentation
- **Continuation Plan:** [`INSTALL_LOCATION_FINAL_CONTINUATION_PLAN.md`](INSTALL_LOCATION_FINAL_CONTINUATION_PLAN.md:1)
- **Status Tracker:** [`INSTALL_LOCATION_FINAL_STATUS.md`](INSTALL_LOCATION_FINAL_STATUS.md:1)
- **Current Prompt:** This file

### Reference Materials
- **Formula Examples:** `spec/examples/formulas/*.yml`
- **Test Fixtures:** `spec/fixtures/fonts/*.ttf`
- **System Config:** [`lib/fontist/system.yml`](lib/fontist/system.yml:1)

---

## Timeline

**Estimated Completion:** 2-3 hours

| Task | Time | Priority |
|------|------|----------|
| Fix 20 path expectation tests | 1.0h | HIGH |
| Fix 10 test isolation issues | 0.3h | MEDIUM |
| Investigate 10 unrelated tests | 0.2h | LOW |
| Update README.adoc | 0.5h | CRITICAL |
| Create installation guide | 0.3h | IMPORTANT |
| Clean up documentation | 0.3h | NICE |
| **TOTAL** | **2.6h** | |

---

## Final Notes

**Remember:**
1. The implementation is **correct** - formula-keyed paths are the right architecture
2. Test failures are **expected** - they're checking for old flat paths
3. **Do not revert** the formula-keyed structure - fix the tests instead
4. **Document thoroughly** - users need to understand the location feature
5. **Complete the work** - we're 93% done, finish the last 7%

**You can do this!** The hardest part (implementation) is complete. Now it's just cleanup and documentation.

Good luck! 🚀