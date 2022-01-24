require "down"
require "digest"
require "json"
require "yaml"
require "singleton"

require "fontist/errors"
require "fontist/version"

require "fontist/repo"
require "fontist/font"
require "fontist/formula"
require "fontist/system_font"
require "fontist/manifest"
require "fontist/helpers"

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
    Fontist.fontist_path.join("fonts")
  end

  def self.formulas_repo_path
    Fontist.fontist_version_path.join("formulas")
  end

  def self.fontist_version_path
    Fontist.fontist_path.join("versions", formulas_version)
  end

  def self.formulas_version
    "v3"
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

  def self.system_file_path
    Fontist.lib_path.join("fontist", "system.yml")
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

  def self.log_level=(level)
    Fontist.ui.level = level
  end
end
