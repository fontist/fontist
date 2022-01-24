module Fontist
  class GoogleCLI < Thor
    include CLI::ClassOptions

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
  end
end
