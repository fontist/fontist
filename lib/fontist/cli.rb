require "thor"

module Fontist
  class CLI < Thor
    STATUS_SUCCESS = 0
    STATUS_ERROR = 1

    desc "install FONT", "Install font by font or formula"
    def install(font)
      fonts_paths = Fontist::Font.install(font)
      Fontist.ui.success("These fonts are found or installed:")
      Fontist.ui.success(fonts_paths.join("\n"))
      STATUS_SUCCESS
    rescue Fontist::Errors::NonSupportedFontError
      Fontist.ui.error("Could not find font '#{font}'.")
      STATUS_ERROR
    end

    desc "update", "Update formulas"
    def update
      Formulas.fetch_formulas
      Fontist.ui.say("Formulas have been successfully updated")
      STATUS_SUCCESS
    end

    desc "create-formula URL", "Create a new formula with fonts from URL"
    option :name, desc: "Example: Times New Roman"
    option :mirror, repeatable: true
    def create_formula(url)
      require "fontist/import/create_formula"
      name = Fontist::Import::CreateFormula.new(url, options).call
      Fontist.ui.say("#{name} formula has been successfully created")
      STATUS_SUCCESS
    end

    def self.exit_on_failure?
      true
    end
  end
end
