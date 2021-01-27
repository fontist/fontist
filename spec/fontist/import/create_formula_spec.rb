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

  context "with 404 mirror" do
    let(:archive_name) { "Lato2OFL.zip" }
    let(:options) { { mirror: ["https://example.com/not_found_url"] } }

    it "outputs a warning message", dev: true do
      require "fontist/import/create_formula"
      expect(Fontist.ui).to receive(:error)
        .with("WARN: a mirror is not found 'https://example.com/not_found_url'")
      formula
    end
  end

  context "with different SHA256 mirrors" do
    let(:url) { "https://gitlab.com/fontmirror/archive/-/raw/master/VistaFont_KOR.EXE" } # rubocop:disable Metrics/LineLength
    let(:options) { { mirror: ["https://download.microsoft.com/download/0/3/e/03e8f61e-be04-4cbd-8007-85a544fec76b/VistaFont_KOR.EXE"] } } # rubocop:disable Metrics/LineLength

    it "outputs a warning message", dev: true do
      require "fontist/import/create_formula"
      expect(Fontist.ui).to receive(:error)
        .with("WARN: SHA256 differs (db5da6c17b02f1e6359aa8c019d9666abdf2e3438d08e77fb4b1576b6023b9f9, c5fe8a36856c7aac913b5a64cf23c9ba1afc07ac538529d61b0e08dbefd2975a)") # rubocop:disable Metrics/LineLength
      formula
    end
  end

  context "with specified subarchive archive" do
    let(:url) { "https://gitlab.com/fontmirror/langpacks/-/raw/master/OfficeLangPack2013_HE_x86.exe" } # rubocop:disable Metrics/LineLength
    let(:options) { { subarchive: "officelr.cab", name: "Guttman" } }

    it "generates proper yaml", dev: true do
      require "fontist/import/create_formula"
      expect(formula).to include example
    end
  end

  context "with collection which has unusual extension" do
    let(:url) { "https://gitlab.com/fontmirror/langpacks/-/raw/master/OfficeLangPack2013_KO_x86.exe" } # rubocop:disable Metrics/LineLength
    let(:options) { { subarchive: "officelr.cab", name: "Korean" } }

    it "generates proper yaml", dev: true do
      require "fontist/import/create_formula"
      expect(formula).to include example
    end
  end

  context "with specified subdir option" do
    let(:url) { "https://github.com/weiweihuanghuang/Work-Sans/archive/v2.010.zip" } # rubocop:disable Metrics/LineLength
    let(:options) { { subdir: "Work-Sans-2.010/fonts/static/*" } }

    it "generates proper yaml", dev: true do
      require "fontist/import/create_formula"
      expect(formula).to include example
    end
  end

  context "rpm archive" do
    let(:url) { "https://download.opensuse.org/repositories/home:/alteratio:/Common/openSUSE_13.2/src/webcore-fonts-3.0-2.1.src.rpm" } # rubocop:disable Metrics/LineLength
    let(:options) { { name: "webcore" } }

    it "generates proper yaml", dev: true do
      require "fontist/import/create_formula"
      expect(formula).to include example
    end
  end
end
