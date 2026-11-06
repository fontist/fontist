require "fileutils"

module Fontist
  module FontOperations
    # Writes a static instance of a variable font at the given axis values,
    # validated against the font's own fvar axes.
    module Instance
      PAIR = /\A([A-Za-z][A-Za-z0-9 ]{2,3})=(-?\d+(\.\d+)?)\z/

      module_function

      # @param source [String] variable font file
      # @param output [String] where to write the static instance
      # @param coordinates [Hash{String=>Numeric}, String] {"wght" => 300}
      #   or "wght=300,wdth=90"
      # @return [String] output path
      def call(source, output, coordinates:)
        FontOperations.guard("Instancing") do
          raise Errors::SourceNotFoundError, source unless File.exist?(source)

          coords = coordinates.is_a?(String) ? parse(coordinates) : coordinates
          raise Errors::InstanceError, "No axis values given" if coords.empty?

          write(source, output, normalize(coords))
        end
      end

      # "wght=300,wdth=90" => {"wght" => 300.0, "wdth" => 90.0}
      def parse(value)
        value.to_s.split(",").map(&:strip).reject(&:empty?).to_h do |pair|
          match = PAIR.match(pair)
          unless match
            raise Errors::InstanceError,
                  "Invalid instance '#{pair}'. Use e.g. wght=300,wdth=90"
          end

          [match[1], match[2].to_f]
        end
      end

      # File name for the instance: "Font[wght].ttf" => "Font-wght300.ttf"
      def file_name(name, coordinates)
        ext = File.extname(name)
        base = File.basename(name, ext).sub(/\[[^\]]*\]\z/, "")
        suffix = coordinates.map { |tag, val| "#{tag}#{number(val)}" }.join("-")
        "#{base}-#{suffix}#{ext}"
      end

      def normalize(coords)
        coords.to_h { |tag, value| [tag.to_s, Float(value)] }
      rescue ArgumentError, TypeError
        raise Errors::InstanceError, "Axis values must be numbers"
      end

      def write(source, output, coords)
        font = Fontisan::FontLoader.load(source)
        unless font.has_table?("fvar")
          raise Errors::InstanceError,
                "#{File.basename(source)} is not a variable font"
        end

        validate!(Fontisan::Variable::Instancer.new(font), coords,
                  File.basename(source))
        FileUtils.mkdir_p(File.dirname(output))
        File.binwrite(output, instance_bytes(source, coords))
        output
      end

      def instance_bytes(source, coords)
        Fontisan::Reference.instance(source, coords: coords)
      end

      def validate!(instancer, coords, name)
        axes = instancer.axes.to_h { |axis| [axis.tag, axis] }
        coords.each do |tag, value|
          axis = axes[tag] || raise(Errors::InstanceError,
                                    "#{name} has no axis '#{tag}' " \
                                    "(axes: #{axes.keys.join(', ')})")
          check_range!(axis, value, name)
        end
      end

      def check_range!(axis, value, name)
        return if value.between?(axis.minimum, axis.maximum)

        raise Errors::InstanceError,
              "#{axis.tag}=#{number(value)} is out of range for #{name}: " \
              "#{number(axis.minimum)}-#{number(axis.maximum)}"
      end

      def number(value)
        format("%g", value)
      end
    end
  end
end
