# fontist convert

Transform a font file you already have, using [Fontisan](https://github.com/fontist/fontisan). Nothing is installed.

## Syntax

```sh
fontist convert format FONT_FILE FORMAT [--output FILE]
fontist convert extract COLLECTION --index N [--output-dir DIR]
fontist convert instance FONT_FILE AXES [--output FILE]
fontist convert subset FONT_FILE [--unicodes LIST] [--text TEXT] [--output FILE]
```

## Subcommands

| Subcommand | Description |
|------------|-------------|
| `format` | Convert to `ttf`, `otf`, `woff` or `woff2` |
| `extract` | Write one member of a TTC/OTC collection as a standalone font |
| `instance` | Write a static instance of a variable font at the given axis values |
| `subset` | Keep only the glyphs for the given characters |

By default each output is written next to the source: `Lato.woff2`, `Font-wght300.ttf`, `Lato-subset.ttf`. A command never overwrites its source font.

## Examples

```sh
fontist convert format Lato-Regular.ttf woff2
fontist convert extract NotoSansCJK.ttc --index 1 --output-dir out
fontist convert instance "Roboto[wdth,wght].ttf" wght=300,wdth=90
fontist convert subset Lato-Regular.ttf --unicodes "U+0020-007E" --text "é"
```

Axis tags and values are checked against the font: an unknown axis or a value outside its range fails with an error.

## Related Commands

- [fontist install](/cli/install) - The same operations while installing (`--format`, `--collection-index`, `--instance`, `--subset-*`)
