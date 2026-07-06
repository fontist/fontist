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

| Option | Alias | Type | Description |
|--------|-------|------|-------------|
| `--force` | `-f` | boolean | Install even if already installed in system |
| `--formula` | `-F` | boolean | Install whole formula instead of a font |
| `--accept-all-licenses` | `-a` | boolean | Accept all license agreements |
| `--hide-licenses` | `-h` | boolean | Hide license texts |
| `--no-progress` | `-p` | boolean | Hide download progress |
| `--version` | `-V` | string | Specify particular version of a font |
| `--smallest` | `-s` | boolean | Install the smallest font by file size if several |
| `--newest` | `-n` | boolean | Install the newest version of a font if several |
| `--size-limit` | `-S` | numeric | Specify upper limit for file size of a formula to be installed (default: 500 MB) |
| `--update-fontconfig` | `-u` | boolean | Update fontconfig |
| `--location` | `-l` | string | Install location: `fontist` (default), `user`, `system` |
| `--format FORMAT` | | string | Font format to install (ttf, otf, woff, woff2, ttc, otc). If format not available, will transcode from available formats
| `--variable-axes` | | string | Variable axes to match (comma-separated, e.g., 'wght,wdth') |
| `--prefer-variable` | | boolean | Prefer variable fonts over static fonts |
| `--prefer-format FORMAT` | | string | Preferred format when multiple available
| `--transcode-path PATH` | | string | Directory to save transcoded fonts (default: same as install location)
| `--keep-original` | | boolean | Keep original font after transcoding. (default: true)
| `--collection-index N` | | numeric | Extract specific font from TTC/OTC collection (0-indexed)



## Examples

### Common uses

```sh
# Install a single font
fontist install "Roboto"

# Install multiple fonts
fontist install "Fira Code" "Open Sans"

# Force reinstall
fontist install "Roboto" --force

# Install to user directory
fontist install "Roboto" --location user

# Accept licenses automatically (for CI)
fontist install "Roboto" --accept-all-licenses --hide-licenses

# Install a specific version
fontist install "Roboto" --version 2.0

# Install whole formula
fontist install "Roboto" --formula
```


### Multi-font Installation

You can install multiple fonts at once:

```sh
fontist install "Fira Code" "Open Sans" "Roboto"
```

When installing multiple fonts, Fontist will:
- Install all fonts in parallel
- Report successes and failures separately
- Return appropriate exit code based on results

### Install Locations

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
