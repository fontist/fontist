require_relative "import/google"

module Fontist
  class ImportCLI < Thor
    include CLI::ClassOptions

    desc "google", "Import Google fonts"
    option :max_count,
           type: :numeric, aliases: :n,
           desc: "Limit the number of formulas to import " \
                 "(default is #{Fontist::Import::Google::DEFAULT_MAX_COUNT})."

    def google
      handle_class_options(options)
      require "fontist/import/google_import"
      Fontist::Import::GoogleImport.new(options).call
      CLI::STATUS_SUCCESS
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
  end
end
