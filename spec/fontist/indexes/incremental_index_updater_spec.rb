require "spec_helper"

RSpec.describe Fontist::Indexes::IncrementalIndexUpdater do
  let(:test_dir) { Fontist.root_path.join("spec/fixtures/updater_test") }

  before do
    FileUtils.mkdir_p(test_dir)
    Fontist::Cache::Manager.clear(namespace: :indexes)
  end

  after do
    FileUtils.rm_rf(test_dir) if Dir.exist?(test_dir)
    Fontist::Cache::Manager.clear(namespace: :indexes)
  end

  describe "#initialize" do
    it "stores directory path" do
      updater = described_class.new(test_dir.to_s)

      expect(updater.directory_path).to eq test_dir.to_s
    end

    it "initializes with empty changes" do
      updater = described_class.new(test_dir.to_s)

      expect(updater.changes).to eq []
    end
  end

  describe "#update" do
    context "first scan (no previous snapshot)" do
      it "detects all files as added" do
        create_test_fonts(test_dir, ["A.ttf", "B.ttf"])
        updater = described_class.new(test_dir.to_s)

        changes = updater.update

        expect(changes.size).to eq 2
        expect(changes.all?(&:added?)).to be true
        expect(updater.changes?).to be true
      end

      it "stores snapshot for subsequent scans" do
        create_test_fonts(test_dir, ["test.ttf"])
        updater = described_class.new(test_dir.to_s)

        updater.update

        # Verify snapshot was cached
        cached = Fontist::Cache::Manager.get(
          "snapshot:#{test_dir}",
          namespace: :indexes
        )
        expect(cached).not_to be_nil
        expect(cached[:files].size).to eq 1
      end

      it "handles empty directories" do
        updater = described_class.new(test_dir.to_s)

        changes = updater.update

        expect(changes).to eq []
        expect(updater.changes?).to be false
      end
    end

    context "subsequent scan with no changes" do
      it "detects no changes" do
        create_test_fonts(test_dir, ["A.ttf", "B.ttf"])

        # First scan
        updater1 = described_class.new(test_dir.to_s)
        updater1.update

        # Second scan
        updater2 = described_class.new(test_dir.to_s)
        changes = updater2.update

        expect(changes).to eq []
        expect(updater2.changes?).to be false
      end
    end

    context "subsequent scan with added files" do
      it "detects newly added files" do
        # First scan with A.ttf
        create_test_fonts(test_dir, ["A.ttf"])
        updater1 = described_class.new(test_dir.to_s)
        updater1.update

        # Add B.ttf and C.ttf
        create_test_fonts(test_dir, ["B.ttf", "C.ttf"])
        updater2 = described_class.new(test_dir.to_s)
        changes = updater2.update

        expect(changes.size).to eq 2
        expect(changes.count(&:added?)).to eq 2
        expect(updater2.added_files.size).to eq 2
      end
    end

    context "subsequent scan with removed files" do
      it "detects removed files" do
        # First scan with A, B, C
        create_test_fonts(test_dir, ["A.ttf", "B.ttf", "C.ttf"])
        updater1 = described_class.new(test_dir.to_s)
        updater1.update

        # Remove B.ttf and C.ttf
        File.delete(File.join(test_dir, "B.ttf"))
        File.delete(File.join(test_dir, "C.ttf"))

        updater2 = described_class.new(test_dir.to_s)
        changes = updater2.update

        expect(changes.size).to eq 2
        expect(changes.count(&:removed?)).to eq 2
        expect(updater2.removed_files.size).to eq 2
      end
    end

    context "subsequent scan with modified files" do
      it "detects modified files" do
        # First scan
        create_test_fonts(test_dir, ["test.ttf"])
        updater1 = described_class.new(test_dir.to_s)
        updater1.update

        # Modify file
        sleep(1.1) # Ensure mtime changes
        test_path = File.join(test_dir, "test.ttf")
        File.write(test_path, "\x00\x01\x00\x00" + "X" * 100)

        updater2 = described_class.new(test_dir.to_s)
        changes = updater2.update

        expect(changes.size).to eq 1
        expect(changes.first).to be_modified
        expect(updater2.modified_files.size).to eq 1
      end
    end

    context "subsequent scan with mixed changes" do
      it "detects all types of changes" do
        # First scan: A, B, C, D
        create_test_fonts(test_dir, ["A.ttf", "B.ttf", "C.ttf", "D.ttf"])
        updater1 = described_class.new(test_dir.to_s)
        updater1.update

        # Modify B, remove C, add E
        sleep(1.1)
        File.write(File.join(test_dir, "B.ttf"), "modified" + "\x00" * 94)
        File.delete(File.join(test_dir, "C.ttf"))
        create_test_fonts(test_dir, ["E.ttf"])

        updater2 = described_class.new(test_dir.to_s)
        changes = updater2.update

        # B modified, C removed, E added (A and D unchanged)
        expect(changes.size).to eq 3
        expect(updater2.added_files.size).to eq 1
        expect(updater2.modified_files.size).to eq 1
        expect(updater2.removed_files.size).to eq 1
      end
    end
  end

  describe "#added_files" do
    it "returns only added changes" do
      create_test_fonts(test_dir, ["new.ttf"])
      updater = described_class.new(test_dir.to_s)
      updater.update

      added = updater.added_files

      expect(added.size).to eq 1
      expect(added.first).to be_added
    end
  end

  describe "#modified_files" do
    it "returns only modified changes" do
      create_test_fonts(test_dir, ["test.ttf"])
      updater1 = described_class.new(test_dir.to_s)
      updater1.update

      sleep(1.1)
      File.write(File.join(test_dir, "test.ttf"), "modified" + "\x00" * 94)

      updater2 = described_class.new(test_dir.to_s)
      updater2.update

      modified = updater2.modified_files

      expect(modified.size).to eq 1
      expect(modified.first).to be_modified
    end
  end

  describe "#removed_files" do
    it "returns only removed changes" do
      create_test_fonts(test_dir, ["old.ttf"])
      updater1 = described_class.new(test_dir.to_s)
      updater1.update

      File.delete(File.join(test_dir, "old.ttf"))

      updater2 = described_class.new(test_dir.to_s)
      updater2.update

      removed = updater2.removed_files

      expect(removed.size).to eq 1
      expect(removed.first).to be_removed
    end
  end

  describe "#stats" do
    it "returns statistics about changes" do
      create_test_fonts(test_dir, ["A.ttf", "B.ttf", "C.ttf"])
      updater1 = described_class.new(test_dir.to_s)
      updater1.update

      sleep(1.1)
      File.write(File.join(test_dir, "B.ttf"), "modified" + "\x00" * 94)
      File.delete(File.join(test_dir, "C.ttf"))
      create_test_fonts(test_dir, ["D.ttf"])

      updater2 = described_class.new(test_dir.to_s)
      updater2.update

      stats = updater2.stats

      expect(stats[:total_changes]).to eq 3
      expect(stats[:added]).to eq 1
      expect(stats[:modified]).to eq 1
      expect(stats[:removed]).to eq 1
    end

    it "returns zeros when no changes" do
      create_test_fonts(test_dir, ["test.ttf"])
      updater1 = described_class.new(test_dir.to_s)
      updater1.update

      updater2 = described_class.new(test_dir.to_s)
      updater2.update

      stats = updater2.stats

      expect(stats[:total_changes]).to eq 0
      expect(stats[:added]).to eq 0
      expect(stats[:modified]).to eq 0
      expect(stats[:removed]).to eq 0
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
