require_relative "incremental_scanner"

module Fontist
  module Indexes
    # Value object representing the state of a directory at a point in time
    # Immutable - returns new instances for state changes
    class DirectorySnapshot
      attr_reader :directory_path, :files, :scanned_at

      # Create a new snapshot by scanning a directory
      # Returns: DirectorySnapshot instance
      def self.create(directory_path)
        directory_path = directory_path.to_s
        files = IncrementalScanner.scan_directory(directory_path)
        new(directory_path, files, Time.now.to_i)
      end

      # Create from existing data (for cache restoration)
      def self.from_hash(hash)
        new(
          hash[:directory_path].to_s,
          hash[:files],
          hash[:scanned_at]
        )
      end

      # Get file info for a specific filename
      # Returns: Hash with file metadata or nil if not found
      def file_info(filename)
        @files_by_filename[filename]
      end

      # Check if snapshot is older than given seconds
      def older_than?(seconds)
        Time.now.to_i - @scanned_at > seconds
      end

      # Check if file exists in snapshot
      def has_file?(filename)
        @files_by_filename.key?(filename)
      end

      # Get count of files in snapshot
      def file_count
        @files.length
      end

      # Convert to hash for serialization
      def to_h
        {
          directory_path: @directory_path,
          files: @files,
          scanned_at: @scanned_at
        }
      end

      private

      def initialize(directory_path, files, scanned_at)
        @directory_path = directory_path
        @files = files.freeze # Immutable
        @files_by_filename = files.each_with_object({}) { |f, h| h[f[:filename]] = f }.freeze
        @scanned_at = scanned_at
      end
    end
  end
end
