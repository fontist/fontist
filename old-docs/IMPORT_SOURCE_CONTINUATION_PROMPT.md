# Import Source Full Implementation - Continuation Prompt

**Context:** The import_source architecture is complete for macOS and Google Fonts at the code level. Now we need to test it with real repositories and extend to SIL fonts.

**Status Files:**
- Plan: [`IMPORT_SOURCE_CONTINUATION_PLAN.md`](IMPORT_SOURCE_CONTINUATION_PLAN.md:1)
- Status: [`IMPORT_SOURCE_CONTINUATION_STATUS.md`](IMPORT_SOURCE_CONTINUATION_STATUS.md:1)
- Architecture: [`docs/import-source-architecture.md`](docs/import-source-architecture.md:1)

**Repository Locations:**
- Google Fonts: `/Users/mulgogi/src/external/google-fonts/` ✅
- Formula Repo: `/Users/mulgogi/src/fontist/formulas`

---

## Current State

### ✅ Complete
- GoogleImportSource class fully implemented
- FontDatabase creates import_source instances
- Simple filename strategy (Google Fonts is a live service)
- All 750 tests passing
- Documentation updated
- google/fonts repository available

### ⏳ Needs Work
- Test with real google/fonts repository
- Implement SIL importer integration
- Generate production formulas with import_source
- Update README with real examples

---

## Your Task

Complete the import_source implementation by testing Google Fonts with the real repository and implementing SIL support.

---

## Phase 1: Test Google Fonts Import (START HERE)

### Step 1: Verify google/fonts Repository

```bash
# Repository is at:
ls -la /Users/mulgogi/src/external/google-fonts/

# Verify it's a git repository
cd /Users/mulgogi/src/external/google-fonts/
git status

# Get current commit
git rev-parse HEAD
```

### Step 2: Test Single Font Import

```bash
cd /Users/mulgogi/src/fontist/fontist

bundle exec exe/fontist import google \
  --font-family "Roboto" \
  --source-path /Users/mulgogi/src/external/google-fonts \
  --output-path /tmp/test_formulas \
  --verbose
```

**Expected Output:**
- Formula file created: `/tmp/test_formulas/roboto.yml` (simple filename)
- File contains `import_source:` section
- `commit_id` is 40-char SHA
- Filename is simple (Google Fonts is a live service, no versioning)

### Step 3: Verify Formula Structure

```bash
# Check the generated formula
cat /tmp/test_formulas/roboto.yml

# Should contain:
# import_source:
#   type: google
#   commit_id: "<40-char-sha>"
#   api_version: "v1"
#   last_modified: "2025-XX-XX"
#   family_id: "roboto"
```

### Step 4: Test Multiple Fonts

```bash
# Import a few more fonts to verify consistency
bundle exec exe/fontist import google \
  --font-family "Open Sans" \
  --source-path /Users/mulgogi/src/external/google-fonts \
  --output-path /tmp/test_formulas \
  --verbose

bundle exec exe/fontist import google \
  --font-family "Lato" \
  --source-path /Users/mulgogi/src/external/google-fonts \
  --output-path /tmp/test_formulas \
  --verbose
```

### Step 5: Verify Consistency

```bash
# All should have the same commit_id
grep "commit_id:" /tmp/test_formulas/*.yml

# All should have simple filenames (no versioning)
ls -1 /tmp/test_formulas/
# Expected: roboto.yml, open_sans.yml, lato.yml
```

**Success Criteria:**
- ✅ All formulas have import_source
- ✅ All use same commit_id
- ✅ All use simple filenames (name.yml)
- ✅ No errors during import

---

## Phase 2: Implement SIL Import Source

### Files to Modify

1. **[`lib/fontist/import/sil_import.rb`](lib/fontist/import/sil_import.rb:1)** - Main importer
2. **[`spec/fontist/import/sil_import_spec.rb`](spec/fontist/import/sil_import_spec.rb:1)** - Tests

### Required Changes

#### Add to SilImport class:

```ruby
def create_import_source(font_data)
  return nil unless font_data[:version]

  Fontist::SilImportSource.new(
    version: font_data[:version] || extract_version(font_data),
    release_date: font_data[:release_date] || extract_release_date(font_data)
  )
end

def extract_version(font_data)
  # Extract from font metadata or URL
  # SIL fonts typically have version in filename or metadata
  font_data[:filename]&.match(/v?(\d+\.\d+\.\d+)/i)&.captures&.first || "1.0.0"
end

def extract_release_date(font_data)
  # Use current date as fallback
  Time.now.utc.iso8601
end

def formula_filename(font_name, import_source)
  base_name = font_name.downcasegsub(/\s+/, '_')

  if import_source&.differentiation_key
    "#{base_name}_#{import_source.differentiation_key}.yml"
  else
    "#{base_name}.yml"
  end
end
```

#### Update formula generation:

```ruby
def build_formula(font_data)
  import_source = create_import_source(font_data)

  formula = {
    name: normalize_name(font_data[:name]),
    description: font_data[:description],
    # ... existing fields ...
  }

  formula[:import_source] = import_source if import_source

  filename = formula_filename(font_data[:name], import_source)

  save_formula(formula, filename)
end
```

### Add Tests

```ruby
describe "SIL import_source integration" do
  it "creates import_source for SIL fonts" do
    font_data = { version: "6.200", release_date: "2024-01-01" }
    source = @importer.create_import_source(font_data)

    expect(source).to be_a(Fontist::SilImportSource)
    expect(source.version).to eq("6.200")
  end

  it "generates versioned filenames" do
    source = Fontist::SilImportSource.new(version: "6.200")
    filename = @importer.formula_filename("Charis SIL", source)

    expect(filename).to eq("charis_sil_6.200.yml")
  end

  it "extracts version from font data" do
    font_data = { filename: "CharisSIL-6.200.ttf" }
    version = @importer.extract_version(font_data)

    expect(version).to eq("6.200")
  end
end
```

**Run Tests:**

```bash
bundle exec rspec spec/fontist/import/sil_import_spec.rb
```

---

## Phase 3: Generate Production Formulas

### Google Fonts

```bash
cd /Users/mulgogi/src/fontist/formulas

# Backup existing formulas
cp -r Formulas/google Formulas/google.backup.$(date +%Y%m%d)

# Generate new formulas (THIS WILL TAKE TIME - ~2000 fonts)
cd /Users/mulgogi/src/fontist/fontist
bundle exec exe/fontist import google \
  --source-path /Users/mulgogi/src/external/google-fonts \
  --output-path /Users/mulgogi/src/fontist/formulas/Formulas/google \
  --verbose

# Verify results
cd /Users/mulgogi/src/fontist/formulas/Formulas/google
echo "Formulas with import_source:"
grep -l "import_source:" *.yml | wc -l

echo "All filenames are simple (no versioning):"
ls -1 *.yml | head -10
```

### SIL Fonts

```bash
cd /Users/mulgogi/src/fontist/formulas

# Backup existing formulas
cp -r Formulas/sil Formulas/sil.backup.$(date +%Y%m%d)

# Generate new formulas
cd /Users/mulgogi/src/fontist/fontist
bundle exec exe/fontist import sil \
  --output-path /Users/mulgogi/src/fontist/formulas/Formulas/sil \
  --verbose

# Verify results
cd /Users/mulgogi/src/fontist/formulas/Formulas/sil
echo "Formulas with import_source:"
grep -l "import_source:" *.yml | wc -l
```

---

## Phase 4: Update Documentation

### Update README.adoc

Add examples showing import_source in formulas:

```adoc
==== Google Fonts with Import Source

Google Fonts formulas track the source repository commit:

[source,yaml]
----
name: roboto
description: Roboto font family
import_source:
  type: google
  commit_id: "abc123def456789..."
  api_version: "v1"
  last_modified: "2025-09-08"
  family_id: "roboto"
resources:
  # ... resources ...
----

Note: Google Fonts formulas use simple filenames (roboto.yml) because
Google Fonts is a live service that always points to the latest version.
The commit_id is tracked for metadata and update detection only.

==== Importing Google Fonts with Version Tracking

[source,bash]
----
fontist import google \
  --source-path /Users/mulgogi/src/external/google-fonts \
  --output-path ./formulas
----
```

---

## Verification Checklist

Before completing, verify:

### Google Fonts
- [ ] Test import works with google/fonts repository at `/Users/mulgogi/src/external/google-fonts/`
- [ ] Generated formulas have import_source section
- [ ] All use simple filenames (name.yml) - no versioning
- [ ] commit_id is valid 40-char SHA
- [ ] All formulas in production repo updated

### SIL
- [ ] SilImport creates import_source instances
- [ ] Version extraction works
- [ ] Versioned filenames generated (name_version.yml)
- [ ] Tests added and passing
- [ ] Production formulas updated

### General
- [ ] All tests still passing (750+)
- [ ] README updated with examples
- [ ] Status files updated
- [ ] No regressions

---

## Important Notes

### Google Fonts Filename Strategy
- **Always simple:** `roboto.yml`, `open_sans.yml`, etc.
- **No versioning:** Google Fonts is a live service (always latest)
- **commit_id tracked:** For metadata and update detection only
- **Filenames stay consistent:** Easy to find and manage

### google/fonts Repository
- Location: `/Users/mulgomi/src/external/google-fonts/`
- Already cloned and available ✅
- Should be up to date (check with `git pull`)

### API Key Required
- Google Fonts API: `GOOGLE_FONTS_API_KEY` environment variable
- Get key from: https://developers.google.com/fonts/docs/developer_api

### Backup Strategy
- Always backup existing formulas before regenerating
- Use dated backups: `Formulas/google.backup.20251229`
- Keep backups until verified

### Testing Strategy
- Test with small number of fonts first
- Verify structure before bulk import
- Run all tests after each phase

---

## Success Criteria

When complete, you should be able to demonstrate:

1. **Google Fonts import with import_source:**
   ```bash
   fontist import google --source-path /Users/mulgogi/src/external/google-fonts
   # Generates: roboto.yml with import_source (simple filename)
   ```

2. **SIL import with import_source:**
   ```bash
   fontist import sil
   # Generates: charis_sil_6.200.yml with import_source (versioned filename)
   ```

3. **All tests passing:**
   ```bash
   bundle exec rspec
   # 750+ examples, 0 failures
   ```

4. **Production formulas updated:**
   ```bash
   cd /Users/mulgogi/src/fontist/formulas/Formulas/google
   grep -c "import_source:" *.yml
   # Should match total number of formulas
   ```

---

## Troubleshooting

### google/fonts Out of Date
Update it: `cd /Users/mulgogi/src/external/google-fonts && git pull`

### API Key Missing
Set it: `export GOOGLE_FONTS_API_KEY=your_key_here`

### Import Fails
Check logs with `--verbose` flag and verify repository structure

### Tests Fail
Review test output, may need to update test expectations for new import_source fields

---

## Timeline

**Phase 1 (Testing):** 2 hours
**Phase 2 (SIL):** 4 hours
**Phase 3 (Production):** 2-4 hours (depends on font count)
**Phase 4 (Docs):** 1 hour

**Total:** ~9-11 hours

---

## References

- **Architecture:** [`docs/import-source-architecture.md`](docs/import-source-architecture.md:1)
- **Google Implementation:** [`lib/fontist/import/google/font_database.rb`](lib/fontist/import/google/font_database.rb:1)
- **SIL Importer:** [`lib/fontist/import/sil_import.rb`](lib/fontist/import/sil_import.rb:1)
- **SIL Import Source:** [`lib/fontist/sil_import_source.rb`](lib/fontist/sil_import_source.rb:1)
- **Google Fonts Repo:** `/Users/mulgogi/src/external/google-fonts/`
- **Formula Repo:** `/Users/mulgogi/src/fontist/formulas`