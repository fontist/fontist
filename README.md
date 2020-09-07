# Fontist

![windows](https://github.com/fontist/fontist/workflows/windows/badge.svg)
![macos](https://github.com/fontist/fontist/workflows/macos/badge.svg)
![ubuntu](https://github.com/fontist/fontist/workflows/ubuntu/badge.svg)

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

## Usage

### Font

The `Fontist::Font` is your go to place to deal with any font using fontist. This
interface will allow you to find a font or install a font. Lets start with how
can we find a font in your system.

#### Finding a font

The `Fontist::Fontist.find` interface can be used a find a font in your system.
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
example the `Calibri` font might contains a `regular`, `bola` or `italic` styles
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
cd ~/.fontist/formulas
git add Formulas/lato.yml
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

### TTC extraction

The stripttc script is used for extraction of TTC files. It's taken from the
https://github.com/DavidBarts/getfonts repository, and placed in the bin/
directory.

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
