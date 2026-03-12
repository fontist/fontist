module Fontist
  module Indexes
    autoload :BaseFontCollectionIndex, "#{__dir__}/indexes/base_font_collection_index"
    autoload :DefaultFamilyFontIndex, "#{__dir__}/indexes/default_family_font_index"
    autoload :DirectoryChange, "#{__dir__}/indexes/directory_change"
    autoload :DirectorySnapshot, "#{__dir__}/indexes/directory_snapshot"
    autoload :FilenameIndex, "#{__dir__}/indexes/filename_index"
    autoload :FontIndex, "#{__dir__}/indexes/font_index"
    autoload :FontistIndex, "#{__dir__}/indexes/fontist_index"
    autoload :FormulaKeyToPath, "#{__dir__}/indexes/formula_key_to_path"
    autoload :IncrementalIndexUpdater, "#{__dir__}/indexes/incremental_index_updater"
    autoload :IncrementalScanner, "#{__dir__}/indexes/incremental_scanner"
    autoload :IndexMixin, "#{__dir__}/indexes/index_mixin"
    autoload :PreferredFamilyFontIndex, "#{__dir__}/indexes/preferred_family_font_index"
    autoload :SystemIndex, "#{__dir__}/indexes/system_index"
    autoload :UserIndex, "#{__dir__}/indexes/user_index"
  end
end
