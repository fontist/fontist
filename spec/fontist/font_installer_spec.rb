require "spec_helper"

RSpec.describe Fontist::FontInstaller do
  describe "#install" do
    context "with confirmation" do
      it "installs font" do
        no_fonts do
          formula = Fontist::Formula.find("andale mono")
          paths = described_class.new(formula).install(confirmation: "yes")
          expect(paths).to include(
            include("AndaleMo.TTF").or(include("andalemo.ttf")),
          )
          expect(font_files).to include(/AndaleMo.TTF/i)
        end
      end
    end

    context "with no confirmation" do
      it "raises an licensing error" do
        no_fonts do
          formula = Fontist::Formula.find("andale mono")
          expect { described_class.new(formula).install(confirmation: "no") }
            .to raise_error(Fontist::Errors::LicensingError)
        end
      end
    end
  end
end
