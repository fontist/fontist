require "spec_helper"

RSpec.describe Fontist::Indexes::DefaultFamilyFontIndex do
  describe "#from_yaml" do
    context "round-trips" do
      let(:filename) do
        File.join(Fontist.fontist_version_path,
                  "formula_index.default_family.yml")
      end

      it "round-trips correctly" do
        # Ensure index file exists (will rebuild if missing)
        index = described_class.from_file(filename)
        content = File.read(filename)
        expect(described_class.from_yaml(content).to_yaml).to eq(content)
      end
    end
  end

  describe "#load_formulas" do
    let(:filename) do
      File.join(Fontist.fontist_version_path,
                "formula_index.default_family.yml")
    end
    let(:index) { described_class.from_file(filename) }

    context "by font" do
      let(:command) { index.load_formulas("lato") }

      it "returns formulas with this font" do
        expect(command.size).to be 1
        expect(command.first.name).to eq "Lato"
      end
    end

    context "by missing font" do
      let(:command) { index.load_formulas("missing") }

      it "returns empty array" do
        expect(command.size).to be 0
      end
    end
  end

  describe ".from_file" do
    context "index not found" do
      it "rebuilds index and raises no error" do
        no_formulas do
          FileUtils.rm(described_class.path)

          expect { described_class.from_file }.not_to raise_error
        end
      end
    end
  end

  describe ".rebuild" do
    let(:command) { described_class.rebuild.to_file }
    let(:index) { YAML.load_file(described_class.path) }

    it "builds an index with fonts, styles and a path to a formula" do
      no_formulas do
        example_formula_to("lato.yml", Fontist.formulas_path)

        command
        expect(index).to include("lato" => ["lato.yml"])
      end
    end
  end
end
