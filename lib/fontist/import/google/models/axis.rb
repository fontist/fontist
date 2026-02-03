require "lutaml/model"

module Fontist
  module Import
    module Google
      module Models
        class Axis < Lutaml::Model::Serializable
          attribute :tag, :string
          attribute :start, :float
          attribute :end, :float

          json do
            map "tag", to: :tag
            map "start", to: :start
            map "end", to: :end
          end

          # Standard OpenType variable font axis tags
          STANDARD_TAGS = {
            "wght" => :weight,
            "wdth" => :width,
            "slnt" => :slant,
            "ital" => :italic,
            "opsz" => :optical_size,
          }.freeze

          # Check if this is the weight axis
          #
          # @return [Boolean] true if tag is 'wght'
          def weight_axis?
            tag == "wght"
          end

          # Check if this is the width axis
          #
          # @return [Boolean] true if tag is 'wdth'
          def width_axis?
            tag == "wdth"
          end

          # Check if this is the slant axis
          #
          # @return [Boolean] true if tag is 'slnt'
          def slant_axis?
            tag == "slnt"
          end

          # Check if this is a custom (non-standard) axis
          #
          # @return [Boolean] true if tag is not a standard OpenType axis
          def custom_axis?
            !STANDARD_TAGS.key?(tag)
          end

          # Get the range of values as an array
          #
          # @return [Array<Float>] [start, end]
          def range
            [start, self.end]
          end

          # Get a human-readable description of the axis
          #
          # @return [String] description of the axis
          def description
            type = STANDARD_TAGS[tag] || "custom"
            start_val = format_value(start)
            end_val = format_value(self.end)
            "#{tag} (#{type}): #{start_val}–#{end_val}"
          end

          private

          # Format a numeric value without unnecessary decimals
          #
          # @param value [Float, Integer] the value to format
          # @return [String] formatted value
          def format_value(value)
            return value.to_s if value.nil?

            if value == value.to_i
              value.to_i.to_s
            else
              value.to_s
            end
          end
        end
      end
    end
  end
end
