module Fontist
  module Manifest
    class Locations
      def initialize(manifest)
        @manifest = manifest
      end

      def self.from_file(file, **keywords)
        raise Fontist::Errors::ManifestCouldNotBeFoundError unless File.exist?(file)

        manifest = YAML.load_file(file)
        raise Fontist::Errors::ManifestCouldNotBeReadError unless manifest.is_a?(Hash)

        from_hash(manifest, **keywords)
      end

      def self.from_hash(manifest, **keywords)
        if keywords.empty?
          new(manifest).call
        else
          new(manifest, **keywords).call
        end
      end

      def call
        font_names.zip(font_paths).to_h
      end

      private

      attr_reader :manifest

      def font_names
        manifest.keys
      end

      def font_paths
        manifest.map do |font, styles|
          styles_to_ary = [styles].flatten
          style_paths_map(font, styles_to_ary)
        end
      end

      def style_paths_map(font, names)
        paths = style_paths(font, names)
        names.zip(paths).to_h
      end

      def style_paths(font, names)
        names.map do |style|
          file_paths(font, style)
        end
      end

      def file_paths(font, style)
        Fontist::SystemFont.find_with_name(font, style).transform_keys(&:to_s)
      end
    end
  end
end
