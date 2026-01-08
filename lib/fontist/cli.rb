require "thor"
require_relative "../fontist"
require_relative "cli/class_options"
require_relative "cli/thor_ext"
require_relative "repo_cli"
require_relative "cache_cli"
require_relative "import_cli"
require_relative "fontconfig_cli"
require_relative "config_cli"
require_relative "index_cli"
require_relative "manifest_cli"

module Fontist
  class CLI < Thor
    include ClassOptions
    extend ThorExt::Start

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
    STATUS_FONTCONFIG_NOT_FOUND = 14
    STATUS_FONTCONFIG_FILE_NOT_FOUND = 15
    STATUS_FONTIST_VERSION_ERROR = 15
    STATUS_INVALID_CONFIG_ATTRIBUTE = 16

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
      Fontist::Errors::FontconfigNotFoundError => [STATUS_FONTCONFIG_NOT_FOUND],
      Fontist::Errors::FontconfigFileNotFoundError =>
        [STATUS_FONTCONFIG_FILE_NOT_FOUND],
      Fontist::Errors::FontistVersionError => [STATUS_FONTIST_VERSION_ERROR],
    }.freeze

    def self.exit_on_failure?
      false
    end

    desc "version", "Show fontist version"
    def version
      handle_class_options(options)
      Fontist.ui.say("fontist: #{Fontist::VERSION}")

      # Show formulas repository information if available
      if Dir.exist?(Fontist.formulas_repo_path)
        begin
          require "git"
          repo = Git.open(Fontist.formulas_repo_path)
          repo_url = repo.config["remote.origin.url"] || Fontist.formulas_repo_url
          branch = repo.current_branch
          # Use execute.first for git gem ~> 4.0 compatibility
          log_entry = repo.log(1).execute.first
          revision = log_entry.sha[0..6]
          updated = repo.gcommit(log_entry.sha).date.strftime("%Y-%m-%d")

          Fontist.ui.say("formulas:")
          Fontist.ui.say("  repo: #{repo_url}")
          Fontist.ui.say("  version: #{Fontist.formulas_version}")
          Fontist.ui.say("  branch: #{branch}")
          Fontist.ui.say("  commit: #{revision}")
          Fontist.ui.say("  updated: #{updated}")
        rescue StandardError => e
          Fontist.ui.debug("Could not read formulas repository info: #{e.message}")
        end
      end

      STATUS_SUCCESS
    end

    desc "install FONT...", "Install one or more fonts"
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
    option :update_fontconfig, type: :boolean, aliases: :u,
                               desc: "Update fontconfig"
    option :location,
           type: :string, aliases: :l,
           enum: ["fontist", "user", "system"],
           desc: "Install location: fontist (default), user, system"
    def install(*fonts)
      handle_class_options(options)

      if fonts.empty?
        return error("Please specify at least one font to install.",
                     STATUS_UNKNOWN_ERROR)
      end

      # For backward compatibility, use original behavior for single font
      if fonts.size == 1
        confirmation = options[:accept_all_licenses] ? "yes" : "no"
        install_options = options.to_h.transform_keys(&:to_sym)
        install_options[:confirmation] = confirmation
        install_options[:location] = options[:location]&.to_sym if options[:location]

        Fontist::Font.install(fonts.first, install_options)
        return success
      end

      # Multi-font installation
      confirmation = options[:accept_all_licenses] ? "yes" : "no"
      install_options = options.to_h.transform_keys(&:to_sym)
      install_options[:confirmation] = confirmation
      install_options[:location] = options[:location]&.to_sym if options[:location]

      result = Fontist::Font.install_many(fonts, install_options)

      # Report results
      if result[:successes].any?
        Fontist.ui.success("Successfully installed #{result[:successes].size} font(s): #{result[:successes].join(', ')}")
      end

      if result[:failures].any?
        Fontist.ui.error("Failed to install #{result[:failures].size} font(s):")
        result[:failures].each do |failure|
          _, mode, message = ERROR_TO_STATUS[failure[:error].class]
          text = if message && mode == :overwrite
                   message
                 elsif message
                   "#{failure[:error].message} #{message}"
                 else
                   failure[:error].message
                 end
          Fontist.ui.error("  - #{failure[:font]}: #{text}")
        end
      end

      # Return appropriate status code
      return STATUS_SUCCESS if result[:failures].empty?

      # If all failed, return the status of the first error
      first_error = result[:failures].first[:error]
      status, = ERROR_TO_STATUS[first_error.class]
      status || STATUS_UNKNOWN_ERROR
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
      if paths.empty?
        return error("No font is installed.",
                     STATUS_MISSING_FONT_ERROR)
      end

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

    desc "manifest SUBCOMMAND ...ARGS", "Manage font manifests"
    subcommand "manifest", Fontist::ManifestCLI

    desc "create-formula URL", "Create a new formula with fonts from URL"
    option :name, desc: "Example: Times New Roman"
    option :mirror, repeatable: true
    option :subdir, desc: "Subdirectory to take fonts from, starting with the " \
                          "root dir, e.g.: stixfonts-2.10/fonts/static_otf. May include `fnmatch` patterns."
    option :file_pattern, desc: "File pattern, e.g. '*.otf'. " \
                                "Uses `fnmatch` patterns."
    option :name_prefix, desc: "Prefix to add to all font family names, " \
                               "e.g. 'Wine ' for compatibility fonts"
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

    desc "macos-catalogs", "List available macOS font catalogs"
    def macos_catalogs
      handle_class_options(options)
      require_relative "macos/catalog/catalog_manager"

      catalogs = Fontist::Macos::Catalog::CatalogManager.available_catalogs

      if catalogs.empty?
        Fontist.ui.error("No macOS font catalogs found.")
        Fontist.ui.say("Expected location: /System/Library/AssetsV2/")
        Fontist.ui.say("\nYou can specify a catalog manually with:")
        Fontist.ui.say("  fontist import macos --plist path/to/com_apple_MobileAsset_FontX.xml")
        return STATUS_UNKNOWN_ERROR
      end

      Fontist.ui.say("Available macOS Font Catalogs:")
      catalogs.each do |catalog_path|
        version = Fontist::Macos::Catalog::CatalogManager.detect_version(catalog_path)
        size = File.size(catalog_path)
        size_str = format_bytes(size)

        Fontist.ui.say("  Font#{version}: #{catalog_path} (#{size_str})")
      end

      Fontist.ui.say("\nTo import a catalog:")
      Fontist.ui.say("  fontist import macos --plist <path>")

      STATUS_SUCCESS
    end

    desc "repo SUBCOMMAND ...ARGS", "Manage custom repositories"
    subcommand "repo", Fontist::RepoCLI

    desc "import SUBCOMMAND ...ARGS", "Manage imports"
    subcommand "import", Fontist::ImportCLI

    desc "fontconfig SUBCOMMAND ...ARGS", "Manage fontconfig"
    subcommand "fontconfig", Fontist::FontconfigCLI

    desc "config SUBCOMMAND ...ARGS", "Manage fontist config"
    subcommand "config", Fontist::ConfigCLI

    desc "cache SUBCOMMAND ...ARGS", "Manage fontist cache"
    subcommand "cache", Fontist::CacheCLI

    desc "index SUBCOMMAND ...ARGS", "Manage system font index"
    subcommand "index", Fontist::IndexCLI

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

    def format_bytes(bytes)
      if bytes < 1024
        "#{bytes} B"
      elsif bytes < 1024 * 1024
        "#{(bytes / 1024.0).round(1)} KB"
      else
        "#{(bytes / (1024.0 * 1024)).round(1)} MB"
      end
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
            opts << (installed ? "installed" : "not installed")
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
