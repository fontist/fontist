---
title: Fontist::Errors
---

# Fontist::Errors

Fontist raises specific errors for various failure conditions. Understanding these errors helps you handle exceptions gracefully in your applications.

## Overview

All Fontist errors inherit from `Fontist::Errors::FontistError`, which is the base error class.

## Error Classes

### `Fontist::Errors::FontistError`

The base error class for all Fontist errors.

**Inherits from:** `StandardError`

**Usage:**

```ruby
begin
  Fontist::Font.find("NonExistent")
rescue Fontist::Errors::FontistError => e
  puts "Fontist error: #{e.message}"
end
```

---

### `Fontist::Errors::UnsupportedFontError`

Raised when a requested font is not supported by Fontist.

**When raised:**
- Font name is not found in any formula
- Font is not available for installation

**Example:**

```ruby
begin
  Fontist::Font.install("Unknown Font")
rescue Fontist::Errors::UnsupportedFontError => e
  puts "Font not supported: #{e.message}"
end
```

---

### `Fontist::Errors::MissingFontError`

Raised when a required font is not installed on the system.

**When raised:**
- Font is supported but not installed
- Font files are missing or corrupted

**Example:**

```ruby
begin
  Fontist::Font.find("Supported But Not Installed")
rescue Fontist::Errors::MissingFontError => e
  puts "Font needs to be installed: #{e.message}"
end
```

---

### `Fontist::Errors::LicensingError`

Raised when there is an issue with font licensing.

**When raised:**
- Font requires license confirmation but none provided
- License terms are not accepted

**Example:**

```ruby
begin
  Fontist::Font.install("Licensed Font", confirmation: "no")
rescue Fontist::Errors::LicensingError => e
  puts "License issue: #{e.message}"
  # Prompt user for license acceptance
  Fontist::Font.install("Licensed Font", confirmation: "yes")
end
```

---

### `Fontist::Errors::DownloadError`

Raised when font download fails.

**When raised:**
- Network connection issues
- Source URL is unavailable
- Downloaded file is corrupted

**Example:**

```ruby
begin
  Fontist::Font.install("Some Font")
rescue Fontist::Errors::DownloadError => e
  puts "Download failed: #{e.message}"
  # Retry or use alternative source
end
```

---

### `Fontist::Errors::InstallationError`

Raised when font installation fails.

**When raised:**
- Insufficient disk space
- Permission denied
- Archive extraction fails

**Example:**

```ruby
begin
  Fontist::Font.install("Some Font")
rescue Fontist::Errors::InstallationError => e
  puts "Installation failed: #{e.message}"
end
```

---

### `Fontist::Errors::FormulaNotFoundError`

Raised when a formula cannot be found.

**When raised:**
- Formula file is missing
- Formula registry is corrupted

**Example:**

```ruby
begin
  Fontist::Formula.find("Unknown")
rescue Fontist::Errors::FormulaNotFoundError => e
  puts "Formula not found: #{e.message}"
end
```

## Error Handling Best Practices

### Catching Specific Errors

```ruby
begin
  Fontist::Font.install("Calibri", confirmation: "yes")
rescue Fontist::Errors::UnsupportedFontError
  puts "This font is not supported"
rescue Fontist::Errors::LicensingError
  puts "License acceptance required"
rescue Fontist::Errors::DownloadError
  puts "Failed to download font"
rescue Fontist::Errors::InstallationError
  puts "Failed to install font"
end
```

### Catching All Fontist Errors

```ruby
begin
  Fontist::Font.install("Calibri", confirmation: "yes")
rescue Fontist::Errors::FontistError => e
  puts "Fontist operation failed: #{e.message}"
end
```

### Checking Font Availability

```ruby
# Check if font is supported before installing
begin
  Fontist::Font.find("Open Sans")
rescue Fontist::Errors::UnsupportedFontError
  puts "Font not supported by Fontist"
end
```

## Error Class Hierarchy

```
StandardError
└── Fontist::Errors::FontistError
    ├── UnsupportedFontError
    ├── MissingFontError
    ├── LicensingError
    ├── DownloadError
    ├── InstallationError
    └── FormulaNotFoundError
```

## See Also

- [Fontist::Font](/api/font) — Font installation and lookup
- [Exit Codes](/cli/exit-codes) — CLI exit codes for errors
