# frozen_string_literal: true

module Fontist
  # Single font validation result with timing information.
  class FontValidationResult < Lutaml::Model::Serializable
    attribute :path, :string
    attribute :valid, :boolean, default: -> { false }
    attribute :family_name, :string
    attribute :full_name, :string
    attribute :error_message, :string
    attribute :time_taken, :float, default: -> { 0.0 }
    attribute :file_size, :integer
    attribute :file_mtime, :integer

    key_value do
      map "path", to: :path
      map "valid", to: :valid
      map "family_name", to: :family_name
      map "full_name", to: :full_name
      map "error_message", to: :error_message
      map "time_taken", to: :time_taken
      map "file_size", to: :file_size
      map "file_mtime", to: :file_mtime
    end
  end

  # Validation report with summary statistics and individual results.
  # Exportable to JSON/YAML via Lutaml::Model.
  class ValidationReport < Lutaml::Model::Serializable
    attribute :generated_at, :integer
    attribute :platform, :string
    attribute :total_fonts, :integer, default: -> { 0 }
    attribute :valid_fonts, :integer, default: -> { 0 }
    attribute :invalid_fonts, :integer, default: -> { 0 }
    attribute :total_time, :float, default: -> { 0.0 }
    attribute :avg_time_per_font, :float, default: -> { 0.0 }
    attribute :min_time, :float, default: -> { 0.0 }
    attribute :max_time, :float, default: -> { 0.0 }
    attribute :results, FontValidationResult, collection: true, initialize_empty: true

    key_value do
      map "generated_at", to: :generated_at
      map "platform", to: :platform
      map "total_fonts", to: :total_fonts
      map "valid_fonts", to: :valid_fonts
      map "invalid_fonts", to: :invalid_fonts
      map "total_time", to: :total_time
      map "avg_time_per_font", to: :avg_time_per_font
      map "min_time", to: :min_time
      map "max_time", to: :max_time
      map "results", to: :results
    end

    # Calculate summary statistics from results
    def calculate_summary!
      self.total_fonts = results.size
      self.valid_fonts = results.count { |r| r.valid }
      self.invalid_fonts = total_fonts - valid_fonts

      times = results.map(&:time_taken).compact
      self.total_time = times.sum
      self.avg_time_per_font = times.empty? ? 0.0 : (total_time / times.size)
      self.min_time = times.min || 0.0
      self.max_time = times.max || 0.0

      self
    end

    # Get only invalid results
    def invalid_results
      results.reject { |r| r.valid }
    end

    # Get only valid results
    def valid_results
      results.select { |r| r.valid }
    end
  end

  # Validation cache for storing/reusing validation results.
  # Uses file metadata for automatic cache invalidation.
  # Persisted to disk for fast subsequent validation runs.
  class ValidationCache < Lutaml::Model::Serializable
    attribute :generated_at, :integer
    attribute :entries, FontValidationResult, collection: true, initialize_empty: true

    key_value do
      map "generated_at", to: :generated_at
      map "entries", to: :entries
    end

    # Build lookup hash for fast O(1) access by path (non-shared state)
    def to_lookup
      entries.index_by(&:path)
    end

    # Get validation result for a path, checking if file has changed
    def get(path)
      return nil unless File.exist?(path)

      stat = File.stat(path)

      entries.find do |entry|
        next unless entry.path == path

        # Check if file has changed since caching
        entry.file_size == stat.size && entry.file_mtime == stat.mtime.to_i
      end
    end

    # Add or update a validation result
    def set(result)
      # Remove existing entry for same path
      @entries = entries.reject { |e| e.path == result.path }
      @entries << result
      @generated_at = Time.now.to_i
      self
    end

    # Check if cache is stale (older than 24 hours)
    def stale?
      return true if @generated_at.nil?

      (Time.now.to_i - @generated_at) > (24 * 60 * 60)
    end
  end
end
