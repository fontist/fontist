require "spec_helper"
require "fontist/cli"

RSpec.describe Fontist::RepoCLI do
  after(:context) do
    restore_default_settings
  end

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

    context "repo already exists and user cancels" do
      before do
        # Set auto_overwrite to false to simulate user cancelling
        @original_auto_overwrite = Fontist.auto_overwrite
        Fontist.auto_overwrite = false
      end

      after do
        Fontist.auto_overwrite = @original_auto_overwrite
      end

      it "does not show success message and returns success status" do
        no_fonts_and_formulas do
          formula_repo_with("tex_gyre_chorus.yml") do |dir|
            Fontist::Repo.setup("acme", dir)

            # Setup again but cancel
            expect(Fontist.ui).to receive(:say).with(include("Repository 'acme' already exists")).ordered
            expect(Fontist.ui).to receive(:say).with(include("Setup cancelled")).ordered
            expect(Fontist.ui).not_to receive(:success)

            status = described_class.start(["setup", "acme", dir])
            expect(status).to be 0
          end
        end
      end
    end

    context "repo already exists and user confirms overwrite" do
      before do
        # Set auto_overwrite to true to simulate user confirming
        @original_auto_overwrite = Fontist.auto_overwrite
        Fontist.auto_overwrite = true
      end

      after do
        Fontist.auto_overwrite = @original_auto_overwrite
      end

      it "shows success message and returns success status" do
        no_fonts_and_formulas do
          formula_repo_with("tex_gyre_chorus.yml") do |dir|
            Fontist::Repo.setup("acme", dir)

            # Setup again with confirmation
            expect(Fontist.ui).to receive(:say).with(include("Repository 'acme' already exists")).ordered
            expect(Fontist.ui).to receive(:say).with(include("Removing existing repository")).ordered
            expect(Fontist.ui).to receive(:success).with(
              "Fontist repo 'acme' from '#{dir}' has been successfully set up.",
            )

            status = described_class.start(["setup", "acme", dir])
            expect(status).to be 0
          end
        end
      end
    end
  end

  describe "#update" do
    context "no such repo" do
      it "prints error message and returns not-found status" do
        fresh_fontist_home do |dir|
          # Stub formulas_repo_path to prevent CLI from finding global main repo
          # This ensures complete isolation for the "no such repo" test
          allow(Fontist).to receive(:formulas_repo_path)
            .and_return(Pathname.new(dir).join("formulas"))

          expect(Fontist.ui).to receive(:error)
            .with("Fontist repo 'acme' is not found.")

          status = described_class.start(["update", "acme"])
          expect(status).to be Fontist::CLI::STATUS_REPO_NOT_FOUND
        end
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

    context "git error during update" do
      it "prints error message and returns update error status" do
        no_fonts_and_formulas do
          formula_repo_with("tex_gyre_chorus.yml") do |dir|
            Fontist::Repo.setup("acme", dir)

            # Simulate git error
            allow_any_instance_of(Git::Base).to receive(:pull).and_raise(
              Git::GitExecuteError, "Unable to fetch"
            )

            expect(Fontist.ui).to receive(:error).with(include("Formulas repo 'acme' could not be updated"))
            expect(Fontist.ui).not_to receive(:success)

            status = described_class.start(["update", "acme"])
            expect(status).to be Fontist::CLI::STATUS_REPO_COULD_NOT_BE_UPDATED
          end
        end
      end
    end
  end

  describe "#remove" do
    context "no such repo" do
      it "prints error message and returns not-found status" do
        fresh_fontist_home do |dir|
          # Stub formulas_repo_path to prevent CLI from finding global main repo
          # This ensures complete isolation for the "no such repo" test
          allow(Fontist).to receive(:formulas_repo_path)
            .and_return(Pathname.new(dir).join("formulas"))

          expect(Fontist.ui).to receive(:error)
            .with("Fontist repo 'acme' is not found.")

          status = described_class.start(["remove", "acme"])
          expect(status).to be Fontist::CLI::STATUS_REPO_NOT_FOUND
        end
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

          expect(Fontist.ui).to receive(:say).with(
            include("Repository info for 'test':")
              .and(include("Found 1 formulas:")),
          )

          status = described_class.start(%w[info test])
          expect(status).to be Fontist::CLI::STATUS_SUCCESS
        end
      end
    end

    it "not exists" do
      expect(Fontist.ui).to receive(:error).with(
        "Fontist repo 'missing-repo' is not found.",
      )
      status = described_class.start(%w[info missing-repo])
      expect(status).to be Fontist::CLI::STATUS_REPO_NOT_FOUND
    end
  end
end
