# fontist list

List installation status of fonts available in Fontist.

## Syntax

```sh
fontist list [FONT]
```

## Arguments

| Name | Required | Description |
|------|----------|-------------|
| `FONT` | No | Optional font name to filter results |

## Examples

```sh
# List all fonts and their installation status
fontist list

# Check status of a specific font
fontist list "Fira Mono"
```

## Output Format

The list shows:
- Formula name
- Font name
- Style type (Regular, Bold, Italic, etc.)
- Installation status (installed/not installed)
- Manual flag (if font requires manual installation)

## Related Commands

- [fontist install](/cli/install) - Install fonts
- [fontist status](/cli/status) - Show installed font paths
