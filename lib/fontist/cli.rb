require "thor"

module Fontist
  class CLI < Thor
    desc "update", "Update formulas"
    def update
      Formulas.fetch_formulas
      puts "Formulas have been successfully updated"
    end
  end
end
