require "git"
require "paint"

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
        formula = Formula.from_file(formula_path)
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
        path = repo_path(name)

        # Check for duplicate URL across all repos
        existing_repo_with_url = find_repo_by_url(url)
        if existing_repo_with_url && existing_repo_with_url != name
          Fontist.ui.error(Paint["Repository URL already in use by '#{existing_repo_with_url}'", :red])
          Fontist.ui.error(Paint["URL: #{url}", :yellow])
          Fontist.ui.error(Paint["Cannot setup duplicate repository.", :red])
          return false
        end

        if Dir.exist?(path)
          Fontist.ui.say(Paint["Repository '#{name}' already exists at #{path}", :yellow])
          unless Fontist.ui.yes?(Paint["Do you want to overwrite it? [y/N]", :yellow, :bright])
            Fontist.ui.say(Paint["Setup cancelled.", :red])
            return false
          end
          Fontist.ui.say(Paint["Removing existing repository...", :yellow])
          FileUtils.rm_rf(path)
        end

        validate_and_fetch_repo(name, url)
        rebuild_index_if_needed
        true
      rescue StandardError => e
        # Catch all git-related errors
        if e.class.name.include?("Git") || e.message.match?(/git|clone|repository/i)
          handle_git_error(name, url, e, :setup)
        else
          raise
        end
      end

      def update(name)
        path = repo_path(name)
        unless Dir.exist?(path)
          raise(Errors::RepoNotFoundError, "No such repo '#{name}'.")
        end

        git = Git.open(path)
        git.pull("origin", git.current_branch)

        rebuild_index_if_needed
      rescue StandardError => e
        # Catch all git-related errors
        if e.class.name.include?("Git") || e.message.match?(/git|pull|repository/i)
          handle_git_error(name, git.config["remote.origin.url"], e, :update)
        else
          raise
        end
      end

      def remove(name)
        path = repo_path(name)
        unless Dir.exist?(path)
          raise(Errors::RepoNotFoundError, "No such repo '#{name}'.")
        end

        FileUtils.rm_r(path)
        rebuild_index_if_needed
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

      def find_repo_by_url(target_url)
        normalized_target = normalize_git_url(target_url)

        list.each do |repo_name|
          repo_path_obj = repo_path(repo_name)
          next unless Dir.exist?(repo_path_obj)

          begin
            git = Git.open(repo_path_obj)
            existing_url = git.config["remote.origin.url"]
            return repo_name if normalize_git_url(existing_url) == normalized_target
          rescue
            # Skip repos that can't be opened
            next
          end
        end

        nil
      end

      def normalize_git_url(url)
        return "" if url.nil? || url.empty?

        normalized = url.to_s.strip.downcase

        # Remove trailing slashes
        normalized = normalized.sub(%r{/+$}, "")

        # Remove .git extension
        normalized = normalized.sub(/\.git$/, "")

        # Normalize protocol variations
        normalized = normalized.sub(%r{^https?://}, "")
        normalized = normalized.sub(%r{^git@}, "")
        normalized = normalized.sub(%r{^ssh://}, "")
        normalized = normalized.sub(%r{^git://}, "")

        # Normalize git@ style to https style for comparison
        # git@github.com:user/repo -> github.com/user/repo
        normalized = normalized.sub(/:/, "/")

        normalized
      end

      def ensure_private_formulas_path_exists
        Fontist.private_formulas_path.tap do |path|
          FileUtils.mkdir_p(path)
        end
      end

      def validate_and_fetch_repo(name, url)
        # Basic URL validation - allow file paths and standard git URLs
        url_str = url.to_s
        is_valid = url_str.match?(%r{^(https?://|git@|ssh://|git://|file://|/)}) ||
                   File.exist?(url_str) ||
                   File.directory?(url_str)

        unless is_valid
          raise Errors::RepoCouldNotBeUpdatedError.new(
            "Invalid repository URL: #{url}\n" \
            "URL must be a valid git repository URL (http://, https://, git@, ssh://, git://) or a local path"
          )
        end

        fetch_repo(name, url)
      end

      def fetch_repo(name, url)
        path = repo_path(name)
        if Dir.exist?(path)
          Fontist.ui.say(Paint["Updating repository '#{name}'...", :cyan])
          Git.open(path).pull
        else
          Fontist.ui.say(Paint["Cloning repository '#{name}' from #{url}...", :cyan])
          repo = Git.clone(url, path, depth: 1)
          if repo.branches[:main].name != repo.current_branch
            # https://github.com/ruby-git/ruby-git/issues/531
            repo.checkout(:main).pull
          end
          Fontist.ui.say(Paint["Repository '#{name}' cloned successfully.", :green])
        end
      end

      def handle_git_error(name, url, error, operation)
        error_msg = error.message

        # Check for common error patterns
        if error_msg.match?(/could not resolve host|unable to access/i)
          raise Errors::RepoCouldNotBeUpdatedError.new(<<~MSG.chomp)
            Repository URL is not accessible: #{url}

            Please check:
            1. The URL is correct and the repository exists
            2. You have network connectivity
            3. The repository is publicly accessible or you have proper credentials configured

            For private repositories, configure git credentials:
              git config --global credential.helper store

            Git error: #{error_msg}
          MSG
        elsif error_msg.match?(/authentication failed|permission denied|publickey/i)
          raise Errors::RepoCouldNotBeUpdatedError.new(<<~MSG.chomp)
            Authentication failed for repository: #{url}

            This repository requires authentication. Please configure credentials:

            For HTTPS URLs:
              git config --global credential.helper store
              # Then clone manually once to store credentials

            For SSH URLs:
              # Ensure your SSH key is added to ssh-agent:
              ssh-add ~/.ssh/id_rsa
              # And your public key is added to the git service (GitHub, GitLab, etc.)

            Git error: #{error_msg}
          MSG
        elsif error_msg.match?(/repository not found|does not exist/i)
          raise Errors::RepoCouldNotBeUpdatedError.new(<<~MSG.chomp)
            Repository not found: #{url}

            Please verify:
            1. The repository URL is correct
            2. The repository exists and is accessible
            3. You have permission to access this repository

            Git error: #{error_msg}
          MSG
        else
          # Generic error
          action = operation == :setup ? "set up" : "updated"
          raise Errors::RepoCouldNotBeUpdatedError.new(<<~MSG.chomp)
            Formulas repo '#{name}' could not be #{action}.

            Git error: #{error_msg}

            For setup issues, try:
              fontist remove #{name}
              fontist setup #{name} #{url}
          MSG
        end
      end

      def rebuild_index_if_needed
        # Only rebuild formula indexes, not system indexes
        # This is fast as it only processes formula YAML files
        Fontist.ui.say(Paint["Rebuilding formula indexes...", :cyan])
        Index.rebuild
        Fontist.ui.say(Paint["Formula indexes rebuilt.", :green])
      end

      def repo_path(name)
        Fontist.private_formulas_path.join(name)
      end
    end
  end
end
