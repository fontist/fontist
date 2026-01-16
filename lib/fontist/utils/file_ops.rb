require "fileutils"

module Fontist
  module Utils
    module FileOps
      # Safe file/directory deletion with Windows retry logic
      #
      # Windows file locking can cause intermittent failures when deleting
      # files that were recently accessed. This method implements retry logic
      # with exponential backoff to handle these cases gracefully.
      #
      # @param path [String] Path to file or directory to delete
      # @param retries [Integer] Number of retry attempts (default: 3)
      # @return [Boolean] true if deletion succeeded
      # @raise [Errno::EACCES, Errno::ENOTEMPTY] if all retries exhausted
      def self.safe_rm_rf(path, retries: 3)
        return FileUtils.rm_rf(path) unless System.windows?

        # Windows file locking retry with exponential backoff
        retries.times do |attempt|
          FileUtils.rm_rf(path)
          return true
        rescue Errno::EACCES, Errno::ENOTEMPTY
          if attempt < retries - 1
            # Exponential backoff: 0.1s, 0.2s, 0.3s
            sleep(0.1 * (attempt + 1))
            GC.start # Force garbage collection to release file handles
            next
          end
          raise
        end
      end

      # Ensure file handles are released before deletion (Windows-specific)
      #
      # On Windows, file handles may not be immediately released after
      # operations, causing deletion failures. This method ensures cleanup.
      #
      # @param path [String] Path to file or directory
      # @yield Block to execute before cleanup
      def self.with_file_cleanup(_path)
        yield
      ensure
        if System.windows?
          GC.start
          sleep(0.05) # Brief pause to allow handle release
        end
      end

      # Safe file copy with Windows compatibility
      #
      # @param src [String] Source path
      # @param dest [String] Destination path
      # @param options [Hash] Options passed to FileUtils.cp_r
      def self.safe_cp_r(src, dest, **options)
        FileUtils.cp_r(src, dest, **options)
      rescue Errno::EACCES
        if System.windows?
          # Retry once after brief pause on Windows
          sleep(0.1)
          GC.start
          FileUtils.cp_r(src, dest, **options)
        else
          raise
        end
      end

      # Safe directory creation with Windows compatibility
      #
      # @param path [String] Directory path to create
      # @param options [Hash] Options passed to FileUtils.mkdir_p
      def self.safe_mkdir_p(path, **options)
        FileUtils.mkdir_p(path, **options)
      rescue Errno::EACCES
        if System.windows?
          # Retry once after brief pause on Windows
          sleep(0.1)
          FileUtils.mkdir_p(path, **options)
        else
          raise
        end
      end
    end
  end
end
