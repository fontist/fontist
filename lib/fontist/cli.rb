require "thor"
require "fontist/import/create_formula"

module Fontist
  class CLI < Thor
    desc "install FONT", "Install font and its styles"
    long_desc <<-LONGDESC
      Install all fonts in formula
      \x5$ fontist install cleartype

      Install one font from formula (all styles)
      \x5$ fontist install calibri

      Install one font style from formula
      \x5$ fontist install calibri bold
    LONGDESC
    def install(font, _style = nil)
      fonts_paths = Fontist::Font.install(font)
      puts "These fonts are found or installed:"
      puts fonts_paths
    rescue Fontist::Errors::NonSupportedFontError
      abort "Could not find font '#{font}'."
    end

    desc "update", "Update formulas"
    def update
      Formulas.fetch_formulas
      puts "Formulas have been successfully updated"
    end

    desc "create-formula URL", "Create a new formula with fonts from URL"
    option :name, desc: "Example: Times New Roman"
    option :mirror, repeatable: true
    def create_formula(url)
      name = Fontist::Import::CreateFormula.new(url, options).call
      puts "#{name} formula has been successfully created"
    end

    def self.exit_on_failure?
      true
    end
  end
end
