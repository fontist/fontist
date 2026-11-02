require "spec_helper"
require "tmpdir"
require "fontist/import/google/formula_builder"

RSpec.describe Fontist::Import::Google::FormulaBuilders::FormulaBuilderV5 do
  let(:sha) { "0123456789abcdef0123456789abcdef01234567" }
  let(:gstatic) { "https://fonts.gstatic.com/s/vfdemo/v1" }
  let(:ttf_files) do
    { "Vf Demo" => { "regular" => "#{gstatic}/a.ttf",
                     "700" => "#{gstatic}/b.ttf" } }
  end
  let(:woff2_files) do
    { "Vf Demo" => { "regular" => "#{gstatic}/a.woff2" } }
  end
  let(:axes) do
    [Fontist::Import::Google::Models::Axis.new(tag: "wght", start: 100,
                                               end: 900)]
  end
  let(:metadata) do
    path = File.expand_path(
      "../../../../fixtures/google_vf/ofl/vfdemo/METADATA.pb", __dir__
    )
    Fontist::Import::Google::Models::Metadata.from_file(path)
  end
  let(:variable_source) do
    Fontist::Import::Google::VariableFontSource.from_metadata(
      metadata, directory: "ofl/vfdemo", commit: sha
    )
  end
  let(:github_family) do
    Fontist::Import::Google::Models::FontFamily.new(family: "Vf Demo")
      .tap { |f| f.variable_source = variable_source }
  end
  let(:family) do
    Fontist::Import::Google::Models::FontFamily.new(family: "Vf Demo",
                                                    axes: axes)
  end
  let(:builder) do
    described_class.new(family, github_index: { "Vf Demo" => github_family },
                                ttf_files: ttf_files, woff2_files: woff2_files)
  end
  let(:formula) { builder.build }

  before do
    allow(Fontist::Utils::Downloader).to receive(:download) do |url|
      double(path: url)
    end
    allow(Fontist::Import::FontMetadataExtractor).to receive(:new) do |url|
      double(extract: double(
        family_name: "Vf Demo", subfamily_name: "Regular",
        full_name: "Vf Demo #{File.basename(url)}",
        postscript_name: "VfDemo-#{File.basename(url, '.*')}",
        version: "1.0", copyright: "c", preferred_family_name: nil,
        preferred_subfamily_name: nil, description: nil
      ))
    end
    allow(builder).to receive(:sleep)
  end

  def all_styles
    formula[:fonts].flat_map { |font| font["styles"] }
  end

  context "with a variable family" do
    it "points ttf_variable at the real variable files pinned to the commit" do
      expect(formula[:resources]["ttf_variable"]["urls"]).to eq(
        [
          "https://raw.githubusercontent.com/google/fonts/#{sha}/ofl/vfdemo/VfDemo[wdth,wght].ttf",
          "https://raw.githubusercontent.com/google/fonts/#{sha}/ofl/vfdemo/VfDemo-Italic[wght].ttf",
        ],
      )
    end

    it "serializes without YAML anchors from shared arrays" do
      expect(YAML.dump(formula[:resources]["ttf_variable"])).not_to match(/&\d/)
      expect(YAML.dump(formula[:fonts])).not_to match(/&\d/)
    end

    it "declares the axis tags of the variable files" do
      expect(formula[:resources]["ttf_variable"]["variable_axes"])
        .to eq(%w[wdth wght])
    end

    it "never offers API static files as variable" do
      urls = formula[:resources].select { |k, _| k.end_with?("_variable") }
        .values.flat_map { |r| r["urls"] }
      expect(urls.grep(/gstatic/)).to be_empty
    end

    it "emits no woff2_variable because Google publishes no variable woff2" do
      expect(formula[:resources]).not_to have_key("woff2_variable")
    end

    it "keeps the API files as static resources without axes" do
      expect(formula[:resources]["ttf_static"]).to include(
        "urls" => ["#{gstatic}/a.ttf", "#{gstatic}/b.ttf"], "format" => "ttf",
      )
      expect(formula[:resources]["ttf_static"]).not_to have_key("variable_axes")
      expect(formula[:resources]["woff2_static"]["urls"])
        .to eq(["#{gstatic}/a.woff2"])
    end

    it "marks only styles served by the variable files as variable" do
      variable, static = all_styles.partition { |s| s["variable_font"] }

      expect(variable.map { |s| s["font"] }).to eq(
        ["VfDemo[wdth,wght].ttf", "VfDemo-Italic[wght].ttf"],
      )
      expect(variable.map { |s| s["variable_axes"] })
        .to eq([%w[wdth wght], %w[wght]])
      expect(static.map { |s| s["font"] }).to eq(%w[a.ttf b.ttf])
      expect(static.map { |s| s["variable_font"] }).to all(be(false))
    end
  end

  context "with a variable family whose variable file is not in google/fonts" do
    let(:github_family) do
      Fontist::Import::Google::Models::FontFamily.new(family: "Vf Demo")
    end

    it "emits no variable resource and no variable styles" do
      expect(formula[:resources].keys).to eq(%w[ttf_static woff2_static])
      expect(all_styles.map { |s| s["variable_font"] }).to all(be(false))
    end
  end

  context "with a static family" do
    let(:axes) { [] }
    let(:github_family) do
      Fontist::Import::Google::Models::FontFamily.new(family: "Vf Demo")
    end

    it "keeps static resources and non-variable styles" do
      expect(formula[:resources].keys).to eq(%w[ttf_static woff2_static])
      expect(all_styles).to all(
        include("variable_font" => false, "formats" => a_kind_of(Array))
          .and(satisfy { |s| !s.key?("source_resource") }),
      )
    end
  end
end
