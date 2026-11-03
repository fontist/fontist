require "spec_helper"
require "fontist/cli"
require "fontisan"

RSpec.describe Fontist::CLI do
  let(:fonts) { File.expand_path("../examples/fonts", __dir__) }
  let(:lato) { File.join(fonts, "Lato-Heavy.ttf") }
  let(:dejavu) { File.join(fonts, "DejaVuSerif.ttf") }
  let(:out) { Dir.mktmpdir("fontist-pack-spec") }

  after { FileUtils.rm_rf(out) }

  describe "pack" do
    it "writes a collection and exits successfully" do
      target = File.join(out, "family.ttc")
      status = described_class.start(["pack", target, lato, dejavu])

      expect(status).to be Fontist::CLI::STATUS_SUCCESS
      expect(File.binread(target, 4)).to eq("ttcf")
      expect(Fontist::FontOperations::Extract.member_count(target)).to eq(2)
    end

    it "fails with a non-zero status for a single font" do
      target = File.join(out, "one.ttc")
      status = described_class.start(["pack", target, lato])

      expect(status).to be Fontist::CLI::STATUS_UNKNOWN_ERROR
      expect(File.exist?(target)).to be false
    end
  end

  describe "install options" do
    it "passes collection, subset and fallback options into the format spec" do
      received = nil
      allow(Fontist::Font).to receive(:install) do |_name, options|
        received = Fontist::FormatSpec.from_options(options)
        []
      end

      described_class.start(
        ["install", "Some Font", "--collection-index", "1",
         "--subset-unicodes", "U+0020-007E", "--subset-text", "abc",
         "--format", "woff2", "--fallback-to-original"],
      )

      expect(received.collection_index).to eq(1)
      expect(received.subset_unicodes).to eq("U+0020-007E")
      expect(received.subset_text).to eq("abc")
      expect(received.format).to eq("woff2")
      expect(received.fallback_to_original).to be true
    end
  end
end
