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

        Git.open(path).pull
        Index.rebuild
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
          Git.clone(url, path, depth: 1)
        end
      end

      def repo_path(name)
        Fontist.private_formulas_path.join(name)
      end
    end
  end
end
