require "spec_helper"
require "fontist/cli"

RSpec.describe Fontist::CLI do
  describe "#install" do
    before { stub_system_fonts }

    context "no formulas repo found" do
      it "proposes to download formulas repo" do
        fresh_fontist_home do
          expect(Fontist.ui).to receive(:error)
            .with("Please fetch formulas with `fontist update`.")
          status = described_class.start(["install", "lato"])
          expect(status).to be Fontist::CLI::STATUS_MAIN_REPO_NOT_FOUND
        end
      end
    end

    context "supported font name" do
      it "returns success status" do
        stub_fonts_path_to_new_path do
          status = described_class.start(["install", "overpass"])
          expect(status).to be 0
        end
      end
    end

    context "unexisting font name" do
      it "returns error status" do
        stub_fonts_path_to_new_path do
          status = described_class.start(["install", "unexisting"])
          expect(status).to be Fontist::CLI::STATUS_NON_SUPPORTED_FONT_ERROR
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
          File.write(Fontist.system_index_path, YAML.dump([{ path: "/some/path" }]))
          expect(Fontist.ui).to receive(:error)
            .with("Font index is corrupted.\n" \
                  "Item {:path=>\"/some/path\"} misses required attributes: full_name, family_name, type.\n" \
                  "You can remove the index file (#{Fontist.system_index_path}) and try again.")

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
  end

  describe "#status" do
    before { stub_system_fonts }

    context "unexisting font name" do
      it "returns error status" do
        stub_fonts_path_to_new_path do
          status = described_class.start(["status", "unexisting"])
          expect(status).to be Fontist::CLI::STATUS_NON_SUPPORTED_FONT_ERROR
        end
      end
    end

    context "supported font name but uninstalled" do
      it "returns error status" do
        stub_fonts_path_to_new_path do
          status = described_class.start(["status", "andale mono"])
          expect(status).to be Fontist::CLI::STATUS_MISSING_FONT_ERROR
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
        stub_fonts_path_to_new_path do
          example_font_to_fontist("AndaleMo.TTF")

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
          expect(status).to be Fontist::CLI::STATUS_MISSING_FONT_ERROR
        end
      end
    end

    context "collection font" do
      it "prints its formula" do
        stub_fonts_path_to_new_path do
          example_font_to_fontist("CAMBRIA.TTC")

          expect(Fontist.ui).to receive(:say).with(include("from cleartype formula"))
          status = described_class.start(["status", "cambria"])
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
          expect(status).to be Fontist::CLI::STATUS_NON_SUPPORTED_FONT_ERROR
        end
      end
    end

    context "supported font name but uninstalled" do
      it "prints `uninstalled`" do
        stub_fonts_path_to_new_path do
          expect(Fontist.ui).to receive(:error).with(include("uninstalled"))
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
      it "returns success status and prints list with no installed status", slow: true do
        stub_fonts_path_to_new_path do
          expect(Fontist.ui).to receive(:error).at_least(1000).times
          expect(Fontist.ui).to receive(:success).exactly(0).times
          status = described_class.start(["list"])
          expect(status).to be 0
        end
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
        expect(command).to be Fontist::CLI::STATUS_MANIFEST_COULD_NOT_BE_FOUND_ERROR
      end
    end

    context "empty manifest" do
      let(:content) { "" }

      it "tells manifest could not be read" do
        expect(Fontist.ui).to receive(:error)
          .with("Manifest could not be read.")
        expect(command).to be Fontist::CLI::STATUS_MANIFEST_COULD_NOT_BE_READ_ERROR
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
        stub_system_fonts
        stub_fonts_path_to_new_path do
          example_font_to_fontist("AndaleMo.TTF")

          expect(Fontist.ui).to receive(:say).with(output)
          expect(command).to be 0
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
        stub_system_fonts
        stub_fonts_path_to_new_path do
          example_font_to_fontist("courbd.ttf")

          expect(Fontist.ui).to receive(:say).with(output)
          expect(command).to be 0
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
        stub_system_fonts
        stub_fonts_path_to_new_path do
          example_font_to_fontist("AndaleMo.TTF")
          example_font_to_fontist("courbd.ttf")

          expect(Fontist.ui).to receive(:say).with(output)
          expect(command).to be 0
        end
      end
    end

    context "contains one font from system paths" do
      let(:manifest) { { "Andale Mono" => "Regular" } }

      it "returns font location" do
        stub_system_fonts_path_to_new_path do |system_dir|
          example_font_to_system("Andale Mono.ttf")

          stub_fonts_path_to_new_path do
            expect(Fontist.ui).to receive(:say).with(include(system_dir))
            expect(command).to be 0
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
        stub_system_fonts_path_to_new_path do |system_dir|
          example_font_to_system("NotoSansOriya.ttc")

          stub_fonts_path_to_new_path do
            expect(Fontist.ui).to receive(:say).with(include_yaml(result))
            expect(command).to be 0
          end
        end
      end
    end

    context "contains uninstalled font" do
      let(:manifest) { { "Andale Mono" => "Regular" } }

      it "returns error code and tells it could not find it" do
        stub_system_fonts
        stub_fonts_path_to_new_path do
          expect(Fontist.ui).to receive(:error)
            .with("'Andale Mono' 'Regular' font is missing, " \
                  "please run `fontist install 'Andale Mono'` to download the font.")
          expect(command).to be Fontist::CLI::STATUS_MISSING_FONT_ERROR
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
          expect(command).to be Fontist::CLI::STATUS_MISSING_FONT_ERROR
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
        expect(command).to be Fontist::CLI::STATUS_MANIFEST_COULD_NOT_BE_FOUND_ERROR
      end
    end

    context "non-yaml file" do
      let(:content) { "not yaml file" }

      it "tells manifest could not be read" do
        expect(Fontist.ui).to receive(:error).with("Manifest could not be read.")
        expect(command).to be Fontist::CLI::STATUS_MANIFEST_COULD_NOT_BE_READ_ERROR
      end
    end

    context "empty file" do
      let(:content) { "" }

      it "tells manifest could not be read" do
        expect(Fontist.ui).to receive(:error).with("Manifest could not be read.")
        expect(command).to be Fontist::CLI::STATUS_MANIFEST_COULD_NOT_BE_READ_ERROR
      end
    end

    context "no fonts" do
      let(:manifest) { {} }

      it "returns empty result" do
        expect_say_yaml({})
      end
    end

    context "unsupported and uninstalled font" do
      let(:manifest) { { "Unexisting Font" => "Regular" } }

      it "tells that font is unsupported" do
        expect(Fontist.ui).to receive(:error).with(/Font 'Unexisting Font' not found locally nor/)
        expect(command).to be Fontist::CLI::STATUS_NON_SUPPORTED_FONT_ERROR
      end
    end

    context "unsupported but installed in system font" do
      let(:manifest) { { "Noto Sans Oriya" => "Regular" } }
      before { example_font("NotoSansOriya.ttc") }

      it "returns its location" do
        expect_say_yaml(
          "Noto Sans Oriya" =>
          { "Regular" => { "full_name" => "Noto Sans Oriya",
                           "paths" => [include("NotoSansOriya.ttc")] } }
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
                           "paths" => [include("AndaleMo.TTF")] } }
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
                           "paths" => include(include("AndaleMo.TTF")) } }
        )
      end
    end

    context "uninstalled but supported font" do
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
                           "paths" => include(/AndaleMo\.TTF/i) } }
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
                        "paths" => [font_path("courbd.ttf")] } }
        )
      end
    end

    context "uninstalled, one supported, one unsupported" do
      let(:manifest) do
        { "Andale Mono" => "Regular",
          "Unexisting Font" => "Regular" }
      end

      before { example_formula("andale.yml") }

      it "tells that font is unsupported" do
        expect(Fontist.ui).to receive(:error).with(/Font 'Unexisting Font' not found locally nor/)
        expect(command).to be Fontist::CLI::STATUS_NON_SUPPORTED_FONT_ERROR
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
          }
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
          }
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
        expect(command).to be Fontist::CLI::STATUS_LICENSING_ERROR
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
                           "paths" => include(/AndaleMo\.TTF/i) } }
        )
      end
    end

    context "confirmed license with aliased cli option" do
      let(:options) { ["--accept-all-licenses"] }
      let(:manifest) { { "Andale Mono" => "Regular" } }

      it "calls installation with a yes option" do
        expect(Fontist::Manifest::Install).to receive(:from_file)
          .with(anything, hash_including(confirmation: "yes"))
          .and_return([])

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

  describe "#rebuild_index" do
    context "with --main-repo option" do
      it "calls corresponding method" do
        fresh_fonts_and_formulas do
          example_formula_to("lato.yml", Fontist.formulas_path)
          expect(Fontist::Index).to receive(:rebuild_for_main_repo)
            .and_call_original

          described_class.start(["rebuild-index", "--main-repo"])

          expect(Fontist.formulas_repo_path.join("index.yml")).to exist
          expect(Fontist.formulas_repo_path.join("filename_index.yml")).to exist
        end
      end
    end
  end

  def expect_say_yaml(result)
    expect(Fontist.ui).to receive(:say).with(include_yaml(result))
    expect(command).to be 0
  end
end
