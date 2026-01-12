# Import UI Unification - Implementation Plan

## Overview

Unify the import UI across Google, SIL, and macOS importers to provide a consistent, polished user experience with shared display components.

## Current State

### macOS Importer (Reference Implementation)
- ✅ Paint-colored headers with Unicode box characters
- ✅ Emoji indicators for status (✓, ✗, ⊝, ⚠, ℹ, 💡, 🎉, 👍)
- ✅ Detailed progress tracking with percentages
- ✅ Rich summary with statistics
- ✅ Status-specific messaging (force mode, skip mode)
- ✅ Import cache location display in verbose mode

### Google/SIL Importers (Current)
- ⚠️ Basic ImportDisplay module with simple formatting
- ⚠️ Plain "=" dividers instead of Paint Unicode
- ⚠️ Basic emoji support
- ⚠️ Simple progress bar
- ⚠️ Less detailed summary

## Architecture

### Shared Display Module: `ImportDisplay`

Enhance the existing `ImportDisplay` module with Paint-based rendering matching macOS style.

#### Core Components

```
ImportDisplay
├── Header Display
│   ├── print_header(source, details)
│   └── print_info_line(key, value)
├── Progress Display
│   ├── print_progress(current, total, item)
│   └── print_status(emoji, message, details)
├── Summary Display
│   ├── print_summary_header
│   ├── print_summary_stats(results)
│   ├── print_summary_tips(results)
│   └── print_summary_footer(results)
└── Utilities
    ├── format_duration(seconds)
    ├── format_bytes(bytes)
    └── format_percentage(count, total)
```

### Display Styles (MECE)

1. **Header**: Cyan with Unicode box characters (`═`)
2. **Progress**: White progress, yellow percentage, cyan item name
3. **Success**: Green checkmark (✓) with green text
4. **Failure**: Red X (✗) with red text
5. **Skip**: Yellow omit (⊝) with yellow text
6. **Warning**: Yellow warning (⚠) with yellow text
7. **Info**: Blue info (ℹ) with cyan text
8. **Tip**: Cyan light bulb (💡) with cyan text

## Implementation Plan

### Phase 1: Enhance ImportDisplay Module

#### 1.1 Add Paint-Based Header

**File:** `lib/fontist/import/import_display.rb`

**Changes:**
```ruby
def self.header(source, details = {}, import_cache: nil)
  Fontist.ui.say("")
  Fontist.ui.say(Paint["═" * 80, :cyan])
  Fontist.ui.say(Paint["  📦 #{source} Import", :cyan, :bright])
  Fontist.ui.say(Paint["═" * 80, :cyan])
  Fontist.ui.say("")

  # Show import cache if provided
  if import_cache
    Fontist.ui.say("📦 Import cache: #{Paint[import_cache, :white]}")
  end

  # Show other details
  details.each do |key, value|
    label = key.to_s.split('_').map(&:capitalize).join(' ')
    Fontist.ui.say("📁 #{label}: #{Paint[value, :white]}")
  end

  Fontist.ui.say("")
end
```

#### 1.2 Add Paint-Based Progress

**Changes:**
```ruby
def self.progress(current, total, item, status: nil)
  progress_text = "(#{current}/#{total})"
  percentage = ((current.to_f / total) * 100).round(1)

  line = "#{Paint[progress_text, :white]} " \
         "#{Paint["#{percentage}%", :yellow]} | " \
         "#{Paint[item, :cyan, :bright]}"

  line += " #{status}" if status

  Fontist.ui.say(line)
end
```

#### 1.3 Add Status Methods

**New methods:**
```ruby
def self.status_success(message, details = "")
  Fontist.ui.say("  #{Paint['✓', :green]} #{Paint[message, :white]} #{Paint[details, :black, :bright]}")
end

def self.status_skipped(message, tip = nil)
  Fontist.ui.say("  #{Paint['⊝', :yellow]} #{message}")
  Fontist.ui.say("    #{Paint['ℹ', :blue]} #{tip}") if tip
end

def self.status_failed(message)
  error_display = message.length > 60 ? "#{message[0..60]}..." : message
  Fontist.ui.say("  #{Paint['✗', :red]} Failed: #{Paint[error_display, :red]}")
end

def self.status_overwrite(message)
  Fontist.ui.say("  #{Paint['⚠', :yellow]} #{message}")
end
```

#### 1.4 Add Paint-Based Summary

**Changes:**
```ruby
def self.summary(results, options = {})
  print_summary_header
  print_summary_stats(results)
  print_summary_tips(results, options)
  print_summary_footer(results)
end

private

def self.print_summary_header
  Fontist.ui.say("")
  Fontist.ui.say(Paint["═" * 80, :cyan])
  Fontist.ui.say(Paint["  📊 Import Summary", :cyan, :bright])
  Fontist.ui.say(Paint["═" * 80, :cyan])
  Fontist.ui.say("")
end

def self.print_summary_stats(results)
  total = results[:total] || (results[:successful] + results[:failed])
  success_rate = (results[:successful].to_f / total * 100).round(1)

  Fontist.ui.say("  Total packages:     #{Paint[total.to_s, :white]}")
  Fontist.ui.say("  #{Paint['✓', :green]} Successful:     #{Paint[results[:successful].to_s, :green, :bright]} #{Paint["(#{success_rate}%)", :green]}")

  if results[:skipped] && results[:skipped] > 0
    skip_rate = (results[:skipped].to_f / total * 100).round(1)
    Fontist.ui.say("  #{Paint['⊝', :yellow]} Skipped:        #{Paint[results[:skipped].to_s, :yellow]} #{Paint["(#{skip_rate}%)", :yellow]}")
  end

  if results[:failed] > 0
    Fontist.ui.say("  #{Paint['✗', :red]} Failed:         #{Paint[results[:failed].to_s, :red]}")
  end

  Fontist.ui.say("")
end

def self.print_summary_footer(results)
  total = results[:total] || (results[:successful] + results[:failed])

  if results[:successful] > (total * 0.5)
    Fontist.ui.say(Paint["  🎉 Great success! #{results[:successful]} formulas created!", :green, :bright])
  elsif results[:successful] > 0
    Fontist.ui.say(Paint["  👍 Keep going! #{results[:successful]} formulas created.", :yellow, :bright])
  end

  Fontist.ui.say("")
end
```

### Phase 2: Extract macOS Display Logic

#### 2.1 Create ImportProgressTracker

**File:** `lib/fontist/import/import_progress_tracker.rb`

**Purpose:** Track import progress and statistics

**Implementation:**
```ruby
module Fontist
  module Import
    class ImportProgressTracker
      attr_reader :success_count, :failure_count, :skipped_count, :overwritten_count

      def initialize
        @success_count = 0
        @failure_count = 0
        @skipped_count = 0
        @overwritten_count = 0
        @errors = []
      end

      def record_success
        @success_count += 1
      end

      def record_failure(error)
        @failure_count += 1
        @errors << error
      end

      def record_skip
        @skipped_count += 1
      end

      def record_overwrite
        @overwritten_count += 1
      end

      def results
        {
          successful: @success_count,
          failed: @failure_count,
          skipped: @skipped_count,
          overwritten: @overwritten_count,
          errors: @errors
        }
      end
    end
  end
end
```

### Phase 3: Migrate SIL Importer

#### 3.1 Update SilImport to Use Enhanced Display

**File:** `lib/fontist/import/sil_import.rb`

**Changes:**
1. Add `@tracker = ImportProgressTracker.new`
2. Use `ImportDisplay.header` with import_cache
3. Use `ImportDisplay.progress` for each font
4. Use `ImportDisplay.status_*` methods for outcomes
5. Use `ImportDisplay.summary` with tracker results

**Example:**
```ruby
def call
  start_time = Time.now
  @tracker = ImportProgressTracker.new

  ImportDisplay.header("SIL International Fonts",
                       { output_path: formula_dir },
                       import_cache: @import_cache || Fontist.import_cache_path)

  links = font_links
  # ... filtering ...

  links.each_with_index do |link, index|
    ImportDisplay.progress(index + 1, links.size, link.content)

    result = process_font(link)
    case result
    when :success
      @tracker.record_success
      ImportDisplay.status_success("Formula created", "#{link.content}.yml")
    when :skip
      @tracker.record_skip
      ImportDisplay.status_skipped("Already exists", "Use --force to overwrite")
    else
      @tracker.record_failure(result)
      ImportDisplay.status_failed(result[:error])
    end
  end

  ImportDisplay.summary(@tracker.results.merge(duration: Time.now - start_time))
end
```

### Phase 4: Migrate Google Importer

#### 4.1 Update GoogleFontsImporter

**File:** `lib/fontist/import/google_fonts_importer.rb`

**Changes:** Similar to SIL, using the unified ImportDisplay

### Phase 5: Clean Up

#### 5.1 Remove Deprecated Display Code

- Remove old progress display logic from SilImport
- Remove old display logic from GoogleFontsImporter
- Keep only ImportDisplay for all formatting

#### 5.2 Update Documentation

**File:** `docs/guide/import.md` (create if doesn't exist)

Document the unified import UI experience.

## Success Criteria

- [ ] All three import commands (macos, google, sil) use identical UI styling
- [ ] Paint-colored output throughout
- [ ] Consistent emoji usage
- [ ] Shared ImportDisplay module for all rendering
- [ ] Import cache location shown in verbose mode for all commands
- [ ] Progress tracking with percentages
- [ ] Rich summaries with success rates
- [ ] No code duplication across importers
- [ ] All tests pass

## Files to Modify

**Core Display:**
- `lib/fontist/import/import_display.rb` - Enhance with Paint

**New Files:**
- `lib/fontist/import/import_progress_tracker.rb` - Shared tracker

**Importers:**
- `lib/fontist/import/sil_import.rb` - Migrate to unified UI
- `lib/fontist/import/google_fonts_importer.rb` - Migrate to unified UI
- `lib/fontist/import/macos.rb` - Extract shared logic to ImportDisplay

## Implementation Order

1. Phase 1: Enhance ImportDisplay with Paint (Foundation)
2. Phase 2: Create ImportProgressTracker (Shared state)
3. Phase 3: Migrate SIL importer (Validation)
4. Phase 4: Migrate Google importer (Completion)
5. Phase 5: Clean up and document (Polish)

## Estimated Effort

- Phase 1: 1-2 hours (Core display module)
- Phase 2: 30 minutes (Progress tracker)
- Phase 3: 1 hour (SIL migration)
- Phase 4: 1 hour (Google migration)
- Phase 5: 30 minutes (Cleanup)

Total: ~4-5 hours

## Benefits

1. **Consistency**: All import commands look and feel the same
2. **Maintainability**: Display logic in one place
3. **User Experience**: Professional, colorful output
4. **Debugging**: Verbose mode consistent across all importers
5. **Code Reuse**: DRY principle applied

## Design Principles

### MECE Structure
Display responsibility layers:
1. **ImportDisplay**: Rendering (how to display)
2. **ImportProgressTracker**: State (what to display)
3. **Importers**: Business logic (what happened)

### Separation of Concerns
- Importers handle: Download, parse, create formula
- Tracker handles: Count successes/failures
- Display handles: Format and output

### Open/Closed Principle
- ImportDisplay methods are extensible
- New import sources can use same display
- Easy to add new status types or formatting