require "fileutils"
require "yaml"
require "tmpdir"
require "find"
require_relative "../formula"

module Fontist
  module Import
    # Batch upgrade existing formulas to v4 schema with VF/WOFF2 support
    #
    # This script upgrades existing formula files by adding optional
    # format and variable_axes attributes to resources while maintaining
    # full backward compatibility.
    #
    # Key features:
    # - Distinguishes archives from direct font files
    # - Downloads and recursively extracts archives to detect fonts
    # - Detects font formats (ttf, otf, woff2, ttc, otc)
    # - Detects variable font axes from filenames
    class UpgradeFormulas
      ARCHIVE_EXTENSIONS = %w[zip tar gz tgz bz2 7z rar].freeze
      FONT_EXTENSIONS = %w[ttf otf woff2 ttc otc].freeze

      def initialize(formulas_path, options = {})
        @formulas_path = formulas_path
        @verbose = options[:verbose]
        @dry_run = options[:dry_run]
        @skip_download = options[:skip_download] # Skip downloading for testing
      end

      def upgrade_all
        results = { upgraded: 0, skipped: 0, failed: 0, errors: [] }

        files = formula_files
        log "Found #{files.size} formula file(s) to process"

        files.each do |path|
          upgrade_formula(path)
          results[:upgraded] += 1
          log "✓ Upgraded #{File.basename(path)}"
        rescue StandardError => e
          results[:failed] += 1
          results[:errors] << { formula: path, error: e.message }
          log "✗ Failed #{File.basename(path)}: #{e.message}"
        end

        results
      end

      def upgrade_formula(path)
        # Load formula
        formula_data = YAML.load_file(path)

        # Skip if no resources
        return unless formula_data["resources"]

        # Upgrade resources
        upgraded = false
        formula_data["resources"].each do |resource_name, resource_data|
          next unless resource_data.is_a?(Hash)

          # Check if this resource is an archive
          is_archive = archive_resource?(resource_name, resource_data)

          # Handle format attribute
          if is_archive
            # CRITICAL: Archives must NOT have format attribute
            if resource_data["format"]
              log "  Removing incorrect format from archive: #{resource_name}"
              resource_data.delete("format")
              upgraded = true
            end
            # Also remove variable_axes from archives (doesn't make sense)
            if resource_data["variable_axes"]
              log "  Removing variable_axes from archive: #{resource_name}"
              resource_data.delete("variable_axes")
              upgraded = true
            end
          else
            # This is a direct font file, add format if missing
            unless resource_data["format"]
              format = detect_format_from_resource(resource_data, resource_name)
              if format
                log "  Adding format '#{format}' to: #{resource_name}"
                resource_data["format"] = format
                upgraded = true
              end
            end

            # Detect and add variable_axes if missing
            unless resource_data["variable_axes"]
              axes = detect_axes_from_resource(resource_data, resource_name)
              if axes && !axes.empty?
                log "  Adding variable_axes #{axes.inspect} to: #{resource_name}"
                resource_data["variable_axes"] = axes
                upgraded = true
              end
            end
          end
        end

        # Save if upgraded and not dry run
        if upgraded && !@dry_run
          File.write(path, YAML.dump(formula_data))
          log "  Saved: #{File.basename(path)}"
        elsif upgraded && @dry_run
          log "  Would save: #{File.basename(path)}"
        elsif !upgraded
          log "  No changes needed: #{File.basename(path)}"
        end
      end

      private

      def formula_files
        if File.file?(@formulas_path)
          # Single file
          [@formulas_path]
        elsif File.directory?(@formulas_path)
          # Directory - find all yml files recursively
          Dir.glob(File.join(@formulas_path, "**/*.yml")).sort
        else
          []
        end
      end


      # Detect format from resource with intelligent archive handling
      #
      # This method:
      # 1. First checks if resource is an archive (no format for archives)
      # 2. Then checks for direct font file patterns
      # 3. Finally downloads and inspects archives if needed
      #
      # @param resource_data [Hash] the resource data
      # @param resource_name [String] the resource name
      # @return [String, nil] format (ttf, otf, woff2, ttc, otc) or nil
      def detect_format_from_resource(resource_data, resource_name)
        # CRITICAL: Archives should NEVER have format attribute
        # Only direct font files should have format
        return nil if archive_resource?(resource_name, resource_data)

        # Try to detect from resource name
        format = detect_format_from_name(resource_name)
        return format if format

        # Try to detect from URLs
        urls = Array(resource_data["urls"] || resource_data["files"])
        urls.each do |url|
          format = detect_format_from_url(url)
          return format if format
        end

        # If still unclear and not skipping downloads, download and inspect
        # This handles cases where URL patterns are ambiguous
        if !@skip_download && urls.any?
          format = detect_format_by_download(urls.first, resource_name)
          return format if format
        end

        # Cannot determine format - return nil (no format attribute)
        nil
      end

      # Check if resource is an archive (container, not a font)
      #
      # @param resource_name [String] the resource name
      # @param resource_data [Hash] the resource data
      # @return [Boolean] true if archive
      def archive_resource?(resource_name, resource_data)
        # Check resource name
        return true if archive_extension?(resource_name)

        # Check URLs
        urls = Array(resource_data["urls"] || resource_data["files"])
        urls.any? { |url| archive_extension?(url) }
      end

      # Check if filename/URL has archive extension
      #
      # @param path [String] the path or URL
      # @return [Boolean] true if archive extension detected
      def archive_extension?(path)
        # Match .zip, .tar.gz, .tgz, etc.
        return true if path =~ /\.(#{ARCHIVE_EXTENSIONS.join('|')})(?:\?|$)/i

        # Match compound extensions like .tar.gz
        return true if path =~ /\.tar\.(gz|bz2)(?:\?|$)/i

        false
      end

      # Detect format from filename
      #
      # @param name [String] the filename
      # @return [String, nil] format or nil
      def detect_format_from_name(name)
        if name =~ /\.(\w+)$/
          ext = Regexp.last_match(1).downcase
          return ext if FONT_EXTENSIONS.include?(ext)
        end
        nil
      end

      # Detect format from URL
      #
      # @param url [String] the URL
      # @return [String, nil] format or nil
      def detect_format_from_url(url)
        # Extract filename from URL
        filename = url.split('/').last.split('?').first
        detect_format_from_name(filename)
      end

      # Download resource and detect format by inspection
      #
      # This downloads the resource, extracts if needed, and finds fonts
      #
      # @param url [String] the URL to download
      # @param resource_name [String] the resource name for logging
      # @return [String, nil] detected format or nil
      def detect_format_by_download(url, resource_name)
        log "  Downloading #{resource_name} to insp ect format..."

        Dir.mktmpdir do |tmpdir|
          # Download file
          downloaded_file = download_resource(url)
          return nil unless downloaded_file

          # If it's a direct font file, detect format
          format = detect_format_from_file(downloaded_file)
          return format if format

          # If it's an archive, extract and find fonts
          if archive_file?(downloaded_file)
            fonts = extract_and_find_fonts(downloaded_file, tmpdir)
            if fonts.any?
              # Return format of first font found
              return detect_format_from_file(fonts.first)
            end
          end
        end

        nil
      rescue StandardError => e
        log "  Warning: Could not download/inspect #{resource_name}: #{e.message}"
        nil
      end

      # Download a resource using Fontist downloader
      #
      # @param url [String] the URL to download
      # @return [String, nil] path to downloaded file or nil
      def download_resource(url)
        # Lazy load downloader to avoid dependency issues
        require_relative "../utils/downloader" unless defined?(Fontist::Utils::Downloader)

        Fontist::Utils::Downloader.download(url)
      rescue StandardError => e
        log "  Warning: Download failed for #{url}: #{e.message}"
        nil
      end

      # Check if file is an archive
      #
      # @param path [String] the file path
      # @return [Boolean] true if archive
      def archive_file?(path)
        archive_extension?(path) || detect_archive_by_magic(path)
      end

      # Detect archive by file magic (content inspection)
      #
      # @param path [String] the file path
      # @return [Boolean] true if archive detected
      def detect_archive_by_magic(path)
        return false unless File.exist?(path)

        # Read first few bytes to detect file signature
        magic = File.binread(path, 10)
        return true if magic.start_with?("PK\x03\x04") # ZIP
        return true if magic.start_with?("\x1f\x8b") # GZIP
        return true if magic[257..261] == "ustar" # TAR

        false
      rescue StandardError
        false
      end

      # Detect font format from file
      #
      # Uses file extension and optionally Otf::FontFile for validation
      #
      # @param path [String] the file path
      # @return [String, nil] format or nil
      def detect_format_from_file(path)
        # Try by extension first
        format = detect_format_from_name(path)
        return format if format

        # Try to parse with Otf::FontFile
        begin
          # Lazy load Otf::FontFile to avoid dependency issues
          require_relative "otf/font_file" unless defined?(Fontist::Import::Otf::FontFile)

          Otf::FontFile.new(path)
          # If it parses, it's likely a font file
          # Guess ttf if we can't determine
          return "ttf"
        rescue StandardError
          nil
        end
      end

      # Extract archive and recursively find all fonts
      #
      # @param archive_path [String] path to archive
      # @param extract_dir [String] directory to extract to
      # @return [Array<String>] paths to all font files found
      def extract_and_find_fonts(archive_path, extract_dir)
        fonts = []

        # Extract archive
        extract_archive(archive_path, extract_dir)

        # Recursively find all fonts
        Find.find(extract_dir) do |path|
          next if File.directory?(path)

          # Check if it's a font file
          if FONT_EXTENSIONS.any? { |ext| path.end_with?(".#{ext}") }
            fonts << path
          elsif archive_file?(path)
            # Recursively extract nested archives
            nested_dir = File.join(extract_dir, "nested_#{File.basename(path)}")
            FileUtils.mkdir_p(nested_dir)
            nested_fonts = extract_and_find_fonts(path, nested_dir)
            fonts.concat(nested_fonts)
          end
        end

        fonts
      rescue StandardError => e
        log "  Warning: Could not extract archive #{archive_path}: #{e.message}"
        []
      end

      # Extract archive to directory
      #
      # @param archive_path [String] path to archive
      # @param extract_dir [String] directory to extract to
      # @return [void]
      def extract_archive(archive_path, extract_dir)
        ext = File.extname(archive_path).downcase.sub(".", "")

        case ext
        when "zip"
          extract_zip(archive_path, extract_dir)
        when "gz", "tgz"
          extract_tar_gz(archive_path, extract_dir)
        when "bz2"
          extract_tar_bz2(archive_path, extract_dir)
        when "tar"
          extract_tar(archive_path, extract_dir)
        else
          # Try to detect by magic
          if detect_archive_by_magic(archive_path)
            # Try zip first as it's most common
            extract_zip(archive_path, extract_dir)
          end
        end
      end

      # Extract ZIP archive
      #
      # @param archive_path [String] path to archive
      # @param extract_dir [String] directory to extract to
      # @return [void]
      def extract_zip(archive_path, extract_dir)
        require "zip"
        Zip::File.open(archive_path) do |zip_file|
          zip_file.each do |entry|
            entry_path = File.join(extract_dir, entry.name)
            FileUtils.mkdir_p(File.dirname(entry_path))
            entry.extract(entry_path) unless File.exist?(entry_path)
          end
        end
      end

      # Extract TAR.GZ archive
      #
      # @param archive_path [String] path to archive
      # @param extract_dir [String] directory to extract to
      # @return [void]
      def extract_tar_gz(archive_path, extract_dir)
        require "rubygems/package"
        require "zlib"

        File.open(archive_path, "rb") do |file|
          Zlib::GzipReader.wrap(file) do |gz|
            Gem::Package::TarReader.new(gz) do |tar|
              extract_tar_entries(tar, extract_dir)
            end
          end
        end
      end

      # Extract TAR.BZ2 archive
      #
      # @param archive_path [String] path to archive
      # @param extract_dir [String] directory to extract to
      # @return [void]
      def extract_tar_bz2(archive_path, extract_dir)
        require "rubygems/package"
        require "bzip2/ffi"

        File.open(archive_path, "rb") do |file|
          Bzip2::FFI::Reader.open(file) do |bz|
            Gem::Package::TarReader.new(bz) do |tar|
              extract_tar_entries(tar, extract_dir)
            end
          end
        end
      end

      # Extract TAR archive
      #
      # @param archive_path [String] path to archive
      # @param extract_dir [String] directory to extract to
      # @return [void]
      def extract_tar(archive_path, extract_dir)
        require "rubygems/package"

        File.open(archive_path, "rb") do |file|
          Gem::Package::TarReader.new(file) do |tar|
            extract_tar_entries(tar, extract_dir)
          end
        end
      end

      # Extract TAR entries
      #
      # @param tar [Gem::Package::TarReader] the tar reader
      # @param extract_dir [String] directory to extract to
      # @return [void]
      def extract_tar_entries(tar, extract_dir)
        tar.each do |entry|
          next unless entry.file?

          entry_path = File.join(extract_dir, entry.full_name)
          FileUtils.mkdir_p(File.dirname(entry_path))
          File.open(entry_path, "wb") do |f|
            f.write(entry.read)
          end
        end
      end

      # Detect variable font axes from resource
      #
      # Looks for patterns like:
      # - Roboto[wght].ttf → ["wght"]
      # - Trispace[wdth,wght].ttf → ["wdth", "wght"]
      #
      # @param resource_data [Hash] the resource data
      # @param resource_name [String] the resource name
      # @return [Array<String>] array of axes (empty if not variable)
      def detect_axes_from_resource(resource_data, resource_name)
        # Try to detect from resource name
        axes = extract_axes_from_name(resource_name)
        return axes if axes.any?

        # Try to detect from URLs
        urls = Array(resource_data["urls"] || resource_data["files"])
        urls.each do |url|
          axes = extract_axes_from_name(url)
          return axes if axes.any?
        end

        # No axes detected
        []
      end

      # Extract axes from filename/URL pattern
      #
      # @param name [String] the filename or URL
      # @return [Array<String>] array of axes
      def extract_axes_from_name(name)
        if name =~ /\[([^\]]+)\]/
          Regexp.last_match(1).split(",").map(&:strip)
        else
          []
        end
      end

      def log(message)
        puts message if @verbose
      end
    end
  end
end