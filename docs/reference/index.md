# Fontist CLI reference

<!-- This can be converted to a folder & multiple pages at any time. -->

## `fontist cache`

The only subcommand available on `fontist cache` is `fontist cache clear`. It clears the `~/.fontist` cache.

```sh
fontist cache clear
```

```
Cache has been successfully removed.
```

## `fontist config`

`fontist config` lets you edit the Fontist config file from the command line instead of opening an editor. There are four subcommands available:

- `fontist config delete <key>`
- `fontist config keys`
- `fontist config set <key> <value>`
- `fontist config show`

Here's an example of these commands being used to edit the config file:

```sh
fontist config keys
fontist config set font_path /var/myfonts
fontist config delete font_path
fontist config show
```

```
$ fontist config keys
Available keys:
fonts_path (default: /home/octocat/.fontist/fonts)
open_timeout (default: 60)
read_timeout (default: 60)

$ fontist config set fonts_path /var/myfonts
'fonts_path' set to '/var/myfonts'.

$ fontist config delete fonts_path
'fonts_path' reset to default ('/home/octocat/.fontist/fonts').

$ fontist config show
Config is empty.
```

### Config reference

<!-- Move this into its own '/reference/config' page if this grows a lot. -->

- **`fonts_path`:** Where to put the `.ttf` files. Defaults to `~/.fontist/fonts`

- **`open_timeout`:** Defaults to 60.

- **`read_timeout`:** Defaults to 60.

## `fontist status [font-name]`

Prints the paths to a particular installed font or all fonts if the `font-name` is omitted. This searches **all fonts available on your system** even those not managed by Fontist.

```sh
fontist status
```

```
Fonts found at:
- /usr/share/fonts/truetype/ubuntu/UbuntuMono-B.ttf
- /usr/share/fonts/truetype/ubuntu/UbuntuMono-BI.ttf
- /usr/share/fonts/truetype/ubuntu/UbuntuMono-R.ttf
- /usr/share/fonts/truetype/ubuntu/UbuntuMono-RI.ttf
- /home/octocat/.fontist/fonts/Arial.ttf (from ms_truetype formula)
- /home/octocat/.fontist/fonts/ArialBI.ttf (from ms_truetype formula)
- /home/octocat/.fontist/fonts/ArialBd.ttf (from ms_truetype formula)
- /home/octocat/.fontist/fonts/ArialI.ttf (from ms_truetype formula)
```

Here's an example narrowed to a specific font:

```sh
fontist status "Open Sans"
```

```
Fonts found at:
- /home/octocat/.fontist/fonts/OpenSans-Bold.ttf (from open_sans formula)
- /home/octocat/.fontist/fonts/OpenSans-BoldItalic.ttf (from open_sans formula)
- /home/octocat/.fontist/fonts/OpenSans-Italic.ttf (from open_sans formula)
- /home/octocat/.fontist/fonts/OpenSans-Regular.ttf (from open_sans formula)
```

## `fontist list [font-name]`

Lists the installation status of `font-name` or all fonts if no font name provided.

```sh
fontist status
```

```
Fonts found at:
- /usr/share/fonts/truetype/ubuntu/UbuntuMono-B.ttf
- /usr/share/fonts/truetype/ubuntu/UbuntuMono-BI.ttf
- /usr/share/fonts/truetype/ubuntu/UbuntuMono-R.ttf
- /usr/share/fonts/truetype/ubuntu/UbuntuMono-RI.ttf
- /home/octocat/.fontist/fonts/Arial.ttf (from ms_truetype formula)
- /home/octocat/.fontist/fonts/ArialBI.ttf (from ms_truetype formula)
- /home/octocat/.fontist/fonts/ArialBd.ttf (from ms_truetype formula)
- /home/octocat/.fontist/fonts/ArialI.ttf (from ms_truetype formula)
```

Here's an example getting the status of a specific font:

```sh
fontist status "Fira Mono"
```

```
Font "Fira Mono" not found locally.
'Fira Mono' font is missing, please run `fontist install 'Fira Mono'` to download the font.
```

## Environment variables

### `FONTIST_PATH`

By default Fontist uses the `~/.fontist` directory to store fonts and its files. It can be changed with the `FONTIST_PATH` environment variable.

```sh
FONTIST_PATH=/var/fontist2 fontist update
```

## Excluded fonts

`fontist` excludes some fonts from usage when they break other software:

- `NISC18030.ttf` (GB18030 Bitmap) - macOS [fontist/fontist#344](https://github.com/fontist/fontist/issues/344)

[📑 View the up-to-date list of known problematic fonts on GitHub](https://github.com/fontist/fontist/blob/main/lib/fontist/exclude.yml)
