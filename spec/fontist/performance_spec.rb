require "spec_helper"

RSpec.describe "Performance testing" do
  context "manifest with some fonts" do
    it "performs under reasonable time" do
      expect do
        Fontist::Manifest::Install.from_file(
          example_manifest("mscorefonts.yml"),
          confirmation: "yes",
          no_progress: true,
        )
      end.to perform_under(1).sec

      expect do
        Fontist::Manifest::Locations.from_file(
          example_manifest("mscorefonts.yml"),
        )
      end.to perform_under(1).sec
    end
  end
end
