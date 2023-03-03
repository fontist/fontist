module Fontist
  class RepoCLI < Thor
    include CLI::ClassOptions

    desc "setup NAME URL",
         "Setup a custom fontist repo named NAME for the repository at URL " \
         "and fetches its formulas"
    def setup(name, url)
      handle_class_options(options)
      Repo.setup(name, url)
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
      meta, formulas = Repo.info(name)
      Fontist.ui.say("Repository info for '#{name}':")
      meta.each do |key, value|
        Fontist.ui.say("  #{key}: #{value}")
      end
      Fontist.ui.say(formulas.empty? ? "No formulas found" : "Formulas found:")
      formulas.each do |info|
        Fontist.ui.say("- #{info.description} (#{info.name})")
      end
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
