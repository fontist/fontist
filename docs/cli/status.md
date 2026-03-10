# fontist status

Show paths of installed fonts on your system.

## Syntax

```sh
fontist status [FONT]
```

## Arguments

| Name | Required | Description |
|------|----------|-------------|
| `FONT` | No | Optional font name to filter results |

## Examples

```sh
# Show all installed fonts on the system
fontist status

# Show paths for a specific font
fontist status "Open Sans"
```

## System Font Detection

The `status` command searches **all fonts available on your system**, including:
- Fonts installed by Fontist
- System fonts (Windows, macOS, Linux)
- User-installed fonts

This is useful to see if a font you need is already available before installing it with Fontist.

## Related Commands

- [fontist install](/cli/install) - Install fonts
- [fontist list](/cli/list) - List available and installed fonts
