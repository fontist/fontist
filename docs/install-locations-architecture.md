# Install Locations Architecture

## Overview

Fontist manages fonts through two separate but related concepts:

1. **Install Locations** - WHERE fonts are installed (user's choice, one location)
2. **Font Search Paths** - WHERE Fontist looks for fonts (always all locations)

These concepts are intentionally separate to provide flexibility while maintaining simplicity.

## Install Locations (Installation Destination)

When installing a font via `fontist install`, the user chooses ONE destination from three **named locations**:

### Named Location Types

#### 1. `fontist` (Default)
- **Path**: `~/.fontist/fonts/{formula-key}/` (customizable via `FONTIST_PATH`)
- **Structure**: Formula-keyed subdirectories prevent naming conflicts
- **Permissions**: No admin/sudo required
- **Isolation**: Safe, won't interfere with system fonts
- **Platform**: Works identically on all platforms
- **Customization**: The base Fontist path can be set via `FONTIST_PATH` environment variable
- **Use Case**: Default for all users, CI/CD, development

**Example**:
```
# Default location
~/.fontist/fonts/
├── roboto/
│   ├── Roboto-Regular.ttf
│   ├── Roboto-Bold.ttf
│   └── ...
├── lato/
│   ├── Lato-Regular.ttf
│   └── ...
└── {formula-key}/
    └── {font-files}

# Customized via FONTIST_PATH=/opt/fontist
/opt/fontist/fonts/
├── roboto/
└── ...

# User location (with fontist subdirectory)
~/Library/Fonts/fontist/  # macOS
├── Roboto-Regular.ttf
├── Roboto-Bold.ttf
└── ...

# Customized user location (without subdirectory)
# Via FONTIST_USER_FONTS_PATH=~/Library/Fonts
~/Library/Fonts/
├── Roboto-Regular.ttf
└── ...
```

#### 2. `user`
- **Path**: Platform-specific user font directory with `fontist` subdirectory
- **Permissions**: No admin/sudo required
- **Visibility**: Available to current user only
- **Platform-specific paths**:
  - macOS: `~/Library/Fonts/fontist`
  - Linux: `~/.local/share/fonts/fontist`
  - Windows: `%LOCALAPPDATA%\Microsoft\Windows\Fonts\fontist`
- **Customization**: Can override via `FONTIST_USER_FONTS_PATH` environment variable or `user_fonts_path` config option
- **Use Case**: Integration with OS font management, user-specific installations

#### 3. `system`
- **Path**: Platform-specific system font directory with `fontist` subdirectory
- **Permissions**: **Requires admin/sudo**
- **Visibility**: Available to all users
- **Platform-specific paths**:
  - macOS: `/Library/Fonts/fontist` (or special paths for supplementary fonts)
  - Linux: `/usr/local/share/fonts/fontist`
  - Windows: `%windir%\Fonts\fontist`
- **Customization**: Can override via `FONTIST_SYSTEM_FONTS_PATH` environment variable or `system_fonts_path` config option
- **Use Case**: System-wide deployment, shared environments

### Important: Only Named Locations

**Three Named Locations Only:**
1. `fontist` - Fontist library (location customizable via `FONTIST_PATH`)
2. `user` - Platform user directory
3. `system` - Platform system directory

**Why Only Named Locations:**
1. **Simplicity**: Three well-defined choices cover all use cases
2. **Predictability**: Font locations follow platform conventions
3. **Platform Integration**: Named locations integrate with OS font systems
4. **Search Consistency**: All installations are automatically discoverable

**Note on fontist Location:**
The `fontist` named location installs to the Fontist library directory. While the base Fontist directory can be customized via the `FONTIST_PATH` environment variable, the install location itself is still the named location `fontist`, not a custom path.

**Invalid Usage**:
```sh
fontist install "Roboto" --location=/my/custom/path  # ❌ NOT SUPPORTED
```

**Valid Usage**:
```sh
# Named location (default)
fontist install "Roboto" --location=fontist  # ✅ or omit --location

# Named location (user)
fontist install "Roboto" --location=user     # ✅

# Named location (system)
fontist install "Roboto" --location=system   # ✅

# Customize fontist library base path via ENV
export FONTIST_PATH=/opt/fontist
fontist install "Roboto"  # ✅ Installs to /opt/fontist/fonts/roboto/
```

## Font Search Paths (Where Fontist Looks)

Fontist **always** searches for fonts in ALL of these locations, regardless of install location:

### Search Order
1. **System font paths** (from `lib/fontist/system.yml`)
   - Platform-specific system directories
   - Varies by OS (macOS, Linux, Windows)

2. **Fontist library paths**
   - `~/.fontist/fonts/**/*.{ttf,otf,ttc,otc}`
   - Recursively searches all subdirectories

3. **User font paths** (included in system paths config)
   - Platform-specific user directories
   - Already included in system.yml

### Implementation

Search is implemented in [`SystemFont.font_paths`](../lib/fontist/system_font.rb):

```ruby
def self.font_paths
  system_font_paths + fontist_font_paths
end
```

**Key Point**: Search is comprehensive and automatic. Users never need to configure search paths.

## Configuration Options

### CLI Option
```sh
fontist install "Roboto" --location=<type>
```

Where `<type>` is one of: `fontist`, `user`, `system` (named locations only)

### Environment Variable for Install Location
```sh
export FONTIST_INSTALL_LOCATION=user
fontist install "Roboto"
```

### Environment Variable for Fontist Library Path
```sh
export FONTIST_PATH=/custom/fontist/directory
fontist install "Roboto"  # Installs to /custom/fontist/directory/fonts/roboto/
```

### Config File
```sh
fontist config set install_location user
fontist install "Roboto"
```

### Ruby API
```ruby
Fontist::Font.install("Roboto", location: :user)
# or
Fontist::Font.install("Roboto", location: "system")
```

## Architecture Diagram

```
┌─────────────────────────────────────────────────┐
│         INSTALLATION (User Choice)               │
│                                                  │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐     │
│  │ fontist  │  │   user   │  │  system  │     │
│  │(default) │  │          │  │ (admin)  │     │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘     │
│       │             │             │            │
│       ▼             ▼             ▼            │
│  ~/.fontist/   ~/Library/   /Library/         │
│    fonts/        Fonts       Fonts             │
└─────────────────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────┐
│         SEARCH (Always All Locations)            │
│                                                  │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐     │
│  │  System  │  │   User   │  │ Fontist  │     │
│  │  Paths   │  │  Paths   │  │  Library │     │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘     │
│       │             │             │            │
│       └─────────────┴─────────────┘            │
│                     │                           │
│                     ▼                           │
│           All fonts found & returned            │
└─────────────────────────────────────────────────┘
```

## Design Principles

### 1. Separation of Concerns
- **Installation** = Where new fonts go (user chooses)
- **Search** = Where fonts are found (automatic, comprehensive)

### 2. Default Safety
- Default (`fontist`) is safest, no permissions needed
- Isolated formula directories prevent conflicts
- Never touches system/user font directories by default

### 3. Named Locations Only
- No arbitrary paths to avoid confusion
- Platform integration through well-defined locations
- Consistent behavior across platforms

### 4. Universal Search
- Always search everywhere regardless of install location
- Find fonts whether installed by Fontist or OS
- No user configuration needed for search

## Use Cases

### Development (Default)
```sh
fontist install "Roboto"
# Installs to ~/.fontist/fonts/roboto/
# Finds all fonts: system + user + fontist
```

### User Integration
```sh
fontist install "Roboto" --location=user
# Installs to ~/Library/Fonts (macOS)
# Fonts appear in Font Book/system font picker
# Still searches everywhere
```

### System Deployment
```sh
sudo fontist install "Roboto" --location=system
# Installs to /Library/Fonts (macOS)
# Available to all users
# Still searches everywhere
```

### CI/CD
```sh
# Default fontist location is perfect for CI
fontist install "Roboto"
# Isolated, no permissions, predictable paths
```

## Error Handling

### Invalid Location Type
```sh
$ fontist install "Roboto" --location=invalid
ERROR: Invalid install location 'invalid'
Valid options: fontist, user, system
Using default: fontist
```

### Invalid Custom Path Attempt
```sh
$ fontist install "Roboto" --location=/custom/path
ERROR: Custom paths not supported for installation
Valid options: fontist (customizable via FONTIST_PATH), user, system
Using default: fontist
```

### Permission Denied
```sh
$ fontist install "Roboto" --location=system
⚠️  WARNING: Installing to system font directory

This requires root/administrator permissions and may affect your system.

Installation will fail if you don't have sufficient permissions.

Recommended alternatives:
- Use default (fontist): Safe, isolated, no permissions needed
- Use --location=user: Install to your user font directory

Continue with system installation? (Ctrl+C to cancel)

ERROR: Permission denied writing to /Library/Fonts
Try: sudo fontist install "Roboto" --location=system
```

## Platform-Specific Behavior

### macOS
- **User**: `~/Library/Fonts` - appears in Font Book
- **System**: `/Library/Fonts` - available system-wide
- **Supplementary**: Special handling for macOS-specific font catalogs

### Linux
- **User**: `~/.local/share/fonts` - user-specific
- **System**: `/usr/local/share/fonts` - system-wide
- **Fontconfig**: Can optionally update fontconfig

### Windows
- **User**: `%LOCALAPPDATA%\Microsoft\Windows\Fonts`
- **System**: `%windir%\Fonts` - requires admin
- **Registry**: No registry updates needed

## Implementation Files

- [`lib/fontist/install_location.rb`](../lib/fontist/install_location.rb) - Installation logic
- [`lib/fontist/system_font.rb`](../lib/fontist/system_font.rb) - Search logic
- [`lib/fontist/system.yml`](../lib/fontist/system.yml) - System path configuration
- [`lib/fontist/config.rb`](../lib/fontist/config.rb) - Configuration management

## Future Considerations

### Not Planned
- ❌ Arbitrary custom paths as install locations (use FONTIST_PATH to customize fontist location)
- ❌ Configurable search paths (automatic search across all locations works well)
- ❌ Per-formula location configuration (unnecessary complexity)

### Potential Enhancements
- ✅ Better permission detection before system install
- ✅ Clearer error messages for platform-specific issues
- ✅ Install location validation in config
- ✅ Warning for system installs on readonly filesystems
