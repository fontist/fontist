require "spec_helper"
require "ostruct"

RSpec.describe Fontist::Cache::Store do
  let(:cache_dir) { Fontist.root_path.join("cache", "store_spec") }

  before do
    FileUtils.rm_rf(cache_dir) if Dir.exist?(cache_dir)
  end

  after do
    FileUtils.rm_rf(cache_dir) if Dir.exist?(cache_dir)
  end

  subject(:store) { described_class.new(cache_dir) }

  describe "#initialize" do
    it "creates cache directory if it doesn't exist" do
      store  # Reference subject to trigger initialization
      expect(Dir.exist?(cache_dir)).to be true
    end

    it "doesn't error if directory already exists" do
      expect { described_class.new(cache_dir) }.not_to raise_error
    end
  end

  describe "#get and #set" do
    it "stores and retrieves simple values" do
      store.set("simple", "value")
      expect(store.get("simple")).to eq "value"
    end

    it "returns nil for non-existent keys" do
      expect(store.get("nonexistent")).to be_nil
    end

    it "overwrites existing values" do
      store.set("key", "value1")
      store.set("key", "value2")
      expect(store.get("key")).to eq "value2"
    end

    it "stores different types independently" do
      store.set("string", "text")
      store.set("number", 42)
      store.set("array", [1, 2, 3])
      store.set("hash", { key: "value" })

      expect(store.get("string")).to eq "text"
      expect(store.get("number")).to eq 42
      expect(store.get("array")).to eq [1, 2, 3]
      expect(store.get("hash")).to eq({ key: "value" })
    end
  end

  describe "#set with TTL" do
    it "creates entry without expiration when no TTL given" do
      store.set("no_ttl", "value")
      entry = read_raw_entry("no_ttl")

      expect(entry.expires_at).to be_nil
    end

    it "creates entry with expiration when TTL given" do
      store.set("with_ttl", "value", ttl: 60)

      # Sleep a tiny bit to ensure time passed
      sleep(0.01)

      entry = read_raw_entry("with_ttl")

      expect(entry.expires_at).to be_a(Integer)
      expect(entry.expires_at).to be > Time.now.to_i
    end

    it "does not return expired entries" do
      store.set("short_lived", "value", ttl: 1)
      sleep(0.5)
      expect(store.get("short_lived")).to eq "value"
      sleep(1.5)  # More than TTL to account for timing
      expect(store.get("short_lived")).to be_nil
    end

    it "removes expired entry on access" do
      store.set("expiring", "value", ttl: 1)
      sleep(2.0)  # More than TTL to ensure expiration

      # Access should delete the file
      store.get("expiring")

      expect(cache_file_exists?("expiring")).to be false
    end
  end

  describe "#delete" do
    it "removes the cache file" do
      store.set("delete_me", "value")
      expect(cache_file_exists?("delete_me")).to be true

      store.delete("delete_me")

      expect(cache_file_exists?("delete_me")).to be false
    end

    it "returns nil after deletion" do
      store.set("delete_me", "value")
      store.delete("delete_me")
      expect(store.get("delete_me")).to be_nil
    end

    it "doesn't raise error for non-existent keys" do
      expect { store.delete("nonexistent") }.not_to raise_error
    end
  end

  describe "#clear" do
    it "removes all cache files" do
      10.times { |i| store.set("key#{i}", "value#{i}") }

      expect(Dir.glob(File.join(cache_dir, "*.marshal")).count).to eq 10

      store.clear

      expect(Dir.glob(File.join(cache_dir, "*.marshal")).count).to eq 0
    end

    it "doesn't remove the cache directory itself" do
      store.set("key", "value")
      store.clear
      expect(Dir.exist?(cache_dir)).to be true
    end
  end

  describe "serialization" do
    it "properly serializes Ruby objects" do
      value = OpenStruct.new(name: "Test", nested: { data: [1, 2, 3] })

      store.set("ostruct", value)
      retrieved = store.get("ostruct")

      expect(retrieved.name).to eq "Test"
      expect(retrieved.nested[:data]).to eq [1, 2, 3]
    end

    it "handles frozen objects" do
      value = ["immutable", "array"].freeze

      store.set("frozen", value)
      retrieved = store.get("frozen")

      expect(retrieved).to eq ["immutable", "array"]
      # Note: Marshal doesn't preserve frozen state by default
      # This is expected behavior
    end

    it "handles Time objects" do
      time = Time.now

      store.set("time", time)
      retrieved = store.get("time")

      expect(retrieved).to be_a(Time)
      expect(retrieved.to_i).to eq time.to_i
    end

    it "handles Date objects" do
      date = Date.today

      store.set("date", date)
      retrieved = store.get("date")

      expect(retrieved).to eq date
    end
  end

  describe "CacheEntry" do
    describe "#expired?" do
      it "returns false when no expiration set" do
        entry = Fontist::Cache::Store::CacheEntry.new("value", nil)
        expect(entry.expired?).to be false
      end

      it "returns false when expiration is in the future" do
        entry = Fontist::Cache::Store::CacheEntry.new("value", 3600)
        expect(entry.expired?).to be false
      end

      it "returns true when expiration has passed" do
        entry = Fontist::Cache::Store::CacheEntry.new("value", 1)
        sleep(2)
        expect(entry.expired?).to be true
      end

      it "calculates expiration correctly" do
        now = Time.now
        entry = Fontist::Cache::Store::CacheEntry.new("value", 100)

        expect(entry.expires_at).to be_within(1).of((now + 100).to_i)
      end
    end
  end

  describe "key sanitization" do
    it "converts slashes to underscores" do
      store.set("path/with/slashes", "value")
      expect(cache_file_exists?("path_with_slashes")).to be true
    end

    it "converts colons to underscores" do
      store.set("namespace:key", "value")
      expect(cache_file_exists?("namespace_key")).to be true
    end

    it "converts dots to underscores" do
      store.set("file.ttf", "value")
      expect(cache_file_exists?("file_ttf")).to be true
    end

    it "handles multiple special characters" do
      store.set("path/with:many.special/chars", "value")
      expect(store.get("path/with:many.special/chars")).to eq "value"
    end
  end

  describe "file system operations" do
    it "creates cache directory if missing during set" do
      new_dir = Fontist.root_path.join("cache", "new_store")
      new_store = described_class.new(new_dir)

      new_store.set("key", "value")

      expect(Dir.exist?(new_dir)).to be true
      expect(new_store.get("key")).to eq "value"

      FileUtils.rm_rf(new_dir)
    end

    it "handles concurrent writes" do
      threads = 5.times.map do |i|
        Thread.new { store.set("concurrent_#{i}", i) }
      end

      threads.each(&:join)

      5.times do |i|
        expect(store.get("concurrent_#{i}")).to eq i
      end
    end
  end

  describe "edge cases" do
    it "handles empty string keys" do
      store.set("", "value")
      expect(store.get("")).to eq "value"
    end

    it "handles very long keys" do
      long_key = "x" * 1000
      store.set(long_key, "value")
      expect(store.get(long_key)).to eq "value"
    end

    it "handles unicode in keys" do
      store.set("日本語", "value")
      expect(store.get("日本語")).to eq "value"
    end

    it "handles nil values" do
      store.set("nil_value", nil)
      expect(store.get("nil_value")).to be_nil
    end

    it "handles false values" do
      store.set("false_value", false)
      expect(store.get("false_value")).to eq false
    end

    it "handles zero values" do
      store.set("zero_value", 0)
      expect(store.get("zero_value")).to eq 0
    end
  end

  private

  def cache_file_exists?(key)
    File.exist?(File.join(cache_dir, "#{sanitize_key(key)}.marshal"))
  end

  def sanitize_key(key)
    key.to_s.gsub(/[^\w\-]/, '_')
  end

  def read_raw_entry(key)
    path = File.join(cache_dir, "#{sanitize_key(key)}.marshal")
    return nil unless File.exist?(path)

    Marshal.load(File.read(path))
  end
end
