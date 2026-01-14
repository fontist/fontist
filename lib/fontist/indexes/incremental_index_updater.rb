require_relative "directory_snapshot"
require_relative "directory_change"
require_relative "incremental_scanner"

module Fontist
  module Indexes
    # Service for performing incremental index updates
    # Only scans changed files/directories instead of full scans
    class IncrementalIndexUpdater
      SNAPSHOT_TTL = 300 # 5 minutes
      CHANGE_DETECTION_TTL = 60 # 1 minute

      attr_reader :directory_path, :changes

      # Initialize updater for a directory
      def initialize(directory_path)
        @directory_path = directory_path
        @changes = []
      end

      # Perform incremental update
      # Returns: Array of DirectoryChange objects
      def update
        old_snapshot = load_snapshot
        new_snapshot = create_snapshot

        if old_snapshot.nil?
          # First scan - all files are new
          @changes = new_snapshot.files.map do |file|
            DirectoryChange.added(file[:filename], file)
          end
        else
          # Detect changes
          @changes = DirectoryChange.diff(old_snapshot, new_snapshot)
        end

        # Save new snapshot for next time
        save_snapshot(new_snapshot)

        @changes
      end

      # Get list of added files
      def added_files
        @changes.select(&:added?)
      end

      # Get list of modified files
      def modified_files
        @changes.select(&:modified?)
      end

      # Get list of removed files
      def removed_files
        @changes.select(&:removed?)
      end

      # Check if any changes were detected
      def changes?
        @changes.any?
      end

      # Get scan statistics
      def stats
        {
          total_changes: @changes.size,
          added: added_files.size,
          modified: modified_files.size,
          removed: removed_files.size
        }
      end

      private

      # Load previous snapshot from cache
      def load_snapshot
        cached = Fontist::Cache::Manager.get(
          snapshot_cache_key,
          namespace: :indexes
        )
        return nil unless cached

        DirectorySnapshot.from_hash(cached)
      end

      # Create new snapshot by scanning directory
      def create_snapshot
        DirectorySnapshot.create(@directory_path)
      end

      # Save snapshot to cache
      def save_snapshot(snapshot)
        Fontist::Cache::Manager.set(
          snapshot_cache_key,
          snapshot.to_h,
          ttl: SNAPSHOT_TTL,
          namespace: :indexes
        )
      end

      # Generate cache key for this directory's snapshot
      def snapshot_cache_key
        "snapshot:#{@directory_path}"
      end
    end
  end
end
