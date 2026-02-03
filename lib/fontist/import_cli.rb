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
    option :font_name,
           type: :string, aliases: %i[f font_family],
           desc: "Import specific font family by name"
    option :force,
           type: :boolean,
           desc: "Overwrite existing formulas"
    option :verbose,
           type: :boolean, aliases: :v,
           desc: "Enable verbose output"
    option :import_cache,
           type: :string,
           desc: "Directory for import cache (default: ~/.fontist/import_cache)"

    def google
      handle_class_options(options)

      require "fontist/import/google_fonts_importer"

      # Support both --font-name and --font-family (backward compatibility)
      font_name = options[:font_name] || options[:font_family]

      importer = Fontist::Import::GoogleFontsImporter.new(
        source_path: options[:source_path],
        output_path: options[:output_path],
        font_family: font_name,
        force: options[:force],
        verbose: options[:verbose],
        import_cache: options[:import_cache],
      )

      result = importer.import

      # Report results only in non-verbose mode (verbose mode already has rich summary)
      unless options[:verbose]
        Fontist.ui.success("Import completed")
        Fontist.ui.say("  Successful: #{result[:successful]}")
        Fontist.ui.say("  Skipped: #{result[:skipped]}") if result[:skipped]&.positive?
        Fontist.ui.say("  Overwritten: #{result[:overwritten]}") if result[:overwritten]&.positive?
        Fontist.ui.say("  Failed: #{result[:failed]}") if result[:failed]&.positive?
        Fontist.ui.say("  Duration: #{format_duration(result[:duration])}")
      end

      CLI::STATUS_SUCCESS
    rescue StandardError => e
      Fontist.ui.error("Import error: #{e.message}")
      Fontist.ui.error(e.backtrace.join("\n")) if options[:verbose]
      Fontist::CLI::STATUS_UNKNOWN_ERROR
    end

    desc "macos", "Import macOS supplementary fonts"
    option :plist,
           type: :string,
           desc: "Path to macOS font catalog XML (e.g., com_apple_MobileAsset_Font8.xml)"
    option :output_path,
           type: :string,
           desc: "Output directory for generated formulas (default: formulas/macos)"
    option :formulas_dir,
           type: :string,
           desc: "DEPRECATED: Use --output-path instead"
    option :font_name,
           type: :string, aliases: :f,
           desc: "Import specific font by name (optional)"
    option :force,
           type: :boolean,
           desc: "Overwrite existing formulas"
    option :verbose,
           type: :boolean, aliases: :v,
           desc: "Enable verbose output"
    option :import_cache,
           type: :string,
           desc: "Directory for import cache (default: ~/.fontist/import_cache)"

    def macos
      handle_class_options(options)
      require_relative "import/macos"

      # Handle deprecated formulas_dir option
      output_dir = if options[:formulas_dir] && !options[:output_path]
                     Fontist.ui.error("DEPRECATED: --formulas-dir is deprecated, use --output-path instead")
                     options[:formulas_dir]
                   else
                     options[:output_path]
                   end

      plist_path = options[:plist] || detect_latest_catalog
      force = options[:force]
      verbose = options[:verbose]
      font_name = options[:font_name]

      Import::Macos.new(
        plist_path,
        formulas_dir: output_dir,
        font_name: font_name,
        force: force,
        verbose: verbose,
        import_cache: options[:import_cache],
      ).call

      CLI::STATUS_SUCCESS
    rescue StandardError => e
      Fontist.ui.error("Import error: #{e.message}")
      Fontist.ui.error(e.backtrace.join("\n")) if options[:verbose]
      CLI::STATUS_UNKNOWN_ERROR
    end

    desc "sil", "Import formulas from SIL International"
    option :output_path,
           type: :string,
           desc: "Output directory for generated formulas (default: ~/.fontist/versions/v4/formulas/Formulas/sil)"
    option :font_name,
           type: :string, aliases: :f,
           desc: "Import specific font by name (optional)"
    option :force,
           type: :boolean,
           desc: "Overwrite existing formulas"
    option :verbose,
           type: :boolean, aliases: :v,
           desc: "Enable verbose output"
    option :import_cache,
           type: :string,
           desc: "Directory for import cache (default: ~/.fontist/import_cache)"

    def sil
      handle_class_options(options)

      require "fontist/import/sil_import"

      importer = Fontist::Import::SilImport.new(
        output_path: options[:output_path],
        font_name: options[:font_name],
        force: options[:force],
        verbose: options[:verbose],
        import_cache: options[:import_cache],
      )

      result = importer.call

      # Report results only in non-verbose mode (verbose mode already has rich summary)
      unless options[:verbose]
        Fontist.ui.success("Import completed")
        Fontist.ui.say("  Successful: #{result[:successful]}")
        Fontist.ui.say("  Skipped: #{result[:skipped]}") if result[:skipped]&.positive?
        Fontist.ui.say("  Overwritten: #{result[:overwritten]}") if result[:overwritten]&.positive?
        Fontist.ui.say("  Failed: #{result[:failed]}") if result[:failed]&.positive?
        Fontist.ui.say("  Duration: #{format_duration(result[:duration])}")
      end

      CLI::STATUS_SUCCESS
    rescue StandardError => e
      Fontist.ui.error("Import error: #{e.message}")
      Fontist.ui.error(e.backtrace.join("\n")) if options[:verbose]
      Fontist::CLI::STATUS_UNKNOWN_ERROR
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

    def detect_latest_catalog
      require_relative "macos/catalog/catalog_manager"

      catalogs = Fontist::Macos::Catalog::CatalogManager.available_catalogs

      if catalogs.empty?
        raise "No macOS font catalogs found. Please specify --plist path/to/catalog.xml"
      end

      catalogs.last # Return the latest version
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
