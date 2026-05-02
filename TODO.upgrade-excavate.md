# TODO: Fix Excavate Memory Leaks and Upgrade Fontist

## Problem
Fontist CI tests pass but fail at the end with:
```
failed to allocate memory (NoMemoryError)
```

This happens after repeated archive extractions during test runs.

## Root Cause Analysis
Memory leaks in Excavate gem due to:
1. Temp directories not cleaned up on errors
2. Incorrect `ensure`/`rescue` order in `extract_and_replace` method

## Remaining Work

### 1. Fix Excavate Gem (in /Users/mulgogi/src/fontist/excavate)

#### archive.rb - Fix `extract_and_replace` method (lines 217-229)
Current broken code has `ensure` BEFORE `rescue` which is invalid Ruby syntax:
```ruby
def extract_and_replace(archive)
  target = Dir.mktmpdir
  extract_recursively(archive, target)
  replace_archive_with_contents(archive, target)
ensure                    # <-- WRONG: ensure must come AFTER rescue
  FileUtils.rm_rf(target)
rescue StandardError      # <-- This causes syntax error
  raise unless TYPES.key?(normalized_extension(archive))
end
```

Fix - swap order so `rescue` comes before `ensure`:
```ruby
def extract_and_replace(archive)
  target = Dir.mktmpdir
  extract_recursively(archive, target)
  replace_archive_with_contents(archive, target)
rescue StandardError
  raise unless TYPES.key?(normalized_extension(archive))
ensure
  FileUtils.rm_rf(target)
end
```

### 2. Run Excavate Tests
```bash
cd /Users/mulgogi/src/fontist/excavate
bundle exec rspec
```
All 65 tests should pass.

### 3. Bump Excavate Version
Edit `/Users/mulgogi/src/fontist/excavate/lib/excavate/version.rb`:
```ruby
VERSION = "1.0.3"
```

### 4. Commit and Push Excavate
```bash
cd /Users/mulgogi/src/fontist/excavate
git add -A
git commit -m "fix: prevent memory leaks by ensuring proper resource cleanup

- Fix extract_and_replace to use correct rescue/ensure order
- Add ensure block to extract_by_filter for temp dir cleanup"
git push origin main
```

### 5. Release Excavate Gem
```bash
cd /Users/mulgogi/src/fontist/excavate
# Tag and push to rubygems
git tag v1.0.3
git push --tags
gem build excavate.gemspec
gem push excavate-1.0.3.gem
```

### 6. Update Fontist to Use New Excavate
```bash
cd /Users/mulgogi/src/fontist/fontist
# Update Gemfile.lock to use excavate >= 1.0.3
bundle update excavate
```

### 7. Run Fontist Tests
```bash
cd /Users/mulgogi/src/fontist/fontist
bundle exec rspec
```
Tests should pass WITHOUT the `NoMemoryError` at the end.

### 8. Create PR and Merge
- Create PR in fontist repository
- Reference issue #451
- Merge after CI passes

## Files Modified

### Excavate
- `lib/excavate/archive.rb` - Fix `extract_and_replace` method

## Notes
- Do NOT add `ensure` blocks with `reader&.close` to extractors - the Omnizip readers don't have a `close` method
- The fix is simple: correct the `rescue`/`ensure` order in `extract_and_replace`
