require "spec_helper"

RSpec.describe Fontist::InstallLocations::SystemLocation do
  let(:formula) do
    instance_double(Fontist::Formula, key: "test", macos_import?: false)
  end

  let(:macos_formula) do
    import_source = instance_double(
      "ImportSource",
      framework_version: 7,
      asset_id: "abc123def456",
    )

    instance_double(
      Fontist::Formula,
      key: "macos/font7/sf_pro",
      macos_import?: true,
      import_source: import_source,
    )
  end

  let(:location) { described_class.new(formula) }

  describe "#location_type" do
    it "returns :system" do
      expect(location.location_type).to eq(:system)
    end
  end

  describe "#base_path" do
    context "with default configuration on macOS (regular fonts)" do
      before do
        allow(Fontist::Utils::System).to receive(:user_os).and_return(:macos)
        allow(Fontist::Config).to receive(:system_fonts_path).and_return(nil)
      end

      it "returns /Library/Fonts/fontist" do
        path = location.base_path

        expect_path(path, "/Library/Fonts/fontist")
      end
    end

    context "with default configuration on macOS (supplementary fonts)" do
      before do
        allow(Fontist::Utils::System).to receive(:user_os).and_return(:macos)
        allow(Fontist::Config).to receive(:system_fonts_path).and_return(nil)
        allow(Fontist::MacosFrameworkMetadata).to receive(:system_install_path)
          .with(7)
          .and_return("/System/Library/AssetsV2/com_apple_MobileAsset_Font7")
      end

      it "returns macOS supplementary path" do
        macos_location = described_class.new(macos_formula)
        path = macos_location.base_path

        expect(path.to_s).to include("AssetsV2/com_apple_MobileAsset_Font7")
        expect(path.to_s).to include("abc123def456.asset")
        expect(path.to_s).to end_with("AssetData")
      end

      it "uses framework version from formula" do
        import_source = instance_double(
          "ImportSource",
          framework_version: 5,
          asset_id: "test123",
        )

        formula_font5 = instance_double(
          Fontist::Formula,
          key: "macos/font5/helvetica",
          macos_import?: true,
          import_source: import_source,
        )

        allow(Fontist::MacosFrameworkMetadata).to receive(:system_install_path)
          .with(5)
          .and_return("/System/Library/AssetsV2/com_apple_MobileAsset_Font5")

        macos_location = described_class.new(formula_font5)
        expect(macos_location.base_path.to_s).to include("Font5")
      end

      it "raises error when framework version missing" do
        import_source = instance_double("ImportSource", framework_version: nil,
                                                        asset_id: "test")
        bad_formula = instance_double(
          Fontist::Formula,
          key: "macos/bad",
          macos_import?: true,
          import_source: import_source,
        )

        bad_location = described_class.new(bad_formula)
        expect do
          bad_location.base_path
        end.to raise_error(/Cannot determine framework version/)
      end

      it "raises error when asset_id missing" do
        import_source = instance_double("ImportSource", framework_version: 7,
                                                        asset_id: nil)
        bad_formula = instance_double(
          Fontist::Formula,
          key: "macos/font7/bad",
          macos_import?: true,
          import_source: import_source,
        )

        allow(Fontist::MacosFrameworkMetadata).to receive(:system_install_path)
          .with(7)
          .and_return("/System/Library/AssetsV2/com_apple_MobileAsset_Font7")

        bad_location = described_class.new(bad_formula)
        expect { bad_location.base_path }.to raise_error(/Asset ID required/)
      end
    end

    context "with default configuration on Linux" do
      before do
        allow(Fontist::Utils::System).to receive(:user_os).and_return(:linux)
        allow(Fontist::Config).to receive(:system_fonts_path).and_return(nil)
      end

      it "returns /usr/local/share/fonts/fontist" do
        path = location.base_path

        expect_path(path, "/usr/local/share/fonts/fontist")
      end
    end

    context "with default configuration on Windows" do
      before do
        allow(Fontist::Utils::System).to receive(:user_os).and_return(:windows)
        allow(Fontist::Config).to receive(:system_fonts_path).and_return(nil)
        ENV["windir"] = "C:/Windows"
      end

      after do
        ENV.delete("windir")
      end

      it "returns %windir%/Fonts/fontist" do
        path = location.base_path

        expect_path(path, "C:/Windows/Fonts/fontist")
      end

      it "falls back to SystemRoot when windir not set" do
        ENV.delete("windir")
        ENV["SystemRoot"] = "C:/WINNT"

        path = location.base_path
        expect_path(path, "C:/WINNT/Fonts/fontist")

        ENV.delete("SystemRoot")
      end

      it "uses default C:/Windows when no env vars set" do
        ENV.delete("windir")
        ENV.delete("SystemRoot")

        path = location.base_path
        expect_path(path, "C:/Windows/Fonts/fontist")
      end
    end

    context "with custom path from config" do
      before do
        allow(Fontist::Config).to receive(:system_fonts_path).and_return("/custom/system/fonts")
      end

      it "returns custom path" do
        path = location.base_path

        expect(path.to_s).to end_with("/custom/system/fonts")
      end

      it "expands relative paths" do
        allow(Fontist::Config).to receive(:system_fonts_path).and_return("~/system/fonts")
        path = location.base_path

        expect(path.to_s).not_to include("~")
        expect(path.to_s).to end_with("system/fonts")
      end
    end

    context "with unsupported platform" do
      before do
        allow(Fontist::Utils::System).to receive(:user_os).and_return(:unknown)
        allow(Fontist::Config).to receive(:system_fonts_path).and_return(nil)
      end

      it "raises error" do
        expect do
          location.base_path
        end.to raise_error(Fontist::Errors::GeneralError,
                           /Unsupported platform/)
      end
    end
  end

  describe "#requires_elevated_permissions?" do
    it "always returns true" do
      expect(location.requires_elevated_permissions?).to be true
    end

    it "returns true even for custom paths" do
      allow(Fontist::Config).to receive(:system_fonts_path).and_return("/custom/path")
      expect(location.requires_elevated_permissions?).to be true
    end
  end

  describe "#permission_warning" do
    it "returns warning message" do
      warning = location.permission_warning

      expect(warning).not_to be_nil
      expect(warning).to include("WARNING")
      expect(warning).to include("root/administrator")
      expect(warning).to include("permissions")
    end

    it "includes recommended alternatives" do
      warning = location.permission_warning

      expect(warning).to include("fontist")
      expect(warning).to include("--location=user")
    end

    it "includes cancellation instructions" do
      warning = location.permission_warning

      expect(warning).to include("Ctrl+C")
      expect(warning).to include("cancel")
    end
  end

  describe "#managed_location?" do
    context "with macOS supplementary font" do
      before do
        allow(Fontist::Utils::System).to receive(:user_os).and_return(:macos)
        allow(Fontist::Config).to receive(:system_fonts_path).and_return(nil)
        allow(Fontist::MacosFrameworkMetadata).to receive(:system_install_path)
          .with(7)
          .and_return("/System/Library/AssetsV2/com_apple_MobileAsset_Font7")
      end

      it "always returns true (OS-managed)" do
        macos_location = described_class.new(macos_formula)
        expect(macos_location.send(:managed_location?)).to be true
      end
    end

    context "with default configuration (regular fonts)" do
      before do
        allow(Fontist::Utils::System).to receive(:user_os).and_return(:linux)
        allow(Fontist::Config).to receive(:system_fonts_path).and_return(nil)
      end

      it "returns true (default managed subdirectory)" do
        expect(location.send(:managed_location?)).to be true
      end
    end

    context "with custom path ending in /fontist" do
      before do
        allow(Fontist::Config).to receive(:system_fonts_path).and_return("/custom/system/fontist")
      end

      it "returns true (managed subdirectory)" do
        expect(location.send(:managed_location?)).to be true
      end
    end

    context "with custom path ending in \\fontist (Windows)" do
      before do
        allow(Fontist::Config).to receive(:system_fonts_path).and_return("C:\\Windows\\Fonts\\fontist")
      end

      it "returns true (managed subdirectory)" do
        expect(location.send(:managed_location?)).to be true
      end
    end

    context "with custom path NOT ending in /fontist" do
      before do
        allow(Fontist::Config).to receive(:system_fonts_path).and_return("/Library/Fonts")
      end

      it "returns false (non-managed root)" do
        expect(location.send(:managed_location?)).to be false
      end
    end
  end

  describe "#index" do
    it "returns SystemIndex singleton instance" do
      index = location.send(:index)

      expect(index).to be_a(Fontist::Indexes::SystemIndex)
      expect(index).to eq(Fontist::Indexes::SystemIndex.instance)
    end

    it "returns same instance on multiple calls" do
      index1 = location.send(:index)
      index2 = location.send(:index)

      expect(index1).to be(index2)
    end
  end

  describe "#uses_fontist_subdirectory?" do
    context "with Unix-style path ending in /fontist" do
      before do
        allow(Fontist::Config).to receive(:system_fonts_path).and_return("/usr/share/fonts/fontist")
      end

      it "returns true" do
        expect(location.send(:uses_fontist_subdirectory?)).to be true
      end
    end

    context "with Windows-style path ending in \\fontist" do
      before do
        allow(Fontist::Config).to receive(:system_fonts_path).and_return("C:\\Windows\\Fonts\\fontist")
      end

      it "returns true" do
        expect(location.send(:uses_fontist_subdirectory?)).to be true
      end
    end

    context "with path not ending in fontist" do
      before do
        allow(Fontist::Config).to receive(:system_fonts_path).and_return("/Library/Fonts")
      end

      it "returns false" do
        expect(location.send(:uses_fontist_subdirectory?)).to be false
      end
    end
  end
end
