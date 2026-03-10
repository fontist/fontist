# fontist install

Install one or more fonts from the Fontist formula repository.

## Syntax

```sh
fontist install FONT... [options]
```

## Arguments

| Name | Required | Description |
|------|----------|-------------|
| `FONT` | Yes | One or more font names to install (variadic) |

## Options

<CliOptions command="install" />

## Examples

<CliExamples command="install" />

## Multi-font Installation

You can install multiple fonts at once:

```sh
fontist install "Fira Code" "Open Sans" "Roboto"
```

When installing multiple fonts, Fontist will:
- Install all fonts in parallel
- Report successes and failures separately
- Return appropriate exit code based on results

## Install Locations

The `--location` option controls where fonts are installed:

| Location | Description | Default |
|----------|-------------|---------|
| `fontist` | Fontist's own fonts directory | Yes |
| `user` | User's local fonts directory | No |
| `system` | System-wide fonts directory (may require admin rights) | No |

## Related Commands

- [fontist uninstall](/cli/uninstall) - Remove installed fonts
- [fontist list](/cli/list) - List available and installed fonts
- [fontist status](/cli/status) - Show installed font paths
