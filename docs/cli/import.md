# fontist import

Import fonts from external sources and create Fontist formulas.

## Subcommands

| Command | Description |
|---------|-------------|
| [`fontist import google`](#import-google) | Import Google Fonts |
| [`fontist import macos`](#import-macos) | Import macOS supplementary fonts |
| [`fontist import sil`](#import-sil) | Import SIL International fonts |

---

## import google

Import fonts from the Google Fonts repository.

### Syntax

```sh
fontist import google [options]
```

### Options

| Option | Type | Description |
|--------|------|-------------|
| `--source-path` | string | Path to checked-out google/fonts repository |
| `--output-path` | string | Output path for generated formulas (default: ./Formulas/google) |
| `--font-name` | string | Import specific font family by name |
| `--force` | boolean | Overwrite existing formulas |
| `--verbose` | boolean | Enable verbose output |
| `--import-cache` | string | Directory for import cache |

### Examples

```sh
# Import all Google fonts
fontist import google

# Import a specific font
fontist import google --font-name "Roboto"

# Import with custom source
fontist import google --source-path /path/to/google/fonts
```

---

## import macos

Import macOS supplementary fonts from system catalogs.

### Syntax

```sh
fontist import macos [options]
```

### Options

| Option | Type | Description |
|--------|------|-------------|
| `--plist` | string | Path to macOS font catalog XML |
| `--output-path` | string | Output directory for generated formulas |
| `--font-name` | string | Import specific font by name |
| `--force` | boolean | Overwrite existing formulas |
| `--verbose` | boolean | Enable verbose output |
| `--import-cache` | string | Directory for import cache |

### Examples

```sh
# Import from detected macOS catalogs
fontist import macos

# Import from specific catalog
fontist import macos --plist /path/to/com_apple_MobileAsset_Font8.xml

# Import specific font
fontist import macos --font-name "SF Pro"
```

### Finding macOS Catalogs

Run `fontist macos-catalogs` to list available font catalogs on your system.

---

## import sil

Import fonts from SIL International.

### Syntax

```sh
fontist import sil [options]
```

### Options

| Option | Type | Description |
|--------|------|-------------|
| `--output-path` | string | Output directory for generated formulas |
| `--font-name` | string | Import specific font by name |
| `--force` | boolean | Overwrite existing formulas |
| `--verbose` | boolean | Enable verbose output |
| `--import-cache` | string | Directory for import cache |

### Examples

```sh
# Import all SIL fonts
fontist import sil

# Import specific font
fontist import sil --font-name "Gentium Plus"
```

---

## Use Cases

The import commands are useful for:

- **Formula maintainers**: Creating formulas for new fonts
- **Private fonts**: Creating formulas for internal fonts
- **Bulk imports**: Converting large font collections to Fontist formulas

## Requirements

These commands require additional setup:
- `google`: Access to the google/fonts repository
- `macos`: macOS system or font catalog files
- `sil`: Network access to SIL font servers
