require "digest"

module Fontist
  module Indexes
    module IncrementalScanner
      # Scan a single directory and return font metadata
      # Returns: Array of hashes with path, filename, file_size, file_mtime, signature
      def self.scan_directory(directory)
        return [] unless Dir.exist?(directory)

        PathScanning.list_font_directory(directory).map do |path|
          scan_font_file(path)
        end
      end

      # Scan a single font file and extract metadata
      # Returns: Hash with path, filename, file_size, file_mtime, signature, format
      def self.scan_font_file(path)
        return nil unless File.exist?(path)

        stat = File.stat(path)

        {
          path: path,
          filename: File.basename(path),
          file_size: stat.size,
          file_mtime: stat.mtime.to_i,
          signature: compute_signature(path),
          format: detect_format(path),
        }
      end

      # Scan with cache - reuse cached metadata if file unchanged
      # Returns: Hash if file exists and unchanged, nil otherwise
      def self.scan_with_cache(path, cached_version)
        return nil unless File.exist?(path)

        current_stat = File.stat(path)

        # Check if file changed
        if cached_version &&
            cached_version[:file_size] == current_stat.size &&
            cached_version[:file_mtime] == current_stat.mtime.to_i
          # Could also check signature here for extra certainty
          return cached_version
        end

        # File changed or no cache - rescan
        scan_font_file(path)
      end

      # Scan multiple font files in batch
      # cache: Optional hash of path => cached_version
      # Returns: Array of font metadata hashes
      def self.scan_batch(paths, cache: {})
        paths.map do |path|
          cached = cache[path]
          if cached
            scan_with_cache(path, cached)
          else
            scan_font_file(path)
          end
        end.compact
      end

      # Compute SHA256 signature of first 1KB for quick change detection
      def self.compute_signature(path)
        return nil unless File.exist?(path)

        # Read first 1KB for fast signature
        header = File.read(path, 1024)
        Digest::SHA256.hexdigest(header)
      end

      # Detect font format from file header
      def self.detect_format(path)
        return :unknown unless File.exist?(path)

        header = File.read(path, 4)

        # Debug output
        # puts "detect_format: path=#{path}, header=#{header.bytes.inspect}"

        case header
        when /^\x00\x01\x00\x00/
          :truetype
        when /^OTTO/
          :opentype
        when /^wOFF/
          :woff
        when /^wOF2/
          :woff2
        else
          :unknown
        end
      end
    end
  end
end
