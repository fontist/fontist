---
title: Installation
---

# Installation

Fontist is distributed as a RubyGem and can be installed on macOS, Windows, and Linux.

## Prerequisites

- **Ruby 2.7 or higher** - Fontist requires a recent Ruby version
- **Git** - Used internally for fetching formulas and fonts

To check your Ruby version:

```sh
ruby --version
```

If you don't have Ruby installed, download it from the [official Ruby website](https://www.ruby-lang.org/en/downloads/).

## Install Fontist

Install the gem using RubyGems:

```sh
gem install fontist
```

Verify the installation:

```sh
fontist version
```

## Platform-Specific Notes

### macOS

macOS comes with Ruby pre-installed. If you encounter permission issues, consider using a Ruby version manager like [rbenv](https://github.com/rbenv/rbenv) or [asdf](https://github.com/asdf-vm/asdf).

### Windows

On Windows, we recommend using [RubyInstaller](https://rubyinstaller.org/) which includes the DevKit needed for native extensions.

### Linux

Most Linux distributions have Ruby available through their package managers:

```sh
# Debian/Ubuntu
sudo apt install ruby ruby-dev

# Fedora
sudo dnf install ruby ruby-devel

# Arch Linux
sudo pacman -S ruby
```

## CI/CD Environments

Fontist works great in CI environments. For GitHub Actions, use the [fontist/setup](https://github.com/fontist/setup) action:

```yaml
- uses: fontist/setup@v1
- run: fontist install "Fira Code"
```

See the [CI/CD Integration guide](/guide/ci) for more details.

## Troubleshooting

### Permission Errors

If you get permission errors during installation, you may need to use `sudo` (not recommended) or configure your Ruby environment to install gems in your user directory:

```sh
gem install fontist --user-install
```

### Native Extension Errors

Fontist uses native extensions for performance. If you see errors about failed compilations, ensure you have a C compiler and development headers installed:

```sh
# Debian/Ubuntu
sudo apt install build-essential ruby-dev

# Fedora
sudo dnf install gcc ruby-devel

# macOS (with Xcode Command Line Tools)
xcode-select --install
```

### Proxy Configuration

If you're behind a proxy, configure Git to use it:

```sh
git config --global http.proxy http://user:pass@proxyhost:port
```

See the [Proxy Configuration guide](/guide/proxy) for detailed instructions.
