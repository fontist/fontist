require "lutaml/model"

module Fontist
  class ExtractOptions < Lutaml::Model::Serializable
    attribute :file, :string
    attribute :fonts_sub_dir, :string

    key_value do
      map "file", to: :file
      map "fonts_sub_dir", to: :fonts_sub_dir
    end
  end

  class Extract < Lutaml::Model::Serializable
    attribute :format, :string
    attribute :file, :string
    attribute :options, ExtractOptions, collection: true

    key_value do
      map "format", to: :format
      map "file", to: :file
      map "options", to: :options
    end

    def empty?
      format.nil? && file.nil? && options_empty?
    end

    private

    def options_empty?
      return true if options.nil?
      return options.empty? if options.respond_to?(:empty?)
      return options.file.nil? && options.fonts_sub_dir.nil? if options.is_a?(ExtractOptions)
      false
    end
  end
end
