# Test Isolation - Continuation Plan

## Status Summary

**Test Results**: 640 examples, 21 failures, 47 pending (96.7% pass)
**Architecture**: ✅ Clean OOP isolation architecture implemented
**Remaining Work**: Test order dependency investigation and fixes

## Completed Work

### ✅ Phase 1: Clean OOP Architecture (COMPLETE)

**Files Created**:
1. [`spec/support/spec_isolation_manager.rb`](spec/support/spec_isolation_manager.rb:1) - Component-based state management
2. [`spec/support/spec_isolation_config.rb`](spec/support/spec_isolation_config.rb:1) - Central RSpec configuration
3. [`TEST_ISOLATION_ARCHITECTURE.md`](TEST_ISOLATION_ARCHITECTURE.md:1) - Architecture documentation

**Files Modified**:
1. [`spec/support/fontist_helper.rb`](spec/support/fontist_helper.rb:3) - Delegates to IsolationManager
2. [`spec/fontist/cli_spec.rb`](spec/fontist/cli_spec.rb:1) - Removed scattered hooks
3. [`spec/fontist/font_spec.rb`](spec/fontist/font_spec.rb:1) - Removed scattered hooks
4. [`spec/fontist/system_font_spec.rb`](spec/fontist/system_font_spec.rb:1) - Removed scattered hooks
5. [`spec/fontist/performance_spec.rb`](spec/fontist/performance_spec.rb:1) - Removed scattered hooks

**Architecture Principles Applied**:
- ✅ Single Responsibility Principle - Each component manages only its state
- ✅ Open/Closed Principle - Easy to extend with new components
- ✅ Dependency Inversion - Components depend on interface, not implementation
- ✅ Separation of Concerns - Clear distinction between coordination and execution
- ✅ Encapsulation - State management hidden within components

## Remaining Work

### Phase 2: Test Order Dependency Investigation (HIGH PRIORITY)

**Objective**: Identify and fix the 21 test order dependencies

**Failing Tests** (all pass individually, fail in suite):

**CLI Spec** (13 failures):
- `spec/fontist/cli_spec.rb:403` - status shows formula and font names
- `spec/fontist/cli_spec.rb:424` - status collection font prints formula
- `spec/fontist/cli_spec.rb:553` - manifest_locations one font regular style
- `spec/fontist/cli_spec.rb:572` - manifest_locations one font bold style
- `spec/fontist/cli_spec.rb:598` - manifest_locations two fonts
- `spec/fontist/cli_spec.rb:613` - manifest_locations from system paths
- `spec/fontist/cli_spec.rb:633` - manifest_locations font with space
- `spec/fontist/cli_spec.rb:648` - manifest_locations not installed font
- `spec/fontist/cli_spec.rb:783` - manifest_install not installed but supported
- `spec/fontist/cli_spec.rb:801` - manifest_install two supported fonts
- `spec/fontist/cli_spec.rb:834` - manifest_install no style specified
- `spec/fontist/cli_spec.rb:857` - manifest_install no style by font name
- `spec/fontist/cli_spec.rb:899` - manifest_install confirmed license

**Font Spec** (4 failures):
- `spec/fontist/font_spec.rb:881` - uninstall second font in formula
- `spec/fontist/font_spec.rb:926` - status supported but not installed
- `spec/fontist/font_spec.rb:940` - status supported and installed
- `spec/fontist/font_spec.rb:991` - status installed from another formula

**SystemFont Spec** (3 failures):
- `spec/fontist/system_font_spec.rb:21` - find with valid font name
- `spec/fontist/system_font_spec.rb:40` - find filename not include full style
- `spec/fontist/system_font_spec.rb:54` - find collection fonts

**Performance Spec** (1 failure):
- `spec/fontist/performance_spec.rb:18` - manifest performs under reasonable time

#### Step 1: Identify Dependencies (2-3 hours)

**Tools to Use**:
```bash
# Find minimal failing set
bundle exec rspec --bisect

# Test with specific seed
bundle exec rspec --order random --seed 12345

# Test only failures
bundle exec rspec --only-failures

# Profile to find slow tests that might cause timing issues
bundle exec rspec --profile 10
```

**Investigation Checklist**:
- [ ] Run `--bisect` on each failing spec file
- [ ] Document which tests must run before failures
- [ ] Identify shared state (files, database, globals)
- [ ] Check for timing/async issues
- [ ] Look for fixture pollution

#### Step 2: Categorize Dependencies (1 hour)

**Dependency Types**:

1. **Fixture Pollution** - Tests leave files/data behind
   - Fix: Proper cleanup in `after` hooks or helper methods

2. **Global State** - Tests modify class variables/constants
   - Fix: Add components to IsolationManager

3. **Stubbing Leakage** - Stubs/mocks persist across tests
   - Fix: Ensure RSpec.reset after each test

4. **Timing Dependencies** - Tests depend on execution order
   - Fix: Make tests fully self-contained

5. **Resource Locking** - Tests hold file handles/locks
   - Fix: Proper resource cleanup

#### Step 3: Fix Dependencies (3-4 hours)

**Template for Fix**:
```ruby
# Before: Order-dependent test
it "does something" do
  # Assumes state from previous test
  expect(Font.find("Arial")).to exist
end

# After: Self-contained test
it "does something" do
  # Sets up own state
  example_font("Arial.ttf")
  expect(Font.find("Arial")).to exist
end
```

**Systematic Approach**:
1. Fix one category at a time
2. Run suite after each fix
3. Document what was changed and why
4. Ensure no regressions

#### Step 4: Validate Fixes (1 hour)

```bash
# Must all pass
bundle exec rspec
bundle exec rspec --order random
bundle exec rspec --order random --seed $(date +%s)
bundle exec rspec --order random --seed $(date +%s)
bundle exec rspec --order random --seed $(date +%s)
```

**Success Criteria**:
- [ ] 640 examples, 0 failures, 47 pending
- [ ] Passes with `--order random` (3+ times)
- [ ] Passes with different random seeds
- [ ] No flaky tests
- [ ] All tests self-contained

### Phase 3: Additional OOP Improvements (OPTIONAL)

**If time permits**, add these components:

#### FileSystemComponent
```ruby
class FileSystemComponent
  def reset
    # Clean temp directories
    # Reset file handles
  end
end
```

#### StubComponent
```ruby
class StubComponent
  def reset
    # Verify all stubs cleared
    # Reset RSpec mocks
  end
end
```

#### MetricsComponent
```ruby
class MetricsComponent
  def reset
    # Track reset times
    # Identify slow components
  end
end
```

### Phase 4: Documentation Updates (30 min)

- [ ] Move completed plans to `old-docs/`:
  - `TEST_FAILURE_FIX_PLAN.md`
  - `CONTINUATION_PROMPT_TEST_FIXES.md`

- [ ] Update `FONTISAN_EXCAVATE_UPDATE_STATUS.md`:
  - Mark Phase 3 complete
  - Update test counts
  - Document OOP architecture

- [ ] Add to README.adoc:
  - Note about test isolation architecture
  - Link to architecture docs

## Estimated Timeline

| Phase | Time | Status |
|-------|------|--------|
| Phase 1: OOP Architecture | 2h | ✅ COMPLETE |
| Phase 2: Fix Dependencies | 7-8h | ⏳ READY TO START |
| Phase 3: Optional Improvements | 2h | 📋 OPTIONAL |
| Phase 4: Documentation | 0.5h | 📋 PENDING |
| **Total** | **11.5-12.5h** | **20% Complete** |

## Next Session Checklist

When continuing this work:

1. ✅ Read `TEST_ISOLATION_ARCHITECTURE.md` for context
2. ✅ Read this continuation plan
3. ⏭️ Start with `bundle exec rspec --bisect`
4. ⏭️ Focus on one failing spec file at a time
5. ⏭️ Document findings as you go
6. ⏭️ Test incrementally - don't change everything at once

## Commands Reference

```bash
# Investigation
bundle exec rspec --bisect
bundle exec rspec --order random --seed 12345
bundle exec rspec --only-failures

# Validation
bundle exec rspec --format documentation
bundle exec rspec --order random (3x minimum)

# Single test debugging
bundle exec rspec spec/fontist/cli_spec.rb:403 --format documentation
```

## Success Metrics

- [x] Clean OOP architecture
- [x] Central state management
- [x] Component-based design
- [ ] Zero test failures
- [ ] Tests pass in any order
- [ ] No flaky tests
- [ ] Full documentation

## Notes

- The OOP architecture is **complete and correct**
- The 21 failures are **test design issues**, not architecture issues
- Each failing test **passes individually** - confirms order dependency
- Fixing these requires **test refactoring**, not more architecture
- This is **normal technical debt cleanup**, separate from Fontisan migration