require "spec_helper"

RSpec.describe Fontist::FromFileCache do
  around do |example|
    Dir.mktmpdir do |dir|
      @dir = dir
      example.run
    end
  end

  after do
    described_class.clear
    described_class.max_entries = Fontist::FromFileCache::DEFAULT_MAX_ENTRIES
  end

  def write_artifact(content, mtime:, name: "artifact.yml")
    path = File.join(@dir, name)
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

  it "serves correct values when called from parallel threads" do
    paths = Array.new(8) do |i|
      name = "artifact-#{i}.yml"
      write_artifact("v#{i}", mtime: Time.at(1000 + i), name: name)
    end
    parses = Queue.new

    threads = paths.map do |path|
      Thread.new do
        described_class.memoize(path) do
          parses << 1
          File.read(path)
        end
      end
    end
    threads.each(&:join)

    expect(parses.size).to eq 8

    results = paths.map do |path|
      described_class.memoize(path) { raise "cache hit expected" }
    end

    expect(results).to eq Array.new(8) { |i| "v#{i}" }
  end

  it "evicts the oldest entry when the cache exceeds its bound" do
    described_class.max_entries = 2

    a = write_artifact("a", mtime: Time.at(1000), name: "a.yml")
    b = write_artifact("b", mtime: Time.at(1000), name: "b.yml")
    c = write_artifact("c", mtime: Time.at(1000), name: "c.yml")
    described_class.memoize(a) { :a }
    described_class.memoize(b) { :b }
    described_class.memoize(c) { :c }

    expect(described_class.memoize(a) { :refetched }).to eq :refetched
    expect(described_class.memoize(b) { :b }).to eq :b
    expect(described_class.memoize(c) { :c }).to eq :c
  end

  it "keeps a recently used entry alive over an untouched one" do
    described_class.max_entries = 2

    a = write_artifact("a", mtime: Time.at(1000), name: "a.yml")
    b = write_artifact("b", mtime: Time.at(1000), name: "b.yml")
    described_class.memoize(a) { :a }
    described_class.memoize(b) { :b }

    described_class.memoize(a) { raise "cache hit expected" }
    c = write_artifact("c", mtime: Time.at(1000), name: "c.yml")
    described_class.memoize(c) { :c }

    expect(described_class.memoize(a) { raise "cache hit expected" }).to eq :a
    expect(described_class.memoize(c) { :c }).to eq :c
  end
end

RSpec.describe Fontist::FromFileCache, "resource bounds" do
  it "bounds retention at a fixed entry count by default" do
    expect(Fontist::FromFileCache::DEFAULT_MAX_ENTRIES).to be_a(Integer)
    expect(Fontist::FromFileCache::DEFAULT_MAX_ENTRIES).to be > 0
  end
end

RSpec.describe "resource-spike guards" do
  let(:lib_sources) do
    Dir[File.expand_path("../../lib/**/*.rb", __dir__)]
      .reject { |f| f.include?("/vendor/") }
      .map { |f| [f, File.read(f)] }
  end

  it "never forks processes" do
    # A fork inherits the host heap, and its RSS is charged to the
    # process group while it lives: 8 workers on a 1GB host transiently
    # count 9GB against cgroup caps (fontist#510)
    fork_pattern = /\bin_processes\b|\bProcess\.fork\b|^\s*fork\s*\(/

    offenders = lib_sources.filter_map do |file, source|
      source.each_line.with_index.filter_map do |line, i|
        "#{file}:#{i + 1}" if line.match?(fork_pattern)
      end
    end.flatten

    expect(offenders).to be_empty
  end

  it "caps every Parallel.map thread pool" do
    # Uncapped pools scale worker counts with host core counts, making
    # peak allocations unpredictable on large CI machines
    offenders = lib_sources.filter_map do |file, source|
      source.each_line.with_index.filter_map do |line, i|
        next unless line.include?("Parallel.map")
        next if line.include?("in_threads")

        "#{file}:#{i + 1}"
      end
    end.flatten

    expect(offenders).to be_empty
  end
end
