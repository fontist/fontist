require "git"

module Fontist
  module Utils
    class GitRequirement
      def initialize
        if `which git`.empty?
          abort "git is not available. (Or is PATH not setup properly?)"\
            " You must install git."\
            " On macOS it can be installed via `brew install git`."
        end
      end

      def pull(repo_path)
        Git.open(repo_path).pull
      end

      def clone(repo_url, repo_path)
        Git.clone(repo_url, repo_path, depth: 1)
      end
    end
  end
end
