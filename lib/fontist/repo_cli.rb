module Fontist
  class RepoCLI < Thor
    desc "setup NAME URL",
         "Setup a custom fontist repo named NAME for the repository at URL"
    def setup(name, url)
      Repo.setup(name, url)
      Fontist.ui.success(
        "Fontist repo '#{name}' from '#{url}' has been successfully set up.",
      )
      CLI::STATUS_SUCCESS
    end

    desc "update NAME", "Update formulas in a fontist repo named NAME"
    def update(name)
      Repo.update(name)
      Fontist.ui.success(
        "Fontist repo '#{name}' has been successfully updated.",
      )
      CLI::STATUS_SUCCESS
    rescue Errors::RepoNotFoundError
      handle_repo_not_found(name)
    end

    desc "remove NAME", "Remove fontist repo named NAME"
    def remove(name)
      Repo.remove(name)
      Fontist.ui.success(
        "Fontist repo '#{name}' has been successfully removed.",
      )
      CLI::STATUS_SUCCESS
    rescue Errors::RepoNotFoundError
      handle_repo_not_found(name)
    end

    private

    def handle_repo_not_found(name)
      Fontist.ui.error("Fontist repo '#{name}' is not found.")
      CLI::STATUS_REPO_NOT_FOUND
    end
  end
end
