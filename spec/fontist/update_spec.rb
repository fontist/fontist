require "spec_helper"

RSpec.describe Fontist::Update do
  let(:command) { described_class.new }

  context "no main repo" do
    # before do
    #   if Fontist::Utils::System.user_os == :windows && Dir.exist?("C:/temp/fontist/versions/v4/formulas")
    #     allow_any_instance_of(Git::Base).to receive(:pull).and_return(true)
    #     allow(File).to receive(:exist?).and_return(true)
    #     allow(Dir).to receive(:mktmpdir).and_yield(Pathname.new("C:/temp/fontist"))
    #   end
    # end

    it "creates main repo" do
      fresh_fontist_home do
        puts "pinging 20.207.73.82 with limiting to 2 packets"
        puts system("ping -n 2 20.207.73.82")
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
