require "spec_helper"

RSpec.describe Fontist::YamlBackend do
  after do
    ENV.delete("FONTIST_YAML")

    Lutaml::Model::AdapterResolver.set_adapter_class(
      :yaml, Lutaml::Yaml::Adapter::StandardAdapter
    )
  end

  describe ".activate!" do
    it "keeps the standard engine by default" do
      ENV.delete("FONTIST_YAML")

      expect(described_class.activate!).to be_nil
    end

    context "when FONTIST_YAML=yeptris" do
      before do
        skip "yeptris not installed" unless described_class.yeptris_available?
      end

      it "routes model YAML parsing through the yeptris adapter" do
        ENV["FONTIST_YAML"] = "yeptris"

        expect(described_class.activate!)
          .to eq Fontist::Yaml::YeptrisAdapter
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
  end
end
