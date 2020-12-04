require "spec_helper"
require "fontist/cli"

RSpec.describe Fontist::CLI do
  describe "#install" do
    before { stub_system_fonts }

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
          expect(status).to be 1
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
  end

  describe "#status" do
    before { stub_system_fonts }

    context "unexisting font name" do
      it "returns error status" do
        stub_fonts_path_to_new_path do
          status = described_class.start(["status", "unexisting"])
          expect(status).to be 1
        end
      end
    end

    context "supported font name but uninstalled" do
      it "returns error status" do
        stub_fonts_path_to_new_path do
          status = described_class.start(["status", "andale"])
          expect(status).to be 1
        end
      end
    end

    context "supported and installed font" do
      it "returns success status and prints path" do
        stub_fonts_path_to_new_path do
          stub_font_file("AndaleMo.TTF")

          expect(Fontist.ui).to receive(:success).with(include("AndaleMo.TTF"))
          status = described_class.start(["status", "andale"])
          expect(status).to be 0
        end
      end

      it "shows formula and font names" do
        stub_fonts_path_to_new_path do
          stub_font_file("AndaleMo.TTF")

          expect(Fontist.ui).to receive(:success)
            .with("Fontist::Formulas::AndaleFont")
          expect(Fontist.ui).to receive(:success)
            .with(" Andale Mono")
          expect(Fontist.ui).to receive(:success)
            .with(/^  Regular \(.*AndaleMo.TTF\)/)
          described_class.start(["status", "andale"])
        end
      end
    end

    context "no font specified" do
      it "returns success status and tells there is no installed font" do
        stub_fonts_path_to_new_path do
          expect(Fontist.ui).to receive(:error).with("No font is installed.")
          status = described_class.start(["status"])
          expect(status).to be 1
        end
      end
    end

    context "collection font" do
      it "returns collection name" do
        stub_fonts_path_to_new_path do
          stub_font_file("SourceHanSans-ExtraLight.ttc")

          expect(Fontist.ui).to receive(:success)
            .with(include("ExtraLight"))
          status = described_class.start(["status", "source han sans"])
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
          expect(status).to be 1
        end
      end
    end

    context "supported font name but uninstalled" do
      it "prints `uninstalled`" do
        stub_fonts_path_to_new_path do
          expect(Fontist.ui).to receive(:error).with(include("uninstalled"))
          status = described_class.start(["list", "andale"])
          expect(status).to be 0
        end
      end
    end

    context "supported and installed font" do
      it "prints `installed`" do
        stub_fonts_path_to_new_path do
          stub_font_file("AndaleMo.TTF")

          expect(Fontist.ui).to receive(:success).with(include("(installed)"))
          status = described_class.start(["list", "andale"])
          expect(status).to be 0
        end
      end

      it "shows formula and font names" do
        stub_fonts_path_to_new_path do
          stub_font_file("AndaleMo.TTF")

          expect(Fontist.ui).to receive(:say)
            .with("Fontist::Formulas::AndaleFont")
          expect(Fontist.ui).to receive(:say)
            .with(" Andale Mono")
          expect(Fontist.ui).to receive(:success)
            .with(/^  Regular \(installed\)/)
          described_class.start(["list", "andale"])
        end
      end
    end

    context "no font specified" do
      it "returns success status and prints list with no installed status" do
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
        expect(command).to be 1
      end
    end

    context "empty manifest" do
      let(:content) { "" }

      it "tells manifest could not be read" do
        expect(Fontist.ui).to receive(:error)
          .with("Manifest could not be read.")
        expect(command).to be 1
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
      let(:manifest) { { "Courier" => "Bold" } }
      let(:result) do
        { "Courier" => { "Bold" => { "full_name" => "Courier New Bold",
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
          "Courier" => "Bold" }
      end

      let(:result) do
        { "Andale Mono" =>
          { "Regular" => { "full_name" => "Andale Mono",
                           "paths" => [font_path("AndaleMo.TTF")] } },
          "Courier" =>
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
      let(:result) do
        { "Andale Mono" =>
          { "Regular" => { "full_name" => nil, "paths" => [] } } }
      end

      it "returns no location" do
        stub_system_fonts
        stub_fonts_path_to_new_path do
          expect(Fontist.ui).to receive(:say).with(output)
          expect(command).to be 0
        end
      end
    end

    context "contains unsupported font" do
      let(:manifest) { { "Unsupported Font" => "Regular" } }
      let(:result) do
        { "Unsupported Font" =>
          { "Regular" => { "full_name" => nil, "paths" => [] } } }
      end

      it "returns no location" do
        stub_system_fonts
        stub_fonts_path_to_new_path do
          expect(Fontist.ui).to receive(:say).with(output)
          expect(command).to be 0
        end
      end
    end
  end

  describe "#manifest_install" do
    let(:command) do
      described_class.start(["manifest-install", *options, path])
    end

    let(:path) { Tempfile.new.tap { |f| f.write(content) && f.close }.path }
    let(:content) { YAML.dump(manifest) }
    let(:options) { [] }

    before do
      stub_license_agreement_prompt_with("yes")
      no_fonts
    end

    after do
      cleanup_fonts
    end

    context "no file at path" do
      let(:path) { Fontist.root_path.join("unexisting.yml") }

      it "tells manifest not found" do
        expect_error("Manifest could not be found.")
      end
    end

    context "non-yaml file" do
      let(:content) { "not yaml file" }

      it "tells manifest could not be read" do
        expect_error("Manifest could not be read.")
      end
    end

    context "empty file" do
      let(:content) { "" }

      it "tells manifest could not be read" do
        expect_error("Manifest could not be read.")
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

      it "returns no location" do
        expect_say_yaml(
          "Unexisting Font" =>
          { "Regular" => { "full_name" => nil, "paths" => [] } }
        )
      end
    end

    context "unsupported but installed in system font" do
      let(:manifest) { { "Noto Sans Oriya" => "Regular" } }
      before { example_font_to_system("NotoSansOriya.ttc") }

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
      before { example_font_to_fontist("AndaleMo.TTF") }

      it "returns its location" do
        expect_say_yaml(
          "Andale Mono" =>
          { "Regular" => { "full_name" => "Andale Mono",
                           "paths" => [include("AndaleMo.TTF")] } }
        )
      end
    end

    context "supported and installed by system font" do
      let(:manifest) { { "Andale Mono" => "Regular" } }
      before { example_font_to_system("AndaleMo.TTF") }

      it "returns its location" do
        expect_say_yaml(
          "Andale Mono" =>
          { "Regular" => { "full_name" => "Andale Mono",
                           "paths" => [include("AndaleMo.TTF")] } }
        )
      end
    end

    context "uninstalled but supported font" do
      let(:manifest) { { "Andale Mono" => "Regular" } }

      it "installs font file" do
        expect { command }
          .to change { font_file("AndaleMo.TTF").exist? }.from(false).to(true)
      end

      it "returns its location" do
        expect_say_yaml(
          "Andale Mono" =>
          { "Regular" => { "full_name" => "Andale Mono",
                           "paths" => [font_path("AndaleMo.TTF")] } }
        )
      end
    end

    context "two supported fonts" do
      let(:manifest) do
        { "Andale Mono" => "Regular",
          "Courier" => "Bold" }
      end

      it "installs both and returns their locations" do
        expect_say_yaml(
          "Andale Mono" =>
          { "Regular" => { "full_name" => "Andale Mono",
                           "paths" => [font_path("AndaleMo.TTF")] } },
          "Courier" =>
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

      it "installs supported and returns its location and no location" do
        expect_say_yaml(
          "Andale Mono" =>
          { "Regular" => { "full_name" => "Andale Mono",
                           "paths" => [font_path("AndaleMo.TTF")] } },
          "Unexisting Font" =>
          { "Regular" => { "full_name" => nil,
                           "paths" => [] } }
        )
      end
    end

    context "with no style specified" do
      let(:manifest) do
        { "Georgia" => nil }
      end

      it "installs supported and returns its location and no location" do
        expect_say_yaml(
          "Georgia" =>
          { nil => { "full_name" => include("Georgia"),
                     "paths" => include(font_path("Georgia.TTF"),
                                        font_path("Georgiab.TTF"),
                                        font_path("Georgiai.TTF"),
                                        font_path("Georgiaz.TTF")) } }
        )
      end
    end

    context "declined license agreement" do
      before { stub_license_agreement_prompt_with("no") }

      let(:manifest) { { "Andale Mono" => "Regular" } }

      it "does not install font file" do
        command
        expect(font_file("AndaleMo.TTF")).not_to exist
      end

      it "returns no location" do
        expect_say_yaml("Andale Mono" =>
                        { "Regular" => { "full_name" => nil,
                                         "paths" => [] } })
      end
    end

    context "confirmed license in cli option" do
      let(:options) { ["--confirm-license"] }

      let(:manifest) { { "Andale Mono" => "Regular" } }

      it "installs font file" do
        expect { command }
          .to change { font_file("AndaleMo.TTF").exist? }.from(false).to(true)
      end

      it "returns its location" do
        expect_say_yaml(
          "Andale Mono" =>
          { "Regular" => { "full_name" => "Andale Mono",
                           "paths" => [font_path("AndaleMo.TTF")] } }
        )
      end
    end
  end

  def expect_say_yaml(result)
    expect(Fontist.ui).to receive(:say).with(include_yaml(result))
    expect(command).to be 0
  end

  def expect_error(output)
    expect(Fontist.ui).to receive(:error).with(output)
    expect(command).to be 1
  end
end
