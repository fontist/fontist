# Formula Resource `provides` Architecture

## Problem Statement

### Current Limitations

The current Formula Resource model has several architectural limitations:

1. **Implicit Style Provision**: Resources don't explicitly declare what font styles they provide. The system must infer this through filename matching, which is fragile and error-prone.

2. **Filename-Based Matching**: Font style matching relies on filename patterns rather than actual font metadata (PostScript names, full names). This breaks when:
   - Filenames don't follow conventions
   - Archives contain differently named files
   - Collections contain multiple fonts in one file

3. **Format Confusion**: The `format` attribute is at the Resource level, but logically belongs to each provided style. This creates problems:
   - A resource providing multiple styles must assume all are the same format
   - Different formats for the same style (TTF vs WOFF2) require separate resources
   - No clear separation between "resource format" (zip, pkg) and "font format" (ttf, otf)

4. **Variable Font Support**: Variable fonts with multiple axes aren't well-represented. The current model doesn't clearly express which styles a variable font can produce.

5. **Archive Ambiguity**: When a resource is an archive (zip, pkg), there's no explicit mapping between the archive and the fonts it contains.

### Impact

These limitations make it difficult to:
- Generate accurate formulas from external data sources (Google Fonts API)
- Support multiple formats for the same font style
- Handle font collections (TTC files)
- Match fonts reliably across different sources
- Maintain formulas as font distributions evolve

## Proposed Solution

### Core Concept

Add a `provides` attribute to the Resource model that explicitly declares:
- What font styles this resource provides (by PostScript name)
- What format each provided style is in
- Where to find each style within the resource (filename)

### Key Design Principles

1. **Explicit over Implicit**: Resources declare what they provide rather than relying on inference
2. **Metadata-Based Matching**: Use PostScript names (the canonical font identifier) for matching
3. **Format per Style**: Each provided style has its own format specification
4. **Optimization Hints**: Include filename as an optimization hint, not a requirement

## Resource Model Changes

### New `ProvidesInfo` Model

```ruby
class ProvidesInfo < Lutaml::Model::Serializable
  attribute :postscript_name, :string
  attribute :filename, :string
  attribute :format, :string  # ttf, woff2, otf, ttc, etc.
  attribute :full_name, :string  # Optional, for human readability
end
```

**Fields:**

- `postscript_name` (required): The PostScript name of the font style. This is the canonical identifier used for matching (e.g., "ABeeZee-Regular", "Roboto-Bold").
- `filename` (required): The filename within the resource containing this style. For direct download resources, this is the downloaded filename. For archives, this is the path within the archive.
- `format` (required): The font file format (ttf, otf, woff2, ttc, etc.). This is the format of the actual font file, not the resource container.
- `full_name` (optional): The human-readable full name of the font (e.g., "ABee Zee Regular"). Useful for debugging and formula readability.

### Updated `Resource` Model

```ruby
class Resource < Lutaml::Model::Serializable
  attribute :name, :string
  attribute :urls, :string, collection: true
  attribute :sha256, :string
  attribute :file_size, :integer
  attribute :variable_axes, :string, collection: true
  attribute :provides, ProvidesInfo, collection: true  # NEW
end
```

**Changes:**

- Added `provides` attribute: A collection of `ProvidesInfo` objects describing what this resource provides
- `format` attribute removed: Now specified per provided style in `provides`
- `variable_axes` retained: Describes axes for variable fonts (applies to entire resource)

## Formula Structure Examples

### Example 1: Static Font with Multiple Formats (ABeeZee)

```yaml
fonts:
- name: ABeeZee
  styles:
  - family_name: ABeeZee
    type: Regular
    postscript_name: ABeeZee-Regular
    full_name: ABee Zee Regular
  - family_name: ABeeZee
    type: Italic
    postscript_name: ABeeZee-Italic
    full_name: ABee Zee Italic

resources:
  # TTF Format Resources
  - name: ABeeZee-Regular.ttf
    urls:
    - https://fonts.gstatic.com/s/abeezee/v22/ABeeZee-Regular.ttf
    sha256: abc123...
    file_size: 45678
    provides:
    - postscript_name: ABeeZee-Regular
      filename: ABeeZee-Regular.ttf
      format: ttf
      full_name: ABee Zee Regular

  - name: ABeeZee-Italic.ttf
    urls:
    - https://fonts.gstatic.com/s/abeezee/v22/ABeeZee-Italic.ttf
    sha256: def456...
    file_size: 46789
    provides:
    - postscript_name: ABeeZee-Italic
      filename: ABeeZee-Italic.ttf
      format: ttf
      full_name: ABee Zee Italic

  # WOFF2 Format Resources
  - name: ABeeZee-Regular.woff2
    urls:
    - https://fonts.gstatic.com/s/abeezee/v22/ABeeZee-Regular.woff2
    sha256: ghi789...
    file_size: 23456
    provides:
    - postscript_name: ABeeZee-Regular
      filename: ABeeZee-Regular.woff2
      format: woff2
      full_name: ABee Zee Regular

  - name: ABeeZee-Italic.woff2
    urls:
    - https://fonts.gstatic.com/s/abeezee/v22/ABeeZee-Italic.woff2
    sha256: jkl012...
    file_size: 24567
    provides:
    - postscript_name: ABeeZee-Italic
      filename: ABeeZee-Italic.woff2
      format: woff2
      full_name: ABee Zee Italic
```

**Key Points:**
- Four separate resources (2 styles × 2 formats)
- Each resource provides exactly one style
- Format specified per style in `provides`
- PostScript name used for matching

### Example 2: Variable Font (Roboto)

```yaml
fonts:
- name: Roboto
  styles:
  - family_name: Roboto
    type: Regular
    postscript_name: Roboto-Regular
    full_name: Roboto Regular
  - family_name: Roboto
    type: Bold
    postscript_name: Roboto-Bold
    full_name: Roboto Bold
  # ... other static styles ...

resources:
  # Static TTF Resources
  - name: Roboto-Regular.ttf
    urls:
    - https://fonts.gstatic.com/s/roboto/v32/Roboto-Regular.ttf
    sha256: abc123...
    file_size: 168076
    provides:
    - postscript_name: Roboto-Regular
      filename: Roboto-Regular.ttf
      format: ttf
      full_name: Roboto Regular

  - name: Roboto-Bold.ttf
    urls:
    - https://fonts.gstatic.com/s/roboto/v32/Roboto-Bold.ttf
    sha256: def456...
    file_size: 167004
    provides:
    - postscript_name: Roboto-Bold
      filename: Roboto-Bold.ttf
      format: ttf
      full_name: Roboto Bold

  # Variable Font Resource
  - name: Roboto[wght].ttf
    urls:
    - https://fonts.gstatic.com/s/roboto/v32/Roboto[wght].ttf
    sha256: vfabc...
    file_size: 145678
    variable_axes:
    - wght
    provides:
    - postscript_name: Roboto-Regular
      filename: Roboto[wght].ttf
      format: ttf
      full_name: Roboto Regular
    - postscript_name: Roboto-Bold
      filename: Roboto[wght].ttf
      format: ttf
      full_name: Roboto Bold
    # The variable font can produce all these styles
```

**Key Points:**
- Variable font resource provides multiple styles from single file
- `variable_axes` declares which axes the font supports
- Multiple `provides` entries with same filename but different PostScript names
- Static and variable resources coexist for same styles

### Example 3: Archive Resource (Lato.zip)

```yaml
fonts:
- name: Lato
  styles:
  - family_name: Lato
    type: Regular
    postscript_name: Lato-Regular
    full_name: Lato Regular
  - family_name: Lato
    type: Italic
    postscript_name: Lato-Italic
    full_name: Lato Italic
  - family_name: Lato
    type: Bold
    postscript_name: Lato-Bold
    full_name: Lato Bold

resources:
  - name: Lato2OFL.zip
    urls:
    - https://fonts.google.com/download?family=Lato
    sha256: xyz789...
    file_size: 2945678
    provides:
    - postscript_name: Lato-Regular
      filename: Lato-Regular.ttf
      format: ttf
      full_name: Lato Regular
    - postscript_name: Lato-Italic
      filename: Lato-Italic.ttf
      format: ttf
      full_name: Lato Italic
    - postscript_name: Lato-Bold
      filename: Lato-Bold.ttf
      format: ttf
      full_name: Lato Bold
```

**Key Points:**
- Single archive resource provides multiple styles
- Filenames are paths within the archive
- Archive contains multiple font files
- Each file provides one style

### Example 4: Collection Resource (NotoSansCJK.ttc)

```yaml
fonts:
- name: Noto Sans CJK JP
  styles:
  - family_name: Noto Sans CJK JP
    type: Regular
    postscript_name: NotoSansCJKjp-Regular
    full_name: Noto Sans CJK JP Regular
  - family_name: Noto Sans CJK JP
    type: Bold
    postscript_name: NotoSansCJKjp-Bold
    full_name: Noto Sans CJK JP Bold

resources:
  - name: NotoSansCJK.ttc
    urls:
    - https://noto-website-2.storage.googleapis.com/pkgs/NotoSansCJK.ttc.zip
    sha256: ttc123...
    file_size: 123456789
    provides:
    - postscript_name: NotoSansCJKjp-Regular
      filename: NotoSansCJK.ttc
      format: ttc
      full_name: Noto Sans CJK JP Regular
    - postscript_name: NotoSansCJKjp-Bold
      filename: NotoSansCJK.ttc
      format: ttc
      full_name: Noto Sans CJK JP Bold
    # Multiple fonts in one TTC file
```

**Key Points:**
- TTC (TrueType Collection) contains multiple fonts in one file
- Multiple `provides` entries with same filename
- Format is `ttc` to indicate collection file
- Each provided font has unique PostScript name

## Matching Logic

### How Fontist Resolves Fonts

1. **User Requests a Font Style**: User specifies a font by family name and style (e.g., "ABeeZee Regular")

2. **Formula Lookup**: Fontist finds the formula containing that font family

3. **Style Matching**: Within the formula, finds the `Font` and `Style` matching the request

4. **PostScript Name Extraction**: Gets the `postscript_name` from the matched style

5. **Resource Matching**: Searches all resources in the formula for one whose `provides` collection contains an entry with matching `postscript_name`

6. **Format Preference** (if multiple resources match):
   - User can specify preferred format (TTF, WOFF2, OTF)
   - Default preference order: TTF → OTF → WOFF2
   - Variable fonts preferred if available and suitable

7. **Download and Extract**: Downloads the resource, extracts if needed, locates the file using `filename` from the matching `provides` entry

### Pseudo-code

```ruby
def find_resource_for_style(formula, style, preferred_format = nil)
  postscript_name = style.postscript_name

  # Find all resources that provide this PostScript name
  matching_resources = formula.resources.select do |resource|
    resource.provides.any? { |p| p.postscript_name == postscript_name }
  end

  # Filter by preferred format if specified
  if preferred_format
    matching_resources = matching_resources.select do |resource|
      provides_entry = resource.provides.find { |p| p.postscript_name == postscript_name }
      provides_entry.format == preferred_format
    end
  end

  # Apply default format preference
  matching_resources.sort_by do |resource|
    provides_entry = resource.provides.find { |p| p.postscript_name == postscript_name }
    format_priority(provides_entry.format)
  end.first
end

def format_priority(format)
  case format
  when 'ttf' then 1
  when 'otf' then 2
  when 'woff2' then 3
  else 4
  end
end
```

### File Attribute as Optimization Hint

The `filename` in `provides` serves as an optimization hint:
- For direct downloads: Validates the downloaded file
- For archives: Guides extraction to specific file
- For collections: Indicates which TTC file contains the font

However, the system should still verify the PostScript name of the extracted font matches what was expected.

## Implementation Requirements

### Phase 1: Model Updates

1. **Create `ProvidesInfo` Model**
   - Define in `lib/fontist/models/provides_info.rb`
   - Inherit from `Lutaml::Model::Serializable`
   - Add required validations

2. **Update `Resource` Model**
   - Add `provides` attribute
   - Ensure backward compatibility with old `format` attribute
   - Add migration helpers

3. **Update Formula Serialization**
   - Ensure YAML serialization handles `provides` correctly
   - Test round-trip serialization

### Phase 2: Formula Generation

1. **Google Fonts Importer Updates**
   - Download all available formats for each font variant
   - Use rate limiting (1 request per 3 seconds)
   - Extract PostScript name from each downloaded font
   - Build `provides` entries from actual font metadata
   - Create separate resources for each format

2. **Font Metadata Extraction**
   - Use existing `FontMetadataExtractor` to get PostScript names
   - Extract format from font file magic numbers
   - Handle TTC collections (extract all PostScript names)

3. **Resource Builder Logic**
   ```ruby
   # For each variant (style) and each format:
   def build_resource(variant, format, url, font_file)
     metadata = FontMetadataExtractor.extract(font_file)

     Resource.new(
       name: File.basename(url),
       urls: [url],
       sha256: calculate_sha256(font_file),
       file_size: File.size(font_file),
       provides: [
         ProvidesInfo.new(
           postscript_name: metadata.postscript_name,
           filename: File.basename(url),
           format: format,
           full_name: metadata.full_name
         )
       ]
     )
   end
   ```

### Phase 3: Archive and Collection Support

1. **Archive Resources**
   - Extract archive contents
   - Process each font file within archive
   - Build single resource with multiple `provides` entries
   - Use relative paths within archive as filenames

2. **Collection Resources (TTC)**
   - Use fonttools/ttx to extract PostScript names from TTC
   - Build resource with multiple `provides` entries
   - All entries reference same filename but different PostScript names

### Phase 4: Matching Logic Updates

1. **Update Font Resolution**
   - Modify style matching to use PostScript names
   - Implement format preference logic
   - Add user-facing format selection API

2. **Update Download and Extraction**
   - Use `provides.filename` to locate fonts in archives
   - Verify PostScript name after extraction
   - Handle format-specific extraction (TTF vs WOFF2 vs OTF)

### Phase 5: Testing

1. **Unit Tests**
   - Test `ProvidesInfo` model
   - Test resource matching logic
   - Test format preferences
   - Test edge cases (collections, archives, variable fonts)

2. **Integration Tests**
   - Test complete font installation flow
   - Test with various formula structures
   - Test backward compatibility

3. **Manual Testing**
   - Test with real Google Fonts
   - Test with archives
   - Test with collections
   - Verify file sizes and checksums

## Benefits

### 1. Explicit Resource Declarations

Resources explicitly declare what they provide, making formulas:
- Self-documenting
- Easier to validate
- Less prone to filename-based errors

### 2. Format-Specific Control

Users and systems can:
- Request specific formats (TTF vs WOFF2)
- Understand format availability before download
- Optimize for size (WOFF2) vs compatibility (TTF)

### 3. Better Variable Font Support

Variable fonts can explicitly declare:
- Which static styles they can produce
- What axes they support
- How they relate to static font resources

### 4. Archive and Collection Support

Works seamlessly with:
- ZIP archives containing multiple fonts
- TTC collections with multiple fonts per file
- PKG installers
- Any container format

### 5. Reliable Matching

Matching based on PostScript names is:
- Canonical (official font identifier)
- Not dependent on filenames
- Works across different sources
- Language-independent

### 6. Multiple Sources

Same font style can be provided by:
- Different formats (TTF, WOFF2, OTF)
- Different resources (static vs variable)
- Different URLs (mirrors, CDNs)

### 7. Formula Generation Automation

Enables fully automated formula generation from:
- Google Fonts API
- Other font repositories
- Font metadata files
- Archive contents

## Migration Plan

### Stage 1: Model and Infrastructure (Week 1)

1. **Create Models**
   - [ ] Implement `ProvidesInfo` model
   - [ ] Update `Resource` model with `provides` attribute
   - [ ] Add backward compatibility for old `format`
   - [ ] Write model tests

2. **Update Serialization**
   - [ ] Test YAML round-trip with new structure
   - [ ] Ensure old formulas still load
   - [ ] Document new YAML structure

### Stage 2: Formula Generation (Week 2-3)

1. **Update Google Fonts Importer**
   - [ ] Implement multi-format download
   - [ ] Add rate limiting (1 req / 3 sec)
   - [ ] Extract metadata from each format
   - [ ] Build `provides` entries
   - [ ] Generate resources per format

2. **Test Formula Generation**
   - [ ] Generate sample formulas
   - [ ] Validate structure
   - [ ] Test with various font types (static, variable, collection)

### Stage 3: Matching Logic (Week 4)

1. **Update Font Resolution**
   - [ ] Implement PostScript name matching
   - [ ] Add format preference logic
   - [ ] Update extraction to use `provides.filename`
   - [ ] Handle edge cases

2. **Update APIs**
   - [ ] Add format selection to install API
   - [ ] Update manifest support
   - [ ] Document new options

### Stage 4: Testing and Validation (Week 5)

1. **Comprehensive Testing**
   - [ ] Unit tests for all components
   - [ ] Integration tests for complete flows
   - [ ] Test with real formulas
   - [ ] Performance testing

2. **Manual Validation**
   - [ ] Test top 50 Google Fonts
   - [ ] Test various formats
   - [ ] Test archives and collections
   - [ ] Verify checksums and sizes

### Stage 5: Migration and Deployment (Week 6)

1. **Formula Migration**
   - [ ] Create migration script
   - [ ] Migrate existing formulas
   - [ ] Validate migrated formulas
   - [ ] Update formula repository

2. **Documentation**
   - [ ] Update README with new structure
   - [ ] Add migration guide
   - [ ] Update API documentation
   - [ ] Add examples

3. **Release**
   - [ ] Bump version
   - [ ] Update CHANGELOG
   - [ ] Create release notes
   - [ ] Deploy to RubyGems

### Stage 6: Cleanup (Week 7)

1. **Deprecation**
   - [ ] Mark old `format` attribute as deprecated
   - [ ] Add migration warnings
   - [ ] Plan removal timeline

2. **Optimization**
   - [ ] Profile performance
   - [ ] Optimize matching logic
   - [ ] Reduce memory usage

## Future Enhancements

### Enhanced Metadata

Add more metadata to `ProvidesInfo`:
- Font weight and width values
- OpenType features
- Language support
- License information per style

### Smart Format Selection

Implement intelligent format selection based on:
- Operating system
- Use case (web vs desktop)
- File size vs quality tradeoffs
- Available features per format

### Parallel Downloads

For resources with multiple `provides` entries:
- Download formats in parallel
- Share common validation logic
- Optimize bandwidth usage

### Format Conversion

Add ability to convert between formats:
- TTF ↔ OTF ↔ WOFF2
- Extract fonts from TTC
- Create variable fonts from statics

### CDN Support

Leverage multiple URLs per resource:
- Automatic mirror failover
- Geographic optimization
- Load balancing

## Conclusion

The `provides` attribute architecture represents a fundamental improvement in how Fontist models and manages font resources. By making resources explicitly declare what they provide, using canonical PostScript names for matching, and separating format from resource structure, we enable:

- Reliable, metadata-based font matching
- Multi-format support for the same font
- Better variable font handling
- Seamless archive and collection support
- Fully automated formula generation

This architecture provides a solid foundation for future enhancements while maintaining backward compatibility with existing formulas.