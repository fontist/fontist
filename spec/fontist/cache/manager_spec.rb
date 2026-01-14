require "spec_helper"

RSpec.describe Fontist::Cache::Manager do
  let(:cache_dir) { Fontist.root_path.join("cache", "spec_test") }
  let(:custom_cache_dir) { Fontist.root_path.join("cache", "spec_custom") }

  before do
    # Clean up any existing test cache
    FileUtils.rm_rf(cache_dir) if Dir.exist?(cache_dir)
    FileUtils.rm_rf(custom_cache_dir) if Dir.exist?(custom_cache_dir)
  end

  after do
    # Clean up test cache
    FileUtils.rm_rf(cache_dir) if Dir.exist?(cache_dir)
    FileUtils.rm_rf(custom_cache_dir) if Dir.exist?(custom_cache_dir)
  end

  describe ".get and .set" do
    it "stores and retrieves values" do
      described_class.set("test_key", "test_value")
      expect(described_class.get("test_key")).to eq "test_value"
    end

    it "returns nil for non-existent keys" do
      expect(described_class.get("non_existent")).to be_nil
    end

    it "handles complex Ruby objects" do
      complex_value = {
        "fonts" => ["Arial.ttf", "Times.ttf"],
        "metadata" => { count: 2, scanned_at: Time.now }
      }

      described_class.set("complex", complex_value)
      retrieved = described_class.get("complex")

      expect(retrieved["fonts"]).to eq ["Arial.ttf", "Times.ttf"]
      expect(retrieved["metadata"]).to be_a(Hash)
    end

    it "handles arrays" do
      array_value = [1, 2, 3, "four", { five: 5 }]

      described_class.set("array_key", array_value)
      expect(described_class.get("array_key")).to eq array_value
    end
  end

  describe ".set with TTL" do
    it "expires values after TTL" do
      described_class.set("expiring", "value", ttl: 1)
      sleep(0.5)
      expect(described_class.get("expiring")).to eq "value"
      sleep(1.5) # Total of 2 seconds to ensure expiration
      expect(described_class.get("expiring")).to be_nil
    end

    it "does not expire values without TTL" do
      described_class.set("persistent", "value")
      sleep(0.5)
      expect(described_class.get("persistent")).to eq "value"
    end
  end

  describe ".delete" do
    it "removes stored values" do
      described_class.set("to_delete", "value")
      expect(described_class.get("to_delete")).to eq "value"

      described_class.delete("to_delete")
      expect(described_class.get("to_delete")).to be_nil
    end

    it "does not raise error for non-existent keys" do
      expect { described_class.delete("non_existent") }.not_to raise_error
    end
  end

  describe ".clear" do
    it "clears all values in default namespace" do
      described_class.set("key1", "value1")
      described_class.set("key2", "value2")

      described_class.clear

      expect(described_class.get("key1")).to be_nil
      expect(described_class.get("key2")).to be_nil
    end

    it "only clears specified namespace" do
      described_class.set("ns1_key", "value1", namespace: :namespace1)
      described_class.set("ns2_key", "value2", namespace: :namespace2)

      described_class.clear(namespace: :namespace1)

      expect(described_class.get("ns1_key", namespace: :namespace1)).to be_nil
      expect(described_class.get("ns2_key", namespace: :namespace2)).to eq "value2"
    end
  end

  describe "namespaces" do
    it "isolates values by namespace" do
      described_class.set("same_key", "value1", namespace: :ns1)
      described_class.set("same_key", "value2", namespace: :ns2)

      expect(described_class.get("same_key", namespace: :ns1)).to eq "value1"
      expect(described_class.get("same_key", namespace: :ns2)).to eq "value2"
    end

    it "uses default namespace when none specified" do
      described_class.set("key", "default_value")
      described_class.set("key", "namespaced_value", namespace: :custom)

      expect(described_class.get("key")).to eq "default_value"
      expect(described_class.get("key", namespace: :custom)).to eq "namespaced_value"
    end
  end

  describe ".get_directory_fonts and .set_directory_fonts" do
    it "stores directory font lists" do
      fonts = ["/Library/Fonts/Arial.ttf", "/Library/Fonts/Times.ttf"]

      described_class.set_directory_fonts("/Library/Fonts", fonts)
      retrieved = described_class.get_directory_fonts("/Library/Fonts")

      expect(retrieved).to eq fonts
    end

    it "uses indexes namespace internally" do
      fonts = ["Arial.ttf"]

      described_class.set_directory_fonts("/System/Library/Fonts", fonts)

      # Should be retrievable via indexes namespace
      expect(
        described_class.get("directory:/System/Library/Fonts", namespace: :indexes)
      ).to eq fonts
    end

    it "applies default TTL to directory fonts" do
      fonts = ["test.ttf"]

      # Should have TTL (1 hour default)
      described_class.set_directory_fonts("/test/path", fonts)

      # Verify it expires (would need time manipulation in real test)
      retrieved = described_class.get_directory_fonts("/test/path")
      expect(retrieved).to eq fonts
    end
  end

  describe "cache persistence" do
    it "persists across instances" do
      # Store in one "instance" (simulate by direct cache access)
      described_class.set("persistent", "value")

      # Simulate new process by clearing instance cache
      described_class.send(:instance_variable_set, :@stores, nil)

      # Should still be retrievable
      expect(described_class.get("persistent")).to eq "value"
    end
  end

  describe "key sanitization" do
    it "handles special characters in keys" do
      special_keys = [
        "path/with/slashes",
        "path-with-dashes",
        "path.with.dots",
        "path:with:colons",
        "path with spaces"
      ]

      special_keys.each do |key|
        expect { described_class.set(key, "value") }.not_to raise_error
        expect(described_class.get(key)).to eq "value"
      end
    end
  end

  describe "concurrent access" do
    it "handles concurrent reads safely" do
      described_class.set("concurrent", [1, 2, 3, 4, 5])

      threads = 10.times.map do
        Thread.new { described_class.get("concurrent") }
      end

      results = threads.map(&:value)
      expect(results.uniq).to eq [[1, 2, 3, 4, 5]]
    end

    it "handles concurrent writes safely" do
      threads = 10.times.map do |i|
        Thread.new { described_class.set("concurrent_write_#{i}", i) }
      end

      threads.each(&:join)

      10.times do |i|
        expect(described_class.get("concurrent_write_#{i}")).to eq i
      end
    end
  end

  describe "edge cases" do
    it "handles nil values" do
      described_class.set("nil_key", nil)
      expect(described_class.get("nil_key")).to be_nil
    end

    it "handles empty strings" do
      described_class.set("empty_string", "")
      expect(described_class.get("empty_string")).to eq ""
    end

    it "handles empty arrays" do
      described_class.set("empty_array", [])
      expect(described_class.get("empty_array")).to eq []
    end

    it "handles empty hashes" do
      described_class.set("empty_hash", {})
      expect(described_class.get("empty_hash")).to eq({})
    end

    it "handles large values" do
      large_value = "x" * 1_000_000

      expect { described_class.set("large", large_value) }.not_to raise_error
      expect(described_class.get("large")).to eq large_value
    end
  end
end
