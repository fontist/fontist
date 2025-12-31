require "sys/uname"

module Fontist
  module Utils
    module System
      def self.user_os # rubocop:disable Metrics/MethodLength
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

      def self.user_os_with_version
        "#{user_os}-#{Sys::Uname.release}"
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
        version = macos_version
        return nil unless version

        parsed = parse_macos_version(version)
        return nil unless parsed

        # Font8 is for macOS 26.0+
        return 8 if parsed >= 260000

        # Font7 is for macOS 10.11-15.7
        return 7 if parsed >= 101100 && parsed <= 150700

        # Unknown version range
        nil
      end
    end
  end
end
