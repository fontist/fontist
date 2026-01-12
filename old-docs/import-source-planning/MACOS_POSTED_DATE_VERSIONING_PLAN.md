# macOS PostedDate-Based Versioning - Corrected Implementation Plan

**Date**: 2025-12-26
**Status**: Ready for Implementation
**Complexity**: High
**Files to Modify**: 10 files
**Critical Fix**: Removes incorrect font_version approach, implements proper catalog versioning

---

## Executive Summary

### What Went Wrong ❌

The previous implementation added a `font_version` attribute that extracted version numbers from individual font files using Fontisan. This approach was fundamentally flawed because:

1. **Font file versions** are metadata within files, not catalog update indicators
2. **Multiple files** in a package (TTC/OTC) have different version numbers
3. **Doesn't identify** which macOS package a formula belongs to
4. **Doesn't solve** update detection or prevent unnecessary reinstallations
5. **Wrong granularity** - versions are per-file, but formulas represent entire packages

### Correct Approach ✅

Use the `PostedDate` field from Apple's MobileAsset catalog XML:

1. **PostedDate** indicates when the catalog was published/updated (e.g., "2024-08-13T18:11:00Z")
2. **One formula** = One macOS supplementary font package
3. **Package identity** tracked via Build/MasteredVersion (e.g., "10M1360", "1360")
4. **Source tracking** identifies formula origin (manual/google/macos/sil)
5. **Versioned filenames** prevent conflicts between package versions
6. **Update detection** only reinstalls if PostedDate is newer

---

## PostedDate Field Discovery

### Location in Catalog XMLs

```xml
<!-- Font7 Catalog -->
<key>postedDate</key>
<date>2024-08-13T18:11:00Z</date>

<!-- Font8 Catalog -->
<key>postedDate</key>
<date>2025-08-05T18:58:57Z</date>

<!-- Font6 Catalog -->
<key>postedDate</key>
<date>2021-06-10T23:37:57Z</date>
```

**XML Path**: At root dict level, sibling to "Assets" key
**Format**: ISO 8601 date string with timezone
**Purpose**: Indicates when catalog was published by Apple

### Sample XML Structure

```xml
<plist version="1.0">
<dict>
  <key>Assets</key>
  <array>
    <!-- Asset entries... -->
  </array>
  <key>ClientVersion</key>
  <integer>2</integer>
  <key>contentVersion</key>
  <date>2025-12-22T11:52:09Z</date>
  <key>postedDate</key>
  <date>2025-08-05T18:58:57Z</date>
</dict>
</plist>
```

---

## Asset Package Identity

Each macOS font package has multiple identifiers:

### Available Identifiers

1. **Build** (e.g., "10M1360", "10M1044")
   - Appears to be unique per package version
   - Format: `\d+M\d+`
   - Most human-readable

2. **_MasteredVersion** (e.g., "1360", "1044")
   - Integer version number
   - Shorter than Build
   - May not be unique across catalogs

3. **_CompatibilityVersion** (e.g., 1, 2)
   - Compatibility level indicator
   - Not unique enough for package identity

4. **__RelativePath** (e.g., "701405507c8753373648c7a6541608e32ed089ec")
   - Hash of asset path
   - Unique but not human-readable

### Recommended: Use Build

**Rationale**:
- Unique per package version
- Human-readable format
- Appears in Apple documentation
- Easy to encode in filename

**Example**: `al_bayan_10m1360.yml`

---

## Implementation Plan

### Phase 1: Rollback Incorrect Implementation

#### 1.1 Remove font_version from Formula
**File**: `lib/fontist/formula.rb`

**Remove**:
```ruby
# Line 77
attribute :font_version, :string

# Line 104 (in key_value mapping)
map "font_version", to: :font_version
```

#### 1.2 Remove from FormulaBuilder
**File**: `lib/fontist/import/formula_builder.rb`

**Remove**:
```ruby
# Line 13 (from FORMULA_ATTRIBUTES)
:font_version,

# Line 24 (attr_writer)
:font_version,

# Line 56 (getter method)
def font_version
  @font_version
end
```

#### 1.3 Remove from CreateFormula
**File**: `lib/fontist/import/create_formula.rb`

**Remove**:
```ruby
# Lines 36-44 (extract_font_version method usage)
font_version = extract_font_version(extracted_fonts)

# Lines 76-93 (extract_font_version method definition)
def extract_font_version(fonts)
  # ... entire method
end

# Remove from options passed to FormulaBuilder
font_version: font_version,
```

#### 1.4 Remove from README
**File**: `README.adoc`

**Remove**: Any references to `font_version` attribute in formula documentation

---

### Phase 2: Add PostedDate Support

#### 2.1 Extract PostedDate in BaseParser
**File**: `lib/fontist/macos/catalog/base_parser.rb`

**Add method**:
```ruby
def posted_date
  # Extract postedDate from catalog root dict
  date_str = data["postedDate"]
  return nil unless date_str
  
  # Parse ISO 8601 date string
  Time.parse(date_str).utc.iso8601
rescue StandardError => e
  Fontist.ui.warn("Could not parse postedDate: #{e.message}")
  nil
end
```

**Update assets method** to pass posted_date:
```ruby
def assets
  date = posted_date
  parse_assets.map { |asset_data| Asset.new(asset_data, posted_date: date) }
end
```

#### 2.2 Update Asset to Accept PostedDate
**File**: `lib/fontist/macos/catalog/asset.rb`

**Update constructor**:
```ruby
attr_reader :base_url, :relative_path, :font_info, :build,
            :compatibility_version, :design_languages, :prerequisite,
            :posted_date  # NEW

def initialize(data, posted_date: nil)
  @base_url = data["__BaseURL"]
  @relative_path = data["__RelativePath"]
  @font_info = data["FontInfo4"] || []
  @build = data["Build"]
  @compatibility_version = data["_CompatibilityVersion"]
  @design_languages = data["FontDesignLanguages"] || []
  @prerequisite = data["Prerequisite"] || []
  @posted_date = posted_date  # NEW
end
```

**Add package identity method**:
```ruby
# Returns unique package identifier for formula filename
def package_identifier
  # Use Build as primary identifier (e.g., "10M1360")
  return build.downcase if build
  
  # Fallback to hash of relative path
  require 'digest'
  Digest::SHA256.hexdigest(@relative_path)[0..15]
end
```

---

### Phase 3: Add New Formula Attributes

#### 3.1 Update Formula Model
**File**: `lib/fontist/formula.rb`

**Add attributes** (after line 76):
```ruby
# Catalog and package versioning
attribute :posted_date, :string        # Catalog publication date (ISO 8601)
attribute :source, :string             # Formula source: manual/google/macos/sil
attribute :macos_asset_id, :string     # macOS package identifier (e.g., Build)
```

**Add key_value mappings** (after line 103):
```ruby
map "posted_date", to: :posted_date
map "source", to: :source
map "macos_asset_id", to: :macos_asset_id
```

**Add validation method**:
```ruby
# Check if formula is outdated based on posted_date
def outdated?(new_posted_date)
  return false unless posted_date && new_posted_date
  
  Time.parse(posted_date) < Time.parse(new_posted_date)
rescue StandardError
  false
end

# Check if formula is from macOS import
def macos_formula?
  source == "macos"
end
```

---

### Phase 4: Update FormulaBuilder

#### 4.1 Add New Attributes to Builder
**File**: `lib/fontist/import/formula_builder.rb`

**Update FORMULA_ATTRIBUTES** (line 13):
```ruby
FORMULA_ATTRIBUTES = %i[
  name
  description
  homepage
  resources
  fonts
  extract
  instructions
  options
  requires_license_agreement
  open_license
  license_url
  license_required
  copyright
  digest
  command
  catalog_version
  min_macos_version
  max_macos_version
  posted_date      # NEW
  source           # NEW
  macos_asset_id   # NEW
].freeze
```

**Add attr_writers** (after line 23):
```ruby
attr_writer :catalog_version, :min_macos_version, :max_macos_version,
            :posted_date, :source, :macos_asset_id
```

**Add getter methods** (after line 55):
```ruby
def posted_date
  @posted_date
end

def source
  @source
end

def macos_asset_id
  @macos_asset_id
end
```

---

### Phase 5: Update CreateFormula

#### 5.1 Accept Package Metadata
**File**: `lib/fontist/import/create_formula.rb`

**Update constructor** to accept new options:
```ruby
def initialize(url, 
               options = {}, 
               archive_path: nil,
               formula_dir: nil,
               name: nil,
               skip_fonts: [],
               keep_existing: false,
               catalog_version: nil,
               min_macos_version: nil,
               max_macos_version: nil,
               posted_date: nil,        # NEW
               source: nil,             # NEW
               macos_asset_id: nil)     # NEW
  @url = url
  @options = options
  @archive_path = archive_path
  @formula_dir = formula_dir
  @given_name = name
  @skip_fonts = skip_fonts
  @keep_existing = keep_existing
  @catalog_version = catalog_version
  @min_macos_version = min_macos_version
  @max_macos_version = max_macos_version
  @posted_date = posted_date          # NEW
  @source = source                    # NEW
  @macos_asset_id = macos_asset_id    # NEW
end
```

**Pass to FormulaBuilder**:
```ruby
builder.catalog_version = @catalog_version if @catalog_version
builder.min_macos_version = @min_macos_version if @min_macos_version
builder.max_macos_version = @max_macos_version if @max_macos_version
builder.posted_date = @posted_date if @posted_date        # NEW
builder.source = @source || "manual"                       # NEW (default to manual)
builder.macos_asset_id = @macos_asset_id if @macos_asset_id  # NEW
```

**Remove** extract_font_version method (lines 76-93)

---

### Phase 6: Update Macos Importer

#### 6.1 Pass Package Metadata
**File**: `lib/fontist/import/macos.rb`

**Update process_asset method** (around line 82):
```ruby
path = Fontist::Import::CreateFormula.new(
  asset.download_url,
  platforms: platforms,
  homepage: homepage,
  requires_license_agreement: license,
  formula_dir: formula_dir,
  keep_existing: !@force,
  catalog_version: @catalog_version,
  min_macos_version: catalog_version_range[:min],
  max_macos_version: catalog_version_range[:max],
  posted_date: asset.posted_date,          # NEW
  source: "macos",                          # NEW
  macos_asset_id: asset.package_identifier, # NEW
).call
```

#### 6.2 Implement Versioned Filenames

**Add method to generate versioned filename**:
```ruby
def versioned_formula_name(asset, family_name)
  normalized_name = family_name.downcase.gsub(/[^a-z0-9]+/, '_')
  package_id = asset.package_identifier
  
  # Encode package version in filename
  "#{normalized_name}_#{package_id}.yml"
end
```

**Update expected_formula_path**:
```ruby
def expected_formula_path(asset, family_name)
  # Use versioned filename
  filename = versioned_formula_name(asset, family_name)
  formula_dir.join(filename)
rescue StandardError
  nil
end
```

---

### Phase 7: Update Other Importers

#### 7.1 Google Fonts Importer
**File**: `lib/fontist/import/google_fonts_importer.rb`

**Add source parameter**:
```ruby
Fontist::Import::CreateFormula.new(
  # ... existing parameters
  source: "google"  # NEW
).call
```

#### 7.2 SIL Importer
**File**: `lib/fontist/import/sil_import.rb`

**Add source parameter**:
```ruby
Fontist::Import::CreateFormula.new(
  # ... existing parameters
  source: "sil"  # NEW
).call
```

#### 7.3 Manual Creation
Formulas created manually or via `bin/convert_formulas` should default to `source: "manual"` (already handled in CreateFormula default)

---

### Phase 8: Add Update Detection Logic

#### 8.1 Add Update Check to Font Installation
**File**: `lib/fontist/font.rb`

**Add method**:
```ruby
private

def check_formula_updates(formula, new_posted_date)
  return unless formula.macos_formula?
  return unless new_posted_date
  
  if formula.outdated?(new_posted_date)
    Fontist.ui.say("📦 Newer version available (posted: #{new_posted_date})")
    Fontist.ui.say("   Current: #{formula.posted_date}")
    Fontist.ui.say("   Run 'fontist update' to refresh formulas")
  end
end
```

#### 8.2 Add Update Detection to CLI
**File**: `lib/fontist/cli.rb`

**Add check-updates command**:
```ruby
desc "check-updates", "Check for formula updates (macOS fonts)"
option :catalog_version, type: :numeric, desc: "Catalog version (7 or 8)"
def check_updates
  # Download latest catalog
  # Compare posted_date with existing formulas
  # Report outdated formulas
end
```

---

### Phase 9: Testing

#### 9.1 Unit Tests for PostedDate Extraction
**File**: `spec/fontist/macos/catalog/base_parser_spec.rb` (NEW)

```ruby
RSpec.describe Fontist::Macos::Catalog::BaseParser do
  describe "#posted_date" do
    it "extracts posted_date from Font7 catalog" do
      parser = described_class.new("com_apple_MobileAsset_Font7.xml")
      expect(parser.posted_date).to eq("2024-08-13T18:11:00Z")
    end
    
    it "extracts posted_date from Font8 catalog" do
      parser = described_class.new("com_apple_MobileAsset_Font8.xml")
      expect(parser.posted_date).to eq("2025-08-05T18:58:57Z")
    end
    
    it "returns nil if postedDate missing" do
      # Test with catalog without postedDate
    end
    
    it "handles invalid date format gracefully" do
      # Test with malformed date
    end
  end
end
```

#### 9.2 Unit Tests for Package Identity
**File**: `spec/fontist/macos/catalog/asset_spec.rb`

```ruby
describe "#package_identifier" do
  it "returns Build value if present" do
    asset = Asset.new({"Build" => "10M1360"})
    expect(asset.package_identifier).to eq("10m1360")
  end
  
  it "returns hash of relative path if Build missing" do
    asset = Asset.new({"__RelativePath" => "path/to/font.pkg"})
    expect(asset.package_identifier).to match(/^[a-f0-9]{16}$/)
  end
end
```

#### 9.3 Integration Tests for Formula Attributes
**File**: `spec/fontist/formula_spec.rb`

```ruby
describe "PostedDate versioning attributes" do
  it "loads posted_date from formula" do
    formula = Formula.from_file("macos/font7/al_bayan_10m1360.yml")
    expect(formula.posted_date).to eq("2024-08-13T18:11:00Z")
  end
  
  it "loads source from formula" do
    formula = Formula.from_file("macos/font7/al_bayan_10m1360.yml")
    expect(formula.source).to eq("macos")
  end
  
  it "loads macos_asset_id from formula" do
    formula = Formula.from_file("macos/font7/al_bayan_10m1360.yml")
    expect(formula.macos_asset_id).to eq("10m1360")
  end
end

describe "#outdated?" do
  it "detects outdated formula" do
    formula = Formula.new(posted_date: "2024-01-01T00:00:00Z")
    expect(formula.outdated?("2024-12-01T00:00:00Z")).to be true
  end
  
  it "returns false if dates equal" do
    date = "2024-12-01T00:00:00Z"
    formula = Formula.new(posted_date: date)
    expect(formula.outdated?(date)).to be false
  end
  
  it "returns false if posted_date missing" do
    formula = Formula.new(posted_date: nil)
    expect(formula.outdated?("2024-12-01T00:00:00Z")).to be false
  end
end

describe "#macos_formula?" do
  it "returns true for macOS formulas" do
    formula = Formula.new(source: "macos")
    expect(formula.macos_formula?).to be true
  end
  
  it "returns false for other sources" do
    formula = Formula.new(source: "google")
    expect(formula.macos_formula?).to be false
  end
end
```

#### 9.4 Integration Test for Macos Import
**File**: `spec/fontist/import/macos_spec.rb`

```ruby
describe "versioned filename generation" do
  it "generates filename with package identifier" do
    importer = Macos.new("Font7.xml")
    asset = double(package_identifier: "10m1360")
    filename = importer.send(:versioned_formula_name, asset, "Al Bayan")
    expect(filename).to eq("al_bayan_10m1360.yml")
  end
  
  it "normalizes family name properly" do
    importer = Macos.new("Font7.xml")
    asset = double(package_identifier: "10m1360")
    filename = importer.send(:versioned_formula_name, asset, "Adobe Arabic")
    expect(filename).to eq("adobe_arabic_10m1360.yml")
  end
end

describe "formula metadata" do
  it "sets source to macos" do
    # Import formula and verify source="macos"
  end
  
  it "sets posted_date from catalog" do
    # Import formula and verify posted_date matches catalog
  end
  
  it "sets macos_asset_id from Build" do
    # Import formula and verify macos_asset_id
  end
end
```

---

### Phase 10: Documentation

#### 10.1 Update README.adoc
**File**: `README.adoc`

**Add section on PostedDate versioning**:

```adoc
=== macOS Font Versioning

macOS supplementary font formulas use catalog-based versioning:

==== PostedDate Tracking

Each formula includes the catalog's `postedDate` to track updates:

[source,yaml]
----
name: Al Bayan
catalog_version: 7
min_macos_version: "10.11"
max_macos_version: "15.7"
posted_date: "2024-08-13T18:11:00Z"
source: "macos"
macos_asset_id: "10m1360"
----

Where:

`posted_date`:: Date when the catalog was published by Apple
`source`:: Formula source (manual/google/macos/sil)
`macos_asset_id`:: Unique package identifier from Build field

==== Versioned Filenames

Formula filenames include package identifiers to prevent conflicts:

[source]
----
formulas/macos/font7/
├── al_bayan_10m1360.yml      # Build 10M1360
├── al_bayan_10m1044.yml      # Build 10M1044 (older version)
└── ...
----

==== Update Detection

Fontist can detect when newer versions are available:

[source,bash]
----
$ fontist check-updates --catalog-version=7
📦 Newer versions available:
  - Al Bayan (posted: 2024-08-13, current: 2024-06-01)
  - Damascus (posted: 2024-08-13, current: 2024-06-01)

Run 'fontist update' to refresh formulas
----
```

**Update import documentation**:

```adoc
=== Importing macOS Fonts

When importing macOS fonts, Fontist automatically:

1. Extracts catalog `postedDate`
2. Assigns package identifier from `Build` field
3. Generates versioned filename
4. Sets `source` to "macos"

[source,bash]
----
$ fontist import macos --plist=/path/to/Font7.xml
📦 Found 157 font packages in catalog
📅 Catalog posted: 2024-08-13T18:11:00Z
📁 Saving formulas to: ~/.fontist/formulas/macos/font7/
...
----
```

#### 10.2 Update Formula Documentation
**File**: `docs/formula-resource-provides-architecture.md`

Add section on catalog versioning attributes

#### 10.3 Create Migration Guide
**File**: `docs/macos-catalog-versioning-migration.md` (NEW)

Document migration from font_version to posted_date approach

---

## Directory Structure After Implementation

```
formulas/macos/
├── font7/                           # macOS 10.11-15.7
│   ├── al_bayan_10m1360.yml        # Build 10M1360
│   ├── al_bayan_10m1044.yml        # Build 10M1044 (if different version)
│   ├── adobe_arabic_10m1360.yml
│   └── ...
├── font8/                           # macOS 26.0+
│   ├── al_bayan_10m1732.yml        # Newer Build
│   ├── adobe_arabic_10m1732.yml
│   └── ...
└── legacy/                          # Old formulas without versioning
    ├── al_bayan.yml                 # No package ID in filename
    └── ...
```

---

## Example Formula After Implementation

```yaml
---
name: Al Bayan
description: Al Bayan is an Arabic font with a distinctive thick stroke...
homepage: https://support.apple.com/en-om/HT211240#document

# Catalog versioning
catalog_version: 7
min_macos_version: "10.11"
max_macos_version: "15.7"

# Package identity and tracking
posted_date: "2024-08-13T18:11:00Z"
source: "macos"
macos_asset_id: "10m1360"

platforms:
  - macos-font7

resources:
  AlBayan_Font:
    urls:
      - https://mesu.apple.com/assets/com_apple_MobileAsset_Font7/.../AlBayan.pkg
    sha256: 558fac4e25f...
    file_size: 412345

fonts:
  - name: Al Bayan
    styles:
      - family_name: Al Bayan
        type: Plain
        post_script_name: AlBayan
        full_name: Al Bayan Plain
        version: "13.0d3e1"
      - family_name: Al Bayan
        type: Bold
        post_script_name: AlBayan-Bold
        full_name: Al Bayan Bold
        version: "13.0d3e1"

license_url: https://www.apple.com/legal/sla/
open_license: Apple Font License
```

---

## Verification Checklist

### Phase 1: Rollback
- [ ] font_version removed from Formula
- [ ] font_version removed from FormulaBuilder
- [ ] font_version extraction removed from CreateFormula
- [ ] font_version removed from README
- [ ] All existing tests still pass

### Phase 2: PostedDate Support
- [ ] BaseParser extracts posted_date correctly
- [ ] Asset receives posted_date in constructor
- [ ] Asset.package_identifier returns correct Build value
- [ ] Tests verify posted_date extraction

### Phase 3: Formula Attributes
- [ ] posted_date attribute in Formula
- [ ] source attribute in Formula
- [ ] macos_asset_id attribute in Formula
- [ ] Formula.outdated? method works
- [ ] Formula.macos_formula? method works
- [ ] Tests verify attribute loading

### Phase 4: FormulaBuilder
- [ ] New attributes in FORMULA_ATTRIBUTES
- [ ] Attr_writers added
- [ ] Getter methods added
- [ ] Tests verify builder passes attributes

### Phase 5: CreateFormula
- [ ] Accepts posted_date parameter
- [ ] Accepts source parameter
- [ ] Accepts macos_asset_id parameter
- [ ] Passes to FormulaBuilder
- [ ] extract_font_version removed

### Phase 6: Macos Importer
- [ ] Passes posted_date to CreateFormula
- [ ] Sets source to "macos"
- [ ] Passes package_identifier as macos_asset_id
- [ ] Generates versioned filenames
- [ ] Creates formulas in correct directories

### Phase 7: Other Importers
- [ ] Google importer sets source="google"
- [ ] SIL importer sets source="sil"
- [ ] Manual formulas default to source="manual"

### Phase 8: Update Detection
- [ ] Formula.outdated? compares dates correctly
- [ ] Update detection logic works
- [ ] CLI provides feedback on outdated formulas

### Phase 9: Testing
- [ ] PostedDate extraction tests pass
- [ ] Package identity tests pass
- [ ] Formula attribute tests pass
- [ ] Integration tests pass
- [ ] All 617 existing tests still pass
- [ ] New tests added (est. 50+ tests)

### Phase 10: Documentation
- [ ] README updated with PostedDate info
- [ ] Formula docs updated
- [ ] Migration guide created
- [ ] Examples show correct attributes

---

## Success Criteria

✅ **Correct Versioning Approach**
- Uses PostedDate from catalog, not font file versions
- One formula per macOS package
- Package identity tracked via Build

✅ **Source Tracking**
- All formulas know their source (manual/google/macos/sil)
- Easy to query formulas by source

✅ **Version Isolation**
- Different package versions have unique filenames
- No overwrites between versions
- Can install multiple versions side by side

✅ **Update Detection**
- Can detect when catalog has been updated
- Only reinstall if PostedDate is newer
- Clear feedback to users

✅ **Backward Compatibility**
- Legacy formulas without new attributes still work
- Graceful handling of missing metadata

✅ **All Tests Pass**
- 617 existing tests still pass
- ~50 new tests added and passing
- Total: ~667 tests

✅ **Documentation Complete**
- README fully updated
- Migration guide available
- Examples show correct usage

---

## Next Steps

1. **Review this plan** with user to confirm approach
2. **Switch to Code mode** to implement changes
3. **Work phase-by-phase** to ensure correctness
4. **Test after each phase** to catch issues early
5. **Document as we go** to maintain clarity

---

## Critical Principles

1. **PostedDate is catalog version**, not font version
2. **One formula = One package**, identified by Build
3. **Source tracking** enables querying by origin
4. **Versioned filenames** prevent conflicts
5. **Update detection** prevents unnecessary work
6. **Backward compatible** with legacy formulas
7. **Test thoroughly** at each phase

---

## Questions for User

1. **Package Identifier**: Confirm using Build (e.g., "10m1360") for filename?
2. **Filename Format**: Is `family_name_build.yml` acceptable? (e.g., `al_bayan_10m1360.yml`)
3. **Update Detection**: Should it be automatic or require explicit command?
4. **Legacy Formulas**: How to handle existing formulas without new attributes?
5. **Multiple Catalogs**: Can same Build appear in both Font7 and Font8?

---

## Timeline Estimate

- **Phase 1 (Rollback)**: 1-2 hours
- **Phase 2 (PostedDate)**: 2-3 hours
- **Phase 3 (Formula)**: 1-2 hours
- **Phase 4 (Builder)**: 1 hour
- **Phase 5 (CreateFormula)**: 1-2 hours
- **Phase 6 (Macos)**: 2-3 hours
- **Phase 7 (Other)**: 1 hour
- **Phase 8 (Updates)**: 2-3 hours
- **Phase 9 (Testing)**: 3-4 hours
- **Phase 10 (Docs)**: 2-3 hours

**Total**: 16-24 hours of development time

---

**Ready to proceed with Phase 1 (Rollback) when approved.**