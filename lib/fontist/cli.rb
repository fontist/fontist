require "thor"
require "fontist/cli/class_options"
require "fontist/repo_cli"
require "fontist/import_cli"

module Fontist
  class CLI < Thor
    include ClassOptions

    STATUS_SUCCESS = 0
    STATUS_UNKNOWN_ERROR = 1
    STATUS_NON_SUPPORTED_FONT_ERROR = 2
    STATUS_MISSING_FONT_ERROR = 3
    STATUS_LICENSING_ERROR = 4
    STATUS_MANIFEST_COULD_NOT_BE_FOUND_ERROR = 5
    STATUS_MANIFEST_COULD_NOT_BE_READ_ERROR = 6
    STATUS_FONT_INDEX_CORRUPTED = 7
    STATUS_REPO_NOT_FOUND = 8
    STATUS_MAIN_REPO_NOT_FOUND = 9
    STATUS_REPO_COULD_NOT_BE_UPDATED = 10
    STATUS_MANUAL_FONT_ERROR = 11
    STATUS_SIZE_LIMIT_ERROR = 12
    STATUS_FORMULA_NOT_FOUND = 13

    ERROR_TO_STATUS = {
      Fontist::Errors::UnsupportedFontError => [STATUS_NON_SUPPORTED_FONT_ERROR],
      Fontist::Errors::MissingFontError => [STATUS_MISSING_FONT_ERROR],
      Fontist::Errors::SizeLimitError => [
        STATUS_SIZE_LIMIT_ERROR,
        :append,
        "Please specify higher `--size-limit`, or use the `--newest` or " \
        "`--smallest` options.",
      ],
      Fontist::Errors::ManualFontError => [STATUS_MANUAL_FONT_ERROR],
      Fontist::Errors::LicensingError => [STATUS_LICENSING_ERROR],
      Fontist::Errors::ManifestCouldNotBeFoundError => [STATUS_MANIFEST_COULD_NOT_BE_FOUND_ERROR,
                                                        :overwrite,
                                                        "Manifest could not be found."],
      Fontist::Errors::ManifestCouldNotBeReadError => [STATUS_MANIFEST_COULD_NOT_BE_READ_ERROR,
                                                       :overwrite,
                                                       "Manifest could not be read."],
      Fontist::Errors::FontIndexCorrupted => [STATUS_FONT_INDEX_CORRUPTED],
      Fontist::Errors::RepoNotFoundError => [STATUS_REPO_NOT_FOUND],
      Fontist::Errors::MainRepoNotFoundError => [STATUS_MAIN_REPO_NOT_FOUND],
      Fontist::Errors::FormulaNotFoundError => [STATUS_FORMULA_NOT_FOUND],
    }.freeze

    def self.exit_on_failure?
      false
    end

    class_option :preferred_family,
                 type: :boolean,
                 desc: "Use Preferred Family when available"

    class_option :quiet,
                 aliases: :q,
                 type: :boolean,
                 desc: "Hide all messages"

    class_option :formulas_path, type: :string, desc: "Path to formulas"

    desc "install FONT", "Install font"
    option :force, type: :boolean, aliases: :f,
                   desc: "Install even if already installed in system"
    option :formula, type: :boolean, aliases: :F,
                     desc: "Install whole formula instead of a font"
    option :accept_all_licenses, type: :boolean,
                                 aliases: ["--confirm-license", :a],
                                 desc: "Accept all license agreements"
    option :hide_licenses, type: :boolean, aliases: :h,
                           desc: "Hide license texts"
    option :no_progress, type: :boolean, aliases: :p,
                         desc: "Hide download progress"
    option :version, type: :string, aliases: :V,
                     desc: "Specify particular version of a font"
    option :smallest, type: :boolean, aliases: :s,
                      desc: "Install the smallest font by file size if several"
    option :newest, type: :boolean, aliases: :n,
                    desc: "Install the newest version of a font if several"
    option :size_limit,
           type: :numeric, aliases: :S,
           desc: "Specify upper limit for file size of a formula to be installed" \
                 "(default is #{Fontist.formula_size_limit_in_megabytes} MB)"
    def install(font)
      handle_class_options(options)
      confirmation = options[:accept_all_licenses] ? "yes" : "no"
      Fontist::Font.install(font, options.merge(confirmation: confirmation))
      success
    rescue Fontist::Errors::GeneralError => e
      handle_error(e)
    end

    desc "uninstall/remove FONT", "Uninstall font by font or formula"
    def uninstall(font)
      handle_class_options(options)
      fonts_paths = Fontist::Font.uninstall(font)
      Fontist.ui.success("These fonts are removed:")
      Fontist.ui.success(fonts_paths.join("\n"))
      success
    rescue Fontist::Errors::GeneralError => e
      handle_error(e)
    end
    map remove: :uninstall

    desc "status [FONT]", "Show paths of FONT or all fonts"
    def status(font = nil)
      handle_class_options(options)
      paths = Fontist::Font.status(font)
      return error("No font is installed.", STATUS_MISSING_FONT_ERROR) if paths.empty?

      success
    rescue Fontist::Errors::GeneralError => e
      handle_error(e)
    end

    desc "list [FONT]", "List installation status of FONT or fonts in fontist"
    def list(font = nil)
      handle_class_options(options)
      formulas = Fontist::Font.list(font)
      print_list(formulas)
      success
    rescue Fontist::Errors::GeneralError => e
      handle_error(e)
    end

    desc "update", "Update formulas"
    def update
      handle_class_options(options)
      Formula.update_formulas_repo
      Fontist.ui.success("Formulas have been successfully updated.")
      success
    rescue Fontist::Errors::RepoCouldNotBeUpdatedError => e
      Fontist.ui.error(e.message)
      STATUS_REPO_COULD_NOT_BE_UPDATED
    end

    desc "manifest-locations MANIFEST",
         "Get locations of fonts from MANIFEST (yaml)"
    def manifest_locations(manifest)
      handle_class_options(options)
      paths = Fontist::Manifest::Locations.from_file(manifest)
      print_yaml(paths)
      success
    rescue Fontist::Errors::GeneralError => e
      handle_error(e)
    end

    desc "manifest-install MANIFEST", "Install fonts from MANIFEST (yaml)"
    option :accept_all_licenses, type: :boolean,
                                 aliases: ["--confirm-license", :a],
                                 desc: "Accept all license agreements"
    option :hide_licenses, type: :boolean,
                           aliases: :h,
                           desc: "Hide license texts"
    def manifest_install(manifest)
      handle_class_options(options)
      paths = Fontist::Manifest::Install.from_file(
        manifest,
        confirmation: options[:accept_all_licenses] ? "yes" : "no",
        hide_licenses: options[:hide_licenses]
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
      handle_class_options(options)
      require "fontist/import/create_formula"
      name = Fontist::Import::CreateFormula.new(url, options).call
      Fontist.ui.say("#{name} formula has been successfully created")
      success
    end

    desc "rebuild-index", "Rebuild formula index (used by formulas maintainers)"
    long_desc <<-LONGDESC
      Index should be rebuilt when any formula changes.

      It is done automatically when formulas are updated, or private formulas
      are set up.
    LONGDESC
    def rebuild_index
      handle_class_options(options)
      Fontist::Index.rebuild
      Fontist.ui.say("Formula index has been rebuilt.")
      STATUS_SUCCESS
    end

    desc "repo SUBCOMMAND ...ARGS", "Manage custom repositories"
    subcommand "repo", Fontist::RepoCLI

    desc "import SUBCOMMAND ...ARGS", "Manage imports"
    subcommand "import", Fontist::ImportCLI

    private

    def success
      STATUS_SUCCESS
    end

    def handle_error(exception)
      status, mode, message = ERROR_TO_STATUS[exception.class]
      raise exception unless status

      text = if message && mode == :overwrite
               message
             elsif message
               "#{exception.message} #{message}"
             else
               exception.message
             end

      error(text, status)
    end

    def error(message, status)
      Fontist.ui.error(message)
      status
    end

    def print_yaml(object)
      Fontist.ui.say(YAML.dump(object))
    end

    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def print_list(formulas)
      formulas.each do |formula, fonts|
        Fontist.ui.say(formula.key)

        fonts.each do |font, styles|
          Fontist.ui.say(" #{font.name}")

          styles.each do |style, installed|
            opts = []
            opts << "manual" if formula.manual?
            opts << (installed ? "installed" : "uninstalled")
            msg = "  #{style.type} (#{opts.join(', ')})"

            if installed
              Fontist.ui.success(msg)
            else
              Fontist.ui.error(msg)
            end
          end
        end
      end
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength
  end
end
