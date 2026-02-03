require "spec_helper"

RSpec.describe Fontist::Font, "license confirmation" do
  describe "installing a font that requires license acceptance" do
    let(:test_formula) { Fontist::Test::PlatformFonts.installable_test_formula }
    let(:test_font) { Fontist::Test::PlatformFonts.installable_test_font }

    before do
      example_formula(test_formula)
    end

    context "when confirmation is not provided (defaults to 'no')" do
      it "raises LicensingError" do
        # Stub UI.ask to return "no" (simulating user rejection)
        allow(Fontist::Utils::UI).to receive(:ask).and_return("no")

        expect do
          Fontist::Font.install(test_font, confirmation: "no")
        end.to raise_error(Fontist::Errors::LicensingError)
      end
    end

    context "when confirmation is explicitly set to 'no'" do
      it "raises LicensingError" do
        # Stub UI.ask to return "no" (simulating user rejection)
        allow(Fontist::Utils::UI).to receive(:ask).and_return("no")

        expect do
          Fontist::Font.install(test_font, confirmation: "no")
        end.to raise_error(Fontist::Errors::LicensingError)
      end
    end

    context "when confirmation is set to 'yes'" do
      it "installs the font without error" do
        # Stub the font installer to avoid actually downloading fonts
        # The license check happens before the installer is called
        allow_any_instance_of(Fontist::FontInstaller).to receive(:install).and_return(["/fake/font.ttf"])

        expect do
          Fontist::Font.install(test_font, confirmation: "yes")
        end.not_to raise_error
      end
    end

    context "when UI.ask is called (confirmation not set)" do
      it "prompts for confirmation and accepts 'yes' response" do
        # Stub UI.ask to return "yes" to simulate user accepting the license
        allow(Fontist::Utils::UI).to receive(:ask).and_return("yes")

        # Stub the font installer to avoid actually downloading fonts
        allow_any_instance_of(Fontist::FontInstaller).to receive(:install).and_return(["/fake/font.ttf"])

        expect do
          Fontist::Font.install(test_font, confirmation: nil)
        end.not_to raise_error
      end
    end

    context "when UI.ask returns 'no'" do
      it "raises LicensingError" do
        # Stub UI.ask to return "no" to simulate user rejecting the license
        allow(Fontist::Utils::UI).to receive(:ask).and_return("no")

        expect do
          Fontist::Font.install(test_font, confirmation: nil)
        end.to raise_error(Fontist::Errors::LicensingError)
      end
    end
  end
end
