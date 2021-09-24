require "spec_helper"

RSpec.describe Fontist::Indexes::FilenameIndex do
  describe "#load_formulas" do
    let(:index) { described_class.from_yaml }

    context "existing filename" do
      let(:command) { index.load_formulas("SourceHanSans-Bold.ttc") }
      before { example_formula("source.yml") }

      it "returns formulas with this font" do
        expect(command.size).to be 1
        expect(command.first.key).to eq "source"
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
