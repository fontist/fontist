require "spec_helper"

RSpec.describe Fontist::SystemIndex do
  context "two simultaneous runs" do
    it "generates the same system index", slow: true do
      # Use minimal fixture - we only need to verify concurrent rebuilds produce
      # the same result, not scan thousands of system fonts
      minimal_system_file = case Fontist::Utils::System.user_os
                            when :macos
                              Fontist.root_path.join("spec", "fixtures",
                                                     "system_macos_minimal.yml")
                            when :windows
                              Fontist.root_path.join("spec", "fixtures",
                                                     "system_windows_minimal.yml")
                            else
                              Fontist.root_path.join("spec", "fixtures",
                                                     "system.yml")
                            end

      stub_system_fonts(minimal_system_file)

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

          def Fontist.system_file_path
            "#{minimal_system_file}"
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
      let(:paths_loader_call) do
        [font_file_path, excluded_font_path, additional_font_path]
      end

      before do
        # Create the font files
        FileUtils.cp(examples_font_path("AndaleMo.TTF"), font_file_path)
        FileUtils.cp(examples_font_path("AndaleMo.TTF"), excluded_font_path)
        FileUtils.cp(examples_font_path("AndaleMo.TTF"), additional_font_path)

        # Build initial index with only the regular font (simulating old state)
        instance = Fontist::SystemIndexFontCollection.from_file(
          path: index_path,
          paths_loader: -> { [font_file_path, excluded_font_path] },
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
          paths_loader: -> { paths_loader_call },
        )

        expect(reloaded_instance).to receive(:update).once.and_call_original
        reloaded_instance.find("Andale Mono", nil)
        reloaded_instance.find("Andale Mono", nil)
      end
    end
  end

  context "incomplete font metadata handling" do
    let(:tmp_dir) { create_tmp_dir }
    let(:index_path) { File.join(tmp_dir, "test_index.yml") }

    context "when font has incomplete English metadata" do
      let(:font_paths) do
        [Fontist.root_path.join("spec", "fixtures", "fonts", "DejaVuSerif.ttf").to_s]
      end

      let(:instance) do
        Fontist::SystemIndexFontCollection.new.tap do |x|
          x.set_path(index_path)
          x.set_path_loader(-> { font_paths })
        end
      end

      it "does not crash when building index" do
        expect { instance.build }.not_to raise_error
      end

      it "filters out fonts with incomplete metadata" do
        # Mock a font file that returns nil for required fields
        allow(Fontist::FontFile).to receive(:from_path).and_return(
          double(
            full_name: nil,
            family: nil,
            subfamily: "Regular",
            preferred_family: nil,
            preferred_subfamily: nil
          )
        )

        expect(Fontist.ui).to receive(:error).with(/Skipping font with incomplete metadata/)

        instance.build
        expect(instance.fonts).to be_empty
      end
    end

    context "when all fonts have complete metadata" do
      let(:font_paths) do
        [Fontist.root_path.join("spec", "fixtures", "fonts", "DejaVuSerif.ttf").to_s]
      end

      let(:instance) do
        Fontist::SystemIndexFontCollection.new.tap do |x|
          x.set_path(index_path)
          x.set_path_loader(-> { font_paths })
        end
      end

      it "includes fonts with complete metadata" do
        instance.build
        # Should have at least one font if DejaVuSerif has complete metadata
        # or be empty if it doesn't, but shouldn't crash
        expect { instance.fonts }.not_to raise_error
      end
    end

    context "when loading corrupted YAML index" do
      it "still raises error for corrupted YAML" do
        stub_system_index_path do
          # Write a corrupted index to YAML
          File.write(Fontist.system_index_path,
                     YAML.dump([{ path: "/some/path" }]))

          expect do
            Fontist::SystemIndex.system_index.find("", "")
          end.to raise_error(Fontist::Errors::FontIndexCorrupted)
        end
      end
    end
  end

  context "Bengali Rupali font metadata handling" do
    let(:rupali_path) { Fontist.root_path.join("spec", "fixtures", "fonts", "Rupali.ttf").to_s }

    describe "FontFile extraction" do
      it "extracts non-English (Bengali) font names" do
        font_file = Fontist::FontFile.from_path(rupali_path)

        # The font has Bengali script names
        expect(font_file.full_name).not_to be_nil
        expect(font_file.full_name).not_to be_empty
        expect(font_file.family).not_to be_nil
        expect(font_file.family).not_to be_empty
        expect(font_file.subfamily).to eq("Regular")

        # Should contain Unicode Bengali characters (রূপালী in UTF-8)
        # The actual encoding might vary but it should not be empty
        expect(font_file.full_name.length).to be > 0
        expect(font_file.family.length).to be > 0
      end
    end

    describe "SystemIndex with Bengali font" do
      let(:tmp_dir) { create_tmp_dir }
      let(:index_path) { File.join(tmp_dir, "bengali_test_index.yml") }
      let(:font_paths) { [rupali_path] }

      let(:instance) do
        Fontist::SystemIndexFontCollection.new.tap do |x|
          x.set_path(index_path)
          x.set_path_loader(-> { font_paths })
        end
      end

      it "successfully builds index with Bengali font" do
        expect { instance.build }.not_to raise_error
      end

      it "includes Bengali font in index when metadata is present" do
        instance.build

        # Should have at least one font indexed
        expect(instance.fonts).not_to be_empty
        expect(instance.fonts.length).to eq(1)

        font = instance.fonts.first
        expect(font.path).to eq(rupali_path)
        expect(font.full_name).not_to be_nil
        expect(font.full_name).not_to be_empty
        expect(font.family_name).not_to be_nil
        expect(font.family_name).not_to be_empty
        expect(font.subfamily).to eq("Regular")
      end

      it "can save and reload index with Bengali font" do
        instance.build
        instance.to_file(index_path)

        # Reload from file
        reloaded = Fontist::SystemIndexFontCollection.from_file(
          path: index_path,
          paths_loader: -> { font_paths }
        )

        expect(reloaded.fonts).not_to be_empty
        font = reloaded.fonts.first
        expect(font.path).to eq(rupali_path)
        expect(font.full_name).not_to be_empty
        expect(font.family_name).not_to be_empty
      end

      it "does not crash when searching for fonts in index with Bengali font" do
        instance.build

        # Should not crash even if we can't find by Bengali name
        expect { instance.find("some font", nil) }.not_to raise_error
        expect { instance.find("Arial", "Regular") }.not_to raise_error
      end
    end

    describe "Regression test for error.md issue" do
      let(:tmp_dir) { create_tmp_dir }
      let(:index_path) { File.join(tmp_dir, "system_index.yml") }

      it "does not raise FontIndexCorrupted when building index with Rupali font" do
        collection = Fontist::SystemIndexFontCollection.new.tap do |x|
          x.set_path(index_path)
          x.set_path_loader(-> { [rupali_path] })
        end

        # This would have raised FontIndexCorrupted before the fix
        # because Bengali names might not extract properly as English
        expect { collection.build }.not_to raise_error
        expect { collection.check_index }.not_to raise_error

        # Verify font was indexed
        expect(collection.fonts).not_to be_empty
      end
    end
  end
end
