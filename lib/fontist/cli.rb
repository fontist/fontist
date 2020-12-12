require "thor"
require "fontist/import"

module Fontist
  class CLI < Thor
    STATUS_SUCCESS = 0
    STATUS_ERROR = 1

    def self.exit_on_failure?
      false
    end

    desc "install FONT", "Install font"
    option :force, type: :boolean, aliases: :f,
                   desc: "Install even if it's already installed in system"
    option :confirm_license, type: :boolean, desc: "Confirm license agreement"
    def install(font)
      Fontist::Font.install(
        font,
        force: options[:force],
        confirmation: options[:confirm_license] ? "yes" : "no"
      )
      STATUS_SUCCESS
    rescue Fontist::Errors::NonSupportedFontError
      could_not_find_font(font)
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
      could_not_find_font(font)
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
      could_not_find_font(font)
    end

    desc "list [FONT]", "List installation status of FONT or fonts in fontist"
    def list(font = nil)
      formulas = Fontist::Font.list(font)
      print_list(formulas)
      success
    rescue Fontist::Errors::NonSupportedFontError
      could_not_find_font(font)
    end

    desc "update", "Update formulas"
    def update
      Formulas.fetch_formulas
      Fontist.ui.say("Formulas have been successfully updated")
      STATUS_SUCCESS
    end

    desc "manifest-locations MANIFEST",
         "Get locations of fonts from MANIFEST (yaml)"
    def manifest_locations(manifest)
      paths = Fontist::Manifest::Locations.from_file(manifest)
      print_yaml(paths)
      success
    rescue Fontist::Errors::ManifestCouldNotBeFoundError
      error("Manifest could not be found.")
    rescue Fontist::Errors::ManifestCouldNotBeReadError
      error("Manifest could not be read.")
    end

    desc "manifest-install MANIFEST", "Install fonts from MANIFEST (yaml)"
    option :confirm_license, type: :boolean, desc: "Confirm license agreement"
    def manifest_install(manifest)
      paths = Fontist::Manifest::Install.from_file(
        manifest,
        confirmation: options[:confirm_license] ? "yes" : "no"
      )

      print_yaml(paths)
      success
    rescue Fontist::Errors::ManifestCouldNotBeFoundError
      error("Manifest could not be found.")
    rescue Fontist::Errors::ManifestCouldNotBeReadError
      error("Manifest could not be read.")
    end

    desc "create-formula URL", "Create a new formula with fonts from URL"
    option :name, desc: "Example: Times New Roman"
    option :mirror, repeatable: true
    option :subarchive, desc: "Subarchive to choose when there are several ones"
    option :subdir, desc: "Subdirectory to take fonts from"
    def create_formula(url)
      require "fontist/import/create_formula"
      name = Fontist::Import::CreateFormula.new(url, options).call
      Fontist.ui.say("#{name} formula has been successfully created")
      STATUS_SUCCESS
    end

    desc "rebuild-index", "Rebuild formula index (used by formulas maintainers)"
    long_desc <<-LONGDESC
      This index is pre-built and served with formulas, so there is no need
      update it unless something changes in the formulas repo.
    LONGDESC
    def rebuild_index
      Fontist::Import::RebuildIndex.new.call
      Fontist.ui.say("Formula index has been rebuilt.")
      STATUS_SUCCESS
    end

    private

    def success
      STATUS_SUCCESS
    end

    def could_not_find_font(font)
      error("Font '#{font}' not found locally nor available in the Fontist " \
            "formula repository.\n" \
            "Perhaps it is available at the latest Fontist formula " \
            "repository.\n" \
            "You can update the formula repository using the command " \
            "`fontist update` and try again.")
    end

    def error(message)
      Fontist.ui.error(message)
      STATUS_ERROR
    end

    def print_yaml(object)
      Fontist.ui.say(YAML.dump(object))
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

    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def print_list(formulas)
      formulas.each do |formula, fonts|
        Fontist.ui.say(formula.installer)

        fonts.each do |font, styles|
          Fontist.ui.say(" #{font.name}")

          styles.each do |style, installed|
            if installed
              Fontist.ui.success("  #{style.type} (installed)")
            else
              Fontist.ui.error("  #{style.type} (uninstalled)")
            end
          end
        end
      end
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength
  end
end
