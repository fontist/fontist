# Continuation Prompt: Fix All Test Failures

## Context

The multi-font installation feature (Issue #351) and system_index.rb D RY refactoring have been successfully completed. All tests related to these changes are passing. However, there are **34 pre-existing test failures** that need to be fixed.

## What Has Been Completed

### 1. Multi-Font Installation Feature ✅
- **Implementation**: [`lib/fontist/font.rb`](lib/fontist/font.rb:37) - `Font.install_many` method
- **CLI Wrapper**: [`lib/fontist/cli.rb`](lib/fontist/cli.rb:122) - Thin CLI layer
- **Tests**: 4/4 new tests passing
- **Documentation**: [`README.adoc`](README.adoc:100) updated

### 2. DRY Refactoring System Index ✅
- **Implementation**: [`lib/fontist/system_index.rb`](lib/fontist/system_index.rb:425)
- **Eliminated**: ~70 lines of code duplication
- **Tests**: 7/8 passing (1 pre-existing failure)

## Current Test Status

```
640 examples, 34 failures, 47 pending
```

### Test Failures by Category

#### Category 1: System Font Detection (26 failures)
**Root Cause**: System fonts not being found in test environment

**Affected Files**:
- `spec/fontist/cli_spec.rb` - 16 failures (lines: 56, 389, 399, 420, 549, 568, 594, 629, 644, 731, 745, 779, 797, 830, 853, 895)
- `spec/fontist/font_spec.rb` - 10 failures (lines: 268, 305, 849, 877, 892, 922, 936, 974, 987, 1000)

**Investigation Needed**:
1. Check test fixture setup in `spec/support/fontist_helper.rb`
2. Verify `stub_system_fonts` and `stub_fonts_path_to_new_path` helpers
3. Inspect system font path configuration in tests
4. Review font index building process in test environment

#### Category 2: Font Index Corruption (2 failures)
**Files**:
- `spec/fontist/cli_spec.rb:56`
- `spec/fontist/system_index_spec.rb:40`

**Issue**: Error message format doesn't match test expectations

#### Category 3: Font Processing (2 failures)
**Files**:
- `spec/fontist/import/font_metadata_extractor_spec.rb:66`
- `spec/fontist/import/otf/font_file_spec.rb:280`

**Issue**: Collection file processing

#### Category 4: Google Fonts API (Warnings, not failures)
**Issue**: Invalid URL format in formula generation

## Tasks to Complete

### Phase 1: System Font Detection (PRIORITY: CRITICAL)
**Estimated Time**: 4-6 hours

```markdown
- [ ] Read test helper files:
  - spec/support/fontist_helper.rb
  - spec/support/fresh_home.rb
  - spec/support/system_fonts.rb (if exists)

- [ ] Investigate why SystemFont.find returns nil in tests
- [ ] Check font fixture setup
- [ ] Verify stub methods work correctly
- [ ] Fix system font path resolution in test environment
- [ ] Run affected tests to verify fixes
```

### Phase 2: Font Index Corruption
**Estimated Time**: 1-2 hours

```markdown
- [ ] Review error in spec/fontist/cli_spec.rb:56
- [ ] Check what error message is expected
- [ ] Update error handling/formatting
- [ ] Verify fix with tests
```

### Phase 3: Font Processing
**Estimated Time**: 2-3 hours

```markdown
- [ ] Review font metadata extractor for collections
- [ ] Check OTF font file processing logic
- [ ] Fix collection enumeration
- [ ] Run import specs
```

### Phase 4: Verification
**Estimated Time**: 1 hour

```markdown
- [ ] Run full test suite
- [ ] Verify 0 failures
- [ ] Check no regressions in passing tests
- [ ] Update documentation
```

## Commands to Run

### Check Specific Failure
```bash
bundle exec rspec spec/fontist/cli_spec.rb:56 -fd
```

### Run Category Tests
```bash
# System font detection tests
bundle exec rspec spec/fontist/cli_spec.rb -e "status"
bundle exec rspec spec/fontist/font_spec.rb -e "install"

# Index corruption
bundle exec rspec spec/fontist/system_index_spec.rb:40

# Import/processing
bundle exec rspec spec/fontist/import/
```

### Full Test Suite
```bash
bundle exec rspec --format progress
```

## Key Files to Review

### Test Helpers
- `spec/support/fontist_helper.rb` - Main test helpers
- `spec/spec_helper.rb` - RSpec configuration

### System Font Logic
- `lib/fontist/system_font.rb` - System font detection
- `lib/fontist/system_index.rb` - Font indexing

### Test Fixtures
- `spec/fixtures/` - Font files for testing
- `spec/examples/` - Example files

## Success Criteria

- [ ] **0 test failures** (640/640 passing)
- [ ] No new failures introduced
- [ ] All categories addressed
- [ ] Documentation updated if behavior changed
- [ ] Performance maintained

## Notes

- Most failures are PRE-EXISTING (not introduced by multi-font feature)
- The multi-font installation feature is COMPLETE and WORKING
- These failures indicate broader issues with test environment setup
- Fixing system font detection will likely resolve ~75% of failures

## Architecture Principles to Follow

- **MECE**: Ensure solutions are mutually exclusive and collectively exhaustive
- **DRY**: Don't duplicate code
- **OOP**: Object-oriented solutions over procedural
- **Separation of Concerns**: Keep test helpers focused
- **Architectural Solutions**: Fix root causes, not symptoms

## Next Steps

1. Start with Phase 1 (system font detection) as it will fix the most failures
2. Use TDD approach - run tests frequently to verify fixes
3. Document any behavioral changes
4. Create helper methods if patterns emerge
5. Update TEST_FAILURE_FIX_PLAN.md with progress