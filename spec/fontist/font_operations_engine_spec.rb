require "spec_helper"
require "fontisan"

# Routes FontOperations through Fontisan::Reference, so the tier chosen by
# FONTISAN_ENGINE (ruby, native or ffi) serves each operation. Run once per
# tier: FONTISAN_ENGINE=native FONTISAN_ENGINE_STRICT=1 rspec <this file>.
RSpec.describe Fontist::FontOperations, "engine routing" do
  let(:fonts) { File.expand_path("../examples/fonts", __dir__) }
  let(:ttc) { File.join(fonts, "NotoSansOriya.ttc") }
  let(:lato) { File.join(fonts, "Lato-Heavy.ttf") }
  let(:dejavu) { File.join(fonts, "DejaVuSerif.ttf") }
  let(:variable) do
    File.expand_path("../fixtures/fonts/MonaSansVF/MonaSansMonoVF[wght].ttf",
                     __dir__)
  end
  let(:out) { Dir.mktmpdir("fontist-engine-spec") }
  let(:tier) { ENV.fetch("FONTISAN_ENGINE", "ruby").to_sym }

  before { Fontisan::Engine.reset! }
  after { FileUtils.rm_rf(out) }

  def served(operation)
    Fontisan::Engine.served_by(operation)
  end

  it "serves convert through the selected tier" do
    described_class::Convert.call(lato, "woff", File.join(out, "a.woff"))

    expect(served(:convert)).to eq(tier)
  end

  it "serves extract through the selected tier" do
    described_class::Extract.call(ttc, index: 1, output_dir: out)

    expect(served(:extract)).to eq(tier)
  end

  it "serves subset through the selected tier" do
    described_class::Subset.call(dejavu, File.join(out, "s.ttf"), text: "Hi")

    expect(served(:subset)).to eq(tier)
  end

  it "serves instance through the selected tier" do
    described_class::Instance.call(
      variable, File.join(out, "i.ttf"), coordinates: "wght=400"
    )

    expect(served(:instance)).to eq(tier)
  end

  it "keeps the exact subset error text through guard" do
    expect do
      described_class::Subset.call(lato, File.join(out, "s.ttf"),
                                   unicodes: "U+4E00")
    end.to raise_error(
      Fontist::FontOperations::Error,
      "None of the requested characters exist in Lato-Heavy.ttf",
    )
  end
end
