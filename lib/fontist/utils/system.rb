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
    end
  end
end
