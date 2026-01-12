# Install Location OOP - Final Completion Prompt

**Mission:** Fix ALL 12 remaining test failures + Complete documentation

**Priority:** All specs MUST pass (1,035 examples, 0 failures) before documentation

---

## 🚀 Quick Start

### 1. Verify Starting State
```bash
cd /Users/mulgogi/src/fontist/fontist
bundle exec rspec --seed 1234 | grep "examples\|failures"
# Expected: 1,035 examples, 12 failures, 18 pending
```

### 2. Read Context (IN ORDER)
1. **INSTALL_LOCATION_OOP_FINAL_STATUS.md** - What's done, what remains
2. **INSTALL_LOCATION_OOP_FINAL_PLAN.md** - Detailed roadmap
3. **docs/install-location-oop-architecture.md** - Architecture reference

### 3. What's Already Done ✅
- ✅ OOP architecture (7 classes, 3 indexes, factory pattern)
- ✅ 149 new tests (100% passing)
- ✅ Test isolation infrastructure
- ✅ Formula-keyed directory structure in `example_font()` helper
- ✅ Reduced failures from 14 → 12 (98.8% pass rate)

---

## 📋 Your Tasks

### Phase 1: Fix 12 Test Failures (4-6 hours) - **MUST DO FIRST**

**Priority Order:**

1. **Integration Test** (1-2h) - Most Complex
   ```bash
   bundle exec rspec spec/fontist/font_spec.rb:292 --seed 1234 -fd
   ```
   - Expects 4 Courier paths, gets 1
   - May need SystemFont.find to return all family styles
   - See PLAN.md Step 1.1 for detailed approach

2. **Manifest Tests** (2-3h)
   ```bash
   bundle exec rspec spec/fontist/cli_spec.rb:647,668,696,752,920,953,976 --seed 1234
   ```
   - Update test setup and path expectations
   - See PLAN.md Step 1.2

3. **CLI Tests** (1h)
   ```bash
   bundle exec rspec spec/fontist/cli_spec.rb:541,551,60,461 --seed 1234
   ```
   - Update output/exit code expectations
   - See PLAN.md Step 1.3

4. **Verify All Pass** (30min)
   ```bash
   bundle exec rspec --seed 1234
   # Target: 1,035 examples, 0 failures ✅
   ```

### Phase 2: Documentation (3-4 hours) - **ONLY AFTER ALL TESTS PASS**

1. **README.adoc** - Add "Font Installation Locations" section
   - Full template in PLAN.md Step 2.1
   - Test all code examples

2. **CHANGELOG.md** - Add v2.1.0 entry
   - Template in PLAN.md Step 2.2

3. **Cleanup** - Move old docs to old-docs/
   - Commands in PLAN.md Step 2.3

---

## 🎯 Success Criteria

**Before completion, you MUST have:**

- [ ] 1,035 examples, 0 failures (run `bundle exec rspec`)
- [ ] README.adoc updated with locations section
- [ ] CHANGELOG.md updated with v2.1.0
- [ ] All code examples manually tested
- [ ] Old docs moved to old-docs/

---

## 💡 Key Insights

### The Architecture is Solid
- OOP design is production-ready
- All 149 new tests pass
- Core functionality works correctly

### The Issues are Test-Level
- Old tests expect old behavior
- Need assertion updates, not code rewrites
- formula-keyed structure is CORRECT

### Critical Files Already Fixed
- ✅ `spec/support/fontist_helper.rb` - Formula-keyed `example_font()`
- ✅ `spec/fontist/system_index_font_collection_spec.rb` - Empty index handling

---

## ⚠️ Critical Guidelines

### DO:
✅ Fix test expectations to match correct OOP behavior
✅ Update assertions for formula-keyed paths
✅ Document all decisions clearly
✅ Test all code examples
✅ Follow OOP and MECE principles

### DON'T:
❌ Lower test thresholds
❌ Skip failing tests
❌ Compromise architecture
❌ Leave TODOs or hacks
❌ Forget documentation

---

## 📁 Key Files

### Documentation (READ FIRST)
- `INSTALL_LOCATION_OOP_FINAL_STATUS.md` - Current state
- `INSTALL_LOCATION_OOP_FINAL_PLAN.md` - Detailed plan
- `docs/install-location-oop-architecture.md` - Architecture

### Modified in This Session
- `spec/support/fontist_helper.rb` - Formula-keyed helpers
- `spec/fontist/system_index_font_collection_spec.rb` - Fixed

### Need Fixing
- `spec/fontist/font_spec.rb` - Integration test (line 292)
- `spec/fontist/cli_spec.rb` - Manifest + CLI tests (multiple lines)

### To Update
- `README.adoc` - Add locations section
- `CHANGELOG.md` - Add v2.1.0 entry

---

## 🆘 If You Get Stuck

### On Integration Test (line 292)
1. Check what SystemFont.find actually returns
2. Verify expected behavior in production
3. See PLAN.md Step 1.1 for decision tree
4. May need to update SystemFont.find OR test expectation

### On Manifest Tests
1. Each test is independent - fix one at a time
2. Check if test uses `example_font()` correctly
3. Update path expectations for formula-keyed structure
4. See PLAN.md Step 1.2 for patterns

### On CLI Tests
1. Run with `-fd` to see actual vs expected
2. Update assertions to match OOP output
3. Usually simple expectation updates

---

## ⏱️ Timeline

| Task | Time | Status |
|------|------|--------|
| Fix integration test | 1-2h | ⏳ TODO |
| Fix manifest tests | 2-3h | ⏳ TODO |
| Fix CLI tests | 1h | ⏳ TODO |
| Verify all pass | 30m | ⏳ TODO |
| README.adoc | 2-3h | ⏳ TODO |
| CHANGELOG.md | 30m | ⏳ TODO |
| Cleanup docs | 30m | ⏳ TODO |
| **TOTAL** | **8-11h** | **Compressed: 6-8h** |

---

**Remember:** Fix ALL specs first, THEN document. No shortcuts! 🚀

**Start here:** `bundle exec rspec spec/fontist/font_spec.rb:292 --seed 1234 -fd`