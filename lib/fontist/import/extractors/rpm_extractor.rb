module Fontist
  module Import
    module Extractors
      class RpmExtractor < Extractor
        def extract
          dir = Dir.mktmpdir
          extract_rpm(@archive, dir)
          dir
        end

        def format
          "rpm"
        end

        private

        def extract_rpm(archive, dir)
          file = File.open(archive, "rb")
          rpm = rpm_class.new(file)
          content = rpm.payload.read
          path = target_path(archive, rpm.tags, dir)

          File.write(path, content)
        ensure
          file.close
        end

        def rpm_class
          @rpm_class ||= begin
                              require "arr-pm"
                              RPM::File
                            end
        end

        def target_path(archive, tags, dir)
          archive_format = tags[:payloadformat]
          compression_format = tags[:payloadcompressor] == "gzip" ? "gz" : tags[:payloadcompressor]
          basename = File.basename(archive, ".*")
          filename = basename + "." + archive_format + "." + compression_format
          File.join(dir, filename)
        end
      end
    end
  end
end
