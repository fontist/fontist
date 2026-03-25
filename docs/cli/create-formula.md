# fontist create-formula

Create a new Fontist formula from a font download URL.

## Syntax

```sh
fontist create-formula URL [options]
```

## Arguments

| Name | Required | Description |
|------|----------|-------------|
| `URL` | Yes | URL to download fonts from |

## Options

| Option | Type | Description |
|--------|------|-------------|
| `--name` | string | Font name (e.g., "Times New Roman") |
| `--mirror` | array | Mirror URLs (can be repeated) |
| `--subdir` | string | Subdirectory to extract fonts from |
| `--file-pattern` | string | File pattern to match (e.g., "*.otf") |
| `--name-prefix` | string | Prefix for font family names |

## Examples

```sh
# Create formula from a font archive
fontist create-formula https://example.com/fonts/myfont.zip

# Specify font name
fontist create-formula https://example.com/fonts/myfont.zip --name "My Font"

# Use subdirectory
fontist create-formula https://example.com/fonts/myfont.zip --subdir "fonts/otf"

# Filter by file pattern
fontist create-formula https://example.com/fonts/myfont.zip --file-pattern "*.otf"

# Add mirror URLs
fontist create-formula https://example.com/fonts/myfont.zip --mirror https://mirror.example.com/fonts/myfont.zip

# Create formula with name prefix (for compatibility fonts)
fontist create-formula https://dl.winehq.org/wine/source/10.x/wine-10.18.tar.xz \
  --subdir fonts \
  --file-pattern "*.ttf" \
  --name-prefix "Wine "
```

## How It Works

1. Downloads the font archive from the URL
2. Extracts and analyzes font files
3. Detects font names, styles, and metadata
4. Generates a formula YAML file

## Generated Formula

The formula is saved to `./Formulas/` directory with a filename based on the font name.

## Use Cases

- **New fonts**: Create formulas for fonts not in Fontist
- **Private fonts**: Create formulas for proprietary fonts
- **Contributing**: Prepare formulas for submission to Fontist

## Related

- [Create a Formula Guide](https://www.fontist.org/formulas/guide/create-formula) - Detailed formula creation guide
