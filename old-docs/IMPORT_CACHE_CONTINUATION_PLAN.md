# Import Cache Enhancement - Continuation Plan

## Overview

This document outlines the remaining work to complete the import cache enhancement feature. The core functionality has been implemented - imports now use a separate cache (`~/.fontist/import_cache`) instead of the user download cache (`~/.fontist/downloads`). This plan covers the remaining CLI arguments, verbose output enhancements, and cache management commands.

## Current Status

### Completed ✓
1. Separate import cache implementation (`Fontist.import_cache_path`)
2. Cache class accepts `cache_path` parameter
3. Downloader accepts `cache_path` parameter
4. Formula imports use import cache via `CreateFormula`
5. Basic verbose output shows import cache location
6. Error handling for malformed formulas during index rebuild
7. Formula naming uses FontFamilyName from plist (not style name)
8. Removed vacant_path logic (formulas always overwrite)
9. Verbose mode only shows component files when requested

### Remaining Work

## Phase 1: CLI Argument Support

### 1.1 Add `--import-cache` Option to Import Commands

**Files to modify:**
- `lib/fontist/import_cli.rb`

**Changes needed:**
```ruby
# Add to each import command (macos, google, sil):
option :import_cache,
       type: :string,
       desc: "Directory for import cache (default: ~/.fontist/import_cache)"
```

**Pass to importers:**
- `Import::Macos.new(..., import_cache: options[:import_cache])`
- `Import::GoogleFontsImporter.new(..., import_cache: options[:import_cache])`
- `Import::SilImport.new(..., import_cache: options[:import_cache])`

### 1.2 Update Importer Classes

**Files to modify:**
- `lib/fontist/import/macos.rb`
- `lib/fontist/import/google_fonts_importer.rb`
- `lib/fontist/import/sil_import.rb`

**Changes needed:**
- Accept `import_cache:` parameter in `initialize`
- Store as instance variable `@import_cache`
- Pass to `CreateFormula.new(..., import_cache: @import_cache)`

### 1.3 Update CreateFormula

**Files to modify:**
- `lib/fontist/import/create_formula.rb`

**Changes needed:**
- Accept `import_cache:` parameter in options
- Use `@options[:import_cache]` if provided, otherwise `Fontist.import_cache_path`
- Pass to downloader: `cache_path: @options[:import_cache] || Fontist.import_cache_path`

## Phase 2: Enhanced Verbose Output

### 2.1 Download Location Display

**Files to modify:**
- `lib/fontist/utils/downloader.rb`

**Changes needed:**
```ruby
def print_download_start
  Fontist.ui.say("Downloading from: #{Paint[url, :cyan]}")
  if @verbose
    Fontist.ui.say("  Cache location: #{Paint[@cache.cache_path, :black, :bright]}")
  end
end
```

### 2.2 Extraction Location Display

**Files to modify:**
- `lib/fontist/import/recursive_extraction.rb`

**Changes needed:**
```ruby
def extract_data(archive)
  extraction_dir = nil
  Excavate::Archive.new(path(archive)).files(recursive_packages: true) do |path|
    extraction_dir ||= File.dirname(path)
    if @verbose && extraction_dir == File.dirname(path)
      Fontist.ui.say("  Extracting to: #{Paint[extraction_dir, :black, :bright]}")
      extraction_dir = false # Only print once
    end
    # ... rest of method
  end
end
```

### 2.3 Cache Clear Notification

**Files to modify:**
- `lib/fontist/import/create_formula.rb` or `lib/fontist/import/recursive_extraction.rb`

**Changes needed:**
After extraction completes, if verbose:
```ruby
Fontist.ui.say("  Extraction cache cleared") if @verbose
```

## Phase 3: Cache Management Commands

### 3.1 Add Cache CLI

**Files to create/modify:**
- Update `lib/fontist/cache_cli.rb` (or create if doesn't exist)

**Implementation:**
```ruby
module Fontist
  class CacheCLI < Thor
    desc "clear", "Clear font download cache"
    def clear
      # Existing implementation for user download cache
    end

    desc "clear-import", "Clear import cache"
    option :verbose, type: :boolean, aliases: :v
    def clear_import
      cache_path = Fontist.import_cache_path

      if Dir.exist?(cache_path)
        size = calculate_size(cache_path)
        FileUtils.rm_rf(cache_path)
        Fontist.ui.success("Import cache cleared: #{format_size(size)}")
      else
        Fontist.ui.say("Import cache is already empty")
      end
    end

    desc "info", "Show cache information"
    def info
      download_cache = cache_info(Fontist.downloads_path)
      import_cache = cache_info(Fontist.import_cache_path)

      Fontist.ui.say("Font download cache:")
      Fontist.ui.say("  Location: #{Fontist.downloads_path}")
      Fontist.ui.say("  Size: #{format_size(download_cache[:size])}")
      Fontist.ui.say("  Files: #{download_cache[:files]}")

      Fontist.ui.say("\nImport cache:")
      Fontist.ui.say("  Location: #{Fontist.import_cache_path}")
      Fontist.ui.say("  Size: #{format_size(import_cache[:size])}")
      Fontist.ui.say("  Files: #{import_cache[:files]}")
    end

    private

    def cache_info(path)
      return { size: 0, files: 0 } unless Dir.exist?(path)

      files = Dir.glob(File.join(path, "**", "*")).select { |f| File.file?(f) }
      size = files.sum { |f| File.size(f) }

      { size: size, files: files.count }
    end

    def calculate_size(path)
      # Similar to cache_info
    end

    def format_size(bytes)
      # Format bytes to human-readable
    end
  end
end
```

### 3.2 Register Cache CLI

**Files to modify:**
- `lib/fontist/cli.rb`

**Changes needed:**
```ruby
desc "cache SUBCOMMAND", "Manage cache"
subcommand "cache", CacheCLI
```

## Phase 4: Ruby API Support

### 4.1 Update Fontist Module

**Files to modify:**
- `lib/fontist.rb`

**Changes needed:**
```ruby
def self.import_cache_path=(path)
  @import_cache_path = Pathname.new(path) if path
end

def self.import_cache_path
  @import_cache_path ||
    (ENV["FONTIST_IMPORT_CACHE"] ? Pathname.new(ENV["FONTIST_IMPORT_CACHE"]) : nil) ||
    fontist_path.join("import_cache")
end
```

### 4.2 API Usage Example

```ruby
# Set custom import cache
Fontist.import_cache_path = "/custom/import/cache"

# Import with custom cache
Fontist::Import::Macos.new(
  plist_path,
  import_cache: "/another/cache/path"
).call
```

## Phase 5: Documentation

### 5.1 Update README.adoc

**Section to add: Import Cache Management**

```adoc
== Import Cache Management

Fontist uses two separate caches:

* *Download cache* (`~/.fontist/downloads`): Font files downloaded by end users via `fontist install`
* *Import cache* (`~/.fontist/import_cache`): Font archives downloaded during formula building

=== Configuring Import Cache

==== CLI Option

[source,bash]
----
fontist import macos --import-cache /custom/path ...
fontist import google --import-cache /custom/path ...
fontist import sil --import-cache /custom/path ...
----

==== Ruby API

[source,ruby]
----
# Global setting
Fontist.import_cache_path = "/custom/import/cache"

# Per-import setting
Fontist::Import::Macos.new(
  plist_path,
  import_cache: "/custom/cache"
).call
----

==== Environment Variable

[source,bash]
----
export FONTIST_IMPORT_CACHE=/custom/import/cache
fontist import macos ...
----

=== Cache Management Commands

==== View Cache Information

[source,bash]
----
fontist cache info
----

==== Clear Import Cache

[source,bash]
----
fontist cache clear-import
----

==== Clear Download Cache

[source,bash]
----
fontist cache clear
----

=== Verbose Mode

Use `--verbose` to see detailed cache operations:

[source,bash]
----
fontist import macos --plist catalog.xml --verbose
----

Output includes:
* Import cache location
* Download URLs and cache status
* Extraction directory locations
* Cache cleanup notifications
```

### 5.2 Create Import Guide

**File to create:** `docs/guide/import.md`

Document:
- Import process overview
- Cache management
- Troubleshooting common issues
- Performance tips

## Phase 6: Testing

### 6.1 Unit Tests

**Files to create/modify:**
- `spec/fontist/cache_cli_spec.rb`
- `spec/fontist/import/macos_spec.rb` (update for import_cache param)
- `spec/fontist/utils/cache_spec.rb` (update for cache_path param)

### 6.2 Integration Tests

Test scenarios:
1. Import with default cache
2. Import with custom CLI cache
3. Import with custom API cache
4. Import with ENV var cache
5. Cache clear operations
6. Cache info display

## Implementation Order

1. **Phase 1**: CLI arguments (enables testing)
2. **Phase 2**: Verbose output (improves debugging)
3. **Phase 3**: Cache commands (completes feature)
4. **Phase 4**: Ruby API (enables programmatic use)
5. **Phase 5**: Documentation (makes it usable)
6. **Phase 6**: Tests (ensures quality)

## Architecture Principles

### Separation of Concerns
- CLI handles argument parsing
- Importers handle business logic
- Cache handles storage
- Downloader handles network

### MECE Structure
Import cache configuration sources (in order of precedence):
1. API/CLI explicit parameter
2. Global `Fontist.import_cache_path=` setting
3. `FONTIST_IMPORT_CACHE` environment variable
4. Default: `~/.fontist/import_cache`

### Open/Closed Principle
- Cache class accepts any path
- Downloader doesn't know about import vs download cache
- Easy to add new cache types in future

## Success Criteria

- [ ] CLI `--import-cache` option works for all import commands
- [ ] Verbose mode shows all cache operations
- [ ] `fontist cache clear-import` clears import cache
- [ ] `fontist cache info` shows both caches
- [ ] Ruby API accepts import_cache parameter
- [ ] Environment variable respected
- [ ] Documentation complete and accurate
- [ ] All tests pass

## Estimated Effort

- Phase 1-2: 1-2 hours
- Phase 3: 1 hour
- Phase 4: 30 minutes
- Phase 5: 1 hour
- Phase 6: 2 hours

Total: ~6 hours