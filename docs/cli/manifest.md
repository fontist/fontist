# fontist manifest

Manage font manifests for reproducible font installations.

## Subcommands

| Command | Description |
|---------|-------------|
| [`fontist manifest install`](#manifest-install) | Install fonts from a manifest file |
| [`fontist manifest locations`](#manifest-locations) | Get locations of fonts from a manifest |

---

## manifest install

Install fonts defined in a YAML manifest file.

### Syntax

```sh
fontist manifest install MANIFEST [options]
```

### Arguments

| Name | Required | Description |
|------|----------|-------------|
| `MANIFEST` | Yes | Path to YAML manifest file |

### Options

| Option | Alias | Type | Description |
|--------|-------|------|-------------|
| `--accept-all-licenses` | `-a` | boolean | Accept all license agreements |
| `--hide-licenses` | `-h` | boolean | Hide license texts |
| `--location` | `-l` | string | Install location: fontist, user, or system |

### Examples

```sh
# Install fonts from manifest
fontist manifest install fonts.yml

# Accept licenses automatically (for CI)
fontist manifest install fonts.yml --accept-all-licenses --hide-licenses

# Install to user directory
fontist manifest install fonts.yml --location user
```

---

## manifest locations

Get the file system locations of fonts defined in a manifest.

### Syntax

```sh
fontist manifest locations MANIFEST [options]
```

### Arguments

| Name | Required | Description |
|------|----------|-------------|
| `MANIFEST` | Yes | Path to YAML manifest file |

### Options

| Option | Alias | Type | Description |
|--------|-------|------|-------------|
| `--show-timing` | `-t` | boolean | Show timing information for manifest resolution |

### Examples

```sh
# Get font paths from manifest
fontist manifest locations fonts.yml

# Show timing information
fontist manifest locations fonts.yml --show-timing
```

---

## Manifest File Format

A manifest is a YAML file listing required fonts:

```yaml
# Simple font list
Roboto:
Source Sans Pro:
Fira Code:
```

```yaml
# With specific styles
Roboto:
  - Regular
  - Bold
  - Italic
```

## Use Cases

- **CI/CD**: Define project fonts in a manifest file for reproducible builds
- **Team projects**: Share font requirements across team members
- **Documentation**: Self-documenting font requirements
