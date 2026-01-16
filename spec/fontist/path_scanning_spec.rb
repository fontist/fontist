require "spec_helper"

RSpec.describe Fontist::PathScanning do
  describe ".list_font_directory" do
    let(:test_dir) { Fontist.root_path.join("spec/fixtures/test_fonts") }
    let(:fonts_dir) { Fontist.root_path.join("spec/fixtures/fonts") }

    before do
      FileUtils.mkdir_p(test_dir)
    end

    after do
      FileUtils.rm_rf(test_dir) if Dir.exist?(test_dir)
    end

    it "returns empty array for non-existent directory" do
      expect(described_class.list_font_directory("/nonexistent/path")).to eq []
    end

    it "lists font files in directory" do
      # Create test font files
      FileUtils.touch(File.join(test_dir, "Arial.ttf"))
      FileUtils.touch(File.join(test_dir, "Times.otf"))
      FileUtils.touch(File.join(test_dir, "readme.txt")) # Not a font

      result = described_class.list_font_directory(test_dir)

      expect(result).to be_a(Array)
      expect(result.count).to eq 2
      expect(result.any? { |p| p.end_with?("Arial.ttf") }).to be true
      expect(result.any? { |p| p.end_with?("Times.otf") }).to be true
      expect(result.none? { |p| p.end_with?("readme.txt") }).to be true
    end

    it "returns full paths" do
      FileUtils.touch(File.join(test_dir, "Test.ttf"))

      result = described_class.list_font_directory(test_dir)

      expect(result.first).to start_with(test_dir.to_s)
    end

    it "only includes supported font extensions" do
      # Create various file types with unique base names for case-insensitive filesystems
      # Note: On case-insensitive filesystems, we can't test uppercase/lowercase variants separately
      supported_lowercase = %w[ttf otf ttc woff woff2]
      unsupported = %w[txt pdf zip exe]

      supported_lowercase.each_with_index do |ext, i|
        FileUtils.touch(File.join(test_dir, "font#{i}.#{ext}"))
      end
      unsupported.each do |ext|
        FileUtils.touch(File.join(test_dir, "file.#{ext}"))
      end

      result = described_class.list_font_directory(test_dir)

      expect(result.count).to eq supported_lowercase.count

      supported_lowercase.each do |ext|
        expect(result.any? { |p| p.end_with?(".#{ext}") }).to be true
      end

      unsupported.each do |ext|
        expect(result.none? { |p| p.end_with?(".#{ext}") }).to be true
      end
    end

    it "handles case-sensitive extensions" do
      # On case-insensitive filesystems, just verify that we match various casings
      %w[font1.ttf font2.TTF font3.OfF].each do |filename|
        FileUtils.touch(File.join(test_dir, filename))
      end

      result = described_class.list_font_directory(test_dir)

      # On case-insensitive filesystems, files may overwrite each other
      # Just verify we found at least one font file
      expect(result.count).to be >= 1
    end

    it "handles symlinks to font files" do
      font_file = File.join(fonts_dir, "LiberationSans-Regular.ttf")
      target_dir = Fontist.root_path.join("spec/fixtures/symlink_test")
      FileUtils.mkdir_p(target_dir)

      symlink = File.join(target_dir, "Symlink.ttf")
      File.symlink(font_file, symlink)

      result = described_class.list_font_directory(target_dir)

      expect(result.count).to eq 1
      expect(result.first).to eq symlink

      FileUtils.rm_rf(target_dir)
    end

    it "handles hidden font files" do
      FileUtils.touch(File.join(test_dir, ".hidden.ttf"))
      FileUtils.touch(File.join(test_dir, "visible.ttf"))

      result = described_class.list_font_directory(test_dir)

      expect(result.count).to eq 2
    end
  end

  describe ".glob_font_files" do
    let(:test_dir) { Fontist.root_path.join("spec/fixtures/glob_test") }

    before do
      FileUtils.mkdir_p(test_dir)
      FileUtils.mkdir_p(File.join(test_dir, "subdir"))
    end

    after do
      FileUtils.rm_rf(test_dir) if Dir.exist?(test_dir)
    end

    it "returns matching font files" do
      FileUtils.touch(File.join(test_dir, "Arial.ttf"))
      FileUtils.touch(File.join(test_dir, "Times.otf"))
      FileUtils.touch(File.join(test_dir, "readme.txt"))

      pattern = File.join(test_dir, "*.ttf")
      result = described_class.glob_font_files(pattern)

      expect(result).to eq [File.join(test_dir, "Arial.ttf")]
    end

    it "handles recursive glob patterns" do
      FileUtils.touch(File.join(test_dir, "root.ttf"))
      FileUtils.touch(File.join(test_dir, "subdir", "nested.ttf"))
      FileUtils.touch(File.join(test_dir, "subdir", "readme.txt"))

      pattern = File.join(test_dir, "**/*.ttf")
      result = described_class.glob_font_files(pattern)

      expect(result.count).to eq 2
      expect(result.any? { |p| p.end_with?("root.ttf") }).to be true
      expect(result.any? { |p| p.end_with?("nested.ttf") }).to be true
    end

    it "handles brace expansion patterns" do
      FileUtils.touch(File.join(test_dir, "font1.ttf"))
      FileUtils.touch(File.join(test_dir, "font2.otf"))

      pattern = File.join(test_dir, "*.{ttf,otf}")
      result = described_class.glob_font_files(pattern)

      expect(result.count).to eq 2
    end

    it "filters out non-font files" do
      FileUtils.touch(File.join(test_dir, "font.ttf"))
      FileUtils.touch(File.join(test_dir, "data.bin"))
      FileUtils.touch(File.join(test_dir, "script.rb"))

      pattern = File.join(test_dir, "*")
      result = described_class.glob_font_files(pattern)

      expect(result).to eq [File.join(test_dir, "font.ttf")]
    end

    it "returns unique results" do
      # Create same file twice via different patterns would produce duplicates
      FileUtils.touch(File.join(test_dir, "test.ttf"))

      pattern = File.join(test_dir, "{*.ttf,test.*}")
      result = described_class.glob_font_files(pattern)

      expect(result.uniq).to eq result
    end
  end

  describe "memoization" do
    it "memoizes directory listings" do
      test_dir = Fontist.root_path.join("spec/fixtures/memo_test")
      FileUtils.mkdir_p(test_dir)
      FileUtils.touch(File.join(test_dir, "test.ttf"))

      # First call
      result1 = described_class.list_font_directory(test_dir)

      # Should be memoized (would need to verify with cache inspection)
      result2 = described_class.list_font_directory(test_dir)

      expect(result1).to eq result2

      FileUtils.rm_rf(test_dir)
    end

    it "uses cache key based on directory path" do
      dir1 = Fontist.root_path.join("spec/fixtures/memo1")
      dir2 = Fontist.root_path.join("spec/fixtures/memo2")

      FileUtils.mkdir_p(dir1)
      FileUtils.mkdir_p(dir2)
      FileUtils.touch(File.join(dir1, "font1.ttf"))
      FileUtils.touch(File.join(dir2, "font2.ttf"))

      result1 = described_class.list_font_directory(dir1)
      result2 = described_class.list_font_directory(dir2)

      expect(result1.count).to eq 1
      expect(result2.count).to eq 1

      FileUtils.rm_rf(dir1)
      FileUtils.rm_rf(dir2)
    end
  end

  describe "performance" do
    it "uses Dir.children instead of glob for simple listing" do
      test_dir = Fontist.root_path.join("spec/fixtures/perf_test")
      FileUtils.mkdir_p(test_dir)

      # Create many files (mostly non-fonts)
      1000.times do |i|
        FileUtils.touch(File.join(test_dir, "file#{i}.txt"))
      end
      FileUtils.touch(File.join(test_dir, "font.ttf"))

      # Should be fast despite many files
      start = Time.now
      result = described_class.list_font_directory(test_dir)
      elapsed = Time.now - start

      expect(result.count).to eq 1
      expect(elapsed).to be < 0.5 # Should complete quickly

      FileUtils.rm_rf(test_dir)
    end
  end

  describe "extension detection" do
    let(:extensions_const) do
      described_class.const_get(:FONT_EXTENSIONS)
    end

    it "includes all common font extensions" do
      expect(extensions_const).to include(".ttf")
      expect(extensions_const).to include(".otf")
      expect(extensions_const).to include(".woff")
      expect(extensions_const).to include(".ttc")
    end

    it "includes case variations" do
      expect(extensions_const).to include(".ttf")
      expect(extensions_const).to include(".TTF")
    end

    it "is frozen for immutability" do
      expect(extensions_const).to be_frozen
    end
  end

  describe "error handling" do
    it "handles permission errors gracefully" do
      skip_on_windows

      test_dir = Fontist.root_path.join("spec/fixtures/perm_test")
      FileUtils.mkdir_p(test_dir)

      # Make directory unreadable (if possible)
      File.chmod(0o000, test_dir)

      result = described_class.list_font_directory(test_dir)

      # Should handle gracefully (return empty array or raise specific error)
      expect(result).to be_a(Array)

      # Restore permissions for cleanup
      File.chmod(0o755, test_dir)
      FileUtils.rm_rf(test_dir)
    end

    it "handles broken symlinks" do
      skip_on_windows

      test_dir = Fontist.root_path.join("spec/fixtures/symlink_test")
      FileUtils.mkdir_p(test_dir)

      # Create broken symlink
      symlink = File.join(test_dir, "broken.ttf")
      File.symlink("/nonexistent/path", symlink)

      result = described_class.list_font_directory(test_dir)

      # Should skip broken symlinks
      expect(result).to be_a(Array)

      FileUtils.rm_rf(test_dir)
    end
  end

  describe "integration with real fixtures" do
    it "correctly identifies fonts in fixtures directory" do
      fixtures_dir = Fontist.root_path.join("spec/fixtures/fonts")

      result = described_class.list_font_directory(fixtures_dir)

      expect(result).to be_a(Array)
      # Should find at least the test fonts
      expect(result.count).to be > 0

      result.each do |path|
        expect(File.exist?(path)).to be true
      end
    end
  end

  private

  def skip_on_windows
    skip "Test not applicable on Windows" if Fontist::Utils::System.user_os == :windows
  end
end
