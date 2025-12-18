require "spec_helper"
require "fontist/cli"

RSpec.describe Fontist::CLI do
  after(:context) do
    restore_default_settings
  end

  describe "#install" do
    before { stub_system_fonts }

    context "no formulas repo found" do
      it "proposes to download formulas repo" do
        fresh_fontist_home do
          expect(Fontist.ui).to receive(:error)
            .with("Please fetch formulas with `fontist update`.")
          status = described_class.start(["install", "texgyrechorus"])
          expect(status).to eq Fontist::CLI::STATUS_MAIN_REPO_NOT_FOUND
        end
      end
    end

    context "supported font name" do
      it "returns success status" do
        stub_fonts_path_to_new_path do
          status = described_class.start(["install", "texgyrechorus"])
          expect(status).to eq 0
        end
      end
    end

    context "unexisting font name" do
      it "returns error status" do
        stub_fonts_path_to_new_path do
          status = described_class.start(["install", "unexisting"])
          expect(status).to eq Fontist::CLI::STATUS_NON_SUPPORTED_FONT_ERROR
        end
      end

      it "tells that could not find font" do
        no_fonts do
          expect(Fontist.ui).to receive(:error)
            .with("Font 'unexisting' not found locally nor available in the " \
                  "Fontist formula repository.\n" \
                  "Perhaps it is available at the latest Fontist formula " \
                  "repository.\n" \
                  "You can update the formula repository using the command " \
                  "`fontist update` and try again.")

          described_class.start(["install", "unexisting"])
        end
      end
    end

    context "font index is corrupted" do
      it "tells the index is corrupted and proposes to remove it" do
        stub_system_index_path do
          File.write(Fontist.system_index_path,
                     YAML.dump([{ path: "/some/path" }]))
          expect(Fontist.ui).to receive(:error) do |msg|
            expect(msg).to start_with("Font index is corrupted.")
            expect(msg).to include("misses required attributes:")
            expect(msg).to end_with("You can remove the index file (#{Fontist.system_index_path}) and try again.")
            true
          end
          described_class.start(["install", "some"])
        end
      end
    end

    ["--confirm-license", "--accept-all-licenses"].each do |accept_flag|
      context "accept flag '#{accept_flag}' passed" do
        it "calls installation with a yes option" do
          no_fonts do
            expect(Fontist::Font).to receive(:install)
              .with(anything, hash_including(confirmation: "yes"))
              .and_return([])

            described_class.start(["install", accept_flag, "segoe ui"])
          end
        end
      end
    end

    context "hide-licenses flag passed" do
      it "passes hide-licenses option" do
        no_fonts do
          expect(Fontist::Font).to receive(:install)
            .with(anything, hash_including(hide_licenses: true))
            .and_return([])

          described_class.start(["install", "--hide_licenses", "segoe ui"])
        end
      end
    end

    context "manual font" do
      include_context "fresh home"
      before { example_formula("manual.yml") }

      it "prints instructions how to install it" do
        expect(Fontist.ui).to receive(:error).with(<<~MSG.chomp)
          'al firat' font is missing.

          To download and enable any of these fonts:

          1. Open Font Book, which is in your Applications folder.
          2. Select All Fonts in the sidebar, or use the Search field to find the font that you want to download. Fonts that are not already downloaded appear dimmed in the list of fonts.
          3. Select the dimmed font and choose Edit > Download, or Control-click it and choose Download from the pop-up menu.
        MSG

        status = described_class.start(["install", "al firat"])
        expect(status).to eq Fontist::CLI::STATUS_MANUAL_FONT_ERROR
      end
    end

    context "with version option" do
      it "passes version number" do
        expect(Fontist::Font).to receive(:install)
          .with(anything, hash_including(version: "3.06"))
          .and_return([])

        described_class.start(["install", "--version", "3.06", "segoe ui"])
      end
    end

    context "with smallest option" do
      it "passes smallest option" do
        expect(Fontist::Font).to receive(:install)
          .with(anything, hash_including(smallest: true))
          .and_return([])

        described_class.start(["install", "--smallest", "segoe ui"])
      end
    end

    context "with newest option" do
      it "passes newest option" do
        expect(Fontist::Font).to receive(:install)
          .with(anything, hash_including(newest: true))
          .and_return([])

        described_class.start(["install", "--newest", "segoe ui"])
      end
    end

    context "with size limit option" do
      it "passes size limit number" do
        expect(Fontist::Font).to receive(:install)
          .with(anything, hash_including(size_limit: 1000))
          .and_return([])

        described_class.start(["install", "--size-limit", "1000", "segoe ui"])
      end
    end

    context "with multiple fonts" do
      it "installs all fonts successfully" do
        stub_fonts_path_to_new_path do
          expect(Fontist.ui).to receive(:success)
            .with("Successfully installed 2 font(s): texgyrechorus, andale mono")

          status = described_class.start(["install", "--accept-all-licenses", "texgyrechorus", "andale mono"])
          expect(status).to eq 0
        end
      end

      it "continues on failure and reports all results" do
        stub_fonts_path_to_new_path do
          expect(Fontist.ui).to receive(:success)
            .with("Successfully installed 1 font(s): texgyrechorus")
          expect(Fontist.ui).to receive(:error)
            .with("Failed to install 1 font(s):")
          expect(Fontist.ui).to receive(:error)
            .with(/unexisting/)

          status = described_class.start(["install", "--accept-all-licenses", "texgyrechorus", "unexisting"])
          expect(status).to eq Fontist::CLI::STATUS_NON_SUPPORTED_FONT_ERROR
        end
      end

      it "returns error when no fonts specified" do
        expect(Fontist.ui).to receive(:error)
          .with("Please specify at least one font to install.")

        status = described_class.start(["install"])
        expect(status).to eq Fontist::CLI::STATUS_UNKNOWN_ERROR
      end

      it "passes options to each font installation" do
        no_fonts do
          expect(Fontist::Font).to receive(:install)
            .with("font1", hash_including(confirmation: "yes"))
            .and_return([])
          expect(Fontist::Font).to receive(:install)
            .with("font2", hash_including(confirmation: "yes"))
            .and_return([])

          described_class.start(["install", "--accept-all-licenses", "font1", "font2"])
        end
      end
    end

    context "formula requires higher min fontist" do
      include_context "fresh home"

      before { example_formula("tex_gyre_chorus_min_fontist_and_font.yml") }

      it "returns fontist-version error" do
        status = described_class.start(["install", "texgyrechorus"])
        expect(status).to eq Fontist::CLI::STATUS_FONTIST_VERSION_ERROR
      end
    end

    context "with formula option" do
      include_context "fresh home"

      subject { command }

      let(:command) { described_class.start(["install", "--formula", formula]) }

      let(:not_found_message) do
        "Formula '#{formula}' not found locally nor available in the " \
          "Fontist formula repository.\n" \
          "Perhaps it is available at the latest Fontist formula " \
          "repository.\n" \
          "You can update the formula repository using the command " \
          "`fontist update` and try again."
      end

      context "missing formula" do
        let(:formula) { "missing" }
        it "returns error status and prints that it's missing" do
          expect(Fontist.ui).to receive(:error).with(not_found_message)
          expect(command).to eq Fontist::CLI::STATUS_FORMULA_NOT_FOUND
        end
      end

      context "manual formula" do
        let(:formula) { "manual" }
        before { example_formula("manual.yml") }

        it "returns error status and prints that it's missing" do
          expect(Fontist.ui).to receive(:error).with(not_found_message)
          expect(command).to eq Fontist::CLI::STATUS_FORMULA_NOT_FOUND
        end
      end

      context "formula from root dir" do
        let(:formula) { "andale" }
        before do
          allow(Fontist.ui).to receive(:ask).and_return("yes").once
          example_formula("andale.yml")
        end

        it "returns success status and prints fonts paths" do
          expect(Fontist.ui).to receive(:say).with(include("AndaleMo.TTF"))
          expect(command).to be 0
        end
      end

      context "formula from subdir" do
        let(:formula) { "subdir/andale" }

        before do
          allow(Fontist.ui).to receive(:ask).and_return("yes").once

          subdir_path = Fontist.formulas_path.join("subdir")
          FileUtils.mkdir_p(subdir_path)
          example_formula_to("andale.yml", subdir_path)
        end

        it "returns success status and prints fonts paths" do
          expect(Fontist.ui).to receive(:say).with(include("AndaleMo.TTF"))
          expect(command).to be 0
        end
      end

      context "with misspelled formula name" do
        let(:formula) { "TX Gyre Chorus" }

        before { example_formula("tex_gyre_chorus.yml") }

        it "suggests to install 'tex_gyre_chorus'" do
          allow(Fontist.ui).to receive(:ask).and_return("")
          expect(Fontist.ui).to receive(:say).with(/tex gyre chorus/i)
          subject
        end

        it "asks to choose" do
          expect(Fontist.ui).to receive(:ask).and_return("")
          subject
        end

        context "suggested formula is chosen" do
          before { allow(Fontist.ui).to receive(:ask).and_return("0") }

          it "installs the formula" do
            expect(Fontist.ui).to receive(:say)
              .with(/texgyrechorus-mediumitalic\.otf/i)
            subject
          end
        end

        context "with empty input" do
          before { expect(Fontist.ui).to receive(:ask).and_return("") }

          it "skips installation and prints formula not found" do
            is_expected.to eq Fontist::CLI::STATUS_FORMULA_NOT_FOUND
          end
        end

        context "with no-interactive flag" do
          let(:command) { described_class.start(["install", *opts]) }
          let(:opts) { ["--no-interactive", "--formula", formula] }

          it "does not ask for input and returns formula-not-found" do
            expect(Fontist.ui).not_to receive(:ask)

            is_expected.to eq Fontist::CLI::STATUS_FORMULA_NOT_FOUND
          end
        end
      end
    end

    context "with update-fontconfig option" do
      include_context "fresh home"
      before { example_formula("tex_gyre_chorus.yml") }

      let(:status) do
        described_class.start(["install",
                               "--update-fontconfig",
                               "texgyrechorus"])
      end

      it "passes it" do
        expect(Fontist::Font).to receive(:install)
          .with(anything, hash_including(update_fontconfig: true))
          .and_return([])

        expect(status).to be 0
      end

      context "no fontconfig installed" do
        it "returns fontconfig-not-found error code" do
          allow(Fontist::Fontconfig).to receive(:update)
            .and_raise(Fontist::Errors::FontconfigNotFoundError)

          expect(status).to eq Fontist::CLI::STATUS_FONTCONFIG_NOT_FOUND
        end
      end
    end

    context "--no-cache used" do
      include_context "fresh home"

      before { example_formula("tex_gyre_chorus.yml") }

      it "calls the download library" do
        expect(Down).to receive(:download).and_call_original

        described_class.start(["install", "-c", "texgyrechorus"])
      end
    end
  end

  describe "#status" do
    before { stub_system_fonts }

    context "unexisting font name" do
      it "returns error status" do
        stub_fonts_path_to_new_path do
          status = described_class.start(["status", "unexisting"])
          expect(status).to eq Fontist::CLI::STATUS_NON_SUPPORTED_FONT_ERROR
        end
      end
    end

    context "supported font name but not installed" do
      it "returns error status" do
        fresh_fonts_and_formulas do
          example_formula("andale.yml")

          status = described_class.start(["status", "andale mono"])
          expect(status).to eq Fontist::CLI::STATUS_MISSING_FONT_ERROR
        end
      end
    end

    context "supported and installed font" do
      it "returns success status and prints path" do
        stub_fonts_path_to_new_path do
          example_font_to_fontist("AndaleMo.TTF")

          expect(Fontist.ui).to receive(:say).with(include("AndaleMo.TTF"))
          status = described_class.start(["status", "andale mono"])
          expect(status).to be 0
        end
      end

      it "shows formula and font names" do
        fresh_fonts_and_formulas do
          example_formula("andale.yml")
          example_font("AndaleMo.TTF")

          expect(Fontist.ui).to receive(:say).with(/^- .*AndaleMo.TTF \(from andale formula\)$/)
          described_class.start(["status", "andale mono"])
        end
      end
    end

    context "no font specified" do
      it "returns success status and tells there is no installed font" do
        stub_fonts_path_to_new_path do
          expect(Fontist.ui).to receive(:error).with("No font is installed.")
          status = described_class.start(["status"])
          expect(status).to eq Fontist::CLI::STATUS_MISSING_FONT_ERROR
        end
      end
    end

    context "collection font" do
      it "prints its formula" do
        fresh_fonts_and_formulas do
          example_formula("andale.yml")
          example_font("AndaleMo.TTF")

          expect(Fontist.ui).to receive(:say)
            .with(include("from andale formula"))
          status = described_class.start(["status", "andale mono"])
          expect(status).to be 0
        end
      end
    end
  end

  describe "#list" do
    before { stub_system_fonts }

    context "unexisting font name" do
      it "returns error status" do
        stub_fonts_path_to_new_path do
          status = described_class.start(["list", "unexisting"])
          expect(status).to eq Fontist::CLI::STATUS_NON_SUPPORTED_FONT_ERROR
        end
      end
    end

    context "supported font name but not installed" do
      it "prints `not installed`" do
        stub_fonts_path_to_new_path do
          expect(Fontist.ui).to receive(:error).with(include("not installed"))
          status = described_class.start(["list", "andale mono"])
          expect(status).to be 0
        end
      end
    end

    context "supported and installed font" do
      it "prints `installed`" do
        stub_fonts_path_to_new_path do
          example_font_to_fontist("AndaleMo.TTF")

          expect(Fontist.ui).to receive(:success).with(include("(installed)"))
          status = described_class.start(["list", "andale mono"])
          expect(status).to be 0
        end
      end

      it "shows formula and font names" do
        stub_fonts_path_to_new_path do
          example_font_to_fontist("AndaleMo.TTF")

          expect(Fontist.ui).to receive(:say)
            .with("andale")
          expect(Fontist.ui).to receive(:say)
            .with(" Andale Mono")
          expect(Fontist.ui).to receive(:success)
            .with(/^  Regular \(installed\)/)
          described_class.start(["list", "andale mono"])
        end
      end
    end

    context "no font specified" do
      it "returns success status and prints list with no installed status",
         slow: true do
        stub_fonts_path_to_new_path do
          expect(Fontist.ui).to receive(:error).at_least(1).times
          expect(Fontist.ui).to receive(:success).exactly(0).times
          status = described_class.start(["list"])
          expect(status).to be 0
        end
      end
    end

    context "manual font" do
      include_context "fresh home"
      before { example_formula("manual.yml") }

      it "marks the font as manual" do
        expect(Fontist.ui).to receive(:error).with(include("manual"))
        status = described_class.start(["list", "al firat"])
        expect(status).to be 0
      end
    end
  end

  describe "#manifest_locations" do
    let(:command) { described_class.start(["manifest-locations", path]) }
    let(:path) { Tempfile.new.tap { |f| f.write(content) && f.close }.path }
    let(:content) { YAML.dump(manifest) }
    let(:output) { include_yaml(result) }

    context "manifest not found" do
      let(:path) { Fontist.root_path.join("unexisting") }

      it "tells manifest could not be found" do
        expect(Fontist.ui).to receive(:error)
          .with("Manifest could not be found.")
        expect(command).to eq Fontist::CLI::STATUS_MANIFEST_COULD_NOT_BE_FOUND_ERROR
      end
    end

    context "empty manifest" do
      let(:content) { "" }

      it "tells manifest could not be read" do
        expect(Fontist.ui).to receive(:error)
          .with("Manifest could not be read.")
        expect(command).to eq Fontist::CLI::STATUS_MANIFEST_COULD_NOT_BE_READ_ERROR
      end
    end

    context "contains no font" do
      let(:manifest) { {} }
      let(:result) { {} }

      it "returns empty result" do
        expect(Fontist.ui).to receive(:say).with(output)
        expect(command).to be 0
      end
    end

    context "contains one font with regular style" do
      let(:manifest) { { "Andale Mono" => "Regular" } }
      let(:result) do
        { "Andale Mono" =>
          { "Regular" => { "full_name" => "Andale Mono",
                           "paths" => [font_path("AndaleMo.TTF")] } } }
      end

      it "returns font location" do
        stub_system_index_path do
          stub_system_fonts
          stub_fonts_path_to_new_path do
            example_font_to_fontist("AndaleMo.TTF")

            expect(Fontist.ui).to receive(:say).with(output)
            expect(command).to be 0
          end
        end
      end
    end

    context "contains one font with bold style" do
      let(:manifest) { { "Courier New" => "Bold" } }
      let(:result) do
        { "Courier New" =>
          { "Bold" => { "full_name" => "Courier New Bold",
                        "paths" => [font_path("courbd.ttf")] } } }
      end

      it "returns font location" do
        stub_system_index_path do
          stub_system_fonts
          stub_fonts_path_to_new_path do
            example_font_to_fontist("courbd.ttf")

            expect(Fontist.ui).to receive(:say).with(output)
            expect(command).to be 0
          end
        end
      end
    end

    context "contains two fonts" do
      let(:manifest) do
        { "Andale Mono" => "Regular",
          "Courier New" => "Bold" }
      end

      let(:result) do
        { "Andale Mono" =>
          { "Regular" => { "full_name" => "Andale Mono",
                           "paths" => [font_path("AndaleMo.TTF")] } },
          "Courier New" =>
          { "Bold" => { "full_name" => "Courier New Bold",
                        "paths" => [font_path("courbd.ttf")] } } }
      end

      it "returns font location" do
        stub_system_index_path do
          stub_system_fonts
          stub_fonts_path_to_new_path do
            example_font_to_fontist("AndaleMo.TTF")
            example_font_to_fontist("courbd.ttf")

            expect(Fontist.ui).to receive(:say).with(output)
            expect(command).to be 0
          end
        end
      end
    end

    context "contains one font from system paths" do
      let(:manifest) { { "Andale Mono" => "Regular" } }

      it "returns font location" do
        stub_system_index_path do
          stub_system_fonts_path_to_new_path do |system_dir|
            example_font_to_system("Andale Mono.ttf")

            stub_fonts_path_to_new_path do
              expect(Fontist.ui).to receive(:say).with(include(system_dir))
              expect(command).to be 0
            end
          end
        end
      end
    end

    context "contains font with space from system paths" do
      let(:manifest) { { "Noto Sans Oriya" => "Regular" } }
      let(:result) do
        { "Noto Sans Oriya" =>
          { "Regular" => { "full_name" => "Noto Sans Oriya",
                           "paths" => [include("NotoSansOriya.ttc")] } } }
      end

      it "returns no-space location" do
        stub_system_index_path do
          stub_system_fonts_path_to_new_path do |_system_dir|
            example_font_to_system("NotoSansOriya.ttc")

            stub_fonts_path_to_new_path do
              expect(Fontist.ui).to receive(:say).with(include_yaml(result))
              expect(command).to be 0
            end
          end
        end
      end
    end

    context "contains not installed font" do
      let(:manifest) { { "Andale Mono" => "Regular" } }

      it "returns error code and tells it could not find it" do
        stub_system_index_path do
          stub_system_fonts
          stub_fonts_path_to_new_path do
            expect(Fontist.ui).to receive(:error)
              .with("'Andale Mono' 'Regular' font is missing, " \
                    "please run `fontist install 'Andale Mono'` to download the font.")
            expect(command).to eq Fontist::CLI::STATUS_MISSING_FONT_ERROR
          end
        end
      end
    end

    context "contains unsupported font" do
      let(:manifest) { { "Unsupported Font" => "Regular" } }

      it "returns error code and tells it could not find it" do
        stub_system_fonts
        stub_fonts_path_to_new_path do
          expect(Fontist.ui).to receive(:error)
            .with("'Unsupported Font' 'Regular' font is missing, " \
                  "please run `fontist install 'Unsupported Font'` to download the font.")
          expect(command).to eq Fontist::CLI::STATUS_MISSING_FONT_ERROR
        end
      end
    end
  end

  describe "#manifest_install" do
    include_context "fresh home"

    let(:command) do
      described_class.start(["manifest-install", *options, path])
    end

    let(:path) { Tempfile.new.tap { |f| f.write(content) && f.close }.path }
    let(:content) { YAML.dump(manifest) }
    let(:options) { [] }

    before { stub_license_agreement_prompt_with("yes") }

    context "no file at path" do
      let(:path) { Fontist.root_path.join("unexisting.yml") }

      it "tells manifest not found" do
        expect(Fontist.ui).to receive(:error).with("Manifest could not be found.")
        expect(command).to eq Fontist::CLI::STATUS_MANIFEST_COULD_NOT_BE_FOUND_ERROR
      end
    end

    context "non-yaml file" do
      let(:content) { "not yaml file" }

      it "tells manifest could not be read" do
        expect(Fontist.ui).to receive(:error).with("Manifest could not be read.")
        expect(command).to eq Fontist::CLI::STATUS_MANIFEST_COULD_NOT_BE_READ_ERROR
      end
    end

    context "empty file" do
      let(:content) { "" }

      it "tells manifest could not be read" do
        expect(Fontist.ui).to receive(:error).with("Manifest could not be read.")
        expect(command).to eq Fontist::CLI::STATUS_MANIFEST_COULD_NOT_BE_READ_ERROR
      end
    end

    context "no fonts" do
      let(:manifest) { {} }

      it "returns empty result" do
        expect_say_yaml({})
      end
    end

    context "unsupported and not installed font" do
      let(:manifest) { { "Unexisting Font" => "Regular" } }

      it "tells that font is unsupported" do
        expect(Fontist.ui).to receive(:error).with(/Font 'Unexisting Font' not found locally nor/)
        expect(command).to eq Fontist::CLI::STATUS_NON_SUPPORTED_FONT_ERROR
      end
    end

    context "unsupported but installed in system font" do
      let(:manifest) { { "Noto Sans Oriya" => "Regular" } }
      before { example_font("NotoSansOriya.ttc") }

      it "returns its location" do
        expect_say_yaml(
          "Noto Sans Oriya" =>
          { "Regular" => { "full_name" => "Noto Sans Oriya",
                           "paths" => [include("NotoSansOriya.ttc")] } },
        )
      end
    end

    context "installed font" do
      let(:manifest) { { "Andale Mono" => "Regular" } }
      before { example_formula("andale.yml") }
      before { example_font("AndaleMo.TTF") }

      it "returns its location" do
        expect_say_yaml(
          "Andale Mono" =>
          { "Regular" => { "full_name" => "Andale Mono",
                           "paths" => [include("AndaleMo.TTF")] } },
        )
      end
    end

    context "supported and installed by system font" do
      include_context "system fonts"

      let(:manifest) { { "Andale Mono" => "Regular" } }
      before { example_formula("andale.yml") }
      before { example_font_to_system("AndaleMo.TTF") }

      it "returns its location" do
        expect_say_yaml(
          "Andale Mono" =>
          { "Regular" => { "full_name" => "Andale Mono",
                           "paths" => include(include("AndaleMo.TTF")) } },
        )
      end
    end

    context "not installed but supported font" do
      let(:manifest) { { "Andale Mono" => "Regular" } }
      before { example_formula("andale.yml") }

      it "installs font file" do
        expect { command }
          .to change { font_file("AndaleMo.TTF").exist? }.from(false).to(true)
      end

      it "returns its location" do
        expect_say_yaml(
          "Andale Mono" =>
          { "Regular" => { "full_name" => "Andale Mono",
                           "paths" => include(/AndaleMo\.TTF/i) } },
        )
      end
    end

    context "two supported fonts" do
      let(:manifest) do
        { "Andale Mono" => "Regular",
          "Courier New" => "Bold" }
      end

      before { example_formula("andale.yml") }
      before { example_formula("courier.yml") }

      it "installs both and returns their locations" do
        expect_say_yaml(
          "Andale Mono" =>
          { "Regular" => { "full_name" => "Andale Mono",
                           "paths" => include(/AndaleMo\.TTF/i) } },
          "Courier New" =>
          { "Bold" => { "full_name" => "Courier New Bold",
                        "paths" => [font_path("courbd.ttf")] } },
        )
      end
    end

    context "not installed, one supported, one unsupported" do
      let(:manifest) do
        { "Andale Mono" => "Regular",
          "Unexisting Font" => "Regular" }
      end

      before { example_formula("andale.yml") }

      it "tells that font is unsupported" do
        expect(Fontist.ui).to receive(:error).with(/Font 'Unexisting Font' not found locally nor/)
        expect(command).to eq Fontist::CLI::STATUS_NON_SUPPORTED_FONT_ERROR
      end
    end

    context "with no style specified" do
      let(:manifest) do
        { "Georgia" => nil }
      end

      before { example_formula("georgia.yml") }

      it "installs supported and returns its location and no location" do
        expect_say_yaml(
          "Georgia" => {
            "Regular" => { "full_name" => "Georgia",
                           "paths" => include(/Georgia\.TTF/i) },
            "Bold" => { "full_name" => "Georgia Bold",
                        "paths" => include(/Georgiab\.TTF/i) },
            "Italic" => { "full_name" => "Georgia Italic",
                          "paths" => include(/Georgiai\.TTF/i) },
            "Bold Italic" => { "full_name" => "Georgia Bold Italic",
                               "paths" => include(/Georgiaz\.TTF/i) },
          },
        )
      end
    end

    context "with no style by font name from formulas" do
      let(:manifest) do
        { "Courier New" => nil }
      end

      before { example_formula("courier.yml") }

      it "installs both and returns their locations" do
        expect_say_yaml(
          "Courier New" => {
            "Regular" => { "full_name" => "Courier New",
                           "paths" => [font_path("cour.ttf")] },
            "Bold" => { "full_name" => "Courier New Bold",
                        "paths" => [font_path("courbd.ttf")] },
            "Italic" => { "full_name" => "Courier New Italic",
                          "paths" => [font_path("couri.ttf")] },
            "Bold Italic" => { "full_name" => "Courier New Bold Italic",
                               "paths" => [font_path("courbi.ttf")] },
          },
        )
      end
    end

    context "declined license agreement" do
      let(:manifest) { { "Andale Mono" => "Regular" } }
      before { example_formula("andale.yml") }
      before { stub_license_agreement_prompt_with("no") }

      it "does not install font file" do
        command
        expect(font_file("AndaleMo.TTF")).not_to exist
      end

      it "tells that license should be confirmed in order for font to be installed" do
        expect(Fontist.ui).to receive(:error).with("Fontist will not download these fonts unless you accept the terms.")
        expect(command).to eq Fontist::CLI::STATUS_LICENSING_ERROR
      end
    end

    context "confirmed license in cli option" do
      let(:options) { ["--confirm-license"] }
      let(:manifest) { { "Andale Mono" => "Regular" } }
      before { example_formula("andale.yml") }

      it "installs font file" do
        expect { command }
          .to change { font_file("AndaleMo.TTF").exist? }.from(false).to(true)
      end

      it "returns its location" do
        expect_say_yaml(
          "Andale Mono" =>
          { "Regular" => { "full_name" => "Andale Mono",
                           "paths" => include(/AndaleMo\.TTF/i) } },
        )
      end
    end

    context "confirmed license with aliased cli option" do
      let(:options) { ["--accept-all-licenses"] }
      let(:manifest) { { "Andale Mono" => "Regular" } }

      it "calls installation with a yes option" do
        # Create a real manifest object and spy on it
        manifest_instance = Fontist::Manifest.new
        allow(Fontist::Manifest).to receive(:from_file)
          .with(anything)
          .and_return(manifest_instance)
        allow(manifest_instance).to receive(:to_hash).and_return({})
        allow(manifest_instance).to receive(:install)
          .with(hash_including(confirmation: "yes"))
          .and_return(manifest_instance)

        command
      end
    end

    context "with accept flag, no hide-licenses flag" do
      let(:options) { ["--accept-all-licenses"] }
      let(:manifest) { { "Andale Mono" => "Regular" } }
      before { example_formula("andale.yml") }

      it "still shows license text" do
        expect(Fontist.ui).to receive(:say).with(/^FONT LICENSE ACCEPTANCE/)

        command
      end
    end

    context "with accept flag and hide-licenses flag" do
      let(:options) { ["--accept-all-licenses", "--hide-licenses"] }
      let(:manifest) { { "Andale Mono" => "Regular" } }

      it "hides license text" do
        expect(Fontist.ui).not_to receive(:say).with(/FONT LICENSE ACCEPTANCE/)

        command
      end
    end
  end

  describe "#help" do
    it "should return exit code 0 on general help command" do
      execute_with_no_output("ruby exe/fontist help")

      expect($?.exitstatus).to eq(0)
    end

    it "should return exit code 0 on --help" do
      execute_with_no_output("ruby exe/fontist --help")

      expect($?.exitstatus).to eq(0)
    end

    it "should return exit code 0 on specific help command" do
      execute_with_no_output("ruby exe/fontist help install")

      expect($?.exitstatus).to eq(0)
    end

    it "should return non 0 exit code for missing command" do
      execute_with_no_output("ruby exe/fontist help_missing")

      expect($?.exitstatus).not_to eq(0)
    end

    def execute_with_no_output(cmd)
      Fontist::Helpers.silence_stream($stderr) do
        Fontist::Helpers.silence_stream($stdout) do
          system(cmd)
        end
      end
    end
  end

  describe "#version" do
    it "returns exit code 0" do
      status = described_class.start(["version"])
      expect(status).to eq(0)
    end

    it "displays version number" do
      expect(Fontist.ui).to receive(:say).with("fontist: #{Fontist::VERSION}")
      expect(Fontist.ui).to receive(:say).with(/formulas:/).at_most(4).times
      described_class.start(["version"])
    end

    it "supports --version flag" do
      expect(Fontist.ui).to receive(:say).with("fontist: #{Fontist::VERSION}")
      expect(Fontist.ui).to receive(:say).with(/formulas:|branch:|commit:|updated:/).at_most(4).times
      described_class.start(["--version"])
    end
  end

  def expect_say_yaml(result)
    expect(Fontist.ui).to receive(:say).with(include_yaml(result))
    expect(command).to be 0
  end
end
