---
title: Importing Fonts from External Sources
---

# Importing Fonts from External Sources

::: warning Maintainer Only
The documentation is for Fontist formula maintainers only. End users should use `fontist install` to install fonts from the official repository.
:::

Fontist can automatically generate formulas from external font sources including Google Fonts, macOS supplementary fonts, and SIL International fonts.

---

## Google Fonts Import

### Overview

[Google Fonts](https://fonts.google.com) provides the largest collection of freely licensed fonts. Fontist maintains formulas for all Google Fonts and supports importing them.

### Data Sources

The Google Fonts importer uses multiple data sources:

#### Four Equal Data Sources

| Source | Provides |
|--------|----------|
| **Ttf** (API) | TTF download URLs |
| **Vf** (API) | Variable font URLs + axes information |
| **Woff2** (API) | WOFF2 web font URLs |
| **Github** (Repo) | Font metadata (designer, license, category) |

### Architecture

The importer uses a layered architecture.

```
        ┌──────────────────────────┐
        │   FontDatabase           │
        │   (Single Entry Point)   │
        └───────────┬──────────────┘
                    │
      ┌─────────────┼─────────────┬─────────────┐
      │             │             │             │
      ▼             ▼             ▼             ▼
┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐
│   Ttf    │  │    Vf    │  │  Woff2   │  │  Github  │
│  (API)   │  │  (API)   │  │  (API)   │  │  (Repo)  │
└──────────┘  └──────────┘  └──────────┘  └──────────┘

All 4 Data Sources Are Equal
```

### Prerequisites

1. **Local checkout** of the [google/fonts](https://github.com/google/fonts) repository

2. **Google Fonts API key** (get one from [Google Cloud Console](https://console.cloud.google.com/))

   ```sh
   export GOOGLE_FONTS_API_KEY="your_api_key_here"
   ```

### Import Command

Import all Google Fonts.

```sh
fontist import google \
  --source-path /path/to/google/fonts \
  --output-path Formulas/google \
  --verbose \
  --import-cache /tmp/fontist-google-cache
```

Import a single font family.

```sh
fontist import google \
  --font-family "Roboto" \
  --source-path /path/to/google/fonts \
  --verbose
```

### Options

| Option | Description |
|--------|-------------|
| `--source-path` | Path to checked-out google/fonts repository |
| `--output-path` | Output directory for generated formulas (default: `./Formulas/google`) |
| `--font-family` | Import specific font family by name |
| `--force` | Overwrite existing formulas |
| `--verbose` | Enable detailed progress output |
| `--import-cache` | Directory for caching downloaded archives |

### Ruby API

```ruby
require 'fontist/import/google/font_database'

# Build database from all 4 sources
db = Fontist::Import::Google::FontDatabase.build(
  api_key: ENV['GOOGLE_FONTS_API_KEY'],
  source_path: '/path/to/google/fonts'
)

# Query merged data
roboto = db.font_by_name('Roboto')
puts roboto.designer      # From Github repository
puts roboto.axes.count    # From API (VF endpoint)

# Generate formulas
db.save_formulas('./formulas')              # All fonts
db.save_formulas('./formulas', family_name: 'Roboto')  # Single font
```

### Automated Updates

Fontist uses a [GitHub Actions workflow](https://github.com/fontist/formulas/blob/v4/.github/workflows/google.yml) to check for updated fonts on Google Fonts daily.

New, updated, or removed fonts are automatically committed to the [Fontist formula repository](https://github.com/fontist/formulas).

---

## SIL Fonts Import

### Overview

[SIL International](https://www.sil.org) is an organization that serves language communities worldwide. SIL provides unique fonts supporting smaller language communities with Unicode support often not available in mainstream fonts.

### Import Command

Import all SIL fonts.

```sh
fontist import sil \
  --output-path Formulas/sil \
  --verbose \
  --import-cache /tmp/sil-import-cache
```

Import a single SIL font.

```sh
fontist import sil \
  --font-name "Andika" \
  --output-path Formulas/sil \
  --verbose \
  --import-cache /tmp/sil-import-cache
```

### Options

| Option | Description |
|--------|-------------|
| `--output-path` | Output directory for generated formulas |
| `--font-name` | Import specific font by name |
| `--force` | Overwrite existing formulas |
| `--verbose` | Enable detailed progress output |
| `--import-cache` | Directory for caching downloaded archives |

---

## macOS Supplementary Fonts Import

### Overview

macOS supplementary fonts use multi-dimensional versioning with framework versions, catalog posted dates, and asset build IDs.

### Import Command

Import from macOS font catalogs.

```sh
fontist import macos \
  --plist com_apple_MobileAsset_Font7.xml \
  --output-path Formulas/macos/font7 \
  --verbose \
  --import-cache /tmp/fontist-macos-cache \
  --force
```

Import a single macOS font.

```sh
fontist import macos \
  --plist com_apple_MobileAsset_Font7.xml \
  --font-name "Hiragino" \
  --output-path Formulas/macos/font7 \
  --verbose
```

### Finding Catalog Files

Run `fontist macos-catalogs` to list available font catalogs on your system.

### Catalog URLs

Catalogs are also available from Apple's Mobile Asset Server.

| Version | URL |
|---------|-----|
| Font 3 | `https://mesu.apple.com/assets/macos/com_apple_MobileAsset_Font3/com_apple_MobileAsset_Font3.xml` |
| Font 4 | `https://mesu.apple.com/assets/macos/com_apple_MobileAsset_Font4/com_apple_MobileAsset_Font4.xml` |
| Font 5 | `https://mesu.apple.com/assets/macos/com_apple_MobileAsset_Font5/com_apple_MobileAsset_Font5.xml` |
| Font 6 | `https://mesu.apple.com/assets/macos/com_apple_MobileAsset_Font6/com_apple_MobileAsset_Font6.xml` |
| Font 7 | `https://mesu.apple.com/assets/macos/com_apple_MobileAsset_Font7/com_apple_MobileAsset_Font7.xml` |
| Font 8 | `https://mesu.apple.com/assets/macos/com_apple_MobileAsset_Font8/com_apple_MobileAsset_Font8.xml` |

---

## Import Source Architecture

### Import Source Attribute

Formulas with import sources track metadata about their origin.

#### macOS Import Source

```yaml
import_source:
  type: macos
  framework_version: 7
  posted_date: "2024-08-13T18:11:00Z"
  asset_id: "10m1360"
```

#### Google Fonts Import Source

```yaml
import_source:
  type: google
  commit_id: "abc123def456"
  api_version: "v1"
  last_modified: "2024-01-01T12:00:00Z"
  family_id: "roboto"
```

#### SIL Import Source

```yaml
import_source:
  type: sil
  version: "1.0.0"
  release_date: "2024-01-01"
```

### Versioned Filenames

Import source type determines filename format.

| Source | Format | Example |
|--------|--------|---------|
| macOS | `{name}_{asset_id}.yml` | `al_bayan_10m1360.yml` |
| Google | `{name}.yml` | `roboto.yml` (no versioning) |
| SIL | `{name}_{version}.yml` | `charis_sil_6.200.yml` |

### Why Different Strategies?

- **macOS**: Multiple versions coexist for different macOS versions
- **Google**: Live service always points to latest; commit tracked for metadata only
- **SIL**: Versioned releases need coexistence

---

## Import Cache Management

### Overview

During formula imports, Fontist downloads font archives for analysis. The import cache optimizes performance and avoids redundant downloads.

Default location: `~/.fontist/import_cache`

### Configuration Methods

#### CLI Option

```sh
fontist import google --import-cache /custom/path ...
fontist import macos --import-cache /custom/path ...
fontist import sil --import-cache /custom/path ...
```

#### Ruby API

```ruby
# Global setting
Fontist.import_cache_path = "/custom/import/cache"

# Per-import setting
Fontist::Import::Macos.new(
  plist_path,
  import_cache: "/custom/cache"
).call
```

#### Environment Variable

```sh
export FONTIST_IMPORT_CACHE=/custom/import/cache
fontist import macos ...
```

### Cache Management

Clear the import cache.

```sh
fontist cache clear-import
```

View cache information.

```sh
fontist cache info
```

---

## Verbose Output

Enable `--verbose` for detailed progress tracking.

```sh
fontist import macos --plist catalog.xml --verbose
```

Output includes.

- Paint-colored headers with Unicode box characters
- Import cache location
- Download URLs and cache status
- Extraction directory paths
- Real-time progress with percentages
- Per-font status indicators
- Detailed summary statistics

### Example Output

```
════════════════════════════════════════════════════════════════════
  📦 macOS Supplementary Fonts Import
════════════════════════════════════════════════════════════════════

📦 Import cache: /Users/user/.fontist/import_cache
📁 Output path: /Users/user/.fontist/versions/v4/formulas/Formulas/macos/font7

(1/3) 33.3% | Hiragino Sans (2 fonts)
Downloading from: https://updates.cdn-apple.com/.../font.zip
  Cache location: /Users/user/.fontist/import_cache
  Extracting to: /var/folders/.../temp
  Extraction cache cleared
  ✓ Formula created: hiragino_sans_10m1044.yml (3.98s)

════════════════════════════════════════════════════════════════════
  📊 Import Summary
════════════════════════════════════════════════════════════════════

  Total packages:     3
  ✓ Successful:     3 (100.0%)

  🎉 Great success! 3 formulas created!
```

---

## See Also

- [Formulas Guide](/guide/formulas) - How formulas work
- [repo Command](/cli/repo) - Managing formula repositories
- [cache Command](/cli/cache) - Cache management
