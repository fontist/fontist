# CLI Interface Standardization Plan

**Date:** 2025-12-29
**Status:** Proposed
**Goal:** Make all import commands use consistent, MECE interface

---

## Current State Analysis

### Google Import
```ruby
option :source_path, type: :string
option :output_path, type: :string
option :font_family, type: :string, aliases: :f
option :verbose, type: :boolean, aliases: :v
```

### macOS Import
```ruby
option :plist, type: :string
option :formulas_dir, type: :string  # ❌ Inconsistent with output_path
option :force, type: :boolean
```

### SIL Import
```ruby
# ❌ NO OPTIONS AT ALL
# Hardcoded output to: Fontist.formulas_path.join("sil")
```

---

## Problems Identified

1. **Naming inconsistency**: `output_path` vs `formulas_dir` vs hardcoded
2. **No SIL options**: Cannot specify output directory or verbosity
3. **Missing verbose** option for macOS and SIL
4. **Not MECE**: Interface varies by command instead of consistent pattern

---

## Proposed Standardized Interface

### Common Options (All Commands)

```ruby
option :output_path,
       type: :string,
       desc: "Output directory for generated formulas"

option :verbose,
       type: :boolean, aliases: :v,
       desc: "Enable verbose output"
```

### Source-Specific Options

#### Google
```ruby
option :source_path,
       type: :string,
       desc: "Path to google/fonts repository (required for import_source)"

option :font_family,
       type: :string, aliases: :f,
       desc: "Import specific font family"
```

#### macOS
```ruby
option :plist,
       type: :string,
       desc: "Path to macOS font catalog XML"

option :force,
       type: :boolean,
       desc: "Overwrite existing formulas"
```

#### SIL
```ruby
option :font_name,
       type: :string, aliases: :f,
       desc: "Import specific font by name (optional)"
```

---

## Implementation Changes Required

### 1. Update SilImport Class

**File:** [`lib/fontist/import/sil_import.rb`](lib/fontist/import/sil_import.rb:1)

**Changes:**
```ruby
class SilImport
  def initialize(options = {})
    @output_path = options[:output_path]
    @font_name = options[:font_name]
    @verbose = options[:verbose]
  end

  def call
    links = font_links
    log("Found #{links.size} links.")

    # Filter by font_name if specified
    links = filter_by_name(links) if @font_name

    paths = []
    links.each do |link|
      path = create_formula_by_page_link(link)
      paths << path if path
    end

    Fontist::Index.rebuild

    Fontist.ui.success("Created #{paths.size} formulas.")

    {
      successful: paths.size,
      failed: links.size - paths.size,
      duration: 0, # Track duration
      errors: []
    }
  end

  private

  def formula_dir
    @formula_dir ||= begin
      if @output_path
        Pathname.new(@output_path).tap { |p| FileUtils.mkdir_p(p) }
      else
        Fontist.formulas_path.join("sil").tap { |p| FileUtils.mkdir_p(p) }
      end
    end
  end

  def filter_by_name(links)
    links.select { |link| link.content.downcase.include?(@font_name.downcase) }
  end

  def log(message)
    Fontist.ui.say(message) if @verbose
  end
end
```

### 2. Update CLI Command

**File:** [`lib/fontist/import_cli.rb`](lib/fontist/import_cli.rb:81)

**Changes:**
```ruby
desc "sil", "Import formulas from SIL International"
option :output_path,
       type: :string,
       desc: "Output directory for generated formulas (default: ~/.fontist/versions/v4/formulas/Formulas/sil)"
option :font_name,
       type: :string, aliases: :f,
       desc: "Import specific font by name (optional)"
option :verbose,
       type: :boolean, aliases: :v,
       desc: "Enable verbose output"

def sil
  handle_class_options(options)

  require "fontist/import/sil_import"

  importer = Fontist::Import::SilImport.new(
    output_path: options[:output_path],
    font_name: options[:font_name],
    verbose: options[:verbose]
  )

  result = importer.call

  # Report results (consistent with Google import)
  Fontist.ui.success("Import completed")
  Fontist.ui.say("  Successful: #{result[:successful]}")
  Fontist.ui.say("  Failed: #{result[:failed]}") if result[:failed]&.positive?
  Fontist.ui.say("  Duration: #{format_duration(result[:duration])}")

  CLI::STATUS_SUCCESS
rescue StandardError => e
  Fontist.ui.error("Import error: #{e.message}")
  Fontist.ui.error(e.backtrace.join("\n")) if options[:verbose]
  Fontist::CLI::STATUS_UNKNOWN_ERROR
end
```

### 3. Standardize macOS Option Name

**File:** [`lib/fontist/import_cli.rb`](lib/fontist/import_cli.rb:55)

**Change `formulas_dir` to `output_path`:**
```ruby
desc "macos", "Import macOS supplementary fonts"
option :plist,
       type: :string,
       desc: "Path to macOS font catalog XML"
option :output_path,  # Changed from formulas_dir
       type: :string,
       desc: "Output directory for generated formulas (default: formulas/macos)"
option :force,
       type: :boolean,
       desc: "Overwrite existing formulas"
option :verbose,
       type: :boolean, aliases: :v,
       desc: "Enable verbose output"

def macos
  handle_class_options(options)
  require_relative "import/macos"

  plist_path = options[:plist] || detect_latest_catalog
  output_path = options[:output_path]  # Changed from formulas_dir
  force = options[:force]
  verbose = options[:verbose]

  Import::Macos.new(
    plist_path,
    formulas_dir: output_path,  # Keep internal param name for now
    force: force,
    verbose: verbose
  ).call

  CLI::STATUS_SUCCESS
rescue StandardError => e
  Fontist.ui.error("Import error: #{e.message}")
  Fontist.ui.error(e.backtrace.join("\n")) if options[:verbose]
  CLI::STATUS_UNKNOWN_ERROR
end
```

---

## Standardized Interface Comparison

### After Changes

| Command | Source Options | Output Options | Filter Options | Common Options |
|---------|---------------|----------------|----------------|----------------|
| **google** | `--source-path` | `--output-path` | `--font-family` | `--verbose` |
| **macos** | `--plist` | `--output-path` | - | `--verbose`, `--force` |
| **sil** | (web scraping) | `--output-path` | `--font-name` | `--verbose` |

All commands now share:
- ✅ `--output-path` for output directory
- ✅ `--verbose` for debugging
- ✅ Consistent result reporting
- ✅ Consistent error handling

---

## Benefits

1. **MECE Interface**: Each option has single, clear responsibility
2. **Consistent UX**: Users learn once, apply everywhere
3. **Predictable Behavior**: Same option names mean same things
4. **Easy to Document**: Patterns apply across all commands
5. **Extensible**: New import sources follow same pattern

---

## Implementation Steps

1. ✅ Update `SilImport` class to accept options
2. ✅ Add CLI options to `sil` command
3. ✅ Rename `formulas_dir` to `output_path` in macOS command
4. ✅ Add verbose support to macOS
5. ✅ Update tests for new interface
6. ✅ Update documentation

---

## Backward Compatibility

### Breaking Changes

- **SIL**: Adding CLI options is backward compatible (old behavior is default)
- **macOS**: Renaming `--formulas-dir` to `--output-path` is breaking
  - Solution: Support both with deprecation warning

### Migration Path

```ruby
# Support both old and new names
option :output_path, type: :string
option :formulas_dir, type: :string  # Deprecated

def macos
  if options[:formulas_dir] && !options[:output_path]
    Fontist.ui.warn("DEPRECATED: --formulas-dir is deprecated, use --output-path instead")
    output_path = options[:formulas_dir]
  else
    output_path = options[:output_path]
  end

  # ...rest of implementation
end
```

---

## Testing Strategy

### Unit Tests

```ruby
# SilImport with options
describe Fontist::Import::SilImport do
  it "accepts output_path option" do
    importer = described_class.new(output_path: "/tmp/test")
    expect(importer.send(:formula_dir)).to eq(Pathname.new("/tmp/test"))
  end

  it "accepts verbose option" do
    importer = described_class.new(verbose: true)
    expect { importer.send(:log, "test") }.to output("test\n").to_stdout
  end

  it "accepts font_name filter" do
    importer = described_class.new(font_name: "Charis")
    links = [mock_link("Charis SIL"), mock_link("Andika")]
    filtered = importer.send(:filter_by_name, links)
    expect(filtered.size).to eq(1)
  end
end
```

### Integration Tests

```bash
# Test all three commands with consistent interface
bundle exec fontist import google --output-path /tmp/test --verbose
bundle exec fontist import macos --output-path /tmp/test --verbose
bundle exec fontist import sil --output-path /tmp/test --verbose
```

---

## Documentation Updates

### CLI Help Output

```
$ fontist help import

Commands:
  fontist import google    # Import Google Fonts
  fontist import macos     # Import macOS supplementary fonts
  fontist import sil       # Import SIL International fonts

Options:
  --output-path PATH       # Output directory for formulas
  -v, --verbose            # Enable verbose output

# Source-specific:
  google --source-path PATH     # Path to google/fonts repository
  google --font-family NAME     # Import specific family

  macos --plist PATH            # Path to catalog XML
  macos --force                 # Overwrite existing

  sil --font-name NAME          # Import specific font
```

### README.adoc Updates

Update all import command examples to use standardized interface:

```adoc
==== Importing Google Fonts

[source,bash]
----
fontist import google \
  --source-path /path/to/google/fonts \
  --output-path ./Formulas/google \
  --verbose
----

==== Importing SIL Fonts

[source,bash]
----
fontist import sil \
  --output-path ./Formulas/sil \
  --verbose
----

==== Importing macOS Fonts

[source,bash]
----
fontist import macos \
  --plist com_apple_MobileAsset_Font7.xml \
  --output-path ./Formulas/macos/font7 \
  --verbose
----
```

---

## Timeline

**Estimated Time:** 2-3 hours

| Task | Duration |
|------|----------|
| Update SilImport class | 30 min |
| Update CLI commands | 30 min |
| Add/update tests | 45 min |
| Update documentation | 30 min |
| Integration testing | 30 min |

---

## Migration Notes

### For Users

Old commands still work with deprecation warnings:

```bash
# Old (still works with warning)
fontist import macos --formulas-dir ./output

# New (preferred)
fontist import macos --output-path ./output
```

### For Workflows

Update GitHub Actions workflows to use `--output-path`:

```yaml
# Old
--formulas-dir ${{ matrix.output_dir }}

# New
--output-path ${{ matrix.output_dir }}
```

---

## Success Criteria

After implementation:

- [ ] All three commands accept `--output-path`
- [ ] All three commands accept `--verbose`
- [ ] All three commands have consistent result reporting
- [ ] All tests passing
- [ ] Documentation updated
- [ ] Old `--formulas-dir` still works with deprecation warning
- [ ] Integration tests verify consistent behavior

---

## Risk Assessment

**Low Risk**:
- Adding options to SIL (backward compatible)
- Adding verbose to macOS (backward compatible)

**Medium Risk**:
- Renaming macOS option (breaking change)
- Solution: Support both with deprecation

**No Risk**:
- Google import already has correct interface