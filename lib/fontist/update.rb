module Fontist
  class Update
    def self.call
      new.call
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

      if Dir.exist?(Fontist.formulas_repo_path)
        Git.open(Fontist.formulas_repo_path).pull
      else
        Utils::Git.clone(Fontist.formulas_repo_url,
                         Fontist.formulas_repo_path,
                         depth: 1)
      end
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
