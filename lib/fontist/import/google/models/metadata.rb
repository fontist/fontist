# frozen_string_literal: true

require "lutaml/model"
require_relative "font_file_metadata"
require_relative "axis_metadata"
require_relative "source_metadata"

module Fontist
  module Import
    module Google
      module Models
        # Rich domain model for Google Fonts metadata from METADATA.pb
        #
        # This class represents complete font family metadata with:
        # - Validation methods
        # - Business logic for font classification
        # - Query methods for font properties
        # - Transformation methods for formula generation
        #
        # @example Basic usage
        #   metadata = Metadata.new(name: "Roboto", designer: "Google")
        #   metadata.valid? # => true
        #   metadata.variable_font? # => false
        #
        # @example With validation
        #   metadata = Metadata.new(name: "")
        #   metadata.validate! # raises ValidationError
        #
        # @example Loading from file
        #   metadata = Metadata.from_file("/path/to/METADATA.pb")
        class Metadata < Lutaml::Model::Serializable
          # Core Attributes
          attribute :name, :string
          attribute :designer, :string
          attribute :license, :string
          attribute :category, :string
          attribute :date_added, :string

          # Collections
          attribute :fonts, FontFileMetadata, collection: true
          attribute :subsets, :string, collection: true
          attribute :axes, AxisMetadata, collection: true
          attribute :languages, :string, collection: true

          # Complex Attributes
          attribute :source, SourceMetadata
          attribute :registry_default_overrides, Lutaml::Model::Type::Hash

          # Flags
          attribute :is_noto, :boolean
          attribute :primary_script, :string

          key_value do
            map "name", to: :name
            map "designer", to: :designer
            map "license", to: :license
            map "category", to: :category
            map "date_added", to: :date_added
            map "fonts", to: :fonts
            map "subsets", to: :subsets
            map "axes", to: :axes
            map "source", to: :source
            map "registry_default_overrides", to: :registry_default_overrides
            map "is_noto", to: :is_noto
            map "languages", to: :languages
            map "primary_script", to: :primary_script
          end

          # Class Methods (Factory & Creation)

          # Load metadata from METADATA.pb file
          #
          # @param file_path [String] Path to METADATA.pb file
          # @return [Metadata] parsed metadata object
          # @raise [ParseError] if file cannot be parsed
          def self.from_file(file_path)
            require "unibuf"
            require_relative "../metadata_adapter"

            unibuf_message = Unibuf.parse_textproto_file(file_path)
            MetadataAdapter.adapt(unibuf_message)
          end

          # Load metadata from content string
          #
          # @param content [String] METADATA.pb file content
          # @return [Metadata] parsed metadata object
          # @raise [ParseError] if content cannot be parsed
          def self.from_content(content)
            require "unibuf"
            require_relative "../metadata_adapter"

            unibuf_message = Unibuf.parse_textproto(content)
            MetadataAdapter.adapt(unibuf_message)
          end

          # Validation Methods

          # Validate metadata completeness and correctness
          #
          # @raise [ValidationError] if validation fails
          # @return [true] if valid
          def validate!
            errors = validation_errors
            raise ValidationError, errors.join(", ") unless errors.empty?

            true
          end

          # Check if metadata is valid
          #
          # @return [Boolean] true if valid, false otherwise
          def valid?
            validation_errors.empty?
          end

          # Get all validation errors
          #
          # @return [Array<String>] array of error messages
          def validation_errors
            errors = []
            errors << "name is required" if name.nil? || name.empty?
            errors << "designer is required" if designer.nil? || designer.empty?
            errors << "license is required" if license.nil? || license.empty?
            errors << "category is required" if category.nil? || category.empty?
            errors << "date_added is required" if date_added.nil? || date_added.empty?
            errors << "at least one font file is required" if fonts.nil? || fonts_array.empty?
            errors << "invalid license type" unless valid_license?
            errors << "invalid category" unless valid_category?
            errors << "invalid date format" unless valid_date_format?
            errors
          end

          # Font Classification Methods

          # Check if this is a variable font
          #
          # @return [Boolean] true if has variable font axes
          def variable_font?
            !axes.nil? && !axes_array.empty?
          end

          # Check if this is a static font
          #
          # @return [Boolean] true if has no variable font axes
          def static_font?
            !variable_font?
          end

          # Check if font is a Noto font
          #
          # @return [Boolean] true if is_noto flag is set or name starts with "Noto"
          def noto_font?
            is_noto == true || name&.start_with?("Noto")
          end

          # Check if metadata is complete (has all optional fields filled)
          #
          # @return [Boolean] true if has source, axes, languages, etc.
          def complete?
            !source.nil? &&
              !subsets.nil? && !subsets.empty? &&
              (!variable_font? || !axes.nil?)
          end

          # Check if metadata is minimal (only required fields)
          #
          # @return [Boolean] true if only has required fields
          def minimal?
            source.nil? &&
              (subsets.nil? || subsets.empty?) &&
              (languages.nil? || languages.empty?)
          end

          # Font Property Methods

          # Get all font filenames
          #
          # @return [Array<String>] array of font filenames
          def filenames
            fonts_array.map(&:filename)
          end

          # Get all variable font axis tags
          #
          # @return [Array<String>] array of axis tags (e.g., ["wght", "wdth"])
          def axis_tags
            axes_array.map(&:tag)
          end

          # Get number of font files
          #
          # @return [Integer] count of font files
          def font_count
            fonts_array.count
          end

          # Get number of variable font axes
          #
          # @return [Integer] count of axes (0 for static fonts)
          def axis_count
            axes_array.count
          end

          # Get number of supported languages
          #
          # @return [Integer] count of languages
          def language_count
            languages_array.count
          end

          # Get number of supported subsets
          #
          # @return [Integer] count of subsets
          def subset_count
            subsets_array.count
          end

          # License & Legal Methods

          # Check if license is open source
          #
          # @return [Boolean] true if OFL or Apache license
          def open_license?
            %w[OFL APACHE].include?(license)
          end

          # Check if license requires acceptance
          #
          # @return [Boolean] true if UFL or other non-open license
          def requires_license_agreement?
            !open_license?
          end

          # Get license name
          #
          # @return [String] human-readable license name
          def license_name
            case license
            when "OFL" then "SIL Open Font License"
            when "APACHE" then "Apache License 2.0"
            when "UFL" then "Ubuntu Font License"
            else license
            end
          end

          # Font File Query Methods

          # Find font by style and weight
          #
          # @param style [String] font style ("normal", "italic")
          # @param weight [Integer] font weight (100-900)
          # @return [FontFileMetadata, nil] matching font or nil
          def find_font(style:, weight:)
            fonts_array.find { |f| f.style == style && f.weight == weight }
          end

          # Get regular/normal font
          #
          # @return [FontFileMetadata, nil] normal weight 400 font
          def regular_font
            find_font(style: "normal", weight: 400)
          end

          # Get bold font
          #
          # @return [FontFileMetadata, nil] normal weight 700 font
          def bold_font
            find_font(style: "normal", weight: 700)
          end

          # Get italic font
          #
          # @return [FontFileMetadata, nil] italic weight 400 font
          def italic_font
            find_font(style: "italic", weight: 400)
          end

          # Get all font styles
          #
          # @return [Array<String>] unique font styles
          def font_styles
            fonts_array.map(&:style).uniq
          end

          # Get all font weights
          #
          # @return [Array<Integer>] unique font weights
          def font_weights
            fonts_array.map(&:weight).uniq.sort
          end

          # Check if has italic variants
          #
          # @return [Boolean] true if has any italic fonts
          def has_italics?
            fonts_array.any? { |f| f.style == "italic" }
          end

          # Variable Font Methods

          # Find axis by tag
          #
          # @param tag [String] axis tag (e.g., "wght", "wdth")
          # @return [AxisMetadata, nil] matching axis or nil
          def find_axis(tag)
            axes_array.find { |a| a.tag == tag }
          end

          # Get weight axis
          #
          # @return [AxisMetadata, nil] weight axis
          def weight_axis
            find_axis("wght")
          end

          # Get width axis
          #
          # @return [AxisMetadata, nil] width axis
          def width_axis
            find_axis("wdth")
          end

          # Get slant axis
          #
          # @return [AxisMetadata, nil] slant axis
          def slant_axis
            find_axis("slnt")
          end

          # Check if has weight axis
          #
          # @return [Boolean] true if has wght axis
          def variable_weight?
            !weight_axis.nil?
          end

          # Check if has width axis
          #
          # @return [Boolean] true if has wdth axis
          def variable_width?
            !width_axis.nil?
          end

          # Check if has slant/italic axis
          #
          # @return [Boolean] true if has slnt axis
          def variable_slant?
            !slant_axis.nil?
          end

          # Get registry default override for axis
          #
          # @param axis_tag [String] axis tag
          # @return [Float, nil] override value or nil
          def registry_override(axis_tag)
            return nil unless registry_default_overrides

            registry_default_overrides[axis_tag]
          end

          # Check if has registry overrides
          #
          # @return [Boolean] true if has any overrides
          def has_registry_overrides?
            !registry_default_overrides.nil? && !registry_default_overrides.empty?
          end

          # Transformation Methods

          # Convert to hash for formula generation
          #
          # @return [Hash] hash representation suitable for formulas
          def to_formula_hash
            {
              name: name,
              designer: designer,
              license: license,
              license_url: source&.repository_url,
              open_license: open_license?,
              category: category,
              date_added: date_added,
              fonts: fonts_array.map(&:to_h),
              subsets: subsets_array,
              axes: axes_array.map(&:to_h),
              source: source&.to_h,
              registry_default_overrides: registry_default_overrides,
              languages: languages_array,
              primary_script: primary_script,
            }
          end

          # Convert to display format
          #
          # @return [String] human-readable representation
          def to_s
            parts = ["#{name} by #{designer}"]
            parts << "(Variable Font)" if variable_font?
            parts << "(Noto)" if noto_font?
            parts << "- #{font_count} files"
            parts << "- #{axis_count} axes" if variable_font?
            parts << "- #{language_count} languages" if language_count.positive?
            parts.join(" ")
          end

          # Comparison Methods

          # Compare with another metadata object
          #
          # @param other [Metadata] other metadata object
          # @return [Boolean] true if same family
          def ==(other)
            return false unless other.is_a?(Metadata)

            name == other.name && designer == other.designer
          end

          # Hash code for using as hash key
          #
          # @return [Integer] hash code
          def hash
            [name, designer].hash
          end

          alias eql? ==

          private

          # Helper Methods for Array Normalization

          def fonts_array
            return [] unless fonts

            fonts.is_a?(Array) ? fonts : [fonts]
          end

          def axes_array
            return [] unless axes

            axes.is_a?(Array) ? axes : [axes]
          end

          def subsets_array
            return [] unless subsets

            subsets.is_a?(Array) ? subsets : [subsets]
          end

          def languages_array
            return [] unless languages

            languages.is_a?(Array) ? languages : [languages]
          end

          # Validation Helper Methods

          def valid_license?
            return true if license.nil?

            %w[OFL APACHE UFL].include?(license)
          end

          def valid_category?
            return true if category.nil?

            %w[SANS_SERIF SERIF DISPLAY HANDWRITING
               MONOSPACE].include?(category)
          end

          def valid_date_format?
            return true if date_added.nil?

            date_added.match?(/^\d{4}-\d{2}-\d{2}$/)
          end
        end

        # Custom error for validation failures
        class ValidationError < StandardError; end
      end
    end
  end
end
