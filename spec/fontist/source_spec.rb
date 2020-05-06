require "spec_helper"

RSpec.describe Fontist::Source do
  describe ".all" do
    it "returns all of the dataset" do
      sources = Fontist::Source.all

      expect(sources.system.linux.paths).not_to be_nil
      expect(sources.system.macosx.paths).not_to be_nil
      expect(sources.system.windows.paths).not_to be_nil
      expect(sources.remote.formulas.first).to include("./formulas")
    end
  end

  describe ".formulas" do
    it "returns all available dataset" do
      formulas = Fontist::Source.formulas

      expect(formulas.msvista.license).not_to be_nil
      expect(formulas.msvista.file_size).to eq("62914560")
      expect(formulas.msvista.fonts).to include("CALIBRI.TTF")
    end
  end
end
