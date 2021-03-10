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
end
