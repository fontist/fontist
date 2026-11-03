require "spec_helper"

RSpec.describe "variable font index entries" do
  # One variable file carries every named instance in its fvar table, but
  # the name table exposes only the default instance's family. Without
  # per-instance index entries, find_styles can only ever see the default
  # family and every other family/style lookup of the same file misses.
  let(:vf_path) do
    File.expand_path("../fixtures/fonts/MonaSansVF/MonaSansMonoVF[wght].ttf",
                     __dir__)
  end

  describe "Fontist::FontFile#variable_instances" do
    let(:font_file) { Fontist::FontFile.from_path(vf_path) }

    it "expands every named instance" do
      expect(font_file.variable_instances.map { |i| i[:style] })
        .to eq(["Regular", "Regular", "Regular", "Regular", "Regular",
                "Bold", "Regular", "Regular"])
    end

    it "keeps Regular and Bold on the base family" do
      families = font_file.variable_instances.map { |i| i[:family] }

      expect(families).to include("Mona Sans Mono VF")
      expect(families.count("Mona Sans Mono VF")).to eq(2)
    end

    it "gives non-RIBBI weights their own family" do
      families = font_file.variable_instances.map { |i| i[:family] }

      expect(families).to include("Mona Sans Mono VF Light",
                                  "Mona Sans Mono VF SemiBold",
                                  "Mona Sans Mono VF Black")
    end

    it "does not double the style in the full name" do
      full_names = font_file.variable_instances.map { |i| i[:full_name] }

      expect(full_names).to include("Mona Sans Mono VF Regular",
                                    "Mona Sans Mono VF Bold",
                                    "Mona Sans Mono VF Light")
    end

    it "returns no instances for a static font" do
      static = File.expand_path("../fixtures/fonts/DejaVuSerif.ttf", __dir__)
      font_file = Fontist::FontFile.from_path(static)

      expect(font_file.variable_instances).to be_empty
    end
  end

  describe "the fontist index" do
    include_context "fresh home"

    before do
      FileUtils.cp(vf_path, File.join(temp_dir, "MonaSansMonoVF[wght].ttf"))
      allow(Fontist).to receive(:fonts_path).and_return(Pathname.new(temp_dir))
      Fontist::Indexes::FontistIndex.reset_cache
    end

    after { Fontist::Indexes::FontistIndex.reset_cache }

    def index
      Fontist::Indexes::FontistIndex.instance
    end

    it "finds the base family without a style" do
      expect(index.find("Mona Sans Mono VF")).not_to be_nil
    end

    it "finds the Bold style of the base family" do
      found = index.find("Mona Sans Mono VF", "Bold")

      expect(found).not_to be_nil
      expect(found.map(&:path).uniq).to eq([File.join(temp_dir,
                                                      "MonaSansMonoVF[wght].ttf")])
    end

    it "finds a non-RIBBI weight under its own family" do
      expect(index.find("Mona Sans Mono VF SemiBold", "Regular")).not_to be_nil
    end

    it "resolves through SystemFont.find_styles" do
      found = Fontist::SystemFont.find_styles("Mona Sans Mono VF", "Bold")

      expect(found.map(&:path)).to include(
        File.join(temp_dir, "MonaSansMonoVF[wght].ttf"),
      )
    end
  end
end
