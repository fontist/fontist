require "spec_helper"

RSpec.describe "Performance testing" do
  # This test measures performance of cached operations
  # Pre-cache the webcore RPM on first install
  before(:all) do
    # Pre-install fonts to ensure RPM is cached
    Fontist::Manifest.from_file(
      example_manifest("mscorefonts.yml")
    ).install(confirmation: "yes", no_progress: true)
  end

  context "manifest with some fonts" do
    it "performs under reasonable time with cached downloads" do
      expect do
        Fontist::Manifest.from_file(
          example_manifest("mscorefonts.yml"),
        ).install(confirmation: "yes", no_progress: true)
      end.to perform_under(2).sec

      expect do
        Fontist::Manifest.from_file(
          example_manifest("mscorefonts.yml"),
          locations: true,
        )
      end.to perform_under(2).sec
    end
  end
end
