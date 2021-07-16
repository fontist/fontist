require "spec_helper"

RSpec.describe Fontist::Indexes::FontIndex do
  describe "#load_formulas" do
    let(:index) { described_class.from_yaml }

    context "by font" do
      let(:command) { index.load_formulas("lato") }

      it "returns formulas with this font" do
        expect(command.size).to be 1
        expect(command.first.key).to eq "lato"
      end
    end

    context "by missing font" do
      let(:command) { index.load_formulas("missing") }

      it "returns empty array" do
        expect(command.size).to be 0
      end
    end
  end

  describe ".from_yaml" do
    context "index not found" do
      it "rebuilds index and raises no error" do
        no_formulas do
          FileUtils.rm(Fontist.formula_index_path)

          expect { described_class.from_yaml }.not_to raise_error
        end
      end
    end
  end

  describe ".rebuild" do
    let(:command) { Fontist::Indexes::DefaultFamilyFontIndex.rebuild }
    let(:index) { YAML.load_file(Fontist.formula_index_path) }

    it "builds an index with fonts, styles and a path to a formula" do
      no_formulas do
        example_formula_to("lato.yml", Fontist.formulas_path)

        command
        expect(index).to include("lato" => ["lato.yml"])
      end
    end
  end
end
