require "spec_helper"

RSpec.describe Fontist::MsVistaFont do
  describe ".fetch_font", api_call: true  do
    it "downloads and returns font path" do
      fonts = Fontist::MsVistaFont.fetch_font("CANDARAI.TTF")

      expect(fonts.count).to eq(1)
      expect(fonts.first).to include("CANDARAI.TTF")
    end
  end
end
