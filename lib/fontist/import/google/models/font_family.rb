require "lutaml/model"
require_relative "axis"

module Fontist
  module Import
    module Google
      module Models
        class FontFamily < Lutaml::Model::Serializable
          attribute :family, :string
          attribute :variants, :string, collection: true
          attribute :subsets, :string, collection: true
          attribute :version, :string
          attribute :last_modified, :string
          attribute :files_data, :string
          attribute :category, :string
          attribute :kind, :string
          attribute :menu, :string
          attribute :axes, Axis, collection: true

          # GitHub-specific fields
          attribute :designer, :string
          attribute :license, :string
          attribute :license_text, :string
          attribute :description, :string
          attribute :homepage, :string
          attribute :font_file_data, :string

          json do
            map "family", to: :family
            map "variants", to: :variants
            map "subsets", to: :subsets
            map "version", to: :version
            map "lastModified", to: :last_modified
            map "files", to: :files_data
            map "category", to: :category
            map "kind", to: :kind
            map "menu", to: :menu
            map "axes", to: :axes
          end

          # Initialize with support for files as Hash
          def initialize(**attributes)
            if attributes.key?(:files)
              files_value = attributes.delete(:files)
              attributes[:files_data] = files_value
            end
            super(**attributes)
          end

          # Get files as a Hash
          #
          # @return [Hash] hash of variant names to URLs
          def files
            return {} if files_data.nil?
            return {} if files_data.respond_to?(:empty?) && files_data.empty?
            return files_data if files_data.is_a?(Hash)

            # Try to parse as JSON first
            begin
              return JSON.parse(files_data)
            rescue JSON::ParserError, TypeError
              # If it fails, convert Ruby hash syntax to JSON and parse
              if files_data.is_a?(String)
                # Convert Ruby hash syntax (=>) to JSON syntax (:)
                json_str = files_data.gsub("=>", ":")
                begin
                  return JSON.parse(json_str)
                rescue JSON::ParserError
                  {}
                end
              end
              {}
            end
          end

          # Set files from a Hash or JSON string
          #
          # @param value [Hash, String] the files data
          def files=(value)
            self.files_data = value
          end

          # Check if this is a variable font family
          # Variable fonts have axes defined
          #
          # @return [Boolean] true if axes are present and not empty
          def variable_font?
            !axes.nil? && !axes.empty?
          end

          # Get all variants in a specific format
          # Note: This requires the files hash to contain URLs with
          # the format extension
          #
          # @param format [Symbol, String] the format (:ttf or :woff2)
          # @return [Hash] hash of variant name to URL for the format
          def variants_by_format(format)
            return {} if files.nil?

            extension = format_extension(format)
            files.select do |_variant_name, url|
              url.end_with?(extension)
            end
          end

          # Find an axis by its tag
          #
          # @param tag [String] the axis tag (e.g., "wght", "wdth")
          # @return [Axis, nil] the axis if found, nil otherwise
          def axis_by_tag(tag)
            return nil unless variable_font?

            axes.find { |axis| axis.tag == tag }
          end

          # Get all weight axes
          #
          # @return [Array<Axis>] array of weight axes
          def weight_axes
            return [] unless variable_font?

            axes.select(&:weight_axis?)
          end

          # Get all width axes
          #
          # @return [Array<Axis>] array of width axes
          def width_axes
            return [] unless variable_font?

            axes.select(&:width_axis?)
          end

          # Get all slant axes
          #
          # @return [Array<Axis>] array of slant axes
          def slant_axes
            return [] unless variable_font?

            axes.select(&:slant_axis?)
          end

          # Get all custom (non-standard) axes
          #
          # @return [Array<Axis>] array of custom axes
          def custom_axes
            return [] unless variable_font?

            axes.select(&:custom_axis?)
          end

          # Get the number of axes
          #
          # @return [Integer] the number of axes
          def axes_count
            variable_font? ? axes.length : 0
          end

          # Get all variant names
          #
          # @return [Array<String>] array of variant names
          def variant_names
            variants || []
          end

          # Get all file URLs
          #
          # @return [Array<String>] array of file URLs
          def file_urls
            files ? files.values : []
          end

          # Check if a specific variant exists
          #
          # @param variant_name [String] the variant name
          # @return [Boolean] true if variant exists
          def variant_exists?(variant_name)
            variant_names.include?(variant_name)
          end

          # Get URL for a specific variant
          #
          # @param variant_name [String] the variant name
          # @return [String, nil] the URL if found, nil otherwise
          def variant_url(variant_name)
            return nil if files.nil? || files.empty?

            files[variant_name]
          end

          # Get a human-readable summary
          #
          # @return [String] summary of the font family
          def summary
            parts = [family, version]
            parts << "(#{axes_count} axes)" if variable_font?
            parts.join(" ")
          end

          private

          # Get the file extension for a format
          #
          # @param format [Symbol, String] the format
          # @return [String] the file extension
          def format_extension(format)
            case format.to_sym
            when :ttf
              ".ttf"
            when :woff2
              ".woff2"
            else
              ""
            end
          end
        end
      end
    end
  end
end