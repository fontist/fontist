require "libmspack"
require "fontist/version"

require "fontist/finder"
require "fontist/source"
require "fontist/system_font"
require "fontist/ms_vista_font"

module Fontist
  class Error < StandardError; end

  def self.lib_path
    Fontist.root_path.join("lib")
  end

  def self.root_path
    Pathname.new(File.dirname(__dir__))
  end

  def self.assets_path
    Fontist.root_path.join("assets")
  end

  def self.fonts_path
    Fontist.assets_path.join("fonts")
  end
end
