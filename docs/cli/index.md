# Fontist CLI Reference

Complete command-line interface reference for Fontist.

## Quick Reference

| Command | Description |
|---------|-------------|
| [`fontist install`](/cli/install) | Install fonts |
| [`fontist uninstall`](/cli/uninstall) | Uninstall fonts |
| [`fontist list`](/cli/list) | List font status |
| [`fontist status`](/cli/status) | Show font paths |
| [`fontist update`](/cli/update) | Update formulas |
| [`fontist version`](/cli/version) | Show version info |

## Subcommands

| Command | Description |
|---------|-------------|
| [`fontist manifest`](/cli/manifest) | Manifest management |
| [`fontist index`](/cli/index-cmd) | System font index |
| [`fontist cache`](/cli/cache) | Cache management |
| [`fontist config`](/cli/config) | Configuration |
| [`fontist repo`](/cli/repo) | Custom repositories |
| [`fontist fontconfig`](/cli/fontconfig) | Fontconfig integration |
| [`fontist import`](/cli/import) | Import fonts |
| [`fontist create-formula`](/cli/create-formula) | Create formulas |

## Global Options

These options work with all commands:

| Option | Description |
|--------|-------------|
| `--quiet` | Suppress output |
| `--verbose` | Enable verbose output |
| `--debug` | Enable debug output |
| `--color` | Force colored output |
| `--no-color` | Disable colored output |

## Environment Variables

| Variable | Description |
|----------|-------------|
| `FONTIST_PATH` | Override Fontist directory (default: `~/.fontist`) |
| `FONTIST_NO_PROGRESS` | Disable progress bars |

## Getting Help

```sh
# Show general help
fontist help

# Show command-specific help
fontist install --help
fontist manifest --help
```

## Exit Codes

Fontist uses standard exit codes for scripting. See the [Exit Codes Reference](/cli/exit-codes) for details.

---

## Installation

```sh
gem install fontist
```

## Prerequisites

- Ruby 2.7 or higher
- Network access for downloading fonts

## Next Steps

- [Getting Started Guide](/guide/) - Learn the basics
- [Using Fontist in CI](/guide/ci) - CI/CD integration
- [Manifest Support](/cli/manifest) - Reproducible installations
