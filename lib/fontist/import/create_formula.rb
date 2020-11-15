require "fontist/import"
require_relative "recursive_extraction"
require_relative "otf/font_file"
require_relative "files/collection_file"
require_relative "helpers/hash_helper"
require_relative "formula_builder"

module Fontist
  module Import
    class CreateFormula
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
        builder.archive = archive
        builder.extractor = extractor
        builder.options = @options
        builder.font_files = extractor.font_files
        builder.font_collection_files = extractor.font_collection_files
        builder.license_text = extractor.license_text
        builder.formula
      end

      def extractor
        @extractor ||=
          RecursiveExtraction.new(archive, subarchive: @options[:subarchive])
      end

      def archive
        @archive ||= download(@url)
      end

      def download(url)
        return url if File.exist?(url)

        Fontist::Utils::Downloader.download(url, progress_bar: true).path
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
