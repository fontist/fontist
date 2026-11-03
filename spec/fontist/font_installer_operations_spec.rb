require "spec_helper"
require "fontisan"

# Installer behaviour for collection-member extraction, conversion and
# subsetting, driven with local fixtures (no network).
RSpec.describe Fontist::FontInstaller do
  include_context "fresh home"
  include_context "platform test fonts"

  let(:fonts) { File.expand_path("../examples/fonts", __dir__) }
  let(:ttc) { File.join(fonts, "NotoSansOriya.ttc") }
  let(:lato) { File.join(fonts, "Lato-Heavy.ttf") }
  let(:broken_dir) { Dir.mktmpdir("fontist-broken-font") }
  # Not a font: Fontisan cannot convert it.
  let(:broken) do
    File.join(broken_dir, "broken.ttf").tap do |path|
      File.binwrite(path, "\x00\x01\x00\x00#{'garbage' * 20}")
    end
  end

  after { FileUtils.rm_rf(broken_dir) }
  let(:formula) do
    example_formula(test_formula)
    Fontist::Formula.find(test_font_downcase)
  end
  let(:license) { "yes" }

  describe "--collection-index" do
    home_it "installs member 0 as a standalone font" do
      path = install_with_operations(ttc, collection_index: 0)

      expect(File.binread(path, 4)).not_to eq("ttcf")
      expect(font_full_name(path)).to eq("Noto Sans Oriya")
    end

    home_it "installs member 1 as a different standalone font" do
      path = install_with_operations(ttc, collection_index: 1)

      expect(font_full_name(path)).to eq("Noto Sans Oriya Bold")
    end

    home_it "fails clearly when the index is out of range" do
      expect { install_with_operations(ttc, collection_index: 5) }
        .to raise_error(Fontist::Errors::CollectionIndexError, /0-1/)
    end

    home_it "installs the whole collection when no index is given" do
      path = install_with_operations(ttc)

      expect(File.binread(path, 4)).to eq("ttcf")
    end
  end

  describe "--format" do
    home_it "converts to the requested format" do
      path = install_with_operations(lato, format: "woff2")

      expect(File.extname(path)).to eq(".woff2")
      expect(File.binread(path, 4)).to eq("wOF2")
      expect(font_full_name(path)).to eq(font_full_name(lato))
    end

    home_it "does not silently install the original when conversion fails" do
      expect { install_with_operations(broken, format: "woff") }
        .to raise_error(Fontist::FontOperations::Error)
      expect(Dir.glob(File.join(Fontist.fonts_path, "**", "broken*")))
        .to be_empty
    end

    home_it "installs the original only with fallback_to_original" do
      path = install_with_operations(broken, format: "woff",
                                             fallback_to_original: true)

      expect(File.binread(path)).to eq(File.binread(broken))
    end

    home_it "does not touch the font when its format already matches" do
      path = install_with_operations(lato, format: "ttf")

      expect(File.binread(path)).to eq(File.binread(lato))
    end
  end

  describe "--subset-unicodes / --subset-text" do
    home_it "keeps only the requested characters" do
      path = install_with_operations(lato, subset_unicodes: "U+0041-0043")
      font = Fontisan::FontLoader.load(path)

      expect(font.table("cmap").unicode_mappings.keys)
        .to contain_exactly(0x41, 0x42, 0x43)
    end

    home_it "subsets by text and can be combined with conversion" do
      path = install_with_operations(lato, subset_text: "Hi", format: "woff")

      expect(File.binread(path, 4)).to eq("wOFF")
      expect(Fontisan::FontLoader.load(path).table("cmap")
        .unicode_mappings.keys).to contain_exactly(0x48, 0x69)
    end
  end

  describe "--instance" do
    let(:vf) do
      File.expand_path("../fixtures/fonts/MonaSansVF/MonaSansMonoVF[wght].ttf",
                       __dir__)
    end

    home_it "installs a static instance named after the axis values" do
      path = install_with_operations(vf, instance: "wght=300")
      font = Fontisan::FontLoader.load(path)

      expect(File.basename(path)).to eq("MonaSansMonoVF-wght300.ttf")
      expect(font.has_table?("fvar")).to be false
      expect(font.table("OS/2").us_weight_class).to eq(300)
    end

    home_it "fails clearly for an out-of-range axis value" do
      expect { install_with_operations(vf, instance: "wght=50") }
        .to raise_error(Fontist::Errors::InstanceError, /out of range/)
    end

    home_it "fails clearly for a non-variable font" do
      expect { install_with_operations(lato, instance: "wght=300") }
        .to raise_error(Fontist::Errors::InstanceError, /not a variable font/)
    end
  end

  describe "without operation options" do
    home_it "installs the file byte for byte" do
      path = install_with_operations(lato)

      expect(File.binread(path)).to eq(File.binread(lato))
    end
  end
end
