---
title: Manifests
---

# Manifests

Manifests are YAML files that define the fonts your project requires. They enable reproducible font installations across teams, machines, and CI/CD pipelines.

## Basic Format

A manifest is a simple YAML file listing font names:

```yaml
Fira Code:
Open Sans:
Roboto:
```

Save this as `fonts.yml` and install all fonts with:

```sh
fontist manifest install fonts.yml
```

## Specifying Styles

You can request specific font styles:

```yaml
Roboto:
  - Regular
  - Bold
  - Italic

Open Sans:
  - Regular
  - Bold
```

If no styles are specified, Fontist installs all available styles for each font.

## Finding Font Names

To see available fonts and their exact names:

```sh
fontist list
```

Search for a specific font:

```sh
fontist list "Roboto"
```

## Getting Font Locations

After installing fonts from a manifest, you can get their file paths:

```sh
fontist manifest locations fonts.yml
```

Output is a YAML structure with paths:

```yaml
---
Roboto:
  Regular:
    full_name: Roboto
    paths:
    - "/home/user/.fontist/fonts/Roboto-Regular.ttf"
  Bold:
    full_name: Roboto Bold
    paths:
    - "/home/user/.fontist/fonts/Roboto-Bold.ttf"
```

This output can be parsed by scripts or used directly in applications.

## Use Cases

### CI/CD Pipelines

Define project fonts in a manifest for reproducible builds:

```yaml
# fonts.yml
Fira Code:
Source Sans Pro:
```

```yaml
# .github/workflows/build.yml
steps:
  - uses: actions/checkout@v4
  - uses: fontist/setup@v1
  - run: fontist manifest install fonts.yml --accept-all-licenses --hide-licenses
```

### Team Projects

Commit `fonts.yml` to your repository so all team members use the same fonts:

```yaml
# Project fonts - install with: fontist manifest install fonts.yml
Merriweather:
  - Regular
  - Bold
Inter:
  - Regular
```

### Documentation

Manifests serve as self-documenting font requirements. Anyone joining the project can see exactly which fonts are needed.

## CI Options

For automated environments, use these flags:

```sh
fontist manifest install fonts.yml --accept-all-licenses --hide-licenses
```

- `--accept-all-licenses` - Skip license prompts
- `--hide-licenses` - Don't display license text

## Related

- [fontist manifest CLI reference](/cli/manifest) - Complete command documentation
- [CI/CD Integration guide](/guide/ci) - Setting up Fontist in CI
