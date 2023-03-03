require "git"

module Fontist
  class Info
    attr_reader :name, :metadata, :formulas

    def initialize(name, path)
      @name = name
      @metadata = build_metadata(path)
      @formulas = build_formulas(path)
    end

    def to_s
      <<~MSG.chomp
        Repository info for '#{@name}':
        #{@metadata.map { |k, v| "  #{k}: #{v}" }.join("\n")}
        Found #{formulas.count} formulas:
        #{@formulas.map { |info| "- #{info.description} (#{info.name})" }.join("\n")}
      MSG
    end

    private

    def build_metadata(path)
      repo = Git.open(path)

      {
        url: repo.config["remote.origin.url"],
        revision: revision(repo),
        created: created(repo),
        updated: updated(repo),
        dirty: dirty?(repo),
      }
    end

    def build_formulas(path)
      path.glob("*.yml").map do |formula_path|
        formula = Formula.new_from_file(formula_path)
        Struct.new(:name, :description).new(formula.key, formula.description)
      end
    end

    def revision(repo)
      repo.log.first.sha[0..6]
    end

    def created(repo)
      repo.gcommit(repo.log.last.sha).date
    end

    def updated(repo)
      repo.gcommit(repo.log.first.sha).date
    end

    def dirty?(repo)
      !repo.status.changed.empty?
    end
  end

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

        Info.new(name, path)
      end

      private

      def ensure_private_formulas_path_exists
        Fontist.private_formulas_path.tap do |path|
          FileUtils.mkdir_p(path)
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
    end
  end
end
