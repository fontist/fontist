# Test Failure Fix Plan

## Test Failure Analysis

Total: **640 examples, 34 failures, 47 pending**

### Failures by Category

#### 1. Multi-Font Installation Feature (My Changes)
**Status**: ✅ COMPLETE - 4/4 tests passing
- All new multi-font tests passing
- Backward compatibility maintained

#### 2. System Index Refactoring (My Changes)
**Status**: ✅ COMPLETE - 7/8 tests passing
- DRY refactoring successful
- 1 pre-existing failure (index corruption)

#### 3. Pre-Existing CLI Failures (16 failures)
**Location**: `spec/fontist/cli_spec.rb`
**Status**: ⚠️ NEEDS FIX

Affected areas:
- Font index corruption handling (line 56)
- Status command failures (lines 389, 399, 420)
- Manifest-location failures (lines 549, 568, 594, 629, 644)
- Manifest-install failures (lines 731, 745, 779, 797, 830, 853, 895)

**Root Cause**: System font detection issues - fonts not being found where expected

#### 4. Pre-Existing Font API Failures (10 failures)
**Location**: `spec/fontist/font_spec.rb`
**Status**: ⚠️ NEEDS FIX

Affected tests (lines):
- 268, 305, 849, 877, 892, 922, 936, 974, 987, 1000

**Root Cause**: Similar system font detection issues

#### 5. Import/Processing Failures (2 failures)
**Location**: Various import specs
**Status**: ⚠️ NEEDS FIX

- `spec/fontist/import/font_metadata_extractor_spec.rb:66`
- `spec/fontist/import/otf/font_file_spec.rb:280`

#### 6. System Index Corruption (1 failure)
**Location**: `spec/fontist/system_index_spec.rb:40`
**Status**: ⚠️ NEEDS FIX - Pre-existing

## Fix Strategy

### Phase 1: System Font Detection (Priority: HIGH)
Most failures stem from system font detection not finding fonts.

**Tasks**:
1. Investigate why `SystemFont.find` is failing in tests
2. Check if test fixtures are properly set up
3. Verify system font paths configuration
4. Fix font index building in test environment

**Expected to fix**: ~26 failures

### Phase 2: Font Index Corruption Handling
**Tasks**:
1. Review font index corruption detection logic
2. Update error handling to match test expectations
3. Ensure proper error messages are displayed

**Expected to fix**: 2 failures

### Phase 3: Import/Processing
**Tasks**:
1. Review font metadata extraction for collections
2. Fix OTF font file processing

**Expected to fix**: 2 failures

### Phase 4: Google Fonts URL Issues
**Tasks**:
1. Investigate Google Fonts API URL structure changes
2. Update formula generation if needed

**Expected to fix**: N/A (warnings, not failures)

## Implementation Status

### Completed ✅
- [x] Multi-font installation feature (Issue #351)
- [x] Clean CLI/API separation
- [x] DRY refactoring of system_index.rb
- [x] Documentation updates

### In Progress 🔄
- [ ] System font detection fixes
- [ ] Font index corruption handling
- [ ] Import/processing fixes

### Not Started ⏳
- [ ] Create test helper for system fonts
- [ ] Comprehensive test environment setup
- [ ] CI/CD test isolation improvements

## Next Steps

1. **Immediate**: Fix system font detection in test environment
2. **Short-term**: Address font index corruption handling
3. **Medium-term**: Fix import/processing issues
4. **Long-term**: Improve test infrastructure

## Time Estimates

- Phase 1 (System Font Detection): 4-6 hours
- Phase 2 (Index Corruption): 1-2 hours
- Phase 3 (Import/Processing): 2-3 hours
- **Total**: 7-11 hours of focused work

## Risk Assessment

**Low Risk**: Phases 2-3 (isolated fixes)
**Medium Risk**: Phase 1 (affects many tests, requires careful investigation)

## Success Criteria

- [ ] All 640 examples passing (0 failures)
- [ ] No new failures introduced
- [ ] Backward compatibility maintained
- [ ] Performance not degraded