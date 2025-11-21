require "unibuf"
require_relative "../metadata_adapter"
require_relative "../../otf/font_file"
require_relative "../models/font_family"
require "pathname"

module Fontist
  module Import
    module Google
      module DataSources
        # Data source for fetching font data from Google Fonts GitHub repository
        #
        # This data source reads font metadata from a local clone of the
        # Google Fonts repository, parsing METADATA.pb files and extracting
        # information from font files using otfinfo.
        class Github
          attr_reader :source_path

          # Initialize a new GitHub data source
          #
          # @param source_path [String] Path to Google Fonts repository
          def initialize(source_path:)
            @source_path = Pathname.new(source_path)
            @cache = nil
            validate_source_path!
          end

          # Fetch and parse all font families from the repository
          #
          # @return [Array<FontFamily>] array of parsed font family models
          def fetch
            return @cache if @cache

            @cache = parse_all_fonts
          end

          # Fetch a specific font family by name
          #
          # @param name [String] the font family name
          # @return [FontFamily, nil] the font family if found
          def fetch_family(name)
            family_path = find_family_path(name)
            return nil unless family_path

            parse_family(family_path)
          end

          # Clear the internal cache
          #
          # @return [nil]
          def clear_cache
            @cache = nil
          end

          private

          # Validate that the source path exists and contains fonts
          def validate_source_path!
            unless @source_path.exist?
              raise ArgumentError,
                    "Source path does not exist: #{@source_path}"
            end

            unless @source_path.directory?
              raise ArgumentError,
                    "Source path is not a directory: #{@source_path}"
            end

            ofl_path = @source_path.join("ofl")
            apache_path = @source_path.join("apache")
            ufl_path = @source_path.join("ufl")

            unless ofl_path.exist? || apache_path.exist? || ufl_path.exist?
              raise ArgumentError,
                    "Source path does not contain expected font directories: "\
                    "#{@source_path}"
            end
          end

          # Parse all font families from the repository
          #
          # @return [Array<FontFamily>] array of font families
          def parse_all_fonts
            families = []

            font_directories.each do |dir|
              family = parse_family(dir)
              families << family if family
            rescue StandardError => e
              warn "Warning: Failed to parse #{dir}: #{e.message}"
            end

            families
          end

          # Get all font family directories
          #
          # @return [Array<Pathname>] array of directory paths
          def font_directories
            dirs = []

            %w[ofl apache ufl].each do |license_dir|
              license_path = @source_path.join(license_dir)
              next unless license_path.exist?

              license_path.children.select(&:directory?).each do |family_dir|
                dirs << family_dir if family_dir.join("METADATA.pb").exist?
              end
            end

            dirs
          end

          # Find the directory path for a font family by name
          #
          # @param name [String] the font family name
          # @return [Pathname, nil] the directory path if found
          def find_family_path(name)
            normalized_name = normalize_family_name(name)

            font_directories.find do |dir|
              dir.basename.to_s == normalized_name
            end
          end

          # Normalize a font family name to directory name format
          #
          # @param name [String] the font family name
          # @return [String] normalized name
          def normalize_family_name(name)
            name.downcase.gsub(/\s+/, "")
          end

          # Parse a single font family directory
          #
          # @param family_dir [Pathname] the family directory path
          # @return [FontFamily, nil] the parsed font family
          def parse_family(family_dir)
            metadata_path = family_dir.join("METADATA.pb")
            return nil unless metadata_path.exist?

            # Parse with unibuf and adapt to our domain model
            unibuf_message = Unibuf.parse_textproto_file(metadata_path.to_s)
            metadata = MetadataAdapter.adapt(unibuf_message)

            font_files_data = parse_font_files(family_dir, metadata)
            license_info = read_license(family_dir)
            description = read_description(family_dir)

            Models::FontFamily.new(
              family: metadata.name,
              variants: extract_variants(metadata),
              subsets: extract_subsets(metadata_path),
              category: normalize_category(metadata.category),
              designer: metadata.designer,
              license: normalize_license(metadata.license),
              license_text: license_info[:text],
              description: description,
              homepage: license_info[:homepage],
              font_file_data: font_files_data,
            )
          end

          # Parse all font files in a family directory
          #
          # @param family_dir [Pathname] the family directory path
          # @param metadata [Models::Metadata] the parsed metadata model
          # @return [Array<Hash>] array of font file data
          def parse_font_files(family_dir, metadata)
            font_data = []

            metadata.filenames.each do |filename|
              font_path = family_dir.join(filename)
              next unless font_path.exist?

              begin
                font_file = Otf::FontFile.new(font_path.to_s)
                font_data << {
                  filename: filename,
                  family_name: font_file.family_name,
                  type: font_file.type,
                  full_name: font_file.full_name,
                  post_script_name: font_file.post_script_name,
                  version: font_file.version,
                  copyright: font_file.copyright,
                  description: font_file.description,
                }
              rescue StandardError => e
                warn "Warning: Failed to parse font file #{filename}: "\
                     "#{e.message}"
              end
            end

            font_data
          end

          # Extract variant names from metadata
          #
          # @param metadata [Models::Metadata] the parsed metadata model
          # @return [Array<String>] array of variant names
          def extract_variants(metadata)
            return [] unless metadata.fonts

            fonts_array = metadata.fonts.is_a?(Array) ? metadata.fonts : [metadata.fonts]
            fonts_array.map do |font|
              weight = font.respond_to?(:weight) ? font.weight : font["weight"]
              style = font.respond_to?(:style) ? font.style : font["style"]
              variant_name(weight, style)
            end.compact.uniq
          end

          # Generate variant name from weight and style
          #
          # @param weight [Integer] the font weight
          # @param style [String] the font style
          # @return [String] the variant name
          def variant_name(weight, style)
            return "regular" if weight == 400 && style == "normal"
            return "italic" if weight == 400 && style == "italic"
            return weight.to_s if style == "normal"

            "#{weight}#{style}"
          end

          # Extract subsets from METADATA.pb file
          #
          # @param metadata_path [Pathname] path to METADATA.pb
          # @return [Array<String>] array of subsets
          def extract_subsets(metadata_path)
            content = File.read(metadata_path)
            content.scan(/subsets:\s*"([^"]*)"/).flatten
          end

          # Normalize category from METADATA.pb format to API format
          #
          # @param category [String] the category from METADATA.pb
          # @return [String] normalized category
          def normalize_category(category)
            return nil unless category

            case category.upcase
            when "SANS_SERIF"
              "sans-serif"
            when "SERIF"
              "serif"
            when "DISPLAY"
              "display"
            when "HANDWRITING"
              "handwriting"
            when "MONOSPACE"
              "monospace"
            else
              category.downcase.tr("_", "-")
            end
          end

          # Normalize license from METADATA.pb format
          #
          # @param license [String] the license from METADATA.pb
          # @return [String] normalized license
          def normalize_license(license)
            return nil unless license

            case license.upcase
            when "APACHE2"
              "Apache-2.0"
            when "OFL"
              "OFL-1.1"
            when "UFL"
              "UFL-1.0"
            else
              license
            end
          end

          # Read license file from family directory
          #
          # @param family_dir [Pathname] the family directory path
          # @return [Hash] hash with :text and :homepage
          def read_license(family_dir)
            license_files = %w[OFL.txt LICENSE.txt LICENCE.txt UFL.txt]
            license_file = license_files.find do |name|
              family_dir.join(name).exist?
            end

            return { text: nil, homepage: nil } unless license_file

            content = File.read(family_dir.join(license_file),
                                encoding: "UTF-8")

            # Extract homepage URL from license if present
            homepage = content[/https?:\/\/[^\s\)]+/]

            { text: content, homepage: homepage }
          end

          # Read description from DESCRIPTION.en_us.html
          #
          # @param family_dir [Pathname] the family directory path
          # @return [String, nil] the description text
          def read_description(family_dir)
            desc_file = family_dir.join("DESCRIPTION.en_us.html")
            return nil unless desc_file.exist?

            content = File.read(desc_file, encoding: "UTF-8")

            # Strip HTML tags and clean up
            content.gsub(/<[^>]*>/, " ")
                   .gsub(/\s+/, " ")
                   .strip
          end
        end
      end
    end
  end
end