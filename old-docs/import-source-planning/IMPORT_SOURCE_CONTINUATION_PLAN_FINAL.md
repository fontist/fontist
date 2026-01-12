# Import Source Implementation - Continuation Plan

**Status:** Phases 1-7 COMPLETE, Moving to Documentation & Cleanup
**Timeline:** Complete all remaining work immediately
**Current:** All 737 tests passing, formula generation/loading working

---

## Completed Work (Phases 1-7) ✅

### Phase 1-4: Core Implementation
- ✅ Created 5 import source classes with lutaml-model polymorphism
- ✅ Updated Formula and FormulaBuilder
- ✅ Updated catalog parsers and Asset
- ✅ Updated macOS importer logic

### Phase 5-7: Testing & Verification
- ✅ 52 new tests created (all passing)
- ✅ Formula generation verified
- ✅ Formula loading verified  
- ✅ Full test suite: 737 tests passing

---

## Remaining Work (Phases 8-9)

### Phase 8: Documentation Updates (REQUIRED)

#### Update README.adoc
**File:** `README.adoc`

**Add Section:** "Import Source Architecture"

Location: After the "Formula Repository" section

Content to add:
```adoc
=== Import Source Architecture

Fontist tracks the source and metadata of imported formulas using a polymorphic
`import_source` attribute.

==== General

The `import_source` attribute contains metadata about where and when a font
formula was imported from, enabling:

* Formula versioning and update detection
* Platform compatibility checks
* Audit trail for formula origins

==== macOS Supplementary Fonts

macOS supplementary fonts use a multi-dimensional versioning system:

Framework Version:: Font7, Font8 - determines schema and parser
Catalog PostedDate:: Version of catalog within framework  
Asset Build ID:: Individual package identifier

.Example import_source for macOS
[source,yaml]
----
import_source:
  type: macos
  framework_version: 7
  posted_date: "2024-08-13T18:11:00Z"
  asset_id: "10m1360"
----

Framework-specific metadata (min/max macOS versions, parser classes) is stored
externally in `lib/fontist/macos_framework_metadata.rb` as a Ruby constant.

==== Google Fonts

Google Fonts formulas track the source commit, API version, and family information.

.Example import_source for Google Fonts
[source,yaml]
----
import_source:
  type: google
  commit_id: "abc123def456"
  api_version: "v1"
  last_modified: "2024-01-01T12:00:00Z"
  family_id: "roboto"
----

==== SIL International Fonts

SIL fonts track version and release date information.

.Example import_source for SIL
[source,yaml]
----
import_source:
  type: sil
  version: "1.0.0"
  release_date: "2024-01-01"
----

==== Manual Formulas

Manually created formulas have no import_source attribute (it is `nil`).

==== Implementation

The import source system uses lutaml-model's polymorphic attributes:

* Base class: `Fontist::ImportSource` with `polymorphic_class: true`
* Subclasses: `MacosImportSource`, `GoogleImportSource`, `SilImportSource`
* Automatic polymorphic deserialization based on `type` field

Each import source provides:

* `differentiation_key()` - Unique identifier for version comparison
* `outdated?(new_source)` - Check if formula needs updating
* Source-specific methods (e.g., `min_macos_version()` for macOS)
----
```

#### Create Architecture Documentation
**File:** `docs/import-source-architecture.md`

**Content:**
```adoc
= Import Source Architecture

== Overview

The Import Source architecture provides a polymorphic system for tracking the
origin and version of font formulas in Fontist.

== Design Principles

=== Separation of Concerns

Formula metadata is separated into three layers:

Font data:: Stored in Formula (fonts, styles, resources)
Import metadata:: Stored in ImportSource (framework version, dates, IDs)
Framework metadata:: Stored in MacosFrameworkMetadata constant (version ranges, parsers)

=== Polymorphic Design

Import sources use lutaml-model's polymorphic attributes for type-safe
deserialization.

[source,ruby]
----
class ImportSource < Lutaml::Model::Serializable
  attribute :type, :string, polymorphic_class: true
end

class MacosImportSource < ImportSource
  attribute :framework_version, :integer
  attribute :posted_date, :string
  attribute :asset_id, :string
end
----

== Class Hierarchy

[source]
----
ImportSource (abstract)
  ├─ MacosImportSource
  │    Methods: min_macos_version(), max_macos_version(),
  │             compatible_with_macos?()
  ├─ GoogleImportSource  
  │    Methods: (version tracking via commit_id)
  └─ SilImportSource
       Methods: (version tracking via version string)
----

== Formula Structure

=== With Import Source
[source,yaml]
----
name: Al Bayan
platforms:
  - macos-font7
import_source:
  type: macos
  framework_version: 7
  posted_date: "2024-08-13T18:11:00Z"
  asset_id: "10m1360"
resources:
  # ... resources ...
----

=== Without Import Source (Manual Formula)
[source,yaml]
----
name: Custom Font
resources:
  # ... resources ...
# No import_source attribute
----

== Framework Metadata System

=== Rationale

Framework-specific metadata (version ranges, parser classes) is stored
externally to formulas to maintain proper separation of concerns.

This metadata is not part of individual fonts but describes the framework
itself.

=== Implementation

File: `lib/fontist/macos_framework_metadata.rb`

[source,ruby]
----
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
----

=== Usage

[source,ruby]
----
source = MacosImportSource.new(framework_version: 7)
source.min_macos_version         # => "10.11"
source.compatible_with_macos?("12.0")  # => true
----

== Version Differentiation

=== macOS Fonts

macOS fonts are differentiated by:

1. **Framework version** (7 vs 8) - Different schemas
2. **Posted date** - Catalog version within framework
3. **Asset ID** - Individual package build

Filename: `{normalized_name}_{asset_id}.yml`

Example: `al_bayan_10m1360.yml`

=== Google Fonts

Google Fonts are differentiated by commit ID from the google/fonts repository.

=== SIL Fonts

SIL fonts are differentiated by version string.

== Update Detection

Each ImportSource implements `outdated?(new_source)`:

[source,ruby]
----
old_source.outdated?(new_source)  # => true if old_source should be replaced
----

Implementation varies by source type:
- macOS: Compares posted_date
- Google: Compares commit_id
- SIL: Compares version strings

== Extensibility

To add a new import source:

1. Create subclass of `ImportSource`
2. Implement `differentiation_key()` and `outdated?()`
3. Add to polymorphic configuration in `ImportSource` and `Formula`
4. Update `FormulaBuilder` with setter method

Example:

[source,ruby]
----
class AdobeImportSource < ImportSource
  attribute :version, :string
  attribute :release_date, :string
  
  def differentiation_key
    version
  end
  
  def outdated?(new_source)
    version < new_source.version
  end
end
----
```

---

### Phase 9: Cleanup (REQUIRED)

#### Move Planning Documents to old-docs/

**Files to move:**
- `MACOS_POSTED_DATE_VERSIONING_PLAN.md`
- `MACOS_POSTED_DATE_VERSIONING_CORRECTED_PLAN.md`
- `MACOS_FONT_PLATFORM_VERSIONING.md`
- `MACOS_FONT_PLATFORM_VERSIONING_PROMPT.md`
- `MACOS_FONT_PLATFORM_VERSIONING_IMPLEMENTATION_PLAN.md`
- `MACOS_FONT_PLATFORM_VERSIONING_STATUS.md`
- `MACOS_IMPORT_SOURCE_FINAL_PLAN.md`
- `IMPORT_SOURCE_CONTINUATION_PROMPT.md`
- All other temporary multi-version/testing continuation plans

**Keep in root:**
- `IMPORT_SOURCE_IMPLEMENTATION_PLAN.md` - Main plan
- `IMPORT_SOURCE_IMPLEMENTATION_STATUS.md` - Status tracker
- `IMPORT_SOURCE_FINAL_STATUS.md` - Final report
- `MACOS_IMPORT_SOURCE_CORRECTED_ARCHITECTURE.md` - Architecture spec

#### Archive Implementation Documentation

**Move to old-docs/:**
- Any CONTINUATION_PROMPT_*.md files
- MACOS_MULTI_VERSION_*.md files
- MACOS_ONDEMAND_TESTING_*.md files

---

## Implementation Priority

**IMMEDIATE (Today):**
1. Update README.adoc with import_source section
2. Create docs/import-source-architecture.md
3. Move obsolete planning docs to old-docs/

**OPTIONAL (Can defer):**
- Additional README examples
- Migration guide for existing formulas

---

## Verification Checklist

Before completing:
- [x] All 737 tests passing
- [x] Formula generation works
- [x] Formula loading works with polymorphic deserialization
- [x] import_source attributes accessible
- [x] Framework metadata methods working
- [ ] README.adoc updated
- [ ] Architecture docs created
- [ ] Old docs archived

---

## Notes

### What Made This Work

1. **Proper lutaml-model polymorphism** - Used `polymorphic_class: true` and `polymorphic_map`
2. **Fully qualified class names** - Used `"Fontist::MacosImportSource"` not `"MacosImportSource"`
3. **Framework metadata as constant** - Not YAML file
4. **Proper OOP** - Each class has single responsibility

### Key Files

**Core:**
- `lib/fontist/import_source.rb` - Base class
- `lib/fontist/macos_import_source.rb` - macOS implementation
- `lib/fontist/macos_framework_metadata.rb` - Framework metadata
- `lib/fontist/formula.rb` - Updated Formula with polymorphic import_source

**Critical for polymorphism:**
- Attribute: `polymorphic_class: true` on `:type`
- Mapping: `polymorphic_map` in key_value block
- Formula: `polymorphic:` option with class list
