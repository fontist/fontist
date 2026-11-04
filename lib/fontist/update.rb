module Fontist
  class Update
    def self.call
      new(Fontist.formulas_version).call
    end

    def initialize(branch = "main")
      @branch = branch
    end

    def call
      main_changed = update_main_repo
      private_changed = update_private_repos
    ensure
      # The index is a projection of the corpus: a pull that brought no
      # changes leaves it valid, and a failed pull leaves the corpus
      # untouched. Rebuilding costs a full pass over every formula, so
      # it only runs when some repo actually moved — or when no index
      # exists yet (a fresh clone never had one; lookups self-heal by
      # rebuilding on demand, but an explicit update should leave one
      # behind).
      rebuild_index if main_changed || private_changed || index_missing?
    end

    private

    def index_missing?
      !File.exist?(Fontist.formula_filename_index_path)
    end

    def update_main_repo
      dir = File.dirname(Fontist.formulas_repo_path)
      FileUtils.mkdir_p(dir)

      unless Dir.exist?(Fontist.formulas_repo_path)
        Git.clone(Fontist.formulas_repo_url,
                  Fontist.formulas_repo_path,
                  branch: @branch,
                  depth: 1)
        return true
      end

      git = if Dir.exist?(Fontist.formulas_repo_path.join(".git"))
              Git.open(Fontist.formulas_repo_path)
            else
              Git.init(Fontist.formulas_repo_path.to_s).tap do |g|
                g.remote_add("origin", Fontist.formulas_repo_url)
              end
            end

      if git.current_branch != @branch
        git.config_set("remote.origin.fetch",
                       "+refs/heads/#{@branch}:refs/remotes/origin/#{@branch}")
        git.fetch
        git.checkout(@branch)
        git.pull("origin", @branch)
        return true
      end

      # A freshly init-ed repo has no commits yet; nil before the first
      # pull means "changed", since the pull then creates the corpus
      before = head_sha(git)
      git.pull("origin", @branch)
      head_sha(git) != before
    end

    def update_private_repos
      Repo.list.reduce(false) do |changed, name|
        Repo.update(name, rebuild: false) || changed
      end
    end

    def head_sha(git)
      git.rev_parse("HEAD")
    rescue Git::FailedError, Git::GitError
      nil
    end

    def rebuild_index
      Index.rebuild
    end
  end
end
