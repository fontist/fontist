require "spec_helper"

RSpec.describe Fontist::FormulaPicker do
  describe ".call" do
    context "size above the limit, but cached" do
      include_context "fresh home"

      before { example_formula("georgia.yml") }

      let(:formula_path) { Fontist.formulas_path.join("georgia.yml") }
      let(:formula) { Fontist::Formula.new_from_file(formula_path) }

      it "don't raises size-limit error if cached" do
        cache = double

        expect(cache).to receive(:already_fetched?).and_return(true)
        allow(Fontist::Utils::Cache).to receive(:new).and_return(cache)

        picker = Fontist::FormulaPicker.new(
          "Georgia",
          size_limit: 0,
          version: nil,
          smallest: nil,
          newest: nil,
        )
        picker.call([formula])
      end
    end
  end
end
