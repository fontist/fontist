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
        setup_version_info(builder)
      end

      def setup_version_info(builder)
        # Handle import_source if provided
        if @options[:import_source]
          case @options[:import_source]
          when MacosImportSource
            builder.set_macos_import_source(
              framework_version: @options[:import_source].framework_version,
              posted_date: @options[:import_source].posted_date,
              asset_id: @options[:import_source].asset_id,
            )
          when GoogleImportSource
            builder.set_google_import_source(
              commit_id: @options[:import_source].commit_id,
              api_version: @options[:import_source].api_version,
              last_modified: @options[:import_source].last_modified,
              family_id: @options[:import_source].family_id,
            )
          when SilImportSource
            builder.set_sil_import_source(
              version: @options[:import_source].version,
              release_date: @options[:import_source].release_date,
            )
          end
        else
          # Legacy support for backward compatibility
          builder.catalog_version = @options[:catalog_version] if @options[:catalog_version]
          builder.min_macos_version = @options[:min_macos_version] if @options[:min_macos_version]
          builder.max_macos_version = @options[:max_macos_version] if @options[:max_macos_version]
        end

        builder.font_version = extract_font_version
      end

      def extract_font_version
        # Extract version from the first font file
        # All fonts in a formula should have the same version
        # The version is already extracted during Otf::FontFile initialization
        font_file = extractor.font_files.first
        return nil unless font_file

        # Use the already-extracted metadata instead of re-extracting
        font_file.version
      rescue StandardError => e
        Fontist.ui.error("WARN: Could not extract font version: #{e.message}")
        nil
      end

      def setup_files(builder)
        builder.operations = extractor.operations
        builder.font_files = extractor.font_files
        builder.font_collection_files = extractor.font_collection_files
        builder.license_text = extractor.license_text
        builder.error_collector = extractor.error_collector
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
        cache_path = @options[:import_cache] || Fontist.import_cache_path
        cache_path = Pathname.new(cache_path) if cache_path.is_a?(String)
        Fontist::Utils::Downloader.download(url, progress_bar: true,
                                                 cache_path: cache_path).path
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
                                  name_prefix: @options[:name_prefix],
                                  verbose: @options[:verbose])
      end

      def archive
        @archive ||= download(@url)
      end

      def download(url)
        return url if File.exist?(url)

        progress_bar = @options.fetch(:verbose, false) ? :verbose : true
        cache_path = @options[:import_cache] || Fontist.import_cache_path
        cache_path = Pathname.new(cache_path) if cache_path.is_a?(String)
        Fontist::Utils::Downloader.download(url, progress_bar: progress_bar,
                                                 cache_path: cache_path).path
      end
    end
  end
end
