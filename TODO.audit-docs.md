# TODO: Documentation Audit

## Purpose
Audit all Fontist Ruby gem functionality to ensure complete documentation coverage.

## Reference Files
- docs/guide/how-it-works.md
- docs/api/
- docs/cli/
- docs/guide/concepts/

**Last Updated:** 2026-03-10

---

## ✅ COMPLETED

### 1. Configuration Priority System
Documented in `/guide/how-it-works.md`

**Priority Order (Highest to Lowest):**

| Priority | Source | Example | Notes |
|----------|--------|---------|-------|
| 1 | ENV VAR | `FONTIST_PATH=/custom` | Always wins |
| 2 | Config file | `~/.fontist/config.yml` | Persistent settings |
| 3 | CLI option | `--location user` | Per-command override |
| 4 | Ruby API | `Fontist.preferred_family = true` | Programmatic |
| 5 | Default | Built-in defaults | Fallback |

### 2. Installation Locations
Documented in `/guide/how-it-works.md`

| Type | Path | Managed? | Use Case |
|------|------|----------|----------|
| fontist | `~/.fontist/fonts/{formula}/` | ✅ Yes | Default, isolated |
| user | `~/Library/Fonts/fontist/` (macOS) | ✅ Yes | User-wide access |
| system | `/Library/Fonts/fontist/` (macOS) | ✅ Yes | All users |

### 3. Font Indexes
Documented in `/guide/how-it-works.md`

- Formula Index: Maps font names → formula files
- System Index: OS-installed fonts
- Fontist Index: Fonts installed via Fontist
- User Index: User-installed fonts

### 4. Formula Repository
Documented in `/guide/formulas.md`

- Location: `~/.fontist/versions/v4/formulas/`
- Git clone from `https://github.com/fontist/formulas.git`
- Auto-updates via `fontist update`
- Private repos via `fontist repo`

### 5. CLI Commands
All documented in `/docs/cli/`

### 6. Ruby API Classes
All documented in `/docs/api/`

---

## 🔄 IN PROGRESS

- [ ] Add configuration priority table to how-it-works.md
- [ ] Add managed vs non-managed location explanation
- [ ] Document all ENV variables in reference page

---

## Configuration Reference

### All Configuration Settings

| Setting | ENV VAR | Config Key | CLI Option | Default |
|---------|---------|------------|------------|---------|
| Base path | `FONTIST_PATH` | - | - | `~/.fontist` |
| Fonts path | - | `fonts_path` | - | `~/.fontist/fonts` |
| Formulas path | `FONTIST_FORMULAS_PATH` | - | `--formulas-path` | (auto) |
| Install location | `FONTIST_INSTALL_LOCATION` | `fonts_install_location` | `--location` | `fontist` |
| User fonts path | `FONTIST_USER_FONTS_PATH` | `user_fonts_path` | - | Platform default |
| System fonts path | `FONTIST_SYSTEM_FONTS_PATH` | `system_fonts_path` | - | Platform default |
| Preferred family | - | `preferred_family` | `--preferred-family` | `false` |
| No cache | - | - | `--no-cache` | `false` |
| Quiet mode | - | - | `--quiet` | `false` |
| Verbose | - | - | `--verbose` | `false` |
| Open timeout | - | `open_timeout` | - | `60` |
| Read timeout | - | `read_timeout` | - | `60` |
| Google Fonts key | `GOOGLE_FONTS_API_KEY` | `google_fonts_key` | - | `nil` |
| Import cache | `FONTIST_IMPORT_CACHE` | - | - | `~/.fontist/import_cache` |

---

## Environment Variables Reference

| Variable | Description | Default |
|----------|-------------|---------|
| `FONTIST_PATH` | Base directory for all Fontist data | `~/.fontist` |
| `FONTIST_FORMULAS_PATH` | Custom formulas directory | (auto) |
| `FONTIST_INSTALL_LOCATION` | Default install location (`fontist`, `user`, `system`) | `fontist` |
| `FONTIST_USER_FONTS_PATH` | Custom user fonts path | Platform default |
| `FONTIST_SYSTEM_FONTS_PATH` | Custom system fonts path | Platform default |
| `FONTIST_IMPORT_CACHE` | Import cache directory | `~/.fontist/import_cache` |
| `FONTIST_NO_MIRRORS` | Disable formula index mirrors | `false` |
| `GOOGLE_FONTS_API_KEY` | Google Fonts API key | (none) |

---

## Managed vs Non-Managed Locations

### Managed Locations (Fontist controls)
- `~/.fontist/fonts/` - Always managed
- `~/Library/Fonts/fontist/` - Managed subdirectory
- `/Library/Fonts/fontist/` - Managed subdirectory

**Behavior:** Safe to replace existing fonts

### Non-Managed Locations (custom paths via ENV)
- `FONTIST_USER_FONTS_PATH=~/Library/Fonts` → installs directly
- `FONTIST_SYSTEM_FONTS_PATH=/Library/Fonts` → installs directly

**Behavior:** Uses unique filenames (`-fontist` suffix) to avoid conflicts

---

## Directory Structure

```
~/.fontist/
├── fonts/                          # Installed font files
│   └── {formula-key}/
│       └── *.ttf
├── versions/
│   └── v4/
│       ├── formulas/               # Git clone of formulas repo
│       │   └── Formulas/
│       │       ├── roboto.yml
│       │       └── private/        # Custom formula repos
│       ├── formula_index.default_family.yml
│       ├── formula_index.preferred_family.yml
│       └── filename_index.yml
├── config.yml                      # User configuration
├── downloads/                      # Temporary downloads
├── import_cache/                   # Imported font cache
├── system_index.default_family.yml # System fonts index
├── fontist_index.default_family.yml # Fontist fonts index
└── user_index.default_family.yml   # User fonts index
```

---

## Remaining Minor Gaps

- [ ] Document import system (`fontist import`) internals
- [ ] Document cache system internals
- [ ] Document formula picker algorithm
- [ ] Document locking mechanism (for concurrent operations)

---

## Status: Nearly Complete
**Priority:** High
**Notes:** Core functionality documented, minor gaps remain
