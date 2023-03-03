require "spec_helper"
require "fontist/cli"

RSpec.describe Fontist::RepoCLI do
  describe "#setup" do
    it "setups repo and lets find its formulas" do
      no_fonts_and_formulas do
        formula_repo_with("tex_gyre_chorus.yml") do |dir|
          expect(Fontist.ui).to receive(:success).with(
            "Fontist repo 'acme' from '#{dir}' has been successfully set up.",
          )

          status = described_class.start(["setup", "acme", dir])
          expect(status).to be 0
        end
      end
    end
  end

  describe "#update" do
    context "no such repo" do
      it "prints error message and returns not-found status" do
        expect(Fontist.ui).to receive(:error)
          .with("Fontist repo 'acme' is not found.")

        status = described_class.start(["update", "acme"])
        expect(status).to be Fontist::CLI::STATUS_REPO_NOT_FOUND
      end
    end

    context "repo exists" do
      it "prints message and returns success status" do
        no_fonts_and_formulas do
          formula_repo_with("tex_gyre_chorus.yml") do |dir|
            Fontist::Repo.setup("acme", dir)

            expect(Fontist.ui).to receive(:success)
              .with("Fontist repo 'acme' has been successfully updated.")
            status = described_class.start(["update", "acme"])
            expect(status).to be 0
          end
        end
      end
    end
  end

  describe "#remove" do
    context "no such repo" do
      it "prints error message and returns not-found status" do
        expect(Fontist.ui).to receive(:error)
          .with("Fontist repo 'acme' is not found.")

        status = described_class.start(["remove", "acme"])
        expect(status).to be Fontist::CLI::STATUS_REPO_NOT_FOUND
      end
    end

    context "repo exists" do
      it "returns success status" do
        no_fonts_and_formulas do
          formula_repo_with("tex_gyre_chorus.yml") do |dir|
            Fontist::Repo.setup("acme", dir)

            expect(Fontist.ui).to receive(:success)
              .with("Fontist repo 'acme' has been successfully removed.")

            status = described_class.start(["remove", "acme"])
            expect(status).to be 0
          end
        end
      end
    end
  end

  describe "#list" do
    context "private repo exists" do
      it "prints its name in a list and returns success status" do
        fresh_fontist_home do
          formula_repo_with("tex_gyre_chorus.yml") do |repo_dir|
            Fontist::Repo.setup("acme", repo_dir)

            expect(Fontist.ui).to receive(:say).with("acme")

            status = described_class.start(["list"])
            expect(status).to be 0
          end
        end
      end
    end
  end

  describe "#info" do
    it "success" do
      fresh_fontist_home do
        formula_repo_with("tex_gyre_chorus.yml") do |repo_dir|
          Fontist::Repo.setup("test", repo_dir)

          expect(Fontist.ui).to receive(:say).with("Repository info for 'test':")
          expect(Fontist.ui).to receive(:say).with("Formulas found:")

          status = described_class.start(%w[info test])
          expect(status).to be Fontist::CLI::STATUS_SUCCESS
        end
      end
    end

    it "not exists" do
      expect(Fontist.ui).to receive(:error).with("Fontist repo 'missing-repo' is not found.")
      status = described_class.start(%w[info missing-repo])
      expect(status).to be Fontist::CLI::STATUS_REPO_NOT_FOUND
    end
  end
end
