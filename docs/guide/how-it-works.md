---
title: How Fontist Works
---

# How Fontist Works

Understanding Fontist's internal architecture helps you use it effectively and troubleshoot issues.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         Fontist                                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐          │
│  │   Formulas  │    │   Indexes   │    │   Fonts     │          │
│  │  (Recipes)  │    │  (Catalogs) │    │  (Files)    │          │
│  └──────┬──────┘    └──────┬──────┘    └──────┬──────┘          │
│         │                  │                  │                  │
│         │    ┌─────────────┴─────────────┐    │                  │
│         │    │                           │    │                  │
│         └────┤     Font Lookup          ├────┘                  │
│              │                           │                        │
│              └─────────────┬─────────────┘                        │
│                            │                                      │
│                            ▼                                      │
│                    ┌───────────────┐                              │
│                    │  Return Paths │                              │
│                    └───────────────┘                              │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Directory Structure

Fontist stores all its data in `~/.fontist/`:

```
~/.fontist/
├── fonts/                          # Installed font files
│   ├── roboto/                     # Fonts organized by formula
│   │   ├── Roboto-Regular.ttf
│   │   └── Roboto-Bold.ttf
│   └── open-sans/
│       └── OpenSans-Regular.ttf
│
├── versions/
│   └── v4/
│       ├── formulas/               # Git clone of formulas repo
│       │   └── Formulas/
│       │       ├── roboto.yml
│       │       └── private/        # Custom formula repos
│       │           └── my-org/
│       │
│       ├── formula_index.default_family.yml    # Formula index
│       ├── formula_index.preferred_family.yml  # Alternative naming
│       └── filename_index.yml                  # Filename lookup
│
├── fontist_index.default_family.yml  # Fontist-installed fonts
├── system_index.default_family.yml   # OS system fonts
└── user_index.default_family.yml     # User-installed fonts
```

---

## Font Indexes

Fontist maintains multiple indexes for fast font lookups. Each index catalogs fonts from a different source.

### Index Types

| Index | Source | Path |
|-------|--------|------|
| **Formula Index** | Formula YAML files | `~/.fontist/versions/v4/formula_index.*.yml` |
| **System Index** | OS-installed fonts | `~/.fontist/system_index.*.yml` |
| **Fontist Index** | Fonts installed by Fontist | `~/.fontist/fontist_index.*.yml` |
| **User Index** | User font directory | `~/.fontist/user_index.*.yml` |

### Formula Index

Maps font names to formula files for fast lookups:

```yaml
# formula_index.default_family.yml
roboto:
  - roboto.yml
open sans:
  - open_sans.yml
segoe ui:
  - segoe_ui.yml
  - macos/segoe_ui.yml  # Can have multiple sources
```

### System Font Index

Catalogs fonts already installed on your operating system:

```yaml
# system_index.default_family.yml
- path: /System/Library/Fonts/Helvetica.ttc
  full_name: Helvetica
  family_name: Helvetica
  subfamily: Regular
  file_size: 1034204
  file_mtime: 1699900000
```

The system index includes smart caching:
- **Timestamp checks**: Skips re-indexing if directories haven't changed
- **File metadata**: Uses size and mtime to detect changes
- **30-minute threshold**: Trusts recent scans without re-checking

### Font Lookup Order

When you search for a font, Fontist checks indexes in this order:

```
1. Fontist Index    → ~/.fontist/fonts/
2. User Index       → Platform user fonts + /fontist/
3. System Index     → OS system fonts
4. Formula Index    → Download if not found
```

---

## System Font Detection

Fontist automatically detects fonts in OS-specific locations.

### macOS

```
/Library/Fonts/**/*.ttf
/System/Library/Fonts/**/*.ttf
~/Library/Fonts/*.ttf
/Applications/Microsoft*/Contents/Resources/**/*.ttf
/System/Library/AssetsV2/com_apple_MobileAsset_Font*/**/*.ttf
```

### Windows

```
C:\Windows\Fonts\**\*.ttf
C:\Users\{username}\AppData\Local\Microsoft\Windows\Fonts\**\*.ttf
C:\Program Files\Common Files\Microsoft\**\*.ttf
```

### Linux

```
/usr/share/fonts/**/*.ttf
~/.local/share/fonts/**/*.ttf
```

---

## Configuration Priority

Fontist uses a unified configuration system with a clear priority order. Settings can come from multiple sources, but higher-priority sources always override lower ones.

### Priority Order (Highest to Lowest)

| Priority | Source | Example | Scope |
|----------|--------|---------|-------|
| 1 | **Environment Variable** | `FONTIST_PATH=/custom` | Process-wide |
| 2 | **Config File** | `~/.fontist/config.yml` | Persistent |
| 3 | **CLI Option** | `--location user` | Single command |
| 4 | **Ruby API** | `Fontist.preferred_family = true` | Current session |
| 5 | **Default Value** | Built-in defaults | Fallback |

### Example: Install Location Priority

```sh
# Priority 1: ENV VAR wins
export FONTIST_INSTALL_LOCATION=user
fontist install "Roboto" --location system  # Still uses "user"!

# To override ENV, unset it first
unset FONTIST_INSTALL_LOCATION
fontist install "Roboto" --location system  # Now uses "system"
```

### Configuration Settings

| Setting | ENV VAR | Config Key | CLI Option | Default |
|--------|---------|------------|------------|---------|
| Base path | `FONTIST_PATH` | - | - | `~/.fontist` |
| Fonts path | - | `fonts_path` | - | `~/.fontist/fonts` |
| Formulas path | `FONTIST_FORMULAS_PATH` | - | `--formulas-path` | (auto) |
| Install location | `FONTIST_INSTALL_LOCATION` | `fonts_install_location` | `--location` | `fontist` |
| User fonts path | `FONTIST_USER_FONTS_PATH` | `user_fonts_path` | - | Platform default |
| System fonts path | `FONTIST_SYSTEM_FONTS_PATH` | `system_fonts_path` | - | Platform default |
| Preferred family | - | `preferred_family` | `--preferred-family` | `false` |
| No cache | - | - | `--no-cache` | `false` |

---

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `FONTIST_PATH` | Base directory for all Fontist data | `~/.fontist` |
| `FONTIST_FORMULAS_PATH` | Custom formulas directory | (auto) |
| `FONTIST_INSTALL_LOCATION` | Default install location | `fontist` |
| `FONTIST_USER_FONTS_PATH` | Custom user fonts path | Platform default |
| `FONTIST_SYSTEM_FONTS_PATH` | Custom system fonts path | Platform default |
| `FONTIST_IMPORT_CACHE` | Import cache directory | `~/.fontist/import_cache` |
| `FONTIST_NO_MIRRORS` | Disable formula index mirrors | `false` |
| `GOOGLE_FONTS_API_KEY` | Google Fonts API key | (none) |

### Example: Custom Fontist Path

```sh
# Use a different base directory
export FONTIST_PATH=/opt/fontist
fontist install "Roboto"
# Installs to /opt/fontist/fonts/roboto/
```

---

## Installation Locations

Fonts can be installed to different locations:

| Location | Path | Use Case |
|----------|------|----------|
| **fontist** (default) | `~/.fontist/fonts/{formula}/` | Isolated, safe, recommended |
| **user** | Platform-specific + `/fontist/` | Available to all apps |
| **system** | System fonts dir + `/fontist/` | All users (requires admin) |

### Platform-Specific User Paths

| Platform | User Font Path |
|----------|----------------|
| macOS | `~/Library/Fonts/fontist/` |
| Linux | `~/.local/share/fonts/fontist/` |
| Windows | `%LOCALAPPDATA%\Microsoft\Windows\Fonts\fontist\` |

### Specifying Location

```sh
# Default: install to ~/.fontist/fonts/
fontist install "Roboto"

# Install to user fonts directory
fontist install "Roboto" --location user

# Install system-wide (requires admin)
sudo fontist install "Roboto" --location system
```

---

## Font Lookup Flow

When you run `fontist install "Open Sans"`:

```
┌─────────────────────────────────────────────────────────────┐
│ Step 1: Check Installed Fonts                               │
│   Search Fontist Index → Found? → Return paths              │
│   Search User Index    → Found? → Return paths              │
│   Search System Index  → Found? → Return paths              │
└─────────────────────────┬───────────────────────────────────┘
                          │ Not found
                          ▼
┌─────────────────────────────────────────────────────────────┐
│ Step 2: Search Formulas                                     │
│   Look up "open sans" in Formula Index                      │
│   Found formula: open_sans.yml                              │
└─────────────────────────┬───────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│ Step 3: Download & Install                                  │
│   Parse formula → Get download URL                          │
│   Download archive → Verify checksum                        │
│   Extract fonts → Install to ~/.fontist/fonts/open-sans/    │
│   Update Fontist Index                                      │
└─────────────────────────┬───────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│ Step 4: Return Paths                                        │
│   Return: ["/home/user/.fontist/fonts/open-sans/OpenSans-   │
│            Regular.ttf", ...]                               │
└─────────────────────────────────────────────────────────────┘
```

---

## Index Management

### Automatic Rebuilding

Indexes are rebuilt automatically when:
- Formulas repository is updated (`fontist update`)
- A new formula repo is added (`fontist repo add`)
- Fonts are installed or uninstalled

### Manual Index Commands

```sh
# Rebuild all indexes from scratch
fontist index rebuild

# Show index file location
fontist index path

# List all indexed fonts
fontist index list

# Clear index (forces rebuild on next access)
fontist index clear

# Show index statistics
fontist index info
```

### Index Update Strategies

| Command | When to Use |
|---------|-------------|
| `fontist update` | Get latest formulas and rebuild indexes |
| `fontist index rebuild` | Full system font rescan (slow but complete) |
| `fontist index update` | Incremental update (fast, detects changes) |

---

## Configuration Priority

Fontist uses a unified configuration system with a clear priority order. Settings can come from multiple sources, but higher-priority sources always override lower ones.

### Priority Order (Highest to Lowest)

| Priority | Source | Example | Scope |
|----------|--------|---------|-------|
| 1 | **Environment Variable** | `FONTIST_PATH=/custom` | Process-wide |
| 2 | **Config File** | `~/.fontist/config.yml` | Persistent |
| 3 | **CLI Option** | `--location user` | Single command |
| 4 | **Ruby API** | `Fontist.preferred_family = true` | Current session |
| 5 | **Default Value** | Built-in defaults | Fallback |

### Example: Install Location Priority

```sh
# Priority 1: ENV VAR wins
export FONTIST_INSTALL_LOCATION=user
fontist install "Roboto" --location system  # Still uses "user"!

# To override ENV, unset it first
unset FONTIST_INSTALL_LOCATION
fontist install "Roboto" --location system  # Now uses "system"
```

### Configuration Settings Matrix

| Setting | ENV VAR | Config Key | CLI Option | Default |
|---------|---------|------------|------------|---------|
| Base path | `FONTIST_PATH` | - | - | `~/.fontist` |
| Fonts path | - | `fonts_path` | - | `~/.fontist/fonts` |
| Formulas path | `FONTIST_FORMULAS_PATH` | - | `--formulas-path` | (auto) |
| Install location | `FONTIST_INSTALL_LOCATION` | `fonts_install_location` | `--location` | `fontist` |
| User fonts path | `FONTIST_USER_FONTS_PATH` | `user_fonts_path` | - | Platform default |
| System fonts path | `FONTIST_SYSTEM_FONTS_PATH` | `system_fonts_path` | - | Platform default |
| Preferred family | `FONTIST_PREFERRED_FAMILY` | `preferred_family` | `--preferred-family` | `false` |
| Open timeout | - | `open_timeout` | - | `60` |
| Read timeout | - | `read_timeout` | - | `60` |
| Google Fonts key | `GOOGLE_FONTS_API_KEY` | `google_fonts_key` | - | `nil` |

---

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `FONTIST_PATH` | Base directory for all Fontist data | `~/.fontist` |
| `FONTIST_FORMULAS_PATH` | Custom formulas directory | (auto) |
| `FONTIST_INSTALL_LOCATION` | Default install location (`fontist`, `user`, `system`) | `fontist` |
| `FONTIST_USER_FONTS_PATH` | Custom user fonts path | Platform default |
| `FONTIST_SYSTEM_FONTS_PATH` | Custom system fonts path | Platform default |
| `FONTIST_IMPORT_CACHE` | Import cache directory | `~/.fontist/import_cache` |
| `FONTIST_NO_MIRRORS` | Disable formula index mirrors | `false` |
| `FONTIST_PREFERRED_FAMILY` | Use preferred family naming | `false` |
| `GOOGLE_FONTS_API_KEY` | Google Fonts API key | (none) |

### Example: Custom Fontist Path

```sh
# Use a different base directory
export FONTIST_PATH=/opt/fontist
fontist install "Roboto"
# Installs to /opt/fontist/fonts/roboto/
```

---

## Managed vs Non-Managed Locations

### Managed Locations (Fontist controls)

When using default paths or paths with `/fontist/` subdirectory:
- `~/.fontist/fonts/` - Always managed
- `~/Library/Fonts/fontist/` - Managed subdirectory
- `/Library/Fonts/fontist/` - Managed subdirectory

**Behavior:** Fontist safely replaces existing fonts

### Non-Managed Locations (custom paths)

When you set custom root paths via ENV:
- `FONTIST_USER_FONTS_PATH=~/Library/Fonts` → installs directly to user fonts
- `FONTIST_SYSTEM_FONTS_PATH=/Library/Fonts` → installs directly to system fonts

**Behavior:** Fontist uses unique filenames (`-fontist` suffix) to avoid overwriting existing fonts

---

## See Also

- [Formulas Guide](/guide/formulas) - How formulas work
- [Installation Guide](/guide/installation) - Installing Fontist
- [CLI Reference: index](/cli/index-cmd) - Index commands
- [CLI Reference: repo](/cli/repo) - Repository management
