module Fontist
  class ImportCLI < Thor
    include CLI::ClassOptions

    desc "macos", "Create formula for on-demand macOS fonts"
    option :name, desc: "Example: Big Sur", required: true
    option :fonts_link,
           desc: "A link to a list of available fonts in a current OS",
           required: true
    def macos
      handle_class_options(options)
      require_relative "import/macos"
      Import::Macos.new(options).call
      CLI::STATUS_SUCCESS
    end
  end
end
