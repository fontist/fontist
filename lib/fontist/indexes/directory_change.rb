module Fontist
  module Indexes
    # Value object representing a single change detected in a directory
    # Immutable - describes what changed between two snapshots
    class DirectoryChange
      attr_reader :change_type, :filename, :old_info, :new_info

      # Change types
      ADDED = :added
      MODIFIED = :modified
      REMOVED = :removed
      UNCHANGED = :unchanged

      # Class methods for creating change objects
      class << self
        # Create an added file change
        def added(filename, new_info)
          new(ADDED, filename, nil, new_info)
        end

        # Create a modified file change
        def modified(filename, old_info, new_info)
          new(MODIFIED, filename, old_info, new_info)
        end

        # Create a removed file change
        def removed(filename, old_info)
          new(REMOVED, filename, old_info, nil)
        end

        # Create an unchanged file change
        def unchanged(filename, info)
          new(UNCHANGED, filename, info, info)
        end

        # Compare two snapshots and detect changes
        # Returns: Array of DirectoryChange objects
        def diff(old_snapshot, new_snapshot)
          changes = []

          # Check for added and modified files
          new_snapshot.files.each do |new_file|
            filename = new_file[:filename]
            old_file = old_snapshot.file_info(filename)

            if old_file.nil?
              changes << added(filename, new_file)
            elsif file_modified?(old_file, new_file)
              changes << modified(filename, old_file, new_file)
            end
          end

          # Check for removed files
          old_snapshot.files.each do |old_file|
            filename = old_file[:filename]

            unless new_snapshot.has_file?(filename)
              changes << removed(filename, old_file)
            end
          end

          changes
        end

        private

        # Check if a file was modified based on metadata
        def file_modified?(old_file, new_file)
          old_file[:file_size] != new_file[:file_size] ||
            old_file[:file_mtime] != new_file[:file_mtime] ||
            old_file[:signature] != new_file[:signature]
        end
      end

      # Instance methods
      def initialize(change_type, filename, old_info, new_info)
        @change_type = change_type
        @filename = filename
        @old_info = old_info
        @new_info = new_info
        freeze # Immutable
      end

      # Query methods for change type
      def added?
        @change_type == ADDED
      end

      def modified?
        @change_type == MODIFIED
      end

      def removed?
        @change_type == REMOVED
      end

      def unchanged?
        @change_type == UNCHANGED
      end

      # Convert to hash for serialization
      def to_h
        {
          change_type: @change_type,
          filename: @filename,
          old_info: @old_info,
          new_info: @new_info,
        }
      end
    end
  end
end
