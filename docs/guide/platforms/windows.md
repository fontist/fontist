---
title: Windows Platform Guide
---

# Windows Platform Guide

Fontist provides comprehensive Windows platform support, allowing installation and management of fonts on Windows 7 and later.

## Windows Font Management

Windows font management differs from Unix systems in several key ways:

| Difference | Description |
|------------|-------------|
| Path separator | Uses backslash (`\`) instead of forward slash (`/`) |
| Font locations | Registry-based and directory-based locations |
| File locking | Stricter file locking during operations |
| Permissions | Case-insensitive but case-preserving filesystem |

---

## Windows Font Locations

Fontist supports three installation locations on Windows:

### System Fonts

| Property | Value |
|----------|-------|
| Location | `C:\Windows\Fonts` |
| Requires Admin | Yes |
| Available To | All users |

### User Fonts

| Property | Value |
|----------|-------|
| Location | `%LOCALAPPDATA%\Microsoft\Windows\Fonts` |
| Requires Admin | No |
| Available To | Current user only |
| Windows Version | Windows 10+ |

### Fontist Library

| Property | Value |
|----------|-------|
| Location | `%USERPROFILE%\.fontist\fonts` |
| Requires Admin | No |
| Available To | Current user only |
| Default | Yes |

Fontist creates a `fontist` subdirectory within user and system font directories to avoid cluttering the main font directory.

---

## Installation Examples

### Install to Fontist Library (Default)

```powershell
# No administrator privileges required
fontist install "Roboto"
```

### Install to User Fonts Directory

```powershell
# No administrator privileges required (Windows 10+)
fontist install "Roboto" --location=user
```

### Install to System Fonts Directory

```powershell
# Run as Administrator
fontist install "Roboto" --location=system
```

---

## Windows-Specific Considerations

### File Locking

Windows uses stricter file locking than Unix systems. Fontist handles this with automatic retry logic when encountering locked files during cleanup operations.

If you encounter file locking issues:
1. Close applications that might be using the font
2. Retry the operation
3. Use Task Manager to identify processes locking the file

### Path Handling

Fontist automatically handles Windows path separators and drive letters. Font paths are returned in Windows-native format:

```
C:\Users\user\.fontist\fonts\font.ttf
```

### Registry Integration

While Windows historically used registry-based font registration, modern Windows (10+) supports directory-based fonts. Fontist uses directory-based installation for maximum compatibility and ease of management.

### Administrator Privileges

| Operation | Admin Required |
|-----------|----------------|
| Install to `fontist` location | No |
| Install to `user` location | No |
| Install to `system` location | Yes |
| Uninstall from system fonts | Yes |

---

## Platform Compatibility

| Windows Version | Support Status | Notes |
|-----------------|----------------|-------|
| Windows 11 | ✅ Fully Supported | All features available |
| Windows 10 | ✅ Fully Supported | User font directory available |
| Windows 8/8.1 | ✅ Supported | System and fontist locations only |
| Windows 7 | ⚠️ Limited Support | System and fontist locations only |

::: warning Windows 7 Support
Extended support for Windows 7 ended January 14, 2020. Fontist is tested on Windows 10 and later. Earlier versions may work but are not actively tested.
:::

---

## Ruby Installation on Windows

### Prerequisites

1. **RubyInstaller with DevKit** - Required for native gem extensions
2. **MSYS2** - Required for building native extensions
3. **Git for Windows** - Required for `fontist update` and `fontist repo` commands

### Installation Steps

1. Download [RubyInstaller](https://rubyinstaller.org/downloads/) (select "Ruby+Devkit" version)

2. Run the installer and check "Add Ruby executables to your PATH"

3. After installation, run MSYS2 setup:
   ```powershell
   ridk install
   ```
   Select option 3 (MSYS2 and MINGW development toolchain) when prompted.

4. Install [Git for Windows](https://git-scm.com/download/win)

5. Install Fontist:
   ```powershell
   gem install fontist
   ```

---

## Troubleshooting

### Native Extension Errors

If you see errors about failed compilations:

```powershell
# Ensure MSYS2 is properly installed
ridk install

# Reinstall the gem with verbose output
gem install fontist --verbose
```

### Permission Errors

If you get permission errors:

```powershell
# Option 1: Install to user directory
fontist install "Roboto" --location=user

# Option 2: Run as Administrator for system fonts
# Right-click PowerShell → "Run as administrator"
fontist install "Roboto" --location=system
```

### Path Too Long Errors

Windows has a 260 character path limit by default. If you encounter path issues:

1. Enable long paths in Windows (requires admin):
   ```powershell
   # Run as Administrator
   New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" `
     -Name "LongPathsEnabled" -Value 1 -PropertyType DWORD -Force
   ```

2. Or use a shorter installation path via environment variable:
   ```powershell
   $env:FONTIST_PATH = "C:\f"
   fontist install "Roboto"
   ```

---

## Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `FONTIST_PATH` | Base directory for Fontist data | `C:\fontist` |
| `FONTIST_INSTALL_LOCATION` | Default install location | `user` |
| `FONTIST_USER_FONTS_PATH` | Custom user fonts path | `C:\Users\me\Fonts` |
| `FONTIST_SYSTEM_FONTS_PATH` | Custom system fonts path | `C:\Windows\Fonts` |

---

## See Also

- [Installation Guide](/guide/installation) - General installation instructions
- [Install Command](/cli/install) - CLI reference for install
- [How Fontist Works](/guide/how-it-works) - Architecture overview
