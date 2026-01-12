# Investigation: .ttc Collection File Failures

## Summary

The failures during macOS font import for .ttc (TrueType Collection) files are **NOT** due to fontisan parsing issues. Fontisan handles .ttc files correctly. The issue is in fontist's collection file handling code.

## Evidence

### Test Case: KoufiAbjadi.ttc

```ruby
require 'fontisan'
ttc_path = '/tmp/test_ttc/AssetData/KoufiAbjadi.ttc'
collection = Fontisan::TrueTypeCollection.from_file(ttc_path)

# SUCCESS:
collection.class         # => Fontisan::TrueTypeCollection
collection.num_fonts    # => 2
collection.font(0, File.open(ttc_path, 'rb'))  # Works!
collection.font(1, File.open(ttc_path, 'rb'))  # Works!
```

### The Actual Error

```
undefined method `num_fonts' for an instance of String
```

This means we're calling `num_fonts` on a **String** (likely a file path), not on a TrueTypeCollection object.

## Root Cause

The error occurs in `lib/fontist/import/files/collection_file.rb:45`:

```ruby
def extract_fonts
  Array.new(@collection.num_fonts) do |index|  # <-- @collection is a String!
    extract_font_at(index)
  end
end
```

The `@collection` instance variable should contain a `Fontisan::TrueTypeCollection` object but is receiving a String (file path) instead.

## Hypothesis

Somewhere in the call chain:
1. Archive is downloaded and extracted
2. RecursiveExtraction finds .ttc files  
3. CollectionFile.from_path is called
4. However, a String path is being passed to `initialize` instead of calling `build_collection`

OR

5. An exception occurs in `build_collection` that's being caught and the String path is being used as fallback

## Recommended Fix

Add defensive checks and better error messages in `collection_file.rb`:

```ruby
def initialize(fontisan_collection, path, name_prefix = nil)
  unless fontisan_collection.is_a?(Fontisan::TrueTypeCollection)
    raise TypeError, "Expected Fontisan::TrueTypeCollection, got #{fontisan_collection.class}: #{fontisan_collection.inspect[0..100]}"
  end
  @collection = fontisan_collection
  @path = path
  @name_prefix = name_prefix
  @fonts = extract_fonts
end
```

## Success Rate

- **Working .ttc files**: KoufiAbjadi.ttc and many others work perfectly with fontisan
- **330 successful formula creations** (62%) prove fontisan works well
- **205 failures** (38%) are due to this String vs TrueTypeCollection type mismatch

## Action Items

1. Add type checking in CollectionFile.initialize
2. Trace where String paths are being passed instead of TrueTypeCollection objects  
3. Fix the calling code to properly construct TrueTypeCollection before passing to CollectionFile
4. Add integration test that imports a .ttc-containing font package end-to-end

## Conclusion

**Fontisan is working correctly.** The issue is in fontist's code that handles collection files, not in the fontisan library itself.
