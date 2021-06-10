require "spec_helper"

RSpec.describe Fontist::Repo do
  describe "#setup" do
    it "setups repo and lets find its formulas" do
      no_fonts_and_formulas do
        formula_repo_with("lato.yml") do |dir|
          Fontist::Repo.setup("acme", dir)
          expect(Fontist::Formula.find("Lato")).to be
        end
      end
    end
  end

  describe "#update" do
    context "no such repo" do
      it "throws not-found error" do
        no_fonts_and_formulas do
          expect { Fontist::Repo.update("non-existent") }
            .to raise_error(Fontist::Errors::RepoNotFoundError)
        end
      end
    end

    context "repo exists" do
      it "updates existing repo and lets find new formulas" do
        no_fonts_and_formulas do
          formula_repo_with("lato.yml") do |dir|
            Fontist::Repo.setup("acme", dir)
            add_to_formula_repo(dir, "andale.yml")

            Fontist::Repo.update("acme")
            expect(Fontist::Formula.find("Andale Mono")).to be
          end
        end
      end
    end
  end

  describe "#remove" do
    context "no such repo" do
      it "throws not-found error" do
        no_fonts_and_formulas do
          expect { Fontist::Repo.remove("non-existent") }
            .to raise_error(Fontist::Errors::RepoNotFoundError)
        end
      end
    end

    context "repo exists" do
      it "removes existing repo, and its formulas cannot be found anymore" do
        no_fonts_and_formulas do
          formula_repo_with("lato.yml") do |dir|
            Fontist::Repo.setup("acme", dir)

            Fontist::Repo.remove("acme")
            expect(Fontist::Formula.find("Lato")).to be_nil
          end
        end
      end
    end
  end
end
