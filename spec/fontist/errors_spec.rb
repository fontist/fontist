require "spec_helper"

RSpec.describe Fontist::Errors do
  describe Fontist::Errors::UnsupportedMacOSVersionError do
    let(:detected_version) { "16.0" }
    let(:available_frameworks) do
      {
        3 => {
          "min_macos_version" => "10.12",
          "max_macos_version" => "10.12",
          "description" => "Font3 framework (macOS Sierra)",
        },
        7 => {
          "min_macos_version" => "12.0",
          "max_macos_version" => "15.99",
          "description" => "Font7 framework (macOS Monterey, Ventura, Sonoma, Sequoia)",
        },
        8 => {
          "min_macos_version" => "26.0",
          "max_macos_version" => nil,
          "description" => "Font8 framework (macOS Tahoe+)",
        },
      }
    end

    subject { described_class.new(detected_version, available_frameworks) }

    describe "error message" do
      it "includes the detected version" do
        expect(subject.message).to include("16.0")
        expect(subject.message).to include("Unsupported macOS version")
      end

      it "includes framework compatibility table" do
        message = subject.message

        expect(message).to include("Supported frameworks:")
        expect(message).to include("Font3")
        expect(message).to include("Font7")
        expect(message).to include("Font8")
      end

      it "shows version ranges for each framework" do
        message = subject.message

        expect(message).to include("10.12-10.12")
        expect(message).to include("12.0-15.99")
        expect(message).to include("26.0-+")
      end

      it "shows framework descriptions" do
        message = subject.message

        expect(message).to include("macOS Sierra")
        expect(message).to include("Monterey, Ventura, Sonoma, Sequoia")
        expect(message).to include("Tahoe+")
      end

      it "includes platform override instructions" do
        message = subject.message

        expect(message).to include("Override platform")
        expect(message).to include('export FONTIST_PLATFORM_OVERRIDE="macos-font<N>"')
        expect(message).to include('export FONTIST_PLATFORM_OVERRIDE="macos-font7"')
      end

      it "suggests installing to Fontist library" do
        message = subject.message

        expect(message).to include("Install to Fontist library")
        expect(message).to include("--macos-fonts-location=fontist-library")
      end

      it "mentions non-platform-tagged fonts work normally" do
        message = subject.message

        expect(message).to include("Non-macOS-platform-tagged fonts work normally")
      end

      it "includes GitHub issues link" do
        message = subject.message

        expect(message).to include("https://github.com/fontist/fontist/issues")
        expect(message).to include("Report issues")
      end
    end

    describe "with different version numbers" do
      it "handles version 20.0" do
        error = described_class.new("20.0", available_frameworks)
        expect(error.message).to include("20.0")
      end

      it "handles version 25.99" do
        error = described_class.new("25.99", available_frameworks)
        expect(error.message).to include("25.99")
      end
    end

    describe "with framework without max version" do
      it "shows + for unlimited max" do
        expect(subject.message).to include("26.0-+")
      end
    end

    describe "inheritance" do
      it "inherits from GeneralError" do
        expect(subject).to be_a(Fontist::Errors::GeneralError)
      end

      it "inherits from StandardError" do
        expect(subject).to be_a(StandardError)
      end
    end
  end
end
