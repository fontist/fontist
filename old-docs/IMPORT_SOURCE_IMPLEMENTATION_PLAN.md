# Import Source Implementation Plan

**Date**: 2025-12-27
**Status**: Ready for Implementation
**Architecture**: Corrected - Framework metadata separated from formulas
**Priority**: High - Compressed timeline for deadline

---

## Architecture Summary

### Core Principle: Separation of Concerns

1. **Formula**: Generic model, no source-specific metadata
2. **ImportSource**: Polymorphic classes (Macos, Google, Sil)
3. **Framework Metadata**: External YAML file (macOS only)

### Key Files

```
lib/fontist/
├── import_source.rb                     # Base class
├── macos_import_source.rb               # macOS-specific
├── google_import_source.rb              # Google-specific
├── sil_import_source.rb                 # SIL-specific
├── macos_framework_metadata.yml         # Framework -> macOS version mapping
├── macos_framework_metadata.rb          # Metadata loader
└── formula.rb                           # Updated with import_source

formulas/
├── macos/
│   ├── font7/                          # Framework 7
│   └── font8/                          # Framework 8
├── google/
├── sil/
└── manual/
```

---

## Implementation Phases (Compressed)

### Phase 1: Core Models (2-3 hours)

**Create Import Source Classes**

1.1. **ImportSource base class** (`lib/fontist/import_source.rb`)
   - Abstract base with polymorphic factory
   - `differentiation_key()` abstract method
   - `outdated?(new_source)` abstract method

1.2. **MacosImportSource** (`lib/fontist/macos_import_source.rb`)
   - `framework_version: integer`
   - `posted_date: string`
   - `asset_id: string`
   - Delegates min/max_macos_version to external metadata

1.3. **GoogleImportSource** (`lib/fontist/google_import_source.rb`)
   - `commit_id: string`
   - `api_version: string`
   - `last_modified: string`
   - `family_id: string`

1.4. **SilImportSource** (`lib/fontist/sil_import_source.rb`)
   - `version: string`
   - `release_date: string`

1.5. **Framework Metadata** (`lib/fontist/macos_framework_metadata.yml` + `.rb`)
   - YAML file with framework definitions
   - Loader class with query methods

**Tests**:
- `spec/fontist/import_source_spec.rb`
- `spec/fontist/macos_import_source_spec.rb`
- `spec/fontist/google_import_source_spec.rb`
- `spec/fontist/sil_import_source_spec.rb`
- `spec/fontist/macos_framework_metadata_spec.rb`

**Acceptance**:
- ✅ All import source classes serialize/deserialize correctly
- ✅ Framework metadata loads and queries work
- ✅ Polymorphic factory creates correct subclass

---

### Phase 2: Formula Integration (1-2 hours)

**Update Formula and Builder**

2.1. **Formula** (`lib/fontist/formula.rb`)
   - Remove: `catalog_version`, `min_macos_version`, `max_macos_version`
   - Add: `import_source: ImportSource`
   - Add convenience methods: `macos_import?`, `google_import?`, etc.

2.2. **FormulaBuilder** (`lib/fontist/import/formula_builder.rb`)
   - Add `import_source` to FORMULA_ATTRIBUTES
   - Add attr_writer and getter
   - Add helper methods for each source type

2.3. **CreateFormula** (`lib/fontist/import/create_formula.rb`)
   - Accept `import_source` parameter
   - Pass to FormulaBuilder
   - Remove any font_version code if present

**Tests**:
- Update `spec/fontist/formula_spec.rb`
- Update `spec/fontist/import/formula_builder_spec.rb`

**Acceptance**:
- ✅ Formula loads/saves with import_source
- ✅ Convenience methods work correctly
- ✅ Backward compatible (nil import_source)

---

### Phase 3: Catalog Parsers (1-2 hours)

**Extract PostedDate and Build ImportSource**

3.1. **BaseParser** (`lib/fontist/macos/catalog/base_parser.rb`)
   - Add `posted_date()` method
   - Add `framework_version()` method
   - Pass to Asset constructor

3.2. **Asset** (`lib/fontist/macos/catalog/asset.rb`)
   - Accept `posted_date` and `framework_version` in constructor
   - Add `to_import_source()` method
   - Add `asset_id()` convenience method

**Tests**:
- `spec/fontist/macos/catalog/base_parser_spec.rb`
- `spec/fontist/macos/catalog/asset_spec.rb`

**Acceptance**:
- ✅ PostedDate extracted from XML
- ✅ Framework version detected from filename
- ✅ Asset builds correct ImportSource

---

### Phase 4: Macos Importer (2-3 hours)

**Versioned Filenames and Directory Structure**

4.1. **Macos Importer** (`lib/fontist/import/macos.rb`)
   - Detect framework version from catalog path
   - Build MacosImportSource for each asset
   - Generate versioned filename: `{name}_{asset_id}.yml`
   - Use directory: `macos/font{N}/`
   - Pass import_source to CreateFormula

**Tests**:
- Update `spec/fontist/import/macos_spec.rb`

**Acceptance**:
- ✅ Formulas created in correct directory
- ✅ Filenames include asset_id
- ✅ ImportSource correctly populated
- ✅ No top-level framework metadata in formulas

---

### Phase 5: Google & SIL Importers (2-3 hours)

**Add ImportSource Support**

5.1. **Google Importer** (`lib/fontist/import/google_fonts_importer.rb`)
   - Research GitHub commit fetching
   - Build GoogleImportSource
   - Generate versioned filename: `{name}_{commit_short}.yml`
   - Use directory: `google/`

5.2. **SIL Importer** (`lib/fontist/import/sil_import.rb`)
   - Build SilImportSource
   - Generate versioned filename: `{name}_{version}.yml`
   - Use directory: `sil/`

**Tests**:
- Update `spec/fontist/import/google_fonts_importer_spec.rb`
- Update `spec/fontist/import/sil_import_spec.rb`

**Acceptance**:
- ✅ Google fonts have commit-based versioning
- ✅ SIL fonts have version-based naming
- ✅ Correct directory structure

---

### Phase 6: Update Detection (1 hour)

**Outdated Formula Detection**

6.1. **Font** (`lib/fontist/font.rb`)
   - Add `check_import_updates()` method
   - Use `import_source.outdated?()` for comparison

6.2. **CLI** (`lib/fontist/cli.rb`)
   - Add `check-updates` command (optional)

**Tests**:
- Update `spec/fontist/font_spec.rb`

**Acceptance**:
- ✅ Outdated formulas detected correctly
- ✅ User feedback provided

---

### Phase 7: Cleanup (1 hour)

**Remove Old Implementation**

7.1. **Remove font_version** (if present)
   - From Formula
   - From FormulaBuilder
   - From CreateFormula
   - From README

7.2. **Remove catalog_version, min/max_macos_version** (if present)
   - From Formula model
   - From FormulaBuilder
   - From all tests

**Acceptance**:
- ✅ No font_version references remain
- ✅ No top-level framework metadata in Formula

---

### Phase 8: Testing (2-3 hours)

**Comprehensive Test Suite**

8.1. **Unit Tests**
   - Import source models (5 files)
   - Framework metadata
   - Formula integration
   - Catalog parsers

8.2. **Integration Tests**
   - End-to-end import flow
   - Formula serialization
   - Platform compatibility
   - Update detection

8.3. **Regression Tests**
   - All 617 existing tests must pass
   - New tests: ~60 additional

**Acceptance**:
- ✅ All tests pass (677 total)
- ✅ No regressions
- ✅ Complete coverage of new features

---

### Phase 9: Documentation (1-2 hours)

**Update Official Documentation**

9.1. **README.adoc**
   - Document import_source attribute
   - Explain framework metadata
   - Show versioned filenames
   - Example formulas

9.2. **Architecture Docs** (`docs/`)
   - Import source architecture
   - Framework metadata design
   - Migration guide

9.3. **Move Old Docs**
   - Archive temporary planning docs to `old-docs/`
   - Keep only official documentation

**Acceptance**:
- ✅ README fully updated
- ✅ Architecture documented
- ✅ Migration guide available
- ✅ Old docs archived

---

## Total Timeline: 13-19 hours (Compressed)

**Critical Path**:
1. Phase 1: Core Models (3h)
2. Phase 2: Formula Integration (2h)
3. Phase 3: Catalog Parsers (2h)
4. Phase 4: Macos Importer (3h)
5. Phase 5: Google & SIL (3h)
6. Phase 6: Update Detection (1h)
7. Phase 7: Cleanup (1h)
8. Phase 8: Testing (3h)
9. Phase 9: Documentation (2h)

**Total**: ~20 hours

**Compressed to 2-3 days** with focused implementation.

---

## Success Criteria

### Architecture
- ✅ Formula has NO source-specific metadata
- ✅ ImportSource polymorphic classes correct
- ✅ Framework metadata external
- ✅ MECE structure throughout
- ✅ Proper separation of concerns

### Functionality
- ✅ Versioned filenames work
- ✅ Correct directory structure
- ✅ Platform compatibility via framework metadata
- ✅ Update detection functional

### Tests
- ✅ All 617 existing tests pass
- ✅ ~60 new tests pass
- ✅ Total: ~677 tests

### Documentation
- ✅ README.adoc updated
- ✅ Architecture documented
- ✅ Migration guide available
- ✅ Examples clear

---

## Implementation Notes

### Correctness Over Speed
- Architecture correctness is paramount
- Tests may need updating for new behavior
- Regressions indicate tests need correction, not code
- No shortcuts or threshold lowering

### OOP Principles
- Full object-oriented implementation
- MECE at all levels
- Single responsibility per class
- Open/closed principle

### Testing Philosophy
- Test behavior, not implementation
- Comprehensive coverage
- Clear expectations
- No lowering pass thresholds

---

## Next Steps

1. **Review** this plan
2. **Confirm** architecture is correct
3. **Switch to Code mode** to begin Phase 1
4. **Work phase-by-phase** with testing after each
5. **Document as we go**

---

**Ready to begin implementation with correct architecture.**