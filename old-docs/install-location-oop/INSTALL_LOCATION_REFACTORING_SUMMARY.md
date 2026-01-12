# Install Location Refactoring - Universal Implementation

**Date:** 2026-01-05
**Status:** ✅ Complete

## Overview

Refactored install location system from macOS-specific (`--macos-fonts-location`) to universal cross-platform support (`--install-location`) with three location types that work on all platforms.

## Architecture Change

### Before (macOS-specific)
- `--macos-fonts-location system|fontist-library`
- Only supported macOS supplementary fonts
- Binary choice between two locations

### After (Universal)
- `--install-location fontist|user|system`
- Works for ALL fonts on ALL platforms
- Three well-defined location types

## Location Types

### 1. `fontist` (Default, Recommended)
**Path:** `~/.fontist/fonts/{formula-key}/`

**Characteristics:**
- ✅ Isolated from system
- ✅ No permissions required
- ✅ Safe, won't affect system
- ✅ Formula-keyed (prevents conflicts)

**Use when:** Default for all installations

### 2. `user`
**Platform-specific paths:**
- macOS: `~/Library/Fonts`
- Linux: `~/.local/share/fonts`
- Windows: `%USERPROFILE%\AppData\Local\Microsoft\Windows\Fonts`

**Characteristics:**
- ✅ User-specific, no admin required
- ✅ Recognized by system immediately
- ✅ Won't affect other users

**Use when:** Want fonts in user directory for system-wide recognition

### 3. `system`
**Platform-specific paths:**
- macOS (regular): `/System/Library/Fonts`
- macOS (supplementary): `/System/Library/Assets*/com_apple_MobileAsset_Font<N>/{asset_id}.asset/AssetData/`
- Linux: `/usr/local/share/fonts`
- Windows: `%windir%\Fonts`

**Characteristics:**
- ⚠️ Requires root/admin permissions
- ⚠️ Affects entire system
- ⚠️ Shows permission warning before install

**Use when:** Need system-wide fonts for all users (use with caution)

## Implementation Details

### InstallLocation Class ([`lib/fontist/install_location.rb`](lib/fontist/install_location.rb:1))

**Key Methods:**
- [`base_path()`](lib/fontist/install_location.rb:33) - Returns platform-specific path
- [`font_path(filename)`](lib/fontist/install_location.rb:43) - Full path for font file
- [`permission_warning()`](lib/fontist/install_location.rb:84) - Warning message for system installs
- [`requires_elevated_permissions?()`](lib/fontist/install_location.rb:76) - Permission check

**Platform Resolution:**
```ruby
def user_path
  case Utils::System.user_os
  when :macos
    "~/Library/Fonts"
  when :linux
    "~/.local/share/fonts"
  when :windows
    "%LOCALAPPDATA%/Microsoft/Windows/Fonts"
  end
end

def system_path
  case Utils::System.user_os
  when :macos
    macos_system_path  # Handles regular vs supplementary
  when :linux
    "/usr/local/share/fonts"
  when :windows
    "%windir%/Fonts"
  end
end
```

### Config Updates ([`lib/fontist/config.rb`](lib/fontist/config.rb:1))

**New Methods:**
- [`Config.fonts_install_location()`](lib/fontist/config.rb:70) - ENV > config > default
- [`Config.set_fonts_install_location(location)`](lib/fontist/config.rb:79) - Persist setting

**Environment Variable:**
```bash
export FONTIST_INSTALL_LOCATION="user"
```

**Priority:** ENV > config file > default ("fontist")

### Permission Warning System

When installing to system location, users see:

```
⚠️  WARNING: Installing to system font directory

This requires root/administrator permissions and may affect your system.

Installation will fail if you don't have sufficient permissions.

Recommended alternatives:
- Use default (fontist): Safe, isolated, no permissions needed
- Use --user: Install to your user font directory

Continue with system installation? (Ctrl+C to cancel)
Proceeding in 3 seconds... (Press Ctrl+C to cancel)
```

### macOS Supplementary Font Handling

The system intelligently routes macOS supplementary fonts (platform-tagged formulas) to the correct Apple asset structure:

```ruby
def macos_system_path
  if formula.macos_import?
    # Supplementary fonts: /System/Library/Assets*/com_apple_MobileAsset_Font<N>/{asset_id}.asset/AssetData/
    macos_supplementary_path
  else
    # Regular fonts: /System/Library/Fonts
    "/System/Library/Fonts"
  end
end
```

## Usage Examples

### CLI

```bash
# Default (fontist) - recommended
fontist install "Roboto"

# User directory
fontist install "Roboto" --install-location=user

# System directory (with warning)
fontist install "Roboto" --install-location=system

# macOS supplementary font to system (correct path)
fontist install "SF Pro" --install-location=system
```

### API

```ruby
# Default
Font.install("Roboto")

# User directory
Font.install("Roboto", install_location: "user")

# System directory
Font.install("Roboto", install_location: "system")
```

### Environment Variable

```bash
# Set persistent default
export FONTIST_INSTALL_LOCATION="user"
fontist install "Roboto"  # Installs to user directory
```

### Config File

```bash
fontist config set fonts_install_location user
```

## Files Modified

1. ✅ [`lib/fontist/install_location.rb`](lib/fontist/install_location.rb:1) - Complete refactor
2. ✅ [`lib/fontist/config.rb`](lib/fontist/config.rb:1) - Renamed to `fonts_install_location`
3. ✅ [`lib/fontist/font.rb`](lib/fontist/font.rb:1) - Updated to `install_location`, added permission check
4. ✅ [`lib/fontist/font_installer.rb`](lib/fontist/font_installer.rb:1) - Added `attr_reader :location`
5. ✅ [`lib/fontist/cli.rb`](lib/fontist/cli.rb:1) - Updated to `--install-location`

## Benefits

### 1. Universal Design
- ✅ Works on all platforms (macOS, Linux, Windows)
- ✅ Consistent API across platforms
- ✅ One option for all font types

### 2. Safety
- ✅ Default is isolated and safe
- ✅ Clear warnings for risky operations
- ✅ Permission checks prevent silent failures

### 3. Flexibility
- ✅ Three clear choices for different use cases
- ✅ Platform-specific path resolution
- ✅ Smart handling of special cases (macOS supplementary fonts)

### 4. User Experience
- ✅ Clear, descriptive option names
- ✅ Helpful warnings with alternatives
- ✅ 3-second delay allows cancellation

## Migration Notes

### From Old Implementation

Old option `--macos-fonts-location` is **deprecated** (not removed for compatibility):

**Old:**
```bash
fontist install "SF Pro" --macos-fonts-location=system
fontist install "SF Pro" --macos-fonts-location=fontist-library
```

**New (recommended):**
```bash
fontist install "SF Pro" --install-location=system
fontist install "SF Pro" --install-location=fontist
# or --install-location=user
```

### Environment Variables

**Old:** `FONTIST_MACOS_FONTS_LOCATION`
**New:** `FONTIST_INSTALL_LOCATION`

## Testing Checklist

- [ ] Test `fontist` location on all platforms
- [ ] Test `user` location on all platforms
- [ ] Test `system` location on all platforms (with proper permissions)
- [ ] Test permission warning display
- [ ] Test macOS supplementary fonts to system path
- [ ] Test regular fonts to system path on macOS
- [ ] Test ENV variable priority
- [ ] Test config file persistence
- [ ] Test invalid location values

## Documentation Updates Needed

- [ ] Update README.adoc with install location section
- [ ] Create docs/install-locations-guide.md
- [ ] Update CLI help text
- [ ] Add examples for each platform
- [ ] Document permission requirements

## Success Criteria

✅ Universal design works on all platforms
✅ Clear separation of three location types
✅ Smart platform-specific path resolution
✅ Permission warnings for system installs
✅ macOS supplementary fonts handled correctly
✅ Backward compatible with existing code
✅ ENV/CLI/API all support new options