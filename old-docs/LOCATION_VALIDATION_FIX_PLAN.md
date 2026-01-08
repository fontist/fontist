# Location Validation Architecture Fix

## Problem

Currently validation logic is duplicated in two places:
- [`Font#parse_location`](lib/fontist/font.rb:395) - validates and converts
- [`InstallLocation#parse_location_type`](lib/fontist/install_location.rb:105) - validates and converts

This violates DRY and single responsibility principles.

## Correct Architecture

**Single Responsibility**: ALL validation should be in `InstallLocation`

**Flow**:
```
CLI (--location=user)
  ↓
Font.install(name, install_location: "user")
  ↓ (pass through, no validation)
FontInstaller.new(formula, location: "user")
  ↓ (pass through, no validation)
InstallLocation.new(formula, location_type: "user")
  ↓ (VALIDATE HERE - single source of truth)
parse_location_type("user") → :user
```

## Required Changes

### 1. CLI Option Name
**File**: `lib/fontist/cli.rb`

Change `--install_location` to `--location`:
```ruby
option :location,
       type: :string,
       enum: ["fontist", "user", "system"],
       desc: "Install location: fontist (default), user, system"
```

**Why**: Shorter, clearer, follows CLI conventions

### 2. Remove Duplicate Validation from Font
**File**: `lib/fontist/font.rb`

Remove `parse_location` method (lines 395-409) completely.

Change line 21 from:
```ruby
@install_location = parse_location(options[:install_location])
```

To:
```ruby
@install_location = options[:location] || options[:install_location]
```

**Why**: 
- Font class should not validate
- Just pass through to InstallLocation
- Support both `:location` (new) and `:install_location` (backward compat)

### 3. InstallLocation Does All Validation
**File**: `lib/fontist/install_location.rb`

Keep existing `parse_location_type` method as-is.

This is the SINGLE source of truth for validation.

### 4. Add Validation Tests
**File**: `spec/fontist/install_location_spec.rb`

Add comprehensive validation tests:
```ruby
describe "#parse_location_type" do
  context "valid locations" do
    it "accepts :fontist"
    it "accepts 'user'"
    it "accepts :system"
  end
  
  context "invalid locations" do
    it "rejects :invalid with error"
    it "rejects '/custom/path' with error"
    it "shows helpful error message"
    it "falls back to :fontist"
  end
end
```

## Implementation Order

1. ✅ Update CLI option name: `install_location` → `location`
2. ✅ Remove `Font#parse_location` method
3. ✅ Update `Font#initialize` to accept both option names
4. ✅ Add validation tests to `install_location_spec.rb`
5. ✅ Add CLI integration tests to `cli_spec.rb`
6. ✅ Run test suite and fix any issues

## Benefits

- **DRY**: Validation in ONE place only
- **Single Responsibility**: InstallLocation owns validation
- **Clarity**: Clear separation of concerns
- **Maintainability**: Changes to validation logic happen in one place
- **Testability**: Easier to test validation comprehensively