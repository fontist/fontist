module Fontist
  module Helpers
    def self.parse_to_object(data)
      JSON.parse(data.to_json, object_class: OpenStruct)
    end

    def self.run(command)
      Fontist.ui.debug("Run `#{command}`")

      result = `#{command}`
      unless $CHILD_STATUS.to_i.zero?
        raise Errors::BinaryCallError,
              "Failed to run #{command}, status: #{$CHILD_STATUS}"
      end

      result
    end

    def self.silence_stream(stream)
      old_stream = stream.dup
      stream.reopen(RbConfig::CONFIG["host_os"] =~ /mswin|mingw/ ? "NUL:" : "/dev/null") # rubocop:disable Performance/RegexpMatch, Metrics/LineLength
      stream.sync = true
      yield
    ensure
      stream.reopen(old_stream)
    end
  end
end
