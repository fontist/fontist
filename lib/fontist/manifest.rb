require "lutaml/model"

module Fontist
  class ManifestFont < Lutaml::Model::Serializable
    attribute :name, :string
    attribute :styles, :string, collection: true

    def style_paths(locations: false)
      ary = Array(styles)
      (ary.empty? ? [nil] : ary).flat_map do |style|
        find_font_with_name(name, style).tap do |x|
          raise Errors::MissingFontError.new(name, style) if x.nil? && locations
        end
      end.compact
    end

    def group_paths(locations: false)
      style_paths(locations: locations).group_by(&:type)
        .transform_values { |group| style(group) }
    end

    def style(styles_ary)
      { "full_name" => styles_ary.first.full_name,
        "paths" => styles_ary.filter_map(&:path) }
    end

    def find_font_with_name(font, style)
      Fontist::SystemFont.find_styles(font, style)
    end

    def install(confirmation: "no", hide_licenses: false, no_progress: false)
      Fontist::Font.install(
        name,
        force: true,
        confirmation: confirmation,
        hide_licenses: hide_licenses,
        no_progress: no_progress,
      )
    end

    def to_response(locations: false)
      groups = group_paths(locations: locations)

      return self if groups.empty?

      ManifestResponseFont.new(
        name: name,
        styles: groups.map do |type, details|
          ManifestResponseFontStyle.new(
            type: type,
            full_name: details["full_name"],
            paths: details["paths"],
          )
        end,
      )
    end

    def group_paths_empty?
      group_paths.compact.empty?
    end
  end

  # Manifest class for managing font manifests.
  class Manifest < Lutaml::Model::Collection
    instances :fonts, ManifestFont

    # TODO: Re-enable these when
    key_value do
      map to: :fonts, root_mappings: {
        name: :key,
        styles: :value,
      }
    end

    def self.from_file(path, locations: false)
      Fontist.ui.debug("Manifest: #{path}")

      unless File.exist?(path)
        raise Fontist::Errors::ManifestCouldNotBeFoundError,
              "Manifest file not found: #{path}"
      end

      file_content = File.read(path).strip

      if file_content.empty?
        raise Fontist::Errors::ManifestCouldNotBeReadError,
              "Manifest file is empty: #{path}"
      end

      manifest_model = begin
        from_yaml(file_content)
      rescue StandardError => e
        raise Fontist::Errors::ManifestCouldNotBeReadError,
              "Manifest file could not be read: #{e.message}"
      end

      manifest_model.to_response(locations: locations)
    end

    def self.font_class
      ManifestFont
    end

    def fonts_casted
      Array(fonts).map do |font|
        self.class.font_class === font ? font : self.class.font_class.new(font.to_h)
      end
    end

    def install(confirmation: "no", hide_licenses: false, no_progress: false)
      fonts_casted.each do |font|
        paths = font.group_paths
        if paths.length < fonts_casted.length
          font.install(confirmation: confirmation,
                       hide_licenses: hide_licenses, no_progress: no_progress)
        end
      end
      to_response
    end

    def to_response(locations: false)
      return self if fonts_casted.any?(&:group_paths_empty?) && !locations

      ManifestResponse.new.tap do |response|
        response.fonts = fonts_casted.map do |font|
          font.to_response(locations: locations)
        end
      end
    end

    def to_file(path)
      File.mkdir_p(File.dirname(path))
      File.write(path, to_yaml)
    end
  end
end
