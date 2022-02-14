module Fontist
  class FontconfigCLI < Thor
    include CLI::ClassOptions

    desc "update", "Update fontconfig configuration to use fontist fonts"
    def update
      handle_class_options(options)
      Fontconfig.update
      Fontist.ui.success("Fontconfig file has been successfully updated.")
      CLI::STATUS_SUCCESS
    rescue Errors::FontconfigNotFoundError => e
      Fontist.ui.error(e.message)
      CLI::STATUS_FONTCONFIG_NOT_FOUND
    end

    desc "remove", "Remove fontist file in fontconfig configuration"
    option :force, type: :boolean, aliases: :f,
                   desc: "Proceed even if does not exist"
    def remove
      handle_class_options(options)
      Fontconfig.remove(options)
      Fontist.ui.success("Fontconfig file has been successfully removed.")
      CLI::STATUS_SUCCESS
    rescue Errors::FontconfigFileNotFoundError => e
      Fontist.ui.error(e.message)
      CLI::STATUS_FONTCONFIG_FILE_NOT_FOUND
    end
  end
end
