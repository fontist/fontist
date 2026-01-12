# Install Location Architecture - Final Summary

## Overview

Fontist's install location feature has been implemented with a clear separation between:

1. **Install Locations** - WHERE fonts are installed (user chooses ONE named location)
2. **Font Search** - WHERE Fontist looks for fonts (ALWAYS searches ALL locations)

## Architecture Principles

### Install Locations (Named Locations Only)

**Three Named Location Types:**

1. **`fontist`** (default)
   - Installs to: `~/.fontist/fonts/{formula-key}/`
   - Customizable base via: `FONTIST_PATH` environment variable
   - Example: `FONTIST_PATH=/opt/fonts` → installs to `/opt/fonts/fonts/roboto/`

2. **`user`**
   - Installs to platform-specific user directory
   - macOS: `~/Library/Fonts`
   - Linux: `~/.local/share/fonts`
   - Windows: `%LOCALAPPDATA%\Microsoft\Windows\Fonts`

3. **`system`**
   - Installs to platform-specific system directory (requires admin)
   - macOS: `/Library/Fonts`
   - Linux: `/usr/local/share/fonts`
   - Windows: `%windir%\Fonts`

**Important:** Custom paths like `/my/custom/path` are NOT supported as install locations.

### Font Search (Always All Locations)

Fontist ALWAYS searches for fonts in ALL locations:
- System font directories
- User font directories
- Fontist library directory

This is automatic regardless of install location choice.

## Usage

### CLI
```sh
# Default (fontist location)
fontist install "Roboto"

# User location
fontist install "Roboto" --location=user

# System location (may need sudo)
fontist install "Roboto" --location=system
sudo fontist install "Roboto" --location=system

# Customize fontist base path
export FONTIST_PATH=/opt/fontist
fontist install "Roboto"  # Installs to /opt/fontist/fonts/roboto/
```

### Configuration
```sh
# Set default install location
fontist config set install_location user
export FONTIST_INSTALL_LOCATION=user

# Customize fontist library path
export FONTIST_PATH=/custom/fontist
```

### Ruby API
```ruby
Fontist::Font.install("Roboto", location: :user)
Fontist::Font.install("Roboto", location: "system")
```

## Implementation

### Core Files
- [`lib/fontist/install_location.rb`](lib/fontist/install_location.rb) - Installation destination logic
- [`lib/fontist/system_font.rb`](lib/fontist/system_font.rb) - Font search logic
- [`lib/fontist/config.rb`](lib/fontist/config.rb) - Configuration management

### Key Implementation Points

1. **Location Validation** ([`InstallLocation#parse_location_type`](lib/fontist/install_location.rb:105))
   - Only accepts: `fontist`, `user`, `system`
   - Invalid values fall back to `fontist` with clear error message
   - Error explains custom paths not supported and suggests `FONTIST_PATH`

2. **Formula-Keyed Paths** ([`InstallLocation#fontist_path`](lib/fontist/install_location.rb:128))
   - Structure: `{FONTIST_PATH}/fonts/{formula-key}/`
   - Prevents filename conflicts between formulas
   - Maintains MECE principle

3. **Universal Search** ([`SystemFont.font_paths`](lib/fontist/system_font.rb:6))
   - Always searches: system + user + fontist locations
   - No configuration needed
   - Automatic discovery of OS-installed fonts

## Error Handling

### Invalid Location Type
```
$ fontist install "Roboto" --location=invalid

Invalid install location: 'invalid'

Valid options: fontist, user, system
(Custom paths not supported. Use FONTIST_PATH to customize fontist location)

Using default location: fontist
```

### System Installation Without Permissions
```
$ fontist install "Roboto" --location=system

⚠️  WARNING: Installing to system font directory

This requires root/administrator permissions and may affect your system.

Installation will fail if you don't have sufficient permissions.

Recommended alternatives:
- Use default (fontist): Safe, isolated, no permissions needed
- Use --user: Install to your user font directory

Continue with system installation? (Ctrl+C to cancel)
```

## Documentation

### For Users
- [`docs/readme-install-locations-section.adoc`](docs/readme-install-locations-section.adoc) - Ready to copy into README.adoc
- Clear examples of each named location
- Explanation of font discovery

### For Developers
- [`docs/install-locations-architecture.md`](docs/install-locations-architecture.md) - Complete architecture guide
- Design principles and rationale
- Platform-specific implementation details
- Error handling specifications

## Test Status

### Completed (893 examples, 4 failures)
- ✅ 147 unit tests for `InstallLocation` (100% pass rate)
- ✅ 36 integration tests fixed for formula-keyed paths
- ✅ Recursive font search working correctly

### Remaining Failures (Unrelated)
- 1 Adobe font rename bug (pre-existing)
- 3 macOS version parsing tests (unrelated to install location)

## Key Differences from Initial Plan

### What Changed
1. **Removed custom path support** - Only named locations (`fontist`, `user`, `system`)
2. **Clarified fontist customization** - Via `FONTIST_PATH`, not `--location` path
3. **Separated concepts** - Install location vs. search locations are distinct

### Why These Changes
1. **Simplicity** - Three named locations cover all real use cases
2. **Predictability** - Users know exactly where fonts will be
3. **Platform Integration** - Named locations follow OS conventions
4. **Automatic Discovery** - Universal search finds all fonts

## Migration Notes

### For Existing Users
No breaking changes. Default behavior unchanged:
- Fonts still install to `~/.fontist/fonts/{formula-key}/` by default
- All fonts still found automatically regardless of location
- `FONTIST_PATH` still works to customize base directory

### New Capabilities
Users can now:
- Install to user directory: `--location=user`
- Install to system directory: `--location=system`
- Set default via config: `fontist config set install_location user`

## Future Considerations

### Not Planned
- ❌ Custom paths as install locations (use `FONTIST_PATH` instead)
- ❌ Configurable search paths (automatic search works)
- ❌ Per-formula location settings (adds complexity)

### Potential Enhancements
- ✅ Better permission detection before system install
- ✅ Warning for readonly filesystems
- ✅ Validation in config setter
- ✅ Platform-specific error messages

## Summary

The install location feature is complete and working correctly:

1. **Clear Architecture** - Install destinations vs. search locations
2. **Named Locations Only** - `fontist`, `user`, `system`
3. **Universal Search** - Always finds fonts everywhere
4. **Good Defaults** - Safe, isolated `fontist` location
5. **Platform Integration** - Proper OS font directory support
6. **Clear Errors** - Helpful messages for invalid input

The implementation follows object-oriented principles, maintains MECE organization through formula-keyed paths, and provides flexibility through named locations while avoiding the complexity of arbitrary custom paths.