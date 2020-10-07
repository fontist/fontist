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

    desc "uninstall/remove FONT", "Uninstall font by font or formula"
    def uninstall(font)
      fonts_paths = Fontist::Font.uninstall(font)
      Fontist.ui.success("These fonts are removed:")
      Fontist.ui.success(fonts_paths.join("\n"))
      STATUS_SUCCESS
    rescue Fontist::Errors::MissingFontError => e
      Fontist.ui.error(e.message)
      STATUS_ERROR
    rescue Fontist::Errors::NonSupportedFontError
      Fontist.ui.error("Could not find font '#{font}'.")
      STATUS_ERROR
    end
    map remove: :uninstall

    desc "status [FONT]", "Show status of FONT or all fonts in fontist"
    def status(font = nil)
      formulas = Fontist::Font.status(font)
      return error("No font is installed.") if formulas.empty?

      print_formulas(formulas)
      success
    rescue Fontist::Errors::MissingFontError => e
      error(e.message)
    rescue Fontist::Errors::NonSupportedFontError
      error("Could not find font '#{font}'.")
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

    private

    def success
      STATUS_SUCCESS
    end

    def error(message)
      Fontist.ui.error(message)
      STATUS_ERROR
    end

    def print_formulas(formulas)
      formulas.each do |formula, fonts|
        Fontist.ui.success(formula.installer)

        fonts.each do |font, styles|
          Fontist.ui.success(" #{font.name}")

          styles.each do |style, path|
            Fontist.ui.success("  #{style.type} (#{path})")
          end
        end
      end
    end
  end
end
