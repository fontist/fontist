# Formula Import Commands

**Location:** Run these commands from `/Users/mulgogi/src/fontist/formulas`

**Prerequisites:**
```bash
# Set Google Fonts API key
source ~/.google-fonts-api-key

# Ensure fontist gem is available
cd /Users/mulgogi/src/fontist/fontist
bundle install
```

---

## Google Fonts Import

### Import All Google Fonts

```bash
cd /Users/mulgogi/src/fontist/formulas

source ~/.google-fonts-api-key

bundle exec fontist import google \
  --source-path /Users/mulgogi/src/external/google-fonts \
  --output-path ./Formulas/google \
  --verbose
```

### Import Single Font Family

```bash
bundle exec fontist import google \
  --font-family "Roboto" \
  --source-path /Users/mulgogi/src/external/google-fonts \
  --output-path ./Formulas/google \
  --verbose
```

### Backup Before Import

```bash
# Create timestamped backup
cp -r Formulas/google "Formulas/google.backup.$(date +%Y%m%d_%H%M%S)"
```

---

## SIL International Fonts Import

### Import All SIL Fonts

```bash
cd /Users/mulgogi/src/fontist/formulas

bundle exec fontist import sil
# Formulas saved to: ~/.fontist/versions/v4/formulas/Formulas/sil/

# Copy to formulas repo
cp ~/.fontist/versions/v4/formulas/Formulas/sil/*.yml ./Formulas/sil/
```

### Backup Before Import

```bash
# Create timestamped backup
cp -r Formulas/sil "Formulas/sil.backup.$(date +%Y%m%d_%H%M%S)"
```

---

## macOS Supplementary Fonts Import

### Prerequisites

Download the latest macOS font catalogs:

```bash
# Font7 catalog (macOS 10.11-15.7)
curl -o com_apple_MobileAsset_Font7.xml \
  https://mesu.apple.com/assets/macos/com_apple_MobileAsset_Font7/com_apple_MobileAsset_Font7.xml

# Font8 catalog (macOS 26.0+)
curl -o com_apple_MobileAsset_Font8.xml \
  https://mesu.apple.com/assets/macos/com_apple_MobileAsset_Font8/com_apple_MobileAsset_Font8.xml
```

### Import Font7 Catalog

```bash
cd /Users/mulgogi/src/fontist/formulas

bundle exec fontist import macos \
  --plist com_apple_MobileAsset_Font7.xml \
  --formulas-dir ./Formulas/macos/font7
```

### Import Font8 Catalog

```bash
bundle exec fontist import macos \
  --plist com_apple_MobileAsset_Font8.xml \
  --formulas-dir ./Formulas/macos/font8
```

### Backup Before Import

```bash
# Backup both catalog versions
cp -r Formulas/macos "Formulas/macos.backup.$(date +%Y%m%d_%H%M%S)"
```

---

## Verification Commands

### Count Formulas with import_source

```bash
# Google Fonts
grep -rl "import_source:" Formulas/google/ | wc -l

# SIL
grep -rl "import_source:" Formulas/sil/ | wc -l

# macOS Font7
grep -rl "import_source:" Formulas/macos/font7/ | wc -l

# macOS Font8
grep -rl "import_source:" Formulas/macos/font8/ | wc -l
```

### Verify Filename Formats

```bash
# Google Fonts: simple filenames (no versioning)
ls Formulas/google/ | head -10

# SIL: versioned filenames
ls Formulas/sil/ | grep -E "_\d+\.\d+" | head -5

# macOS: versioned filenames with asset_id
ls Formulas/macos/font7/ | grep -E "_[a-z0-9]+\.yml" | head -5
ls Formulas/macos/font8/ | grep -E "_[a-z0-9]+\.yml" | head -5
```

### Check Specific Formula

```bash
# View import_source section
grep -A 10 "import_source:" Formulas/google/roboto.yml
grep -A 5 "import_source:" Formulas/sil/charis_sil_*.yml
grep -A 5 "import_source:" Formulas/macos/font7/al_bayan_*.yml
```

---

## Git Workflow

### Commit Google Fonts Updates

```bash
cd /Users/mulgogi/src/fontist/formulas

git add Formulas/google
git status
git commit -m "chore(formulas): update Google Fonts with import_source tracking"
git push
```

### Commit SIL Updates

```bash
git add Formulas/sil
git status
git commit -m "feat(formulas): add SIL fonts with import_source tracking"
git push
```

### Commit macOS Updates

```bash
git add Formulas/macos
git status
git commit -m "feat(formulas): update macOS supplementary fonts with import_source"
git push
```

---

## Troubleshooting

### Google Fonts API Key Issues

```bash
# Verify API key is set
echo ${GOOGLE_FONTS_API_KEY:+API_KEY_SET}

# Re-source if needed
source ~/.google-fonts-api-key
```

### google/fonts Repository Out of Date

```bash
cd /Users/mulgogi/src/external/google-fonts
git pull
git rev-parse HEAD  # Get current commit
```

### SIL Import Errors

```bash
# SIL import scrapes live website, may fail if URLs change
# Check error messages and update SilImport if needed
bundle exec fontist import sil 2>&1 | tee sil-import.log
```

### macOS Catalog Download Issues

```bash
# Verify catalog URL is accessible
curl -I https://mesu.apple.com/assets/macos/com_apple_MobileAsset_Font7/com_apple_MobileAsset_Font7.xml
```

---

## Expected Results

### Google Fonts
- **Filenames:** Simple (e.g., `roboto.yml`, `lato.yml`)
- **import_source:** commit_id from google/fonts repository
- **Count:** ~1,976 formulas (all Google Fonts)

### SIL
- **Filenames:** Versioned (e.g., `charis_sil_6.200.yml`)
- **import_source:** version and release_date
- **Count:** ~40 formulas (all SIL fonts)

### macOS
- **Filenames:** Versioned with asset_id (e.g., `al_bayan_10m1360.yml`)
- **import_source:** framework_version, posted_date, asset_id
- **Count:**
  - Font7: ~700 formulas (macOS 10.11-15.7)
  - Font8: ~100 formulas (macOS 26.0+)