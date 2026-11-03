require "spec_helper"
require "fontist/import/sil_importer"

RSpec.describe "Fontist::Import::SilImporter", slow: true, dev: true do
  let(:formulas_repo_path) { Pathname.new(create_tmp_dir) }

  let(:fonts_under_test) { ["Apparatus SIL"] }

  it "finds archive links and calls CreateFormula" do
    VCR.use_cassette("sil_import") do
      require "fontist/import/sil_importer"

      allow(Fontist).to receive(:formulas_repo_path)
        .and_return(formulas_repo_path)

      Dir.mktmpdir do |index_dir|
        allow(Fontist).to receive(:formula_index_dir)
          .and_return(Pathname.new(index_dir))

        allow_any_instance_of(Fontist::Import::SilImporter)
          .to receive(:font_links).and_wrap_original do |m, *args|
            m.call(*args).select do |tag|
              fonts_under_test.include?(tag.content)
            end
          end

        received_count = 0
        allow_any_instance_of(Fontist::Import::CreateFormula)
          .to receive(:call) { received_count += 1 }

        # Test with new interface
        importer = Fontist::Import::SilImporter.new
        result = importer.call

        expect(received_count).to be 1
        expect(result).to be_a(Hash)
        expect(result[:successful]).to eq(1)

        expect(Fontist.formulas_path.join("sil")).to exist
      end
    end
  end
end

RSpec.describe Fontist::Import::SilImporter do
  subject(:importer) { described_class.new }

  describe "#initialize" do
    it "accepts no options (backward compatible)" do
      importer = described_class.new
      expect(importer.send(:formula_dir)).to be_a(Pathname)
    end

    it "accepts output_path option" do
      importer = described_class.new(output_path: "/tmp/test")
      expect(importer.send(:formula_dir).to_s).to eq("/tmp/test")
    end

    it "accepts font_name option" do
      importer = described_class.new(font_name: "Charis")
      expect(importer.instance_variable_get(:@font_name)).to eq("Charis")
    end

    it "accepts verbose option" do
      importer = described_class.new(verbose: true)
      expect(importer.instance_variable_get(:@verbose)).to be true
    end
  end

  describe "#filter_by_name" do
    let(:links) do
      html = <<~HTML
        <table class="products">
          <tr><td><div class="title"><a href="/charis">Charis SIL</a></div></td></tr>
          <tr><td><div class="title"><a href="/andika">Andika</a></div></td></tr>
          <tr><td><div class="title"><a href="/apparatus">Apparatus SIL</a></div></td></tr>
        </table>
      HTML
      Nokogiri::HTML.parse(html).css("table.products div.title > a")
    end

    it "filters links by font name (case insensitive)" do
      importer = described_class.new(font_name: "charis")
      filtered = importer.send(:filter_by_name, links)
      expect(filtered.size).to eq(1)
      expect(filtered.first.content).to eq("Charis SIL")
    end

    it "returns multiple matches if applicable" do
      importer = described_class.new(font_name: "sil")
      filtered = importer.send(:filter_by_name, links)
      expect(filtered.size).to eq(2)
    end
  end

  describe "#font_links" do
    let(:fonts_page) { instance_double(URI::HTTPS) }

    before do
      allow(URI).to receive(:parse).and_call_original
      allow(URI).to receive(:parse)
        .with(described_class::ROOT).and_return(fonts_page)
      allow(fonts_page).to receive(:open).and_return(StringIO.new(page_html))
    end

    let(:page_html) do
      <<~HTML
        <div class="inner-wrapper cust-card all-cards">
          <div class="card"><a class="inner-card Supported" href="https://software.sil.org/charis">
            <div class="title-txt"><h2 class="title-text notranslate">Charis</h2></div>
            <div class="content"><p>A serif Latin and Cyrillic script font, similar to Bitstream Charter.</p></div>
          </a></div>
          <div class="card"><a class="inner-card Supported" href="https://software.sil.org/andika">
            <div class="title-txt"><h2 class="title-text notranslate">Andika</h2></div>
            <div class="content"><p>A sans serif font designed for literacy use.</p></div>
          </a></div>
        </div>
      HTML
    end

    it "reads the font cards of the current SIL fonts page" do
      importer = described_class.new

      links = importer.send(:font_links)

      expect(links.map { |link| importer.send(:link_name, link) })
        .to eq(%w[Charis Andika])
      expect(links.map { |link| link[:href] })
        .to eq(%w[https://software.sil.org/charis https://software.sil.org/andika])
    end

    it "matches a font name against the card title, not its description" do
      importer = described_class.new(font_name: "serif")

      links = importer.send(:filter_by_name, importer.send(:font_links))

      expect(links).to be_empty
    end

    context "with the legacy products table" do
      let(:page_html) do
        <<~HTML
          <table class="products"><tr><td>
            <div class="title"><a href="/charis">Charis SIL</a></div>
          </td></tr></table>
        HTML
      end

      it "reads the product links" do
        importer = described_class.new

        names = importer.send(:font_links)
          .map { |link| importer.send(:link_name, link) }

        expect(names).to eq(["Charis SIL"])
      end
    end
  end

  describe "#call with no matching fonts" do
    it "reports that no fonts were found" do
      importer = described_class.new(font_name: "NoSuchFont")
      allow(importer).to receive(:font_links).and_return([])

      expect(importer.call).to include(no_fonts_found: true, successful: 0)
    end
  end

  describe "#extract_version_from_url" do
    it "extracts version from standard SIL URL format" do
      url = "https://software.sil.org/downloads/r/charis/CharisSIL-6.200.zip"
      expect(importer.send(:extract_version_from_url, url)).to eq("6.200")
    end

    it "extracts version from URL with dash separator" do
      url = "https://example.com/fonts/Andika-6.101.zip"
      expect(importer.send(:extract_version_from_url, url)).to eq("6.101")
    end

    it "extracts version from URL with underscore separator" do
      url = "https://example.com/fonts/Font_1.5.2.zip"
      expect(importer.send(:extract_version_from_url, url)).to eq("1.5.2")
    end

    it "extracts two-part version" do
      url = "https://example.com/fonts/Font-2.1.tar.gz"
      expect(importer.send(:extract_version_from_url, url)).to eq("2.1")
    end

    it "handles version with 'v' prefix" do
      url = "https://example.com/fonts/Font-v3.0.zip"
      expect(importer.send(:extract_version_from_url, url)).to eq("3.0")
    end

    it "returns nil when no version found" do
      url = "https://example.com/fonts/SomeFont.zip"
      expect(importer.send(:extract_version_from_url, url)).to be_nil
    end
  end

  describe "#create_import_source" do
    it "creates SilImportSource with version and timestamp" do
      source = importer.send(:create_import_source, "6.200")

      expect(source).to be_a(Fontist::SilImportSource)
      expect(source.version).to eq("6.200")
      expect(source.release_date).to match(/^\d{4}-\d{2}-\d{2}T/)
    end

    it "returns nil when version is nil" do
      source = importer.send(:create_import_source, nil)
      expect(source).to be_nil
    end

    it "creates import_source with differentiation_key" do
      source = importer.send(:create_import_source, "1.5.0")
      expect(source.differentiation_key).to eq("1.5.0")
    end
  end

  describe "#call" do
    it "returns results hash" do
      importer = described_class.new
      allow(importer).to receive(:font_links).and_return([])

      result = importer.call

      expect(result).to be_a(Hash)
      expect(result).to have_key(:successful)
      expect(result).to have_key(:failed)
      expect(result).to have_key(:duration)
      expect(result).to have_key(:errors)
    end
  end
end
