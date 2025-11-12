module Fontist
  class Update
    def self.call
      new(Fontist.formulas_version).call
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
      FileUtils.mkdir_p(dir)

      unless Dir.exist?(Fontist.formulas_repo_path)
        return Git.clone(Fontist.formulas_repo_url,
                         Fontist.formulas_repo_path,
                         branch: @branch,
                         depth: 1)
      end

      git = if Dir.exist?(Fontist.formulas_repo_path.join(".git"))
              Git.open(Fontist.formulas_repo_path)
            else
              Git.init(Fontist.formulas_repo_path.to_s).tap do |g|
                g.add_remote("origin", Fontist.formulas_repo_url)
              end
            end

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
