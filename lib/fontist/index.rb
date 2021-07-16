require_relative "indexes/font_index"
require_relative "indexes/filename_index"

module Fontist
  class Index
    def self.rebuild_for_main_repo
      unless Dir.exist?(Fontist.private_formulas_path)
        return do_rebuild_for_main_repo_with
      end

      Dir.mktmpdir do |dir|
        tmp_private_path = File.join(dir, "private")
        FileUtils.mv(Fontist.private_formulas_path, tmp_private_path)

        do_rebuild_for_main_repo_with

        FileUtils.mv(tmp_private_path, Fontist.private_formulas_path)
      end
    end

    def self.do_rebuild_for_main_repo_with
      Fontist.formula_preferred_family_index_path =
        Fontist.formulas_repo_path.join("index.yml")
      Fontist.formula_filename_index_path =
        Fontist.formulas_repo_path.join("filename_index.yml")

      rebuild

      Fontist.formula_preferred_family_index_path = nil
      Fontist.formula_filename_index_path = nil
    end

    def self.rebuild
      Fontist::Indexes::DefaultFamilyFontIndex.rebuild
      Fontist::Indexes::PreferredFamilyFontIndex.rebuild
      Fontist::Indexes::FilenameIndex.rebuild

      reset_cache
    end

    def self.reset_cache
      Fontist::Indexes::DefaultFamilyFontIndex.reset_cache
      Fontist::Indexes::PreferredFamilyFontIndex.reset_cache
      Fontist::Indexes::FilenameIndex.reset_cache
    end
  end
end
