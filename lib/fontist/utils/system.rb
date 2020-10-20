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
    end
  end
end
