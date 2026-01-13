module Fontist
  module Utils
    module System
      # Platform override from environment (ONLY platform tags supported)
      def self.platform_override
        ENV["FONTIST_PLATFORM_OVERRIDE"]
      end

      def self.platform_override?
        !platform_override.nil?
      end

      # Parse platform override (ONLY platform tag format)
      # Returns: { os: Symbol, framework: Integer } or { os: Symbol } or nil
      def self.parse_platform_override
        override = platform_override
        return nil unless override

        # "macos-font7" => { os: :macos, framework: 7 }
        if match = override.match(/^(macos|linux|windows)-font(\d+)$/)
          return { os: match[1].to_sym, framework: match[2].to_i }
        end

        # "linux" or "windows" => { os: Symbol }
        if override.match?(/^(macos|linux|windows)$/)
          return { os: override.to_sym, framework: nil }
        end

        # Invalid format
        Fontist.ui.error(
          "Invalid FONTIST_PLATFORM_OVERRIDE: #{override}\n" \
          "Supported: 'macos-font<N>', 'linux', 'windows'"
        )
        nil
      end

      def self.user_os # rubocop:disable Metrics/MethodLength
        # Check for platform override first
        if platform_override?
          parsed = parse_platform_override
          return parsed[:os] if parsed
        end

        @user_os ||= begin
          host_os = RbConfig::CONFIG["host_os"]
          case host_os
          when /mswin|msys|mingw|cygwin|bccwin|wince|emc/
            :windows
          when /darwin|mac os/
            :macos
          when /linux/
            :linux
          when /solaris|bsd/
            :unix
          else
            raise Fontist::Error, "unknown os: #{host_os.inspect}"
          end
        end
      end

      # Reset cached values for testing
      # @api private
      def self.reset_cache
        @user_os = nil
        @macos_version = nil
      end

      def self.windows?
        user_os == :windows
      end

      def self.macos?
        user_os == :macos
      end

      def self.linux?
        user_os == :linux
      end

      def self.unix?
        user_os == :unix
      end

      def self.path_separator
        windows? ? "\\" : "/"
      end

      def self.case_sensitive_filesystem?
        ![:windows, :macos].include?(user_os)
      end

      def self.user_os_with_version
        release = if windows?
          # Windows doesn't have uname command
          # Try to extract version from RbConfig or use a placeholder
          RbConfig::CONFIG["host_os"].match(/\d+/)[0] rescue "unknown"
        else
          # Unix-like systems (macOS, Linux, etc.) have uname command
          begin
            `uname -r`.strip
          rescue Errno::ENOENT
            "unknown"
          end
        end

        "#{user_os}-#{release}"
      end

      def self.match?(platform)
        user_os_with_version.start_with?(platform)
      end

      def self.fontconfig_installed?
        Helpers.silence_stream($stderr) do
          !!Helpers.run("fc-cache -V")
        end
      rescue Errno::ENOENT
        false
      end

      def self.macos_version
        # Check for platform override first
        if platform_override?
          parsed = parse_platform_override
          if parsed && parsed[:framework]
            require_relative "../macos_framework_metadata"
            return MacosFrameworkMetadata.min_macos_version(parsed[:framework])
          end
        end

        return nil unless user_os == :macos

        @macos_version ||= begin
          output = Helpers.run("sw_vers -productVersion")
          output&.strip
        rescue Errno::ENOENT
          nil
        end
      end

      def self.parse_macos_version(version_string)
        return nil unless version_string
        return nil if version_string.strip.empty?

        # Parse version string like "10.11.6" or "26.0.0"
        parts = version_string.split(".").map(&:to_i)
        major = parts[0] || 0
        minor = parts[1] || 0
        patch = parts[2] || 0

        # Convert to comparable integer: major * 10000 + minor * 100 + patch
        # This allows: 10.11.6 = 101106, 26.0.0 = 260000
        major * 10000 + minor * 100 + patch
      end

      def self.version_in_range?(min_version, max_version)
        current = macos_version
        return true unless current # Can't determine version, allow installation

        current_parsed = parse_macos_version(current)
        return true unless current_parsed

        # Check minimum version
        if min_version
          min_parsed = parse_macos_version(min_version)
          return false if min_parsed && current_parsed < min_parsed
        end

        # Check maximum version
        if max_version
          max_parsed = parse_macos_version(max_version)
          return false if max_parsed && current_parsed > max_parsed
        end

        true
      end

      def self.catalog_version_for_macos
        # Check for platform override first
        if platform_override?
          parsed = parse_platform_override
          return parsed[:framework] if parsed && parsed[:framework]
        end

        version = macos_version
        return nil unless version

        # Use MacosFrameworkMetadata as single source of truth
        require_relative "../macos_framework_metadata"
        MacosFrameworkMetadata.framework_for_macos(version)
      end
    end
  end
end
