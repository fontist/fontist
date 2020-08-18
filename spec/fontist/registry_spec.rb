require "spec_helper"

RSpec.describe Fontist::Registry do
  describe ".register" do
    context "with no key provided" do
      it "registers a fontist formula with default key" do
        Fontist::Registry.register(Fontist::Formulas::DemoFormula)
        demo_formula = Fontist::Registry.formulas.demo_formula

        expect(demo_formula.license).to eq("Vendor specific font licences")
        expect(demo_formula.fonts.first.styles.first.type).to eq("Regular")
        expect(demo_formula.installer).to eq("Fontist::Formulas::DemoFormula")
        expect(demo_formula.homepage).to eq("https://github.com/fontist/fontist")
      end
    end

    context "with custom key provided" do
      it "registers the formula with this custom key" do
        Fontist::Registry.register(Fontist::Formulas::DemoFormula, :custom_key)

        expect(Fontist::Registry.formulas.custom_key).not_to be_nil
      end
    end
  end

  module Fontist
    module Formulas
      class DemoFormula < FontFormula
        key :demo_formula
        desc "Demo font formula"
        homepage "https://github.com/fontist/fontist"
        requires_license_agreement "Vendor specific font licences"

        resource "demo-formula" do
          urls [ "https://github.com/fontist/fontist" ]
          sha256 "594e0f42e6581add4dead70c1dfb9"
          file_size "1234567890"
        end

        provides_font "Demo font", match_styles_from_file_extended: [
          {
            family_name: "Demo font",
            style: "Regular",
            full_name: "Demo font",
            filename: "demo-font.ttf",
          },
          {
            family_name: "Demo font",
            style: "Italic",
            full_name: "Demo font Italic",
            filename: "demo-fonti.ttf",
          },
        ]
      end
    end
  end
end
