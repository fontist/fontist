module Fontist
  module Helpers
    def self.url_object(request)
      return request unless request.include?("\"url\"")

      obj = JSON.parse(request.gsub("=>", ":"))
      Struct.new(:url, :headers).new(obj["url"], obj["headers"])
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
      stream.reopen(RbConfig::CONFIG["host_os"] =~ /mswin|mingw/ ? File::NULL : File::NULL) # rubocop:disable Performance/RegexpMatch, Layout/LineLength
      stream.sync = true
      yield
    ensure
      stream.reopen(old_stream)
    end
  end
end
