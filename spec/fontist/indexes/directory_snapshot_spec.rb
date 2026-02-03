require "spec_helper"

RSpec.describe Fontist::Indexes::DirectorySnapshot do
  let(:test_dir) { Fontist.root_path.join("spec/fixtures/snapshot_test") }

  before do
    FileUtils.mkdir_p(test_dir)
    Fontist::Cache::Manager.clear(namespace: :indexes)
  end

  after do
    FileUtils.rm_rf(test_dir) if Dir.exist?(test_dir)
    Fontist::Cache::Manager.clear(namespace: :indexes)
  end

  describe ".create" do
    it "creates snapshot with scanned files" do
      create_test_fonts(test_dir, ["A.ttf", "B.ttf"])

      snapshot = described_class.create(test_dir)

      expect(snapshot.directory_path).to eq test_dir.to_s
      expect(snapshot.file_count).to eq 2
      expect(snapshot.files.map do |f|
        f[:filename]
      end).to contain_exactly("A.ttf", "B.ttf")
    end

    it "records scan timestamp" do
      snapshot = described_class.create(test_dir)
      now = Time.now.to_i

      expect(snapshot.scanned_at).to be_between(now - 1, now + 1)
    end

    it "handles empty directories" do
      snapshot = described_class.create(test_dir)

      expect(snapshot.file_count).to eq 0
      expect(snapshot.files).to eq []
    end

    it "handles non-existent directories" do
      snapshot = described_class.create("/nonexistent/path")

      expect(snapshot.file_count).to eq 0
    end
  end

  describe ".from_hash" do
    it "restores snapshot from hash" do
      hash = {
        directory_path: test_dir.to_s,
        files: [
          { filename: "test.ttf", path: "#{test_dir}/test.ttf", file_size: 100,
            file_mtime: 123456, signature: "abc123" },
        ],
        scanned_at: 1234567890,
      }

      snapshot = described_class.from_hash(hash)

      expect(snapshot.directory_path).to eq test_dir.to_s
      expect(snapshot.file_count).to eq 1
      expect(snapshot.files.first[:filename]).to eq "test.ttf"
    end
  end

  describe "#file_info" do
    it "returns file info for existing file" do
      create_test_fonts(test_dir, ["existing.ttf"])
      snapshot = described_class.create(test_dir)

      info = snapshot.file_info("existing.ttf")

      expect(info).not_to be_nil
      expect(info[:filename]).to eq "existing.ttf"
    end

    it "returns nil for non-existent file" do
      create_test_fonts(test_dir, ["existing.ttf"])
      snapshot = described_class.create(test_dir)

      info = snapshot.file_info("nonexistent.ttf")

      expect(info).to be_nil
    end
  end

  describe "#has_file?" do
    it "returns true for existing file" do
      create_test_fonts(test_dir, ["test.ttf"])
      snapshot = described_class.create(test_dir)

      expect(snapshot.has_file?("test.ttf")).to be true
    end

    it "returns false for non-existent file" do
      create_test_fonts(test_dir, ["test.ttf"])
      snapshot = described_class.create(test_dir)

      expect(snapshot.has_file?("nonexistent.ttf")).to be false
    end
  end

  describe "#older_than?" do
    it "returns true for old snapshots" do
      old_time = Time.now.to_i - 1000
      snapshot = described_class.from_hash(
        directory_path: test_dir.to_s,
        files: [],
        scanned_at: old_time,
      )

      expect(snapshot.older_than?(100)).to be true
    end

    it "returns false for recent snapshots" do
      snapshot = described_class.create(test_dir)

      expect(snapshot.older_than?(100)).to be false
    end
  end

  describe "#file_count" do
    it "returns number of files" do
      create_test_fonts(test_dir, ["A.ttf", "B.ttf", "C.ttf"])
      snapshot = described_class.create(test_dir)

      expect(snapshot.file_count).to eq 3
    end
  end

  describe "#to_h" do
    it "serializes snapshot to hash" do
      create_test_fonts(test_dir, ["test.ttf"])
      snapshot = described_class.create(test_dir)

      hash = snapshot.to_h

      expect(hash).to include(:directory_path, :files, :scanned_at)
      expect(hash[:directory_path]).to eq test_dir.to_s
      expect(hash[:files]).to be_an(Array)
    end

    it "can be restored from serialized hash" do
      create_test_fonts(test_dir, ["test.ttf"])
      original = described_class.create(test_dir)

      restored = described_class.from_hash(original.to_h)

      expect(restored.directory_path).to eq original.directory_path
      expect(restored.file_count).to eq original.file_count
      expect(restored.scanned_at).to eq original.scanned_at
    end
  end

  describe "immutability" do
    it "freezes files array" do
      snapshot = described_class.create(test_dir)

      expect(snapshot.files).to be_frozen
    end

    it "freezes files_by_filename hash" do
      create_test_fonts(test_dir, ["test.ttf"])
      snapshot = described_class.create(test_dir)

      # Access the private instance variable to check
      files_by_filename = snapshot.instance_variable_get(:@files_by_filename)
      expect(files_by_filename).to be_frozen
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

    content = case File.extname(filename)
              when ".ttf", ".TTF"
                "\u0000\u0001\u0000\u0000#{"\x00" * 100}"
              when ".otf", ".OTF"
                "OTTO#{"\x00" * 100}"
              else
                "\x00" * 104
              end

    File.write(path, content)
    path
  end
end
