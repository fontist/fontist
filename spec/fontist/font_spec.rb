require "spec_helper"

RSpec.describe Fontist::Font do
  describe ".all" do
    it "list all supported fonts" do
      fonts = Fontist::Font.all

      expect(fonts.count).to be > 10
      expect(fonts.first.name).not_to be_nil
      expect(fonts.first.styles).not_to be_nil
    end
  end

  describe ".find" do
    let(:command) { Fontist::Font.find(font) }

    context "with valid font name" do
      it "returns the fonts path" do
        name = "DejaVuSerif.ttf"
        stub_system_font_finder_to_fixture(name)
        dejavu_ttf = Fontist::Font.find(name)

        expect(dejavu_ttf.first).to include(name)
      end
    end

    context "with downloadable font name" do
      let(:font) { "Courier New" }

      it "raises font missing error" do
        allow(Fontist::SystemFont).to receive(:find).and_return(nil)

        expect { command }.to raise_error Fontist::Errors::MissingFontError
        expect { command }.to(
          raise_error { |e| expect(e.font).to eq "Courier New" },
        )
        expect { command }.to(
          raise_error { |e| expect(e.name).to eq "Font name: 'Courier New'" },
        )
      end
    end

    context "with invalid font name" do
      let(:font) { "InvalidFont.ttf" }

      it "raises font unsupported error" do
        no_fonts do
          expect { command }.to raise_error Fontist::Errors::UnsupportedFontError
          expect { command }.to(raise_error { |e| expect(e.font).to eq "InvalidFont.ttf" })
        end
      end
    end

    context "with macos system fonts", slow: true, macos: true do
      # rubocop:disable Metrics/LineLength
      fonts = [
        ["Arial Unicode MS", "/System/Library/Fonts/Supplemental/Arial Unicode.ttf"],
        ["AppleGothic", "/System/Library/Fonts/Supplemental/AppleGothic.ttf"],
        ["Apple Braille", "/System/Library/Fonts/Apple Braille Outline 6 Dot.ttf"],
        ["Apple Symbols", "/System/Library/Fonts/Apple Symbols.ttf"],
        ["Helvetica", "/System/Library/Fonts/Helvetica.ttc"],
      ]
      # rubocop:enable Metrics/LineLength

      fonts.each do |font_name, path|
        context font_name do
          let(:font) { font_name }

          it "returns #{path}" do
            expect(command).to include(path)
          end
        end
      end
    end

    context "with windows system fonts", windows: true do
      fonts = [
        ["Arial", "C:/Windows/Fonts/arial.ttf"],
        ["Cambria", "C:/Windows/Fonts/cambria.ttc"],
        ["Calibri", "C:/Windows/Fonts/calibri.ttf"],
        ["Segoe UI", "C:/Windows/Fonts/segoeui.ttf"],
      ]

      fonts.each do |font_name, path|
        context font_name do
          let(:font) { font_name }

          it "returns #{path}" do
            expect(command).to include(path)
          end
        end
      end
    end

    context "with windows user fonts", windows: true do
      let(:font) { "dejavu serif" }
      let(:fixture_path) { Fontist.root_path.join("spec", "fixtures", "fonts", "DejaVuSerif.ttf") } # rubocop:disable Metrics/LineLength
      let(:user_path) { File.join("AppData", "Local", "Microsoft", "Windows", "Fonts", "DejaVuSerif.ttf") } # rubocop:disable Metrics/LineLength
      let(:absolute_user_path) { File.join(Dir.home, user_path) }

      before do
        FileUtils.mkdir_p(File.dirname(absolute_user_path))
        FileUtils.cp(fixture_path, absolute_user_path)
      end

      it "returns user's path" do
        expect(command).to include(include(user_path))
      end
    end
  end

  describe ".install" do
    include_context "fresh home"

    let(:command) do
      Fontist::Font.install(font, confirmation: "yes", **options)
    end

    let(:options) { {} }

    context "with valid font name" do
      it "installs and returns paths for fonts with open license" do
        example_formula("andale.yml")
        font_paths = Fontist::Font.install("andale mono", confirmation: "yes")

        expect(font_paths).to include(include("AndaleMo.TTF"))
      end

      it "install proprietary fonts with correct license agreement" do
        example_formula("andale.yml")
        stub_license_agreement_prompt_with("yes")
        font_paths = Fontist::Font.install("andale mono")

        expect(font_paths).to include(include("AndaleMo.TTF"))
      end

      it "raises error for missing license agreement" do
        example_formula("andale.yml")
        stub_license_agreement_prompt_with("no")

        expect { Fontist::Font.install("andale mono") }.to raise_error(
          Fontist::Errors::LicensingError
        )
      end
    end

    context "uninstalled but supported" do
      let(:font) { "andale mono" }
      let(:url) do
        "https://gitlab.com/fontmirror/archive/-/raw/master/andale32.exe"
      end

      before { example_formula("andale.yml") }

      around { |example| avoid_cache(url) { example.run } }

      it "prints descriptive messages of what's going on" do
        # rubocop:disable Metrics/LineLength
        expect(Fontist.ui).to receive(:say).with(%(Font "andale mono" not found locally.))
        expect(Fontist.ui).to receive(:say).with(%(Downloading font "andale" from https://gitlab.com/fontmirror/archive/-/raw/master/andale32.exe))
        expect(Fontist.ui).to receive(:print).with(/\r\e\[0KDownloading:\s+\d+% \(\d+\/\d+ MiB\)/)
        expect(Fontist.ui).to receive(:print).with(/, \d+\.\d+ MiB\/s, done\./)
        expect(Fontist.ui).to receive(:say).with(%(Installing font "andale".))
        expect(Fontist.ui).to receive(:say).with(%(Fonts installed at:))
        expect(Fontist.ui).to receive(:say).with(%(- #{font_path('AndaleMo.TTF')}))
        # rubocop:enable Metrics/LineLength

        command
      end
    end

    context "with --no-progress option" do
      let(:font) { "fira code" }
      let(:url) { "https://github.com/tonsky/FiraCode/releases/download/5.2/Fira_Code_v5.2.zip" }
      let(:options) { { no_progress: true } }

      before { example_formula("fira_code.yml") }

      around { |example| avoid_cache(url) { example.run } }

      it "skips printing of progress lines" do
        expect(Fontist.ui).to receive(:print).with(/\r\e\[0KDownloading:/).once
        expect(Fontist.ui).to receive(:print).with(/done/).once
        command
      end
    end

    context "uninstalled but supported and in cache" do
      let(:font) { "andale mono" }
      let(:options) { { force: true } }
      before { example_formula("andale.yml") }

      it "tells about fetching from cache" do
        Fontist::Font.install(font, confirmation: "yes")

        expect(Fontist.ui)
          .to receive(:say).with(/Fetched from cache: \d+ MiB\./)
        command
      end
    end

    context "already installed font" do
      let(:font) { "andale mono" }
      before { example_font("AndaleMo.TTF") }

      it "tells that font found locally" do
        expect(Fontist.ui).to receive(:say).with(%(Fonts found at:))
        expect(Fontist.ui).to receive(:say)
          .with(include(font_path("AndaleMo.TTF")))

        command
      end
    end

    context "with existing font name" do
      before { example_formula("courier.yml") }

      it "returns the existing font paths" do
        font = "Courier New"
        Fontist::Font.install(font, confirmation: "yes")

        font_paths = Fontist::Font.install(font, confirmation: "yes")

        expect(font_paths.count).to be > 3
        expect_any_instance_of(Fontist::FontInstaller).not_to receive(:install)
      end
    end

    context "with collection font name" do
      let(:font) { "Source Han Sans" }
      let(:file) { "SourceHanSans-Normal.ttc" }
      before { example_formula("source.yml") }

      it "returns path of collection file" do
        expect(command).to include(include(file))
      end
    end

    context "with font name when installed" do
      let(:font) { "cambria" }
      let(:file) { "CAMBRIA.TTC" }

      it "skips download" do
        example_font(file)
        expect_any_instance_of(Fontist::FontInstaller).not_to receive(:install)
        command
      end
    end

    context "with unsupported fonts" do
      let(:command) do
        Fontist::Font.install(font, confirmation: "no")
      end

      let(:font) { "Invalid font name" }

      it "raises an unsupported error" do
        expect { command }.to raise_error(Fontist::Errors::UnsupportedFontError)
        expect { command }.to(
          raise_error { |e| expect(e.font).to eq "Invalid font name" },
        )
      end
    end

    context "with msi archive" do
      before { example_formula("adobe_reader_19.yml") }

      it "installs and returns paths for fonts" do
        font = { name: "Adobe Arabic", filename: "adobearabic_bold.otf" }
        font_paths = Fontist::Font.install(font[:name], confirmation: "yes")

        expect(font_paths.join("|").downcase).to include(font[:filename])
      end
    end

    context "with 7z archive" do
      before { example_formula("adobe_reader_20.yml") }

      it "installs and returns paths for fonts" do
        font = { name: "Adobe Pi Std", filename: "adobepistd.otf" }
        font_paths = Fontist::Font.install(font[:name], confirmation: "yes")

        expect(font_paths.join("|").downcase).to include(font[:filename])
      end
    end

    context "with rpm archive" do
      let(:font) { "Wingdings" }
      before { example_formula("webcore.yml") }

      it "installs and returns paths for fonts" do
        expect(command).to include(include("wingding.ttf"))
      end
    end

    context "with subarchive option", slow: true do
      let(:font) { "guttman aharoni" }
      let(:file) { "GAHROM.ttf" }
      before { example_formula("guttman.yml") }

      it "installs and returns paths for fonts" do
        expect(command).to include(include(file))
      end
    end

    context "with subdir option" do
      let(:font) { "Work Sans" }
      let(:file) { "WorkSans-Black.ttf" }
      let(:current_version_size) { 203512 }
      before { example_formula("work_sans.yml") }

      it "installs from proper directory", slow: true do
        command
        expect(font_file(file).size).to eq current_version_size
      end
    end

    context "with force flag when installed" do
      include_context "system fonts"

      let(:font) { "andale mono" }
      let(:file) { "AndaleMo.TTF" }
      let(:options) { { force: true } }
      before { example_formula("andale.yml") }

      it "installs font anyway" do
        example_font_to_system(file)
        expect(font_file(file)).not_to exist
        command
        expect(font_file(file)).to exist
      end
    end

    context "with unusual font extension" do
      let(:font) { "adobe devanagari" }
      let(:file) { "adobedevanagari_bolditalic.otf" }
      before { example_formula("adobe_reader_19.yml") }

      it "detects, renames and installs the font" do
        command
        expect(font_file(file)).to exist
      end
    end

    context "with set FONTIST_PATH env" do
      let(:font) { "andale mono" }
      let(:file) { "AndaleMo.TTF" }
      let(:fontist_path) { create_tmp_dir }

      it "installs font at a FONTIST_PATH directory" do
        Dir.mktmpdir do |fontist_path|
          stub_env("FONTIST_PATH", fontist_path) do
            FileUtils.mkdir_p(Fontist.formulas_path)
            example_formula_to("andale.yml", Fontist.formulas_path)

            rebuilt_index do
              command
              expect(Pathname.new(File.join(fontist_path, "fonts", file)))
                .to exist
            end
          end
        end
      end
    end

    context "when several formulas exist" do
      let(:font) { "andale mono" }
      before { example_formula("andale.yml") }
      before { example_formula("webcore.yml") }

      it "installs all matching formulas" do
        expect(Fontist::FontInstaller).to receive(:new).at_least(2).times
          .and_call_original
        command
        expect(font_file("AndaleMo.TTF")).to exist
        expect(font_file("andalemo.ttf")).to exist
      end
    end

    context "when several formulas exist and require license agreement" do
      let(:command) { Fontist::Font.install(font, confirmation: "no", **options) }
      let(:font) { "andale mono" }
      before { example_formula("andale.yml") }
      before { example_formula("webcore.yml") }

      it "asks for acceptance for each formula" do
        expect(Fontist.ui).to receive(:ask).and_return("yes")
          .at_least(2).times
        command
      end
    end

    context "preferred family and no option" do
      let(:font) { "lato heavy" }
      before { example_formula("lato.yml") }

      it "installs by default family" do
        expect(command).to include(include("Lato-Heavy.ttf"))
        expect(font_file("Lato-Heavy.ttf")).to exist
      end
    end

    context "preferred family with option" do
      let(:font) { "lato heavy" }
      before { example_formula("lato.yml") }

      it "does not find by default family" do
        with_option(:preferred_family) do
          expect { command }
            .to raise_error(Fontist::Errors::UnsupportedFontError)
          expect(font_file("Lato-Heavy.ttf")).not_to exist
        end
      end
    end
  end

  describe ".uninstall" do
    let(:command) { Fontist::Font.uninstall(font) }

    context "with unsupported font" do
      let(:font) { "nonexistent" }

      it "raises font unsupported error" do
        expect { command }.to raise_error Fontist::Errors::UnsupportedFontError
        expect { command }.to(raise_error { |e| expect(e.font).to eq "nonexistent" })
      end
    end

    context "with unsupported font but available in system" do
      let(:font) { "menlo" }
      before { stub_system_font_to("/System/Library/Fonts/Menlo.ttc") }

      it "raises font unsupported error" do
        expect { command }.to raise_error Fontist::Errors::UnsupportedFontError
      end
    end

    context "with supported font but not installed" do
      let(:font) { "overpass" }

      it "raises font missing error" do
        stub_system_fonts
        stub_fonts_path_to_new_path do
          expect { command }.to raise_error Fontist::Errors::MissingFontError
          expect { command }.to(raise_error { |e| expect(e.font).to eq "overpass" })
        end
      end
    end

    context "with supported and installed font" do
      it "removes font" do
        stub_fonts_path_to_new_path do
          example_font_to_fontist("overpass-regular.otf")

          Fontist::Font.uninstall("overpass")
          expect(font_file("overpass-regular.otf")).not_to exist
        end
      end
    end

    context "with supported but half of name specified" do
      let(:font) { "segoe" }

      it "keeps other fonts" do
        stub_fonts_path_to_new_path do
          example_font("overpass-regular.otf")

          expect { command }.to raise_error Fontist::Errors::UnsupportedFontError
          expect(font_file("overpass-regular.otf")).to exist
        end
      end
    end

    context "with the second font in formula" do
      let(:font) { "overpass mono" }
      let(:this) { "overpass-mono-regular.otf" }
      let(:other) { "overpass-regular.otf" }

      it "removes only this font and keeps others" do
        stub_fonts_path_to_new_path do
          [this, other].each { |f| example_font_to_fontist(f) }

          command

          expect(font_file(this)).not_to exist
          expect(font_file(other)).to exist
        end
      end
    end

    context "preferred family and no option" do
      let(:font) { "lato heavy" }

      it "uninstall by default family" do
        fresh_fonts_and_formulas do
          example_font("Lato-Heavy.ttf")

          command
          expect(font_file("Lato-Heavy.ttf")).not_to exist
        end
      end
    end
  end

  describe ".status" do
    let(:command) { Fontist::Font.status(font) }

    context "with unsupported font" do
      let(:font) { "nonexistent" }

      it "raises font unsupported error" do
        no_fonts do
          expect { command }.to raise_error Fontist::Errors::UnsupportedFontError
          expect { command }.to(raise_error { |e| expect(e.font).to eq "nonexistent" })
        end
      end
    end

    context "with supported font but not installed" do
      let(:font) { "andale mono" }

      it "raises font missing error" do
        stub_system_fonts
        stub_fonts_path_to_new_path do
          expect { command }.to raise_error Fontist::Errors::MissingFontError
          expect { command }.to(raise_error { |e| expect(e.font).to eq "andale mono" })
        end
      end
    end

    context "with supported and installed font" do
      let(:font) { "andale mono" }

      it "returns its path" do
        stub_system_fonts
        stub_fonts_path_to_new_path do
          example_font_to_fontist("AndaleMo.TTF")

          expect(command).to eq [font_path("AndaleMo.TTF")]
        end
      end
    end

    context "with no font and nothing installed" do
      let(:font) { nil }

      it "returns system fonts" do
        stub_fonts_path_to_new_path do
          expect(command.size).to be > 1
        end
      end
    end

    context "with no font and no system font" do
      let(:font) { nil }

      it "returns no fonts" do
        stub_fonts_path_to_new_path do
          stub_system_fonts_path_to_new_path do
            expect(command.size).to be 0
          end
        end
      end
    end

    context "with no font and a font installed" do
      let(:font) { nil }

      it "returns installed font with its path" do
        stub_system_fonts
        stub_fonts_path_to_new_path do
          example_font_to_fontist("AndaleMo.TTF")

          expect(command).to eq [font_path("AndaleMo.TTF")]
        end
      end
    end

    context "when installed from another formula" do
      let(:font) { "arial" }

      it "shows original formula" do
        no_fonts do
          example_font_to_fontist("ariali.ttf")

          expect(Fontist.ui).to receive(:say).with(/from .*webcore formula/)
          command
        end
      end
    end

    context "preferred family and no option" do
      let(:font) { "lato heavy" }

      it "finds by default family" do
        fresh_fonts_and_formulas do
          example_font("Lato-Heavy.ttf")
          expect(command).to include(include("Lato-Heavy.ttf"))
        end
      end
    end
  end

  describe ".list" do
    let(:command) { Fontist::Font.list(font) }

    context "with unsupported font" do
      let(:font) { "nonexistent" }

      it "raises font unsupported error" do
        expect { command }.to raise_error Fontist::Errors::UnsupportedFontError
        expect { command }.to(raise_error { |e| expect(e.font).to eq "nonexistent" })
      end
    end

    context "with supported font but not installed" do
      let(:font) { "andale mono" }

      it "returns its status as uninstalled" do
        stub_system_fonts
        stub_fonts_path_to_new_path do
          expect(command.size).to be >= 1

          installs = unpack_statuses(command)
          expect(installs).to all(be false)
        end
      end
    end

    context "with supported and installed font" do
      let(:font) { "andale mono" }

      it "returns its status as installed" do
        stub_system_fonts
        stub_fonts_path_to_new_path do
          stub_font_file("AndaleMo.TTF")

          expect(command.size).to be >= 1
          installs = unpack_statuses(command)
          expect(installs).to include true
        end
      end
    end

    context "with no font and nothing installed" do
      let(:font) { nil }

      it "returns all fonts", slow: true do
        stub_fonts_path_to_new_path do
          expect(command.size).to be > 1000
          _, _, _, installed = unpack_status(command)
          expect(installed).to be false
        end
      end
    end

    context "with no font and a font installed" do
      let(:font) { nil }

      it "returns installed font with its path" do
        stub_system_fonts
        stub_fonts_path_to_new_path do
          stub_font_file("AndaleMo.TTF")

          expect(command.size).to be > 1000

          statuses = command.map do |_, fonts|
            fonts.map do |_, styles|
              styles.values
            end
          end.flatten

          expect(statuses).to include(true)
        end
      end
    end
  end

  def unpack_status(formulas)
    formula, fonts = formulas.first
    font, styles = fonts.first
    style, status = styles.first
    [formula, font, style, status]
  end

  def unpack_statuses(formulas)
    formulas.flat_map do |_formula, fonts|
      fonts.flat_map do |_font, styles|
        styles.map do |_style, status|
          status
        end
      end
    end
  end
end
