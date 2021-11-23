require "spec_helper"

RSpec.describe "formulas isolation" do
  context "old version was used, then it changed" do
    before { allow(Fontist).to receive(:formulas_version).and_return("master") }
    include_context "fresh home"
    before { allow(Fontist).to receive(:formulas_version).and_return("v2") }

    it "status should ask to update" do
      expect { Fontist::Formula.find("andale mono") }
        .to raise_error(Fontist::Errors::MainRepoNotFoundError)
    end

    it "update should create a new dir" do
      Fontist::Formula.update_formulas_repo

      expect(Fontist.fontist_path.join("versions", "v2", "formulas")).to exist
    end
  end

  context "old version was used, then it changed, updated, and switched back" do
    before { allow(Fontist).to receive(:formulas_version).and_return("master") }
    include_context "fresh home"

    before do
      example_formula("andale.yml")

      allow(Fontist).to receive(:formulas_version).and_return("v2")
      Fontist::Formula.update_formulas_repo

      allow(Fontist).to receive(:formulas_version).and_return("master")
    end

    it "does not ask to update and returns formula" do
      expect(Fontist::Formula.find("andale mono")).to be
    end
  end
end
