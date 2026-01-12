# Google Fonts Import Source Implementation - Continuation Prompt

**Context:** The import_source architecture is complete for macOS fonts. Now we need to extend it to Google Fonts.

**Status Files:**
- Plan: [`GOOGLE_FONTS_IMPORT_SOURCE_IMPLEMENTATION_PLAN.md`](GOOGLE_FONTS_IMPORT_SOURCE_IMPLEMENTATION_PLAN.md:1)
- Status: [`GOOGLE_FONTS_IMPORT_SOURCE_STATUS.md`](GOOGLE_FONTS_IMPORT_SOURCE_STATUS.md:1)

---

## Quick Summary

The GoogleImportSource class exists and is fully tested, but the Google Fonts importer doesn't use it yet. We need to:

1. Update FontDatabase to create GoogleImportSource instances
2. Update GoogleFontsImporter to accept and use import_source
3. Generate versioned filenames based on commit_id
4. Add tests and documentation

**Total Estimated Time:** 9 hours (compressed to 1-2 days)

---

## What's Already Done ✅

- ✅ `GoogleImportSource` class implemented with lutaml-model
- ✅ Polymorphic configuration in ImportSource and Formula
- ✅ 5 tests for GoogleImportSource (all passing)
- ✅ Documentation in README.adoc and import-source-architecture.md
- ✅ Base import_source infrastructure complete

---

## What Needs To Be Done

### Phase 1: Update FontDatabase (START HERE)

**File:** [`lib/fontist/import/google/font_database.rb`](lib/fontist/import/google/font_database.rb:1)

Add these three methods:

```ruby
# Get current git commit from google/fonts repo
def current_commit_id
  return @commit_id if @commit_id

  if @source_path && File.directory?(@source_path)
    @commit_id = get_git_commit(@source_path)
  end

  @commit_id
end

private

def get_git_commit(path)
  Dir.chdir(path) do
    `git rev-parse HEAD`.strip
  rescue StandardError => e
    Fontist.ui.error("Failed to get git commit: #{e.message}")
    nil
  end
end

def last_modified_for(family)
  # Extract from API metadata or use current time
  Time.now.utc.iso8601
end
```

Then update the `to_formula` method to create and pass import_source:

```ruby
def to_formula(family_name, output_dir: nil)
  family = font_by_name(family_name)

  # Create import source
  import_source = Fontist::GoogleImportSource.new(
    commit_id: current_commit_id,
    api_version: "v1",
    last_modified: last_modified_for(family),
    family_id: family.name.downcase.tr(" ", "_")
  )

  Fontist::Import::GoogleFontsImporter.new(
    font_family: family,
    output_path: output_dir,
    import_source: import_source  # NEW: pass import_source
  ).import
end
```

### Phase 2: Update GoogleFontsImporter

**File:** [`lib/fontist/import/google_fonts_importer.rb`](lib/fontist/import/google_fonts_importer.rb:1)

1. Accept import_source in constructor:

```ruby
def initialize(font_family:, output_path: nil, import_source: nil)
  @font_family = font_family
  @output_path = output_path
  @import_source = import_source  # NEW
end
```

2. Pass to CreateFormula:

```ruby
Fontist::Import::CreateFormula.new(
  url_or_path,
  name: formula_name,
  platforms: ["google"],
  import_source: @import_source  # NEW
).call
```

3. Update filename strategy for versioning:

```ruby
def formula_filename
  name = @font_family.name.downcase.tr(" ", "_")
  differentiation = @import_source&.differentiation_key

  if differentiation
    "#{name}_#{differentiation}.yml"
  else
    "#{name}.yml"  # Fallback for API-only mode
  end
end
```

### Phase 3-7: Testing, Documentation, etc.

See [`GOOGLE_FONTS_IMPORT_SOURCE_IMPLEMENTATION_PLAN.md`](GOOGLE_FONTS_IMPORT_SOURCE_IMPLEMENTATION_PLAN.md:1) for complete details.

---

## Verification Steps

After each phase:

1. Run tests:
   ```bash
   bundle exec rspec --format progress
   ```

2. Test formula generation:
   ```bash
   bundle exec exe/fontist import google \
     --font-family "Roboto" \
     --source-path /path/to/google/fonts \
     --output-path /tmp/test_formulas
   ```

3. Verify generated formula has import_source:
   ```bash
   cat /tmp/test_formulas/roboto_*.yml | grep -A5 "import_source:"
   ```

---

## Important Principles

**From project rules:**
- ALWAYS be fully object-oriented
- ALWAYS ensure MECE (Mutually Exclusive, Collectively Exhaustive)
- ALWAYS prioritize architectural solutions over hacks
- NEVER hardcode - use configuration and metadata
- Correctness of architecture is paramount
- Tests may need updating to match correct behavior

**Specific to this task:**
- import_source is OPTIONAL (backward compatible)
- commit_id can be nil (API-only mode)
- Differentiation key is short commit (7 chars)
- All changes must maintain existing functionality

---

## Success Criteria

- ✅ All 737 tests still passing (+ new tests)
- ✅ Google Fonts formulas include import_source
- ✅ Versioned filenames use commit_id
- ✅ API-only mode still works (commit_id = nil)
- ✅ Update detection works via outdated?()
- ✅ Documentation updated with examples

---

## Files to Modify

**Core (Phases 1-3):**
- `lib/fontist/import/google/font_database.rb`
- `lib/fontist/import/google_fonts_importer.rb`

**Tests (Phase 5):**
- `spec/fontist/import/google_fonts_importer_spec.rb`
- `spec/fontist/import/google/font_database_spec.rb`

**Documentation (Phase 7):**
- `README.adoc` (add examples)

---

## Start Here

1. Read [`GOOGLE_FONTS_IMPORT_SOURCE_IMPLEMENTATION_PLAN.md`](GOOGLE_FONTS_IMPORT_SOURCE_IMPLEMENTATION_PLAN.md:1)
2. Update [`GOOGLE_FONTS_IMPORT_SOURCE_STATUS.md`](GOOGLE_FONTS_IMPORT_SOURCE_STATUS.md:1) as you progress
3. Begin with Phase 1: Update FontDatabase
4. Run tests after each change
5. Move through phases sequentially

---

## Questions?

Refer to:
- Import source architecture: [`docs/import-source-architecture.md`](docs/import-source-architecture.md:1)
- Existing GoogleImportSource tests: [`spec/fontist/google_import_source_spec.rb`](spec/fontist/google_import_source_spec.rb:1)
- macOS implementation example: [`lib/fontist/import/macos.rb`](lib/fontist/import/macos.rb:1)

The architecture is correct and complete. This is just wiring up the importer to use it.