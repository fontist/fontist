require "spec_helper"

RSpec.describe Fontist::Source do
  describe ".all" do
    it "returns all of the dataset" do
      sources = Fontist::Source.all

      expect(sources.system.linux.paths).not_to be_nil
      expect(sources.remote.msvista.file_size).to eq("62914560")
      expect(sources.remote.msvista.fonts).to include("CALIBRI.TTF")
    end
  end
end
