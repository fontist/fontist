require "spec_helper"

RSpec.describe Fontist::Indexes::DirectoryChange do
  let(:old_info) { { filename: "test.ttf", path: "/path/test.ttf", file_size: 100, file_mtime: 1000, signature: "old_sig" } }
  let(:new_info) { { filename: "test.ttf", path: "/path/test.ttf", file_size: 200, file_mtime: 2000, signature: "new_sig" } }

  describe ".added" do
    it "creates added change with new info" do
      change = described_class.added("new.ttf", new_info)

      expect(change.change_type).to eq described_class::ADDED
      expect(change.filename).to eq "new.ttf"
      expect(new_info).to eq new_info
      expect(change.old_info).to be_nil
    end

    it "creates immutable change" do
      change = described_class.added("new.ttf", new_info)

      expect(change).to be_frozen
    end
  end

  describe ".modified" do
    it "creates modified change with old and new info" do
      change = described_class.modified("test.ttf", old_info, new_info)

      expect(change.change_type).to eq described_class::MODIFIED
      expect(change.filename).to eq "test.ttf"
      expect(change.old_info).to eq old_info
      expect(change.new_info).to eq new_info
    end
  end

  describe ".removed" do
    it "creates removed change with old info" do
      change = described_class.removed("old.ttf", old_info)

      expect(change.change_type).to eq described_class::REMOVED
      expect(change.filename).to eq "old.ttf"
      expect(change.old_info).to eq old_info
      expect(change.new_info).to be_nil
    end
  end

  describe ".unchanged" do
    it "creates unchanged change with info" do
      change = described_class.unchanged("same.ttf", old_info)

      expect(change.change_type).to eq described_class::UNCHANGED
      expect(change.filename).to eq "same.ttf"
      expect(change.old_info).to eq old_info
      expect(change.new_info).to eq old_info
    end
  end

  describe "#added?" do
    it "returns true for added changes" do
      change = described_class.added("new.ttf", new_info)

      expect(change.added?).to be true
    end

    it "returns false for other change types" do
      change = described_class.modified("test.ttf", old_info, new_info)

      expect(change.added?).to be false
    end
  end

  describe "#modified?" do
    it "returns true for modified changes" do
      change = described_class.modified("test.ttf", old_info, new_info)

      expect(change.modified?).to be true
    end

    it "returns false for other change types" do
      change = described_class.added("new.ttf", new_info)

      expect(change.modified?).to be false
    end
  end

  describe "#removed?" do
    it "returns true for removed changes" do
      change = described_class.removed("old.ttf", old_info)

      expect(change.removed?).to be true
    end

    it "returns false for other change types" do
      change = described_class.added("new.ttf", new_info)

      expect(change.removed?).to be false
    end
  end

  describe "#unchanged?" do
    it "returns true for unchanged changes" do
      change = described_class.unchanged("same.ttf", old_info)

      expect(change.unchanged?).to be true
    end

    it "returns false for other change types" do
      change = described_class.added("new.ttf", new_info)

      expect(change.unchanged?).to be false
    end
  end

  describe "#to_h" do
    it "serializes change to hash" do
      change = described_class.modified("test.ttf", old_info, new_info)

      hash = change.to_h

      expect(hash).to include(:change_type, :filename, :old_info, :new_info)
      expect(hash[:change_type]).to eq described_class::MODIFIED
      expect(hash[:filename]).to eq "test.ttf"
    end
  end

  describe ".diff" do
    let(:test_dir) { Fontist.root_path.join("spec/fixtures/diff_test") }

    before do
      FileUtils.mkdir_p(test_dir)
      Fontist::Cache::Manager.clear(namespace: :indexes)
    end

    after do
      FileUtils.rm_rf(test_dir) if Dir.exist?(test_dir)
      Fontist::Cache::Manager.clear(namespace: :indexes)
    end

    it "detects added files" do
      old_snapshot = create_snapshot(test_dir, [])
      new_snapshot = create_snapshot(test_dir, ["new.ttf"])

      changes = described_class.diff(old_snapshot, new_snapshot)

      added_changes = changes.select(&:added?)
      expect(added_changes.size).to eq 1
      expect(added_changes.first.filename).to eq "new.ttf"
    end

    it "detects removed files" do
      old_snapshot = create_snapshot(test_dir, ["removed.ttf"])
      new_snapshot = create_snapshot(test_dir, [])

      changes = described_class.diff(old_snapshot, new_snapshot)

      removed_changes = changes.select(&:removed?)
      expect(removed_changes.size).to eq 1
      expect(removed_changes.first.filename).to eq "removed.ttf"
    end

    it "detects modified files" do
      old_file_info = { filename: "modified.ttf", file_size: 100, file_mtime: 1000, signature: "old" }
      new_file_info = { filename: "modified.ttf", file_size: 200, file_mtime: 2000, signature: "new" }

      old_snapshot = create_snapshot(test_dir, [old_file_info])
      new_snapshot = create_snapshot(test_dir, [new_file_info])

      changes = described_class.diff(old_snapshot, new_snapshot)

      modified_changes = changes.select(&:modified?)
      expect(modified_changes.size).to eq 1
      expect(modified_changes.first.filename).to eq "modified.ttf"
    end

    it "detects all types of changes" do
      # Old: A, B, C
      # New: B (modified), D, E
      # Result: A removed, C removed, B modified, D added, E added

      old_files = [
        { filename: "A.ttf", file_size: 100, file_mtime: 1000, signature: "a" },
        { filename: "B.ttf", file_size: 100, file_mtime: 1000, signature: "b" },
        { filename: "C.ttf", file_size: 100, file_mtime: 1000, signature: "c" }
      ]
      new_files = [
        { filename: "B.ttf", file_size: 200, file_mtime: 2000, signature: "b-modified" },
        { filename: "D.ttf", file_size: 100, file_mtime: 1000, signature: "d" },
        { filename: "E.ttf", file_size: 100, file_mtime: 1000, signature: "e" }
      ]

      old_snapshot = create_snapshot(test_dir, old_files)
      new_snapshot = create_snapshot(test_dir, new_files)

      changes = described_class.diff(old_snapshot, new_snapshot)

      expect(changes.size).to eq 5
      expect(changes.count(&:added?)).to eq 2 # D, E
      expect(changes.count(&:removed?)).to eq 2 # A, C
      expect(changes.count(&:modified?)).to eq 1 # B
    end

    it "returns empty array when no changes" do
      file_info = { filename: "same.ttf", file_size: 100, file_mtime: 1000, signature: "same" }

      old_snapshot = create_snapshot(test_dir, [file_info])
      new_snapshot = create_snapshot(test_dir, [file_info])

      changes = described_class.diff(old_snapshot, new_snapshot)

      expect(changes).to eq []
    end

    it "detects modification when size changes" do
      old_file = { filename: "size_changed.ttf", file_size: 100, file_mtime: 1000, signature: "sig1" }
      new_file = { filename: "size_changed.ttf", file_size: 200, file_mtime: 1000, signature: "sig2" }

      old_snapshot = create_snapshot(test_dir, [old_file])
      new_snapshot = create_snapshot(test_dir, [new_file])

      changes = described_class.diff(old_snapshot, new_snapshot)

      expect(changes.size).to eq 1
      expect(changes.first).to be_modified
    end

    it "detects modification when mtime changes" do
      old_file = { filename: "time_changed.ttf", file_size: 100, file_mtime: 1000, signature: "sig1" }
      new_file = { filename: "time_changed.ttf", file_size: 100, file_mtime: 2000, signature: "sig2" }

      old_snapshot = create_snapshot(test_dir, [old_file])
      new_snapshot = create_snapshot(test_dir, [new_file])

      changes = described_class.diff(old_snapshot, new_snapshot)

      expect(changes.size).to eq 1
      expect(changes.first).to be_modified
    end

    it "detects modification when signature changes" do
      old_file = { filename: "sig_changed.ttf", file_size: 100, file_mtime: 1000, signature: "sig1" }
      new_file = { filename: "sig_changed.ttf", file_size: 100, file_mtime: 1000, signature: "sig2" }

      old_snapshot = create_snapshot(test_dir, [old_file])
      new_snapshot = create_snapshot(test_dir, [new_file])

      changes = described_class.diff(old_snapshot, new_snapshot)

      expect(changes.size).to eq 1
      expect(changes.first).to be_modified
    end
  end

  private

  def create_snapshot(dir, file_infos)
    # Convert simple file info hashes to full file info hashes
    files = file_infos.map do |info|
      build_full_file_info(dir, info)
    end

    Fontist::Indexes::DirectorySnapshot.from_hash(
      directory_path: dir,
      files: files,
      scanned_at: Time.now.to_i
    )
  end

  # Build a complete file info hash from minimal info
  def build_full_file_info(dir, info)
    if info.is_a?(Hash)
      {
        filename: info[:filename],
        path: File.join(dir, info[:filename]),
        file_size: info.fetch(:file_size, 100),
        file_mtime: info.fetch(:file_mtime, 1000),
        signature: info.fetch(:signature, "default_sig")
      }
    else
      # info is a string filename - build minimal file info
      filename = info.to_s
      {
        filename: filename,
        path: File.join(dir, filename),
        file_size: 100,
        file_mtime: 1000,
        signature: "sig_#{filename}"
      }
    end
  end
end
