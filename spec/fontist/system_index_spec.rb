require "spec_helper"

RSpec.describe Fontist::SystemIndex do
  context "two simultaneous runs" do
    it "generates the same system index", slow: true do
      reference_index_path = stub_system_index_path do
        Fontist::SystemIndex.rebuild
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
            Fontist.root_path.join("spec", "fixtures")
          end

          Fontist::SystemIndex.rebuild
        COMMAND
      end

      Process.waitall

      expect(File.read(test_index_path)).to eq(File.read(reference_index_path))
    end
  end

  context "corrupted index" do
    let(:command) { described_class.find("", "") }

    it "throws FontIndexCorrupted error" do
      stub_system_index_path do
        File.write(Fontist.system_index_path, YAML.dump([{ path: "/some/path" }]))
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
    let(:instance) { described_class.new(font_paths) }

    it "does not raise errors" do
      expect { instance.find("some font", nil) }.not_to raise_error
    end

    it "warns about the corrupt font file" do
      expect { instance.find("some font", nil) }
        .to output(/#{corrupt_font_file} not recognized as a font file/)
        .to_stderr
    end
  end
end
