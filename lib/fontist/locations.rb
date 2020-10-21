module Fontist
  class Locations
    def initialize(manifest)
      @manifest = manifest
    end

    def self.call(manifest)
      new(manifest).call
    end

    def call
      font_names.zip(font_paths).to_h
    end

    private

    def font_names
      fonts.keys
    end

    def fonts
      @fonts ||= begin
        unless File.exist?(@manifest)
          raise Fontist::Errors::ManifestCouldNotBeFoundError
        end

        fonts = YAML.load_file(@manifest)
        unless fonts.is_a?(Hash)
          raise Fontist::Errors::ManifestCouldNotBeReadError
        end

        fonts
      end
    end

    def font_paths
      fonts.map do |font, styles|
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
      Fontist::SystemFont.find_with_style(font, style)
    end
  end
end
