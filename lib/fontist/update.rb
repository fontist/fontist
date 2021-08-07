module Fontist
  class Update
    VERSION = "v2".freeze

    def self.call
      new(VERSION).call
    end

    def initialize(branch = "main")
      @branch = branch
    end

    def call
      update_main_repo
      update_private_repos
    ensure
      rebuild_index
    end

    private

    def update_main_repo
      dir = File.dirname(Fontist.formulas_repo_path)
      FileUtils.mkdir_p(dir) unless File.exist?(dir)

      unless Dir.exist?(Fontist.formulas_repo_path)
        return Git.clone(Fontist.formulas_repo_url,
                         Fontist.formulas_repo_path,
                         branch: @branch,
                         depth: 1)
      end

      git = Git.open(Fontist.formulas_repo_path)
      return git.pull("origin", @branch) if git.current_branch == @branch

      git.config("remote.origin.fetch",
                 "+refs/heads/#{@branch}:refs/remotes/origin/#{@branch}")
      git.fetch
      git.checkout(@branch)
      git.pull("origin", @branch)
    end

    def update_private_repos
      private_repos.each do |path|
        update_repo(path)
      end
    end

    def update_repo(path)
      Git.open(path).pull
    rescue Git::GitExecuteError => e
      name = repo_name(path)
      raise Errors::RepoCouldNotBeUpdatedError.new(<<~MSG.chomp)
        Formulas repo '#{name}' could not be updated.
        Please consider reinitializing it with:
          fontist remove #{name}
          fontist setup #{name} REPO_URL

        Git error:
        #{e.message}
      MSG
    end

    def private_repos
      Dir.glob(Fontist.private_formulas_path.join("*")).select do |path|
        File.directory?(path)
      end
    end

    def repo_name(path)
      File.basename(path)
    end

    def rebuild_index
      Index.rebuild
    end
  end
end
