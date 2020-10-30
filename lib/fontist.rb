require "down"
require "digest"
require "json"
require "yaml"
require "singleton"

require "fontist/errors"
require "fontist/version"

require "fontist/font"
require "fontist/registry"
require "fontist/formulas"
require "fontist/formula"
require "fontist/system_font"
require "fontist/fontist_font"
require "fontist/manifest"

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
    Pathname.new(Dir.home).join(".fontist")
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

  def self.downloads_path
    Fontist.fontist_path.join("downloads")
  end

  def self.system_file_path
    Fontist.lib_path.join("fontist", "system.yml")
  end
end
