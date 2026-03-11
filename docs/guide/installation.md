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

#### Windows Installation Steps

1. **Download RubyInstaller** from [rubyinstaller.org](https://rubyinstaller.org/downloads/)
   - Select the **"Ruby+Devkit"** version (not the plain Ruby version)
   - Example: `Ruby+Devkit 3.2.X (x64)`

2. **Run the installer**
   - Check "Add Ruby executables to your PATH"
   - Check "Associate .rb files with this Ruby installation"

3. **Set up MSYS2** (required for native extensions):
   ```powershell
   ridk install
   ```
   Select option **3** (MSYS2 and MINGW development toolchain) when prompted.

4. **Install Git for Windows** from [git-scm.com](https://git-scm.com/download/win)
   - Required for `fontist update` and `fontist repo` commands

5. **Verify installation**:
   ```powershell
   ruby --version
   gem install fontist
   fontist version
   ```

See the [Windows Platform Guide](/guide/platforms/windows) for Windows-specific considerations.

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

## Native Dependencies

Fontist depends on several gems with native C/C++ extensions. The following table shows what's required:

| Gem | Compiler | Purpose |
|-----|----------|---------|
| `json` | gcc | JSON parsing |
| `brotli` (via fontisan) | gcc | WOFF2 font decompression |
| `seven-zip` (via excavate) | g++ | 7z archive extraction |
| `libmspack` (via excavate) | gcc | CAB/CHM archive extraction |
| `ffi-libarchive-binary` (via excavate) | gcc | Archive extraction (zip, tar, etc.) |

::: note Prebuilt Binaries
Some gems like `nokogiri` and `ffi` provide prebuilt binaries for common platforms, so they typically don't require compilation.
:::

### Windows DevKit Setup

On Windows, native extensions require the RubyInstaller DevKit:

1. Download [RubyInstaller](https://rubyinstaller.org/downloads/) with DevKit (select "Ruby+Devkit" version)

2. Run the installer, checking "Add Ruby executables to your PATH"

3. After installation, run the following in a command prompt:

   ```cmd
   ridk install
   ```

4. Select option **3** (MSYS2 and MINGW development toolchain) when prompted

5. Install [Git for Windows](https://git-scm.com/download/win) for `fontist update` and `fontist repo` commands

### Proxy Configuration

If you're behind a proxy, configure Git to use it:

```sh
git config --global http.proxy http://user:pass@proxyhost:port
```

See the [Proxy Configuration guide](/guide/proxy) for detailed instructions.
