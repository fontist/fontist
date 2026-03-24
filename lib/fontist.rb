require "down"
require "digest"
require "singleton"
require "pathname"
require "lutaml/model"

require_relative "fontist/errors"
require_relative "fontist/version"
require_relative "fontist/cache"
require_relative "fontist/memoizable"
require_relative "fontist/path_scanning"
require_relative "fontist/utils"

module Fontist
  # Core classes
  autoload :Config, "#{__dir__}/fontist/config"
  autoload :Font, "#{__dir__}/fontist/font"
  autoload :FontCollection, "#{__dir__}/fontist/font_collection"
  autoload :FontFile, "#{__dir__}/fontist/font_file"
  autoload :FontInstaller, "#{__dir__}/fontist/font_installer"
  autoload :FontModel, "#{__dir__}/fontist/font_model"
  autoload :FontPath, "#{__dir__}/fontist/font_path"
  autoload :FontStyle, "#{__dir__}/fontist/font_style"
  autoload :Fontconfig, "#{__dir__}/fontist/fontconfig"
  autoload :Formula, "#{__dir__}/fontist/formula"
  autoload :FormulaCollection, "#{__dir__}/fontist/formula"
  autoload :FormulaPicker, "#{__dir__}/fontist/formula_picker"
  autoload :FormulaSuggestion, "#{__dir__}/fontist/formula_suggestion"
  autoload :Helpers, "#{__dir__}/fontist/helpers"
  autoload :Import, "#{__dir__}/fontist/import"
  autoload :ImportSource, "#{__dir__}/fontist/import_source"
  autoload :InstallLocation, "#{__dir__}/fontist/install_location"
  autoload :StyleVersion, "#{__dir__}/fontist/style_version"
  autoload :Update, "#{__dir__}/fontist/update"

  # Index classes
  autoload :Index, "#{__dir__}/fontist/index"
  autoload :IndexEntry, "#{__dir__}/fontist/index"
  autoload :IndexStats, "#{__dir__}/fontist/system_index"
  autoload :SystemIndexFont, "#{__dir__}/fontist/system_index"
  autoload :SystemIndexFontCollection, "#{__dir__}/fontist/system_index"
  autoload :SystemIndex, "#{__dir__}/fontist/system_index"

  # Data models
  autoload :CollectionFile, "#{__dir__}/fontist/collection_file"
  autoload :Extract, "#{__dir__}/fontist/extract"
  autoload :ExtractOptions, "#{__dir__}/fontist/extract"
  autoload :Resource, "#{__dir__}/fontist/resource"
  autoload :ResourceCollection, "#{__dir__}/fontist/resource_collection"

  # Font sources
  autoload :GoogleImportSource, "#{__dir__}/fontist/google_import_source"
  autoload :MacosImportSource, "#{__dir__}/fontist/macos_import_source"
  autoload :SilImportSource, "#{__dir__}/fontist/sil_import_source"
  autoload :MacosFrameworkMetadata, "#{__dir__}/fontist/macos_framework_metadata"

  # Manifest classes
  autoload :Manifest, "#{__dir__}/fontist/manifest"
  autoload :ManifestFont, "#{__dir__}/fontist/manifest"
  autoload :ManifestRequest, "#{__dir__}/fontist/manifest_request"
  autoload :ManifestRequestFont, "#{__dir__}/fontist/manifest_request"
  autoload :ManifestResponse, "#{__dir__}/fontist/manifest_response"
  autoload :ManifestResponseFont, "#{__dir__}/fontist/manifest_response"
  autoload :ManifestResponseFontStyle, "#{__dir__}/fontist/manifest_response"

  # System
  autoload :Info, "#{__dir__}/fontist/repo"
  autoload :Repo, "#{__dir__}/fontist/repo"
  autoload :SystemFont, "#{__dir__}/fontist/system_font"

  # CLI
  autoload :CLI, "#{__dir__}/fontist/cli"
  autoload :CacheCLI, "#{__dir__}/fontist/cache_cli"
  autoload :ConfigCLI, "#{__dir__}/fontist/config_cli"
  autoload :FontconfigCLI, "#{__dir__}/fontist/fontconfig_cli"
  autoload :ImportCLI, "#{__dir__}/fontist/import_cli"
  autoload :IndexCLI, "#{__dir__}/fontist/index_cli"
  autoload :ManifestCLI, "#{__dir__}/fontist/manifest_cli"
  autoload :RepoCLI, "#{__dir__}/fontist/repo_cli"
  autoload :ThorExt, "#{__dir__}/fontist/cli/thor_ext"
  autoload :Validation, "#{__dir__}/fontist/validation"
  autoload :ValidationReport, "#{__dir__}/fontist/validation"
  autoload :ValidationCache, "#{__dir__}/fontist/validation"
  autoload :FontValidationResult, "#{__dir__}/fontist/validation"
  autoload :Validator, "#{__dir__}/fontist/validator"
  autoload :ValidateCLI, "#{__dir__}/fontist/validate_cli"

  # Namespace modules
  autoload :Indexes, "#{__dir__}/fontist/indexes"
  autoload :InstallLocations, "#{__dir__}/fontist/install_locations"
  autoload :Resources, "#{__dir__}/fontist/resources"
  autoload :Macos, "#{__dir__}/fontist/macos"

  def self.ui
    Fontist::Utils::UI
  end

  def self.lib_path
    Fontist.root_path.join("lib")
  end

  def self.root_path
    Pathname.new(File.dirname(__dir__))
  end

  def self.fontist_path
    Pathname.new(ENV["FONTIST_PATH"] || default_fontist_path)
  end

  def self.default_fontist_path
    Pathname.new(File.join(Dir.home, ".fontist"))
  end

  def self.fonts_path
    Pathname.new(config[:fonts_path])
  end

  def self.formulas_repo_path
    Fontist.fontist_version_path.join("formulas")
  end

  def self.fontist_version_path
    Fontist.fontist_path.join("versions", formulas_version)
  end

  def self.formulas_version
    "v4"
  end

  def self.formulas_repo_url
    "https://github.com/fontist/formulas.git"
  end

  def self.formulas_path
    @formulas_path || Fontist.formulas_repo_path.join("Formulas")
  end

  def self.formulas_path=(path)
    @formulas_path = path
  end

  def self.private_formulas_path
    Fontist.formulas_path.join("private")
  end

  def self.downloads_path
    Fontist.fontist_path.join("downloads")
  end

  def self.import_cache_path=(path)
    @import_cache_path = Pathname.new(path) if path
  end

  def self.import_cache_path
    @import_cache_path ||
      (ENV["FONTIST_IMPORT_CACHE"] ? Pathname.new(ENV["FONTIST_IMPORT_CACHE"]) : nil) ||
      Fontist.fontist_path.join("import_cache")
  end

  def self.system_file_path
    Fontist.lib_path.join("fontist", "system.yml")
  end

  def self.excluded_fonts_path
    Fontist.lib_path.join("fontist", "exclude.yml")
  end

  def self.system_index_path
    Fontist.fontist_path.join("system_index.default_family.yml")
  end

  def self.system_preferred_family_index_path
    Fontist.fontist_path.join("system_index.preferred_family.yml")
  end

  def self.fontist_index_path
    Fontist.fontist_path.join("fontist_index.default_family.yml")
  end

  def self.fontist_preferred_family_index_path
    Fontist.fontist_path.join("fontist_index.preferred_family.yml")
  end

  def self.user_index_path
    Fontist.fontist_path.join("user_index.default_family.yml")
  end

  def self.user_preferred_family_index_path
    Fontist.fontist_path.join("user_index.preferred_family.yml")
  end

  def self.formula_index_path
    formula_index_dir.join("formula_index.default_family.yml")
  end

  def self.formula_preferred_family_index_path
    formula_index_dir.join("formula_index.preferred_family.yml")
  end

  def self.formula_filename_index_path
    formula_index_dir.join("filename_index.yml")
  end

  def self.formula_index_dir
    Fontist.fontist_version_path
  end

  def self.formula_size_limit_in_megabytes
    300
  end

  def self.preferred_family?
    !!@preferred_family
  end

  def self.preferred_family=(bool)
    @preferred_family = bool
  end

  def self.open_timeout
    config[:open_timeout]
  end

  def self.read_timeout
    config[:read_timeout]
  end

  def self.config
    Fontist::Config.instance.values
  end

  def self.config_path
    Fontist.fontist_path.join("config.yml")
  end

  def self.use_cache?
    instance_variable_defined?(:@use_cache) ? @use_cache : true
  end

  def self.use_cache=(bool)
    @use_cache = bool
  end

  def self.log_level=(level)
    Fontist.ui.level = level
  end

  def self.interactive?
    @interactive || false
  end

  def self.interactive=(bool)
    @interactive = bool
  end

  def self.auto_overwrite
    return @auto_overwrite if defined?(@auto_overwrite)

    nil
  end

  def self.auto_overwrite=(value)
    @auto_overwrite = value
  end

  def self.google_fonts_key
    ENV["GOOGLE_FONTS_API_KEY"] || config[:google_fonts_key]
  end

  def self.formulas_repo_path_exists!
    return true if Dir.exist?(Fontist.formulas_repo_path.join("Formulas"))

    # Auto-update formulas repo if it doesn't exist (lazy initialization).
    # This ensures formulas are always discoverable without requiring
    # explicit `fontist update`.
    Formula.update_formulas_repo

    true
  end
end
