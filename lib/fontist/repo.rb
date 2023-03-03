require "git"

module Fontist
  class Repo
    class << self
      def setup(name, url)
        ensure_private_formulas_path_exists
        fetch_repo(name, url)
        Index.rebuild
      end

      def update(name)
        path = repo_path(name)
        unless Dir.exist?(path)
          raise(Errors::RepoNotFoundError, "No such repo '#{name}'.")
        end

        git = Git.open(path)
        git.pull("origin", git.current_branch)

        Index.rebuild
      rescue Git::GitExecuteError => e
        raise Errors::RepoCouldNotBeUpdatedError.new(<<~MSG.chomp)
          Formulas repo '#{name}' could not be updated.
          Please consider reinitializing it with:
            fontist remove #{name}
            fontist setup #{name} REPO_URL

          Git error:
          #{e.message}
        MSG
      end

      def remove(name)
        path = repo_path(name)
        unless Dir.exist?(path)
          raise(Errors::RepoNotFoundError, "No such repo '#{name}'.")
        end

        FileUtils.rm_r(path)
        Index.rebuild
      end

      def list
        Dir.glob(Fontist.private_formulas_path.join("*"))
          .select { |path| File.directory?(path) }
          .map { |path| File.basename(path) }
      end

      def info(name)
        path = Pathname.new repo_path(name)
        unless path.exist?
          raise(Errors::RepoNotFoundError, "No such repo '#{name}'.")
        end

        formulas = path.glob("*.yml").map do |formula_path|
          formula = Formula.new_from_file(formula_path)
          Struct.new(:name, :description).new(formula.key, formula.description)
        end

        [repo_metadata(path), formulas]
      end

      private

      def ensure_private_formulas_path_exists
        Fontist.private_formulas_path.tap do |path|
          FileUtils.mkdir_p(path) unless Dir.exist?(path)
        end
      end

      def fetch_repo(name, url)
        path = repo_path(name)
        if Dir.exist?(path)
          Git.open(path).pull
        else
          repo = Git.clone(url, path, depth: 1)
          if repo.branches[:main].name != repo.current_branch
            # https://github.com/ruby-git/ruby-git/issues/531
            repo.checkout(:main).pull
          end
        end
      end

      def repo_path(name)
        Fontist.private_formulas_path.join(name)
      end

      def repo_metadata(path)
        repo = Git.open(path)
        log = repo.log
        first = log.first

        {
          url: repo.config["remote.origin.url"],
          revision: first.sha[0..6],
          created: repo.gcommit(log.last.sha).date,
          updated: repo.gcommit(first.sha).date,
          dirty: !repo.status.changed.empty?,
        }
      end
    end
  end
end
