require "fontist/version"
require "fontist/source"
require "fontist/finder"

module Fontist
  class Error < StandardError; end

  def self.lib_path
    Fontist.root_path.join("lib")
  end

  def self.root_path
    Pathname.new(File.dirname(__dir__))
  end
end
