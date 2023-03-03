module Fontist
  class CacheCLI < Thor
    include CLI::ClassOptions

    desc "clear", "Clear fontist download cache"
    def clear
      handle_class_options(options)
      dir = Fontist.downloads_path
      dir.each_child(&:delete) if dir.exist?
      Fontist.ui.success("Download cache has been successfully removed.")
      CLI::STATUS_SUCCESS
    end
  end
end
