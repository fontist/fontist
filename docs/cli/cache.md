# fontist cache

Manage Fontist cache directories.

## Subcommands

| Command | Description |
|---------|-------------|
| [`fontist cache clear`](#cache-clear) | Clear font download cache |
| [`fontist cache clear-import`](#cache-clear-import) | Clear import cache |
| [`fontist cache info`](#cache-info) | Show cache information |

---

## cache clear

Clear the font download cache.

### Syntax

```sh
fontist cache clear
```

### Description

Removes:
- Downloaded font archives
- System font indexes

This does not remove installed fonts, only cached downloads.

### Examples

```sh
fontist cache clear
```

---

## cache clear-import

Clear the import cache used during formula creation.

### Syntax

```sh
fontist cache clear-import [options]
```

### Options

| Option | Alias | Type | Description |
|--------|-------|------|-------------|
| `--verbose` | `-v` | boolean | Show detailed output |

### Examples

```sh
fontist cache clear-import
```

---

## cache info

Show cache information including sizes and file counts.

### Syntax

```sh
fontist cache info
```

### Output

- Font download cache location and size
- Import cache location and size
- File counts for each cache

### Examples

```sh
fontist cache info
```

---

## Cache Locations

| Cache | Default Location |
|-------|-------------------|
| Font downloads | `~/.fontist/downloads` |
| Import cache | `~/.fontist/import_cache` |

## When to Clear Cache

- **Free disk space**: Cache can grow large with many font downloads
- **Corrupted downloads**: If a download was interrupted or corrupted
- **After import operations**: Clear import cache after creating formulas
