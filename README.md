# Fontist

[![Build Status](https://github.com/fontist/fontist/actions/workflows/rspec.yml/badge.svg)](https://github.com/fontist/fontist/actions/workflows/rspec.yml)
[![Gem Version](https://img.shields.io/gem/v/fontist.svg)](https://rubygems.org/gems/fontist)
[![Pull Requests](https://img.shields.io/github/issues-pr-raw/fontist/fontist.svg)](https://github.com/fontist/fontist/pulls)

A simple library to find and download fonts for Windows, Linux and Mac.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "fontist"
```

And then execute:

```sh
bundle install
```

Or install it yourself as:

```sh
gem install fontist
```

### Fetch formulas

After installation please fetch formulas to your system:

```sh
fontist update
```

### Dependencies

Depends on
[ffi-libarchive-binary](https://github.com/fontist/ffi-libarchive-binary) which
has the following requirements:

* zlib
* Expat
* OpenSSL (for Linux only)

These dependencies are generally present on all systems.

## Usage

### Font

The `Fontist::Font` is your go to place to deal with any font using fontist. This
interface will allow you to find a font or install a font. Lets start with how
can we find a font in your system.

#### Finding a font

The `Fontist::Font.find` interface can be used a find a font in your system.
It will look into the operating system specific font directories, and also the
fontist specific `~/.fontist` directory.

```ruby
Fontist::Font.find(name)
```

If fontist find a font then it will return the paths, but if not found then it
will could raise an unsupported font error or maybe an installation instruction
for that specific font.

#### Install a font

The `Fontist::Font.install` interface can be used to install any supported font.
This interface first checks if you already have that font installed or not and
if you do then it will return the paths.

If you don't but supported by fontist, then it will download the font and copy
it to `~/.fontist` directory and also return the paths.

```ruby
Fontist::Font.install(name, confirmation: "no")
```

If there are some issue with the provided font, like not supported or some other
issue then it will raise those errors.

#### List all fonts

The `Fontist::Font` interface exposes an interface to list all supported fonts,
this might be useful if want to know the name of the font or the available
styles. You can do that by using:

```ruby
Fontist::Font.all
```

The return values are ` OpenStruct` object, so you can easily do any other
operation you would do in any ruby object.

### Formula

The `fontist` gem internally usages the `Fontist::Formula` interface to find a
registered formula or fonts supported by any formula. Unless, you need to do
anything with that you shouldn't need to work with this interface directly. But
if you do then these are the public interface it offers.

#### Find a formula

The `Fontist::Formula.find` interface allows you to find any of the registered
formula. This interface takes a font name as an argument and it looks through
each of the registered formula that offers this font installation. Usages:

```ruby
Fontist::Formula.find("Calibri")
```

The above method will find which formula offers this font and then it will
return a installable formula that can be used to check licences or install that
fonts in your system.

#### Find formula fonts

Normally, each font name can be associated with multiple styles or collection, for
example the `Calibri` font might contains a `regular`, `bold` or `italic` styles
fonts and if you want a interface that can return the complete list then this is
your friend. You can use it as following:

```ruby
Fontist::Formula.find_fonts("Calibri")
```


#### List all formulas

The `Fontist::Formula` interface exposes an interface to list all registered
font formula. This might be useful if want to know the name of the formula or
what type fonts can be installed using that formula. Usages:

```ruby
Fontist::Formula.all
```

The return values are ` OpenStruct` object, so you can easily do any other
operation you would do in any ruby object.


### Manifest

#### Locations

Fontist lets find font locations from a manifest of the following format:

```ruby
{"Segoe UI"=>["Regular", "Bold"],
 "Roboto Mono"=>["Regular"]}
```

Calling the following code returns a nested hash with font paths and names.
Font name is useful to choose a specific font in a font collection file (TTC).

```ruby
Fontist::Manifest::Locations.from_hash(manifest)
```

```ruby
{"Segoe UI"=> {
   "Regular"=>{"full_name"=>"Segoe UI",
               "paths"=>["/Users/user/.fontist/fonts/SEGOEUI.TTF"]},
   "Bold"=>{"full_name"=>"Segoe UI Bold",
            "paths"=>["/Users/user/.fontist/fonts/SEGOEUIB.TTF"]}},
 "Roboto Mono"=> {
   "Regular"=>{"full_name"=>nil,
               "paths"=>[]}}}
```

#### Install

Fontist lets not only to get font locations but also to install fonts from the
manifest:

```ruby
Fontist::Manifest::Install.from_hash(manifest, confirmation: "yes")
```

It will install fonts and return their locations:

```ruby
{"Segoe UI"=> {
   "Regular"=>{"full_name"=>"Segoe UI",
               "paths"=>["/Users/user/.fontist/fonts/SEGOEUI.TTF"]},
   "Bold"=>{"full_name"=>"Segoe UI Bold",
            "paths"=>["/Users/user/.fontist/fonts/SEGOEUIB.TTF"]}},
 "Roboto Mono"=> {
   "Regular"=>{"full_name"=>"Roboto Mono Regular",
               "paths"=>["/Users/user/.fontist/fonts/RobotoMono-VariableFont_wght.ttf"]}}}
```

#### Support of YAML format

Both commands support a YAML file as an input with a `from_file` method. For
example, if there is a `manifest.yml` file containing:

```yaml
Segoe UI:
- Regular
- Bold
Roboto Mono:
- Regular
```

Then the following calls would return font names and paths, as from the
`from_hash` method (see [Locations](#locations) and [Install](#install)).

```ruby
Fontist::Manifest::Locations.from_file("manifest.yml")
Fontist::Manifest::Install.from_file("manifest.yml", confirmation: "yes")
```

### CLI

These commands makes possible to operate with fonts via command line. The CLI
properly supports exit status, so in a case of error it returns a status code
higher or equal than 1.

All searches are case-insensitive for ease of use.

#### Install

The `install` command is similar to the `Font.install` call. It first checks
whether this font is already installed, and if not, then installs the font and
returns its paths. Only font name (not formula name, nor font filename) could
be used as a parameter.

```
$ fontist install "segoe ui"
These fonts are found or installed:
/Users/user/.fontist/fonts/SEGOEUI.TTF
/Users/user/.fontist/fonts/SEGOEUIB.TTF
/Users/user/.fontist/fonts/SEGOEUII.TTF
/Users/user/.fontist/fonts/SEGOEUIZ.TTF
```

#### Uninstall

Uninstalls any font supported by Fontist. Returns paths of an uninstalled font,
or prints an error telling that the font isn't installed or could not be found
in Fontist formulas. Aliased as `remove`.

```
$ fontist uninstall "segoe ui"
These fonts are removed:
/Users/user/.fontist/fonts/SEGOEUII.TTF
/Users/user/.fontist/fonts/SEGOEUIZ.TTF
/Users/user/.fontist/fonts/SEGOEUIB.TTF
/Users/user/.fontist/fonts/SEGOEUI.TTF
```

#### Status

Prints installed font paths grouped by formula and font.

```
$ fontist status "segoe ui"
segoe_ui
 Segoe UI
  Regular (/Users/user/.fontist/fonts/SEGOEUI.TTF)
  Bold (/Users/user/.fontist/fonts/SEGOEUIB.TTF)
  Italic (/Users/user/.fontist/fonts/SEGOEUII.TTF)
  Bold Italic (/Users/user/.fontist/fonts/SEGOEUIZ.TTF)
```

#### List

Lists installation status of fonts supported by Fontist.

```
$ fontist list "segoe ui"
segoe_ui
 Segoe UI
  Regular (installed)
  Bold (installed)
  Italic (installed)
  Bold Italic (installed)
```

```
$ fontist list "roboto mono"
google/roboto_mono
 Roboto Mono
  Regular (uninstalled)
  Italic (uninstalled)
```

#### Locations from manifest

Returns locations of fonts specified in a YAML file as an input.

For example, if there is a file `manifest.yml`:

```yml
Segoe UI:
- Regular
- Bold
Roboto Mono:
- Regular
```

Then the command will return the following YAML output:

```yml
$ fontist manifest-locations manifest.yml
---
Segoe UI:
  Regular:
    full_name: Segoe UI
    paths:
    - "/Users/user/.fontist/fonts/SEGOEUI.TTF"
  Bold:
    full_name: Segoe UI Bold
    paths:
    - "/Users/user/.fontist/fonts/SEGOEUIB.TTF"
Roboto Mono:
  Regular:
    full_name:
    paths: []
```

Since Segoe UI is installed, but Roboto Mono is not.

#### Install from manifest

Install fonts from a YAML manifest:

```yml
$ fontist manifest-install --confirm-license manifest.yml
---
Segoe UI:
  Regular:
    full_name: Segoe UI
    paths:
    - "/Users/user/.fontist/fonts/SEGOEUI.TTF"
  Bold:
    full_name: Segoe UI Bold
    paths:
    - "/Users/user/.fontist/fonts/SEGOEUIB.TTF"
Roboto Mono:
  Regular:
    full_name: Roboto Mono Regular
    paths:
    - "/Users/user/.fontist/fonts/RobotoMono-VariableFont_wght.ttf"
```

#### Help

List of all commands could be seen by:

```
fontist help
```

### Configuration

By default Fontist uses the `~/.fontist` directory to store fonts and its
files. It could be changed with the `FONTIST_PATH` environment variable.

```sh
FONTIST_PATH=~/.fontist_new fontist update
```

## Development

We are following Sandi Metz's Rules for this gem, you can read the
[description of the rules here][sandi-metz] All new code should follow these
rules. If you make changes in a pre-existing file that violates these rules you
should fix the violations as part of your contribution.

### Setup

Clone the repository.

```sh
git clone https://github.com/fontist/fontist
```

Setup your environment.

```sh
bin/setup
```

Run the test suite

```sh
bin/rspec
```

### Formulas storage

All formulas are kept in the [formulas][fontist-formulas] repository. If you'd
like to add a new one or change any existing, please refer to its documentation.

### Auto-generate a formula

A formula could be generated from a fonts archive. Just specify a URL to the
archive:

```sh
fontist create-formula https://www.latofonts.com/download/lato2ofl-zip/
cp lato.yml ~/.fontist/formulas/Formulas/
```

A formula index should be rebuild, when a new formula is generated or an
existing one changed:

```sh
fontist rebuild-index
```

Then, both the formula and the updated index should be commited and pushed to
the formula repository:

```sh
cd ~/.fontist/formulas
git add Formulas/lato.yml
git add index.yml
git commit -m "Add Lato formula"
```

### Google Import

The library contains formulas for [Google Foonts][google-fonts]. A GHA workflow
checks for fonts update every day. In case an update is found, it could be
fetched to the library by:

```
bin/import_google
```

The script would update formulas which should be committed to a separate
repository [formulas][fontist-formulas]:

```
cd ~/.fontist/formulas
git add Formulas/google
git commit -m "Google Fonts update"
git push
```

### Import of SIL fonts

Fontist contains formulas of [SIL fonts](https://software.sil.org/fonts/). They
can be updated with:

```sh
fontist import-sil
cd ~/.fontist/formulas
git add Formulas/sil
git add index.yml
git commit -m "SIL fonts update"
git push
```

### Releasing

Releasing is done automatically with GitHub Action. Just bump and tag with `gem-release`.

For a patch release (0.0.x) use:

```sh
gem bump --version patch --tag --push
```

For a minor release (0.x.0) use:

```sh
gem bump --version minor --tag --push
```

## Contributing

First, thank you for contributing! We love pull requests from everyone. By
participating in this project, you hereby grant [Ribose Inc.][riboseinc] the
right to grant or transfer an unlimited number of non exclusive licenses or
sub-licenses to third parties, under the copyright covering the contribution
to use the contribution by all means.

Here are a few technical guidelines to follow:

1. Open an [issue][issues] to discuss a new feature.
1. Write tests to support your new feature.
1. Make sure the entire test suite passes locally and on CI.
1. Open a Pull Request.
1. [Squash your commits][squash] after receiving feedback.
1. Party!


## Credit

This gem is developed, maintained and funded by [Ribose Inc.][riboseinc]

[riboseinc]: https://www.ribose.com
[issues]: https://github.com/fontist/fontist/issues
[squash]: https://github.com/thoughtbot/guides/tree/master/protocol/git#write-a-feature
[sandi-metz]: http://robots.thoughtbot.com/post/50655960596/sandi-metz-rules-for-developers
[fontist-formulas]: https://github.com/fontist/formulas
[google-fonts]: https://fonts.google.com
