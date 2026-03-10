# fontist fontconfig

Manage fontconfig integration for Linux systems.

## Subcommands

| Command | Description |
|---------|-------------|
| [`fontist fontconfig update`](#fontconfig-update) | Update fontconfig to use Fontist fonts |
| [`fontist fontconfig remove`](#fontconfig-remove) | Remove Fontist from fontconfig |

---

## fontconfig update

Update fontconfig configuration to include Fontist-installed fonts.

### Syntax

```sh
fontist fontconfig update
```

### Description

Creates or updates a fontconfig configuration file that includes Fontist's font directory. This allows applications using fontconfig to discover and use fonts installed by Fontist.

### Examples

```sh
fontist fontconfig update
```

### Requirements

- Fontconfig must be installed on your system
- Typically used on Linux systems

---

## fontconfig remove

Remove Fontist's fontconfig configuration.

### Syntax

```sh
fontist fontconfig remove [options]
```

### Options

| Option | Alias | Type | Description |
|--------|-------|------|-------------|
| `--force` | `-f` | boolean | Proceed even if configuration file does not exist |

### Examples

```sh
# Remove fontconfig integration
fontist fontconfig remove

# Force removal
fontist fontconfig remove --force
```

---

## How It Works

Fontist integrates with fontconfig by creating a configuration file at:
- `~/.config/fontconfig/99-fontist.conf` (or equivalent on your system)

This configuration adds Fontist's fonts directory to fontconfig's search path.

## When to Use

Use fontconfig integration when:
- Running Linux applications that rely on fontconfig
- Applications need to discover fonts through fontconfig rather than direct file paths
- Working with document rendering systems (LaTeX, etc.)

## Related

- [Fontist with Fontconfig guide](/guide/fontconfig) - Detailed integration guide
