# Continuation Prompt: macOS Multi-Version Font Support Implementation

## Context

You are continuing implementation of multi-version macOS font catalog support for Fontist. The architecture phase is complete. You are now implementing the solution.

## Current State

**What exists**:
- ✅ [`lib/fontist/import/macos.rb`](lib/fontist/import/macos.rb:1) - Works for Font6 only
- ✅ 180+ macOS formulas in [`spec/fixtures/formulas/Formulas/macos/`](spec/fixtures/formulas/Formulas/macos/)
- ✅ Uses `plist` gem (already a dependency)
- ✅ CLI command: `fontist import macos`

**What's needed**:
- Extend to support Font5, Font6, Font7, Font8 (currently only Font6)
- Use Plist-based parsing (NOT Lutaml::Model)
- Maintain 100% backward compatibility
- Implement in 5 compressed phases (~3.5 hours total)

## Documentation References

**READ THESE FIRST**:
1. [`MACOS_MULTI_VERSION_CONTINUATION_PLAN.md`](MACOS_MULTI_VERSION_CONTINUATION_PLAN.md) - Full implementation plan with code examples
2. [`MACOS_MULTI_VERSION_STATUS.md`](MACOS_MULTI_VERSION_STATUS.md) - Current progress tracker
3. [`docs/macos-addon-fonts-architecture-v2.md`](docs/macos-addon-fonts-architecture-v2.md) - Technical architecture
4. [`docs/macos-addon-fonts-implementation-summary.md`](docs/macos-addon-fonts-implementation-summary.md) - Quick reference

## Implementation Phases (Start with Phase 1)

### Phase 1: CI Enhancement (30min) - **START HERE**

**Goal**: Get real catalog XML samples from different macOS versions

**File to modify**: `.github/workflows/discover-fonts.yml`

**Changes needed**:
1. Add matrix strategy for macOS versions [13, 14, 15]
2. Add step to find and display all catalogs
3. Add step to upload catalogs as artifacts

**Specific code** (see CONTINUATION_PLAN.md for full details):
```yaml
jobs:
  discover-macos:
    strategy:
      matrix:
        version: [13, 14, 15]
    
    steps:
      # ... existing steps ...
      
      - name: Find and Display Catalogs
        run: |
          echo "=== Available Font Catalogs ==="
          find /System/Library/AssetsV2/ -name "*.xml" -type f | sort
      
      - name: Upload Catalogs
        uses: actions/upload-artifact@v4
        with:
          name: macos-${{ matrix.version }}-catalogs
          path: /System/Library/AssetsV2/com_apple_MobileAsset_Font*/*.xml
```

**Success criteria**:
- Workflow runs on macOS 13, 14, 15
- Catalogs uploaded as artifacts
- Can download XMLs to analyze schemas

**After Phase 1**: Download artifacts, analyze schemas, then proceed to Phase 2

### Phase 2: Data Structures (1 hour)

**Goal**: Create Asset class and Plist-based parsers

**Files to create**:
```
lib/fontist/macos/catalog/
├── asset.rb           # Simple data class with attr_readers
├── base_parser.rb     # Plist.parse_xml wrapper
├── font5_parser.rb    # Inherits BaseParser
├── font6_parser.rb    # Inherits BaseParser
├── font7_parser.rb    # Inherits BaseParser
└── font8_parser.rb    # Inherits BaseParser
```

**Key implementation** (see CONTINUATION_PLAN.md for complete code):
- Asset: Simple Ruby class with `initialize(data)` taking Plist hash
- BaseParser: Uses `Plist.parse_xml(@xml_path)` 
- Version parsers: Inherit from BaseParser, override if schemas differ

**Tests to create**:
- `spec/fontist/macos/catalog/asset_spec.rb`
- `spec/fontist/macos/catalog/base_parser_spec.rb`
- One spec file per parser

### Phase 3: Import Enhancement (1 hour)

**Goal**: Extend `Import::Macos` with multi-version support

**File to modify**: `lib/fontist/import/macos.rb`

**Key additions**:
1. `self.available_catalogs` - Auto-detect all Font{5,6,7,8}
2. `self.import_all_versions` - Batch import
3. `detect_version(path)` - Extract version number
4. `parse_catalog` - Use structured parsers instead of inline Plist
5. Replace `links` method to use `parse_catalog.map(&:download_url)`

**Backward compatibility**: Default behavior must remain unchanged

### Phase 4: CLI Enhancement (30min)

**Goal**: Add version-specific CLI options

**File to modify**: `lib/fontist/import_cli.rb`

**Add to existing `macos` command**:
- `--version` option for specific version
- `--all-versions` flag for batch import

**Add new command**:
- `macos-catalogs` - List available catalogs on system

### Phase 5: Documentation (30min)

**Goal**: Update user-facing documentation

**File to modify**: `README.adoc`

**Add section**: macOS On-Demand Fonts (Multiple Versions)
- Version table (Font5-Font8 with macOS releases)
- Usage examples for all CLI commands
- Clear examples

**Move to old-docs/**:
- `docs/macos-addon-fonts-architecture.md`
- `docs/macos-addon-fonts-diagram.md`
- `docs/macos-addon-fonts-implementation-plan.md`

## Core Principles (CRITICAL)

### Architecture Principles
- **Pure OOP**: Every concept is a class with single responsibility
- **MECE**: Mutually exclusive, collectively exhaustive
- **Separation of Concerns**: Data, parsing, importing, CLI all separate
- **Open/Closed**: Version-specific parsers extend BaseParser
- **DRY**: Reuse BaseParser, Asset class across versions

### Technical Constraints
- **Use Plist gem** (NOT Lutaml::Model) - It's native macOS, already a dependency
- **No new dependencies** - Everything needed is already there
- **100% backward compatible** - Existing `fontist import macos` must work unchanged
- **All tests must pass** - No regressions allowed

### Quality Standards
- Run `bundle exec rubocop` after each phase - must be clean
- Write tests FIRST for each class (TDD approach)
- Every class needs a corresponding spec file
- Tests must be thorough and follow principles
- If specs fail, fix the BEHAVIOR not the expectations

## Implementation Strategy

### Start Order
1. **Phase 1 FIRST** (CI) - Provides data for everything else
2. Wait for CI artifacts, download and analyze schemas
3. **Phase 2** (build parsers based on actual schemas)
4. **Phase 3** (integrate parsers)
5. **Phase 4 & 5** can partially overlap if needed

### Testing Strategy
- Unit test each class individually
- Integration test the full import flow
- Manual test CLI commands on real macOS
- Verify backward compatibility explicitly

### Error Handling
- Graceful handling of missing catalogs
- Clear error messages identifying which version had issues
- Don't fail entire import if one version fails

## Success Criteria

**Technical**:
- [ ] Supports Font5, Font6, Font7, Font8
- [ ] Auto-detects available versions
- [ ] All existing tests pass (backward compat)
- [ ] All new tests pass
- [ ] Rubocop clean
- [ ] No new dependencies

**Functional**:
- [ ] `fontist import macos` works (default)
- [ ] `fontist import macos --version 7` works
- [ ] `fontist import macos --all-versions` works
- [ ] `fontist macos-catalogs` lists catalogs
- [ ] Formula generation works for all versions

**Quality**:
- [ ] OOP principles maintained
- [ ] MECE architecture
- [ ] Proper tests for all classes
- [ ] Clear error messages
- [ ] Documentation accurate

## Common Pitfalls to Avoid

❌ **DON'T**:
- Use Lutaml::Model (use Plist instead)
- Add new gem dependencies
- Break backward compatibility
- Lower test expectations to make them pass
- Use hardcoded paths
- Repeat code across version parsers

✅ **DO**:
- Use Plist gem for parsing
- Keep Asset as simple data class
- Maintain full backward compatibility
- Fix behavior when tests fail
- Use inheritance for version parsers
- Test on real macOS system

## Next Actions (When You Start)

1. **Read all documentation files listed above**
2. **Update status tracker** ([`MACOS_MULTI_VERSION_STATUS.md`](MACOS_MULTI_VERSION_STATUS.md))
3. **Start Phase 1**: Modify `.github/workflows/discover-fonts.yml`
4. **Commit and push** to trigger CI
5. **Download artifacts** when CI completes
6. **Analyze schemas** to understand differences
7. **Proceed to Phase 2** with actual schema knowledge

## Questions to Answer During Implementation

These will inform implementation decisions:

1. **Do Font5/7/8 have same schema as Font6?**
   - If yes: BaseParser handles all
   - If no: Version-specific parsers override

2. **What fields are in the XML?**
   - Confirm: `__BaseURL`, `__RelativePath`, `PostScriptName`, `FontFamily`, `DisplayName`
   - Any additional fields to capture?

3. **Are all versions available on GitHub Actions?**
   - macOS 13: Font7?
   - macOS 14: Font7?
   - macOS 15: Font8?

## Update This Prompt

As you progress:
1. Update [`MACOS_MULTI_VERSION_STATUS.md`](MACOS_MULTI_VERSION_STATUS.md) after each phase
2. Note any deviations from plan in status tracker
3. Document schema differences discovered
4. Add any new risks or blockers

## Code Quality Reminders

- **OOP**: Each class has single responsibility
- **MECE**: No overlap, no gaps
- **DRY**: Reuse BaseParser logic
- **Tests**: Write before implementation
- **Backward Compat**: Test explicitly
- **Rubocop**: Clean before each commit

---

**Ready to start implementation at Phase 1**. All architecture is complete, plan is detailed, success criteria are clear.