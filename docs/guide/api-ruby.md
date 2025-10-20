# Fontist Ruby library

In addition to the command-line interface, Fontist can be used as a Ruby library.

## Fontist::Font

The `Fontist::Font` is your go-to place to deal with any font using Fontist.

This interface allows you to find a font or install a font.

### Finding a font

The `Fontist::Font.find` interface can be used to find a font in your system.

It will look into the operating system specific font directories, and also the fontist specific `~/.fontist` directory.

```ruby
Fontist::Font.find(name)
```

- If Fontist finds a font, then it will return the paths.
- Otherwise, it will either raise an unsupported font error, or trigger display of installation instructions for that specific font.

### Install a font

The `Fontist::Font.install` interface can be used to install any supported font.

This interface first checks if you already have that font installed or not and if you do, then it will return the paths.

If you don't have a font but that font is supported by Fontist, then it will download the font and copy it to `~/.fontist` directory and also return the paths.

```ruby
Fontist::Font.install(name, confirmation: "no")
```

If there are issues detected with the provided font, such as the font is not supported, those errors would be raised.

### List all fonts

The `Fontist::Font` interface exposes an interface to list all supported fonts.

This might be useful if you want to know the name of the font or the available styles. You can do that by using:

```ruby
Fontist::Font.all
```

The return values are `OpenStruct` objects, so you can easily do any other operation you would do in any Ruby object.

## Fontist::Formula

The `fontist` gem internally uses the `Fontist::Formula` interface to find a registered formula or fonts supported by any formula. Unless you need to do anything with that, you shouldn't need to work with this interface directly. But if you do, then these are the public interfaces it offers.

### Find a formula

The `Fontist::Formula.find` interface allows you to find any of the registered formulas. This interface takes a font name as an argument and it looks through each of the registered formulas that offer this font installation. Usages:

```ruby
Fontist::Formula.find("Calibri")
```

This method will search and return a Fontist formula for the provided keyword which allows for further processing, such as license checks or proceeding with the installation of the font in your system.

### List font styles supported by a formula

Normally, each font name can be associated with multiple styles or collections, for example, the `Calibri` font might contain `regular`, `bold`, or `italic` styles fonts and if you want an interface that can return the complete list then this is your friend.

You can use it as following:

```ruby
Fontist::Formula.find_fonts("Calibri")
```

### List all formulas

The `Fontist::Formula` interface exposes an interface to list all registered font formulas. This might be useful if you want to know the name of the formula or what type of fonts can be installed using that formula. Usages:

```ruby
Fontist::Formula.all
```

The return values are `OpenStruct` objects, so you can easily do any other operation you would do in any Ruby object.

## Fontist::Manifest

### Global options

Fontist can be switched to use the preferred family names. This format was used prior to v1.10.

```ruby
Fontist.preferred_family = true
```

### Manifest from YAML file or Hash

Fontist lets you find font locations from a defined manifest Hash in the following format:

```ruby
{
  "Segoe UI"=>["Regular", "Bold"],
  "Roboto Mono"=>["Regular"]
}
```

Calling the following code returns a nested Hash with font paths and names. Font name is useful to choose a specific font in a font collection file (TTC).

```ruby
Fontist::Manifest.from_yaml(manifest)
Fontist::Manifest.from_hash(manifest)
```

```ruby
{
  "Segoe UI"=> {
    "Regular"=>{
      "full_name"=>"Segoe UI",
      "paths"=>["/Users/user/.fontist/fonts/SEGOEUI.TTF"]
    },
    "Bold"=>{
      "full_name"=>"Segoe UI Bold",
      "paths"=>["/Users/user/.fontist/fonts/SEGOEUIB.TTF"]
    }
  },
  "Roboto Mono"=> {
    "Regular"=>{
      "full_name"=>nil,
      "paths"=>[]
    }
  }
}
```

Fontist lets you not only obtain font locations but also install fonts from the manifest:

```ruby
manifest.install(confirmation: "yes")
```

It will install fonts and return their locations:

```ruby
{
  "Segoe UI"=> {
    "Regular"=>{
      "full_name"=>"Segoe UI",
      "paths"=>["/Users/user/.fontist/fonts/SEGOEUI.TTF"]},
    "Bold"=>{
      "full_name"=>"Segoe UI Bold",
      "paths"=>["/Users/user/.fontist/fonts/SEGOEUIB.TTF"]
    }
  },
  "Roboto Mono"=> {
    "Regular"=>{
      "full_name"=>"Roboto Mono Regular",
      "paths"=>["/Users/user/.fontist/fonts/RobotoMono-VariableFont_wght.ttf"]
    }
  }
}
```

#### Support of YAML format

Both commands support a YAML file as an input with a `from_file` method. For example, if there is a `manifest.yml` file containing:

```yaml
---
Segoe UI:
  - Regular
  - Bold
Roboto Mono:
  - Regular
```

Then the following calls would return font names and paths, as from the `from_hash` method (see Fontist::Manifest).

```ruby
manifest = Fontist::Manifest.from_file("manifest.yml")
manifest.install(confirmation: "yes")
```

## Fontist::Fontconfig

Fontist supports work with Fontconfig via the Ruby interface:

```ruby
Fontist::Fontconfig.update              # let detect fontist fonts
Fontist::Fontconfig.remove              # disable detection
Fontist::Fontconfig.remove(force: true) # do not fail if no config exists
```
