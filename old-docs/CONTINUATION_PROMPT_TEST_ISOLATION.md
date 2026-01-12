# Continuation Prompt: Fix Remaining Test Order Dependencies

## Context

You are continuing work on Fontist test isolation improvements. A clean OOP architecture has been implemented for cache management, but 21 tests still fail due to test order dependencies.

## Current State

### ✅ Completed

**Clean OOP Test Isolation Architecture**:
- [`spec/support/spec_isolation_manager.rb`](spec/support/spec_isolation_manager.rb:1) - Component-based state management
- [`spec/support/spec_isolation_config.rb`](spec/support/spec_isolation_config.rb:1) - Central RSpec configuration
- [`TEST_ISOLATION_ARCHITECTURE.md`](TEST_ISOLATION_ARCHITECTURE.md:1) - Complete architecture documentation

**Test Results**: 640 examples, 21 failures, 47 pending (96.7% pass)

**Key Finding**: All 21 failures pass individually but fail in full suite → test order dependencies

### 📋 Your Task

Fix the 21 test order dependencies by making tests self-contained.

## Failing Tests

**CLI Spec** (13 failures) - `spec/fontist/cli_spec.rb`:
- Line 403: status shows formula and font names
- Line 424: status collection font prints formula
- Line 553: manifest_locations one font regular style
- Line 572: manifest_locations one font bold style
- Line 598: manifest_locations two fonts
- Line 613: manifest_locations from system paths
- Line 633: manifest_locations font with space
- Line 648: manifest_locations not installed font
- Line 783: manifest_install not installed but supported
- Line 801: manifest_install two supported fonts
- Line 834: manifest_install no style specified
- Line 857: manifest_install no style by font name
- Line 899: manifest_install confirmed license

**Font Spec** (4 failures) - `spec/fontist/font_spec.rb`:
- Line 881: uninstall second font in formula
- Line 926: status supported but not installed
- Line 940: status supported and installed
- Line 991: status installed from another formula

**SystemFont Spec** (3 failures) - `spec/fontist/system_font_spec.rb`:
- Line 21: find with valid font name
- Line 40: find filename not include full style
- Line 54: find collection fonts

**Performance Spec** (1 failure) - `spec/fontist/performance_spec.rb`:
- Line 18: manifest performs under reasonable time

## Step-by-Step Approach

### Step 1: Identify Dependencies (30 min per spec file)

For each failing spec file:

```bash
# Find minimal failing set
bundle exec rspec spec/fontist/cli_spec.rb --bisect

# Test with specific seed to reproduce
bundle exec rspec spec/fontist/cli_spec.rb --order random --seed 12345
```

**Document findings**:
- Which tests must run before failures?
- What state do they set up?
- What cleanup is missing?

### Step 2: Categorize Dependencies (15 min per failure)

For each failure, identify the type:

1. **Fixture Pollution** - Files/data left behind
   ```ruby
   # Bad: Leaves files
   it "test" do
     example_font("Arial.ttf")  # Not cleaned up
   end

   # Good: Cleans up
   it "test" do
     stub_fonts_path_to_new_path do
       example_font_to_fontist("Arial.ttf")
     end  # Cleanup happens here
   end
   ```

2. **Global State** - Class variables/constants modified
   ```ruby
   # Bad: Modifies global state
   it "test" do
     Fontist.fonts_path = "/custom/path"  # Persists
   end

   # Good: Temporary stub
   it "test" do
     allow(Fontist).to receive(:fonts_path).and_return("/custom/path")
   end  # Stub cleared after test
   ```

3. **Stubbing Leakage** - Stubs persist across tests
   ```ruby
   # Ensure using allow(), not stub!()
   # allow() is cleared by RSpec automatically
   ```

4. **Resource Locking** - File handles/locks held
   ```ruby
   # Bad: File left open
   it "test" do
     file = File.open("test.txt")
     # ...
   end

   # Good: Ensure closed
   it "test" do
     File.open("test.txt") do |file|
       # ...
     end  # Auto-closed
   end
   ```

### Step 3: Fix Dependencies (20-30 min per failure)

**Pattern for Self-Contained Tests**:

```ruby
it "does something" do
  # 1. Set up fresh state
  stub_fonts_path_to_new_path do
    stub_system_fonts_path_to_new_path do
      # 2. Create needed fixtures
      example_font_to_system("Arial.ttf")

      # 3. Perform test
      result = SystemFont.find("Arial")

      # 4. Assert
      expect(result).to include("Arial.ttf")
    end  # Auto cleanup
  end  # Auto cleanup
end
```

**Common Fixes**:

```ruby
# Fix 1: Use proper helpers
# Bad:
FileUtils.cp("font.ttf", Fontist.fonts_path)

# Good:
example_font_to_fontist("font.ttf")  # Uses proper path setup

# Fix 2: Wrap in cleanup blocks
# Bad:
stub_system_fonts

# Good:
stub_system_fonts_path_to_new_path do
  # test code
end

# Fix 3: Use examples, not real files
# Bad:
Font.install("Arial")  # Downloads real font

# Good:
example_font_to_fontist("Arial.ttf")  # Uses fixture
```

### Step 4: Validate Fixes (10 min per spec file)

After fixing each spec file:

```bash
# Test the file alone
bundle exec rspec spec/fontist/cli_spec.rb

# Test with full suite
bundle exec rspec

# Test with random order (3 times)
bundle exec rspec --order random
bundle exec rspec --order random --seed $(date +%s)
bundle exec rspec --order random --seed $(date +%s)
```

**Success Criteria**:
- File passes alone: ✅
- File passes in full suite: ✅
- Passes with random order: ✅
- No new failures introduced: ✅

## Systematic Process

Work through spec files in this order (easiest to hardest):

1. **SystemFont Spec** (3 failures) - Simplest, good warm-up
2. **Font Spec** (4 failures) - Medium complexity
3. **CLI Spec** (13 failures) - Most failures, save for when experienced
4. **Performance Spec** (1 failure) - May need special handling

For each file:
1. Run `--bisect` to understand dependencies
2. Fix one test at a time
3. Run full suite after each fix
4. Document what was changed and why
5. Move to next test only after current passes

## Tools Reference

```bash
# Investigation
bundle exec rspec spec/fontist/cli_spec.rb --bisect
bundle exec rspec --order random --seed 12345
bundle exec rspec --only-failures

# Single test debugging
bundle exec rspec spec/fontist/cli_spec.rb:403 -fd

# Validation
bundle exec rspec spec/fontist/cli_spec.rb
bundle exec rspec
bundle exec rspec --order random

# Performance profiling
bundle exec rspec --profile 10
```

## Common Pitfalls to Avoid

❌ **Don't**: Disable failing tests
✅ **Do**: Fix the root cause

❌ **Don't**: Add sleeps or waits
✅ **Do**: Fix race conditions properly

❌ **Don't**: Modify production code to fix tests
✅ **Do**: Fix test design

❌ **Don't**: Lower expectations to pass
✅ **Do**: Make tests match correct behavior

❌ **Don't**: Fix all at once
✅ **Do**: Fix incrementally and validate

## Expected Timeline

| Task | Time | Total |
|------|------|-------|
| SystemFont fixes (3) | 1.5h | 1.5h |
| Font fixes (4) | 2h | 3.5h |
| CLI fixes (13) | 4h | 7.5h |
| Performance fix (1) | 0.5h | 8h |
| Final validation | 0.5h | 8.5h |

**Estimated Total**: 8-9 hours of focused work

## Success Metrics

- [ ] 640 examples, 0 failures, 47 pending
- [ ] Tests pass with `--order random` (3+ consecutive runs)
- [ ] No flaky tests
- [ ] All tests self-contained
- [ ] Clean, maintainable test code

## Documentation to Read

Before starting:
1. [`TEST_ISOLATION_ARCHITECTURE.md`](TEST_ISOLATION_ARCHITECTURE.md:1) - Understand the architecture
2. [`spec/support/fontist_helper.rb`](spec/support/fontist_helper.rb:1) - Available helper methods
3. [`TEST_ISOLATION_CONTINUATION_PLAN.md`](TEST_ISOLATION_CONTINUATION_PLAN.md:1) - Detailed plan

## After Completion

Once all tests pass:

1. Run final validation:
   ```bash
   bundle exec rspec --order random (3x)
   bundle exec rspec --format documentation
   ```

2. Update documentation:
   - Move temp docs to `old-docs/`
   - Update `FONTISAN_EXCAVATE_UPDATE_STATUS.md`
   - Update `CHANGELOG.md` if needed

3. Create summary of:
   - What dependencies were found
   - What fixes were applied
   - Patterns discovered
   - Recommendations for future tests

## Quick Start

```bash
# 1. Start with SystemFont (easiest)
bundle exec rspec spec/fontist/system_font_spec.rb --bisect

# 2. Fix identified dependency
# (edit test to be self-contained)

# 3. Validate
bundle exec rspec spec/fontist/system_font_spec.rb
bundle exec rspec

# 4. Move to next test
# Repeat until all pass
```

Good luck! The hard architectural work is done. This is systematic test cleanup.