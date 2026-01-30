require "spec_helper"

RSpec.describe Fontist::Update do
  let(:command) { described_class.new }

  context "no main repo" do
    # Skip on Windows due to Git threading/fetch issues in CI environment
    # before do
    #   skip "Git operations not reliable in Windows CI" if Fontist::Utils::System.user_os == :windows
    # end

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
          command.call
        end
      end
    end
  end

  context "main repo changed branch" do
    let(:branch) { "v2" }
    let(:new_file_name) { "new_file.yml" }

    it "fetches changes" do
      fresh_fontist_home do
        fresh_main_repo do |remote_dir|
          git = Git.open(remote_dir)
          git.checkout(branch, new_branch: true)

          create_new_file_in_repo(remote_dir, new_file_name)

          described_class.new(branch).call

          expect(
            Pathname.new(File.join(Fontist.formulas_repo_path, new_file_name)),
          ).to exist
        end
      end
    end
  end

  context "main repo updated on changed branch" do
    let(:branch) { "v2" }
    let(:new_file_name) { "new_file.yml" }

    it "fetches changes" do
      fresh_fontist_home do
        fresh_main_repo(branch) do |remote_dir|
          create_new_file_in_repo(remote_dir, new_file_name)

          described_class.new(branch).call

          expect(
            Pathname.new(File.join(Fontist.formulas_repo_path, new_file_name)),
          ).to exist
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
            command.call

            expect(Fontist::Formula.find("lato")).not_to be nil
          end
        end
      end
    end
  end

  context "private repo's branch is main instead of master" do
    it "runs successfully" do
      fresh_fontist_home do
        fresh_main_repo do
          formula_repo_with("andale.yml") do |dir|
            Fontist::Repo.setup("example", dir)
            command.call
          end
        end
      end
    end
  end

  context "private repo is set up before the main one" do
    it "fetches the main repo" do
      fresh_fontist_home do
        remote_main_repo do |main_repo_url|
          allow(Fontist).to receive(:formulas_repo_url)
            .and_return(main_repo_url)

          formula_repo_with("andale.yml") do |private_repo_url|
            Fontist::Repo.setup("example", private_repo_url)

            command.call
          end
        end
      end
    end
  end
end
