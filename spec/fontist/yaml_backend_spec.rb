require "spec_helper"

RSpec.describe Fontist::YamlBackend do
  after do
    ENV.delete("FONTIST_YAML")

    Lutaml::Model::AdapterResolver.set_adapter_class(
      :yaml, Lutaml::Yaml::Adapter::StandardAdapter
    )
  end

  describe ".activate!" do
    context "when yeptris is available" do
      before do
        skip "yeptris not installed" unless described_class.yeptris_available?
      end

      it "routes model YAML parsing through the yeptris adapter" do
        ENV.delete("FONTIST_YAML")

        described_class.activate!

        expect(Lutaml::Model::Config.instance.yaml_adapter)
          .to eq Fontist::Yaml::YeptrisAdapter
      end

      it "parses a formula identically to the standard adapter" do
        path = Fontist::Formula.find_by_name("Lato").path
        content = File.read(path)

        expect(Fontist::Yaml::YeptrisAdapter.parse(content))
          .to eq Lutaml::Yaml::Adapter::StandardAdapter.parse(content)
      end
    end

    context "when FONTIST_YAML=psych" do
      it "does not activate" do
        ENV["FONTIST_YAML"] = "psych"

        expect(described_class.activate!).to be_nil
      end
    end
  end
end
