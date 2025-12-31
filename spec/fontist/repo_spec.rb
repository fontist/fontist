require "spec_helper"

RSpec.describe Fontist::Repo do
  describe "#setup" do
    it "setups repo and lets find its formulas" do
      no_fonts_and_formulas do
        formula_repo_with("tex_gyre_chorus.yml") do |dir|
          Fontist::Repo.setup("acme", dir)
          expect(Fontist::Formula.find("TeXGyreChorus")).to be
        end
      end
    end

    context "invalid URL" do
      it "raises error with helpful message" do
        no_fonts_and_formulas do
          expect { Fontist::Repo.setup("acme", "invalid-url") }
            .to raise_error(Fontist::Errors::RepoCouldNotBeUpdatedError,
                            /Invalid repository URL/)
        end
      end
    end

    context "non-existent repository" do
      it "raises appropriate error" do
        no_fonts_and_formulas do
          allow(Git).to receive(:clone).and_raise(
            Git::GitExecuteError.new("fatal: repository 'https://github.com/invalid/repo' not found"),
          )

          expect { Fontist::Repo.setup("acme", "https://github.com/invalid/repo") }
            .to raise_error(Fontist::Errors::RepoCouldNotBeUpdatedError)
        end
      end
    end

    context "authentication required" do
      it "raises error with credential configuration instructions" do
        no_fonts_and_formulas do
          allow(Git).to receive(:clone).and_raise(
            Git::GitExecuteError.new("fatal: Authentication failed"),
          )

          expect { Fontist::Repo.setup("acme", "https://github.com/private/repo") }
            .to raise_error(Fontist::Errors::RepoCouldNotBeUpdatedError,
                            /Authentication failed/)
        end
      end
    end

    context "repo already exists" do
      it "prompts for overwrite and cancels when user says no" do
        no_fonts_and_formulas do
          formula_repo_with("tex_gyre_chorus.yml") do |dir|
            Fontist::Repo.setup("acme", dir)

            # Try to setup again
            expect(Fontist.ui).to receive(:say).with(include("Repository 'acme' already exists"))
            expect(Fontist.ui).to receive(:yes?).with(include("Do you want to overwrite it?")).and_return(false)
            expect(Fontist.ui).to receive(:say).with(include("Setup cancelled"))

            result = Fontist::Repo.setup("acme", dir)
            expect(result).to be false
          end
        end
      end

      it "prompts for overwrite and proceeds when user says yes" do
        no_fonts_and_formulas do
          formula_repo_with("tex_gyre_chorus.yml") do |dir|
            Fontist::Repo.setup("acme", dir)

            # Try to setup again with different formula
            formula_repo_with("andale.yml") do |new_dir|
              expect(Fontist.ui).to receive(:say).with(include("Repository 'acme' already exists"))
              expect(Fontist.ui).to receive(:yes?).with(include("Do you want to overwrite it?")).and_return(true)
              expect(Fontist.ui).to receive(:say).with(include("Removing existing repository"))

              result = Fontist::Repo.setup("acme", new_dir)
              expect(result).to be true
              expect(Fontist::Formula.find("Andale Mono")).to be
            end
          end
        end
      end
    end

    context "duplicate URL detection" do
      it "prevents setting up repo with same URL under different name" do
        no_fonts_and_formulas do
          formula_repo_with("tex_gyre_chorus.yml") do |dir|
            # Setup first repo
            Fontist::Repo.setup("acme", dir)

            # Try to setup same URL under different name
            expect(Fontist.ui).to receive(:error).with(include("Repository URL already in use by 'acme'"))
            expect(Fontist.ui).to receive(:error).with(include("URL: #{dir}"))
            expect(Fontist.ui).to receive(:error).with(include("Cannot setup duplicate repository"))

            result = Fontist::Repo.setup("acme-duplicate", dir)
            expect(result).to be false
          end
        end
      end

      it "allows same name with same URL (overwrite scenario)" do
        no_fonts_and_formulas do
          formula_repo_with("tex_gyre_chorus.yml") do |dir|
            # Setup first repo
            Fontist::Repo.setup("acme", dir)

            # Setup same name with same URL should prompt for overwrite
            expect(Fontist.ui).to receive(:say).with(include("Repository 'acme' already exists"))
            expect(Fontist.ui).to receive(:yes?).and_return(true)
            expect(Fontist.ui).to receive(:say).with(include("Removing existing repository"))

            result = Fontist::Repo.setup("acme", dir)
            expect(result).to be true
          end
        end
      end

      it "normalizes URLs correctly for comparison" do
        no_fonts_and_formulas do
          formula_repo_with("tex_gyre_chorus.yml") do |dir|
            # Setup with trailing slash
            dir_with_slash = "#{dir}/"
            Fontist::Repo.setup("acme", dir_with_slash)

            # Try same URL without trailing slash
            expect(Fontist.ui).to receive(:error).with(include("Repository URL already in use"))
            result = Fontist::Repo.setup("acme-dup", dir)
            expect(result).to be false
          end
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
          formula_repo_with("tex_gyre_chorus.yml") do |dir|
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
          formula_repo_with("tex_gyre_chorus.yml") do |dir|
            Fontist::Repo.setup("acme", dir)

            Fontist::Repo.remove("acme")
            expect(Fontist::Formula.find("TeXGyreChorus")).to be_nil
          end
        end
      end
    end
  end

  describe "#list" do
    context "private repo exists" do
      it "returns a list of repo names" do
        fresh_fontist_home do
          formula_repo_with("tex_gyre_chorus.yml") do |repo_dir|
            Fontist::Repo.setup("acme", repo_dir)

            expect(described_class.list).to eq %w[acme]
          end
        end
      end
    end
  end
end
