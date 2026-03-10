---
title: Formulas
---

# Formulas

Formulas are YAML files that describe how to download and install fonts. Fontist uses formulas to locate fonts from various sources and install them consistently across platforms.

## How Formulas Work

When you run `fontist install "Fira Code"`, Fontist:

1. Searches the formula repository for a formula matching "Fira Code"
2. Reads the formula to find the download URL and extraction instructions
3. Downloads the font archive
4. Extracts and installs the font files to your Fontist directory

The formula contains all the metadata needed: download URLs, checksums, file patterns, font names, and styles.

## Formula Repository

### Official Repository

The main formula repository is [fontist/formulas](https://github.com/fontist/formulas) on GitHub. It includes formulas for:

- Google Fonts (Roboto, Open Sans, etc.)
- SIL Fonts
- macOS system fonts
- Windows fonts
- Many other open source fonts

### Local Storage

Fontist clones the formulas repository to your local machine:

```
~/.fontist/
└── versions/
    └── v4/
        └── formulas/           # Git clone of fontist/formulas
            └── Formulas/       # YAML formula files
                ├── roboto.yml
                ├── open-sans.yml
                ├── private/    # Custom formula repos
                │   └── my-org/
                │       └── custom-font.yml
                └── ...
```

### Automatic Management

Fontist manages the formulas repository automatically:

- **Lazy initialization**: The repository is cloned on first use
- **Automatic updates**: Run `fontist update` to fetch the latest formulas
- **Shallow clone**: Only the latest commit is downloaded (depth=1) for efficiency

```sh
# Update to latest formulas
fontist update

# This pulls the latest changes and rebuilds the index
```

### Formula Index

For fast lookups, Fontist builds an index mapping font names to formula files:

```
~/.fontist/versions/v4/
├── formula_index.default_family.yml    # Font name → formula path
├── formula_index.preferred_family.yml  # Alternative naming
└── filename_index.yml                  # Filename → formula path
```

The index is rebuilt automatically when formulas are updated.

## Viewing Available Formulas

To see all available fonts:

```sh
fontist list
```

Search for a specific font:

```sh
fontist list "Roboto"
```

The list shows both installed fonts and fonts available in formulas.

## Formula Structure

A formula is a YAML file with this structure:

```yaml
name: Roboto
description: Roboto is a neo-grotesque sans-serif typeface family
homepage: https://fonts.google.com/specimen/Roboto
resources:
  Roboto.zip:
    urls:
    - https://github.com/googlefonts/Roboto/releases/download/v3.009/Roboto.zip
    sha256: abc123...
fonts:
- name: Roboto
  styles:
  - family_name: Roboto
    type: Regular
    full_name: Roboto Regular
    post_script_name: Roboto-Regular
    filename: Roboto-Regular.ttf
```

## Creating Custom Formulas

If a font isn't in the main repository, you can create a custom formula:

```sh
fontist create-formula https://example.com/fonts/myfont.zip
```

This command:

1. Downloads the font archive
2. Analyzes the font files
3. Generates a formula YAML file

You can specify options:

```sh
fontist create-formula https://example.com/fonts/myfont.zip \
  --name "My Font" \
  --subdir "fonts/otf" \
  --file-pattern "*.otf"
```

### Custom Formula Use Cases

- **Private fonts**: Create formulas for proprietary fonts your organization uses
- **New fonts**: Add support for fonts not yet in the main repository
- **Contributing**: Prepare formulas for submission to the Fontist project

## Private Formula Repositories

Organizations can maintain private formula repositories for internal or licensed fonts.

### Adding a Private Repository

```sh
# Add a private formula repository
fontist repo add my-company https://github.com/mycompany/fontist-formulas

# List configured repositories
fontist repo list

# Update a specific repository
fontist repo update my-company

# Remove a repository
fontist repo remove my-company
```

### Private Repository Structure

Private repos are stored alongside the main formulas:

```
~/.fontist/versions/v4/formulas/Formulas/private/
├── my-company/
│   ├── corporate-font.yml
│   └── licensed-font.yml
└── another-org/
    └── special-font.yml
```

### When to Use Private Repositories

- **Licensed fonts**: Fonts your organization has licensed for internal use
- **Custom fonts**: Proprietary typefaces developed in-house
- **Preliminary formulas**: Testing formulas before contributing to the main repo

See the [repo command reference](/cli/repo) for complete command documentation.

## Related

- [How Fontist Works](/guide/how-it-works) - Internal architecture and indexes
- [create-formula CLI reference](/cli/create-formula) - Command options and examples
- [repo CLI reference](/cli/repo) - Managing formula repositories
- [update CLI reference](/cli/update) - Updating formulas
