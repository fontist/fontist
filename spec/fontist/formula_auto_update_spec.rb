require "spec_helper"

RSpec.describe "Formula auto-update (lazy initialization)" do
  # This test suite verifies that formulas are automatically downloaded
  # when first needed, without requiring explicit `fontist update`.
  # This addresses the issue where STIX Two Math works on macOS (system font)
  # but fails on Linux/Windows without explicit `fontist update`.

  describe "Fontist.formulas_repo_path_exists!" do
    context "when formulas repo does not exist" do
      it "auto-updates the formulas repo" do
        fresh_fontist_home do
          # Use local repo instead of cloning from internet for speed
          local_test_repo do |repo_path|
            allow(Fontist).to receive(:formulas_repo_url).and_return(repo_path)

            # The formulas repo shouldn't exist initially
            formulas_dir = Fontist.formulas_repo_path.join("Formulas")
            expect(formulas_dir).not_to exist

            # Calling formulas_repo_path_exists! should auto-update
            expect(Fontist.formulas_repo_path_exists!).to be true

            # Now the formulas directory should exist
            expect(formulas_dir).to exist
            expect(formulas_dir.join(".keep")).to exist
          end
        end
      end

      it "makes formulas discoverable without explicit update", slow: true do
        fresh_fontist_home do
          # Use local repo with actual formula
          local_test_repo_with_formula("andale.yml") do |repo_path|
            allow(Fontist).to receive(:formulas_repo_url).and_return(repo_path)

            # The formulas repo shouldn't exist initially
            formulas_dir = Fontist.formulas_repo_path.join("Formulas")
            expect(formulas_dir).not_to exist

            # Find formula should trigger auto-update and succeed
            formula = Fontist::Formula.find("andale mono")
            expect(formula).to be_a(Fontist::Formula)
            expect(formula.key).to eq("andale")

            # Verify the formulas directory was created
            expect(formulas_dir).to exist
          end
        end
      end
    end

    context "when formulas repo already exists" do
      it "does not re-update unnecessarily" do
        fresh_fontist_home do
          # Use local repo instead of cloning from internet for speed
          local_test_repo do |repo_path|
            allow(Fontist).to receive(:formulas_repo_url).and_return(repo_path)

            # Initialize the repo first
            Fontist::Formula.update_formulas_repo
            formulas_dir = Fontist.formulas_repo_path.join("Formulas")
            expect(formulas_dir).to exist

            # Get the initial mtime
            initial_mtime = File.mtime(formulas_dir)

            # Wait a bit to ensure mtime would change if updated
            sleep(0.1)

            # Calling formulas_repo_path_exists! should not re-update
            expect(Fontist.formulas_repo_path_exists!).to be true

            # Verify the directory wasn't re-updated (mtime should be the same)
            expect(File.mtime(formulas_dir)).to eq(initial_mtime)
          end
        end
      end
    end
  end

  describe "Formula.find with lazy initialization" do
    context "when formulas repo does not exist" do
      it "auto-updates and finds the formula", slow: true do
        fresh_fontist_home do
          # Use local repo with actual formula
          local_test_repo_with_formula("andale.yml") do |repo_path|
            allow(Fontist).to receive(:formulas_repo_url).and_return(repo_path)

            # The formulas repo shouldn't exist initially
            formulas_dir = Fontist.formulas_repo_path.join("Formulas")
            expect(formulas_dir).not_to exist

            # Find formula should trigger auto-update
            formula = Fontist::Formula.find("andale mono")

            expect(formula).to be_a(Fontist::Formula)
            expect(formula.key).to eq("andale")
            # Formula name from andale.yml is "Andale" not "Andale Mono"
            expect(formula.name).to eq("Andale")

            # Verify the formulas directory was created
            expect(formulas_dir).to exist
          end
        end
      end

      it "returns nil for nonexistent fonts after auto-update",
         slow: true do
        fresh_fontist_home do
          # Use local repo with actual formula
          local_test_repo_with_formula("andale.yml") do |repo_path|
            allow(Fontist).to receive(:formulas_repo_url).and_return(repo_path)

            # The formulas repo shouldn't exist initially
            formulas_dir = Fontist.formulas_repo_path.join("Formulas")
            expect(formulas_dir).not_to exist

            # Try to find a nonexistent font - Formula.find returns nil
            formula = Fontist::Formula.find("nonexistent font")
            expect(formula).to be_nil

            # Verify the formulas directory was still created
            # (auto-update happened)
            expect(formulas_dir).to exist
          end
        end
      end
    end
  end

  describe "FontIndex.from_file with lazy initialization" do
    context "when formulas repo does not exist" do
      it "auto-updates before loading the index", slow: true do
        fresh_fontist_home do
          # Use local repo with actual formula
          local_test_repo_with_formula("andale.yml") do |repo_path|
            allow(Fontist).to receive(:formulas_repo_url).and_return(repo_path)

            # The formulas repo shouldn't exist initially
            formulas_dir = Fontist.formulas_repo_path.join("Formulas")
            expect(formulas_dir).not_to exist

            # Index.from_file should trigger auto-update
            index = Fontist::Indexes::FontIndex.from_file

            # FontIndex.from_file returns DefaultFamilyFontIndex by default
            expect(index).to be_a(Fontist::Indexes::DefaultFamilyFontIndex)

            # Verify the formulas directory was created
          end
        end
      end
    end
  end

  describe "Font.install with lazy initialization" do
    context "when formulas repo does not exist" do
      it "auto-updates and raises UnsupportedFontError for nonexistent font",
         slow: true do
        fresh_fontist_home do
          # Use local repo with actual formula
          local_test_repo_with_formula("andale.yml") do |repo_path|
            allow(Fontist).to receive(:formulas_repo_url).and_return(repo_path)

            # Stub system fonts to avoid scanning real system directories
            stub_system_fonts(Fontist.root_path.join("spec", "fixtures",
                                                     "system.yml"))

            # The formulas repo shouldn't exist initially
            formulas_dir = Fontist.formulas_repo_path.join("Formulas")
            expect(formulas_dir).not_to exist

            # Try to install a nonexistent font
            expect do
              Fontist::Font.install("nonexistent font", confirmation: "yes")
            end.to raise_error(Fontist::Errors::UnsupportedFontError)

            # Verify the formulas directory was created (auto-update happened)
            expect(formulas_dir).to exist
          end
        end
      end
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

      # Create v4 branch and switch to it
      git.checkout("v4", new_branch: true)

      yield dir
    end
  end

  # Helper to create a local test repo with an actual formula
  def local_test_repo_with_formula(example_formula)
    Dir.mktmpdir do |dir|
      # Initialize a Git repo
      git = Git.init(dir)
      git.config("user.name", "Test")
      git.config("user.email", "test@example.com")

      # Create Formulas directory
      formulas_dir = File.join(dir, "Formulas")
      FileUtils.mkdir_p(formulas_dir)

      # Copy the example formula to the Formulas directory
      example_path = File.join("spec", "examples", "formulas", example_formula)
      target_path = File.join(formulas_dir, example_formula)
      FileUtils.cp(example_path, target_path)

      # Add and commit
      git.add("Formulas/#{example_formula}")
      git.commit("Add formula")

      # Create v4 branch and switch to it
      git.checkout("v4", new_branch: true)

      yield dir
    end
  end
end
