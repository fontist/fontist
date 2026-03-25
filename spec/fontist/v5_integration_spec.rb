require "spec_helper"
require "fontist/formula"
require "fontist/format_spec"
require "fontist/format_matcher"
require "fontist/font_finder"

RSpec.describe "V5 Integration" do
  let(:fixture_path) { File.expand_path("../examples/formulas/roboto_v5.yml", __dir__) }
  let(:formula) { Fontist::Formula.from_file(fixture_path) }

  describe "v5 formula loading" do
    it "loads with schema_version 5" do
      expect(formula.schema_version).to eq(5)
      expect(formula.v5?).to be true
    end

    it "loads resources with format metadata" do
      expect(formula.resources).not_to be_empty

      ttf_resource = formula.resources.find { |r| r.name == "ttf_static" }
      expect(ttf_resource).not_to be_nil
      expect(ttf_resource.format).to eq("ttf")
      expect(ttf_resource.source).to eq("google")
      expect(ttf_resource.family).to eq("Roboto")
    end

    it "loads resources with separate files and urls" do
      ttf_resource = formula.resources.find { |r| r.name == "ttf_static" }
      expect(ttf_resource.files).to eq(["Roboto-Regular.ttf", "Roboto-Bold.ttf"])
      expect(ttf_resource.urls).to include(
        "https://fonts.gstatic.com/s/roboto/v30/Roboto-Regular.ttf"
      )
    end

    it "loads variable axes on variable resources" do
      variable = formula.resources.find { |r| r.name == "woff2_variable" }
      expect(variable.variable_font?).to be true
      expect(variable.variable_axes).to eq(%w[wght wdth])
    end

    it "loads font styles with v5 metadata" do
      style = formula.fonts.first.styles.first
      expect(style.formats).to eq(%w[ttf woff2])
      expect(style.variable_font).to eq(false)
      expect(style.variable_font?).to be false
    end

  end

  describe "format-specific resource selection" do
    it "selects woff2 resources with --format=woff2" do
      spec = Fontist::FormatSpec.new(format: "woff2")
      matching = formula.matching_resources(spec)
      expect(matching.map(&:format).uniq).to eq(["woff2"])
      expect(matching.size).to eq(2)
    end

    it "selects ttf resources with --format=ttf" do
      spec = Fontist::FormatSpec.new(format: "ttf")
      matching = formula.matching_resources(spec)
      expect(matching.map(&:format).uniq).to eq(["ttf"])
      expect(matching.size).to eq(1)
    end

    it "returns all resources with no format constraint" do
      matching = formula.matching_resources(nil)
      expect(matching.size).to eq(3)
    end
  end

  describe "variable font resource selection" do
    it "selects variable resources with prefer_variable" do
      spec = Fontist::FormatSpec.new(prefer_variable: true)
      matcher = Fontist::FormatMatcher.new(spec)
      matching = matcher.filter_resources(formula.resources)
      expect(matching.all?(&:variable_font?)).to be true
      expect(matching.size).to eq(1)
    end

    it "selects resources with matching axes" do
      spec = Fontist::FormatSpec.new(variable_axes: %w[wght wdth])
      matcher = Fontist::FormatMatcher.new(spec)
      matching = matcher.filter_resources(formula.resources)
      expect(matching.size).to eq(1)
      expect(matching.first.name).to eq("woff2_variable")
    end

    it "rejects resources missing required axes" do
      spec = Fontist::FormatSpec.new(variable_axes: %w[wght wdth ital])
      matcher = Fontist::FormatMatcher.new(spec)
      matching = matcher.filter_resources(formula.resources)
      expect(matching).to be_empty
    end
  end

  describe "FormatMatcher with v5 styles" do
    it "filters styles by format" do
      spec = Fontist::FormatSpec.new(format: "woff2")
      matcher = Fontist::FormatMatcher.new(spec)
      styles = formula.fonts.first.styles
      matching = matcher.filter_styles(styles)
      expect(matching.size).to eq(2) # Both styles have woff2 in formats
    end

    it "excludes styles without matching format" do
      spec = Fontist::FormatSpec.new(format: "otf")
      matcher = Fontist::FormatMatcher.new(spec)
      styles = formula.fonts.first.styles
      matching = matcher.filter_styles(styles)
      expect(matching).to be_empty
    end
  end
end
