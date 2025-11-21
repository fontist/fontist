require_relative "models/font_family"
require_relative "models/axis"
require_relative "data_sources/ttf"
require_relative "data_sources/vf"
require_relative "data_sources/woff2"
require_relative "data_sources/github"
require_relative "../font_metadata_extractor"
require_relative "../../utils/downloader"
require "yaml"
require "fileutils"

module Fontist
  module Import
    module Google
      # Database for merged font data from API sources
      #
      # Generates v4 formulas (TTF static only) or v5 formulas (all formats)
      class FontDatabase
        attr_reader :fonts, :ttf_files, :woff2_files, :version, :github_data

        # Build database for v4 formulas (production)
        #
        # V4 Requirements:
        # - TTF format ONLY (no WOFF2)
        # - Static fonts ONLY (exclude variable fonts)
        # - OFL.txt license from GitHub repository
        # - Complete metadata from Fontisan
        #
        # @param api_key [String] Google Fonts API key
        # @param source_path [String] Path to google/fonts repository
        # @return [FontDatabase] configured database instance
        def self.build_v4(api_key:, source_path:)
          ttf_data = DataSources::Ttf.new(api_key: api_key).fetch
          # NO VF endpoint, NO WOFF2 endpoint for v4
          github_data = DataSources::Github.new(source_path: source_path).fetch

          new(
            ttf_data: ttf_data,
            github_data: github_data,
            version: 4
          )
        end

        # Build database for v5 formulas (future)
        #
        # V5 will support:
        # - TTF + WOFF2 formats
        # - Static + Variable fonts
        # - Enhanced `provides` attribute
        # - Per-file resources
        #
        # @param api_key [String] Google Fonts API key
        # @param source_path [String] Path to google/fonts repository
        # @return [FontDatabase] configured database instance
        def self.build_v5(api_key:, source_path:)
          ttf_data = DataSources::Ttf.new(api_key: api_key).fetch
          vf_data = DataSources::Vf.new(api_key: api_key).fetch
          woff2_data = DataSources::Woff2.new(api_key: api_key).fetch
          github_data = DataSources::Github.new(source_path: source_path).fetch

          new(
            ttf_data: ttf_data,
            vf_data: vf_data,
            woff2_data: woff2_data,
            github_data: github_data,
            version: 5
          )
        end

        # Generic build method for backward compatibility
        # Delegates to build_v4 by default
        #
        # @param api_key [String] Google Fonts API key
        # @param source_path [String, nil] Path to google/fonts repository (optional)
        # @return [FontDatabase] configured database instance
        def self.build(api_key:, source_path: nil)
          if source_path
            build_v4(api_key: api_key, source_path: source_path)
          else
            # Build without GitHub data
            ttf_data = DataSources::Ttf.new(api_key: api_key).fetch
            new(ttf_data: ttf_data, version: 4)
          end
        end

        # Initialize database with API data
        #
        # @param ttf_data [Array] TTF endpoint data
        # @param vf_data [Array, nil] VF endpoint data (optional, for v5)
        # @param woff2_data [Array, nil] WOFF2 endpoint data (optional, for v5)
        # @param github_data [Array, nil] GitHub repository data (optional)
        # @param version [Integer] Formula version (4 or 5)
        def initialize(ttf_data:, vf_data: nil, woff2_data: nil, github_data: nil, version: 4)
          @ttf_data = Array(ttf_data)
          @vf_data = Array(vf_data)
          @woff2_data = Array(woff2_data)
          @github_data_raw = Array(github_data)
          @version = version
          @ttf_files = {}
          @woff2_files = {}
          @github_index = index_github_data
          @github_data = @github_index  # Expose indexed version
          @fonts = merge_data
        end

        # Get all font families
        def all_fonts
          @fonts.values
        end

        # Find a specific font family by name
        def font_by_name(family_name)
          @fonts[family_name]
        end

        # Filter fonts by category
        def by_category(category)
          all_fonts.select { |font| font.category == category }
        end

        # Get only variable fonts (fonts with axes)
        def variable_fonts_only
          all_fonts.select(&:variable_font?)
        end

        # Get only static fonts (fonts without axes)
        def static_fonts_only
          all_fonts.reject(&:variable_font?)
        end

        # Get count of fonts by type
        def fonts_count
          {
            total: all_fonts.count,
            variable: variable_fonts_only.count,
            static: static_fonts_only.count,
          }
        end

        # Get all unique categories
        def categories
          all_fonts.map(&:category).compact.uniq.sort
        end

        # Get fonts available in TTF format
        def fonts_with_ttf
          all_fonts.select { |font| @ttf_files.key?(font.family) }
        end

        # Get fonts available in WOFF2 format
        def fonts_with_woff2
          all_fonts.select { |font| @woff2_files.key?(font.family) }
        end

        # Get fonts available in both formats
        def fonts_with_both_formats
          all_fonts.select do |font|
            @ttf_files.key?(font.family) && @woff2_files.key?(font.family)
          end
        end

        # Get TTF files for a specific font family
        def ttf_files_for(family_name)
          @ttf_files[family_name]
        end

        # Get WOFF2 files for a specific font family
        def woff2_files_for(family_name)
          @woff2_files[family_name]
        end

        # Generate formula for a font family
        def to_formula(family_name)
          family = font_by_name(family_name)
          return nil unless family

          build_formula_v4(family)
        end

        # Generate formulas for all fonts
        def to_formulas
          all_fonts.map { |f| to_formula(f.family) }.compact
        end

        # Save formulas to disk
        def save_formulas(output_dir, family_name: nil)
          families = family_name ? [font_by_name(family_name)] : all_fonts
          families = families.compact

          families.map do |family|
            formula = to_formula(family.family)
            next unless formula

            save_formula(formula, family.family, output_dir)
          end.compact
        end

        # Build v4 formula from API data
        def build_formula_v4(family)
          github_family = @github_index[family.family]

          # Read license from GitHub if available
          license_url, license_text = if github_family&.license_text
            [
              "https://scripts.sil.org/OFL",
              github_family.license_text
            ]
          else
            [
              "https://scripts.sil.org/OFL",
              "SIL Open Font License v1.1"
            ]
          end

          # Build fonts first to get copyright
          fonts_data = build_fonts_v4(family)

          # Extract copyright from first font style, or use license_text as fallback
          copyright = fonts_data.dig(0, "styles", 0, "copyright") || github_family&.license_text

          # Use GitHub description if available
          description = github_family&.description || default_description(family)

          {
            name: formula_name(family),
            description: description,
            homepage: default_homepage(family),
            resources: build_resources_v4(family),
            fonts: fonts_data,
            extract: {},
            copyright: copyright,
            license_url: license_url,
            license: license_text,  # Changed from open_license
            open_license: license_text
          }.compact
        end

        # Build resources from API URLs (v4: TTF only, no WOFF2)
        def build_resources_v4(family)
          files = []

          # V4: Collect ONLY TTF URLs from API (no WOFF2)
          @ttf_files[family.family]&.each_value do |url|
            files << url
          end

          return nil if files.empty?

          # V4: Always use "ttf" format (no variable fonts in v4)
          format = "ttf"

          resource = {
            "source" => "google",
            "family" => family.family,
            "files" => files,
            "format" => format
          }

          # Add variable_axes if present
          if family.variable_font? && family.axes
            resource["variable_axes"] = family.axes.map(&:tag)
          end

          { family.family => resource }
        end

        # Build fonts from API variant data with full metadata (v4: TTF only)
        def build_fonts_v4(family)
          parsed_fonts = []

          # V4: Download and parse ONLY TTF files to get complete metadata
          @ttf_files[family.family]&.each do |variant, url|
            sleep(0.05)  # Throttle API requests

            begin
              # Download font
              downloaded = Fontist::Utils::Downloader.download(url)

              # Parse with Fontisan
              metadata = Fontist::Import::FontMetadataExtractor.new(downloaded.path).extract

              # V4: Skip variable fonts
              if metadata.is_variable
                next
              end

              # Get filename from URL
              filename = url.split("/").last

              # Create style with complete metadata
              style_data = {
                family_name: metadata.family_name,
                type: metadata.subfamily_name,
                full_name: metadata.full_name,
                post_script_name: metadata.postscript_name,
                version: metadata.version,
                copyright: metadata.copyright,
                font: filename
              }

              # Add preferred names if present
              if metadata.preferred_family_name
                style_data[:preferred_family_name] = metadata.preferred_family_name
              end
              if metadata.preferred_subfamily_name
                style_data[:preferred_type] = metadata.preferred_subfamily_name
              end

              # Add description if present
              if metadata.description
                style_data[:description] = metadata.description
              end

              parsed_fonts << style_data
            rescue StandardError => e
              warn "Warning: Failed to download/parse #{url}: #{e.message}"
            end
          end

          return [] if parsed_fonts.empty?

          # Group by subfamily (family_name from font, not API family)
          fonts_by_subfamily = parsed_fonts.group_by { |f| f[:family_name] }

          fonts_by_subfamily.map do |subfamily_name, styles|
            {
              "name" => subfamily_name,
              "styles" => styles.map { |s| stringify_style(s) }
            }
          end
        end

        # Convert style hash to string keys
        def stringify_style(style)
          style.transform_keys(&:to_s).transform_values { |v| v.is_a?(Symbol) ? v.to_s : v }
        end

        # Find filename for a variant
        def find_font_filename_for_variant(family, variant)
          # Try TTF first
          url = @ttf_files[family.family]&.[](variant)
          return url.split("/").last if url

          # Try WOFF2
          url = @woff2_files[family.family]&.[](variant)
          return url.split("/").last if url

          nil
        end

        # Convert API variant to style type
        def variant_to_type(variant)
          case variant
          when "regular" then "Regular"
          when "italic" then "Italic"
          when /^(\d+)italic$/ then "#{$1} Italic"
          when /^(\d+)$/ then variant
          else variant.capitalize
          end
        end

        # Generate formula name from family name
        def formula_name(family)
          family.family.downcase.gsub(/\s+/, "_")
        end

        # Generate default description
        def default_description(family)
          "#{family.family} font family"
        end

        # Generate default homepage
        def default_homepage(family)
          "https://fonts.google.com/specimen/#{family.family.gsub(/\s+/, '+')}"
        end

        # Save formula to disk
        def save_formula(formula, family_name, output_dir)
          FileUtils.mkdir_p(output_dir)
          filename = "#{family_name.downcase.gsub(/\s+/, '_')}.yml"
          path = File.join(output_dir, filename)
          File.write(path, YAML.dump(formula))
          path
        end

        private

        # Index GitHub data by family name for quick lookup
        def index_github_data
          return {} if @github_data_raw.empty?

          @github_data_raw.each_with_object({}) do |family, hash|
            hash[family.family] = family
          end
        end

        # Merge data from API sources
        def merge_data
          merged = {}

          # Index all fonts by family name
          ttf_index = index_by_family(@ttf_data)
          vf_index = index_by_family(@vf_data)
          woff2_index = index_by_family(@woff2_data)

          # Get all unique family names
          all_families = (ttf_index.keys + vf_index.keys + woff2_index.keys).uniq

          all_families.each do |family_name|
            ttf_font = ttf_index[family_name]
            vf_font = vf_index[family_name]
            woff2_font = woff2_index[family_name]

            # Use TTF as base, or VF, or WOFF2 as fallback
            base_font = ttf_font || vf_font || woff2_font
            next unless base_font

            # For v4: skip only fonts that are ACTUALLY variable (have axes)
            if @version == 4 && vf_font&.variable_font?
              next
            end

            # Store format-specific files
            @ttf_files[family_name] = ttf_font.files if ttf_font
            @woff2_files[family_name] = woff2_font.files if woff2_font

            # Create merged font
            merged[family_name] = merge_font_family(base_font, ttf_font, vf_font, woff2_font)
          end

          merged
        end

        # Index fonts by family name
        def index_by_family(fonts)
          fonts.each_with_object({}) do |font, hash|
            hash[font.family] = font
          end
        end

        # Merge a single font family from multiple sources
        def merge_font_family(base_font, ttf_font, vf_font, woff2_font)
          # Use the most recent version
          version = most_recent_version(
            base_font.version,
            ttf_font&.version,
            vf_font&.version,
            woff2_font&.version
          )

          # Use the most recent lastModified
          last_modified = most_recent_date(
            base_font.last_modified,
            ttf_font&.last_modified,
            vf_font&.last_modified,
            woff2_font&.last_modified
          )

          # Use TTF files as primary
          merged_files = ttf_font&.files || base_font.files

          # Get axes from VF endpoint
          axes = vf_font&.axes

          # Get GitHub metadata if available
          github_family = @github_index[base_font.family]

          Models::FontFamily.new(
            family: base_font.family,
            variants: base_font.variants,
            subsets: base_font.subsets,
            version: version,
            last_modified: last_modified,
            files: merged_files,
            category: base_font.category,
            kind: base_font.kind,
            menu: base_font.menu,
            axes: axes,
            designer: github_family&.designer,
            license: github_family&.license,
            description: github_family&.description,
          )
        end

        # Get the most recent version string
        def most_recent_version(*versions)
          versions.compact.max_by { |v| version_number(v) }
        end

        # Extract numeric version from version string
        def version_number(version)
          version.to_s.gsub(/[^0-9]/, "").to_i
        end

        # Get the most recent date string
        def most_recent_date(*dates)
          dates.compact.max_by { |d| Date.parse(d) rescue Date.new(0) }
        end
      end
    end
  end
end