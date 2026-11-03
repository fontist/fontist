require "spec_helper"
require "fontisan"

RSpec.describe Fontist::FontOperations do
  let(:fonts) { File.expand_path("../examples/fonts", __dir__) }
  let(:ttc) { File.join(fonts, "NotoSansOriya.ttc") }
  let(:lato) { File.join(fonts, "Lato-Heavy.ttf") }
  let(:dejavu) { File.join(fonts, "DejaVuSerif.ttf") }
  let(:out) { Dir.mktmpdir("fontist-ops-spec") }

  after { FileUtils.rm_rf(out) }

  describe Fontist::FontOperations::Extract do
    it "extracts member 0 and member 1 as distinct standalone fonts" do
      first = described_class.call(ttc, index: 0, output_dir: out)
      second = described_class.call(ttc, index: 1, output_dir: out)

      expect(font_full_name(first)).to eq("Noto Sans Oriya")
      expect(font_full_name(second)).to eq("Noto Sans Oriya Bold")
      expect(font_magic(first)).not_to eq("ttcf")
      expect(File.binread(first)).not_to eq(File.binread(second))
    end

    it "raises a clear error for an out-of-range index" do
      expect { described_class.call(ttc, index: 2, output_dir: out) }
        .to raise_error(Fontist::Errors::CollectionIndexError,
                        /index 2 out of range.*0-1/)
    end

    it "rejects a font that is not a collection" do
      expect { described_class.call(lato, index: 0, output_dir: out) }
        .to raise_error(Fontist::FontOperations::Error, /not a TTC\/OTC/)
    end
  end

  describe Fontist::FontOperations::Pack do
    it "bundles fonts into a collection that round-trips" do
      path = File.join(out, "family.ttc")
      described_class.call(path, [lato, dejavu])

      expect(font_magic(path)).to eq("ttcf")
      expect(Fontist::FontOperations::Extract.member_count(path)).to eq(2)
      expect(font_full_name(path, index: 0)).to eq(font_full_name(lato))
      expect(font_full_name(path, index: 1)).to eq(font_full_name(dejavu))
    end

    it "requires at least two fonts" do
      expect { described_class.call(File.join(out, "x.ttc"), [lato]) }
        .to raise_error(Fontist::FontOperations::Error, /at least two/)
    end

    it "rejects an unknown collection format" do
      expect { described_class.call(File.join(out, "x.zip"), [lato, dejavu]) }
        .to raise_error(Fontist::FontOperations::Error, /Unsupported/)
    end
  end

  describe Fontist::FontOperations::Convert do
    {
      "woff" => "wOFF", "woff2" => "wOF2", "otf" => "OTTO"
    }.each do |format, signature|
      it "converts ttf to #{format} with the right signature" do
        target = File.join(out, "lato.#{format}")
        described_class.call(lato, format, target)

        expect(font_magic(target)).to eq(signature)
        expect(font_full_name(target)).to eq(font_full_name(lato))
      end
    end

    it "raises when Fontisan cannot convert the font" do
      broken = File.join(out, "broken.ttf")
      File.binwrite(broken, "\x00\x01\x00\x00#{'garbage' * 20}")

      expect { described_class.call(broken, "woff", File.join(out, "b.woff")) }
        .to raise_error(Fontist::FontOperations::Error, /to woff failed/)
    end

    it "converts a CFF font to ttf (fixed in Fontisan)" do
      otf = File.expand_path("../fixtures/fonts/overpass-regular.otf", __dir__)
      target = described_class.call(otf, "ttf", File.join(out, "o.ttf"))

      expect(font_magic(target)).to eq("\x00\x01\x00\x00".b)
    end

    it "rejects unsupported target formats" do
      expect { described_class.call(lato, "ttc", File.join(out, "x.ttc")) }
        .to raise_error(Fontist::Errors::UnsupportedTranscodeError)
    end
  end

  describe Fontist::FontOperations::Subset do
    let(:subset) { File.join(out, "subset.ttf") }

    def mapped(path)
      Fontisan::FontLoader.load(path).table("cmap").unicode_mappings.keys
    end

    it "keeps only the requested unicode ranges" do
      described_class.call(dejavu, subset, unicodes: "U+0041-0043,U+00E9")

      original = Fontisan::FontLoader.load(dejavu).table("maxp").num_glyphs
      kept = Fontisan::FontLoader.load(subset).table("maxp").num_glyphs
      expect(kept).to be < original
      expect(mapped(subset)).to include(0x41, 0x42, 0x43, 0xE9)
      expect(mapped(subset)).not_to include(0x44)
    end

    it "keeps only the characters of the given text" do
      described_class.call(dejavu, subset, text: "Hi")

      expect(mapped(subset)).to contain_exactly(0x48, 0x69)
    end

    it "fails when none of the characters exist in the font" do
      expect { described_class.call(lato, subset, unicodes: "U+4E00") }
        .to raise_error(Fontist::FontOperations::Error, /None of the requested/)
    end

    it "rejects malformed unicode lists" do
      expect { described_class.call(lato, subset, unicodes: "hello") }
        .to raise_error(Fontist::FontOperations::Error, /Invalid unicode/)
    end

    it "requires something to keep" do
      expect { described_class.call(lato, subset) }
        .to raise_error(Fontist::FontOperations::Error, /No characters/)
    end
  end
end
