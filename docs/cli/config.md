# fontist config

Manage Fontist configuration settings.

## Subcommands

| Command | Description |
|---------|-------------|
| [`fontist config show`](#config-show) | Show current configuration |
| [`fontist config set`](#config-set) | Set a configuration value |
| [`fontist config delete`](#config-delete) | Delete a configuration key |
| [`fontist config keys`](#config-keys) | List available configuration keys |

---

## config show

Show values of the current configuration.

### Syntax

```sh
fontist config show
```

### Examples

```sh
fontist config show
```

---

## config set

Set a configuration key to a value.

### Syntax

```sh
fontist config set KEY VALUE
```

### Arguments

| Name | Required | Description |
|------|----------|-------------|
| `KEY` | Yes | Configuration key name |
| `VALUE` | Yes | Value to set |

### Examples

```sh
# Set custom fonts path
fontist config set fonts_path /var/myfonts

# Set timeout
fontist config set open_timeout 120
```

---

## config delete

Delete a configuration key (resets to default).

### Syntax

```sh
fontist config delete KEY
```

### Arguments

| Name | Required | Description |
|------|----------|-------------|
| `KEY` | Yes | Configuration key to delete |

### Examples

```sh
fontist config delete fonts_path
```

---

## config keys

List all available configuration keys with their default values.

### Syntax

```sh
fontist config keys
```

### Examples

```sh
fontist config keys
```

Output:
```
Available keys:
fonts_path (default: /home/user/.fontist/fonts)
open_timeout (default: 60)
read_timeout (default: 60)
```

---

## Available Configuration Keys

| Key | Default | Description |
|-----|---------|-------------|
| `fonts_path` | `~/.fontist/fonts` | Where Fontist installs fonts |
| `open_timeout` | 60 | HTTP open timeout in seconds |
| `read_timeout` | 60 | HTTP read timeout in seconds |

## Configuration File

Configuration is stored in `~/.fontist/config.yml`.
