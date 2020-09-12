require "thor"
require "fontist/import/create_formula"

module Fontist
  class CLI < Thor
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
  end
end
