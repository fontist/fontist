require "spec_helper"
require_relative "../../lib/fontist/macos/catalog/catalog_manager"
require_relative "../../lib/fontist/macos/catalog/asset"
require_relative "../../lib/fontist/macos/catalog/base_parser"
require_relative "../../lib/fontist/macos/catalog/font7_parser"
require_relative "../../lib/fontist/macos/catalog/font8_parser"
require_relative "../support/macos_catalog_helper"

RSpec.describe "macOS On-Demand Fonts" do
  describe "platform-specific font installation" do
    let(:macos_formula_path) do
      Fontist.formulas_path.join("macos", "test_al_bayan.yml")
    end

    let(:macos_formula_content) do
      <<~YAML
        ---
        name: Al Bayan
        description: Arabic font from macOS
        homepage: https://support.apple.com/en-us/HT211240
        platforms:
          - macos
        resources:
          al_bayan:
            source: apple_cdn
            urls:
              - https://updates.cdn-apple.com/2022/mobileassets/071-13653-20220413-E31024B7-9C74-440D-BD83-2BC15B9FF98E/com_apple_MobileAsset_Font7/701405507c8753373648c7a6541608e32ed089ec.zip
            sha256:
              - 9f4e142e68bcbf161ecfa290da0c65ebc4ef2c0e2aa85ee4f4c6a0e4b8e4b8e4
            file_size: 101972
        fonts:
          - name: Al Bayan
            styles:
              - family_name: Al Bayan
                type: Plain
                font: AlBayan.ttc
                post_script_name: AlBayan
        open_license: Apple Font License
      YAML
    end

    before do
      FileUtils.mkdir_p(macos_formula_path.dirname)
      File.write(macos_formula_path, macos_formula_content)
      Fontist::Index.rebuild
    end

    after do
      FileUtils.rm_f(macos_formula_path)
      Fontist::Index.rebuild
    end

    context "on macOS platform" do
      it "allows installation of macOS-only fonts", skip_unless_macos: true do
        formula = Fontist::Formula.find_by_key("macos/test_al_bayan")

        expect(formula).not_to be_nil
        expect(formula.platforms).to eq(["macos"])
        expect(formula.compatible_with_platform?).to be true
        expect(formula.source).to eq("apple_cdn")
      end

      it "recognizes apple_cdn source", skip_unless_macos: true do
        formula = Fontist::Formula.find_by_key("macos/test_al_bayan")

        expect(formula.source).to eq("apple_cdn")
        expect(formula.requires_system_installation?).to be true
      end
    end

    context "on Linux platform" do
      it "prevents installation of macOS-only fonts", skip_on_macos: true do
        formula = Fontist::Formula.find_by_key("macos/test_al_bayan")

        expect(formula).not_to be_nil
        expect(formula.platforms).to eq(["macos"])

        # Should not be compatible on Linux
        allow(Fontist::Utils::System).to receive(:user_os).and_return(:linux)
        expect(formula.compatible_with_platform?).to be false
      end

      it "raises PlatformMismatchError when installing", skip_on_macos: true do
        # First verify the formula exists before mocking
        formula = Fontist::Formula.find_by_key("macos/test_al_bayan")
        skip "Test formula not available" if formula.nil?

        allow(Fontist::Utils::System).to receive(:user_os).and_return(:linux)

        # Use FontInstaller directly to test platform validation
        installer = Fontist::FontInstaller.new(formula, font_name: "Al Bayan")

        expect do
          installer.install(confirmation: "yes")
        end.to raise_error(Fontist::Errors::PlatformMismatchError) do |error|
          expect(error.message).to include("Al Bayan")
          expect(error.message).to include("only available for: macos")
          expect(error.message).to include("platform is: linux")
        end
      end

      it "provides helpful error message", skip_on_macos: true do
        allow(Fontist::Utils::System).to receive(:user_os).and_return(:linux)
        formula = Fontist::Formula.find_by_key("macos/test_al_bayan")

        skip "Test formula not available" if formula.nil?

        message = formula.platform_restriction_message
        expect(message).to include("only available for: macos")
        expect(message).to include("platform is: linux")
      end
    end

    context "on Windows platform" do
      it "prevents installation of macOS-only fonts", skip_on_macos: true do
        formula = Fontist::Formula.find_by_key("macos/test_al_bayan")

        allow(Fontist::Utils::System).to receive(:user_os).and_return(:windows)
        expect(formula.compatible_with_platform?).to be false
      end

      it "raises PlatformMismatchError at FontInstaller level" do
        allow(Fontist::Utils::System).to receive(:user_os).and_return(:windows)

        formula = Fontist::Formula.find_by_key("macos/test_al_bayan")
        skip "Test formula not available" if formula.nil?

        installer = Fontist::FontInstaller.new(formula, font_name: "Al Bayan")

        expect do
          installer.install(confirmation: "yes")
        end.to raise_error(Fontist::Errors::PlatformMismatchError) do |error|
          expect(error.message).to include("only available for: macos")
          expect(error.message).to include("Your current platform is: windows")
        end
      end
    end

    context "manifest installation with platform validation" do
      let(:manifest_content) do
        <<~YAML
          ---
          "Al Bayan":
            - Plain
        YAML
      end

      let(:manifest_path) do
        Tempfile.new(["macos_manifest", ".yml"]).tap do |f|
          f.write(manifest_content)
          f.close
        end.path
      end

      after do
        FileUtils.rm_f(manifest_path)
      end

      it "validates platform before installation on Linux", skip_on_macos: true do
        allow(Fontist::Utils::System).to receive(:user_os).and_return(:linux)

        # Check if formula exists first
        formula = Fontist::Formula.find_by_key("macos/test_al_bayan")
        skip "Test formula not available" if formula.nil?

        # Test at ManifestFont level
        manifest_font = Fontist::ManifestFont.new(name: "Al Bayan", styles: ["Plain"])

        expect do
          manifest_font.install(confirmation: "yes")
        end.to raise_error(Fontist::Errors::PlatformMismatchError)
      end

      it "validates platform before installation on Windows" do
        allow(Fontist::Utils::System).to receive(:user_os).and_return(:windows)

        # Check if formula exists first
        formula = Fontist::Formula.find_by_key("macos/test_al_bayan")
        skip "Test formula not available" if formula.nil?

        # Test at ManifestFont level
        manifest_font = Fontist::ManifestFont.new(name: "Al Bayan", styles: ["Plain"])

        expect do
          manifest_font.install(confirmation: "yes")
        end.to raise_error(Fontist::Errors::PlatformMismatchError) do |error|
          expect(error.message).to match(/only available for.*macos/)
          expect(error.message).to include("windows")
        end
      end
    end
  end

  describe "catalog parsing", skip_unless_macos: true do
    context "when catalogs are available" do
      before do
        # Set up catalogs in the Fontist home directory for these tests
        MacosCatalogHelper.setup_catalogs(Fontist.fontist_version_path.to_s)
      end

      it "detects available catalogs" do
        catalogs = Fontist::Macos::Catalog::CatalogManager.available_catalogs

        expect(catalogs).to be_an(Array)
        expect(catalogs).not_to be_empty
      end

      it "detects catalog versions correctly" do
        catalog_path = Fontist::Macos::Catalog::CatalogManager.available_catalogs.first
        version = Fontist::Macos::Catalog::CatalogManager.detect_version(catalog_path)

        expect(version).to be_a(Integer)
        expect(version).to be >= 3
      end
    end
  end

  describe "CLI commands" do
    describe "macos-catalogs command" do
      it "lists available catalogs without error", skip_unless_macos: true do
        expect do
          Fontist::CLI.new.invoke(:macos_catalogs)
        end.not_to raise_error
      end

      it "handles missing catalogs gracefully" do
        allow(Fontist::Macos::Catalog::CatalogManager)
          .to receive(:available_catalogs)
          .and_return([])

        # Should not crash, just report no catalogs found
        expect do
          Fontist::CLI.new.invoke(:macos_catalogs)
        end.not_to raise_error
      end
    end
  end

  describe "cross-platform behavior" do
    let(:macos_formula_path) do
      Fontist.formulas_path.join("macos", "test_al_bayan.yml")
    end

    let(:macos_formula_content) do
      <<~YAML
        ---
        name: Al Bayan
        description: Arabic font from macOS
        homepage: https://support.apple.com/en-us/HT211240
        platforms:
          - macos
        resources:
          al_bayan:
            source: apple_cdn
            urls:
              - https://updates.cdn-apple.com/2022/mobileassets/071-13653-20220413-E31024B7-9C74-440D-BD83-2BC15B9FF98E/com_apple_MobileAsset_Font7/701405507c8753373648c7a6541608e32ed089ec.zip
            sha256:
              - 9f4e142e68bcbf161ecfa290da0c65ebc4ef2c0e2aa85ee4f4c6a0e4b8e4b8e4
            file_size: 101972
        fonts:
          - name: Al Bayan
            styles:
              - family_name: Al Bayan
                type: Plain
                font: AlBayan.ttc
                post_script_name: AlBayan
        open_license: Apple Font License
      YAML
    end

    let(:current_os) { Fontist::Utils::System.user_os }

    before do
      FileUtils.mkdir_p(macos_formula_path.dirname)
      File.write(macos_formula_path, macos_formula_content)
      Fontist::Index.rebuild
    end

    after do
      FileUtils.rm_f(macos_formula_path)
      Fontist::Index.rebuild
    end

    it "knows the current platform" do
      expect([:macos, :linux, :windows, :unix]).to include(current_os)
    end

    it "validates platform correctly for macOS formulas" do
      formula = Fontist::Formula.find_by_key("macos/test_al_bayan")
      expect(formula).not_to be_nil, "Test formula should be available"

      case current_os
      when :macos
        expect(formula.compatible_with_platform?).to be true
      when :linux, :windows
        allow(Fontist::Utils::System).to receive(:user_os).and_return(current_os)
        expect(formula.compatible_with_platform?).to be false
      end
    end
  end
end

# RSpec configuration for platform-specific tests
RSpec.configure do |config|
  config.before(:each, skip_unless_macos: true) do
    skip "Test requires macOS" unless Fontist::Utils::System.user_os == :macos
  end

  config.before(:each, skip_on_macos: true) do
    skip "Test only runs on non-macOS" if Fontist::Utils::System.user_os == :macos
  end
end