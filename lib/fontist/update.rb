require "git"

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
        puts "Git.clone"
        gh_url = Fontist.formulas_repo_url
        # .gsub(/github\.com/, "140.82.121.4")
        puts gh_url
        puts Fontist.formulas_repo_path
        puts Gem.loaded_specs['Git']&.version&.to_s || 'unknown'
        Gem.loaded_specs.values.map do |spec|
          puts "#{spec.name} (#{spec.version})"
        end
        all_threads = Thread.list
        puts "Available threads:  #{all_threads.count}"
        if ObjectSpace.respond_to?(:each_object)
          count = 0
          ObjectSpace.each_object(IO) do |io|
            unless io.closed?
              count += 1
            end
          rescue ::Exception
            # Handle potential exceptions when accessing IO objects (e.g., in edge cases)
            next
          end
          puts "Number of open Ruby IO objects: #{count}"
        else
          puts "ObjectSpace.each_object is not available in this Ruby environment."
        end
        gitclone = nil
        begin
          gitclone = Git.clone(gh_url,
                         Fontist.formulas_repo_path,
                         branch: @branch,
                         depth: 1)
        rescue Git::FailedError => e
          puts "An error occurred: #{e.message}"
        end
        return gitclone
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
