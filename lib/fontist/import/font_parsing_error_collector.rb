module Fontist
  module Import
    # Collects font parsing errors during import for later reporting
    class FontParsingErrorCollector
      attr_reader :errors

      def initialize
        @errors = []
      end

      def add(file_path, error_message, backtrace: nil)
        @errors << {
          path: file_path,
          message: error_message,
          backtrace: backtrace,
        }
      end

      def any?
        @errors.any?
      end

      def count
        @errors.count
      end

      # Group errors by file for cleaner display
      def grouped_errors
        @errors.group_by { |e| File.basename(e[:path]) }
      end
    end
  end
end
