module Fontist
  class GoogleCLI < Thor
    class_option :formulas_path, type: :string, desc: "Path to formulas"

    desc "check", "Check Google fonts for updates"
    def check
      handle_class_options(options)
      require "fontist/import/google_check"
      Fontist::Import::GoogleCheck.new.call
      CLI::STATUS_SUCCESS
    end

    desc "import", "Import Google fonts"
    def import
      handle_class_options(options)
      require "fontist/import/google_import"
      Fontist::Import::GoogleImport.new.call
      CLI::STATUS_SUCCESS
    end

    private

    def handle_class_options(options)
      if options[:formulas_path]
        Fontist.formulas_path = Pathname.new(options[:formulas_path])
      end
    end
  end
end
