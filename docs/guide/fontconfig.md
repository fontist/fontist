# Fontist with Fontconfig

Fontconfig is software designed to provide fonts to other programs. It is typically used on Linux, but also available on macOS and Windows. Fontconfig is used by LibreOffice, GIMP, and many other programs.

In order to find Fontist fonts, Fontconfig should be updated to include Fontist paths. This can be done with the `--update-fontconfig` option of `install`:

```sh
fontist install --update-fontconfig 'courier prime'
```

Or by calling a special command:

```sh
fontist fontconfig update
```

This will create a configuration file in `~/.config/fontconfig/conf.d/10-fontist.conf`.

To remove it, please use:

```sh
fontist fontconfig remove
```
