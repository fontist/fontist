module Fontist
  class ImportCLI < Thor
    desc "macos", "Create formula for on-demand macOS fonts"
    option :name, desc: "Example: Big Sur", required: true
    option :fonts_link,
           desc: "A link to a list of available fonts in a current OS",
           required: true
    option :formulas_path, type: :string, desc: "Path to formulas"
    def macos
      if options[:formulas_path]
        Fontist.formulas_path = Pathname.new(options[:formulas_path])
      end

      require_relative "import/macos"
      Import::Macos.new(options).call
      CLI::STATUS_SUCCESS
    end
  end
end
