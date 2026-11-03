require "spec_helper"

RSpec.describe Fontist::Indexes::DefaultFamilyFontIndex do
  let(:index_class) { described_class }
  let(:yaml_path) { index_class.path }
  let(:sidecar_path) { "#{yaml_path}.json" }

  after { Fontist::FromFileCache.clear }

  describe "lookup sidecar" do
    before do
      index_class.from_file(yaml_path)
    end

    it "writes a JSON sidecar beside the index file" do
      expect(File.exist?(sidecar_path)).to be(true)

      parsed = JSON.parse(File.read(sidecar_path))
      expect(parsed).to have_key("entries")
      expect(parsed["entries"].keys).not_to be_empty
    end

    it "resolves formulas identically through the lookup path" do
      full = index_class.from_file(yaml_path).load_formulas("lato")
      fast = index_class.lookup_index.load_formulas("lato")

      expect(fast.map(&:name)).to eq(full.map(&:name))
      expect(fast.size).to eq(full.size)
    end

    it "returns key-to-path entries through the lookup path" do
      key = JSON.parse(File.read(sidecar_path))["entries"].keys.first
      full = index_class.from_file(yaml_path).load_index_formulas(key)
      fast = index_class.lookup_index.load_index_formulas(key)

      expect(fast.first.formula_path).to eq(full.first.formula_path)
    end

    it "regenerates a stale sidecar" do
      File.write(sidecar_path, "{}")
      stamp = Time.now - 3600
      File.utime(stamp, stamp, sidecar_path)

      fast = index_class.lookup_index.load_formulas("lato")

      expect(fast.map(&:name)).to eq(["Lato"])
      entries = JSON.parse(File.read(sidecar_path))["entries"]
      expect(entries.keys).not_to be_empty
    end

    it "falls back to the index file when the sidecar is corrupt" do
      File.write(sidecar_path, "{not json")
      stamp = Time.now + 3600
      File.utime(stamp, stamp, sidecar_path)

      fast = index_class.lookup_index.load_formulas("lato")

      expect(fast.map(&:name)).to eq(["Lato"])
    end

    it "memoizes parsed sidecar entries between lookups" do
      first = index_class.sidecar_entries
      second = index_class.sidecar_entries

      expect(first).not_to be_nil
      expect(second).to equal(first)
    end

    it "picks up sidecar rewrites on the next lookup" do
      index_class.sidecar_entries

      rewritten = JSON.parse(File.read(sidecar_path))
      rewritten["entries"]["zzz-custom"] = ["x.yml"]
      File.write(sidecar_path, JSON.dump(rewritten))

      entries = index_class.sidecar_entries

      expect(entries["zzz-custom"]).to eq(["x.yml"])
    end

    it "drops the memo when the index cache is reset" do
      first = index_class.sidecar_entries
      index_class.reset_cache

      index_class.from_file(yaml_path)
      second = index_class.sidecar_entries

      expect(second).not_to equal(first)
    end
  end
end
