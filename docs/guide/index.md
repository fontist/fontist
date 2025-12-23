# Getting started

The easiest way to get started with Fontist is to install the Fontist CLI. There's also a [fontist RubyGem package](/guide/api-ruby) that you can use from your Ruby code.

```sh
gem install fontist
```

💎 Don't have Ruby installed? You can [download Ruby from the official Ruby website](https://www.ruby-lang.org/en/downloads/).

Now you're ready to start using Fontist to install fonts on your machine! 🤩

```sh
fontist install "Fira Code"
fontist install "Open Sans"
fontist install "Consolas"
```

<sup>👩‍⚖️ Some fonts may require you to accept license terms regarding their use.</sup>

## Using a Fontist manifest

Several fonts can be specified in a file, called "manifest", and installed together.

First, prepare a file "manifest.yml":

```yaml
---
Times New Roman:
Arial:
Courier New:
---
```

Then run:

```sh
fontist manifest install manifest.yml
```

```
---
Arial:
  Regular:
    full_name: Arial
    paths:
    - "/home/octocat/.fontist/fonts/Arial.ttf"
  Bold Italic:
    ...
```

💡 You can use `fontist manifest locations` to get the installation paths of **only the fonts listed in the manifest file**.

```sh
fontist manifest locations manifest.yml
```

```
---
Arial:
  Regular:
    full_name: Arial
    paths:
    - "/home/octocat/.fontist/fonts/Arial.ttf"
  Bold Italic:
    ...
```
