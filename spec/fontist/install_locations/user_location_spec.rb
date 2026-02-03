require "spec_helper"

RSpec.describe Fontist::InstallLocations::UserLocation do
  let(:formula) do
    instance_double(Fontist::Formula, key: "test")
  end

  let(:location) { described_class.new(formula) }

  describe "#location_type" do
    it "returns :user" do
      expect(location.location_type).to eq(:user)
    end
  end

  describe "#base_path" do
    context "with default configuration on macOS" do
      before do
        allow(Fontist::Utils::System).to receive(:user_os).and_return(:macos)
        allow(Fontist::Config).to receive(:user_fonts_path).and_return(nil)
      end

      it "returns ~/Library/Fonts/fontist" do
        path = location.base_path

        expect(path.to_s).to match(%r{Library/Fonts/fontist$})
      end
    end

    context "with default configuration on Linux" do
      before do
        allow(Fontist::Utils::System).to receive(:user_os).and_return(:linux)
        allow(Fontist::Config).to receive(:user_fonts_path).and_return(nil)
      end

      it "returns ~/.local/share/fonts/fontist" do
        path = location.base_path

        expect(path.to_s).to match(%r{\.local/share/fonts/fontist$})
      end
    end

    context "with default configuration on Windows" do
      before do
        allow(Fontist::Utils::System).to receive(:user_os).and_return(:windows)
        allow(Fontist::Config).to receive(:user_fonts_path).and_return(nil)
        ENV["LOCALAPPDATA"] = "C:/Users/Test/AppData/Local"
      end

      after do
        ENV.delete("LOCALAPPDATA")
      end

      it "returns %LOCALAPPDATA%/Microsoft/Windows/Fonts/fontist" do
        path = location.base_path

        expect(path.to_s).to include("Microsoft/Windows/Fonts/fontist")
      end

      it "falls back when LOCALAPPDATA not set" do
        ENV.delete("LOCALAPPDATA")
        path = location.base_path

        expect(path.to_s).to match(%r{AppData/Local/Microsoft/Windows/Fonts/fontist$})
      end
    end

    context "with custom path from config" do
      before do
        allow(Fontist::Config).to receive(:user_fonts_path).and_return("/custom/path/fonts")
      end

      it "returns custom path" do
        path = location.base_path

        expect(path.to_s).to end_with("/custom/path/fonts")
      end

      it "expands relative paths" do
        allow(Fontist::Config).to receive(:user_fonts_path).and_return("~/custom/fonts")
        path = location.base_path

        expect(path.to_s).not_to include("~")
        expect(path.to_s).to end_with("custom/fonts")
      end
    end

    context "with unsupported platform" do
      before do
        allow(Fontist::Utils::System).to receive(:user_os).and_return(:unknown)
        allow(Fontist::Config).to receive(:user_fonts_path).and_return(nil)
      end

      it "raises error" do
        expect do
          location.base_path
        end.to raise_error(Fontist::Errors::GeneralError,
                           /Unsupported platform/)
      end
    end
  end

  describe "#managed_location?" do
    context "with default configuration" do
      before do
        allow(Fontist::Utils::System).to receive(:user_os).and_return(:macos)
        allow(Fontist::Config).to receive(:user_fonts_path).and_return(nil)
      end

      it "returns true (default managed subdirectory)" do
        expect(location.send(:managed_location?)).to be true
      end
    end

    context "with custom path ending in /fontist" do
      before do
        allow(Fontist::Config).to receive(:user_fonts_path).and_return("/custom/path/fontist")
      end

      it "returns true (managed subdirectory)" do
        expect(location.send(:managed_location?)).to be true
      end
    end

    context "with custom path ending in \\fontist (Windows)" do
      before do
        allow(Fontist::Config).to receive(:user_fonts_path).and_return("C:\\custom\\path\\fontist")
      end

      it "returns true (managed subdirectory)" do
        expect(location.send(:managed_location?)).to be true
      end
    end

    context "with custom path NOT ending in /fontist" do
      before do
        allow(Fontist::Config).to receive(:user_fonts_path).and_return("/Library/Fonts")
      end

      it "returns false (non-managed root)" do
        expect(location.send(:managed_location?)).to be false
      end
    end

    context "with custom path containing fontist but not as final segment" do
      before do
        allow(Fontist::Config).to receive(:user_fonts_path).and_return("/fontist/custom/path")
      end

      it "returns false" do
        expect(location.send(:managed_location?)).to be false
      end
    end
  end

  describe "#requires_elevated_permissions?" do
    it "returns false" do
      expect(location.requires_elevated_permissions?).to be false
    end
  end

  describe "#permission_warning" do
    it "returns nil" do
      expect(location.permission_warning).to be_nil
    end
  end

  describe "#index" do
    it "returns UserIndex singleton instance" do
      index = location.send(:index)

      expect(index).to be_a(Fontist::Indexes::UserIndex)
      expect(index).to eq(Fontist::Indexes::UserIndex.instance)
    end

    it "returns same instance on multiple calls" do
      index1 = location.send(:index)
      index2 = location.send(:index)

      expect(index1).to be(index2)
    end
  end

  describe "platform-specific paths" do
    context "macOS" do
      before do
        allow(Fontist::Utils::System).to receive(:user_os).and_return(:macos)
        allow(Fontist::Config).to receive(:user_fonts_path).and_return(nil)
      end

      it "uses Library/Fonts as base" do
        path = location.send(:default_user_path)
        expect(path.to_s).to end_with("Library/Fonts")
      end
    end

    context "Linux" do
      before do
        allow(Fontist::Utils::System).to receive(:user_os).and_return(:linux)
        allow(Fontist::Config).to receive(:user_fonts_path).and_return(nil)
      end

      it "uses .local/share/fonts as base" do
        path = location.send(:default_user_path)
        expect(path.to_s).to end_with(".local/share/fonts")
      end
    end

    context "Windows" do
      before do
        allow(Fontist::Utils::System).to receive(:user_os).and_return(:windows)
        allow(Fontist::Config).to receive(:user_fonts_path).and_return(nil)
        ENV["LOCALAPPDATA"] = "C:/Users/Test/AppData/Local"
      end

      after do
        ENV.delete("LOCALAPPDATA")
      end

      it "uses LOCALAPPDATA/Microsoft/Windows/Fonts as base" do
        path = location.send(:default_user_path)
        expect(path.to_s).to include("Microsoft/Windows/Fonts")
      end
    end
  end

  describe "#uses_fontist_subdirectory?" do
    context "with Unix-style path ending in /fontist" do
      before do
        allow(Fontist::Config).to receive(:user_fonts_path).and_return("/path/to/fontist")
      end

      it "returns true" do
        expect(location.send(:uses_fontist_subdirectory?)).to be true
      end
    end

    context "with Windows-style path ending in \\fontist" do
      before do
        allow(Fontist::Config).to receive(:user_fonts_path).and_return("C:\\path\\to\\fontist")
      end

      it "returns true" do
        expect(location.send(:uses_fontist_subdirectory?)).to be true
      end
    end

    context "with path not ending in fontist" do
      before do
        allow(Fontist::Config).to receive(:user_fonts_path).and_return("/path/to/fonts")
      end

      it "returns false" do
        expect(location.send(:uses_fontist_subdirectory?)).to be false
      end
    end
  end
end
