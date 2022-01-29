require "fontist/import"
require_relative "recursive_extraction"
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
        save(builder)
      end

      private

      def builder
        builder = FormulaBuilder.new
        setup_strings(builder, archive)
        setup_files(builder)
        builder
      end

      def setup_strings(builder, archive)
        builder.archive = archive
        builder.url = @url
        builder.options = @options
      end

      def setup_files(builder)
        builder.extractor = extractor
        builder.font_files = extractor.font_files
        builder.font_collection_files = extractor.font_collection_files
        builder.license_text = extractor.license_text
      end

      def extractor
        @extractor ||=
          RecursiveExtraction.new(archive,
                                  subarchive: @options[:subarchive],
                                  subdir: @options[:subdir])
      end

      def archive
        @archive ||= download(@url)
      end

      def download(url)
        return url if File.exist?(url)

        Fontist::Utils::Downloader.download(url, progress_bar: true).path
      end

      def save(builder)
        path = vacant_path
        yaml = YAML.dump(Helpers::HashHelper.stringify_keys(builder.formula))
        File.write(path, yaml)
        path
      end

      def vacant_path
        path = path_from_name
        return path unless @options[:keep_existing] && File.exist?(path)

        2.upto(9) do |i|
          candidate = path.sub(/\.yml$/, "#{i}.yml")
          return candidate unless File.exist?(candidate)
        end

        raise Errors::GeneralError, "Formula #{path} already exists."
      end

      def path_from_name
        filename = Import.name_to_filename(builder.name)
        if @options[:formula_dir]
          File.join(@options[:formula_dir], filename)
        else
          filename
        end
      end
    end
  end
end
