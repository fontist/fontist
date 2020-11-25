require "spec_helper"

RSpec.describe "Fontist::Formulas::DemoFormula" do
  describe "initialization" do
    it "registers formula resources through the DSL" do
      formula = Fontist::Formulas::DemoFormula.instance
      resource = formula.resources["demo-formula"]
      demo_font = formula.font_list.first

      expect(formula.key).to eq(:demo_formula)
      expect(formula.license_required).to be_truthy
      expect(formula.description).to eq("Demo font formula")
      expect(formula.license).to eq("Vendor specific font licences")
      expect(formula.homepage).to eq("https://github.com/fontist/fontist")

      expect(resource[:file_size]).to eq("1234567890")
      expect(resource[:urls].first).to eq("https://github.com/fontist/fontist")
      expect(resource[:sha256]).to eq("594e0f42e6581add4dead70c1dfb9")

      expect(demo_font[:styles].count).to eq(2)
      expect(demo_font[:name]).to eq("Demo font")
      expect(demo_font[:styles].first[:font]).to eq("demo-font.ttf")
    end
  end

  describe "method invokation" do
    it "invokes the correct method for installation" do
      expect {
        Fontist::Formulas::DemoFormula.fetch_font("Demo font", confirmation: "yes")
      }.not_to raise_error
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

        provides_font "Demo font", match_styles_from_file: [
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

        provides_font_collection("Meiryo Bold") do |coll|
          filename "demo-font.ttc"
          provides_font "Demo collection", extract_styles_from_collection: [
            {
              family_name: "Demo font",
              style: "Regular",
              full_name: "Demo font",
            },
            {
              family_name: "Demo font",
              style: "Italic",
              full_name: "Demo font Italic",
            },
          ]
        end

        def extract
          []
        end
      end
    end
  end
end
