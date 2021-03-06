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
require "fontist/fontist_font"
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
    Fontist.fontist_path.join("formulas")
  end

  def self.formulas_repo_url
    "https://github.com/fontist/formulas.git"
  end

  def self.formulas_path
    Fontist.formulas_repo_path.join("Formulas")
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
    Fontist.fontist_path.join("system_index.yml")
  end

  def self.formula_index_path
    @formula_index_path || Fontist.formula_index_dir.join("formula_index.yml")
  end

  def self.formula_index_path=(path)
    @formula_index_path = path
  end

  def self.formula_filename_index_path
    @formula_filename_index_path ||
      Fontist.formula_index_dir.join("filename_index.yml")
  end

  def self.formula_filename_index_path=(path)
    @formula_filename_index_path = path
  end

  def self.formula_index_dir
    Fontist.fontist_path
  end
end
