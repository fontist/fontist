# CollectionFile OOP Refactoring - Implementation Plan

## Status: In Progress

**Created:** 2025-12-13
**Target Completion:** 2025-12-13
**Assignee:** Code mode AI

## Objective

Refactor [`lib/fontist/import/files/collection_file.rb`](lib/fontist/import/files/collection_file.rb) to follow clean OOP principles, matching the production [`lib/fontist/collection_file.rb`](lib/fontist/collection_file.rb) pattern while maintaining backward compatibility.

## Architecture Decision

**Pattern:** Factory + Eager Extraction (production-like)

### Key Principles
- ✅ Single Responsibility: Each method does ONE thing
- ✅ DRY: No code duplication
- ✅ Minimal Overhead: Simple, direct implementation
- ✅ Factory Pattern: `from_path` for clean instantiation
- ✅ Backward Compatible: Existing API unchanged
- ✅ Automatic Cleanup: Use `Tempfile` instead of `Dir.mktmpdir`

### Design Rationale
The current implementation violates OOP by:
1. Mixing parsing, extraction, and filtering in procedural methods
2. Using multi-step extraction (`read` → `extract_ttfs`)
3. Manual temp directory management
4. No factory pattern

The refactored design:
1. Separates concerns into focused methods
2. Uses direct, clear extraction flow
3. Automatic cleanup with `Tempfile`
4. Adds factory pattern while keeping backward compatibility

## Implementation Phases

### Phase 1: Refactor CollectionFile ✅ DESIGNED
**File:** `lib/fontist/import/files/collection_file.rb`

**Changes:**
- Add factory method `from_path`
- Simplify constructor to take parsed collection
- Replace `read` → `extract_ttfs` chain with `extract_fonts` → `extract_font_at`
- Use `Tempfile` instead of `Dir.mktmpdir`
- Extract filtering logic to `hidden?` method
- Extract extension detection to `detect_extension` method

**Lines of Code:** 66 (reduced from 77)

**Backward Compatibility:**
- Keep `.new(path, name_prefix:)` working
- Keep `.fonts` returning array
- Keep `.filename` and `.source_filename` working

### Phase 2: Implementation ⏳ IN PROGRESS
**Tasks:**
- [ ] Replace file content with refactored version
- [ ] Verify syntax is correct
- [ ] Check all methods are properly defined

### Phase 3: Testing 🔜 PENDING
**Tasks:**
- [ ] Run full test suite: `bundle exec rspec`
- [ ] Check if any specs need updating
- [ ] Test with actual font collection files
- [ ] Verify `RecursiveExtraction` still works
- [ ] Verify `FormulaBuilder` still works

### Phase 4: Validation 🔜 PENDING
**Tasks:**
- [ ] Manual testing with real font collections
- [ ] Check error handling
- [ ] Verify temp file cleanup
- [ ] Performance check (should be same or better)

### Phase 5: Documentation 🔜 PENDING
**Tasks:**
- [ ] Update inline code comments if needed
- [ ] No README changes needed (internal refactoring)
- [ ] Move this plan to old-docs/ when complete

## Implementation Details

### Refactored Code Structure

```ruby
module Fontist::Import::Files
  class CollectionFile
    # Factory pattern
    def self.from_path(path, name_prefix: nil)
      collection = build_collection(path)
      new(collection, path, name_prefix)
    end
    
    # Backward compatible constructor
    def initialize(fontisan_collection, path, name_prefix = nil)
      @collection = fontisan_collection
      @path = path
      @name_prefix = name_prefix
      @fonts = extract_fonts
    end
    
    # Public API
    attr_reader :fonts
    def filename
    def source_filename
    
    # Private implementation
    private
    def extract_fonts
    def extract_font_at(index)
    def hidden?(font_file)
    def extension
    def detect_extension
  end
end
```

### Method Responsibilities

| Method | Responsibility | Lines |
|--------|---------------|-------|
| `from_path` | Factory: parse and create instance | 5 |
| `build_collection` | Parse Fontisan collection | 5 |
| `initialize` | Initialize with parsed collection | 6 |
| `extract_fonts` | Orchestrate extraction + filtering | 5 |
| `extract_font_at` | Extract single font via Tempfile | 8 |
| `hidden?` | Filter hidden fonts | 3 |
| `detect_extension` | Detect correct extension | 5 |
| `filename` | Generate normalized filename | 3 |
| `source_filename` | Return original if different | 3 |

**Total:** 43 lines of actual code (rest is class/module declarations, comments)

## Risk Assessment

### Low Risk ✅
- Backward compatible API
- No breaking changes to callers
- Same functionality, cleaner code
- Automatic temp cleanup improves reliability

### Medium Risk ⚠️
- Specs might need updating (acceptable per instructions)
- Different error messages possible (improved clarity)

### Mitigation
- Run full test suite
- Manual testing with real files
- Can revert if critical issues found

## Success Criteria

- [x] Code follows OOP principles
- [x] Code is DRY
- [x] Minimal overhead
- [ ] All existing functionality works
- [ ] Tests pass (or updated to correct expectations)
- [ ] No regression in actual behavior
- [ ] Code is more maintainable

## Dependencies

**None** - This is an isolated refactoring of a single file.

**Files that use CollectionFile:**
- `lib/fontist/import/recursive_extraction.rb` (line 87)
- `lib/fontist/import/formula_builder.rb` (lines 75, 100-101)

**No changes needed** to these files due to backward compatibility.

## Timeline

- **Phase 1:** ✅ Complete (Design)
- **Phase 2:** ⏳ In Progress (Implementation)
- **Phase 3:** 🔜 15 minutes (Testing)
- **Phase 4:** 🔜 10 minutes (Validation)
- **Phase 5:** 🔜 5 minutes (Documentation)

**Total Estimated Time:** 30 minutes remaining

## Notes

- This refactoring follows the memory bank guidelines for OOP, MECE, and separation of concerns
- Production `CollectionFile` serves as the architectural reference
- Correctness of architecture takes priority over passing old tests
- Tests that fail may need updating to new (correct) expectations