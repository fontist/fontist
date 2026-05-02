require "spec_helper"

RSpec.describe "Windows On-Demand Fonts" do
  describe "platform-specific font installation" do
    let(:windows_formula_path) do
      Fontist.formulas_path.join("windows", "test_japanese_supplemental_fonts.yml")
    end

    let(:windows_formula_content) do
      <<~YAML
        ---
        name: Japanese Supplemental Fonts
        description: Japanese Supplemental Fonts for Windows
        homepage: https://learn.microsoft.com/en-us/typography/fonts/windows_11_font_list
        platforms:
          - windows
        resources:
          japanese_supplemental_fonts:
            source: windows_fod
            capability_name: "Language.Fonts.Jpan~~~und-JPAN~0.0.1.0"
        fonts:
          - name: Meiryo
            styles:
              - family_name: Meiryo
                type: Regular
                font: Meiryo.ttc
              - family_name: Meiryo
                type: Bold
                font: Meiryob.ttc
        open_license: |
          Licensed under the Microsoft Software License Terms for Windows.
        import_source:
          type: windows
          capability_name: "Language.Fonts.Jpan~~~und-JPAN~0.0.1.0"
          min_windows_version: "10.0"
      YAML
    end

    before do
      FileUtils.mkdir_p(windows_formula_path.dirname)
      File.write(windows_formula_path, windows_formula_content)
      Fontist::Index.rebuild
    end

    after do
      FileUtils.rm_f(windows_formula_path)
      Fontist::Index.rebuild
    end

    context "formula loading" do
      it "loads the Windows FOD formula correctly" do
        formula = Fontist::Formula.find_by_key("windows/test_japanese_supplemental_fonts")

        expect(formula).not_to be_nil
        expect(formula.name).to eq("Japanese Supplemental Fonts")
        expect(formula.platforms).to eq(["windows"])
        expect(formula.source).to eq("windows_fod")
      end

      it "recognizes windows_fod source" do
        formula = Fontist::Formula.find_by_key("windows/test_japanese_supplemental_fonts")

        expect(formula.source).to eq("windows_fod")
        expect(formula.windows_fod?).to be true
      end

      it "has a WindowsImportSource" do
        formula = Fontist::Formula.find_by_key("windows/test_japanese_supplemental_fonts")

        expect(formula.windows_import?).to be true
        expect(formula.import_source).to be_a(Fontist::WindowsImportSource)
        expect(formula.import_source.capability_name).to eq("Language.Fonts.Jpan~~~und-JPAN~0.0.1.0")
        expect(formula.import_source.min_windows_version).to eq("10.0")
      end

      it "has the capability_name on the resource" do
        formula = Fontist::Formula.find_by_key("windows/test_japanese_supplemental_fonts")

        expect(formula.resources.first.capability_name).to eq("Language.Fonts.Jpan~~~und-JPAN~0.0.1.0")
      end
    end

    context "on macOS platform" do
      it "prevents installation of Windows-only fonts" do
        formula = Fontist::Formula.find_by_key("windows/test_japanese_supplemental_fonts")

        allow(Fontist::Utils::System).to receive(:user_os).and_return(:macos)
        expect(formula.compatible_with_platform?).to be false
      end

      it "raises PlatformMismatchError when installing" do
        formula = Fontist::Formula.find_by_key("windows/test_japanese_supplemental_fonts")
        skip "Test formula not available" if formula.nil?

        allow(Fontist::Utils::System).to receive(:user_os).and_return(:macos)

        installer = Fontist::FontInstaller.new(formula, font_name: "Meiryo")

        expect do
          installer.install(confirmation: "yes")
        end.to raise_error(Fontist::Errors::PlatformMismatchError) do |error|
          expect(error.message).to include("only available for: windows")
          expect(error.message).to include("platform is: macos")
        end
      end
    end

    context "on Linux platform" do
      it "prevents installation of Windows-only fonts" do
        formula = Fontist::Formula.find_by_key("windows/test_japanese_supplemental_fonts")

        allow(Fontist::Utils::System).to receive(:user_os).and_return(:linux)
        expect(formula.compatible_with_platform?).to be false
      end

      it "raises PlatformMismatchError when installing" do
        formula = Fontist::Formula.find_by_key("windows/test_japanese_supplemental_fonts")
        skip "Test formula not available" if formula.nil?

        allow(Fontist::Utils::System).to receive(:user_os).and_return(:linux)

        installer = Fontist::FontInstaller.new(formula, font_name: "Meiryo")

        expect do
          installer.install(confirmation: "yes")
        end.to raise_error(Fontist::Errors::PlatformMismatchError) do |error|
          expect(error.message).to include("only available for: windows")
          expect(error.message).to include("platform is: linux")
        end
      end

      it "provides helpful error message" do
        allow(Fontist::Utils::System).to receive(:user_os).and_return(:linux)
        formula = Fontist::Formula.find_by_key("windows/test_japanese_supplemental_fonts")

        skip "Test formula not available" if formula.nil?

        message = formula.platform_restriction_message
        expect(message).to include("only available for: windows")
        expect(message).to include("platform is: linux")
      end
    end

    context "on Windows platform" do
      it "allows installation of Windows fonts" do
        formula = Fontist::Formula.find_by_key("windows/test_japanese_supplemental_fonts")

        allow(Fontist::Utils::System).to receive(:user_os).and_return(:windows)
        expect(formula.compatible_with_platform?).to be true
      end
    end
  end

  describe "FontInstaller resource dispatch" do
    let(:windows_formula_path) do
      Fontist.formulas_path.join("windows", "test_dispatch.yml")
    end

    let(:windows_formula_content) do
      <<~YAML
        ---
        name: Test Windows FOD Dispatch
        platforms:
          - windows
        resources:
          test_resource:
            source: windows_fod
            capability_name: "Language.Fonts.Jpan~~~und-JPAN~0.0.1.0"
        fonts:
          - name: TestFont
            styles:
              - family_name: TestFont
                type: Regular
                font: test.ttf
        open_license: Test license
      YAML
    end

    before do
      FileUtils.mkdir_p(windows_formula_path.dirname)
      File.write(windows_formula_path, windows_formula_content)
      Fontist::Index.rebuild
    end

    after do
      FileUtils.rm_f(windows_formula_path)
      Fontist::Index.rebuild
    end

    it "dispatches to WindowsFodResource for windows_fod source" do
      allow(Fontist::Utils::System).to receive(:user_os).and_return(:windows)

      formula = Fontist::Formula.find_by_key("windows/test_dispatch")
      expect(formula.source).to eq("windows_fod")

      # The resource method is private, so we test through the installer
      installer = Fontist::FontInstaller.new(formula)
      resource = installer.send(:resource)
      expect(resource).to be_a(Fontist::Resources::WindowsFodResource)
    end
  end
end
