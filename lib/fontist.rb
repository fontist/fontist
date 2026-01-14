require "down"
require "digest"
require "singleton"

require_relative "fontist/errors"
require_relative "fontist/version"
require_relative "fontist/cache/manager"
require_relative "fontist/memoizable"
require_relative "fontist/path_scanning"

module Fontist
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
    Fontist.formula_index_dir.join("formula_index.default_family.yml")
  end

  def self.formula_preferred_family_index_path
    Fontist.formula_index_dir.join("formula_index.preferred_family.yml")
  end

  def self.formula_filename_index_path
    Fontist.formula_index_dir.join("filename_index.yml")
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
    return true if Dir.exist?(Fontist.formulas_repo_path)

    raise Errors::MainRepoNotFoundError.new(
      "Please fetch formulas with `fontist update`.",
    )
  end
end

require_relative "fontist/repo"
require_relative "fontist/font"
require_relative "fontist/formula"
require_relative "fontist/system_font"
require_relative "fontist/manifest"
require_relative "fontist/manifest_response"
require_relative "fontist/manifest_request"
require_relative "fontist/helpers"
require_relative "fontist/config"
require_relative "fontist/update"
require_relative "fontist/index"
require_relative "fontist/indexes/incremental_scanner"
require_relative "fontist/indexes/directory_snapshot"
require_relative "fontist/indexes/directory_change"
require_relative "fontist/indexes/incremental_index_updater"
require_relative "fontist/indexes/font_index"
require_relative "fontist/indexes/filename_index"
require_relative "fontist/indexes/fontist_index"
require_relative "fontist/indexes/user_index"
require_relative "fontist/indexes/system_index"
require_relative "fontist/cli"
require_relative "fontist/font_installer"
require_relative "fontist/fontconfig"
require_relative "fontist/formula_picker"
require_relative "fontist/formula_suggestion"
require_relative "fontist/extract"
require_relative "fontist/font_style"
require_relative "fontist/font_collection"
require_relative "fontist/import"
require_relative "fontist/import_source"
require_relative "fontist/macos_import_source"
require_relative "fontist/google_import_source"
require_relative "fontist/sil_import_source"
require_relative "fontist/macos_framework_metadata"
