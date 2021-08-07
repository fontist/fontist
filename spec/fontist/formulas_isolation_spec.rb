require "spec_helper"

RSpec.describe "formulas isolation" do
  context "old version was used, then it changed" do
    before { stub_const("Fontist::Update::VERSION", "master") }
    include_context "fresh home"
    before { stub_const("Fontist::Update::VERSION", "v2") }

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
    before { stub_const("Fontist::Update::VERSION", "master") }
    include_context "fresh home"

    before do
      example_formula("andale.yml")

      stub_const("Fontist::Update::VERSION", "v2")
      Fontist::Formula.update_formulas_repo

      stub_const("Fontist::Update::VERSION", "master")
    end

    it "does not ask to update and returns formula" do
      expect(Fontist::Formula.find("andale mono")).to be
    end
  end
end
