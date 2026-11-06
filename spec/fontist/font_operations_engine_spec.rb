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

  before do
    ensure_tier_available
    Fontisan::Engine.reset!
  end
  after do
    FileUtils.rm_rf(out)
    Fontisan::Engine.reset!
  end

  # Unavailable tier: skip locally, but under FONTISAN_ENGINE_STRICT=1 fail,
  # so a run that is meant to prove native or ffi can never pass vacuously.
  def ensure_tier_available
    return if tier_available?

    message = "fontisan #{tier} tier unavailable"
    raise message if ENV["FONTISAN_ENGINE_STRICT"] == "1"

    skip message
  end

  # Runs the block with the Ruby tier forced, for reference output.
  def with_ruby_tier
    saved = ENV.values_at("FONTISAN_ENGINE", "FONTISAN_ENGINE_STRICT")
    ENV["FONTISAN_ENGINE"] = "ruby"
    ENV.delete("FONTISAN_ENGINE_STRICT")
    Fontisan::Engine.reset!
    yield
  ensure
    ENV["FONTISAN_ENGINE"], ENV["FONTISAN_ENGINE_STRICT"] = saved
    Fontisan::Engine.reset!
  end

  def error_message
    yield
    nil
  rescue StandardError => e
    "#{e.class}: #{e.message}"
  end

  def bytes_of(path)
    File.binread(path)
  end

  # WOFF2 compression is not byte-deterministic (two Ruby runs differ), so
  # compare what the file decodes to.
  def structure_of(path)
    font = Fontisan::FontLoader.load(path)
    [font.table_names.sort, font.table("maxp").num_glyphs]
  end

  def tier_available?
    case tier
    when :native then Fontisan::Native.available?
    when :ffi then Fontisan::Ffi.available?
    else true
    end
  end

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

  describe "parity with the Ruby tier" do
    let(:garbage) do
      File.join(out, "garbage.ttf").tap do |f|
        File.binwrite(f, "not a font" * 20)
      end
    end

    it "extracts byte-identical members" do
      mine = described_class::Extract.call(ttc, index: 1, output_dir: out)
      ref_dir = Dir.mktmpdir("fontist-engine-ref")
      theirs = with_ruby_tier do
        described_class::Extract.call(ttc, index: 1, output_dir: ref_dir)
      end

      expect(bytes_of(mine)).to eq(bytes_of(theirs))
    ensure
      FileUtils.rm_rf(ref_dir)
    end

    it "writes the same variable-font instance" do
      mine = described_class::Instance.call(
        variable, File.join(out, "i.ttf"), coordinates: "wght=400"
      )
      theirs = with_ruby_tier do
        described_class::Instance.call(
          variable, File.join(out, "ref.ttf"), coordinates: "wght=400"
        )
      end

      expect(bytes_of(mine)).to eq(bytes_of(theirs))
    end

    it "writes the same subset" do
      mine = described_class::Subset.call(dejavu, File.join(out, "s.ttf"),
                                          text: "Hi")
      theirs = with_ruby_tier do
        described_class::Subset.call(dejavu, File.join(out, "ref.ttf"),
                                     text: "Hi")
      end

      expect(bytes_of(mine)).to eq(bytes_of(theirs))
    end

    %w[ttf otf woff woff2].each do |target|
      it "converts to #{target} with equivalent output" do
        mine = described_class::Convert.call(
          lato, target, File.join(out, "a.#{target}")
        )
        theirs = with_ruby_tier do
          described_class::Convert.call(
            lato, target, File.join(out, "ref.#{target}")
          )
        end

        if target == "woff2"
          expect(structure_of(mine)).to eq(structure_of(theirs))
        else
          expect(bytes_of(mine)).to eq(bytes_of(theirs))
        end
      end
    end

    it "raises the same convert error for an unreadable source" do
      run = -> {
        described_class::Convert.call(garbage, "woff", File.join(out, "g.woff"))
      }
      mine = error_message(&run)

      expect(mine).not_to be_nil
      expect(mine).to eq(with_ruby_tier { error_message(&run) })
    end

    it "raises the same subset error for an unreadable source" do
      run = -> {
        described_class::Subset.call(garbage, File.join(out, "g.ttf"),
                                     text: "A")
      }
      mine = error_message(&run)

      expect(mine).not_to be_nil
      expect(mine).to eq(with_ruby_tier { error_message(&run) })
    end

    it "raises the same extract error for an unreadable collection" do
      run = -> {
        described_class::Extract.call(garbage, index: 0, output_dir: out)
      }
      mine = error_message(&run)

      expect(mine).not_to be_nil
      expect(mine).to eq(with_ruby_tier { error_message(&run) })
    end

    it "keeps the Ruby axis check before the tier is consulted" do
      run = lambda do
        described_class::Instance.call(variable, File.join(out, "x.ttf"),
                                       coordinates: "wght=99999")
      end
      mine = error_message(&run)

      expect(mine).to match(/out of range/)
      expect(mine).to eq(with_ruby_tier { error_message(&run) })
    end
  end
end
