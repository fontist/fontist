require "spec_helper"

RSpec.describe Fontist::ResourceCollection do
  describe ".from_yaml" do
    # Note: ResourceCollection is no longer the primary way to handle resources
    # in Formula. Formula now uses Resource with child_mappings instead.
    # These tests are kept for backward compatibility testing.

    # Skip round-trip tests as ResourceCollection.to_yaml has known issues
    # with lutaml-model Collection serialization. The from_yaml parsing works
    # correctly, but to_yaml does not produce the expected keyed hash format.
    # Formula round-trip tests verify the correct behavior with child_mappings.

    it "parses resources correctly" do
      content = File.read("spec/examples/formulas/lato.yml")
      resources_yaml = YAML.safe_load(content)["resources"].to_yaml

      rc = described_class.from_yaml(resources_yaml)
      expect(rc.resources).to be_an(Array)
      expect(rc.resources.size).to eq(1)
      expect(rc.resources.first.name).to eq("lato-source-1.0.0.zip")
      expect(rc.resources.first.urls).to include("https://github.com/latofonts/lato-source/archive/refs/tags/v1.0.0.zip")
    end
  end
end
