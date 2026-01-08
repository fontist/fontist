# Google Fonts API Multi-Format Architecture Plan

## Executive Summary

This document outlines the architecture for refactoring [`lib/fontist/import/google/api.rb`](../../lib/fontist/import/google/api.rb) to support retrieving data from three Google Fonts API endpoints:

1. **Standard TTF** (static files): `https://www.googleapis.com/webfonts/v1/webfonts?key={API_KEY}`
2. **Variable Fonts** (VF): `https://www.googleapis.com/webfonts/v1/webfonts?key={API_KEY}&capability=VF`
3. **WOFF2 files**: `https://www.googleapis.com/webfonts/v1/webfonts?key={API_KEY}&capability=WOFF2`

The goal is to create an object-oriented, model-based architecture that provides unified access to all three data sources while maintaining MECE principles and separation of concerns.

## Current State Analysis

### Existing Implementation

Current [`lib/fontist/import/google/api.rb`](../../lib/fontist/import/google/api.rb):

```ruby
module Fontist
  module Import
    module Google
      class Api
        class << self
          def items
            db["items"]
          end

          def db
            @db ||= JSON.parse(Net::HTTP.get(URI(url)))
          end

          def url
            "https://www.googleapis.com/webfonts/v1/webfonts?key=#{api_key}"
          end

          def api_key
            Fontist.google_fonts_key
          end
        end
      end
    end
  end
end
```

**Limitations:**
- Only fetches standard TTF files
- No support for variable fonts or WOFF2 formats
- Flat structure with no model-based architecture
- Direct JSON parsing without type safety
- Class-level singleton pattern limits extensibility

### Current API Response Structure

Based on Google Fonts API documentation, the standard endpoint returns:

```json
{
  "kind": "webfonts#webfontList",
  "items": [
    {
      "family": "ABeeZee",
      "variants": ["regular", "italic"],
      "subsets": ["latin", "latin-ext"],
      "version": "v23",
      "lastModified": "2025-09-08",
      "files": {
        "regular": "https://fonts.gstatic.com/s/abeezee/v23/esDR31xSG-6AGleN6tKukbcHCpE.ttf",
        "italic": "https://fonts.gstatic.com/s/abeezee/v23/esDT31xSG-6AGleN2tCklZUCGpG-GQ.ttf"
      },
      "category": "sans-serif",
      "kind": "webfonts#webfont",
      "menu": "https://fonts.gstatic.com/s/abeezee/v23/esDR31xSG-6AGleN2tKklQ.ttf"
    }
  ]
}
```

## Requirements Analysis

### Functional Requirements

1. **Multi-Endpoint Support**
   - Fetch data from all three API endpoints
   - Handle different response structures per capability

2. **Unified Data Model**
   - Create OO models for font families
   - Support multiple format types per family
   - Store variable font axes information
   - Maintain file URLs for all formats

3. **Data Merging Strategy**
   - Intelligently combine data from all three endpoints
   - Handle fonts available in multiple formats
   - Preserve format-specific metadata

4. **Extensibility**
   - Easy to add new capabilities/endpoints
   - Plugin architecture for format handlers
   - Configuration-driven capabilities

5. **Performance**
   - Cache API responses
   - Lazy loading support
   - Efficient data structures

### Non-Functional Requirements

1. **Maintainability**
   - Clear separation of concerns
   - MECE principle adherence
   - DRY implementation
   - Comprehensive documentation

2. **Testability**
   - Unit tests for all models
   - Integration tests for API calls
   - VCR cassettes for HTTP requests

3. **Clean Architecture**
   - No legacy format support needed
   - Direct model-based API
   - Modern, idiomatic Ruby design

## Proposed Architecture

### Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                      Fontist::Import::Google                     │
└─────────────────────────────────────────────────────────────────┘
                                 │
                                 ▼
         ┌───────────────────────────────────────────┐
         │          Api (Facade/Entry Point)         │
         │  - unified_database                       │
         │  - font_families                          │
         │  - items (backward compat)                │
         │  - ttf_client, vf_client, woff2_client    │
         └───────────────────────────────────────────┘
                                 │
                    ┌────────────┴────────────┐
                    ▼                         ▼
         ┌──────────────────┐      ┌─────────────────┐
         │  FontDatabase    │      │   ApiEndpoint   │
         │  - merge_data    │      │   (Base)        │
         │  - font_by_name  │      │  - fetch        │
         │  - all_fonts     │      │  - capability   │
         └──────────────────┘      │  - cache        │
                    │              └─────────────────┘
                    │                       │
                    │              ┌────────┼────────┐
                    │              ▼        ▼        ▼
                    │         ┌────────┬────────┬────────┐
                    │         │  TTF   │   VF   │ WOFF2  │
                    │         │ Client │ Client │ Client │
                    │         └────────┴────────┴────────┘
                    ▼
         ┌──────────────────┐
         │   FontFamily     │
         │   - family       │
         │   - variants     │
         │   - category     │
         └──────────────────┘
                    │
                    ▼
         ┌─────────────────┐
         │   FontVariant   │
         │   - name        │
         │   - weight      │
         │   - style       │
         │   - format      │
         │   - url         │
         │   - axes (VF)   │
         └─────────────────┘
```

### Core Components

#### 1. FontFamily Model

Represents a font family with all its variants and formats.

```ruby
module Fontist
  module Import
    module Google
      module Models
        class FontFamily < Lutaml::Model::Serializable
          attribute :family, :string
          attribute :category, :string
          attribute :subsets, :string, collection: true
          attribute :version, :string
          attribute :last_modified, :string
          attribute :kind, :string
          attribute :menu_url, :string
          attribute :variants, FontVariant, collection: true

          # Returns variants of a specific format
          def variants_by_format(format)
            variants.select { |v| v.format == format }
          end

          # Check if family has variable fonts
          def variable_fonts?
            variants.any?(&:variable_font?)
          end

          # Check if family has WOFF2 format
          def woff2_available?
            variants.any? { |v| v.format == :woff2 }
          end
        end
      end
    end
  end
end
```

#### 2. FontVariant Model

Represents a specific font variant (style/weight) with format information.

```ruby
module Fontist
  module Import
    module Google
      module Models
        class FontVariant < Lutaml::Model::Serializable
          attribute :name, :string           # "regular", "italic", "700", etc.
          attribute :weight, :integer        # 400, 700, etc.
          attribute :style, :string          # "normal", "italic"
          attribute :format, :string         # :ttf, :vf, :woff2
          attribute :url, :string            # Download URL
          attribute :axes, VariableAxes      # Only for VF format

          def variable_font?
            format == :vf && !axes.nil?
          end

          def to_h
            super.tap do |hash|
              hash.delete(:axes) unless variable_font?
            end
          end
        end
      end
    end
  end
end
```

#### 3. VariableAxes Model

Stores variable font axes information.

```ruby
module Fontist
  module Import
    module Google
      module Models
        class VariableAxes < Lutaml::Model::Serializable
          attribute :weight_min, :integer
          attribute :weight_max, :integer
          attribute :width_min, :float
          attribute :width_max, :float
          attribute :slant_min, :float
          attribute :slant_max, :float
          attribute :custom_axes, CustomAxis, collection: true

          def has_weight_axis?
            !weight_min.nil? && !weight_max.nil?
          end

          def has_width_axis?
            !width_min.nil? && !width_max.nil?
          end

          def has_slant_axis?
            !slant_min.nil? && !slant_max.nil?
          end
        end

        class CustomAxis < Lutaml::Model::Serializable
          attribute :tag, :string     # 4-char axis tag
          attribute :name, :string
          attribute :min_value, :float
          attribute :max_value, :float
          attribute :default_value, :float
        end
      end
    end
  end
end
```

#### 4. ApiEndpoint (Base Class)

Abstract base class for API endpoint clients.

```ruby
module Fontist
  module Import
    module Google
      module Clients
        class ApiEndpoint
          attr_reader :capability, :api_key

          def initialize(api_key:, capability: nil)
            @api_key = api_key
            @capability = capability
          end

          def fetch
            @cache ||= parse_response(fetch_raw)
          end

          def url
            base = "https://www.googleapis.com/webfonts/v1/webfonts?key=#{api_key}"
            capability ? "#{base}&capability=#{capability}" : base
          end

          def fetch_raw
            response = Net::HTTP.get(URI(url))
            JSON.parse(response)
          end

          def parse_response(raw_data)
            raise NotImplementedError, "Subclass must implement parse_response"
          end

          def clear_cache
            @cache = nil
          end
        end
      end
    end
  end
end
```

#### 5. Specific Endpoint Clients

```ruby
module Fontist
  module Import
    module Google
      module Clients
        class TtfClient < ApiEndpoint
          def initialize(api_key:)
            super(api_key: api_key, capability: nil)
          end

          def parse_response(raw_data)
            raw_data["items"].map do |item|
              parse_font_family(item, :ttf)
            end
          end

          private

          def parse_font_family(item, format)
            # Convert to FontFamily model
            # Implementation details...
          end
        end

        class VfClient < ApiEndpoint
          def initialize(api_key:)
            super(api_key: api_key, capability: "VF")
          end

          def parse_response(raw_data)
            raw_data["items"].map do |item|
              parse_font_family_with_axes(item, :vf)
            end
          end

          private

          def parse_font_family_with_axes(item, format)
            # Parse variable font specific data
            # Extract axes information
            # Implementation details...
          end
        end

        class Woff2Client < ApiEndpoint
          def initialize(api_key:)
            super(api_key: api_key, capability: "WOFF2")
          end

          def parse_response(raw_data)
            raw_data["items"].map do |item|
              parse_font_family(item, :woff2)
            end
          end

          private

          def parse_font_family(item, format)
            # Convert to FontFamily model with WOFF2 URLs
            # Implementation details...
          end
        end
      end
    end
  end
end
```

#### 6. FontDatabase (Data Merger)

Merges data from all three endpoints into a unified database.

```ruby
module Fontist
  module Import
    module Google
      class FontDatabase
        attr_reader :families

        def initialize(ttf_data:, vf_data:, woff2_data:)
          @families = merge_all_data(ttf_data, vf_data, woff2_data)
        end

        def font_by_name(family_name)
          @families.find { |f| f.family == family_name }
        end

        def all_fonts
          @families
        end

        def by_category(category)
          @families.select { |f| f.category == category }
        end

        def variable_fonts_only
          @families.select(&:variable_fonts?)
        end

        private

        def merge_all_data(ttf_data, vf_data, woff2_data)
          # Create a hash indexed by family name
          db = {}

          # Add TTF data as base
          ttf_data.each do |family|
            db[family.family] = family
          end

          # Merge VF data
          vf_data.each do |vf_family|
            if db.key?(vf_family.family)
              db[vf_family.family] = merge_family(db[vf_family.family], vf_family)
            else
              db[vf_family.family] = vf_family
            end
          end

          # Merge WOFF2 data
          woff2_data.each do |woff2_family|
            if db.key?(woff2_family.family)
              db[woff2_family.family] = merge_family(db[woff2_family.family], woff2_family)
            else
              db[woff2_family.family] = woff2_family
            end
          end

          db.values.sort_by(&:family)
        end

        def merge_family(base_family, additional_family)
          # Merge variants from additional_family into base_family
          # Keep all variants, mark format appropriately
          base_family.tap do |family|
            additional_family.variants.each do |variant|
              family.variants << variant unless has_variant?(family, variant)
            end
          end
        end

        def has_variant?(family, variant)
          family.variants.any? do |v|
            v.name == variant.name && v.format == variant.format
          end
        end
      end
    end
  end
end
```

#### 7. Api (Refactored Facade)

Main entry point maintaining backward compatibility.

```ruby
module Fontist
  module Import
    module Google
      class Api
        class << self
          # New unified database access
          def database
            @database ||= build_database
          end

          # Returns all font families with all formats
          def font_families
            database.all_fonts
          end

          # Backward compatible method
          def items
            # Return array compatible with old format
            font_families.map { |f| family_to_legacy_format(f) }
          end

          # Access to raw endpoint data
          def ttf_data
            ttf_client.fetch
          end

          def vf_data
            vf_client.fetch
          end

          def woff2_data
            woff2_client.fetch
          end

          # Clear all caches
          def clear_cache
            @database = nil
            ttf_client.clear_cache
            vf_client.clear_cache
            woff2_client.clear_cache
          end

          private

          def build_database
            FontDatabase.new(
              ttf_data: ttf_data,
              vf_data: vf_data,
              woff2_data: woff2_data
            )
          end

          def ttf_client
            @ttf_client ||= Clients::TtfClient.new(api_key: api_key)
          end

          def vf_client
            @vf_client ||= Clients::VfClient.new(api_key: api_key)
          end

          def woff2_client
            @woff2_client ||= Clients::Woff2Client.new(api_key: api_key)
          end

          def api_key
            Fontist.google_fonts_key
          end

          def family_to_legacy_format(font_family)
            # Convert FontFamily model to old hash format
            # for backward compatibility
            {
              "family" => font_family.family,
              "variants" => font_family.variants.map(&:name).uniq,
              "subsets" => font_family.subsets,
              "version" => font_family.version,
              "lastModified" => font_family.last_modified,
              "files" => extract_legacy_files(font_family),
              "category" => font_family.category,
              "kind" => font_family.kind,
              "menu" => font_family.menu_url
            }
          end

          def extract_legacy_files(font_family)
            # Extract TTF files in old format
            files = {}
            font_family.variants.select { |v| v.format == :ttf }.each do |variant|
              files[variant.name] = variant.url
            end
            files
          end
        end
      end
    end
  end
end
```

## Implementation Phases

### Phase 1: Investigation & Data Analysis
- [ ] Fetch actual responses from all three API endpoints
- [ ] Document response structure differences
- [ ] Identify variable font axes representation
- [ ] Create sample JSON fixtures for testing

### Phase 2: Model Implementation
- [ ] Create [`FontFamily`](../../lib/fontist/import/google/models/font_family.rb) model class
- [ ] Create [`FontVariant`](../../lib/fontist/import/google/models/font_variant.rb) model class
- [ ] Create [`VariableAxes`](../../lib/fontist/import/google/models/variable_axes.rb) and [`CustomAxis`](../../lib/fontist/import/google/models/custom_axis.rb) models
- [ ] Write comprehensive RSpec tests for all models

### Phase 3: Client Implementation
- [ ] Create [`ApiEndpoint`](../../lib/fontist/import/google/clients/api_endpoint.rb) base class
- [ ] Implement [`TtfClient`](../../lib/fontist/import/google/clients/ttf_client.rb)
- [ ] Implement [`VfClient`](../../lib/fontist/import/google/clients/vf_client.rb)
- [ ] Implement [`Woff2Client`](../../lib/fontist/import/google/clients/woff2_client.rb)
- [ ] Add VCR cassettes for HTTP caching in tests
- [ ] Write RSpec tests for all clients

### Phase 4: Database & Merging Logic
- [ ] Implement [`FontDatabase`](../../lib/fontist/import/google/font_database.rb) class
- [ ] Create merge strategy for combining data
- [ ] Handle edge cases (fonts only in some endpoints)
- [ ] Write comprehensive merger tests

### Phase 5: Facade Refactoring
- [ ] Refactor [`Api`](../../lib/fontist/import/google/api.rb) class as facade
- [ ] Maintain backward compatibility with [`items`](../../lib/fontist/import/google/api.rb:6) method
- [ ] Add new methods for accessing unified database
- [ ] Write integration tests

### Phase 6: Integration & Testing
- [ ] Update [`GoogleImport`](../../lib/fontist/import/google_import.rb) to use new models
- [ ] Update [`GoogleImporter`](../../lib/fontist/import/google_importer.rb) if needed
- [ ] Run full test suite
- [ ] Performance testing and optimization

### Phase 7: Documentation
- [ ] Update [`README.adoc`](../../README.adoc) with new capabilities
- [ ] Add code examples for new API
- [ ] Document migration path from old to new
- [ ] Add architecture diagrams

## File Structure

New directory structure:

```
lib/fontist/import/google/
├── api.rb                          # Refactored facade
├── metadata_parser.rb              # Existing, untouched
├── font_database.rb                # NEW: Data merger
├── models/
│   ├── font_family.rb             # NEW: FontFamily model
│   ├── font_variant.rb            # NEW: FontVariant model
│   ├── variable_axes.rb           # NEW: VariableAxes model
│   └── custom_axis.rb             # NEW: CustomAxis model
└── clients/
    ├── api_endpoint.rb            # NEW: Base client
    ├── ttf_client.rb              # NEW: TTF endpoint client
    ├── vf_client.rb               # NEW: VF endpoint client
    └── woff2_client.rb            # NEW: WOFF2 endpoint client

spec/fontist/import/google/
├── api_spec.rb                     # Updated tests
├── font_database_spec.rb           # NEW: Merger tests
├── models/
│   ├── font_family_spec.rb        # NEW
│   ├── font_variant_spec.rb       # NEW
│   └── variable_axes_spec.rb      # NEW
├── clients/
│   ├── ttf_client_spec.rb         # NEW
│   ├── vf_client_spec.rb          # NEW
│   └── woff2_client_spec.rb       # NEW
└── fixtures/
    ├── ttf_response.json           # NEW: Sample TTF response
    ├── vf_response.json            # NEW: Sample VF response
    └── woff2_response.json         # NEW: Sample WOFF2 response
```

## Testing Strategy

### Unit Tests

1. **Model Tests**
   - Test serialization/deserialization
   - Test attribute validation
   - Test helper methods
   - Test edge cases

2. **Client Tests**
   - Test URL generation
   - Test response parsing
   - Test caching behavior
   - Use VCR cassettes for HTTP

3. **Database Tests**
   - Test merging logic
   - Test query methods
   - Test edge cases (missing data, duplicates)

### Integration Tests

1. Test full data flow from API to models
2. Test backward compatibility with existing code
3. Test performance with large datasets

## API Usage

The refactored [`Api`](../../lib/fontist/import/google/api.rb) class provides a clean, model-based interface:

```ruby
# Get all font families (FontFamily objects)
Google::Api.items  # Returns array of FontFamily models
Google::Api.font_families  # Same as above

# Access unified database
Google::Api.database.variable_fonts_only  # Get VF-only fonts
Google::Api.database.by_category("sans-serif")  # Filter by category
Google::Api.database.font_by_name("Roboto")  # Get specific family

# Access raw endpoint data if needed
Google::Api.ttf_data  # Raw TTF endpoint data
Google::Api.vf_data  # Raw VF endpoint data
Google::Api.woff2_data  # Raw WOFF2 endpoint data
```

## Performance Considerations

### Caching Strategy

1. **API Response Caching**
   - Cache responses at client level
   - Configurable TTL
   - Manual cache invalidation

2. **Database Caching**
   - Lazy initialization
   - Singleton pattern for database instance
   - Clear method for cache busting

### Optimization Opportunities

1. **Parallel Fetching**
   - Fetch all three endpoints concurrently
   - Use Thread pool or async library

2. **Partial Loading**
   - Option to load only specific formats
   - On-demand endpoint fetching

3. **Memory Efficiency**
   - Stream parsing for large responses
   - Pagination support if needed

## Security Considerations

1. **API Key Management**
   - Never hardcode API keys
   - Use environment variables
   - Document key acquisition process

2. **Rate Limiting**
   - Respect Google API rate limits
   - Implement exponential backoff
   - Cache responses appropriately

3. **Error Handling**
   - Graceful degradation on endpoint failures
   - Clear error messages
   - Logging for debugging

## Open Questions

### Questions Requiring Investigation

1. **VF Response Structure**
   - How are axes represented in the VF endpoint response?
   - Are axes at family level or variant level?
   - What is the exact JSON structure?

2. **WOFF2 Differences**
   - Does WOFF2 endpoint return different font families?
   - Are URLs the only difference?
   - Are all TTF fonts available as WOFF2?

3. **Data Consistency**
   - Are family names consistent across endpoints?
   - Do version numbers match?
   - How to handle discrepancies?

4. **Format Priority**
   - When multiple formats exist, which should be default?
   - Should formulas prefer VF over static TTF?
   - User preference configuration?

### Decisions to Be Made

1. **Merge Strategy**: Confirmed after API response analysis
2. **Default Format**: Based on project requirements
3. **Cache Duration**: Based on API update frequency
4. **Error Recovery**: Based on reliability requirements

## Next Steps

1. **Create test script** to fetch and save responses from all three endpoints
2. **Analyze responses** to finalize model structure
3. **Update this plan** based on actual API response structure
4. **Begin Phase 2** implementation (models)

## References

- [Google Fonts Developer API](https://developers.google.com/fonts/docs/developer_api)
- [Google Fonts GitHub Repository](https://github.com/google/fonts)
- [Lutaml Model Documentation](~/src/lutaml/lutaml-model/README.adoc)
- [Variable Fonts Specification](https://docs.microsoft.com/en-us/typography/opentype/spec/otvaroverview)