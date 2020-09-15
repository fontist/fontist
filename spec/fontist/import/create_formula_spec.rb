require "spec_helper"

RSpec.describe "Fontist::Import::CreateFormula" do
  let(:formula) { fixtures_dir { YAML.load_file(formula_file) } }
  let(:formula_file) { Fontist::Import::CreateFormula.new(url, options).call }
  let(:url) { "../examples/archives/#{archive_name}" }
  let(:options) { {} }

  let(:example) { YAML.load_file(example_file) }
  let(:example_file) { "spec/examples/formulas/#{formula_file}" }

  context "zip archive" do
    let(:archive_name) { "_2.6.6 Euphemia UCAS.zip" }

    it "generates proper yaml", dev: true do
      require "fontist/import/create_formula"
      expect(formula).to include example
    end
  end

  context "msi archive" do
    let(:url) { "http://ardownload.adobe.com/pub/adobe/reader/win/AcrobatDC/misc/FontPack1902120058_XtdAlf_Lang_DC.msi" } # rubocop:disable Metrics/LineLength
    let(:options) { { name: "Adobe Reader 19", mirror: ["https://web.archive.org/web/20200816153035/http://ardownload.adobe.com/pub/adobe/reader/win/AcrobatDC/misc/FontPack1902120058_XtdAlf_Lang_DC.msi"] } } # rubocop:disable Metrics/LineLength

    it "generates proper yaml", dev: true do
      require "fontist/import/create_formula"
      expect(formula).to include example
    end
  end

  context "7z archive" do
    let(:url) { "http://ardownload.adobe.com/pub/adobe/reader/win/AcrobatDC/2001220041/AcroRdrDC2001220041_en_US.exe" } # rubocop:disable Metrics/LineLength
    let(:options) { { name: "Adobe Reader 20" } }

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
