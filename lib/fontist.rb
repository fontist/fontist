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

  def self.formulas_path
    Fontist.lib_path.join("fontist", "formulas")
  end
end

# Loading formulas
#
# The formula loading behavior is dynamic, so what we are actualy
# doing here is looking for formulas in the `./fontist/formulas` directory
# then require thos as we go.
#
# There is a caviat, since the `Dir` method depends on absoulate path
# so moving this loading up or somewhere else might not always ensure
# the fontist related path helpers.
#
Dir[Fontist.formulas_path.join("**/*.rb").to_s].sort.each do |file|
  require file
end
