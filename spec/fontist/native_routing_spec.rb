require "spec_helper"
require "fontisan"
require "tmpdir"

# fontist#540: the validator scan and the index metadata loop reach fontisan
# only through the batch Fontisan.scan, so FONTISAN_ENGINE (ruby, native, ffi
# or auto) picks the tier. Run once per tier:
#   FONTISAN_ENGINE=native FONTISAN_ENGINE_STRICT=1 rspec <this file>
RSpec.describe "Fontisan tier routing for scans" do
  let(:fonts) { Fontist.root_path.join("spec", "fixtures", "fonts") }
  let(:examples) { Fontist.root_path.join("spec", "examples", "fonts") }
  let(:dir) { Dir.mktmpdir("fontist-native-routing") }
  let(:paths) do
    FileUtils.cp(fonts.join("DejaVuSerif.ttf"), dir)
    FileUtils.cp(fonts.join("overpass-bold.otf"), dir)
    FileUtils.cp(fonts.join("MonaSansVF", "MonaSansMonoVF[wght].ttf"), dir)
    FileUtils.cp(examples.join("NotoSansOriya.ttc"), dir)
    File.binwrite(File.join(dir, "broken.ttf"), "this is not a font")
    Dir.children(dir).sort.map { |f| File.join(dir, f) }
  end
  let(:tier) do
    forced = ENV.fetch("FONTISAN_ENGINE", "")
    next forced.to_sym unless ["", "auto"].include?(forced)

    %i[native ffi ruby].find { |name| tier_available?(name) }
  end

  before do
    ensure_tier_available
    Fontisan::Engine.reset!
  end
  after do
    FileUtils.remove_entry(dir)
    Fontisan::Engine.reset!
  end

  def tier_available?(name = tier)
    case name
    when :native then Fontisan::Native.available?
    when :ffi then Fontisan::Ffi.available?
    else true
    end
  end

  # An unavailable tier skips locally but fails under FONTISAN_ENGINE_STRICT=1,
  # so a run meant to prove native or ffi cannot pass vacuously.
  def ensure_tier_available
    return if tier_available?

    message = "fontisan #{tier} tier unavailable"
    raise message if ENV["FONTISAN_ENGINE_STRICT"] == "1"

    skip message
  end

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

  def validate(list)
    validator = Fontist::Validator.new
    allow(validator).to receive(:scan_font_paths).and_return(list)
    validator.validate_all(parallel: false).results.map do |r|
      [File.basename(r.path), r.valid, r.family_name, r.full_name,
       r.error_message]
    end
  end

  def index(list)
    Fontist::SystemIndexFontCollection.new.send(:detect_paths, list)
      .map(&:to_yaml).sort
  end

  describe "Validator" do
    it "serves its batch scan through the selected tier" do
      validate(paths)

      expect(Fontisan::Engine.served_by(:scan)).to eq(tier)
    end

    it "reports exactly what the Ruby tier reports" do
      reference = with_ruby_tier { validate(paths) }

      expect(validate(paths)).to eq(reference)
      expect(reference.map { |r| r[1] }).to include(true, false)
    end
  end

  describe "index metadata loop" do
    it "serves its batch scan through the selected tier" do
      index(paths)

      expect(Fontisan::Engine.served_by(:scan)).to eq(tier)
    end

    it "indexes variable instances exactly as the Ruby tier does" do
      reference = with_ruby_tier { index(paths) }
      result = index(paths)

      expect(result).to eq(reference)
      expect(result.join).to include("MonaSans")
      expect(Fontist::ScanRowFonts.file_font(
        Fontisan.scan([paths.find { |p| p.include?("MonaSans") }]).first,
      ).variable_instances).not_to be_empty
    end
  end
end
