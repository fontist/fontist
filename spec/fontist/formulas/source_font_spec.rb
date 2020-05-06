require "spec_helper"

RSpec.describe Fontist::Formulas::SourceFont do
  describe ".fetch_font" do
    it "downloads and extract out fonts", file_download: true do
      name = "SourceCodePro"
      stub_fontist_path_to_assets

      fonts = Fontist::Formulas::SourceFont.fetch_font(
        name, confirmation: "yes", force_download: true,
      )

      expect(fonts).not_to be_empty
      expect(fonts.first).to include(name)
      expect(Fontist::Finder.find(name)).not_to be_empty
    end
  end
end
