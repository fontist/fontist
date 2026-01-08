= Import Source Architecture

== Overview

The Import Source architecture provides a polymorphic system for tracking the
origin and version of font formulas in Fontist. This enables formula versioning,
update detection, platform compatibility checks, and complete audit trails.

== Design Principles

=== Separation of Concerns

Formula metadata is separated into three distinct layers, ensuring clean architecture
and MECE (Mutually Exclusive, Collectively Exhaustive) design:

Font data:: Stored in Formula (fonts, styles, resources, platforms)
Import metadata:: Stored in ImportSource subclasses (framework version, dates, IDs)
Framework metadata:: Stored in MacosFrameworkMetadata constant (version ranges, parsers)

This separation prevents duplication and ensures each piece of data has a single source of truth.

=== Polymorphic Design Using Lutaml::Model

Import sources use lutaml-model's polymorphic attributes for type-safe deserialization.
The `type` field determines which concrete class to instantiate when loading formulas.

.Base ImportSource class
[source,ruby]
----
class ImportSource < Lutaml::Model::Serializable
  attribute :type, :string, polymorphic_class: true

  key_value do
    map "type", to: :type, polymorphic_map: {
      "macos" => "Fontist::MacosImportSource",
      "google" => "Fontist::GoogleImportSource",
      "sil" => "Fontist::SilImportSource",
    }
  end
end
----

.MacosImportSource subclass
[source,ruby]
----
class MacosImportSource < ImportSource
  attribute :framework_version, :integer
  attribute :posted_date, :string
  attribute :asset_id, :string

  def min_macos_version
    MacosFrameworkMetadata.min_macos_version(framework_version)
  end
end
----

== Class Hierarchy

----
ImportSource (abstract base)
│
├─ MacosImportSource
│    Attributes: framework_version, posted_date, asset_id
│    Methods: min_macos_version(), max_macos_version(),
│             compatible_with_macos?()
│
├─ GoogleImportSource
│    Attributes: commit_id, api_version, last_modified, family_id
│    Methods: (version tracking via commit_id)
│
└─ SilImportSource
     Attributes: version, release_date
     Methods: (version tracking via version string)
----

Each subclass must implement:

* `differentiation_key()` - Returns unique identifier for versioned filenames
* `outdated?(new_source)` - Compares with new source to detect updates

== Formula Integration

=== Formula with Import Source

.Example macOS formula
[source,yaml]
----
name: Al Bayan
description: Al Bayan is an Arabic font...
homepage: https://support.apple.com/en-om/HT211240
platforms:
  - macos
import_source:
  type: macos
  framework_version: 7
  posted_date: "2024-08-13T18:11:00Z"
  asset_id: "10m1360"
resources:
  AlBayan_Font:
    urls:
      - https://mesu.apple.com/assets/.../AlBayan.pkg
    sha256: 558fac4e25f...
fonts:
  - name: Al Bayan
    styles:
      - family_name: Al Bayan
        type: Plain
----

=== Formula Without Import Source (Manual)

Manually created formulas have `import_source: nil` and are not tied to any import system.

[source,yaml]
----
name: Custom Font
description: Manually created formula
resources:
  font.zip:
    urls:
      - https://example.com/font.zip
fonts:
  - name: Custom Font
    styles:
      - family_name: Custom
        type: Regular
# No import_source attribute
----

=== Formula Configuration

The Formula class configures polymorphic deserialization:

[source,ruby]
----
class Formula < Lutaml::Model::Serializable
  attribute :import_source, ImportSource, polymorphic: [
    "MacosImportSource",
    "GoogleImportSource",
    "SilImportSource",
  ]

  key_value do
    map "import_source", to: :import_source, polymorphic: {
      attribute: :type,
      class_map: {
        "macos" => "Fontist::MacosImportSource",
        "google" => "Fontist::GoogleImportSource",
        "sil" => "Fontist::SilImportSource",
      },
    }
  end
end
----

== Framework Metadata System (macOS Only)

=== Rationale

Framework-specific metadata (version ranges, parser classes) is stored externally
to formulas to maintain proper separation of concerns.

This metadata describes the *framework itself*, not individual fonts. Storing it
per-formula would violate DRY and make updates difficult.

=== Implementation

File: [`lib/fontist/macos_framework_metadata.rb`](../lib/fontist/macos_framework_metadata.rb)

[source,ruby]
----
class MacosFrameworkMetadata
  METADATA = {
    7 => {
      "min_macos_version" => "10.11",
      "max_macos_version" => "15.7",
      "parser_class" => "Fontist::Macos::Catalog::Font7Parser",
      "description" => "Font7 framework (macOS Monterey, Ventura, Sonoma)"
    },
    8 => {
      "min_macos_version" => "26.0",
      "max_macos_version" => nil,
      "parser_class" => "Fontist::Macos::Catalog::Font8Parser",
      "description" => "Font8 framework (macOS Sequoia+)"
    }
  }.freeze
end
----

=== Usage

[source,ruby]
----
# Create import source with framework version
source = MacosImportSource.new(framework_version: 7)

# Query framework metadata (delegated to MacosFrameworkMetadata)
source.min_macos_version          # => "10.11"
source.max_macos_version          # => "15.7"
source.compatible_with_macos?("12.0")  # => true
source.compatible_with_macos?("16.0")  # => false (too new)
----

== Version Differentiation

=== macOS Fonts

macOS fonts use multi-dimensional versioning to differentiate between versions:

1. **Framework version** (7 vs 8) - Different catalog schemas
2. **Posted date** - Catalog version within framework
3. **Asset ID** - Individual package build identifier

.Versioned filename format
----
{normalized_font_name}_{asset_id}.yml
----

.Example
----
al_bayan_10m1360.yml
----

Where:
* `al_bayan` = normalized font name
* `10m1360` = lowercased asset_id

.Directory structure
----
macos/
├── font7/
│   ├── al_bayan_10m1360.yml
│   ├── arial_unicode_ms_10m1361.yml
│   └── ...
└── font8/
    ├── sf_pro_26m2001.yml
    └── ...
----

=== Google Fonts

Google Fonts are differentiated by commit ID (short form) from the google/fonts repository.

.Versioned filename format
----
{normalized_font_name}_{commit_id_short}.yml
----

=== SIL Fonts

SIL fonts are differentiated by version string.

.Versioned filename format
----
{normalized_font_name}_{version}.yml
----

== Update Detection

Each ImportSource subclass implements `outdated?(new_source)` to enable automatic
update detection when catalogs are refreshed.

[source,ruby]
----
# Check if formula needs updating
old_source.outdated?(new_source)  # => true if old_source should be replaced
----

=== Implementation by Source Type

==== macOS

Compares `posted_date` timestamps:

[source,ruby]
----
def outdated?(new_source)
  return false unless new_source.is_a?(MacosImportSource)
  return false unless posted_date && new_source.posted_date

  Time.parse(posted_date) < Time.parse(new_source.posted_date)
end
----

==== Google Fonts

Compares commit IDs:

[source,ruby]
----
def outdated?(new_source)
  return false unless new_source.is_a?(GoogleImportSource)
  commit_id != new_source.commit_id
end
----

==== SIL

Compares version strings using Gem::Version:

[source,ruby]
----
def outdated?(new_source)
  return false unless new_source.is_a?(SilImportSource)
  Gem::Version.new(version) < Gem::Version.new(new_source.version)
end
----

== Platform Compatibility

=== Checking Compatibility

For macOS formulas, platform compatibility is determined by the import source:

[source,ruby]
----
# In Formula class
def compatible_with_platform?(platform)
  return true unless macos_import?
  return true unless platform == "macos"

  current_macos = Utils::System.macos_version
  import_source.compatible_with_macos?(current_macos)
end

def macos_import?
  import_source.is_a?(MacosImportSource)
end
----

=== Compatibility Error Messages

When a formula is incompatible with the current platform:

[source,ruby]
----
def platform_restriction_message
  return nil unless macos_import?

  "This font requires macOS #{import_source.min_macos_version} " \
  "or later. Your current version is #{Utils::System.macos_version}."
end
----

== Import Source Types

=== macOS Import Source

Tracks macOS supplementary fonts from Apple's MobileAsset catalogs.

.Attributes
[source,yaml]
----
type: macos
framework_version: 7                    # Integer: 7 or 8
posted_date: "2024-08-13T18:11:00Z"    # ISO 8601 datetime
asset_id: "10m1360"                     # Build identifier
----

.Key Methods
* `min_macos_version()` - Minimum macOS version (from framework metadata)
* `max_macos_version()` - Maximum macOS version (from framework metadata)
* `compatible_with_macos?(version)` - Check version compatibility
* `differentiation_key()` - Returns lowercased asset_id
* `outdated?(new_source)` - Compares posted_date

=== Google Import Source

Tracks fonts from Google Fonts repository with commit-based versioning.

**Implementation:** Completed 2025-12-29

**Important:** Google Fonts formulas use **simple filenames** (not versioned) because Google Fonts is a live service that always points to the latest version. The commit_id is tracked in import_source for metadata and update detection purposes only.

.Attributes
[source,yaml]
----
type: google
commit_id: "abc123def456789..."           # Full 40-char GitHub commit SHA
api_version: "v1"                          # Google Fonts API version
last_modified: "2024-01-01T12:00:00Z"     # Last modification timestamp
family_id: "roboto"                        # Normalized font family identifier
----

.Key Methods
* `differentiation_key()` - Returns nil (Google Fonts use simple filenames)
* `outdated?(new_source)` - Compares commit_id for update detection
* `to_s` - Human-readable representation for debugging

==== Implementation Details

The Google import source is automatically created by `FontDatabase` when a source_path
to the google/fonts repository is provided:

[source,ruby]
----
# With source_path: enables import_source tracking
db = Fontist::Import::Google::FontDatabase.build_v4(
  api_key: ENV["GOOGLE_FONTS_API_KEY"],
  source_path: "/Users/mulgogi/src/external/google-fonts"
)

# Creates formulas with import_source
formula = db.to_formula("Roboto")
# => { name: "roboto", import_source: #<GoogleImportSource...>, ... }

# Without source_path: API-only mode (no import_source)
db = Fontist::Import::Google::FontDatabase.build(
  api_key: ENV["GOOGLE_FONTS_API_KEY"]
)

# Creates formulas without import_source
formula = db.to_formula("Roboto")
# => { name: "roboto", ... } # No import_source key
----

==== Filenames (NOT Versioned)

Google Fonts formulas always use simple filenames because Google Fonts is a live service that always points to the latest online version:

.Google Fonts filenames (simple, not versioned)
----
google/
  roboto.yml              # Simple filename
  open_sans.yml           # Simple filename
  noto_sans.yml           # Simple filename
----

The commit_id in import_source is used for:
- Metadata tracking (which commit was used for generation)
- Update detection (comparing commits to detect changes)
- Audit trail (knowing the source state at generation time)

But filenames remain simple because Google Fonts URLs always serve the latest version.

==== Formula Example

[source,yaml]
----
name: roboto
description: Roboto font family
homepage: https://fonts.google.com/specimen/Roboto
platforms:
  - google
import_source:
  type: google
  commit_id: "abc123def456789abcdef0123456789abcdef01"
  api_version: "v1"
  last_modified: "2025-09-08"
  family_id: "roboto"
resources:
  Roboto:
    source: google
    family: Roboto
    files:
      - https://fonts.gstatic.com/s/roboto/v30/KFOmCnqEu92Fr1Me5WZLCzYlKw.ttf
      - https://fonts.gstatic.com/s/roboto/v30/KFOlCnqEu92Fr1MmEU9vAw.ttf
    format: ttf
fonts:
  - name: Roboto
    styles:
      - family_name: Roboto
        type: Regular
        full_name: Roboto Regular
        post_script_name: Roboto-Regular
        version: "3.008"
        copyright: "Copyright 2011 Google Inc..."
        font: KFOmCnqEu92Fr1Me5WZLCzYlKw.ttf
----

==== Update Detection

Google Fonts formulas can be checked for updates by comparing commit IDs:

[source,ruby]
----
# Load existing formula
old_formula = Fontist::Formula.from_file("google/roboto.yml")

# Get new formula from updated repository
new_db = Fontist::Import::Google::FontDatabase.build_v4(
  api_key: ENV["GOOGLE_FONTS_API_KEY"],
  source_path: "/Users/mulgogi/src/external/google-fonts"  # Now at newer commit
)
new_formula = new_db.to_formula("Roboto")

# Check if update available (different commit)
if old_formula.import_source.outdated?(new_formula[:import_source])
  puts "Repository has changed!"
  puts "Old commit: #{old_formula.import_source.commit_id[0..6]}"
  puts "New commit: #{new_formula[:import_source].commit_id[0..6]}"
  puts "Formula should be regenerated to pick up latest font URLs"
end
----

==== Backward Compatibility

- ✅ Formulas without import_source continue to work normally
- ✅ API-only mode (without source_path) works as before
- ✅ import_source is completely optional
- ✅ Existing functionality preserved
- ✅ Filenames remain simple and consistent

==== Technical Implementation

**Files:**
- [`lib/fontist/google_import_source.rb`](../lib/fontist/google_import_source.rb) - Class definition
- [`lib/fontist/import/google/font_database.rb`](../lib/fontist/import/google/font_database.rb) - Import source creation
- [`spec/fontist/google_import_source_spec.rb`](../spec/fontist/google_import_source_spec.rb) - Tests
- [`spec/fontist/import/google/font_database_spec.rb`](../spec/fontist/import/google/font_database_spec.rb) - Integration tests

**Methods in FontDatabase:**
- `current_commit_id()` - Extracts git commit SHA from source_path
- `create_import_source(family)` - Builds GoogleImportSource instance
- `last_modified_for(family)` - Extracts timestamp from API metadata
- `save_formula(formula, name, dir)` - Saves with simple filename (always `name.yml`)

== SIL Import Source

Tracks fonts from SIL International.

.Attributes
[source,yaml]
----
type: sil
version: "1.0.0"          # Semantic version
release_date: "2024-01-01" # Release date
----

.Key Methods
* `differentiation_key()` - Returns version string
* `outdated?(new_source)` - Compares versions using Gem::Version

== Extensibility

=== Adding a New Import Source

To add support for a new font source:

1. **Create subclass** of ImportSource
2. **Implement required methods**: `differentiation_key()`, `outdated?()`
3. **Add polymorphic configuration** to ImportSource and Formula
4. **Update FormulaBuilder** with setter method
5. **Create importer** that generates import_source instances

.Example: Adobe Import Source
[source,ruby]
----
class AdobeImportSource < ImportSource
  attribute :version, :string
  attribute :release_date, :string

  key_value do
    map "type", to: :type, default: -> { "adobe" }
    map "version", to: :version
    map "release_date", to: :release_date
  end

  def differentiation_key
    version
  end

  def outdated?(new_source)
    return false unless new_source.is_a?(AdobeImportSource)
    Gem::Version.new(version) < Gem::Version.new(new_source.version)
  end
end
----

.Update polymorphic configuration
[source,ruby]
----
# In ImportSource
key_value do
  map "type", to: :type, polymorphic_map: {
    "macos" => "Fontist::MacosImportSource",
    "google" => "Fontist::GoogleImportSource",
    "sil" => "Fontist::SilImportSource",
    "adobe" => "Fontist::AdobeImportSource",  # Add new mapping
  }
end

# In Formula
attribute :import_source, ImportSource, polymorphic: [
  "MacosImportSource",
  "GoogleImportSource",
  "SilImportSource",
  "AdobeImportSource",  # Add to list
]
----

== File Organization

----
lib/fontist/
├── import_source.rb                  # Base class with polymorphism
├── macos_import_source.rb            # macOS implementation
├── google_import_source.rb           # Google Fonts implementation
├── sil_import_source.rb              # SIL implementation
├── macos_framework_metadata.rb       # Framework metadata (macOS only)
└── formula.rb                        # Formula with polymorphic import_source

formulas/
├── macos/
│   ├── font7/                        # Framework 7 formulas
│   │   ├── al_bayan_10m1360.yml
│   │   └── ...
│   └── font8/                        # Framework 8 formulas
│       ├── sf_pro_26m2001.yml
│       └── ...
├── google/
│   ├── roboto.yml
│   └── ...
└── sil/
    ├── charis_sil_1.0.0.yml
    └── ...
----

== Benefits

✅ **Clean Separation**: Framework metadata separate from font data +
✅ **Type Safety**: Lutaml-model polymorphism ensures correct types +
✅ **Versioning**: Multiple versions of same font coexist +
✅ **Update Detection**: Automatic detection of outdated formulas +
✅ **Extensibility**: Easy to add new import sources +
✅ **MECE**: Each concern handled in exactly one place +
✅ **Single Source of Truth**: Framework metadata in one location +

== Testing

The import source system includes comprehensive test coverage:

.Test files
* `spec/fontist/import_source_spec.rb` - Base class tests
* `spec/fontist/macos_import_source_spec.rb` - macOS-specific tests
* `spec/fontist/google_import_source_spec.rb` - Google Fonts tests
* `spec/fontist/sil_import_source_spec.rb` - SIL tests
* `spec/fontist/macos_framework_metadata_spec.rb` - Framework metadata tests

.Test coverage includes
* Polymorphic serialization/deserialization
* Round-trip YAML conversion
* Version comparison logic
* Framework metadata lookups
* Platform compatibility checks
* Equality comparisons

== Migration Notes

=== From Previous Architecture

Prior to the import source system, macOS formulas stored framework metadata
directly in each formula file (`catalog_version`, `min_macos_version`,
`max_macos_version`).

The new architecture:
* Removes these attributes from Formula
* Adds `import_source` with framework_version
* Stores framework metadata externally in MacosFrameworkMetadata
* Uses polymorphic ImportSource classes

=== Backward Compatibility

Formulas without `import_source` (manually created) continue to work normally.
The `import_source` attribute is optional and defaults to `nil`.

== References

* Implementation files in [`lib/fontist/`](../lib/fontist/)
* Complete test suite in [`spec/fontist/`](../spec/fontist/)
* Implementation plan: [`IMPORT_SOURCE_IMPLEMENTATION_PLAN.md`](../IMPORT_SOURCE_IMPLEMENTATION_PLAN.md)
* Final status: [`IMPORT_SOURCE_FINAL_STATUS.md`](../IMPORT_SOURCE_FINAL_STATUS.md)