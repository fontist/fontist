require "fontist/import"
require_relative "recursive_extraction"
require_relative "otf/font_file"
require_relative "files/collection_file"
require_relative "helpers/hash_helper"
require_relative "formula_builder"

module Fontist
  module Import
    class CreateFormula
      FONT_PATTERN = /(\.ttf|\.otf)$/i.freeze
      FONT_COLLECTION_PATTERN = /\.ttc$/i.freeze
      LICENSE_PATTERN = /(OFL\.txt|UFL\.txt|LICENSE\.txt)$/i.freeze

      def initialize(url, options = {})
        @url = url
        @options = options
      end

      def call
        save(formula)
      end

      private

      def formula
        builder = FormulaBuilder.new
        builder.url = @url
        builder.archive = download(@url)
        builder.extractor = extractor(builder.archive)
        builder.options = @options
        builder.font_files = font_files(builder.extractor)
        builder.font_collection_files = font_collection_files(builder.extractor)
        builder.license_text = license_texts(builder.extractor).first
        builder.formula
      end

      def download(url)
        return url if File.exist?(url)

        Fontist::Utils::Downloader.download(url, progress_bar: true).path
      end

      def extractor(archive)
        RecursiveExtraction.new(archive)
      end

      def font_files(extractor)
        extractor.extract(FONT_PATTERN) do |path|
          Otf::FontFile.new(path)
        end
      end

      def font_collection_files(extractor)
        extractor.extract(FONT_COLLECTION_PATTERN) do |path|
          Files::CollectionFile.new(path)
        end
      end

      def license_texts(extractor)
        extractor.extract(LICENSE_PATTERN) do |path|
          File.read(path)
        end
      end

      def save(hash)
        filename = Import.name_to_filename(hash[:name])
        yaml = YAML.dump(Helpers::HashHelper.stringify_keys(hash))
        File.write(filename, yaml)
        filename
      end
    end
  end
end
