require "down"
require "digest"
require "singleton"
require "lutaml/model"

require_relative "fontist/errors"
require_relative "fontist/version"
require_relative "fontist/cache/manager"
require_relative "fontist/memoizable"
require_relative "fontist/path_scanning"
require_relative "fontist/utils"

module Fontist
  # Core classes
  autoload :Config, "fontist/config"
  autoload :Font, "fontist/font"
  autoload :FontCollection, "fontist/font_collection"
  autoload :FontFile, "fontist/font_file"
  autoload :FontInstaller, "fontist/font_installer"
  autoload :FontModel, "fontist/font_model"
  autoload :FontPath, "fontist/font_path"
  autoload :FontStyle, "fontist/font_style"
  autoload :Fontconfig, "fontist/fontconfig"
  autoload :Formula, "fontist/formula"
  autoload :FormulaCollection, "fontist/formula"
  autoload :FormulaPicker, "fontist/formula_picker"
  autoload :FormulaSuggestion, "fontist/formula_suggestion"
  autoload :Helpers, "fontist/helpers"
  autoload :Import, "fontist/import"

  # Import namespace
  module Import
    autoload :ConvertFormulas, "fontist/import/convert_formulas"
    autoload :CreateFormula, "fontist/import/create_formula"
    autoload :FontMetadataExtractor, "fontist/import/font_metadata_extractor"
    autoload :FontParsingErrorCollector, "fontist/import/font_parsing_error_collector"
    autoload :FontStyle, "fontist/import/font_style"
    autoload :FormulaBuilder, "fontist/import/formula_builder"
    autoload :FormulaSerializer, "fontist/import/formula_serializer"
    autoload :Google, "fontist/import/google"
    autoload :GoogleFontsImporter, "fontist/import/google_fonts_importer"
    autoload :GoogleImport, "fontist/import/google_import"
    autoload :ImportDisplay, "fontist/import/import_display"
    autoload :Macos, "fontist/import/macos"
    autoload :ManualFormulaBuilder, "fontist/import/manual_formula_builder"
    autoload :RecursiveExtraction, "fontist/import/recursive_extraction"
    autoload :SilImport, "fontist/import/sil_import"
    autoload :TextHelper, "fontist/import/text_helper"
    autoload :TemplateHelper, "fontist/import/template_helper"
    autoload :UpgradeFormulas, "fontist/import/upgrade_formulas"

    module Helpers
      autoload :HashHelper, "fontist/import/helpers/hash_helper"
      autoload :SystemHelper, "fontist/import/helpers/system_helper"
    end

    module Files
      autoload :CollectionFile, "fontist/import/files/collection_file"
      autoload :FontDetector, "fontist/import/files/font_detector"
    end

    module Models
      autoload :FontMetadata, "fontist/import/models/font_metadata"
    end

    module Otf
      autoload :FontFile, "fontist/import/otf/font_file"
    end

    module Google
      autoload :Api, "fontist/import/google/api"
      autoload :FontDatabase, "fontist/import/google/font_database"
      autoload :MetadataAdapter, "fontist/import/google/metadata_adapter"
      autoload :MetadataParser, "fontist/import/google/metadata_parser"

      module DataSources
        autoload :Base, "fontist/import/google/data_sources/base"
        autoload :Github, "fontist/import/google/data_sources/github"
        autoload :Ttf, "fontist/import/google/data_sources/ttf"
        autoload :Vf, "fontist/import/google/data_sources/vf"
        autoload :Woff2, "fontist/import/google/data_sources/woff2"
      end

      module Models
        autoload :Axis, "fontist/import/google/models/axis"
        autoload :AxisMetadata, "fontist/import/google/models/axis_metadata"
        autoload :FileMetadata, "fontist/import/google/models/file_metadata"
        autoload :FontFamily, "fontist/import/google/models/font_family"
        autoload :FontFileMetadata, "fontist/import/google/models/font_file_metadata"
        autoload :FontVariant, "fontist/import/google/models/font_variant"
        autoload :Metadata, "fontist/import/google/models/metadata"
        autoload :SourceMetadata, "fontist/import/google/models/source_metadata"
      end
    end
  end
  autoload :ImportSource, "fontist/import_source"
  autoload :InstallLocation, "fontist/install_location"
  autoload :StyleVersion, "fontist/style_version"
  autoload :Update, "fontist/update"

  # Index classes
  autoload :Index, "fontist/index"
  autoload :IndexEntry, "fontist/index"
  autoload :IndexStats, "fontist/system_index"
  autoload :SystemIndexFont, "fontist/system_index"
  autoload :SystemIndexFontCollection, "fontist/system_index"
  autoload :SystemIndex, "fontist/system_index"

  # Data models
  autoload :CollectionFile, "fontist/collection_file"
  autoload :Extract, "fontist/extract"
  autoload :ExtractOptions, "fontist/extract"
  autoload :Resource, "fontist/formula"
  autoload :ResourceCollection, "fontist/formula"

  # Font sources
  autoload :GoogleImportSource, "fontist/google_import_source"
  autoload :MacosImportSource, "fontist/macos_import_source"
  autoload :SilImportSource, "fontist/sil_import_source"
  autoload :MacosFrameworkMetadata, "fontist/macos_framework_metadata"

  # Manifest classes
  autoload :Manifest, "fontist/manifest"
  autoload :ManifestFont, "fontist/manifest"
  autoload :ManifestRequest, "fontist/manifest_request"
  autoload :ManifestRequestFont, "fontist/manifest_request"
  autoload :ManifestResponse, "fontist/manifest_response"
  autoload :ManifestResponseFont, "fontist/manifest_response"
  autoload :ManifestResponseFontStyle, "fontist/manifest_response"

  # System
  autoload :Info, "fontist/repo"
  autoload :Repo, "fontist/repo"
  autoload :SystemFont, "fontist/system_font"

  # CLI
  autoload :CLI, "fontist/cli"
  autoload :CacheCLI, "fontist/cache_cli"
  autoload :ConfigCLI, "fontist/config_cli"
  autoload :FontconfigCLI, "fontist/fontconfig_cli"
  autoload :ImportCLI, "fontist/import_cli"
  autoload :IndexCLI, "fontist/index_cli"
  autoload :ManifestCLI, "fontist/manifest_cli"
  autoload :RepoCLI, "fontist/repo_cli"
  autoload :ThorExt, "fontist/cli/thor_ext"
  autoload :Validation, "fontist/validation"
  autoload :ValidationReport, "fontist/validation"
  autoload :ValidationCache, "fontist/validation"
  autoload :FontValidationResult, "fontist/validation"
  autoload :Validator, "fontist/validator"
  autoload :ValidateCLI, "fontist/validate_cli"

  # Indexes namespace
  module Indexes
    autoload :BaseFontCollectionIndex, "fontist/indexes/base_font_collection_index"
    autoload :DefaultFamilyFontIndex, "fontist/indexes/default_family_font_index"
    autoload :DirectoryChange, "fontist/indexes/directory_change"
    autoload :DirectorySnapshot, "fontist/indexes/directory_snapshot"
    autoload :FilenameIndex, "fontist/indexes/filename_index"
    autoload :FontIndex, "fontist/indexes/font_index"
    autoload :FontistIndex, "fontist/indexes/fontist_index"
    autoload :FormulaKeyToPath, "fontist/indexes/formula_key_to_path"
    autoload :IncrementalIndexUpdater, "fontist/indexes/incremental_index_updater"
    autoload :IncrementalScanner, "fontist/indexes/incremental_scanner"
    autoload :IndexMixin, "fontist/indexes/index_mixin"
    autoload :PreferredFamilyFontIndex, "fontist/indexes/preferred_family_font_index"
    autoload :SystemIndex, "fontist/indexes/system_index"
    autoload :UserIndex, "fontist/indexes/user_index"
  end

  # Install locations namespace
  module InstallLocations
    autoload :BaseLocation, "fontist/install_locations/base_location"
    autoload :FontistLocation, "fontist/install_locations/fontist_location"
    autoload :SystemLocation, "fontist/install_locations/system_location"
    autoload :UserLocation, "fontist/install_locations/user_location"
  end

  # Utils namespace
  module Utils
    autoload :Cache, "fontist/utils/cache"
    autoload :Downloader, "fontist/utils/downloader"
    autoload :FileMagic, "fontist/utils/file_magic"
    autoload :FileOps, "fontist/utils/file_ops"
    autoload :GitHubClient, "fontist/utils/github_client"
    autoload :GitHubUrl, "fontist/utils/github_url"
    autoload :Locking, "fontist/utils/locking"
    autoload :System, "fontist/utils/system"
    autoload :UI, "fontist/utils/ui"
  end

  # Resources namespace
  module Resources
    autoload :AppleCDNResource, "fontist/resources/apple_cdn_resource"
    autoload :ArchiveResource, "fontist/resources/archive_resource"
    autoload :GoogleResource, "fontist/resources/google_resource"
  end

  # Cache namespace
  module Cache
    autoload :Store, "fontist/cache/store"
  end

  # Macos namespace
  module Macos
    module Catalog
      autoload :Asset, "fontist/macos/catalog/asset"
      autoload :BaseParser, "fontist/macos/catalog/base_parser"
      autoload :CatalogManager, "fontist/macos/catalog/catalog_manager"
      autoload :Font3Parser, "fontist/macos/catalog/font3_parser"
      autoload :Font4Parser, "fontist/macos/catalog/font4_parser"
      autoload :Font5Parser, "fontist/macos/catalog/font5_parser"
      autoload :Font6Parser, "fontist/macos/catalog/font6_parser"
      autoload :Font7Parser, "fontist/macos/catalog/font7_parser"
      autoload :Font8Parser, "fontist/macos/catalog/font8_parser"
    end
  end

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
