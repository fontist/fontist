# Google Fonts Import Source Implementation Plan

**Date:** 2025-12-29
**Status:** Planning
**Priority:** High - Extends import_source to Google Fonts
**Context:** GoogleImportSource class exists but not used by importer

---

## Overview

Update the Google Fonts importer to create and use GoogleImportSource instances
when generating formulas, enabling version tracking and update detection for
Google Fonts.

---

## Current State

### ✅ Already Complete
- `GoogleImportSource` class created with lutaml-model polymorphism
- Polymorphic configuration in `ImportSource` and `Formula`
- Tests for GoogleImportSource (5 tests passing)
- Documentation in README.adoc and import-source-architecture.md

### ❌ Not Yet Implemented
- Google Fonts importer doesn't create import_source instances
- Generated formulas lack import_source metadata
- No commit tracking from google/fonts repository
- No update detection for Google Fonts formulas

---

## Architecture

### GoogleImportSource Attributes

```yaml
import_source:
  type: google
  commit_id: "abc123def456"       # GitHub commit SHA
  api_version: "v1"                # API version used
  last_modified: "2024-01-01T12:00:00Z"
  family_id: "roboto"              # Font family identifier
```

### Data Flow

```
GoogleFontsImporter.import
    ↓
FontDatabase.build_api_only(api_key)
    ↓
For each font family:
    ↓
  FontDatabase#to_formula(family_name)
      ↓
  Create GoogleImportSource with:
    - commit_id from git repo (if available)
    - api_version = "v1"
    - last_modified from API metadata
    - family_id = normalized family name
      ↓
  Pass to FormulaBuilder via import_source option
      ↓
  Formula saved with import_source
```

---

## Implementation Plan

### Phase 1: Update FontDatabase (2 hours)

#### 1.1 Add commit_id tracking

**File:** `lib/fontist/import/google/font_database.rb`

Add method to get current google/fonts commit:

```ruby
def current_commit_id
  return @commit_id if @commit_id

  # If source_path provided, get commit from git
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
```

#### 1.2 Add last_modified tracking

Extract from API metadata or use current time:

```ruby
def last_modified_for(family)
  # Try to get from API metadata
  metadata = @metadata_by_family[family.name]
  metadata&.dig("lastModified") || Time.now.utc.iso8601
end
```

#### 1.3 Update to_formula method

**Current:**
```ruby
def to_formula(family_name, output_dir: nil)
  # ... existing code ...
  Fontist::Import::GoogleFontsImporter.new(
    font_family: family,
    output_path: output_dir
  ).import
end
```

**New:**
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
    import_source: import_source
  ).import
end
```

---

### Phase 2: Update GoogleFontsImporter (1 hour)

#### 2.1 Accept import_source parameter

**File:** `lib/fontist/import/google_fonts_importer.rb`

```ruby
def initialize(font_family:, output_path: nil, import_source: nil)
  @font_family = font_family
  @output_path = output_path
  @import_source = import_source
end
```

#### 2.2 Pass to CreateFormula

```ruby
def import
  # ... existing download and extraction ...

  Fontist::Import::CreateFormula.new(
    url_or_path,
    name: formula_name,
    platforms: ["google"],
    homepage: homepage,
    requires_license_agreement: license,
    formula_dir: formula_dir,
    import_source: @import_source
  ).call
end
```

---

### Phase 3: Formula Directory Structure (1 hour)

#### 3.1 Versioned filenames

**Current:**
```
google/
  roboto.yml
  open_sans.yml
```

**New:**
```
google/
  roboto_abc123.yml      # abc123 = short commit_id
  open_sans_def456.yml
```

#### 3.2 Update formula_dir logic

```ruby
def formula_dir
  @formula_dir ||= if @custom_formulas_dir
                     Pathname.new(@custom_formulas_dir)
                   else
                     Fontist.formulas_path.join("google")
                   end.tap { |path| FileUtils.mkdir_p(path) }
end

def formula_filename
  name = @font_family.name.downcase.tr(" ", "_")
  differentiation = @import_source&.differentiation_key

  if differentiation
    "#{name}_#{differentiation}.yml"
  else
    "#{name}.yml"
  end
end
```

---

### Phase 4: CLI Integration (1 hour)

#### 4.1 Update import google command

**File:** `lib/fontist/import_cli.rb`

Ensure commit_id is captured when source_path is provided:

```ruby
def google
  # ... existing code ...

  importer = Fontist::Import::Google::FontDatabase.build(
    api_key: api_key,
    source_path: options[:source_path]  # Enables commit tracking
  )

  # ... rest of implementation ...
end
```

---

### Phase 5: Testing (2 hours)

#### 5.1 Update existing tests

**File:** `spec/fontist/import/google_fonts_importer_spec.rb`

Add tests for import_source:

```ruby
describe "with import_source" do
  it "includes import_source in generated formula" do
    import_source = Fontist::GoogleImportSource.new(
      commit_id: "abc123",
      api_version: "v1",
      last_modified: "2024-01-01T12:00:00Z",
      family_id: "roboto"
    )

    importer = described_class.new(
      font_family: font_family,
      import_source: import_source
    )

    formula_path = importer.import
    formula = Fontist::Formula.from_file(formula_path)

    expect(formula.import_source).to be_a(Fontist::GoogleImportSource)
    expect(formula.import_source.commit_id).to eq("abc123")
  end
end
```

#### 5.2 Integration tests

Test complete flow from FontDatabase to formula file:

```ruby
describe "Google Fonts import with source tracking" do
  it "generates formulas with import_source from git repo" do
    # Assuming google/fonts repo is available
    db = Fontist::Import::Google::FontDatabase.build(
      api_key: ENV["GOOGLE_FONTS_API_KEY"],
      source_path: "/path/to/google/fonts"
    )

    formula_path = db.to_formula("Roboto")
    formula = Fontist::Formula.from_file(formula_path)

    expect(formula.import_source).to be_a(Fontist::GoogleImportSource)
    expect(formula.import_source.commit_id).to match(/^[a-f0-9]{40}$/)
    expect(formula.import_source.api_version).to eq("v1")
  end
end
```

---

### Phase 6: Update Detection (1 hour)

#### 6.1 Implement outdated? logic

Already implemented in GoogleImportSource:

```ruby
def outdated?(new_source)
  return false unless new_source.is_a?(GoogleImportSource)
  commit_id != new_source.commit_id
end
```

#### 6.2 Add update checking utility

Create helper to check if Google Fonts formulas need updating:

```ruby
# In lib/fontist/import/google_fonts_importer.rb or new file

def self.check_updates(source_path:, api_key:)
  db = FontDatabase.build(api_key: api_key, source_path: source_path)
  current_commit = db.current_commit_id

  outdated_formulas = []

  Dir.glob(Fontist.formulas_path.join("google/*.yml")).each do |path|
    formula = Fontist::Formula.from_file(path)
    next unless formula.google_import?

    if formula.import_source.commit_id != current_commit
      outdated_formulas << formula.name
    end
  end

  outdated_formulas
end
```

---

### Phase 7: Documentation Updates (1 hour)

#### 7.1 Update README usage examples

Add example showing import_source in Google Fonts formulas:

```adoc
==== Google Fonts with Import Source

Google Fonts formulas track the source repository commit for version control:

[source,yaml]
----
name: Roboto
platforms:
  - google
import_source:
  type: google
  commit_id: "abc123def456"
  api_version: "v1"
  last_modified: "2024-01-01T12:00:00Z"
  family_id: "roboto"
resources:
  # ...
----
```

#### 7.2 Update import guide

Document how commit tracking works and benefits.

---

## Success Criteria

### Implementation
- ✅ GoogleFontsImporter creates import_source instances
- ✅ Formulas include import_source with commit_id
- ✅ Versioned filenames based on commit_id
- ✅ API version tracked
- ✅ Last modified timestamp captured

### Testing
- ✅ All existing tests still pass
- ✅ New tests for import_source creation
- ✅ Integration tests with real git repo
- ✅ Update detection tests

### Documentation
- ✅ README examples updated
- ✅ Architecture docs reflect Google Fonts usage
- ✅ CLI help text updated if needed

---

## Timeline

**Total:** 9 hours compressed to 1-2 days

1. Phase 1: FontDatabase updates (2h)
2. Phase 2: GoogleFontsImporter updates (1h)
3. Phase 3: Directory structure (1h)
4. Phase 4: CLI integration (1h)
5. Phase 5: Testing (2h)
6. Phase 6: Update detection (1h)
7. Phase 7: Documentation (1h)

---

## Notes

### Backward Compatibility

Existing Google Fonts formulas without import_source will continue to work.
The import_source is optional and defaults to nil.

### Commit ID Availability

- With source_path: Full commit SHA from git
- Without source_path (API-only): commit_id will be nil
- Formula generation still works without commit_id

### Version Differentiation

Short commit ID (first 7 chars) used for filenames to avoid collision and
maintain readability:

```ruby
def differentiation_key
  commit_id&.slice(0, 7)
end
```

---

## Related Files

**Core:**
- `lib/fontist/google_import_source.rb` (already exists)
- `lib/fontist/import/google/font_database.rb` (needs update)
- `lib/fontist/import/google_fonts_importer.rb` (needs update)

**Tests:**
- `spec/fontist/google_import_source_spec.rb` (already complete)
- `spec/fontist/import/google_fonts_importer_spec.rb` (needs update)
- `spec/fontist/import/google/font_database_spec.rb` (needs new tests)

**Documentation:**
- `README.adoc` (add examples)
- `docs/import-source-architecture.md` (already complete)