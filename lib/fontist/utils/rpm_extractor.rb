module Fontist
  module Utils
    module RpmExtractor
      def rpm_extract(resource)
        file = download_file(resource)

        extract_rpm_file(file)
      end

      private

      def extract_rpm_file(file)
        rpm = rpm_class.new(file)
        content = rpm.payload.read
        path = rpm_target_path(file.path, rpm.tags)
        File.write(path, content, mode: "wb")

        path
      end

      def rpm_class
        @rpm_class ||= begin
                         require "arr-pm"

                         # fix for Ruby 3.0
                         unless RPM::File::Header::HEADER_MAGIC == [0x8eade801, 0x00000000].pack("NN")
                           RPM::File::Header.send(:remove_const, "HEADER_MAGIC")
                           RPM::File::Header.const_set("HEADER_MAGIC", [0x8eade801, 0x00000000].pack("NN"))
                         end

                         RPM::File
                       end
      end

      def rpm_target_path(archive, tags)
        basename = File.basename(archive, ".*")
        archive_format = tags[:payloadformat]
        compression_format = tags[:payloadcompressor] == "gzip" ? "gz" : tags[:payloadcompressor]
        filename = basename + "." + archive_format + "." + compression_format
        File.join(Dir.mktmpdir, filename)
      end
    end
  end
end
