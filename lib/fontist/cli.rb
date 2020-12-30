require "thor"

module Fontist
  class CLI < Thor
    STATUS_SUCCESS = 0
    STATUS_UNKNOWN_ERROR = 1
    STATUS_NON_SUPPORTED_FONT_ERROR = 2
    STATUS_MISSING_FONT_ERROR = 3
    STATUS_LICENSING_ERROR = 4
    STATUS_MANIFEST_COULD_NOT_BE_FOUND_ERROR = 5
    STATUS_MANIFEST_COULD_NOT_BE_READ_ERROR = 6

    ERROR_TO_STATUS = {
      Fontist::Errors::NonSupportedFontError => [STATUS_NON_SUPPORTED_FONT_ERROR],
      Fontist::Errors::MissingFontError => [STATUS_MISSING_FONT_ERROR],
      Fontist::Errors::LicensingError => [STATUS_LICENSING_ERROR],
      Fontist::Errors::ManifestCouldNotBeFoundError => [STATUS_MANIFEST_COULD_NOT_BE_FOUND_ERROR,
                                                        "Manifest could not be found."],
      Fontist::Errors::ManifestCouldNotBeReadError => [STATUS_MANIFEST_COULD_NOT_BE_READ_ERROR,
                                                       "Manifest could not be read."],
    }.freeze

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
      success
    rescue Fontist::Errors::GeneralError => e
      handle_error(e)
    end

    desc "uninstall/remove FONT", "Uninstall font by font or formula"
    def uninstall(font)
      fonts_paths = Fontist::Font.uninstall(font)
      Fontist.ui.success("These fonts are removed:")
      Fontist.ui.success(fonts_paths.join("\n"))
      success
    rescue Fontist::Errors::GeneralError => e
      handle_error(e)
    end
    map remove: :uninstall

    desc "status [FONT]", "Show status of FONT or all fonts in fontist"
    def status(font = nil)
      formulas = Fontist::Font.status(font)
      return error("No font is installed.", STATUS_MISSING_FONT_ERROR) if formulas.empty?

      print_formulas(formulas)
      success
    rescue Fontist::Errors::GeneralError => e
      handle_error(e)
    end

    desc "list [FONT]", "List installation status of FONT or fonts in fontist"
    def list(font = nil)
      formulas = Fontist::Font.list(font)
      print_list(formulas)
      success
    rescue Fontist::Errors::GeneralError => e
      handle_error(e)
    end

    desc "update", "Update formulas"
    def update
      Formula.update_formulas_repo
      Fontist.ui.say("Formulas have been successfully updated")
      success
    end

    desc "manifest-locations MANIFEST",
         "Get locations of fonts from MANIFEST (yaml)"
    def manifest_locations(manifest)
      paths = Fontist::Manifest::Locations.from_file(manifest)
      print_yaml(paths)
      success
    rescue Fontist::Errors::GeneralError => e
      handle_error(e)
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
    rescue Fontist::Errors::GeneralError => e
      handle_error(e)
    end

    desc "create-formula URL", "Create a new formula with fonts from URL"
    option :name, desc: "Example: Times New Roman"
    option :mirror, repeatable: true
    option :subarchive, desc: "Subarchive to choose when there are several ones"
    option :subdir, desc: "Subdirectory to take fonts from, starting with the " \
      "root dir, e.g.: stixfonts-2.10/fonts/static_otf. May include `fnmatch` patterns."
    def create_formula(url)
      require "fontist/import/create_formula"
      name = Fontist::Import::CreateFormula.new(url, options).call
      Fontist.ui.say("#{name} formula has been successfully created")
      success
    end

    desc "rebuild-index", "Rebuild formula index (used by formulas maintainers)"
    long_desc <<-LONGDESC
      This index is pre-built and served with formulas, so there is no need
      update it unless something changes in the formulas repo.
    LONGDESC
    def rebuild_index
      Fontist::Index.rebuild
      Fontist.ui.say("Formula index has been rebuilt.")
      STATUS_SUCCESS
    end

    desc "import-sil", "Import formulas from SIL"
    def import_sil
      require "fontist/import/sil_import"
      Fontist::Import::SilImport.new.call
    end

    private

    def success
      STATUS_SUCCESS
    end

    def handle_error(exception)
      status, message = ERROR_TO_STATUS[exception.class]
      raise exception unless status

      error(message || exception.message, status)
    end

    def error(message, status)
      Fontist.ui.error(message)
      status
    end

    def print_yaml(object)
      Fontist.ui.say(YAML.dump(object))
    end

    def print_formulas(formulas)
      formulas.each do |formula, fonts|
        Fontist.ui.success(formula.key)

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
        Fontist.ui.say(formula.key)

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
