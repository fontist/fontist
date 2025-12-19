module Fontist
  class RepoCLI < Thor
    include CLI::ClassOptions

    desc "setup NAME URL",
         "Setup a custom fontist repo named NAME for the repository at URL " \
         "and fetches its formulas"
    def setup(name, url)
      handle_class_options(options)
      result = Repo.setup(name, url)

      # setup returns false if user cancelled
      return CLI::STATUS_SUCCESS if result == false

      Fontist.ui.success(
        "Fontist repo '#{name}' from '#{url}' has been successfully set up.",
      )
      CLI::STATUS_SUCCESS
    end

    desc "update NAME", "Update formulas in a fontist repo named NAME"
    def update(name)
      handle_class_options(options)
      Repo.update(name)
      Fontist.ui.success(
        "Fontist repo '#{name}' has been successfully updated.",
      )
      CLI::STATUS_SUCCESS
    rescue Errors::RepoNotFoundError
      handle_repo_not_found(name)
    rescue Errors::RepoCouldNotBeUpdatedError => e
      Fontist.ui.error(e.message)
      CLI::STATUS_REPO_COULD_NOT_BE_UPDATED
    end

    desc "remove NAME", "Remove fontist repo named NAME"
    def remove(name)
      handle_class_options(options)
      Repo.remove(name)
      Fontist.ui.success(
        "Fontist repo '#{name}' has been successfully removed.",
      )
      CLI::STATUS_SUCCESS
    rescue Errors::RepoNotFoundError
      handle_repo_not_found(name)
    end

    desc "list", "List fontist repos"
    def list
      handle_class_options(options)
      Repo.list.each do |name|
        Fontist.ui.say(name)
      end
      CLI::STATUS_SUCCESS
    end

    desc "info NAME", "Information about repos"
    def info(name)
      handle_class_options(options)
      info = Repo.info(name)
      Fontist.ui.say(info.to_s)
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
