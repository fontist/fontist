# Import Source Deployment Guide

**Date:** 2025-12-29
**Status:** Ready for Production

---

## Quick Start - Manual Import Commands

### Prerequisites

```bash
# 1. Set Google Fonts API key
source ~/.google-fonts-api-key

# 2. Navigate to formulas repository
cd /Users/mulgogi/src/fontist/formulas

# 3. Ensure fontist is installed
cd /Users/mulgogi/src/fontist/fontist && bundle install
```

---

## Import Commands (Run from formulas repository)

### 1. Google Fonts Import

```bash
cd /Users/mulgogi/src/fontist/formulas

# Backup first
cp -r Formulas/google "Formulas/google.backup.$(date +%Y%m%d_%H%M%S)"

# Import all fonts (takes ~2 hours for 1,976 fonts)
source ~/.google-fonts-api-key
bundle exec fontist import google \
  --source-path /Users/mulgogi/src/external/google-fonts \
  --output-path ./Formulas/google \
  --verbose

# Commit
git add Formulas/google
git commit -m "chore(formulas): update Google Fonts with import_source tracking"
git push
```

### 2. SIL International Fonts Import

```bash
cd /Users/mulgogi/src/fontist/formulas

# Backup first
cp -r Formulas/sil "Formulas/sil.backup.$(date +%Y%m%d_%H%M%S)"

# Import (takes ~20 minutes for 40 fonts)
bundle exec fontist import sil

# Copy to formulas repo
cp ~/.fontist/versions/v4/formulas/Formulas/sil/*.yml ./Formulas/sil/

# Commit
git add Formulas/sil
git commit -m "feat(formulas): update SIL fonts with import_source tracking"
git push
```

### 3. macOS Supplementary Fonts Import

**Note:** Must be run on macOS system

```bash
cd /Users/mulgogi/src/fontist/formulas

# Backup first
cp -r Formulas/macos "Formulas/macos.backup.$(date +%Y%m%d_%H%M%S)"

# Download catalogs (if not already available)
curl -o com_apple_MobileAsset_Font7.xml \
  https://mesu.apple.com/assets/macos/com_apple_MobileAsset_Font7/com_apple_MobileAsset_Font7.xml

curl -o com_apple_MobileAsset_Font8.xml \
  https://mesu.apple.com/assets/macos/com_apple_MobileAsset_Font8/com_apple_MobileAsset_Font8.xml

# Import Font7 (macOS 10.11-15.7)
bundle exec fontist import macos \
  --plist com_apple_MobileAsset_Font7.xml \
  --formulas-dir ./Formulas/macos/font7

# Import Font8 (macOS 26.0+) - requires macOS 26 runner
bundle exec fontist import macos \
  --plist com_apple_MobileAsset_Font8.xml \
  --formulas-dir ./Formulas/macos/font8

# Commit
git add Formulas/macos
git commit -m "feat(formulas): update macOS fonts with import_source tracking"
git push
```

---

## GitHub Actions Workflows

### Created Workflows

Three new/updated workflows have been created in `/Users/mulgogi/src/fontist/formulas/.github/workflows/`:

1. **[`google.yml`](../formulas/.github/workflows/google.yml:1)** (updated)
   - **Schedule:** Daily at midnight UTC
   - **Action:** Imports all Google Fonts with import_source
   - **Features:**
     - Checks out google/fonts repo for commit tracking
     - Generates formulas with simple filenames (`roboto.yml`)
     - Auto-commits changes

2. **[`sil.yml`](../formulas/.github/workflows/sil.yml:1)** (new)
   - **Schedule:** Weekly on Sunday at 6am UTC
   - **Action:** Imports all SIL fonts with import_source
   - **Features:**
     - Generates versioned filenames (`charis_sil_6.200.yml`)
     - Auto-commits changes
     - Error reporting

3. **[`macos.yml`](../formulas/.github/workflows/macos.yml:1)** (new)
   - **Schedule:** Weekly on Sunday at 12pm UTC
   - **Action:** Imports macOS supplementary fonts
   - **Platforms:**
     - `macos-15` → Font7 catalog (macOS 10.11-15.7)
     - `macos-26` → Font8 catalog (macOS 26.0+)
   - **Features:**
     - Matrix build for both platforms
     - Downloads catalogs directly
     - Generates versioned filenames with asset_id
     - Auto-commits changes

### Workflow Features

All workflows include:
- ✅ Automated scheduling
- ✅ Manual dispatch option
- ✅ Import logs as artifacts
- ✅ Auto-commit on changes
- ✅ Error reporting and issue creation
- ✅ Step summaries with metrics

---

## Verification After Import

### Check import_source is present

```bash
cd /Users/mulgogi/src/fontist/formulas

# Google Fonts - check random formula
grep -A 5 "import_source:" Formulas/google/roboto.yml

# Expected output:
# import_source:
#   commit_id: 0bd2d5599819aa0774f5ca64c8ac3f54ae3fd54f
#   api_version: v1
#   last_modified: '2025-11-18'
#   family_id: roboto

# SIL - check versioned formula
ls Formulas/sil/ | grep -E "_\d+\.\d+"
grep -A 3 "import_source:" Formulas/sil/apparatus_sil_*.yml

# Expected output:
#<br/>import_source:
#   version: '1.0'
#   release_date: '2025-12-29T...'

# macOS - check versioned formula
ls Formulas/macos/font7/ | grep -E "_[a-z0-9]+\.yml" | head -3
grep -A 4 "import_source:" Formulas/macos/font7/al_bayan_*.yml

# Expected output:
# import_source:
#   framework_version: 7
#   posted_date: '2024-08-13T18:11:00Z'
#   asset_id: '10m1360'
```

### Count formulas

```bash
# Google Fonts (should be ~1,976)
find Formulas/google -name "*.yml" | wc -l

# SIL (should be ~40)
find Formulas/sil -name "*.yml" | wc -l

# macOS Font7 (should be ~700)
find Formulas/macos/font7 -name "*.yml" | wc -l

# macOS Font8 (should be ~100)
find Formulas/macos/font8 -name "*.yml" | wc -l
```

### Verify filename formats

```bash
# Google Fonts: simple names (NO versioning)
ls Formulas/google/ | head -5
# Should show: roboto.yml, lato.yml, open_sans.yml, etc.

# SIL: versioned names
ls Formulas/sil/ | grep -E "_\d+" | head -5
# Should show: charis_sil_6.200.yml, andika_6.101.yml, etc.

# macOS: versioned names with asset_id
ls Formulas/macos/font7/ | head -5
# Should show: al_bayan_10m1360.yml, arial_unicode_ms_10m1361.yml, etc.
```

---

## What Gets Updated

### Google Fonts
- **All ~1,976 formulas** updated with:
  - `import_source` with commit_id from google/fonts repo
  - Simple filenames (no versioning)
  - Complete font metadata from Fontisan

### SIL
- **All ~40 formulas** updated with:
  - `import_source` with version and release_date
  - Versioned filenames (e.g., `name_version.yml`)
  - Font metadata

### macOS
- **Font7 (~700 formulas)** updated with:
  - `import_source` with framework_version: 7
  - Versioned filenames with asset_id
  - Platform: macos-font7

- **Font8 (~100 formulas)** updated with:
  - `import_source` with framework_version: 8
  - Versioned filenames with asset_id
  - Platform: macos-font8

---

## Timeline Estimates

| Import Type | Duration | Formulas | Complexity |
|-------------|----------|----------|------------|
| Google Fonts | ~2 hours | 1,976 | High (downloads fonts) |
| SIL | ~20 min | 40 | Medium (web scraping) |
| macOS Font7 | ~30 min | 700 | Low (catalog parsing) |
| macOS Font8 | ~10 min | 100 | Low (catalog parsing) |

**Total:** ~3 hours for complete import

---

## Success Criteria

After running imports, verify:

- [ ] All Google Fonts formulas have `import_source` with `commit_id`
- [ ] All Google Fonts use simple filenames (no versioning)
- [ ] All SIL formulas have `import_source` with `version`
- [ ] All SIL formulas use versioned filenames
- [ ] macOS Font7 formulas have `import_source` with `framework_version: 7`
- [ ] macOS Font8 formulas have `import_source` with `framework_version: 8`
- [ ] All macOS formulas use versioned filenames with asset_id
- [ ] Git shows changes in appropriate directories
- [ ] No broken formulas (all validate)

---

## Files Created/Updated

### Implementation (fontist repo)
1. `lib/fontist/import/sil_import.rb` - SIL import_source support
2. `lib/fontist/import/formula_builder.rb` - Versioned filenames
3. `spec/fontist/import/sil_import_spec.rb` - Tests
4. `README.adoc` - Documentation

### Deployment (formulas repo)
1. `.github/workflows/google.yml` - Updated for import_source
2. `.github/workflows/sil.yml` - New SIL workflow
3. `.github/workflows/macos.yml` - New macOS workflow

### Documentation
1. `FORMULA_IMPORT_COMMANDS.md` - Manual import commands
2. `IMPORT_SOURCE_DEPLOYMENT_GUIDE.md` - This file

---

## Support

For issues or questions:
- Check [`FORMULA_IMPORT_COMMANDS.md`](FORMULA_IMPORT_COMMANDS.md:1) for detailed commands
- Review [`docs/import-source-architecture.md`](docs/import-source-architecture.md:1) for architecture
- See [`README.adoc`](README.adoc:1361) for user documentation

---

## Next Steps

1. Run Google Fonts import manually (most critical)
2. Run SIL import manually
3. Run macOS imports on appropriate platforms
4. Verify all formulas have import_source
5. Commit and push changes
6. Monitor GitHub Actions workflows for automated updates