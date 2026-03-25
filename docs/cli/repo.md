# fontist repo

Manage custom font formula repositories.

## Subcommands

| Command | Description |
|---------|-------------|
| [`fontist repo setup`](#repo-setup) | Setup a custom repository |
| [`fontist repo update`](#repo-update) | Update a custom repository |
| [`fontist repo remove`](#repo-remove) | Remove a custom repository |
| [`fontist repo list`](#repo-list) | List all repositories |
| [`fontist repo info`](#repo-info) | Show repository information |

---

## repo setup

Setup a custom fontist formula repository.

### Syntax

```sh
fontist repo setup NAME URL
```

### Arguments

| Name | Required | Description |
|------|----------|-------------|
| `NAME` | Yes | Local name for the repository |
| `URL` | Yes | Git repository URL |

### Examples

```sh
# Setup a custom repository
fontist repo setup my-fonts https://github.com/myorg/font-formulas

# Setup from a private repository
fontist repo setup company git@github.com:company/font-formulas.git
```

---

## repo update

Update formulas in a custom repository.

### Syntax

```sh
fontist repo update NAME
```

### Arguments

| Name | Required | Description |
|------|----------|-------------|
| `NAME` | Yes | Repository name |

### Examples

```sh
fontist repo update my-fonts
```

---

## repo remove

Remove a custom repository.

### Syntax

```sh
fontist repo remove NAME
```

### Arguments

| Name | Required | Description |
|------|----------|-------------|
| `NAME` | Yes | Repository name |

### Examples

```sh
fontist repo remove my-fonts
```

---

## repo list

List all configured repositories.

### Syntax

```sh
fontist repo list
```

### Examples

```sh
fontist repo list
```

---

## repo info

Show information about a repository.

### Syntax

```sh
fontist repo info NAME
```

### Arguments

| Name | Required | Description |
|------|----------|-------------|
| `NAME` | Yes | Repository name |

### Examples

```sh
fontist repo info my-fonts
```

---

## Use Cases

Custom repositories are useful for:

- **Private fonts**: Host formulas for proprietary fonts
- **Organization-specific**: Share fonts within an organization
- **Testing**: Test new formulas before contributing upstream
