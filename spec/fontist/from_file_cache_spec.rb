require "spec_helper"

RSpec.describe Fontist::FromFileCache do
  around do |example|
    Dir.mktmpdir do |dir|
      @dir = dir
      example.run
    end
  end

  after { described_class.clear }

  def write_artifact(content, mtime:)
    path = File.join(@dir, "artifact.yml")
    File.write(path, content)
    File.utime(mtime, mtime, path)
    path
  end

  it "yields once and shares the instance while the file is unchanged" do
    path = write_artifact("content", mtime: Time.at(1000))
    calls = 0
    parser = lambda do
      calls += 1
      :parsed
    end

    first = described_class.memoize(path, &parser)
    second = described_class.memoize(path, &parser)

    expect(second).to equal(first)
    expect(calls).to eq 1
  end

  it "yields again after the file is rewritten" do
    path = write_artifact("v1", mtime: Time.at(1000))
    first = described_class.memoize(path) { :v1 }

    path = write_artifact("v2", mtime: Time.at(2000))
    second = described_class.memoize(path) { :v2 }

    expect(first).to eq :v1
    expect(second).to eq :v2
  end

  it "drops all entries on clear" do
    path = write_artifact("content", mtime: Time.at(1000))
    described_class.memoize(path) { :parsed }
    described_class.clear

    calls = 0
    described_class.memoize(path) { calls += 1 }

    expect(calls).to eq 1
  end
end

RSpec.describe "parsed artifact memoization" do
  after { Fontist::FromFileCache.clear }

  describe "Fontist::Indexes::DefaultFamilyFontIndex.from_file" do
    let(:index_class) { Fontist::Indexes::DefaultFamilyFontIndex }
    let(:filename) { index_class.path }

    it "returns the shared instance while the index file is unchanged" do
      first = index_class.from_file(filename)
      second = index_class.from_file(filename)

      expect(second).to equal(first)
    end

    it "re-parses after the index file is rewritten" do
      first = index_class.from_file(filename)

      content = File.read(filename)
      File.write(filename, content)
      stamp = Time.now + 10
      File.utime(stamp, stamp, filename)
      second = index_class.from_file(filename)

      expect(second).not_to equal(first)
    end
  end

  describe "Fontist::Formula.from_file" do
    it "returns the shared instance while the formula file is unchanged" do
      path = Fontist::Formula.find_by_name("Lato").path

      first = Fontist::Formula.from_file(path)
      second = Fontist::Formula.from_file(path)

      expect(second).to equal(first)
    end
  end
end
