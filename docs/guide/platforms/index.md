---
title: Platform Guides
---

# Platform Guides

Fontist works consistently across macOS, Windows, and Linux, but each platform has unique characteristics and features.

## Available Platform Guides

### [macOS](/guide/platforms/macos)

Learn about:
- macOS supplementary fonts framework
- Framework versioning (Font3-Font8)
- Platform-specific font installation
- Version compatibility

### [Windows](/guide/platforms/windows)

Learn about:
- Windows font locations
- Administrator privileges
- File locking considerations
- Troubleshooting Windows-specific issues

---

## Quick Comparison

| Feature | macOS | Windows | Linux |
|---------|-------|---------|-------|
| System fonts | `/Library/Fonts` | `C:\Windows\Fonts` | `/usr/share/fonts` |
| User fonts | `~/Library/Fonts` | `%LOCALAPPDATA%\...\Fonts` | `~/.local/share/fonts` |
| Supplementary fonts | ✅ Framework | ❌ | ❌ |
| Fontconfig | ✅ Optional | ✅ Optional | ✅ Recommended |
| Admin for system | Yes | Yes | Yes |

---

## Platform-Specific Features

### macOS Supplementary Fonts

macOS includes a supplementary fonts framework for licensed fonts. Fontist can install these fonts automatically:

```sh
fontist install "Canela"
```

See the [macOS guide](/guide/platforms/macos) for details.

### Windows Font Management

Windows uses different font locations and has stricter file locking:

```powershell
# Install to user fonts (no admin needed)
fontist install "Roboto" --location user
```

See the [Windows guide](/guide/platforms/windows) for details.

### Linux Fontconfig

On Linux, Fontist integrates with fontconfig to make fonts available system-wide:

```sh
fontist fontconfig update
```

See the [Fontconfig guide](/guide/fontconfig) for details.
