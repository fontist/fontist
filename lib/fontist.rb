require "down"
require "digest"
require "singleton"

require "fontist/errors"
require "fontist/version"

require "fontist/font"
require "fontist/source"
require "fontist/downloader"

require "fontist/registry"
require "fontist/formulas"
require "fontist/formula_finder"
require "fontist/system_font"

module Fontist
  def self.lib_path
    Fontist.root_path.join("lib")
  end

  def self.root_path
    Pathname.new(File.dirname(__dir__))
  end

  def self.assets_path
    Fontist.root_path.join("assets")
  end

  def self.data_path
    Fontist.lib_path.join("fontist", "data")
  end

  def self.fontist_path
    Pathname.new(Dir.home).join(".fontist")
  end

  def self.fonts_path
    Fontist.fontist_path.join("fonts")
  end
end
