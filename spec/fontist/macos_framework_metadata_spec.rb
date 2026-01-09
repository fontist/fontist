require "spec_helper"
require_relative "../../lib/fontist/macos_framework_metadata"

RSpec.describe Fontist::MacosFrameworkMetadata do
  describe ".framework_for_macos" do
    context "with valid macOS versions" do
      it "returns 3 for macOS 10.12 (Sierra)" do
        expect(described_class.framework_for_macos("10.12")).to eq(3)
      end

      it "returns 4 for macOS 10.13 (High Sierra)" do
        expect(described_class.framework_for_macos("10.13")).to eq(4)
      end

      it "returns 5 for macOS 10.14 (Mojave)" do
        expect(described_class.framework_for_macos("10.14")).to eq(5)
      end

      it "returns 6 for macOS 10.15 (Catalina)" do
        # Font6 range is 10.15-11.99, selected over Font5 (10.14-10.15) as newest
        expect(described_class.framework_for_macos("10.15")).to eq(6)
      end

      it "returns 6 for macOS 11.0 (Big Sur)" do
        expect(described_class.framework_for_macos("11.0")).to eq(6)
      end

      it "returns 6 for macOS 11.99 (Big Sur edge)" do
        expect(described_class.framework_for_macos("11.99")).to eq(6)
      end

      it "returns 7 for macOS 12.0 (Monterey)" do
        expect(described_class.framework_for_macos("12.0")).to eq(7)
      end

      it "returns 7 for macOS 13.0 (Ventura)" do
        expect(described_class.framework_for_macos("13.0")).to eq(7)
      end

      it "returns 7 for macOS 14.0 (Sonoma)" do
        expect(described_class.framework_for_macos("14.0")).to eq(7)
      end

      it "returns 7 for macOS 15.0 (Sequoia)" do
        expect(described_class.framework_for_macos("15.0")).to eq(7)
      end

      it "returns 7 for macOS 15.99 (highest in Font7 range)" do
        expect(described_class.framework_for_macos("15.99")).to eq(7)
      end

      it "returns 8 for macOS 26.0 (Tahoe)" do
        expect(described_class.framework_for_macos("26.0")).to eq(8)
      end

      it "returns 8 for macOS 27.0 (future version)" do
        expect(described_class.framework_for_macos("27.0")).to eq(8)
      end
    end

    context "with unsupported macOS versions" do
      it "returns nil for versions 16-25 (gap in Apple versioning)" do
        expect(described_class.framework_for_macos("16.0")).to be_nil
        expect(described_class.framework_for_macos("20.0")).to be_nil
        expect(described_class.framework_for_macos("25.0")).to be_nil
        expect(described_class.framework_for_macos("25.99")).to be_nil
      end

      it "returns nil for ancient versions (< 10.12)" do
        expect(described_class.framework_for_macos("10.11")).to be_nil
        expect(described_class.framework_for_macos("10.10")).to be_nil
        expect(described_class.framework_for_macos("10.9")).to be_nil
      end

      it "returns nil for invalid versions" do
        expect(described_class.framework_for_macos("")).to be_nil
        expect(described_class.framework_for_macos(nil)).to be_nil
      end
    end

    context "with version edge cases" do
      it "handles patch versions for ranges that allow them" do
        # Font7 has range 12.0-15.99, so patch versions work fine
        expect(described_class.framework_for_macos("12.5.1")).to eq(7)
        expect(described_class.framework_for_macos("14.2.1")).to eq(7)
      end

      it "selects newest compatible framework for overlapping ranges" do
        # 10.15 is compatible with both Font5 (10.14-10.15) and Font6 (10.15-11.99)
        # Code searches in reverse order (newest first), so it picks Font6
        expect(described_class.framework_for_macos("10.15.0")).to eq(6)
      end
    end
  end

  describe ".system_install_path" do
    it "returns correct path for Font3" do
      path = described_class.system_install_path(3)
      expect_path(path, "/System/Library/Assets/com_apple_MobileAsset_Font3")
    end

    it "returns correct path for Font4" do
      path = described_class.system_install_path(4)
      expect_path(path, "/System/Library/Assets/com_apple_MobileAsset_Font4")
    end

    it "returns correct path for Font5" do
      path = described_class.system_install_path(5)
      expect_path(path, "/System/Library/AssetsV2/com_apple_MobileAsset_Font5")
    end

    it "returns correct path for Font6" do
      path = described_class.system_install_path(6)
      expect_path(path, "/System/Library/AssetsV2/com_apple_MobileAsset_Font6")
    end

    it "returns correct path for Font7" do
      path = described_class.system_install_path(7)
      expect_path(path, "/System/Library/AssetsV2/com_apple_MobileAsset_Font7")
    end

    it "returns correct path for Font8" do
      path = described_class.system_install_path(8)
      expect_path(path, "/System/Library/AssetsV2/com_apple_MobileAsset_Font8")
    end
  end

  describe ".asset_path" do
    it "returns /System/Library/Assets for Font3" do
      expect_path(described_class.asset_path(3), "/System/Library/Assets")
    end

    it "returns /System/Library/Assets for Font4" do
      expect_path(described_class.asset_path(4), "/System/Library/Assets")
    end

    it "returns /System/Library/AssetsV2 for Font5-8" do
      expect_path(described_class.asset_path(5), "/System/Library/AssetsV2")
      expect_path(described_class.asset_path(6), "/System/Library/AssetsV2")
      expect_path(described_class.asset_path(7), "/System/Library/AssetsV2")
      expect_path(described_class.asset_path(8), "/System/Library/AssetsV2")
    end
  end

  describe ".min_macos_version" do
    it "returns correct minimum versions" do
      expect(described_class.min_macos_version(3)).to eq("10.12")
      expect(described_class.min_macos_version(4)).to eq("10.13")
      expect(described_class.min_macos_version(5)).to eq("10.14")
      expect(described_class.min_macos_version(6)).to eq("10.15")
      expect(described_class.min_macos_version(7)).to eq("12.0")
      expect(described_class.min_macos_version(8)).to eq("26.0")
    end
  end

  describe ".max_macos_version" do
    it "returns correct maximum versions" do
      expect(described_class.max_macos_version(3)).to eq("10.12")
      expect(described_class.max_macos_version(4)).to eq("10.13")
      expect(described_class.max_macos_version(5)).to eq("10.15")
      expect(described_class.max_macos_version(6)).to eq("11.99")
      expect(described_class.max_macos_version(7)).to eq("15.99")
      expect(described_class.max_macos_version(8)).to be_nil # No upper limit
    end
  end

  describe ".description" do
    it "returns correct descriptions" do
      expect(described_class.description(3)).to eq("Font3 framework (macOS Sierra)")
      expect(described_class.description(7)).to eq("Font7 framework (macOS Monterey, Ventura, Sonoma, Sequoia)")
      expect(described_class.description(8)).to eq("Font8 framework (macOS Tahoe+)")
    end

    it "returns generic message for unknown framework" do
      expect(described_class.description(99)).to eq("Unknown framework 99")
    end
  end

  describe ".compatible_with_macos?" do
    it "returns true for exact minimum version match" do
      expect(described_class.compatible_with_macos?(7, "12.0")).to be true
    end

    it "returns true for version in range" do
      expect(described_class.compatible_with_macos?(7, "13.5")).to be true
      expect(described_class.compatible_with_macos?(7, "15.0")).to be true
    end

    it "returns false for version below minimum" do
      expect(described_class.compatible_with_macos?(7, "11.9")).to be false
    end

    it "returns false for version above maximum" do
      expect(described_class.compatible_with_macos?(7, "16.0")).to be false
    end

    it "returns true for Font8 with no upper limit" do
      expect(described_class.compatible_with_macos?(8, "26.0")).to be true
      expect(described_class.compatible_with_macos?(8, "30.0")).to be true
      expect(described_class.compatible_with_macos?(8, "100.0")).to be true
    end

    it "returns false for invalid framework" do
      expect(described_class.compatible_with_macos?(99, "12.0")).to be false
    end
  end
end