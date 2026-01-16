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
          expect { command }.to(raise_error do |e|
            expect(e.font).to eq "InvalidFont.ttf"
          end)
        end
      end
    end

    context "with macos system fonts", slow: true, macos: true do
      before do
        # Use minimal fixture that only includes the specific fonts being tested
        # This avoids scanning thousands of system fonts and speeds up tests dramatically
        minimal_system_file = Fontist.root_path.join("spec", "fixtures",
                                                     "system_macos_minimal.yml")
        stub_system_fonts(minimal_system_file)
        # Rebuild system index to detect actual macOS fonts
        Fontist::SystemIndex.system_index.rebuild
      end

      after do
        # Reset system index to prevent affecting other tests
        Fontist::SystemIndex.reset_cache
        Fontist::SystemFont.reset_font_paths_cache
      end

      # rubocop:disable Layout/LineLength
      # Fonts confirmed to exist on vanilla GHA macOS runners
      fonts = [
        ["Apple Braille", "/System/Library/Fonts/Apple Braille Outline 6 Dot.ttf"],
        ["Apple Symbols", "/System/Library/Fonts/Apple Symbols.ttf"],
        ["Courier", "/System/Library/Fonts/Courier.ttc"],
        ["Helvetica", "/System/Library/Fonts/Helvetica.ttc"],
        ["Times", "/System/Library/Fonts/Times.ttc"],
      ]
      # rubocop:enable Layout/LineLength

      fonts.each do |font_name, path|
        context font_name do
          let(:font) { font_name }

          it "returns #{path}" do
            expect(command).to include(path)
          end
        end
      end
    end

    context "with windows system fonts", windows: true, slow: true do
      before do
        # Use minimal fixture that only includes the specific fonts being tested
        minimal_system_file = Fontist.root_path.join("spec", "fixtures",
                                                     "system_windows_minimal.yml")
        stub_system_fonts(minimal_system_file)
      end

      # Fonts confirmed to exist on vanilla GHA Windows runners
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
      let(:fixture_path) { Fontist.root_path.join("spec", "fixtures", "fonts", "DejaVuSerif.ttf") } # rubocop:disable Layout/LineLength
      let(:user_path) { File.join("AppData", "Local", "Microsoft", "Windows", "Fonts", "DejaVuSerif.ttf") } # rubocop:disable Layout/LineLength
      let(:absolute_user_path) { File.join(Dir.home, user_path) }

      before do
        FileUtils.mkdir_p(File.dirname(absolute_user_path))
        FileUtils.cp(fixture_path, absolute_user_path)
        # Use minimal fixture for Windows user font tests
        minimal_system_file = Fontist.root_path.join("spec", "fixtures",
                                                     "system_windows_minimal.yml")
        stub_system_fonts(minimal_system_file)
      end

      after do
        FileUtils.rm(absolute_user_path)
      end

      it "returns user's path" do
        expect(command).to include(include(user_path))
      end
    end

    context "differing platforms" do
      include_context "fresh home"

      let(:font) { "work sans" }
      before { example_formula("work_sans_macos_only.yml") }

      before do
        allow(Fontist::Utils::System).to receive(:user_os).and_return(:windows)
      end

      it "raises font unsupported error" do
        expect { command }.to raise_error Fontist::Errors::UnsupportedFontError
      end
    end

    context "differing platform versions" do
      include_context "fresh home"

      let(:font) { "work sans" }
      before { example_formula("work_sans_macos_19_only.yml") }

      before do
        allow(Fontist::Utils::System).to receive(:user_os_with_version)
          .and_return("macos-18")
      end

      it "raises font unsupported error" do
        expect { command }.to raise_error Fontist::Errors::UnsupportedFontError
      end
    end

    context "manual font" do
      include_context "fresh home"

      let(:font) { "al firat" }
      before { example_formula("manual.yml") }

      it "raises manual font error" do
        expect { command }.to raise_error Fontist::Errors::ManualFontError
      end
    end
  end

  describe ".install" do
    include_context "fresh home"

    let(:subject) { command }

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
          Fontist::Errors::LicensingError,
        )
      end

      it "raises licensing error in fully detached mode" do
        example_formula("andale.yml")
        stub_license_agreement_prompt_with_exception
        expect { Fontist::Font.install("andale mono") }.to raise_error(
          Fontist::Errors::LicensingError,
        )
      end
    end

    context "not installed but supported" do
      let(:font) { "andale mono" }
      let(:url) do
        "https://gitlab.com/fontmirror/archive/-/raw/master/andale32.exe"
      end

      before { example_formula("andale.yml") }

      around { |example| avoid_cache(url) { example.run } }

      it "prints descriptive messages of what's going on" do
        # rubocop:disable Layout/LineLength
        expect(Fontist.ui).to receive(:say).with(%(Font "andale mono" not found locally.))
        expect(Fontist.ui).to receive(:say).with(%(Downloading from https://gitlab.com/fontmirror/archive/-/raw/master/andale32.exe))
        expect(Fontist.ui).to receive(:print).with(/\r\e\[0KDownloading:\s+\d+% \(\d+\/\d+ MiB\)/)
        expect(Fontist.ui).to receive(:print).with(/, \d+\.\d+ MiB\/s, done\./)
        expect(Fontist.ui).to receive(:say).with(%(Installing from formula "andale".))
        expect(Fontist.ui).to receive(:say).with(%(Fonts installed at:))
        expect(Fontist.ui).to receive(:say).with(%(- #{formula_font_path('andale', 'AndaleMo.TTF')}))
        # rubocop:enable Layout/LineLength

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

    context "not installed but supported and in cache" do
      let(:font) { "andale mono" }
      let(:options) { { force: true } }
      before { example_formula("andale.yml") }

      it "tells about fetching from cache" do
        Fontist::Font.install(font, confirmation: "yes")

        expect(Fontist.ui)
          .to receive(:say).with("Using cached file.")
        command
      end
    end

    context "already installed font" do
      let(:font) { "andale mono" }
      before { example_font("AndaleMo.TTF") }

      it "tells that font found locally" do
        expect(Fontist.ui).to receive(:say).with(%(Fonts found at:))
        expect(Fontist.ui).to receive(:say)
          .with(include("AndaleMo.TTF"))

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
      let(:file) { "SourceHanSans-Bold.ttc" }
      before { example_formula("source.yml") }

      it "returns path of collection file", slow: true do
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

      it "installs and returns paths for fonts", slow: true do
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
      let(:file) { "WorkSans-Regular.ttf" }
      let(:current_version_size) { 212660 }
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
        safe_mktmpdir do |fontist_path|
          stub_env("FONTIST_PATH", fontist_path) do
            FileUtils.mkdir_p(Fontist.formulas_path)
            example_formula_to("andale.yml", Fontist.formulas_path)

            rebuilt_index do
              command
              expect(Pathname.new(File.join(fontist_path, "fonts", "andale",
                                            file)))
                .to exist
            end
          end
        end
      end
    end

    context "when requires license agreement" do
      let(:command) { Fontist::Font.install(font, confirmation: "no", **options) }
      let(:font) { "andale mono" }
      before { example_formula("andale.yml") }

      it "asks for acceptance for each formula" do
        expect(Fontist.ui).to receive(:ask).and_return("yes").once
        command
      end
    end

    context "preferred family and no option" do
      let(:font) { "texgyrechorus" }
      before { example_formula("tex_gyre_chorus.yml") }

      it "installs by default family" do
        expect(command).to include(include("texgyrechorus-mediumitalic.otf"))
        expect(font_file("texgyrechorus-mediumitalic.otf")).to exist
      end
    end

    context "preferred family with option" do
      let(:font) { "texgyrechorus" }
      before { example_formula("tex_gyre_chorus.yml") }

      it "does not find by default family" do
        with_option(:preferred_family) do
          expect { command }
            .to raise_error(Fontist::Errors::UnsupportedFontError)
          expect(font_file("texgyrechorus-mediumitalic.otf")).not_to exist
        end
      end
    end

    context "differing platform" do
      let(:font) { "work sans" }
      before { example_formula("work_sans_macos_only.yml") }

      before do
        allow(Fontist::Utils::System).to receive(:user_os).and_return(:windows)
      end

      it "raises font unsupported error" do
        expect { command }.to raise_error Fontist::Errors::UnsupportedFontError
      end
    end

    context "the same platform" do
      let(:font) { "work sans" }
      before { example_formula("work_sans_macos_only.yml") }

      before do
        allow(Fontist::Utils::System).to receive(:user_os).and_return(:macos)
      end

      it "does not raise any error" do
        expect { command }.not_to raise_error
      end
    end

    context "has min_fontist attribute" do
      context "higher min_fontist" do
        let(:font) { "texgyrechorus" }
        before { example_formula("tex_gyre_chorus_min_fontist_and_font.yml") }

        it "throws FontistVersionError" do
          expect { command }.to raise_error Fontist::Errors::FontistVersionError
        end
      end

      context "higher min_fontist, above size limit" do
        let(:font) { "texgyrechorus" }
        before { example_formula("tex_gyre_chorus_min_fontist_and_font.yml") }
        before { set_size_limit(0) }

        before do
          allow_any_instance_of(Fontist::Utils::Cache)
            .to receive(:already_fetched?).and_return(false)
        end

        it "raises size-limit error" do
          expect { command }.to raise_error(Fontist::Errors::SizeLimitError)
        end
      end

      context "higher min_fontist, missing version" do
        let(:font) { "texgyrechorus" }
        before { example_formula("tex_gyre_chorus_min_fontist_and_font.yml") }
        let(:options) { { version: "100.0" } }

        it "raises font unsupported error" do
          expect { command }
            .to raise_error Fontist::Errors::UnsupportedFontError
        end
      end

      context "two formulas, better choice with higher min_fontist" do
        let(:font) { "texgyrechorus" }
        before do
          example_formula("tex_gyre_chorus_min_fontist_and_font.yml")
          example_formula("tex_gyre_chorus.yml")
        end

        it "installs from that which does not require higher version" do
          expect(command).to include(include("texgyrechorus-mediumitalic.otf"))
          expect(font_file("texgyrechorus-mediumitalic.otf")).to exist
        end
      end

      context "one formula, requires lower version of fontist" do
        let(:font) { "texgyrechorus" }
        before { example_formula("tex_gyre_chorus_min_fontist_1.yml") }

        it "installs font" do
          expect(command).to include(include("texgyrechorus-mediumitalic.otf"))
          expect(font_file("texgyrechorus-mediumitalic.otf")).to exist
        end
      end
    end

    context "manual font" do
      include_context "fresh home"

      let(:font) { "al firat" }
      before { example_formula("manual.yml") }

      it "raises manual font error" do
        expect { command }.to raise_error Fontist::Errors::ManualFontError
      end
    end

    context "two formulas with the same font" do
      before do
        allow_any_instance_of(Fontist::Utils::Cache)
          .to receive(:already_fetched?).and_return(false)
      end

      context "diff size, below the limit and above" do
        let(:font) { "source code pro" }

        # file_size: 101_440_249, version: 2.030
        before { example_formula("source.yml") }

        # file_size not set, version: 0.050, 0.030
        before { example_formula("source_code_pro_version_0.yml") }

        before { set_size_limit(10) }

        it "installs the smallest" do
          expect_to_install("source_code_pro_version_0")
          command
        end
      end

      context "both size below the limit, diff versions" do
        let(:font) { "source code pro" }
        before { example_formula("source.yml") }
        before { example_formula("source_code_pro_version_0.yml") }
        before { set_size_limit(1000) }

        it "installs the newest" do
          expect_to_install("source")
          command
        end
      end

      context "both size below the limit, same versions" do
        let(:font) { "source code pro" }
        before { example_formula("source.yml") }
        before { example_formula("source_code_pro.yml") }
        before { set_size_limit(1000) }

        it "installs the smallest" do
          expect_to_install("source_code_pro")
          command
        end
      end

      context "size above the limit" do
        let(:font) { "source code pro" }
        before { example_formula("source.yml") }
        before { set_size_limit(0) }

        it "raises size-limit error" do
          expect { command }.to raise_error(Fontist::Errors::SizeLimitError)
        end
      end

      context "formula has no file_size and size limit is very low" do
        let(:font) { "source code pro" }
        before { example_formula("source_code_pro.yml") }
        before { set_size_limit(0) }

        it "install the formula anyway" do
          expect_to_install("source_code_pro")
          command
        end
      end

      context "missing version" do
        let(:font) { "cambria" }
        before { example_formula("cleartype.yml") }

        it "installs the font" do
          expect(Fontist::FontInstaller).to receive(:new).once.and_call_original
          command
        end
      end

      context "diff styles" do
        let(:font) { "au passata" }
        before { example_formula("au.yml") }
        before { example_formula("au_passata_oblique.yml") }
        before { set_size_limit(1000) }

        it "installs both" do
          # Mock FontInstaller to avoid network calls to broken AU university URLs
          # while still testing that FormulaPicker selects both formulas
          mock_location = double("location",
                                 base_path: Fontist.fonts_path,
                                 permission_warning: nil)
          mock_installer = instance_double(Fontist::FontInstaller,
                                           install: ["/fake/path.ttf"],
                                           location: mock_location)
          expect(Fontist::FontInstaller).to receive(:new).twice
            .and_return(mock_installer)
          command
        end
      end

      context "concrete version is passed" do
        let(:font) { "source code pro" }
        let(:options) { { version: "0.050" } }
        before { example_formula("source.yml") }
        before { example_formula("source_code_pro_version_0.yml") }
        before { set_size_limit(0) }

        it "installs formula with this version" do
          expect_to_install("source_code_pro_version_0")
          command
        end
      end

      context "concrete version is the smallest in a formula" do
        let(:font) { "source code pro" }
        let(:options) { { version: "0.030" } }
        before { example_formula("source_code_pro_version_0.yml") }
        before { set_size_limit(0) }

        it "installs formula with this version" do
          expect_to_install("source_code_pro_version_0")
          command
        end
      end

      context "concrete version is passed and there is no such" do
        let(:font) { "source code pro" }
        let(:options) { { version: "100.0" } }
        before { example_formula("source.yml") }
        before { example_formula("source_code_pro_version_0.yml") }
        before { set_size_limit(0) }

        it "raises font unsupported error" do
          expect { command }
            .to raise_error Fontist::Errors::UnsupportedFontError
        end
      end

      context "requested to install the smallest" do
        let(:font) { "source code pro" }
        let(:options) { { smallest: true } }
        before { example_formula("source.yml") }
        before { example_formula("source_code_pro.yml") }
        before { set_size_limit(0) }

        it "installs the smallest formula" do
          expect_to_install("source_code_pro")
          command
        end
      end

      context "requested to install the newest" do
        let(:font) { "source code pro" }
        let(:options) { { newest: true } }
        before { example_formula("source.yml") }
        before { example_formula("source_code_pro_version_0.yml") }
        before { set_size_limit(0) }

        it "installs the newest formula" do
          expect_to_install("source")
          command
        end
      end

      context "with user-defined size limit" do
        let(:font) { "source code pro" }
        let(:options) { { size_limit: 10 } }
        before { example_formula("source.yml") }
        before { example_formula("source_code_pro.yml") }

        it "installs a formula below the size limit" do
          expect_to_install("source_code_pro")
          command
        end
      end

      context "formula contains more than one font" do
        let(:font) { "lato" }
        before { example_formula("lato.yml") }

        it "installs only requested font" do
          command
          expect(Pathname.new(formula_font_path("lato",
                                                "Lato-Regular.ttf"))).to exist
          expect(Pathname.new(formula_font_path("lato",
                                                "Lato-Black.ttf"))).not_to exist
        end
      end

      context "with update_fontconfig option set to true" do
        let(:font) { "texgyrechorus" }
        before { example_formula("tex_gyre_chorus.yml") }
        let(:options) { { update_fontconfig: true } }

        it "calls Fontconfig" do
          expect(Fontist::Fontconfig).to receive(:update)
          command
        end
      end

      context "no update_fontconfig option" do
        let(:font) { "texgyrechorus" }
        before { example_formula("tex_gyre_chorus.yml") }

        it "does not call Fontconfig" do
          expect(Fontist::Fontconfig).not_to receive(:update)
          command
        end
      end

      context "with location parameter" do
        let(:font) { "andale mono" }
        before { example_formula("andale.yml") }

        context "valid locations" do
          it "installs to fontist location" do
            paths = Fontist::Font.install(font, confirmation: "yes",
                                                location: :fontist)
            expect(paths).to include(include("AndaleMo.TTF"))
            expect(paths.first).to include("andale") # formula-keyed path
          end

          it "installs to user location" do
            paths = Fontist::Font.install(font, confirmation: "yes",
                                                location: :user)
            expect(paths).to include(include("AndaleMo.TTF"))
          end

          it "installs to system location" do
            # With OOP architecture, location object handles installation
            # Just verify successful installation
            paths = Fontist::Font.install(font, confirmation: "yes",
                                                location: :system)
            expect(paths).to include(include("AndaleMo.TTF"))
          end
        end

        context "invalid locations" do
          it "shows error for invalid symbol but proceeds with default" do
            expect(Fontist.ui).to receive(:error).with(include("Invalid install location"))
            paths = Fontist::Font.install(font, confirmation: "yes",
                                                location: :invalid)
            expect(paths).to include(include("AndaleMo.TTF"))
          end

          it "raises ArgumentError for string location parameter" do
            expect do
              Fontist::Font.install(font, confirmation: "yes", location: "user")
            end.to raise_error(ArgumentError, /location must be a Symbol/)
          end

          it "raises ArgumentError for custom path (string)" do
            expect do
              Fontist::Font.install(font, confirmation: "yes",
                                          location: "/custom/path")
            end.to raise_error(ArgumentError, /location must be a Symbol/)
          end

          it "raises ArgumentError for any string value" do
            expect do
              Fontist::Font.install(font, confirmation: "yes",
                                          location: "/my/path")
            end.to raise_error(ArgumentError, /location must be a Symbol/)
          end
        end

        context "location option passed through properly" do
          it "passes location to FontInstaller" do
            # Location is created in FontInstaller constructor via InstallLocation.create
            expect(Fontist::InstallLocation).to receive(:create)
              .with(anything, hash_including(location_type: :user))
              .and_call_original

            Fontist::Font.install(font, confirmation: "yes", location: :user)
          end
        end
      end
    end

    context "with human-readable formula name" do
      let(:options) { { formula: true } }
      let(:font) { "TeX Gyre Chorus" }
      before { example_formula("tex_gyre_chorus.yml") }

      it { is_expected.to be }
    end

    context "with misspelled formula name" do
      let(:options) { { formula: true } }
      let(:font) { "TX Gyre Chorus" }
      before { example_formula("tex_gyre_chorus.yml") }

      it "raises formula-not-found error and not offers suggestions" do
        expect(Fontist.ui).not_to receive(:ask)

        expect { command }.to raise_error(Fontist::Errors::FormulaNotFoundError)
      end
    end

    def expect_to_install(_formula_key)
      expect_any_instance_of(Fontist::Font)
        .to receive(:font_installer).with(be_a(Fontist::Formula))
        .and_call_original
    end

    def set_size_limit(limit)
      allow(Fontist).to receive(:formula_size_limit_in_megabytes)
        .and_return(limit)
    end
  end

  describe ".install with no setup" do
    include_context "empty home"

    let(:command) do
      Fontist::Font.install(font, confirmation: "yes", **options)
    end

    let(:options) { {} }

    context "no main repo" do
      let(:font) { "any font" }
      before do
        # Use empty system.yml fixture - no need to scan any system fonts for this test
        stub_system_fonts(Fontist.root_path.join("spec", "fixtures",
                                                 "system.yml"))
      end

      it "throws MainRepoNotFoundError", slow: true do
        expect { command }
          .to raise_error(Fontist::Errors::MainRepoNotFoundError)
      end
    end
  end

  describe ".uninstall" do
    let(:command) { Fontist::Font.uninstall(font) }

    context "with unsupported font" do
      let(:font) { "nonexistent" }

      it "raises font unsupported error" do
        expect { command }.to raise_error Fontist::Errors::UnsupportedFontError
        expect { command }.to(raise_error do |e|
          expect(e.font).to eq "nonexistent"
        end)
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
      let(:font) { "andale mono" }

      it "raises font missing error" do
        fresh_fonts_and_formulas do
          example_formula("andale.yml")
          # Ensure font is not in any index (system, user, or fontist)
          # by not copying any font files

          expect { command }.to raise_error Fontist::Errors::MissingFontError
          expect { command }.to(
            raise_error { |e| expect(e.font).to eq "andale mono" },
          )
        end
      end
    end

    context "with supported and installed font" do
      it "removes font" do
        fresh_fonts_and_formulas do
          example_formula("overpass.yml")
          # Copy font file AND it will be indexed
          example_font("overpass-regular.otf")

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
        fresh_fonts_and_formulas do
          example_formula("overpass.yml")
          # Copy both font files AND they will be indexed
          [this, other].each { |f| example_font(f) }

          command

          expect(font_file(this)).not_to exist
          expect(font_file(other)).to exist
        end
      end
    end

    context "preferred family and no option" do
      let(:font) { "texgyrechorus" }

      it "uninstall by default family" do
        fresh_fonts_and_formulas do
          example_formula("tex_gyre_chorus.yml")
          # Copy font file AND it will be indexed
          example_font("texgyrechorus-mediumitalic.otf")

          command
          expect(font_file("texgyrechorus-mediumitalic.otf")).not_to exist
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
          expect { command }.to(raise_error do |e|
            expect(e.font).to eq "nonexistent"
          end)
        end
      end
    end

    context "with supported font but not installed" do
      let(:font) { "andale mono" }

      it "raises font missing error" do
        fresh_fonts_and_formulas do
          example_formula("andale.yml")

          expect { command }.to raise_error Fontist::Errors::MissingFontError
          expect { command }.to(raise_error do |e|
            expect(e.font).to eq "andale mono"
          end)
        end
      end
    end

    context "with supported and installed font" do
      let(:font) { "overpass" }

      it "returns its path" do
        fresh_fonts_and_formulas do
          example_font("overpass-regular.otf")

          expect(command).to all(include("overpass-regular.otf"))
        end
      end
    end

    context "with no font and nothing installed" do
      let(:font) { nil }

      it "returns system fonts" do
        stub_fonts_path_to_new_path do
          stub_system_fonts_path_to_new_path do
            example_font_to_system("AndaleMo.TTF")
            expect(command.size).to be 1
          end
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

          expect(command).to all(include("AndaleMo.TTF"))
        end
      end
    end

    context "when installed from another formula" do
      let(:font) { "arial" }

      it "shows original formula" do
        fresh_fonts_and_formulas do
          example_formula("webcore.yml")
          example_font("ariali.ttf")

          expect(Fontist.ui).to receive(:say).with(/from .*webcore formula/)
          command
        end
      end
    end

    context "preferred family and no option" do
      let(:font) { "texgyrechorus" }

      it "finds by default family" do
        fresh_fonts_and_formulas do
          example_formula("tex_gyre_chorus.yml")
          example_font("texgyrechorus-mediumitalic.otf")
          expect(command).to include(include("texgyrechorus-mediumitalic.otf"))
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
        expect { command }.to(raise_error do |e|
          expect(e.font).to eq "nonexistent"
        end)
      end
    end

    context "with supported font but not installed" do
      let(:font) { "andale mono" }

      it "returns its status as not installed" do
        fresh_fonts_and_formulas do
          example_formula_to("andale.yml", Fontist.formulas_path)
          expect(command.size).to be >= 1

          installs = unpack_statuses(command)
          expect(installs).to all(be false)
        end
      end
    end

    context "with supported and installed font" do
      let(:font) { "andale mono" }

      it "returns its status as installed" do
        fresh_fonts_and_formulas do
          example_formula_to("andale.yml", Fontist.formulas_path)
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
          # Add example formulas so Formula.all returns fonts
          fresh_fontist_home do
            FileUtils.mkdir_p(Fontist.formulas_path)
            example_formula_to("andale.yml", Fontist.formulas_path)
            example_formula_to("courier.yml", Fontist.formulas_path)
            Fontist::Index.rebuild

            expect(command.size).to be > 1
            _, _, _, installed = unpack_status(command)
            expect(installed).to be false
          end
        end
      end
    end

    context "with no font and a font installed" do
      let(:font) { nil }

      it "returns installed font with its path" do
        stub_system_fonts
        fresh_fonts_and_formulas do
          # Add multiple formulas so command.size > 1
          example_formula_to("andale.yml", Fontist.formulas_path)
          example_formula_to("courier.yml", Fontist.formulas_path)
          stub_font_file("AndaleMo.TTF")

          expect(command.size).to be > 1

          statuses = command.map do |_, fonts|
            fonts.map do |_, styles|
              styles.values
            end
          end.flatten

          expect(statuses).to include(true)
        end
      end
    end

    context "differing platforms" do
      include_context "fresh home"

      let(:font) { nil }
      before { example_formula("work_sans_macos_only.yml") }

      before do
        allow(Fontist::Utils::System).to receive(:user_os).and_return(:windows)
      end

      it "does not contain the formula" do
        formulas = command.keys.map(&:key)
        expect(formulas).to eq []
      end
    end

    context "the same platform" do
      include_context "fresh home"

      let(:font) { nil }
      before { example_formula("work_sans_macos_only.yml") }

      before do
        allow(Fontist::Utils::System).to receive(:user_os).and_return(:macos)
      end

      it "returns the formula" do
        formulas = command.keys.map(&:key)
        expect(formulas).to eq ["work_sans_macos_only"]
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
