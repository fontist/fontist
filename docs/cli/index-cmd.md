# fontist index

Rebuild the system font index by scanning system font directories.

## Syntax

```sh
fontist index
```

## Aliases

- `fontist index-rebuild` - Same as index

## Description

Rebuilds the system font index by scanning system font directories. This command scans your system for available fonts and rebuilds Fontist's internal index of system fonts.

This is useful when:
- New fonts have been installed on your system outside of Fontist
- The font index has become corrupted or out of date
- You want Fontist to recognize newly installed system fonts

## Examples

```sh
# Rebuild the system font index
fontist index

# Using the alias
fontist index-rebuild
```

## Related Commands

- [fontist status](/cli/status) - Show installed font paths
- [fontist list](/cli/list) - List available and installed fonts
