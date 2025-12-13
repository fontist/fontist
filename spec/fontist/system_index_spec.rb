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
      font = font_index.find("Andale Mono", nil).first
      expect(font.preferred_family_name).to be_nil
    end

    it "does not raise errors for default family" do
      font_index = instance.rebuild
      font = font_index.find("Andale Mono", nil).first
      expect(font.family_name).to eq "Andale Mono"
    end
  end

  describe "#index_changed?" do
    let(:tmp_dir) { create_tmp_dir }
    let(:index_path) { File.join(tmp_dir, "system_index.yml") }
    let(:font_paths) { [] }
    let(:instance) do
      Fontist::SystemIndexFontCollection.new.tap do |x|
        x.set_path(index_path)
        x.set_path_loader(-> { paths_loader_call })
      end
    end

    context "when paths loader returns excluded fonts in addition to indexed fonts" do
      let(:font_file_path) { File.join(tmp_dir, "regular_font.ttf") }
      let(:excluded_font_path) { File.join(tmp_dir, "NISC18030.ttf") }
      let(:font_paths) { [font_file_path] }
      let(:paths_loader_call) { [font_file_path, excluded_font_path] }

      before do
        # Create the font file
        FileUtils.cp(examples_font_path("AndaleMo.TTF"), font_file_path)

        # Create the excluded font file
        FileUtils.cp(examples_font_path("AndaleMo.TTF"), excluded_font_path)

        # Build initial index with only the regular font
        instance.update
        instance.to_file(index_path)
      end

      it "returns false because excluded fonts should not trigger a rebuild" do
        expect(instance.index_changed?).to be false
      end
    end

    context "when paths loader returns additional non-excluded fonts" do
      let(:font_file_path) { File.join(tmp_dir, "regular_font.ttf") }
      let(:excluded_font_path) { File.join(tmp_dir, "NISC18030.ttf") }
      let(:additional_font_path) { File.join(tmp_dir, "additional_font.ttf") }
      let(:paths_loader_call) { [font_file_path, excluded_font_path, additional_font_path] }

      before do
        # Create the font files
        FileUtils.cp(examples_font_path("AndaleMo.TTF"), font_file_path)
        FileUtils.cp(examples_font_path("AndaleMo.TTF"), excluded_font_path)
        FileUtils.cp(examples_font_path("AndaleMo.TTF"), additional_font_path)

        # Build initial index with only the regular font (simulating old state)
        instance = Fontist::SystemIndexFontCollection.from_file(
          path: index_path,
          paths_loader: -> { [font_file_path, excluded_font_path] }
        )
        instance.update
        instance.to_file(index_path)
      end

      it "returns true because there are new non-excluded fonts" do
        expect(instance.index_changed?).to be true
      end

      it "calls update only once when rebuilding" do
        # Reset the instance to reload from file
        reloaded_instance = Fontist::SystemIndexFontCollection.from_file(
          path: index_path,
          paths_loader: -> { paths_loader_call }
        )

        expect(reloaded_instance).to receive(:update).once.and_call_original
        reloaded_instance.find("Andale Mono", nil)
        reloaded_instance.find("Andale Mono", nil)
      end
    end
  end
end
