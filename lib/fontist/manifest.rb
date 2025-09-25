require "lutaml/model"

module Fontist
  class ManifestFont < Lutaml::Model::Serializable
    attribute :name, :string
    attribute :styles, :string, collection: true

    key_value do
      map "name", to: :name
      map "styles", to: :styles
    end

    def style_paths
      Array(styles).flat_map do |style|
        find_font_with_name(name, style)
      end.compact
    end

    def group_paths
      style_paths.group_by(&:type)
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

    def to_response
      return self if group_paths.nil? || group_paths.empty?

      ManifestResponseFont.new(
        name: name,
        styles: group_paths.map do |type, details|
          ManifestResponseFontStyle.new(
            type: type,
            full_name: details["full_name"],
            paths: details["paths"],
          )
        end,
      )
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

    def self.from_file(path)
      Fontist.ui.debug("Manifest: #{path}")

      raise Fontist::Errors::ManifestCouldNotBeFoundError, "Manifest file not found: #{path}" unless File.exist?(path)

      file_content = File.read(path).strip
      if file_content.empty?
        raise Fontist::Errors::ManifestCouldNotBeReadError, "Manifest file is empty: #{path}"
      end

      manifest_model = self.from_yaml(file_content)

      # Check if the file was effectively empty (no fonts defined)
      # TODO: There is a bug here:
      # lutaml-model-0.7.5/lib/lutaml/model/serialize.rb:635:in `method_missing': undefined method `empty?' for an instance of Fontist::ManifestRequestFont (NoMethodError)
      if manifest_model.nil? || manifest_model.fonts.empty?
        raise Fontist::Errors::ManifestCouldNotBeReadError, "Manifest #{path} has no fonts defined."
      end

      manifest_model.to_response
    rescue StandardError => e
      raise Fontist::Errors::ManifestCouldNotBeReadError, "Manifest file could not be read: #{e.message}"
    end

    def install(confirmation: "no", hide_licenses: false, no_progress: false)
      Array(fonts).to_h do |font|
        paths = font.group_paths
        if paths.length < fonts.length
          font.install(confirmation: confirmation, hide_licenses: hide_licenses, no_progress: no_progress)
          paths = font.group_paths
        end

        [font.name, paths]
      end
    end

    def to_response
      ManifestResponse.new.tap do |response|
        response.fonts = Array(fonts).map do |font|
          font.to_response
        end
      end
    end

    def to_file(path)
      File.mkdir_p(File.dirname(path))
      File.write(path, to_yaml)
    end
  end
end
