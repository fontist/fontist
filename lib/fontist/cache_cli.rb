module Fontist
  class CacheCLI < Thor
    include CLI::ClassOptions

    desc "clear", "Clear fontist cache"
    def clear
      handle_class_options(options)
      dir = Fontist.downloads_path
      dir.each_child(&:rmtree) if dir.exist?
      clear_indexes
      Fontist.ui.success("Cache has been successfully removed.")
      CLI::STATUS_SUCCESS
    end

    private

    def clear_indexes
      delete_file_with_lock(Fontist.system_index_path)
      delete_file_with_lock(Fontist.system_preferred_family_index_path)
    end

    def delete_file_with_lock(path)
      path.delete if path.exist?
      lock_path = Pathname.new Fontist::Utils::Cache.lock_path(path)
      lock_path.delete if lock_path.exist?
    end
  end
end
