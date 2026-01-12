# Continuation Prompt: Complete Fontisan/Excavate Test Fixes

## Context

You are continuing work on updating Fontist to use the latest `fontisan` and `excavate` gems. The core integration is complete and working - we've successfully migrated from external `otfinfo` commands to pure Ruby Fontisan library. However, 21 tests are still failing due to test isolation and caching issues.

## Current State

**Test Results**: 640 examples, 21 failures, 47 pending (89.4% pass rate)

**What's Already Fixed**:
- ✅ Core Fontisan integration complete
- ✅ FontMetadataExtractor using Fontisan
- ✅ CollectionFile using Fontisan::TrueTypeCollection
- ✅ FontFile using Fontisan with metadata mode
- ✅ create_formula_spec.rb fixed (handles new metadata fields)

**What's Broken**: 21 tests failing due to cached state between test runs

## The Problem

Tests pass individually but fail when run as part of the full suite. This is a classic test isolation problem caused by cached state:

1. `SystemIndex` maintains cached instances (`@system_index`, `@fontist_index`)
2. `SystemFont` caches font paths (`@system_font_paths`, `@fontist_font_paths`)
3. These caches persist between tests, causing state pollution

## Your Task

Fix the remaining 21 test failures by implementing proper cache management and test isolation.

## Detailed Action Plan

### Step 1: Diagnose Cache Issues (30 minutes)

Add debug output to one failing test to understand the cache state:

```ruby
# In spec/fontist/cli_spec.rb:399 (or another failing test)
it "shows formula and font names" do
  # Add these debug lines
  puts "\n=== DEBUG ==="
  puts "SystemIndex @system_index: #{SystemIndex.instance_variable_get(:@system_index).inspect}"
  puts "SystemIndex @system_index_path: #{SystemIndex.instance_variable_get(:@system_index_path).inspect}"
  puts "SystemFont @system_font_paths: #{SystemFont.instance_variable_get(:@system_font_paths).inspect}"
  puts "SystemFont @fontist_font_paths: #{SystemFont.instance_variable_get(:@fontist_font_paths).inspect}"
  puts "=== END DEBUG ===\n"

  # Existing test code...
end
```

Run this single test and the full suite to compare cache states.

### Step 2: Implement Systematic Cache Reset (1 hour)

**File**: `spec/support/fontist_helper.rb`

Add a comprehensive cache reset method:

```ruby
def reset_all_fontist_caches
  # Reset SystemIndex caches
  SystemIndex.reset_cache

  # Reset SystemFont caches
  SystemFont.reset_font_paths_cache

  # Reset any verification flags
  # (SystemIndexFontCollection has @index_check_done flag)
  # This may need additional code in lib/fontist/system_index.rb

  # Clear Fontist path caches if they exist
  Fontist.instance_variable_set(:@fonts_path, nil) if Fontist.instance_variable_defined?(:@fonts_path)
end
```

### Step 3: Update Test Helpers (30 minutes)

Update these helper methods in `spec/support/fontist_helper.rb`:

```ruby
def stub_fonts_path_to_new_path
  reset_all_fontist_caches  # Add this line
  # ... existing code ...
end

def stub_system_fonts_path_to_new_path
  reset_all_fontist_caches  # Add this line
  # ... existing code ...
end

def fresh_fontist_home
  reset_all_fontist_caches  # Add this line
  # ... existing code ...
end

def no_fonts
  reset_all_fontist_caches  # Add this line
  # ... existing code ...
end
```

### Step 4: Fix Failing Test Files (1-2 hours)

Add explicit cache resets to the failing spec files:

**File**: `spec/fontist/cli_spec.rb`
```ruby
RSpec.describe Fontist::CLI do
  before(:each) do
    reset_all_fontist_caches
  end

  # ... existing tests ...
end
```

**File**: `spec/fontist/font_spec.rb`
```ruby
RSpec.describe Fontist::Font do
  before(:each) do
    reset_all_fontist_caches
  end

  # ... existing tests ...
end
```

**File**: `spec/fontist/system_font_spec.rb`
```ruby
RSpec.describe Fontist::SystemFont do
  before(:each) do
    reset_all_fontist_caches
  end

  # ... existing tests ...
end
```

**File**: `spec/fontist/performance_spec.rb`
```ruby
RSpec.describe "Performance testing" do
  before(:each) do
    reset_all_fontist_caches
  end

  # ... existing tests ...
end
```

### Step 5: Verify Fixes (30 minutes)

Run tests incrementally:

```bash
# Test each file individually
bundle exec rspec spec/fontist/cli_spec.rb
bundle exec rspec spec/fontist/font_spec.rb
bundle exec rspec spec/fontist/system_font_spec.rb
bundle exec rspec spec/fontist/performance_spec.rb

# Test full suite
bundle exec rspec

# Test with random order (3 times)
bundle exec rspec --order random
bundle exec rspec --order random
bundle exec rspec --order random
```

All should pass with 0 failures.

### Step 6: Additional Fixes (if needed)

If tests still fail after cache resets, check:

**SystemIndexFontCollection Verification Flag**:
The class has an `@index_check_done` flag that might need resetting:

```ruby
# In lib/fontist/system_index.rb, add to reset_cache method:
def self.reset_cache
  @system_index = nil
  @system_index_path = nil
  @fontist_index = nil
  @fontist_index_path = nil

  # Reset verification flags on cached instances if they exist
  [@system_index, @fontist_index].compact.each do |index|
    index.reset_verification! if index.respond_to?(:reset_verification!)
  end
end
```

## Testing Strategy

1. **Start small**: Fix one test file at a time
2. **Verify incrementally**: Ensure no regressions after each change
3. **Test in isolation**: Run individual files to confirm they work
4. **Test together**: Run full suite to check for interactions
5. **Test randomly**: Use `--order random` to catch order dependencies

## Success Criteria

- ✅ All 640 examples pass (0 failures)
- ✅ Tests pass with `--order random`
- ✅ Tests pass 3 times consecutively (no flakiness)
- ✅ Individual test files all pass
- ✅ Full suite passes

## Potential Issues & Solutions

### Issue: Tests still fail after cache reset
**Solution**: Add more detailed logging to identify which specific state is causing problems

### Issue: Some caches are in Lutaml::Model or other gems
**Solution**: Check for any gem-level caches and reset them too

### Issue: Temp files or directories persist
**Solution**: Enhance `fresh_fontist_home` to ensure clean slate

### Issue: System font stubs not working
**Solution**: Verify stub_system_fonts is called and SystemFont is properly isolated

## Files to Modify

**High Priority**:
1. `spec/support/fontist_helper.rb` - Add cache reset logic
2. `spec/fontist/cli_spec.rb` - Add before(:each) hooks
3. `spec/fontist/font_spec.rb` - Add before(:each) hooks
4. `spec/fontist/system_font_spec.rb` - Add before(:each) hooks
5. `spec/fontist/performance_spec.rb` - Add before(:each) hooks

**May Need**:
6. `lib/fontist/system_index.rb` - Enhanced reset_cache method

## Important Notes

- **DON'T modify production code** - the Fontisan integration is complete and working
- **DON'T lower test standards** - fix the root cause, not the symptoms
- **DON'T skip tests** - all tests must pass
- **DO test incrementally** - verify each change before moving on
- **DO keep changes isolated to test code** - this is a test infrastructure issue

## After Completion

Once all tests pass:

1. Run final validation:
   ```bash
   bundle exec rspec --order random
   ```

2. Update documentation:
   - Update CHANGELOG.md
   - Update README.adoc if needed
   - Move temp docs to old-docs/

3. Create summary of changes made

## Reference Documents

- **FONTISAN_EXCAVATE_UPDATE_COMPLETION_PLAN.md** - Full completion plan
- **FONTISAN_EXCAVATE_UPDATE_STATUS.md** - Current status tracker
- **spec/fontist/import/create_formula_spec.rb** - Example of fixed test

## Quick Start Commands

```bash
# See current failures
bundle exec rspec --format documentation --dry-run | grep -E "FAILED"

# Run one failing test with debug
bundle exec rspec spec/fontist/cli_spec.rb:399 --format documentation

# Run full suite
bundle exec rspec

# Get failure count
bundle exec rspec --format progress 2>&1 | grep "examples,"
```

Good luck! The hard part (Fontisan integration) is done. This is just cleanup work.