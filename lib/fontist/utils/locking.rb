module Fontist
  module Utils
    module Locking
      def lock(lock_path)
        File.dirname(lock_path).tap do |dir|
          FileUtils.mkdir_p(dir) unless File.exist?(dir)
        end

        f = File.open(lock_path, File::CREAT)
        f.flock(File::LOCK_EX)
        yield
      ensure
        f.flock(File::LOCK_UN)
        f.close
      end
    end
  end
end
