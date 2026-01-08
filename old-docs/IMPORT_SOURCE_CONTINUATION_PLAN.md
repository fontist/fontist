# Import Source Full Implementation - Continuation Plan

**Date:** 2025-12-29
**Status:** In Progress
**Focus:** Complete Google Fonts and SIL import_source implementation with real repository testing

**Repository Locations:**
- Google Fonts: `/Users/mulgogi/src/external/google-fonts/` ✅
- Formula Repo: `/Users/mulgogi/src/fontist/formulas`

---

## Overview

Complete the import_source architecture by:
1. Testing Google Fonts import with actual formula repository
2. Implementing SIL import_source support
3. Updating CLI commands to use import_source
4. Generating production formulas with import_source metadata

---

## Phase 1: Google Fonts Formula Repository Testing ⏳

### Objective
Test the Google Fonts import_source implementation with the actual formula repository at `/Users/mulgogi/src/fontist/formulas`.

### Tasks

1. **Verify google/fonts repository availability**
   - Repository is at: `/Users/mulgogi/src/external/google-fonts/` ✅
   - Check status: `cd /Users/mulgogi/src/external/google-fonts && git status`
   - Update if needed: `git pull`

2. **Test import_source creation**
   ```bash
   cd /Users/mulgogi/src/fontist/fontist
   bundle exec exe/fontist import google \
     --font-family "Roboto Flex" \
     --source-path /Users/mulgogi/src/external/google-fonts \
     --output-path /tmp/test_formulas \
     --verbose
   ```

3. **Verify generated formula**
   - Check for `import_source` section
   - Verify `commit_id` is present
   - Verify versioned filename (e.g., `roboto_flex_abc1234.yml`)

4. **Test bulk import**
   ```bash
   # Import multiple fonts to verify consistency
   bundle exec exe/fontist import google \
     --source-path /Users/mulgogi/src/external/google-fonts \
     --output-path /tmp/test_formulas \
     --verbose
   ```

5. **Verify output structure**
   - All formulas have import_source
   - All use versioned filenames
   - commit_id is consistent across all formulas

**Expected Result:**
```yaml
name: roboto_flex
description: Roboto Flex font family
import_source:
  type: google
  commit_id: "<40-char-sha>"
  api_version: "v1"
  last_modified: "2025-XX-XX"
  family_id: "roboto_flex"
resources:
  # ... resources ...
```

**Duration:** 2 hours

---

## Phase 2: SIL Import Source Implementation ⏳

### Objective
Implement import_source support for SIL fonts using the same architecture pattern.

### 2.1 SIL Import Source Class

**File:** [`lib/fontist/sil_import_source.rb`](lib/fontist/sil_import_source.rb:1)

Already exists - verify implementation:

```ruby
class SilImportSource < ImportSource
  attribute :version, :string
  attribute :release_date, :string

  key_value do
    map "type", to: :type, default: -> { "sil" }
    map "version", to: :version
    map "release_date", to: :release_date
  end

  def differentiation_key
    version
  end

  def outdated?(new_source)
    return false unless new_source.is_a?(SilImportSource)
    Gem::Version.new(version) < Gem::Version.new(new_source.version)
  end
end
```

**Status:** Already implemented ✅

### 2.2 Update SIL Importer

**File:** [`lib/fontist/import/sil_import.rb`](lib/fontist/import/sil_import.rb:1)

Add methods to create import_source:

```ruby
def create_import_source(font_info)
  return nil unless font_info[:version] && font_info[:release_date]

  Fontist::SilImportSource.new(
    version: font_info[:version],
    release_date: font_info[:release_date]
  )
end

def extract_version(font_data)
  # Extract version from font metadata or URL
  # Implementation depends on SIL font structure
end

def extract_release_date(font_data)
  # Extract release date from metadata
  # Fallback to current date if not available
  Time.now.utc.iso8601
end
```

Update formula generation to include import_source:

```ruby
def generate_formula(font_data)
  import_source = create_import_source(font_data)

  formula = {
    name: font_data[:name],
    description: font_data[:description],
    # ... other fields ...
  }

  formula[:import_source] = import_source if import_source
  formula
end
```

**Duration:** 3 hours

### 2.3 Add Versioned Filenames for SIL

Update save logic to use differentiation_key:

```ruby
def formula_filename(font_name, import_source)
  base_name = font_name.downcase.gsub(/\s+/, '_')

  if import_source&.differentiation_key
    "#{base_name}_#{import_source.differentiation_key}.yml"
  else
    "#{base_name}.yml"
  end
end
```

**Duration:** 1 hour

---

## Phase 3: CLI Integration ⏳

### Objective
Update CLI commands to properly use import_source features.

### 3.1 Google Fonts CLI

**File:** [`lib/fontist/import_cli.rb`](lib/fontist/import_cli.rb:1)

Verify google command passes source_path:

```ruby
desc "google", "Import Google Fonts"
option :font_family, type: :string, desc: "Specific font family to import"
option :source_path, type: :string, desc: "Path to google/fonts repository"
option :output_path, type: :string, desc: "Output directory for formulas"
option :verbose, type: :boolean, default: false

def google
  require_relative "import/google_fonts_importer"

  Fontist::Import::GoogleFontsImporter.new(
    api_key: ENV["GOOGLE_FONTS_API_KEY"],
    source_path: options[:source_path],  # ✅ Already passing
    output_path: options[:output_path] || "./Formulas/google",
    font_family: options[:font_family],
    verbose: options[:verbose]
  ).import
end
```

**Status:** Verify implementation ✅

### 3.2 SIL CLI

Update SIL import command if needed to support import_source.

**Duration:** 1 hour

---

## Phase 4: Testing and Validation ⏳

### 4.1 Unit Tests

Add tests for SIL import_source:

**File:** `spec/fontist/import/sil_import_spec.rb`

```ruby
describe "SIL import_source integration" do
  it "creates import_source for SIL fonts" do
    font_data = {
      name: "Charis SIL",
      version: "6.200",
      release_date: "2024-01-01"
    }

    import_source = @importer.create_import_source(font_data)

    expect(import_source).to be_a(Fontist::SilImportSource)
    expect(import_source.version).to eq("6.200")
    expect(import_source.release_date).to eq("2024-01-01")
  end

  it "generates versioned filenames" do
    filename = @importer.formula_filename(
      "Charis SIL",
      SilImportSource.new(version: "6.200")
    )

    expect(filename).to eq("charis_sil_6.200.yml")
  end
end
```

### 4.2 Integration Tests

Test complete flow:

```bash
# Google Fonts
bundle exec exe/fontist import google \
  --font-family "Roboto" \
  --source-path /Users/mulgogi/src/external/google-fonts \
  --output-path /tmp/test

# SIL Fonts
bundle exec exe/fontist import sil \
  --output-path /tmp/test

# Verify all formulas have import_source
find /tmp/test -name "*.yml" -exec grep -L "import_source:" {} \;
```

**Duration:** 2 hours

---

## Phase 5: Production Formula Generation ⏳

### Objective
Generate production formulas with import_source for the formula repository.

### 5.1 Google Fonts Production Import

```bash
cd /Users/mulgogi/src/fontist/formulas

# Back up existing formulas
cp -r Formulas/google Formulas/google.backup

# Generate new formulas with import_source
cd /Users/mulgogi/src/fontist/fontist
bundle exec exe/fontist import google \
  --source-path /Users/mulgogi/src/external/google-fonts \
  --output-path /Users/mulgogi/src/fontist/formulas/Formulas/google \
  --verbose
```

### 5.2 SIL Production Import

```bash
# Back up existing SIL formulas
cp -r Formulas/sil Formulas/sil.backup

# Generate new formulas
bundle exec exe/fontist import sil \
  --output-path /Users/mulgogi/src/fontist/formulas/Formulas/sil \
  --verbose
```

### 5.3 Validation

```bash
# Count formulas with import_source
cd /Users/mulgogi/src/fontist/formulas/Formulas/google
grep -l "import_source:" *.yml | wc -l

# Verify versioned filenames
ls -1 | grep -E "_[a-f0-9]{7}\.yml$" | wc -l

# Check for errors
grep -r "import_source: null" .
```

**Duration:** 2 hours

---

## Phase 6: Documentation Updates ⏳

### 6.1 Update README.adoc

Add examples showing import_source in formulas:

```adoc
====Formula with Import Source (Google Fonts)

Google Fonts formulas track the source repository commit:

[source,yaml]
----
name: roboto
import_source:
  type: google
  commit_id: "abc123def456..."
  api_version: "v1"
  last_modified: "2025-09-08"
  family_id: "roboto"
----

==== Formula with Import Source (SIL)

SIL formulas track version and release date:

[source,yaml]
----
name: charis_sil
import_source:
  type: sil
  version: "6.200"
  release_date: "2024-01-01"
----
```

### 6.2 CLI Documentation

Update CLI help with import_source examples:

```adoc
=== Google Fonts Import with Version Tracking

[source,bash]
----
fontist import google \
  --source-path /Users/mulgogi/src/external/google-fonts \
  --output-path ./formulas
----

This generates formulas with import_source tracking the git commit.
```

**Duration:** 1 hour

---

## Success Criteria

### Google Fonts
- ✅ All Google Fonts formulas include import_source
- ✅ All use versioned filenames (name_commit.yml)
- ✅ commit_id is valid 40-char SHA
- ✅ api_version is "v1"
- ✅ last_modified is ISO 8601 timestamp
- ✅ family_id matches normalized name

### SIL
- ✅ All SIL formulas include import_source
- ✅ All use versioned filenames (name_version.yml)
- ✅ version is semantic version string
- ✅ release_date is present

### General
- ✅ All tests passing
- ✅ Documentation updated
- ✅ Production formulas generated
- ✅ Backward compatibility maintained

---

## Timeline

**Total Estimate:** 12 hours compressed to 2 days

| Phase | Duration | Status |
|-------|----------|--------|
| 1. Google Fonts Testing | 2h | ⏳ Not Started |
| 2. SIL Implementation | 4h | ⏳ Not Started |
| 3. CLI Integration | 1h | ⏳ Not Started |
| 4. Testing | 2h | ⏳ Not Started |
| 5. Production Generation | 2h | ⏳ Not Started |
| 6. Documentation | 1h | ⏳ Not Started |

---

## Risk Mitigation

### Google Fonts Repository Out of Date
**Risk:** Repository may have old data
**Mitigation:** Run `git pull` before testing

### SIL Metadata Extraction
**Risk:** SIL fonts may not have structured version data
**Mitigation:** Fall back to manual version configuration or current date

### Formula Repository Breaking Changes
**Risk:** Changing filenames may break existing installations
**Mitigation:** Keep old formulas as backup, test thoroughly before commit

---

## Next Steps

1. **Immediate:** Test Google Fonts import with formula repository
2. **Short-term:** Implement SIL import_source
3. **Medium-term:** Generate all production formulas
4. **Long-term:** Add update checking utilities

---

## References

- **Architecture:** [`docs/import-source-architecture.md`](docs/import-source-architecture.md:1)
- **Google Implementation:** [`lib/fontist/import/google/font_database.rb`](lib/fontist/import/google/font_database.rb:1)
- **SIL Importer:** [`lib/fontist/import/sil_import.rb`](lib/fontist/import/sil_import.rb:1)
- **Formula Repo:** `/Users/mulgogi/src/fontist/formulas`
- **Google Fonts Repo:** `/Users/mulgogi/src/external/google-fonts/` ✅