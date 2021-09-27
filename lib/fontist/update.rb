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
      Repo.list.each do |name|
        Repo.update(name)
      end
    end

    def rebuild_index
      Index.rebuild
    end
  end
end
