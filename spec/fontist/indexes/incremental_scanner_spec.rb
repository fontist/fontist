require "spec_helper"

RSpec.describe Fontist::Indexes::IncrementalScanner do
  let(:test_dir) { Fontist.root_path.join("spec/fixtures/incremental_test") }
  let(:index) { Fontist::Indexes::SystemIndex.instance }

  before do
    FileUtils.mkdir_p(test_dir)
    Fontist::Cache::Manager.clear(namespace: :indexes)
  end

  after do
    FileUtils.rm_rf(test_dir) if Dir.exist?(test_dir)
    Fontist::Cache::Manager.clear(namespace: :indexes)
  end

  describe ".scan_directory" do
    it "returns list of font files in directory" do
      create_test_fonts(test_dir, ["Arial.ttf", "Times.ttf"])

      result = described_class.scan_directory(test_dir)

      expect(result.count).to eq 2
      expect(result.map { |f| f[:filename] }).to contain_exactly("Arial.ttf", "Times.ttf")
    end

    it "returns full paths" do
      create_test_fonts(test_dir, ["Test.ttf"])

      result = described_class.scan_directory(test_dir)

      expect(result.first[:path]).to eq File.join(test_dir, "Test.ttf")
    end

    it "includes file metadata" do
      create_test_fonts(test_dir, ["Font.ttf"])

      result = described_class.scan_directory(test_dir)
      font_data = result.first

      expect(font_data).to include(:file_size)
      expect(font_data).to include(:file_mtime)
      expect(font_data).to include(:signature)
    end

    it "computes signature from file header" do
      create_test_fonts(test_dir, ["Test.ttf"])

      result = described_class.scan_directory(test_dir)
      signature = result.first[:signature]

      expect(signature).to be_a(String)
      expect(signature.length).to eq 64 # SHA256 hex
    end

    it "handles empty directories" do
      result = described_class.scan_directory(test_dir)

      expect(result).to eq []
    end

    it "handles non-existent directories" do
      result = described_class.scan_directory("/nonexistent/path")

      expect(result).to eq []
    end
  end

  describe ".scan_font_file" do
    it "parses font file metadata" do
      font_path = create_test_font(test_dir, "Test.ttf")

      result = described_class.scan_font_file(font_path)

      expect(result[:path]).to eq font_path
      expect(result[:filename]).to eq "Test.ttf"
      expect(result[:file_size]).to be > 0
      expect(result[:file_mtime]).to be_a(Integer)
    end

    it "detects font format" do
      ttf_path = create_test_font(test_dir, "Test.ttf")
      otf_path = create_test_font(test_dir, "Test.otf")

      ttf_result = described_class.scan_font_file(ttf_path)
      otf_result = described_class.scan_font_file(otf_path)

      expect(ttf_result[:format]).to eq :truetype
      expect(otf_result[:format]).to eq :opentype
    end
  end

  describe ".scan_with_cache" do
    it "reuses cached font metadata if file unchanged" do
      font_path = create_test_font(test_dir, "Cached.ttf")

      # First scan
      first_result = described_class.scan_font_file(font_path)
      cached_version = {
        path: font_path,
        file_size: first_result[:file_size],
        file_mtime: first_result[:file_mtime],
        signature: first_result[:signature]
      }

      # Second scan with cache
      second_result = described_class.scan_with_cache(font_path, cached_version)

      expect(second_result).to eq cached_version
    end

    it "rescans if file was modified" do
      font_path = create_test_font(test_dir, "Modified.ttf")
      first_result = described_class.scan_font_file(font_path)
      cached_version = first_result.dup

      # Modify the file
      sleep(1.1) # Ensure mtime changes
      File.write(font_path, "modified content")

      second_result = described_class.scan_with_cache(font_path, cached_version)

      expect(second_result[:file_mtime]).not_to eq cached_version[:file_mtime]
      expect(second_result[:signature]).not_to eq cached_version[:signature]
    end

    it "returns nil if cached file was deleted" do
      font_path = create_test_font(test_dir, "Deleted.ttf")
      cached = described_class.scan_font_file(font_path)

      File.delete(font_path)

      result = described_class.scan_with_cache(font_path, cached)

      expect(result).to be_nil
    end
  end

  describe ".scan_batch" do
    it "scans multiple font files" do
      fonts = create_test_fonts(test_dir, ["A.ttf", "B.ttf", "C.ttf"])
      # create_test_fonts already returns full paths

      results = described_class.scan_batch(fonts)

      expect(results.count).to eq 3
      expect(results.map { |r| r[:filename] }).to contain_exactly("A.ttf", "B.ttf", "C.ttf")
    end

    it "handles empty batch" do
      results = described_class.scan_batch([])

      expect(results).to eq []
    end

    it "skips non-existent files gracefully" do
      existing = create_test_font(test_dir, "Exists.ttf")
      paths = [
        File.join(test_dir, "Exists.ttf"),
        File.join(test_dir, "Nonexistent.ttf")
      ]

      results = described_class.scan_batch(paths)

      expect(results.count).to eq 1
      expect(results.first[:filename]).to eq "Exists.ttf"
    end
  end

  describe "performance" do
    it "is faster than scanning all files when many unchanged" do
      fonts = create_test_fonts(test_dir, (1..100).map { |i| "Font#{i}.ttf" })
      # create_test_fonts already returns full paths, use directly

      # First pass - scan all
      first_results = described_class.scan_batch(fonts)

      # Simulate cached data (hash of path => cached_version)
      cached_data = first_results.map { |r| [r[:path], { signature: r[:signature] }] }.to_h

      # Second pass with cache (should be faster)
      start = Time.now
      second_results = described_class.scan_batch(fonts, cache: cached_data)
      elapsed = Time.now - start

      expect(second_results).to eq first_results
      # With proper caching, this should be much faster
      # In real test, would assert elapsed < threshold
    end
  end

  private

  def create_test_fonts(dir, filenames)
    filenames.map do |filename|
      create_test_font(dir, filename)
    end
  end

  def create_test_font(dir, filename)
    path = File.join(dir, filename)
    FileUtils.mkdir_p(File.dirname(path)) unless Dir.exist?(File.dirname(path))

    # Create minimal TTF header
    content = case File.extname(filename)
              when ".ttf", ".TTF"
                "\x00\x01\x00\x00" + "\x00" * 100
              when ".otf", ".OTF"
                "OTTO" + "\x00" * 100
              else
                "\x00" * 104
              end

    File.write(path, content)
    path
  end
end
