## Solution

Add version attributes to formulas:
- `catalog_version` (7 or 8)
- `min_macos_version` ("10.11" or "26.0")
- `max_macos_version` ("15.7" or nil)
- `font_version` (actual font version from font file, e.g., "2.137", "1.0")

## Example Formula (Font7)

The following is an example of a formula with all the required version attributes for catalog version 7.

```yaml
name: Al Bayan
catalog_version: 7
min_macos_version: "10.11"
max_macos_version: "15.7"
font_version: "2.137"
platforms:
  - macos-font7
resources:
  # ... resources ...
fonts:
  # ... fonts ...
```

// TODO: Add example formula for catalog version 8