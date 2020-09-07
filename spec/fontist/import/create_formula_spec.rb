require "spec_helper"

RSpec.describe "Fontist::Import::CreateFormula" do
  let(:formula) { fixtures_dir { YAML.load_file(formula_file) } }
  let(:formula_file) { Fontist::Import::CreateFormula.new(url).call }
  let(:url) { "../examples/archives/#{archive_name}" }

  let(:example) { YAML.load_file(example_file) }
  let(:example_file) { "spec/examples/formulas/#{formula_file}" }

  context "zip archive" do
    let(:archive_name) { "_2.6.6 Euphemia UCAS.zip" }

    it "generates proper yaml", dev: true do
      require "fontist/import/create_formula"
      expect(formula).to include example
    end
  end

  context "contains collection fonts" do
    let(:archive_name) { "source_example.zip" }

    it "generates proper yaml", slow: true, dev: true do
      require "fontist/import/create_formula"
      expect(formula).to include example
    end
  end

  context "contains license" do
    let(:archive_name) { "Lato2OFL.zip" }

    it "generates proper yaml", slow: true, dev: true do
      require "fontist/import/create_formula"
      expect(formula).to include example
    end
  end
end
