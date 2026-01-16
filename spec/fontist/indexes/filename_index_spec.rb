require "spec_helper"

RSpec.describe Fontist::Indexes::FilenameIndex do
  describe "#from_yaml" do
    context "round-trips" do
      let(:filename) do
        File.join(Fontist.fontist_version_path, "filename_index.yml")
      end

      it "round-trips correctly" do
        # Ensure index file exists (will rebuild if missing)
        described_class.from_file
        content = File.read(filename)
        expect(described_class.from_yaml(content).to_yaml).to eq(content)
      end
    end
  end

  describe "#load_formulas" do
    let(:index) { described_class.from_file }

    context "existing filename" do
      let(:command) { index.load_formulas("SourceHanSans-Bold.ttc") }
      before { example_formula("source.yml") }

      it "returns formulas with this font" do
        expect(command.size).to be 1
        expect(command.first.name).to eq "Source"
      end
    end

    context "missing filename" do
      let(:command) { index.load_formulas("missing.otf") }

      it "returns empty array" do
        expect(command.size).to be 0
      end
    end
  end
end
