require "spec_helper"

RSpec.describe Fontist::Utils::FileOps do
  describe ".safe_rm_rf" do
    let(:test_dir) { Dir.mktmpdir }

    after do
      # Unstub FileUtils to allow real cleanup
      RSpec::Mocks.space.proxy_for(FileUtils).reset
      FileUtils.rm_rf(test_dir) if Dir.exist?(test_dir)
    end

    context "on all platforms" do
      it "removes a file successfully" do
        file_path = File.join(test_dir, "test.txt")
        File.write(file_path, "test content")

        expect(File.exist?(file_path)).to be true
        described_class.safe_rm_rf(file_path)
        expect(File.exist?(file_path)).to be false
      end

      it "removes a directory successfully" do
        dir_path = File.join(test_dir, "subdir")
        FileUtils.mkdir_p(dir_path)
        File.write(File.join(dir_path, "file.txt"), "content")

        expect(Dir.exist?(dir_path)).to be true
        described_class.safe_rm_rf(dir_path)
        expect(Dir.exist?(dir_path)).to be false
      end

      it "handles non-existent paths gracefully" do
        non_existent = File.join(test_dir, "does_not_exist")
        expect { described_class.safe_rm_rf(non_existent) }.not_to raise_error
      end
    end

    context "on Windows", if: Fontist::Utils::System.windows? do
      it "retries on EACCES error" do
        file_path = File.join(test_dir, "locked.txt")
        File.write(file_path, "test")

        # Simulate file locking by stubbing FileUtils
        call_count = 0
        allow(FileUtils).to receive(:rm_rf) do |path|
          call_count += 1
          raise Errno::EACCES if call_count == 1
          # Second call succeeds
        end

        expect { described_class.safe_rm_rf(file_path) }.not_to raise_error
        expect(call_count).to eq(2)
      end

      it "retries on ENOTEMPTY error" do
        dir_path = File.join(test_dir, "locked_dir")
        FileUtils.mkdir_p(dir_path)

        call_count = 0
        allow(FileUtils).to receive(:rm_rf) do |path|
          call_count += 1
          raise Errno::ENOTEMPTY if call_count == 1
          # Second call succeeds
        end

        expect { described_class.safe_rm_rf(dir_path) }.not_to raise_error
        expect(call_count).to eq(2)
      end

      it "raises error after max retries" do
        file_path = File.join(test_dir, "always_locked.txt")
        File.write(file_path, "test")

        allow(FileUtils).to receive(:rm_rf).and_raise(Errno::EACCES)

        expect {
          described_class.safe_rm_rf(file_path, retries: 3)
        }.to raise_error(Errno::EACCES)
      end

      it "forces GC between retries" do
        file_path = File.join(test_dir, "test.txt")
        File.write(file_path, "test")

        call_count = 0
        allow(FileUtils).to receive(:rm_rf) do |path|
          call_count += 1
          raise Errno::EACCES if call_count == 1
        end

        expect(GC).to receive(:start).at_least(:once)
        described_class.safe_rm_rf(file_path)
      end
    end

    context "on Unix", unless: Fontist::Utils::System.windows? do
      it "does not retry on errors" do
        file_path = File.join(test_dir, "test.txt")
        File.write(file_path, "test")

        allow(FileUtils).to receive(:rm_rf).and_raise(Errno::EACCES)

        expect {
          described_class.safe_rm_rf(file_path)
        }.to raise_error(Errno::EACCES)
      end

      it "does not force GC" do
        file_path = File.join(test_dir, "test.txt")
        File.write(file_path, "test")

        expect(GC).not_to receive(:start)
        described_class.safe_rm_rf(file_path)
      end
    end
  end

  describe ".with_file_cleanup" do
    let(:test_dir) { Dir.mktmpdir }

    after do
      FileUtils.rm_rf(test_dir) if Dir.exist?(test_dir)
    end

    it "executes the block" do
      executed = false
      described_class.with_file_cleanup(test_dir) do
        executed = true
      end
      expect(executed).to be true
    end

    context "on Windows", if: Fontist::Utils::System.windows? do
      it "forces GC after block execution" do
        expect(GC).to receive(:start)
        described_class.with_file_cleanup(test_dir) { }
      end

      it "pauses briefly after block execution" do
        expect_any_instance_of(Object).to receive(:sleep).with(0.05)
        described_class.with_file_cleanup(test_dir) { }
      end
    end

    context "on Unix", unless: Fontist::Utils::System.windows? do
      it "does not force GC" do
        expect(GC).not_to receive(:start)
        described_class.with_file_cleanup(test_dir) { }
      end

      it "does not pause" do
        expect_any_instance_of(Object).not_to receive(:sleep)
        described_class.with_file_cleanup(test_dir) { }
      end
    end
  end

  describe ".safe_cp_r" do
    let(:test_dir) { Dir.mktmpdir }
    let(:src_dir) { File.join(test_dir, "src") }
    let(:dest_dir) { File.join(test_dir, "dest") }

    before do
      FileUtils.mkdir_p(src_dir)
      File.write(File.join(src_dir, "file.txt"), "content")
    end

    after do
      # Unstub FileUtils to allow real cleanup
      RSpec::Mocks.space.proxy_for(FileUtils).reset
      FileUtils.rm_rf(test_dir) if Dir.exist?(test_dir)
    end

    it "copies files successfully" do
      described_class.safe_cp_r(src_dir, dest_dir)
      expect(File.exist?(File.join(dest_dir, "file.txt"))).to be true
      expect(File.read(File.join(dest_dir, "file.txt"))).to eq("content")
    end

    context "on Windows", if: Fontist::Utils::System.windows? do
      it "retries on EACCES error" do
        call_count = 0
        allow(FileUtils).to receive(:cp_r).and_wrap_original do |original_method, *args, **kwargs|
          call_count += 1
          if call_count == 1
            raise Errno::EACCES
          else
            original_method.call(*args, **kwargs)
          end
        end

        expect { described_class.safe_cp_r(src_dir, dest_dir) }.not_to raise_error
        expect(call_count).to eq(2)
      end
    end
  end

  describe ".safe_mkdir_p" do
    let(:test_dir) { Dir.mktmpdir }
    let(:new_dir) { File.join(test_dir, "new", "nested", "dir") }

    after do
      # Unstub FileUtils to allow real cleanup
      RSpec::Mocks.space.proxy_for(FileUtils).reset
      FileUtils.rm_rf(test_dir) if Dir.exist?(test_dir)
    end

    it "creates directories successfully" do
      described_class.safe_mkdir_p(new_dir)
      expect(Dir.exist?(new_dir)).to be true
    end

    context "on Windows", if: Fontist::Utils::System.windows? do
      it "retries on EACCES error" do
        call_count = 0
        allow(FileUtils).to receive(:mkdir_p).and_wrap_original do |original_method, *args, **kwargs|
          call_count += 1
          if call_count == 1
            raise Errno::EACCES
          else
            original_method.call(*args, **kwargs)
          end
        end

        expect { described_class.safe_mkdir_p(new_dir) }.not_to raise_error
        expect(call_count).to eq(2)
      end
    end
  end
end