# Continuation Prompt: Implement macOS Font Platform Versioning

## Context

You are continuing work on fontist, a Ruby font management tool. The macOS supplementary font import has been implemented, but there's a critical issue: Font7 and Font8 catalogs contain different versions of fonts, but all formulas currently use generic `platforms: ["macos"]` which causes:

1. Font8 formulas overwriting Font7 formulas
2. No way to ensure version compatibility
3. Users on older macOS getting wrong fonts

## Key Facts

- **Font6 catalog**: Compatible with macOS 10.14 (Mojave) up to Catalina 10.15
- **Font7 catalog**: Compatible with macOS 11+ (Big Sur) through macOS 15 (Sequoia)
- **Font8 catalog**: Compatible with macOS 26+ (Tahoe)
- **Apple's versioning**: Jumped from macOS 15.7 to macOS 26 (not 16!)
- **Current import**: Working perfectly, but platform tags are wrong

## What You Must Do

### STEP 1: Update Formula Model

File: [`lib/fontist/formula.rb`](lib/fontist/formula.rb)

Add these attributes to the Formula class:

```ruby
attribute :catalog_version, :integer
attribute :min_macos_version, :string
attribute :max_macos_version, :string

# In key_value block:
map "catalog_version", to: :catalog_version
map "min_macos_version", to: :min_macos_version
map "max_macos_version", to: :max_macos_version
```

Update `compatible_with_platform?` method to:
- Check if platform is macOS
- If catalog_version or min_macos_version specified, verify OS version compatibility
- Support both `macos` and `macos-fontX` platform tags

### STEP 2: Add macOS Version Detection

File: [`lib/fontist/utils/system.rb`](lib/fontist/utils/system.rb)

Add method to detect macOS version:

```ruby
def self.macos_version
  return nil unless user_os == :macosx

  # Read from sw_vers command
  version_string = `sw_vers -productVersion`.strip
  parse_macos_version(version_string)
end

def self.parse_macos_version(version_string)
  # Handle "10.15.7", "11.0", "15.7", "26.0" formats
  # Return as comparable string
end

def self.macos_catalog_version
  version = macos_version
  return nil unless version

  # Map OS version to catalog version
  # macOS 10.11-15.7 → Font7
  # macOS 26+ → Font8
end
```

### STEP 3: Update Import to Set Version Info

File: [`lib/fontist/import/macos.rb`](lib/fontist/import/macos.rb)

In `process_asset`, pass catalog version info to CreateFormula:

```ruby
def process_asset(asset, current, total)
  # ... existing code ...

  catalog_version = detect_catalog_version
  platform_tag = catalog_version == 8 ? "macos-font8" : "macos-font7"
  version_range = catalog_version_range(catalog_version)

  path = Fontist::Import::CreateFormula.new(
    asset.download_url,
    platforms: [platform_tag],
    catalog_version: catalog_version,
    min_macos_version: version_range[:min],
    max_macos_version: version_range[:max],
    homepage: homepage,
    requires_license_agreement: license,
    formula_dir: formula_dir,
    keep_existing: !@force,
  ).call

  # ... existing code ...
end

def detect_catalog_version
  Fontist::Macos::Catalog::CatalogManager.detect_version(@catalog_path)
end

def catalog_version_range(version)
  case version
  when 7
    { min: "10.11", max: "15.7" }
  when 8
    { min: "26.0", max: nil }
  else
    { min: nil, max: nil }
  end
end
```

### STEP 4: Update CreateFormula/FormulaBuilder

File: [`lib/fontist/import/create_formula.rb`](lib/fontist/import/create_formula.rb) and [`lib/fontist/import/formula_builder.rb`](lib/fontist/import/formula_builder.rb)

Accept and pass through catalog metadata:

```ruby
# In CreateFormula#initialize
def initialize(url, options = {})
  @url = url
  @options = options
  @catalog_version = options[:catalog_version]
  @min_macos_version = options[:min_macos_version]
  @max_macos_version = options[:max_macos_version]
  # ... existing code ...
end

# Pass to FormulaBuilder
builder.catalog_version = @catalog_version
builder.min_macos_version = @min_macos_version
builder.max_macos_version = @max_macos_version
```

### STEP 5: Organize Formulas by Catalog Version

Update formula directory structure to:

```
formulas/macos/
├── font7/          # macOS 10.11-15.7
│   ├── al_bayan.yml
│   └── ...
└── font8/          # macOS 26+
    ├── al_bayan.yml
    └── ...
```

Update `formula_dir` method in Macos importer:

```ruby
def formula_dir
  catalog_ver = detect_catalog_version
  base = @custom_formulas_dir || Fontist.formulas_path.join("macos")

  Pathname.new(base).join("font#{catalog_ver}").tap do |path|
    FileUtils.mkdir_p(path)
  end
end
```

### STEP 6: Update Formula Selection Logic

File: [`lib/fontist/formula.rb`](lib/fontist/formula.rb)

Update `find` methods to prefer version-compatible formulas:

```ruby
def self.find(name)
  formulas = find_by_name(name)
  return nil if formulas.empty?

  # Filter by platform and version compatibility
  compatible = formulas.select(&:compatible_with_platform?)

  # Prefer higher catalog version if multiple matches
  compatible.sort_by { |f| f.catalog_version || 0 }.last
end
```

### STEP 7: Update Tests

File: [`spec/fontist/macos_ondemand_fonts_spec.rb`](spec/fontist/macos_ondemand_fonts_spec.rb)

Add tests for:
- Catalog version detection
- Platform tag generation
- Version range setting
- Formula selection based on OS version
- Multiple catalog formulas for same font

### STEP 8: Update Documentation

Update [`README.adoc`](README.adoc) to explain:
- Font7 vs Font8 catalogs
- Platform version compatibility
- How formula selection works

## Files to Modify

1. `lib/fontist/formula.rb` - Add version attributes
2. `lib/fontist/utils/system.rb` - Add macOS version detection
3. `lib/fontist/import/macos.rb` - Set version info during import
4. `lib/fontist/import/create_formula.rb` - Pass version metadata
5. `lib/fontist/import/formula_builder.rb` - Include version in formulas
6. `spec/fontist/macos_ondemand_fonts_spec.rb` - Add version tests
7. `README.adoc` - Document version compatibility

## Verification Steps

After implementation:

1. Import Font7: `bin/fontist import macos --plist=./com_apple_MobileAsset_Font7.xml`
2. Import Font8: `bin/fontist import macos --plist=./com_apple_MobileAsset_Font8.xml`
3. Verify formulas have platform tags: `macos-font7` or `macos-font8`
4. Verify min/max_macos_version set correctly
5. Test font installation on different macOS versions
6. Verify correct formula selected based on OS version
7. Run all tests: `bundle exec rspec`

## Important Notes

- **Backward Compatibility**: Old formulas with `platforms: ["macos"]` should still work
- **Version Detection**: Handle edge cases in macOS version parsing (10.x, 11+, 26+)
- **Formula Naming**: Ensure Font7 and Font8 formulas don't conflict
- **MECE Principle**: Version ranges must be mutually exclusive
- **No Hardcoding**: Version mappings should be configurable/extensible

## Success Criteria

✅ Font7 formulas have `platforms: ["macos-font7"]` and version range 10.11-15.7
✅ Font8 formulas have `platforms: ["macos-font8"]` and min version 26.0
✅ Formula selection considers OS version automatically
✅ Both catalogs can coexist without conflicts
✅ All tests pass
✅ Documentation updated

Go ahead and implement this architectural solution!