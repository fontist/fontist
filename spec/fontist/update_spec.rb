require "spec_helper"

RSpec.describe Fontist::Update do
  context "no main repo" do
    it "creates main repo" do
      fresh_fontist_home do
        described_class.call
        expect(File.exist?(Fontist.formulas_repo_path)).to be true
      end
    end
  end

  context "main repo exists" do
    it "doesn't fail" do
      fresh_fontist_home do
        fresh_main_repo do
          described_class.call
        end
      end
    end
  end

  context "private repo has new formula" do
    it "makes so fontist can find fonts from the formula" do
      fresh_fontist_home do
        fresh_main_repo do
          formula_repo_with("andale.yml") do |dir|
            Fontist::Repo.setup("acme", dir)
            add_to_formula_repo(dir, "lato.yml")
            described_class.call

            expect(Fontist::Formula.find("lato")).not_to be nil
          end
        end
      end
    end
  end
end
