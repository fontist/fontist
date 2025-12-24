require_relative "import/google"

module Fontist
  class ImportCLI < Thor
    include CLI::ClassOptions

    desc "google", "Import Google fonts"
    option :source_path,
           type: :string,
           desc: "Path to checked-out google/fonts repository"
    option :output_path,
           type: :string,
           desc: "Output path for generated formulas (default: ./Formulas/google)"
    option :font_family,
           type: :string, aliases: :f,
           desc: "Import specific font family by name"
    option :verbose,
           type: :boolean, aliases: :v,
           desc: "Enable verbose output"

    def google
      handle_class_options(options)

      require "fontist/import/google_fonts_importer"

      importer = Fontist::Import::GoogleFontsImporter.new(
        source_path: options[:source_path],
        output_path: options[:output_path],
        font_family: options[:font_family],
        verbose: options[:verbose],
      )

      result = importer.import

      # Report results
      Fontist.ui.success("Import completed")
      Fontist.ui.say("  Successful: #{result[:successful]}")
      Fontist.ui.say("  Failed: #{result[:failed]}") if result[:failed]&.positive?
      Fontist.ui.say("  Duration: #{format_duration(result[:duration])}")

      if result[:errors].any?
        Fontist.ui.say("\nErrors:")
        result[:errors].each do |error|
          Fontist.ui.say("  - #{error[:font]}: #{error[:error]}")
        end
      end

      CLI::STATUS_SUCCESS
    rescue StandardError => e
      Fontist.ui.error("Import error: #{e.message}")
      Fontist.ui.error(e.backtrace.join("\n")) if options[:verbose]
      Fontist::CLI::STATUS_UNKNOWN_ERROR
    end

    desc "macos", "Create formula for on-demand macOS fonts"
    option :version,
           type: :numeric,
           desc: "Import specific Font version (7 or 8)"
    option :all_versions,
           type: :boolean,
           desc: "Import all available versions"
    option :catalog_path,
           type: :string,
           desc: "Path to specific catalog XML"
    def macos
      handle_class_options(options)
      require_relative "import/macos"

      if options[:all_versions]
        import_all_macos_versions
      else
        import_specific_macos_version
      end

      CLI::STATUS_SUCCESS
    end

    desc "macos-catalogs", "List available macOS font catalogs"
    def macos_catalogs
      handle_class_options(options)
      require_relative "macos/catalog/catalog_manager"

      catalogs = Fontist::Macos::Catalog::CatalogManager.available_catalogs

      if catalogs.empty?
        Fontist.ui.error("No macOS font catalogs found.")
        Fontist.ui.say("Expected location: /System/Library/AssetsV2/")
        return CLI::STATUS_UNKNOWN_ERROR
      end

      Fontist.ui.say("Available macOS Font Catalogs:")
      catalogs.each do |catalog_path|
        version = Fontist::Macos::Catalog::CatalogManager.detect_version(catalog_path)
        size = File.size(catalog_path)

        Fontist.ui.say("  Font#{version}: #{catalog_path} (#{format_bytes(size)})")
      end

      CLI::STATUS_SUCCESS
    end

    desc "sil", "Import formulas from SIL"
    def sil
      handle_class_options(options)
      require "fontist/import/sil_import"
      Fontist::Import::SilImport.new.call
      CLI::STATUS_SUCCESS
    end

    private

    # Formats duration in human-readable format
    #
    # @param seconds [Float] duration in seconds
    # @return [String] formatted duration
    def format_duration(seconds)
      return "#{seconds.round(2)}s" if seconds < 60

      minutes = (seconds / 60).floor
      remaining_seconds = (seconds % 60).round(2)
      "#{minutes}m #{remaining_seconds}s"
    end

    def import_all_macos_versions
      require_relative "macos/catalog/catalog_manager"

      catalogs = Fontist::Macos::Catalog::CatalogManager.available_catalogs

      catalogs.each do |catalog_path|
        version = Fontist::Macos::Catalog::CatalogManager.detect_version(catalog_path)
        Fontist.ui.say("Importing Font#{version}...")

        Import::Macos.new(catalog_path).call
      end
    end

    def import_specific_macos_version
      catalog_path = options[:catalog_path] || find_catalog_by_version(options[:version])

      Import::Macos.new(catalog_path).call
    end

    def find_catalog_by_version(version)
      require_relative "macos/catalog/catalog_manager"

      catalogs = Fontist::Macos::Catalog::CatalogManager.available_catalogs

      if version
        catalogs.find { |path| path.include?("Font#{version}") } ||
          raise("Font#{version} catalog not found")
      else
        catalogs.last || raise("No macOS font catalogs found")
      end
    end

    def format_bytes(bytes)
      if bytes < 1024
        "#{bytes} B"
      elsif bytes < 1024 * 1024
        "#{(bytes / 1024.0).round(1)} KB"
      else
        "#{(bytes / (1024.0 * 1024)).round(1)} MB"
      end
    end
  end
end
