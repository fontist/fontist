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

    desc "clear-import", "Clear import cache"
    option :verbose, type: :boolean, aliases: :v
    def clear_import
      handle_class_options(options)
      cache_path = Fontist.import_cache_path

      if Dir.exist?(cache_path)
        size = calculate_size(cache_path)
        FileUtils.rm_rf(cache_path)
        Fontist.ui.success("Import cache cleared: #{format_size(size)}")
      else
        Fontist.ui.say("Import cache is already empty")
      end

      CLI::STATUS_SUCCESS
    end

    desc "info", "Show cache information"
    def info
      handle_class_options(options)

      download_cache = cache_info(Fontist.downloads_path)
      import_cache = cache_info(Fontist.import_cache_path)

      Fontist.ui.say("Font download cache:")
      Fontist.ui.say("  Location: #{Fontist.downloads_path}")
      Fontist.ui.say("  Size: #{format_size(download_cache[:size])}")
      Fontist.ui.say("  Files: #{download_cache[:files]}")

      Fontist.ui.say("\nImport cache:")
      Fontist.ui.say("  Location: #{Fontist.import_cache_path}")
      Fontist.ui.say("  Size: #{format_size(import_cache[:size])}")
      Fontist.ui.say("  Files: #{import_cache[:files]}")

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

    def cache_info(path)
      return { size: 0, files: 0 } unless Dir.exist?(path)

      files = Dir.glob(File.join(path, "**", "*")).select { |f| File.file?(f) }
      size = files.sum { |f| File.size(f) }

      { size: size, files: files.count }
    end

    def calculate_size(path)
      return 0 unless Dir.exist?(path)

      files = Dir.glob(File.join(path, "**", "*")).select { |f| File.file?(f) }
      files.sum { |f| File.size(f) }
    end

    def format_size(bytes)
      if bytes < 1024
        "#{bytes} B"
      elsif bytes < 1024 * 1024
        "#{(bytes / 1024.0).round(1)} KB"
      else
        "#{(bytes / (1024.0 * 1024)).round(1)} MB"
      end
    end
  end
end
