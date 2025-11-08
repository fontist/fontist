require "fontist/import"
require_relative "recursive_extraction"
require_relative "formula_builder"

module Fontist
  module Import
    class CreateFormula
      def initialize(url, options = {})
        @url = url
        @options = options
      end

      def call
        builder.save
      end

      private

      def builder
        builder = FormulaBuilder.new
        setup_strings(builder)
        setup_files(builder)
        builder
      end

      def setup_strings(builder)
        builder.options = @options
        builder.resources = resources
      end

      def setup_files(builder)
        builder.operations = extractor.operations
        builder.font_files = extractor.font_files
        builder.font_collection_files = extractor.font_collection_files
        builder.license_text = extractor.license_text
      end

      def resources
        @resources ||= { filename(archive) => resource_options }
      end

      def filename(file)
        if file.respond_to?(:original_filename)
          file.original_filename
        else
          File.basename(file)
        end
      end

      def resource_options
        if @options[:skip_sha]
          resource_options_without_sha
        else
          resource_options_with_sha
        end
      end

      def resource_options_without_sha
        { urls: [@url] + mirrors, file_size: file_size }
      end

      def resource_options_with_sha
        urls = []
        sha = []
        downloads do |url, path|
          urls << url
          sha << Digest::SHA256.file(path).to_s
        end

        sha = prepare_sha256(sha)

        { urls: urls, sha256: sha, file_size: file_size }
      end

      def downloads
        yield @url, archive

        mirrors.each do |url|
          path = download_mirror(url)
          next unless path

          yield url, path
        end
      end

      def mirrors
        @options[:mirror] || []
      end

      def download_mirror(url)
        Fontist::Utils::Downloader.download(url, progress_bar: true).path
      rescue Errors::InvalidResourceError
        Fontist.ui.error("WARN: a mirror is not found '#{url}'")
        nil
      end

      def prepare_sha256(input)
        output = input.uniq
        return output.first if output.size == 1

        checksums = output.join(", ")
        Fontist.ui.error("WARN: SHA256 differs (#{checksums})")
        output
      end

      def file_size
        File.size(archive)
      end

      def extractor
        @extractor ||=
          RecursiveExtraction.new(archive,
                                  subdir: @options[:subdir],
                                  file_pattern: @options[:file_pattern],
                                  name_prefix: @options[:name_prefix])
      end

      def archive
        @archive ||= download(@url)
      end

      def download(url)
        return url if File.exist?(url)

        Fontist::Utils::Downloader.download(url, progress_bar: true).path
      end
    end
  end
end
