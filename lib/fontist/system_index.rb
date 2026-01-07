require_relative "font_file"
require_relative "collection_file"
require "paint"

module Fontist
  # Statistics tracking for index building (thread-safe)
  class IndexStats
    attr_reader :cache_hits, :cache_misses, :total_fonts, :start_time,
                :parsed_fonts, :skipped_fonts, :errors, :validation_failures

    def initialize
      @cache_hits = 0
      @cache_misses = 0
      @total_fonts = 0
      @parsed_fonts = 0
      @skipped_fonts = 0
      @errors = 0
      @validation_failures = 0
      @start_time = Time.now
      @mutex = Mutex.new
    end

    def total_fonts=(value)
      @mutex.synchronize { @total_fonts = value }
    end

    def record_cache_hit
      @mutex.synchronize do
        @cache_hits += 1
        @skipped_fonts += 1
      end
    end

    def record_cache_miss
      @mutex.synchronize do
        @cache_misses += 1
        @parsed_fonts += 1
      end
    end

    def record_error
      @mutex.synchronize { @errors += 1 }
    end

    def record_validation_failure
      @mutex.synchronize do
        @validation_failures += 1
        @errors += 1
      end
    end

    def elapsed_time
      Time.now - @start_time
    end

    def avg_time_per_font
      return 0 if @parsed_fonts.zero?

      elapsed_time / @parsed_fonts
    end

    def cache_hit_rate
      return 0 if @total_fonts.zero?

      (@cache_hits.to_f / @total_fonts * 100).round(1)
    end

    def summary
      {
        total_time: elapsed_time.round(2),
        total_fonts: @total_fonts,
        parsed_fonts: @parsed_fonts,
        cached_fonts: @cache_hits,
        errors: @errors,
        validation_failures: @validation_failures,
        cache_hit_rate: "#{cache_hit_rate}%",
        avg_time_per_font: avg_time_per_font.round(4),
      }
    end

    def print_summary(verbose: false)
      return unless verbose

      s = summary
      puts "\n#{Paint['=' * 80, :cyan]}"
      puts Paint["Index Build Statistics:", :cyan, :bright]
      puts Paint["=" * 80, :cyan]
      puts "  Total time:          #{Paint[format('%.2f', s[:total_time]),
                                           :green]} seconds"
      puts "  Total fonts:         #{Paint[s[:total_fonts], :yellow]}"
      puts "  Parsed fonts:        #{Paint[s[:parsed_fonts], :yellow]}"
      puts "  Cached fonts:        #{Paint[s[:cached_fonts], :green]}"
      puts "  Cache hit rate:      #{Paint[s[:cache_hit_rate], :green]}"
      puts "  Errors:              #{Paint[s[:errors],
                                           s[:errors].zero? ? :green : :red]}"
      puts "  Validation failures: #{Paint[s[:validation_failures],
                                           s[:validation_failures].zero? ? :green : :yellow]}"
      puts "  Avg time per font:   #{Paint[format('%.4f', s[:avg_time_per_font]),
                                           :green]} seconds"
      puts Paint["=" * 80, :cyan]
    end
  end

  # {:path=>"/Library/Fonts/Arial Unicode.ttf",
  # :full_name=>"Arial Unicode MS",
  # :family_name=>"Arial Unicode MS",
  # :preferred_family_name=>"Arial",
  # :preferred_subfamily_name=>"Regular",
  # :subfamily=>"Regular"},
  class SystemIndexFont < Lutaml::Model::Serializable
    attribute :path, :string
    attribute :full_name, :string
    attribute :family_name, :string
    attribute :preferred_family_name, :string
    attribute :preferred_subfamily_name, :string
    attribute :subfamily, :string

    # File metadata for smart caching
    attribute :file_size, :integer
    attribute :file_mtime, :integer

    alias :type :subfamily

    key_value do
      map "path", to: :path
      map "full_name", to: :full_name
      map "family_name", to: :family_name
      map "type", to: :subfamily
      map "preferred_family_name", to: :preferred_family_name
      map "preferred_subfamily_name", to: :preferred_subfamily_name
      map "file_size", to: :file_size
      map "file_mtime", to: :file_mtime
    end
  end

  class SystemIndexFontCollection < Lutaml::Model::Collection
    include Utils::Locking

    instances :fonts, SystemIndexFont
    attr_accessor :path, :paths_loader

    # Metadata for smart change detection
    attribute :last_scan_time, :integer, default: -> { 0 }
    attribute :directory_mtimes, :string, collection: true, default: -> { [] }

    key_value do
      map_instances to: :fonts
      map "last_scan_time", to: :last_scan_time
      map "directory_mtimes", to: :directory_mtimes
    end

    # Don't rebuild index more frequently than this (in seconds)
    INDEX_REBUILD_THRESHOLD = 30 * 60 # 30 minutes

    def set_path(path)
      @path = path
    end

    def set_path_loader(paths_loader)
      @paths_loader = paths_loader
    end

    def self.from_file(path:, paths_loader:)
      # If the file does not exist, return a new collection
      return new.set_content(path, paths_loader) unless File.exist?(path)

      from_yaml(File.read(path)).set_content(path, paths_loader)
    end

    def set_content(path, paths_loader)
      tap do |content|
        content.set_path(path)
        content.set_path_loader(paths_loader)
      end
    end

    ALLOWED_KEYS = %i[path full_name family_name type].freeze

    # Optional metadata keys for optimization (not required for validity)
    OPTIONAL_KEYS = %i[file_size file_mtime].freeze

    # Check if the content has all required keys
    def check_index
      Fontist.formulas_repo_path_exists!

      Array(fonts).each do |font|
        missing_keys = ALLOWED_KEYS.reject do |key|
          font.send(key)
        end

        raise_font_index_corrupted(font, missing_keys) if missing_keys.any?
      end
    end

    def to_file(path)
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, to_yaml)
    end

    def find(font, style)
      current_fonts = index

      return nil if current_fonts.nil? || current_fonts.empty?

      if style.nil?
        found_fonts = current_fonts.select do |file|
          file.family_name&.casecmp?(font)
        end
      else
        found_fonts = current_fonts.select do |file|
          file.family_name&.casecmp?(font) && file.type&.casecmp?(style)
        end
      end

      found_fonts.empty? ? nil : found_fonts
    end

    def index
      # Fast path: if read_only mode is set, skip index_changed? check entirely
      # But we still need to build if fonts is nil (first time access)
      if @read_only_mode && !fonts.nil?
        return fonts
        # Fall through to build the index on first access
      end

      return fonts unless index_changed?

      # Notify user about index rebuild for large collections
      paths = @paths_loader&.call || []
      if (paths.size > 100) && !@verbose
        Fontist.ui.say("Building font index (#{paths.size} fonts found, this may take a while...)")
      end

      build
      check_index

      fonts
    end

    # Enable read-only mode for operations that don't need index rebuilding
    # This is used during manifest compilation to avoid expensive index checks
    def read_only_mode
      @read_only_mode = true
      self
    end

    def index_changed?
      return true if fonts.nil? || fonts.empty?
      return false if @index_check_done # Skip if already verified in this session

      # Quick check: if index was scanned recently, trust it
      if recently_scanned?
        Fontist.ui.debug("System index scanned #{time_since_scan} seconds ago, skipping check")
        @index_check_done = true
        return false
      end

      # Quick check: if directories haven't changed, trust the index
      if directories_unchanged?
        Fontist.ui.debug("Font directories unchanged, skipping full scan")
        @index_check_done = true
        # Update last scan time to extend validity
        self.last_scan_time = Time.now.to_i
        save_metadata
        return false
      end

      # At this point we need to do a full scan
      Fontist.ui.debug("Font directories changed or stale, performing full scan")

      # Cache the paths loader results to avoid repeated Dir.glob calls
      @cached_current_paths ||= @paths_loader&.call&.sort&.uniq || []

      excluded_paths_in_current = @cached_current_paths.select do |path|
        excluded?(path)
      end

      changed = @cached_current_paths != (font_paths + excluded_paths_in_current).uniq.sort

      # Mark as verified if unchanged, so we don't check again in this session
      @index_check_done = true unless changed

      changed
    end

    # Mark this index as verified, skipping future index_changed? checks
    # Used after successfully loading the index from file
    def mark_verified!
      @index_check_done = true
      self
    end

    # Reset verification flag (for testing or forcing re-check)
    def reset_verification!
      @index_check_done = false
      @cached_current_paths = nil
      self
    end

    def update
      tap do |col|
        col.fonts = detect_paths(@paths_loader&.call || [])
      end
    end

    def update(verbose: false, stats: nil)
      tap do |col|
        col.fonts = detect_paths(@paths_loader&.call || [], verbose: verbose,
                                                            stats: stats)
      end
    end

    def build(forced: false, verbose: false, stats: nil)
      if forced
        return rebuild_with_lock(verbose: verbose, stats: stats)
      end

      previous_index = load_index
      updated_fonts = update

      if changed?(updated_fonts, previous_index.fonts || [])
        # Store the updated fonts so we don't need to call update again
        @pending_fonts = updated_fonts.fonts
        rebuild_with_lock(verbose: verbose, stats: stats)
      end

      self
    end

    def rebuild(verbose: false, stats: nil)
      build(forced: true, verbose: verbose, stats: stats)
    end

    private

    def rebuild_with_lock(verbose: false, stats: nil)
      # Use file locking to prevent concurrent rebuilds across processes
      lock_path = index_lock_path
      start_time = Time.now

      lock(lock_path) do
        # Re-check if another process already rebuilt while we waited for lock
        if File.exist?(@path)
          existing = self.class.from_file(path: @path,
                                          paths_loader: @paths_loader)

          # If recently rebuilt by another process, use that instead
          if existing.last_scan_time &&
              (Time.now.to_i - existing.last_scan_time.to_i) < 60
            Fontist.ui.debug("Index recently rebuilt by another process, using existing")
            self.fonts = existing.fonts
            self.last_scan_time = existing.last_scan_time
            self.directory_mtimes = existing.directory_mtimes
            @pending_fonts = nil
            return self
          end
        end

        # Use pending fonts if available (from build), otherwise update with verbose
        if @pending_fonts
          self.fonts = @pending_fonts
          @pending_fonts = nil
        else
          updated_fonts = update(verbose: verbose, stats: stats)
          self.fonts = updated_fonts.fonts
        end

        self.last_scan_time = Time.now.to_i
        self.directory_mtimes = scan_directory_mtimes.map { |k, v| "#{k}:#{v}" }
        to_file(@path)

        # Show completion message for large collections
        elapsed = Time.now - start_time
        font_count = fonts&.size || 0
        if font_count > 100
          Fontist.ui.say("Font index built: #{font_count} fonts indexed in #{elapsed.round(1)}s")
        end
      end

      self
    end

    def index_lock_path
      "#{@path}.lock"
    end

    def load_index
      index = self.class.from_file(path: @path, paths_loader: @paths_loader)
      index.check_index
      index
    end

    def font_paths
      fonts.map(&:path).uniq.sort
    end

    def changed?(this_fonts, that_fonts)
      this_fonts.map(&:path).uniq.sort != that_fonts.map(&:path).uniq.sort
    end

    def recently_scanned?
      return false unless last_scan_time

      time_since_scan < INDEX_REBUILD_THRESHOLD
    end

    def time_since_scan
      Time.now.to_i - last_scan_time.to_i
    end

    def directories_unchanged?
      current_mtimes = scan_directory_mtimes
      stored_mtimes = parse_directory_mtimes

      return false if stored_mtimes.empty?

      current_mtimes == stored_mtimes
    end

    def scan_directory_mtimes
      dirs = extract_font_directories
      dirs.map { |dir| [dir, directory_mtime(dir)] }.to_h
    end

    def directory_mtime(dir)
      return 0 unless File.directory?(dir)

      File.mtime(dir).to_i
    rescue Errno::ENOENT, Errno::EACCES
      0
    end

    def extract_font_directories
      # Extract base directories from the paths that will be globbed
      # This uses the actual system configuration it will scan
      require_relative "system_font"

      os = Fontist::Utils::System.user_os.to_s
      templates = SystemFont.system_config["system"][os]["paths"]

      # Extract directory part before wildcards
      base_dirs = templates.map do |pattern|
        # Remove glob patterns to get base directory
        pattern.split("/*").first
      end.compact.uniq

      # Add fontist fonts directory
      base_dirs << Fontist.fonts_path.to_s

      base_dirs
    end

    def parse_directory_mtimes
      return {} unless directory_mtimes

      Hash[directory_mtimes.map do |entry|
        dir, mtime = entry.split(":", 2)
        [dir, mtime.to_i]
      end]
    end

    def save_metadata
      return unless @path

      # Update metadata
      self.last_scan_time = Time.now.to_i
      self.directory_mtimes = scan_directory_mtimes.map { |k, v| "#{k}:#{v}" }

      # Save to file
      to_file(@path)
    end

    def detect_paths(paths, verbose: false, stats: nil, parallel: true)
      existing_fonts_by_path = fonts&.group_by(&:path) || {}

      # Initialize stats if not provided
      stats ||= IndexStats.new if verbose
      stats.total_fonts = paths.size if stats

      sorted_paths = paths.sort.uniq

      # Disable parallel processing on Windows due to fontisan's internal tempfile GC issues
      # Windows file locking prevents deletion of recently-accessed files, causing
      # EACCES errors when fontisan's checksum calculator creates tempfiles that get GC'd
      # See: https://github.com/fontist/fontist/issues/xxx
      is_windows = Fontist::Utils::System.user_os == :windows

      # Decide whether to use parallel processing
      use_parallel = parallel && sorted_paths.size > 100 && !is_windows

      if use_parallel
        process_paths_parallel(sorted_paths, existing_fonts_by_path,
                               verbose: verbose, stats: stats)
      else
        process_paths_sequential(sorted_paths, existing_fonts_by_path,
                                 verbose: verbose, stats: stats)
      end
    end

    def process_paths_parallel(sorted_paths, existing_fonts_by_path, verbose:,
stats:)
      require "parallel"

      # Auto-detect cores, cap at 8 for optimal I/O performance
      num_cores = [Parallel.processor_count, 8].min

      if verbose
        puts Paint["Using parallel processing with #{num_cores} cores",
                   :cyan]
      end

      # Thread-safe progress tracking
      progress_mutex = Mutex.new
      processed_count = 0
      spinner_chars = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"]

      # Show minimal progress for large collections even in non-verbose mode
      show_minimal_progress = !verbose && sorted_paths.size > 100
      progress_interval = sorted_paths.size > 1000 ? 100 : 50

      results = Parallel.map(sorted_paths, in_threads: num_cores) do |path|
        cached = existing_fonts_by_path[path]
        result = detect_font_with_cache(path, cached, stats: stats)

        # Update progress (thread-safe)
        progress_mutex.synchronize do
          processed_count += 1
          if verbose && stats
            display_progress(processed_count, sorted_paths.size, path,
                             spinner_chars)
          elsif show_minimal_progress && ((processed_count % progress_interval).zero? || processed_count == sorted_paths.size)
            # Show minimal progress every N fonts or at the end
            Fontist.ui.say("Scanning fonts: #{processed_count}/#{sorted_paths.size}...")
          end
        end

        result
      end.flatten.compact

      clear_progress_line if verbose
      results
    end

    def process_paths_sequential(sorted_paths, existing_fonts_by_path,
verbose:, stats:)
      spinner_chars = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"]
      spinner_index = 0

      # Show minimal progress for large collections even in non-verbose mode
      show_minimal_progress = !verbose && sorted_paths.size > 100
      progress_interval = sorted_paths.size > 1000 ? 100 : 50

      results = sorted_paths.flat_map.with_index do |path, index|
        if verbose && stats
          display_progress(index + 1, sorted_paths.size, path, spinner_chars,
                           spinner_index)
        elsif show_minimal_progress && (((index + 1) % progress_interval).zero? || index == sorted_paths.size - 1)
          # Show minimal progress every N fonts or at the end
          Fontist.ui.say("Scanning fonts: #{index + 1}/#{sorted_paths.size}...")
        end
        spinner_index += 1

        cached = existing_fonts_by_path[path]
        detect_font_with_cache(path, cached, stats: stats)
      end.compact

      clear_progress_line if verbose
      results
    end

    def detect_font_with_cache(path, cached, stats:)
      # Fast path: reuse cached metadata if file unchanged
      if cached&.any? && file_unchanged?(path, cached.first)
        stats&.record_cache_hit
        cached
      else
        # Slow path: parse font file
        stats&.record_cache_miss
        detect_fonts(path, stats: stats)
      end
    end

    def display_progress(current, total, path, spinner_chars,
spinner_index = nil)
      spinner_index ||= (current / 10) % spinner_chars.length
      spinner = spinner_chars[spinner_index % spinner_chars.length]

      display_path = path
      max_path_len = 60
      if display_path.length > max_path_len
        display_path = "...#{display_path[-max_path_len..]}"
      end

      progress = "#{current}/#{total}"
      print "\r#{Paint[spinner,
                       :cyan]} #{Paint[progress,
                                       :yellow]} #{Paint[display_path, :white]}"
      print " " * [0, 80 - display_path.length - progress.length - 3].max
      $stdout.flush
    end

    def clear_progress_line
      print "\r#{' ' * 80}\r"
    end

    def file_unchanged?(path, cached_font)
      return false unless File.exist?(path)
      return false unless cached_font.file_size && cached_font.file_mtime

      current_size = File.size(path)
      current_mtime = File.mtime(path).to_i

      cached_font.file_size == current_size &&
        cached_font.file_mtime == current_mtime
    rescue Errno::ENOENT, Errno::EACCES
      false
    end

    def detect_fonts(path, stats: nil)
      return if excluded?(path)

      gather_fonts(path)
    rescue Errors::FontFileError => e
      # Check if this is a validation failure
      if e.message.include?("indexability validation")
        stats&.record_validation_failure
        print_validation_error(e, path)
      else
        stats&.record_error
        print_recognition_error(e, path)
      end
    end

    def excluded?(path)
      excluded_fonts.include?(File.basename(path))
    end

    def excluded_fonts
      @excluded_fonts ||= YAML.load_file(Fontist.excluded_fonts_path)
    end

    def gather_fonts(path)
      case File.extname(path).gsub(/^\./, "").downcase
      when "ttf", "otf"
        detect_file_font(path)
      when "ttc"
        detect_collection_fonts(path)
      else
        print_recognition_error(Errors::UnknownFontTypeError.new(path), path)
      end
    end

    def print_validation_error(exception, path)
      Fontist.ui.debug(<<~MSG.chomp)
        Skipping corrupt/invalid font: #{File.basename(path)}
        Validation failed: #{exception.message}
      MSG
      nil
    end

    def print_recognition_error(exception, path)
      Fontist.ui.error(<<~MSG.chomp)
        #{exception.inspect}
        Warning: File at #{path} not recognized as a font file.
      MSG
      nil
    end

    def detect_file_font(path)
      font_file = FontFile.from_path(path)

      parse_font(font_file, path)
    end

    def detect_collection_fonts(path)
      CollectionFile.from_path(path) do |collection|
        collection.map do |font_file|
          parse_font(font_file, path)
        end
      end
    end

    def parse_font(font_file, path)
      # Skip fonts with incomplete metadata
      return nil unless font_file.full_name && font_file.family

      # Get file metadata for caching
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

      SystemIndexFont.new(
        path: path,
        full_name: font_file.full_name,
        family_name: font_file.family,
        subfamily: font_file.subfamily,
        preferred_family_name: font_file.preferred_family_name,
        preferred_subfamily_name: font_file.preferred_subfamily_name,
        file_size: file_size,
        file_mtime: file_mtime,
      )
    end

    def filter_valid_fonts(fonts)
      fonts.select do |font|
        missing_keys = ALLOWED_KEYS.reject { |key| font.send(key) }

        next true if missing_keys.empty?

        warn_font_metadata_incomplete(font, missing_keys)
      end
    end

    def warn_font_metadata_incomplete(font, missing_keys)
      Fontist.ui.error(<<~MSG.chomp)
        Skipping font with incomplete metadata: #{font.path}
        Missing attributes: #{missing_keys.join(', ')}.
        This font will not be indexed, but Fontist will continue to work.
      MSG
    end

    def raise_font_index_corrupted(font, missing_keys)
      raise(Errors::FontIndexCorrupted, <<~MSG.chomp)
        Font index is corrupted.
        Item #{font.inspect} misses required attributes: #{missing_keys.join(', ')}.
        You can remove the index file (#{@path}) and try again.
      MSG
    end
  end

  class SystemIndex
    include Utils::Locking

    def self.system_index
      current_path = Fontist.system_index_path
      return @system_index if !@system_index.nil? && @system_index_path == current_path

      @system_index_path = current_path
      @system_index = SystemIndexFontCollection.from_file(
        path: current_path,
        paths_loader: -> { SystemFont.font_paths },
      )

      # Validate the index before marking as verified
      if File.exist?(current_path)
        @system_index.check_index
        @system_index.mark_verified!
      end

      @system_index
    end

    def self.fontist_index
      current_path = Fontist.fontist_index_path
      return @fontist_index if !@fontist_index.nil? && @fontist_index_path == current_path

      @fontist_index_path = current_path
      @fontist_index = SystemIndexFontCollection.from_file(
        path: current_path,
        paths_loader: -> { SystemFont.fontist_font_paths },
      )

      # Validate the index before marking as verified
      if File.exist?(current_path)
        @fontist_index.check_index
        @fontist_index.mark_verified!
      end

      @fontist_index
    end

    # Reset cached indexes (useful for testing)
    def self.reset_cache
      @system_index = nil
      @system_index_path = nil
      @fontist_index = nil
      @fontist_index_path = nil
    end

    # Rebuild the system font index
    # Called after installing fonts to system directories (e.g., apple_cdn)
    def self.rebuild(verbose: false)
      system_index.rebuild(verbose: verbose)
      Fontist.ui.success("System font index rebuilt successfully.") if verbose
    end

    # def build_index
    #   lock(lock_path) do
    #     do_build_index
    #   end
    # end

    # def lock_path
    #   Utils::Cache.lock_path(@index_path)
    # end
  end
end
