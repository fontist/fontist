require "spec_helper"
require "fontist/cli"

RSpec.describe Fontist::CLI do
  describe "#install" do
    it "installs font by name" do
      stub_fonts_path_to_new_path do
        described_class.start(["install", "overpass"])
        expect(Pathname.new(Fontist.fonts_path.join("overpass-regular.otf"))).to exist
      end
    end
  end
end
