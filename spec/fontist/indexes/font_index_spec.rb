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

  describe ".rebuild" do
    let(:command) { described_class.rebuild }
    let(:index) { YAML.load_file(Fontist.formula_index_path) }

    before do
      dir = create_tmp_dir
      allow(Fontist).to receive(:formulas_repo_path).and_return(Pathname.new(dir))

      formulas_path = File.join(dir, "Formulas")
      FileUtils.mkdir_p(formulas_path)

      example_formula_to("lato.yml", formulas_path)
    end

    it "builds an index with fonts, styles and a path to a formula" do
      command
      expect(index).to eq("lato" => ["lato.yml"])
    end
  end
end
