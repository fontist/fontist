require "spec_helper"
require "fontisan"

# Mona Sans Mono VF (wght 200-900), SIL OFL 1.1: spec/fixtures/fonts/MonaSansVF.
RSpec.describe Fontist::FontOperations::Instance do
  let(:vf) do
    File.expand_path("../fixtures/fonts/MonaSansVF/MonaSansMonoVF[wght].ttf",
                     __dir__)
  end
  let(:static_font) do
    File.expand_path("../examples/fonts/Lato-Heavy.ttf", __dir__)
  end
  let(:out) { Dir.mktmpdir("fontist-instance-spec") }

  after { FileUtils.rm_rf(out) }

  describe ".call" do
    it "writes static instances whose outlines follow the axis value" do
      light = described_class.call(vf, File.join(out, "l.ttf"),
                                   coordinates: { "wght" => 300 })
      bold = described_class.call(vf, File.join(out, "b.ttf"),
                                  coordinates: "wght=700")

      expect(Fontisan::FontLoader.load(light).has_table?("fvar")).to be false
      expect(Fontisan::FontLoader.load(light).table_data["glyf"])
        .not_to eq(Fontisan::FontLoader.load(bold).table_data["glyf"])
      expect(Fontisan::FontLoader.load(bold).table("OS/2").us_weight_class)
        .to eq(700)
    end

    it "rejects a value outside the axis range, naming the range" do
      expect do
        described_class.call(vf, File.join(out, "x.ttf"),
                             coordinates: "wght=1000")
      end.to raise_error(Fontist::Errors::InstanceError,
                         /wght=1000.*out of range.*200-900/)
    end

    it "rejects an axis the font does not have" do
      expect do
        described_class.call(vf, File.join(out, "x.ttf"),
                             coordinates: "wdth=90")
      end.to raise_error(Fontist::Errors::InstanceError,
                         /no axis 'wdth'.*wght/)
    end

    it "rejects a non-variable font" do
      expect do
        described_class.call(static_font, File.join(out, "x.ttf"),
                             coordinates: "wght=300")
      end.to raise_error(Fontist::Errors::InstanceError, /not a variable font/)
    end

    it "rejects malformed or empty axis lists" do
      expect { described_class.call(vf, out, coordinates: "wght:300") }
        .to raise_error(Fontist::Errors::InstanceError, /Invalid instance/)
      expect { described_class.call(vf, out, coordinates: "") }
        .to raise_error(Fontist::Errors::InstanceError, /No axis values/)
    end

    it "fails for a missing source" do
      expect do
        described_class.call(File.join(out, "none.ttf"), out,
                             coordinates: "wght=300")
      end.to raise_error(Fontist::Errors::SourceNotFoundError)
    end
  end

  describe ".parse" do
    it "reads several axes" do
      expect(described_class.parse("wght=300, wdth=90.5"))
        .to eq("wght" => 300.0, "wdth" => 90.5)
    end
  end

  describe ".file_name" do
    it "drops the axis brackets and adds the instance" do
      expect(described_class.file_name("Mona[wght,wdth].ttf",
                                       "wght" => 300.0, "wdth" => 90.0))
        .to eq("Mona-wght300-wdth90.ttf")
    end
  end
end
