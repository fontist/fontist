module Fontist
  module Utils
    module Locking
      def lock(lock_path)
        File.dirname(lock_path).tap do |dir|
          FileUtils.mkdir_p(dir)
        end

        f = File.open(lock_path, File::CREAT | File::WRONLY)
        raise "Failed to open lock file: #{lock_path}" unless f

        f.flock(File::LOCK_EX)
        yield
      ensure
        f&.flock(File::LOCK_UN)
        f&.close
      end
    end
  end
end
