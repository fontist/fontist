require "spec_helper"

RSpec.describe Fontist::Formulas do
  describe ".all" do
    it "returns all available font formulas" do
      formulas = Fontist::Formulas.all

      expect(formulas.cleartype.fonts.count).to be > 10
      expect(formulas.cleartype.homepage).to eq("https://www.microsoft.com")
      expect(formulas.cleartype.description).to eq("Microsoft ClearType Fonts")
    end
  end
end
