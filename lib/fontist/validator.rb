# frozen_string_literal: true

require_relative "validation"
require_relative "system_font"
require "parallel"

module Fontist
  # Parallel font validator using non-shared state principle.
  #
  # Validates fonts in parallel without mutex contention:
  # - Map: Each thread validates independently using read-only cache lookup
  # - Reduce: Results are merged into ValidationReport after completion
  # - Cache is updated after validation completes (no shared writes during validation)
  class Validator
    attr_reader :report

    def initialize
      @report = ValidationReport.new
      @report.platform = platform_name
      @report.generated_at = Time.now.to_i
    end

    # Validate all system fonts in parallel.
    #
    # @param options [Hash] Validation options
    # @option options [Boolean] :parallel Use parallel processing (default: true)
    # @option options [Boolean] :verbose Show detailed progress
    # @option options [ValidationCache] :cache Pre-loaded cache to reuse results
    # @return [ValidationReport] Validation report with timing information
    def validate_all(options = {})
      use_parallel = options.fetch(:parallel, true)
      verbose = options[:verbose]
      cache = options[:cache]

      # Get all font paths
      font_paths = scan_font_paths

      if verbose
        Fontist.ui.say("Found #{font_paths.size} font files to validate")
        if cache
          Fontist.ui.say("Using cache with #{cache.entries.size} entries")
        end
      end

      # Build read-only lookup from cache (non-shared state)
      cache_lookup = cache&.to_lookup || {}

      # Validate in parallel or sequential
      results = if use_parallel && font_paths.size > 10
                  validate_parallel(font_paths, cache_lookup: cache_lookup,
                                                     verbose: verbose)
                else
                  validate_sequential(font_paths, cache_lookup: cache_lookup,
                                                    verbose: verbose)
                end

      @report.results = results
      @report.calculate_summary!

      @report
    end

    # Validate a single font and return result with timing.
    #
    # @param path [String] Font file path
    # @return [FontValidationResult] Validation result
    def validate_single(path)
      start_time = Time.now

      # Get file metadata
      file_size = begin
        File.size(path)
      rescue StandardError
        0
      end
      file_mtime = begin
        File.mtime(path).to_i
      rescue StandardError
        0
      end

      # Validate the font
      font_file = FontFile.from_path(path, validate: true,
                                           check_extension: false)

      time_taken = Time.now - start_time

      FontValidationResult.new(
        path: path,
        valid: true,
        family_name: font_file.family,
        full_name: font_file.full_name,
        time_taken: time_taken.round(4),
        file_size: file_size,
        file_mtime: file_mtime,
      )
    rescue Errors::FontFileError => e
      time_taken = Time.now - start_time

      FontValidationResult.new(
        path: path,
        valid: false,
        error_message: e.message,
        time_taken: time_taken.round(4),
        file_size: file_size,
        file_mtime: file_mtime,
      )
    end

    # Build validation cache in parallel.
    #
    # @param cache_path [String] Path to save/load cache file
    # @param options [Hash] Options
    # @return [ValidationCache] The validation cache
    def build_cache(cache_path, options = {})
      verbose = options[:verbose]

      if verbose
        Fontist.ui.say("Building validation cache...")
      end

      start_time = Time.now

      # Load existing cache (if any) for incremental updates
      cache = load_cache_if_exists(cache_path)

      # Validate using cache (non-shared state during validation)
      validate_all(parallel: true, verbose: verbose, cache: cache)

      # Update cache with new/changed results
      update_cache_from_report(cache, @report.results)

      # Save to file
      save_cache(cache, cache_path)

      elapsed = Time.now - start_time

      if verbose
        Fontist.ui.success("Validation cache built in #{elapsed.round(2)}s")
        Fontist.ui.success("Cached #{cache.entries.size} font validations")
        Fontist.ui.success("Cache saved to: #{cache_path}")
      end

      cache
    end

    # Load validation cache from file.
    #
    # @param cache_path [String] Path to cache file
    # @return [ValidationCache, nil] Loaded cache or nil if not found
    def self.load_cache(cache_path)
      return nil unless File.exist?(cache_path)

      ValidationCache.from_yaml(File.read(cache_path))
    end

    private

    # Validate fonts in parallel using non-shared state.
    # Each thread gets read-only cache_lookup (no shared writes)
    def validate_parallel(font_paths, cache_lookup:, verbose:)
      num_cores = [Parallel.processor_count, 8].min

      if verbose
        Fontist.ui.say("Using parallel processing with #{num_cores} cores")
      end

      # Map: Each thread validates independently (non-shared state)
      # cache_lookup is read-only, no mutex needed
      Parallel.map(font_paths, in_threads: num_cores) do |path|
        validate_with_cache_lookup(path, cache_lookup)
      end.compact
    end

    # Validate fonts sequentially with cache lookup.
    def validate_sequential(font_paths, cache_lookup:, verbose:)
      font_paths.map do |path|
        validate_with_cache_lookup(path, cache_lookup)
      end.compact
    end

    # Validate single font, using cache if available and file unchanged.
    def validate_with_cache_lookup(path, cache_lookup)
      cached = cache_lookup[path]

      # Check if cached result is still valid (file unchanged)
      if cached && file_unchanged?(path, cached)
        # Return cached result without re-validating
        return cached
      end

      # No cache or file changed - validate
      validate_single(path)
    end

    # Check if file has unchanged metadata compared to cached result.
    def file_unchanged?(path, cached_result)
      return false unless File.exist?(path)

      stat = File.stat(path)
      cached_result.file_size == stat.size &&
        cached_result.file_mtime == stat.mtime.to_i
    rescue Errno::ENOENT, Errno::EACCES
      false
    end

    # Update cache with new validation results.
    def update_cache_from_report(cache, new_results)
      cache.generated_at = Time.now.to_i

      new_results.each do |result|
        cache.set(result)
      end

      cache
    end

    # Load cache if file exists and is not stale.
    def load_cache_if_exists(cache_path)
      return nil unless File.exist?(cache_path)

      loaded = self.class.load_cache(cache_path)
      return nil if loaded.nil? || loaded.stale?

      loaded
    end

    # Scan all font paths from system configuration.
    def scan_font_paths
      os = Fontist::Utils::System.user_os.to_s
      templates = SystemFont.system_config["system"][os]["paths"]

      # Expand glob patterns
      system_fonts = templates.flat_map { |pattern| Dir.glob(pattern) }
        .select { |f| File.file?(f) }

      # Add fontist fonts
      fontist_patterns = Fontist::Utils.font_file_patterns(
        Fontist.fonts_path.join("**").to_s,
      )
      fontist_fonts = fontist_patterns.flat_map { |pattern| Dir.glob(pattern) }
        .select { |f| File.file?(f) }

      (system_fonts + fontist_fonts).sort.uniq
    end

    # Get platform name for report.
    def platform_name
      os = Fontist::Utils::System.user_os
      case os
      when :macosx then "macOS"
      when :linux then "Linux"
      when :windows then "Windows"
      else os.to_s.capitalize
      end
    end

    # Save cache to file.
    def save_cache(cache, cache_path)
      FileUtils.mkdir_p(File.dirname(cache_path))
      File.write(cache_path, cache.to_yaml)
    end
  end
end
