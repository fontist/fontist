require "lutaml/model"

module Fontist
  class ManifestFont < Lutaml::Model::Serializable
    attribute :name, :string
    attribute :styles, :string, collection: true

    key_value do
      map "name", to: :name
      map "styles", to: :styles
    end
  end

  # Manifest class for managing font manifests.
  class Manifest < Lutaml::Model::Collection
    instances :fonts, ManifestFont

    # TODO: Re-enable these when
    # key_value do
    #   map to: :fonts, root_mappings: {
    #     name: :key,
    #     styles: :value,
    #   }
    # end

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
      if manifest_model.nil? || manifest_model.empty?
        raise Fontist::Errors::ManifestCouldNotBeReadError, "Manifest #{path} has no fonts defined."
      end

      manifest_model
    end

    def to_file(path)
      File.mkdir_p(File.dirname(path))
      File.write(path, to_yaml)
    end
  end
end
