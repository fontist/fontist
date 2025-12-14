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
    def macos
      handle_class_options(options)
      require_relative "import/macos"
      Import::Macos.new.call
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
  end
end
