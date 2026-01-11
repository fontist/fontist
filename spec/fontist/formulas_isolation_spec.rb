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

    it "update should create a new dir", slow: true do
      # Use local repo instead of cloning from internet for speed
      local_test_repo do |repo_path|
        allow(Fontist).to receive(:formulas_repo_url).and_return(repo_path)
        Fontist::Formula.update_formulas_repo

        expect(Fontist.fontist_path.join("versions", "v2", "formulas")).to exist
      end
    end
  end

  context "old version was used, then it changed, updated, and switched back" do
    before { allow(Fontist).to receive(:formulas_version).and_return("master") }
    include_context "fresh home"

    before do
      example_formula("andale.yml")

      allow(Fontist).to receive(:formulas_version).and_return("v2")

      # Use local repo instead of cloning from internet for speed
      local_test_repo do |repo_path|
        allow(Fontist).to receive(:formulas_repo_url).and_return(repo_path)
        Fontist::Formula.update_formulas_repo
      end

      allow(Fontist).to receive(:formulas_version).and_return("master")
    end

    it "does not ask to update and returns formula", slow: true do
      expect(Fontist::Formula.find("andale mono")).to be
    end
  end

  # Helper to create a local test repo for fast Git operations
  def local_test_repo
    Dir.mktmpdir do |dir|
      # Initialize a Git repo with a minimal structure
      git = Git.init(dir)
      git.config("user.name", "Test")
      git.config("user.email", "test@example.com")

      # Create Formulas directory
      formulas_dir = File.join(dir, "Formulas")
      FileUtils.mkdir_p(formulas_dir)
      FileUtils.touch(File.join(formulas_dir, ".keep"))

      git.add("Formulas/.keep")
      git.commit("Initial commit")

      # Create the requested branch
      git.checkout("v2", new_branch: true)

      yield dir
    end
  end
end
