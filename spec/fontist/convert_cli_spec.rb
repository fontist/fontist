require "spec_helper"
require "fontist/cli"
require "fontisan"

RSpec.describe Fontist::ConvertCLI do
  let(:fonts) { File.expand_path("../examples/fonts", __dir__) }
  let(:out) { Dir.mktmpdir("fontist-convert-spec") }
  let(:lato) { File.join(out, "Lato-Heavy.ttf") }
  let(:ttc) { File.join(out, "NotoSansOriya.ttc") }
  let(:vf) { File.join(out, "MonaSansMonoVF[wght].ttf") }

  before do
    FileUtils.cp(File.join(fonts, "Lato-Heavy.ttf"), out)
    FileUtils.cp(File.join(fonts, "NotoSansOriya.ttc"), out)
    FileUtils.cp(
      File.expand_path(
        "../fixtures/fonts/MonaSansVF/MonaSansMonoVF[wght].ttf", __dir__
      ),
      out,
    )
  end

  after { FileUtils.rm_rf(out) }

  def run(*args)
    Fontist::CLI.start(["convert", *args])
  end

  def magic(path)
    File.binread(path, 4)
  end

  describe "format" do
    it "writes the converted font next to the source by default" do
      expect(run("format", lato, "woff2")).to be Fontist::CLI::STATUS_SUCCESS
      expect(magic(File.join(out, "Lato-Heavy.woff2"))).to eq("wOF2")
    end

    it "writes to --output when given" do
      target = File.join(out, "web", "lato.woff")

      expect(run("format", lato, "woff", "--output", target))
        .to be Fontist::CLI::STATUS_SUCCESS
      expect(magic(target)).to eq("wOFF")
    end

    it "fails for an unknown target format" do
      expect(run("format", lato, "eot")).to be Fontist::CLI::STATUS_UNKNOWN_ERROR
    end

    it "refuses to overwrite the source font" do
      before = File.binread(lato)

      expect(run("format", lato, "ttf")).to be Fontist::CLI::STATUS_UNKNOWN_ERROR
      expect(File.binread(lato)).to eq(before)
    end

    it "fails for a missing source" do
      expect(run("format", File.join(out, "nope.ttf"), "woff2"))
        .to be Fontist::CLI::STATUS_UNKNOWN_ERROR
    end
  end

  describe "extract" do
    it "writes one collection member as a standalone font" do
      dir = File.join(out, "members")

      expect(run("extract", ttc, "--index", "1", "--output-dir", dir))
        .to be Fontist::CLI::STATUS_SUCCESS
      files = Dir.children(dir)
      expect(files.size).to eq(1)
      expect(magic(File.join(dir, files.first))).not_to eq("ttcf")
    end

    it "fails for an index outside the collection" do
      expect(run("extract", ttc, "--index", "5"))
        .to be Fontist::CLI::STATUS_UNKNOWN_ERROR
    end
  end

  describe "instance" do
    it "writes a static instance named after the axis values" do
      expect(run("instance", vf, "wght=300")).to be Fontist::CLI::STATUS_SUCCESS

      path = File.join(out, "MonaSansMonoVF-wght300.ttf")
      expect(Fontisan::FontLoader.load(path).has_table?("fvar")).to be false
    end

    it "fails for an axis the font does not have" do
      expect(run("instance", vf, "wdth=90"))
        .to be Fontist::CLI::STATUS_UNKNOWN_ERROR
    end

    it "fails for a value outside the axis range" do
      expect(run("instance", vf, "wght=1000"))
        .to be Fontist::CLI::STATUS_UNKNOWN_ERROR
    end
  end

  describe "subset" do
    it "keeps only the requested characters" do
      expect(run("subset", lato, "--text", "Hi"))
        .to be Fontist::CLI::STATUS_SUCCESS

      path = File.join(out, "Lato-Heavy-subset.ttf")
      mappings = Fontisan::FontLoader.load(path).table("cmap").unicode_mappings
      expect(mappings.keys).to include("H".ord, "i".ord)
      expect(mappings.keys).not_to include("Z".ord)
    end

    it "fails when no characters are given" do
      expect(run("subset", lato)).to be Fontist::CLI::STATUS_UNKNOWN_ERROR
    end
  end
end

RSpec.describe Fontist::CLI do
  it "reports an invalid --instance on install as an error status" do
    allow(Fontist::Font).to receive(:install)
      .and_raise(Fontist::Errors::InstanceError, "bad axis")

    expect(described_class.start(["install", "Some Font", "--instance", "x"]))
      .to be Fontist::CLI::STATUS_UNKNOWN_ERROR
  end
end
