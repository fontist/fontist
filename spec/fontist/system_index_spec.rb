require "spec_helper"

RSpec.describe Fontist::SystemIndex do
  context "two simultaneous runs" do
    it "generates the same system index", slow: true do
      stub_system_fonts(Fontist.orig_system_file_path)

      reference_index_path = stub_system_index_path do
        Fontist::SystemIndex.system_index.rebuild
      end

      test_index_path = File.join(create_tmp_dir, "system_index.yml")

      2.times do
        Process.spawn(RbConfig.ruby, "-e" + <<~COMMAND)
          require "bundler/setup"
          require "fontist"

          def Fontist.system_index_path
            "#{test_index_path}"
          end

          def Fontist.default_fontist_path
            "#{Fontist.default_fontist_path}"
          end

          Fontist::SystemIndex.system_index.rebuild
        COMMAND
      end

      Process.waitall

      expect(File.read(test_index_path)).to eq(File.read(reference_index_path))
    end
  end

  context "corrupted index" do
    let(:command) { described_class.system_index.find("", "") }

    it "throws FontIndexCorrupted error" do
      stub_system_index_path do
        File.write(Fontist.system_index_path,
                   YAML.dump([{ path: "/some/path" }]))
        expect { command }.to raise_error(Fontist::Errors::FontIndexCorrupted)
      end
    end
  end

  context "corrupt font file" do
    let(:tmp_dir) { create_tmp_dir }
    let(:corrupt_font_file) do
      path = File.join(tmp_dir, "corrupt_font.ttf")
      File.write(path, "This is not a font file")
      path
    end
    let(:font_paths) { [corrupt_font_file] }
    let(:index_path) { File.join(tmp_dir, "system_index.yml") }
    let(:instance) do
      described_class.new(index_path,
                          -> { font_paths },
                          Fontist::SystemIndex::DefaultFamily.new)
    end

    it "does not raise errors" do
      expect { instance.find("some font", nil) }.not_to raise_error
    end

    it "warns about the corrupt font file" do
      expect(Fontist.ui).to receive(:error)
        .with(/#{corrupt_font_file} not recognized as a font file/)

      instance.find("some font", nil)
    end
  end
  context "Arch Linux issue" do
    it "generates system index when there is corrupt font file" do
      d = stub_system_fonts_path_to_new_path
      path = File.join(d, "corrupt_font.ttc")
      File.write(path, "This is not a font file")

      #      stub_system_font_finder_to_fixture("Fonts")

      Fontist::SystemIndex.system_index.rebuild

      #      stub_system_fonts(Fontist.orig_system_file_path)

      #     path = File.join(stub_system_index_path, "corrupt_font.ttf")
      #     File.write(path, "This is not a font file")

      #      reference_index_path = stub_system_index_path do
      #        Fontist::SystemIndex.system_index.rebuild
      #      end

      #      puts "#{reference_index_path}"
    end
  end
end
