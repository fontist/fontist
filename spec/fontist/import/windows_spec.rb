require "spec_helper"
require "fileutils"

RSpec.describe Fontist::Import::Windows do
  let(:formulas_dir) { Dir.mktmpdir }
  let(:importer) { described_class.new(formulas_dir: formulas_dir) }

  after do
    FileUtils.rm_rf(formulas_dir)
    Fontist::WindowsFodMetadata.reset_cache
  end

  before { Fontist::WindowsFodMetadata.reset_cache }

  describe "#call" do
    it "generates formula files for all capabilities" do
      allow(Fontist).to receive_message_chain(:ui, :say)

      importer.call

      capabilities = Fontist::WindowsFodMetadata.all_capabilities
      yml_files = Dir[File.join(formulas_dir, "*.yml")]

      expect(yml_files.size).to eq(capabilities.size)
    end

    it "generates valid YAML with required keys" do
      allow(Fontist).to receive_message_chain(:ui, :say)

      importer.call

      yml_files = Dir[File.join(formulas_dir, "*.yml")]
      path = yml_files.first
      data = YAML.safe_load(File.read(path))

      expect(data).to have_key("name")
      expect(data).to have_key("platforms")
      expect(data["platforms"]).to eq(["windows"])
      expect(data).to have_key("resources")
      expect(data).to have_key("fonts")
      expect(data).to have_key("import_source")
    end

    it "sets schema_version to 5" do
      allow(Fontist).to receive_message_chain(:ui, :say)

      importer.call

      yml_files = Dir[File.join(formulas_dir, "*.yml")]
      data = YAML.safe_load(File.read(yml_files.first))

      expect(data["schema_version"]).to eq(5)
    end

    it "includes windows_fod source in resources" do
      allow(Fontist).to receive_message_chain(:ui, :say)

      importer.call

      yml_files = Dir[File.join(formulas_dir, "*.yml")]
      path = yml_files.find { |f| f.include?("japanese") } || yml_files.first
      data = YAML.safe_load(File.read(path))
      resources = data["resources"].values.first

      expect(resources["source"]).to eq("windows_fod")
      expect(resources).to have_key("capability_name")
    end

    it "sets import_source type to windows" do
      allow(Fontist).to receive_message_chain(:ui, :say)

      importer.call

      yml_files = Dir[File.join(formulas_dir, "*.yml")]
      data = YAML.safe_load(File.read(yml_files.first))

      expect(data["import_source"]["type"]).to eq("windows")
      expect(data["import_source"]).to have_key("capability_name")
      expect(data["import_source"]["min_windows_version"]).to eq("10.0")
    end
  end
end
