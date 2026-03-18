# fontist uninstall

Uninstall fonts that were installed by Fontist.

## Syntax

```sh
fontist uninstall FONT
```

## Aliases

- `fontist remove` - Same as uninstall

## Arguments

| Name | Required | Description |
|------|----------|-------------|
| `FONT` | Yes | Font or formula name to uninstall |

## Examples

```sh
# Uninstall a specific font
fontist uninstall "Roboto"

# Using the remove alias
fontist remove "Open Sans"
```

## Related Commands

- [fontist install](/cli/install) - Install fonts
- [fontist status](/cli/status) - Show installed font paths
