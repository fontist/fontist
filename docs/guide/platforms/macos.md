---
title: macOS Platform Guide
---

# macOS Platform Guide

Fontist provides special support for macOS supplementary fonts, a framework introduced in macOS 10.12 (Sierra) for dynamically downloading licensed fonts on demand.

## Supplementary Fonts Overview

macOS provides a "supplementary fonts" framework (shared with iOS) for dynamically downloading and installing a wide range of licensed fonts. These fonts are typically commercial fonts that come free with macOS.

### Typical Use Cases

- CI jobs on macOS environments using specially-licensed fonts
- Automating installation of macOS add-on fonts
- Accessing platform-specific fonts not available elsewhere

::: warning Non-macOS Installation
Fontist does not allow installing macOS-specific fonts on non-macOS platforms due to font license restrictions.
:::

---

## Framework Versioning

The macOS supplementary font catalog is bound to specific framework versions. Different versions contain different sets of fonts, and often different versions of the same fonts.

### Version Compatibility

| macOS Version | Framework Version | Platform Tag |
|---------------|-------------------|--------------|
| macOS 10.12 (Sierra) | Font 3 | `macos-font3` |
| macOS 10.13 (High Sierra) | Font 4 | `macos-font4` |
| macOS 10.14 (Mojave) | Font 5 | `macos-font5` |
| macOS 10.15 (Catalina) | Font 6 | `macos-font6` |
| macOS 11 (Big Sur) | Font 6 | `macos-font6` |
| macOS 12 (Monterey) | Font 7 | `macos-font7` |
| macOS 13 (Ventura) | Font 7 | `macos-font7` |
| macOS 14 (Sonoma) | Font 7 | `macos-font7` |
| macOS 15 (Sequoia) | Font 7 | `macos-font7` |
| macOS 26+ (Tahoe) | Font 8 | `macos-font8` |

### How Versioning Works

A macOS system can only download fonts from the catalog version corresponding to its framework version. Fontist respects this limitation when installing these fonts.

When you install a macOS add-on font, Fontist automatically detects your macOS version and installs the appropriate font version:

```sh
fontist install "Al Bayan"
# On macOS 15: installs Font7 version formula
# On macOS 26: installs Font8 version formula
```

This ensures you always get the font version compatible with your system.

---

## Platform Tags

In Fontist Formulas, each supplementary font is backed by a formula specifying the font framework version using platform tags.

### Tag Format

Platform tags follow the pattern: `macos-fontX` where `X` is the catalog version number.

### Version Compatibility Checking

Fontist controls version compatibility through platform tags:

```sh
# On macOS 14.2 (Sonoma), trying to install a Font8-only formula:
fontist install "Font8OnlyFont"

# Error output:
# Font 'Font8OnlyFont' is only available for: macos-font8.
# Your current platform is: macos. Your macOS version is: 14.2.1.
# This font requires macOS 26.0 or later.
# This font cannot be installed on your system.
```

---

## Manual Installation Methods

On macOS, supplementary fonts can also be installed manually:

### Method 1: Application Trigger

User applications can trigger installation when needed, as described in Apple's ["DownloadFont" sample code](https://developer.apple.com/library/archive/samplecode/DownloadFont/Introduction/Intro.html).

### Method 2: Font Book

1. Open **Font Book.app**
2. Search for the desired font
3. Click "Download"

Both methods trigger a download from Apple's Mobile Asset Server.

---

## Asset Catalog Locations

The asset catalog XML files are located at:

| Version | System Path |
|---------|-------------|
| Font 3 | `/System/Library/Assets/com_apple_MobileAsset_Font3/com_apple_MobileAsset_Font3.xml` |
| Font 4 | `/System/Library/Assets/com_apple_MobileAsset_Font4/com_apple_MobileAsset_Font4.xml` |
| Font 5 | `/System/Library/AssetsV2/com_apple_MobileAsset_Font5/com_apple_MobileAsset_Font5.xml` |
| Font 6 | `/System/Library/AssetsV2/com_apple_MobileAsset_Font6/com_apple_MobileAsset_Font6.xml` |
| Font 7 | `/System/Library/AssetsV2/com_apple_MobileAsset_Font7/com_apple_MobileAsset_Font7.xml` |
| Font 8 | `/System/Library/AssetsV2/com_apple_MobileAsset_Font8/com_apple_MobileAsset_Font8.xml` |

::: note Schema Differences
The Assets and AssetsV2 frameworks use slightly different Plist schemas.
:::

---

## Font Sources by macOS Version

For the complete list of available fonts on each macOS version, see Apple's support pages:

| macOS Version | Apple Support Link |
|---------------|-------------------|
| macOS 15 (Sequoia) | [Fonts included with macOS Sequoia](https://support.apple.com/en-us/120414) |
| macOS 14 (Sonoma) | [Fonts included with macOS Sonoma](https://support.apple.com/en-us/108939) |

::: note Older macOS Versions
Apple may remove or relocate support articles for older macOS versions. For Ventura, Monterey, Big Sur, and earlier versions, use Font Book on your Mac to view available fonts, or search Apple Support for the specific version.
:::

---

## Example: Installing Canela

Canela is a commercial font that comes free with macOS:

```sh
fontist install Canela
```

---

## See Also

- [How Fontist Works](/guide/how-it-works) - Architecture and indexes
- [Formulas Guide](/guide/formulas) - How formulas work
- [Fontist Blog: Installing macOS-specific add-on fonts](https://www.fontist.org/blog/2022-02-11-macos-fonts)
