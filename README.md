# Fontist

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

## Usage

### Find a font

The fontist library allows us to easily locate or download a any of the supported
fonts and then it returns the complete path for the path. To find any font in a
user's system we can use the following interface.

```ruby
Fontist::Finder.find("CALIBRI.TTF")
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
