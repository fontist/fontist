require "zip"
require "fontist/import"
require_relative "otf/font_file"
require_relative "files/collection_file"
require_relative "helpers/hash_helper"
require_relative "formula_builder"

module Fontist
  module Import
    class CreateFormula
      FONT_PATTERN = "**/*.{ttf,otf}".freeze
      FONT_COLLECTION_PATTERN = "**/*.ttc".freeze
      LICENSE_PATTERN = "**/{OFL.txt,UFL.txt,LICENSE.txt}".freeze

      def initialize(url)
        @url = url
      end

      def call
        builder = FormulaBuilder.new
        builder.url = @url
        builder.archive = download(@url)
        builder.font_files = font_files(builder.archive)
        builder.font_collection_files = font_collection_files(builder.archive)
        builder.license_text = license_texts(builder.archive).first

        save(builder.formula)
      end

      private

      def download(url)
        return url if File.exist?(url)

        Fontist::Utils::Downloader.download(url, progress_bar: true)
      end

      def font_files(archive)
        extract_files(archive, FONT_PATTERN) do |path|
          Otf::FontFile.new(path)
        end
      end

      def font_collection_files(archive)
        extract_files(archive, FONT_COLLECTION_PATTERN) do |path|
          Files::CollectionFile.new(path)
        end
      end

      def license_texts(archive)
        extract_files(archive, LICENSE_PATTERN) do |path|
          File.read(path)
        end
      end

      def extract_files(archive, pattern)
        Dir.mktmpdir do |tmp_dir|
          Zip::File.open(archive) do |zip_file|
            zip_file.glob(pattern).map do |entry|
              filename = Pathname.new(entry.name).basename
              path = File.join(tmp_dir, filename)
              entry.extract(path)
              yield path
            end
          end
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
