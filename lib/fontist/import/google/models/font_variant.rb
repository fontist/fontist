require "lutaml/model"

module Fontist
  module Import
    module Google
      module Models
        class FontVariant < Lutaml::Model::Serializable
          attribute :name, :string
          attribute :url, :string
          attribute :format, :string

          json do
            map "name", to: :name
            map "url", to: :url
            map "format", to: :format
          end

          # Valid font formats
          VALID_FORMATS = %i[ttf woff2].freeze

          # Check if this is a variable font
          # Note: This requires access to the parent family's axes
          # Should be called with the parent family as context
          #
          # @param family [FontFamily] the parent font family
          # @return [Boolean] true if the parent family has axes
          def variable_font?(family = nil)
            return false if family.nil?

            family.variable_font?
          end

          # Get the file extension for this variant
          #
          # @return [String] the file extension (.ttf or .woff2)
          def extension
            case format.to_sym
            when :ttf
              ".ttf"
            when :woff2
              ".woff2"
            else
              ""
            end
          end

          # Check if format is TTF
          #
          # @return [Boolean] true if format is :ttf
          def ttf?
            format.to_sym == :ttf
          end

          # Check if format is WOFF2
          #
          # @return [Boolean] true if format is :woff2
          def woff2?
            format.to_sym == :woff2
          end

          # Get a human-readable description of the variant
          #
          # @return [String] description of the variant
          def description
            "#{name} (#{format})"
          end

          # Validate the format
          #
          # @return [Boolean] true if format is valid
          def valid_format?
            VALID_FORMATS.include?(format.to_sym)
          end
        end
      end
    end
  end
end
