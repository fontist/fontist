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
      expect(found.map(&:path).uniq)
        .to eq([File.join(temp_dir, "MonaSansMonoVF[wght].ttf")])
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

RSpec.describe "stale v1 index self-heal" do
  include_context "fresh home"

  let(:vf_path) do
    File.expand_path("../fixtures/fonts/MonaSansVF/MonaSansMonoVF[wght].ttf",
                     __dir__)
  end

  def index
    Fontist::Indexes::FontistIndex.instance
  end

  it "rebuilds a v1-generation index on the first lookup" do
    FileUtils.cp(vf_path, File.join(temp_dir, "MonaSansMonoVF[wght].ttf"))
    allow(Fontist).to receive(:fonts_path).and_return(Pathname.new(temp_dir))
    index.rebuild
    expect(index.fonts.size).to be > 1

    # Simulate a volume persisted by a pre-v2 fontist: one entry per
    # file, generation stamp absent (0).
    v1 = index.fonts.select { |f| f.family_name.include?("ExtraLight") }
    expect(v1).not_to be_empty
    index.collection.fonts = v1
    index.collection.persist_metadata
    metadata = YAML.load_file(index.collection.metadata_path.to_s)
    metadata["format_version"] = 1
    File.write(index.collection.metadata_path, YAML.dump(metadata))
    Fontist::Indexes::FontistIndex.reset_cache

    healed = Fontist::Indexes::FontistIndex.instance
    found = healed.find("Mona Sans Mono VF", "Bold")

    expect(found).not_to be_nil
    expect(healed.fonts.size).to be > 1
  end
end

RSpec.describe "stale format detection scoping" do
  it "does not flag an in-process collection as stale" do
    collection = Fontist::SystemIndexFontCollection.new

    expect(collection.stale_format?).to be false
  end

  it "flags a persisted index whose metadata predates the current generation" do
    Dir.mktmpdir do |dir|
      index_path = File.join(dir, "system_index.yml")
      collection = Fontist::SystemIndexFontCollection.new
      collection.set_path(index_path)
      collection.persist_metadata

      metadata = YAML.load_file(collection.metadata_path.to_s)
      metadata["format_version"] = 1
      File.write(collection.metadata_path, YAML.dump(metadata))

      reloaded = Fontist::SystemIndexFontCollection.from_file(
        path: index_path,
        paths_loader: -> { [] },
      )

      expect(reloaded.stale_format?).to be true
    end
  end
end
