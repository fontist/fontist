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
require "fontist/formula_template"

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

  def self.load_formulas
    Dir[Fontist.formulas_path.join("**/*.yml").to_s].sort.each do |file|
      create_formula_class(file)
    end
  end

  def self.create_formula_class(file)
    formula = parse_to_object(YAML.load_file(file))
    return if Formulas.const_defined?("#{formula.name}Font")

    klass = FormulaTemplate.create_formula_class(formula)
    Formulas.const_set("#{formula.name}Font", klass)
  end

  def self.parse_to_object(hash)
    JSON.parse(hash.to_json, object_class: OpenStruct)
  end
end

Fontist.load_formulas
