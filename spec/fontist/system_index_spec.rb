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
    let(:index_path) { File.join(tmp_dir, "system_index.yml") }
    let(:instance) do
      Fontist::SystemIndexFontCollection.new.tap do |x|
        x.set_path(index_path)
        x.set_path_loader(-> { font_paths })
      end
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

  context "preferred family index" do
    let(:tmp_dir) { Fontist.temp_fontist_path }
    let(:font_file) do
      path = File.join(tmp_dir, "AndaleMo.TTF")
      FileUtils.cp(examples_font_path("AndaleMo.TTF"), path)
      path
    end
    let(:font_paths) { [font_file] }
    let(:index_path) { tmp_dir / "system_index.yml" }
    let(:formula_path) do
      path = Fontist.formulas_path / "andale.yml"
      FileUtils.cp(examples_formula_path("andale.yml"), path)
      path
    end
    let(:instance) do
      Fontist::SystemIndexFontCollection.new.tap do |x|
        x.set_path(index_path)
        x.set_path_loader(-> { font_paths })
      end
    end

    after do
      index_path.delete
    end

    it "does not raise errors for preferred family" do
      font_index = instance.rebuild
      font = font_index.find('Andale Mono', nil).first
      expect(font.preferred_family_name).to eq nil
    end

    it "does not raise errors for default family" do
      font_index = instance.rebuild
      font = font_index.find('Andale Mono', nil).first
      expect(font.family_name).to eq "Andale Mono"
    end
  end
end
