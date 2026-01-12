# Install Location OOP - Continuation Prompt

**Mission:** Fix remaining 14 test failures and complete documentation for the Install Location OOP feature.

**Current State:** 85% complete - OOP architecture done, 149 new tests passing, 50% of failures fixed

**Estimated Time:** 6-8 hours compressed

---

## 🎯 Quick Start

### 1. Verify Starting State
```bash
cd /Users/mulgogi/src/fontist/fontist
bundle exec rspec --seed 1234 | grep "examples\|failures"
# Expected: 1035 examples, 14 failures, 18 pending
```

### 2. Read Context
1. **This Prompt:** Quick overview (you're reading it)
2. **Status:** `INSTALL_LOCATION_OOP_CONTINUATION_STATUS.md` (detailed current state)
3. **Plan:** `INSTALL_LOCATION_OOP_CONTINUATION_PLAN.md` (comprehensive roadmap)
4. **Architecture:** `docs/install-location-oop-architecture.md` (design reference)

### 3. Understand What's Done
✅ **Complete:** Full OOP architecture with 7 classes, factory pattern, three-index search
✅ **Complete:** 149 comprehensive new tests (100% passing)
✅ **Complete:** Test isolation infrastructure (ENV stubbing)
✅ **Achievement:** 50% failure reduction (28 → 14)

---

## 📋 Your Tasks (Priority Order)

### Task 1: Debug Index Issue (1-2 hours)

**Problem:** Fonts copied by `example_font()` not appearing in index search results

**Steps:**
1. Run diagnostic test:
```bash
bundle exec rspec spec/fontist/font_spec.rb:926 --seed 1234 -fd
```

2. Add debug output to understand issue:
```ruby
# In spec/fontist/font_spec.rb around line 926
it "removes font" do
  fresh_fonts_and_formulas do
    example_formula("overpass.yml")
    example_font("overpass-regular.otf")

    # DIAGNOSTIC
    puts "Fonts path: #{Fontist.fonts_path}"
    puts "Font files: #{Dir.glob(Fontist.fonts_path.join('**', '*'))}"
    puts "Index path: #{Fontist.fontist_index_path}"

    index = Fontist::Indexes::FontistIndex.instance
    fonts = index.find("overpass", nil)
    puts "Found in index: #{fonts.inspect}"

    # Will likely fail here
    Fontist::Font.uninstall("overpass")
  end
end
```

3. Identify root cause (likely one of):
   - Path structure mismatch (flat vs formula-keyed)
   - Index not rebuilding properly
   - Singleton caching wrong data

### Task 2: Fix Helper Method (30 min)

Based on diagnostic, update `spec/support/fontist_helper.rb`:

```ruby
def example_font(filename)
  # Option A: If path structure issue
  # Determine formula key and create subdirectory

  # Option B: If index rebuild issue
  # Force complete singleton reset

  # Option C: If timing issue
  # Add explicit wait for index file

  # See INSTALL_LOCATION_OOP_CONTINUATION_PLAN.md for detailed options
end
```

### Task 3: Fix system_index_font_collection_spec.rb (15 min)

```ruby
# In spec/fontist/system_index_font_collection_spec.rb:6
it "round-trips system index file" do
  Dir.mktmpdir do |dir|
    filename = File.join(dir, "system_index.default_family.yml")

    # ADD THIS LINE
    FileUtils.mkdir_p(dir)

    # Rest of test...
  end
end
```

### Task 4: Verify All Tests Pass (30 min)

```bash
bundle exec rspec --seed 1234
# Target: 1035 examples, 0 failures ✅
```

### Task 5: Update README.adoc (2-3 hours)

Add comprehensive "Font Installation Locations" section.
**Template provided in:** `INSTALL_LOCATION_OOP_CONTINUATION_PLAN.md` (Phase 2)

### Task 6: Update CHANGELOG.md (30 min)

Add v2.1.0 entry documenting all changes.
**Template provided in:** `INSTALL_LOCATION_OOP_CONTINUATION_PLAN.md` (Phase 2)

### Task 7: Cleanup Documentation (30 min)

```bash
mkdir -p old-docs
mv INSTALL_LOCATION_OOP_PHASE2_*.md old-docs/
mv TEST_ISOLATION_*.md old-docs/
mv AGGRESSIVE_*.md old-docs/
mv CONTINUATION_PROMPT_*.md old-docs/
# Keep: docs/install-location-oop-architecture.md
```

### Task 8: Final Validation (30 min)

- [ ] All tests pass: `bundle exec rspec`
- [ ] Test README examples manually
- [ ] Verify CLI commands work as documented
- [ ] Check architecture docs are current

---

## 💡 Key Insights for Debugging

### The Core Issue
Tests use `example_font()` which:
1. Copies font file to `Fontist.fonts_path`
2. Calls `Fontist::Indexes::FontistIndex.instance.rebuild`
3. But `Font.uninstall()` can't find fonts in index

### Why This Happens
The index is correctly stubbed to temp paths, BUT:
- Fonts might be copied to wrong path structure
- Index rebuild might not complete before query
- Singleton might be caching old paths

### Test It Works Individually
```bash
# This will PASS
bundle exec rspec spec/fontist/font_spec.rb:926 -fd

# This will FAIL (same test in sequence)
bundle exec rspec spec/fontist/font_spec.rb --seed 1234
```

This proves it's a test isolation/setup issue, NOT an architecture problem!

---

## 🔧 Common Fix Patterns

### Pattern A: Path Structure
```ruby
def example_font(filename)
  # Copy to formula subdirectory
  formula_key = "test_formula"  # or derive from filename
  target_dir = Fontist.fonts_path.join(formula_key)
  FileUtils.mkdir_p(target_dir)
  example_font_to(filename, target_dir)
  Fontist::Indexes::FontistIndex.instance.rebuild
end
```

### Pattern B: Complete Reset
```ruby
def example_font(filename)
  example_font_to(filename, Fontist.fonts_path)
  # Reset singleton completely
  Fontist::Indexes::FontistIndex.instance_variable_set(:@instance, nil)
  Fontist::Indexes::FontistIndex.instance.rebuild
end
```

### Pattern C: Explicit Wait
```ruby
def example_font(filename)
  example_font_to(filename, Fontist.fonts_path)
  Fontist::Indexes::FontistIndex.instance.rebuild
  # Wait for index file
  sleep 0.1 until File.exist?(Fontist.fontist_index_path)
end
```

---

## 🚨 Critical Guidelines

### DO:
✅ Fix test expectations to match correct behavior
✅ Add proper test isolation
✅ Update documentation comprehensively
✅ Test all code examples
✅ Follow OOP and MECE principles

### DON'T:
❌ Lower test thresholds
❌ Skip failing tests
❌ Compromise the architecture
❌ Leave todos or hacks
❌ Forget documentation

---

## 📁 Key Files

### Implementation (Reference - Don't Modify)
- `lib/fontist/install_locations/*.rb` - 7 OOP classes
- `lib/fontist/indexes/*.rb` - 3 index singletons
- `lib/fontist/config.rb` - Location configuration
- `lib/fontist/install_location.rb` - Factory

### Test Infrastructure (May Need Updates)
- `spec/support/fontist_helper.rb` - **Fix `example_font()` here**
- `spec/support/fresh_home.rb` - Isolation already fixed ✅
- `spec/spec_helper.rb` - Cleanup already added ✅

### Tests Needing Fixes (4 + 9 + 1 = 14)
- `spec/fontist/font_spec.rb` - 4 failures (uninstall + existing)
- `spec/fontist/cli_spec.rb` - 9 failures (manifest + status)
- `spec/fontist/system_index_font_collection_spec.rb` - 1 failure (temp file)

### Documentation (To Update)
- `README.adoc` - Add location section
- `CHANGELOG.md` - Add v2.1.0 entry

---

## 🎉 Success Indicators

You'll know you're done when:

```bash
$ bundle exec rspec
...
1035 examples, 0 failures, 18 pending
Finished in X minutes
```

And:
- README.adoc has "Font Installation Locations" section
- CHANGELOG.md documents v2.1.0 changes
- All code examples in README work
- Old docs moved to `old-docs/`
- Manual testing confirms everything works

---

## 🆘 If You Get Stuck

### Debugging Won't Work?
1. Check ENV variables are set in test
2. Verify temp directories exist
3. Check index file location
4. Add more diagnostic output

### Not Sure Which Fix Pattern?
1. Run diagnostic test first
2. Look at actual vs expected paths
3. Check if index file exists and has content
4. Try each pattern in order (A → B → C)

### Documentation Unclear?
Use templates in `INSTALL_LOCATION_OOP_CONTINUATION_PLAN.md` - they're ready to copy/paste.

---

## 📞 Resources

**Planning:**
- `INSTALL_LOCATION_OOP_CONTINUATION_PLAN.md` - Comprehensive roadmap
- `INSTALL_LOCATION_OOP_CONTINUATION_STATUS.md` - Current state
- This file - Quick start

**Reference:**
- `docs/install-location-oop-architecture.md` - Architecture design
- Previous session docs in project root (can be moved to old-docs after)

**Commands:**
```bash
# Check failures
bundle exec rspec --seed 1234 | grep failures

# Test one file
bundle exec rspec spec/fontist/font_spec.rb --seed 1234

# Test one example
bundle exec rspec spec/fontist/font_spec.rb:926 --seed 1234 -fd

# Full suite
bundle exec rspec
```

---

**The hard architectural work is done - just debug and document!** 🚀

**Estimated completion: 6-8 hours of focused work.**