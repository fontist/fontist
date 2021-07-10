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
        styles = style_paths(font, names)
        group_paths(styles)
      end

      def style_paths(font, names)
        names.flat_map do |style|
          file_paths(font, style) || empty_paths(style)
        end
      end

      def group_paths(styles)
        styles.group_by { |s| s[:type] }
          .transform_values { |group| style(group) }
      end

      def style(styles)
        { "full_name" => styles.first[:full_name],
          "paths" => styles.map { |x| x[:path] } }.compact
      end

      def file_paths(font, style)
        find_font_with_name(font, style).tap do |x|
          if x.nil?
            raise Errors::MissingFontError.new(font, style)
          end
        end
      end

      def find_font_with_name(font, style)
        Fontist::SystemFont.find_styles(font, style)
      end

      def empty_paths(style)
        [{ "full_name" => nil, "type" => style, "path" => nil }]
      end
    end
  end
end
