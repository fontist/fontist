module Fontist
  module Utils
    module TarExtractor
      def tar_extract(resource)
        file = @downloaded ? resource : download_file(resource)

        dir = extract_tar_file(file)

        save_fonts(dir)
      end

      private

      def extract_tar_file(file)
        archive_file = File.open(file, "rb")
        dir = Dir.mktmpdir
        tar_reader_class.new(archive_file) do |tar|
          tar.each do |tarfile|
            save_tar_file(tarfile, dir)
          end
        end

        dir
      end

      def tar_reader_class
        @tar_reader_class ||= begin
                            require "rubygems/package"
                            Gem::Package::TarReader
                          end
      end

      def save_tar_file(file, dir)
        path = File.join(dir, file.full_name)

        if file.directory?
          FileUtils.mkdir_p(path)
        else
          File.open(path, "wb") do |f|
            f.print(file.read)
          end
        end
      end

      def save_fonts(dir)
        Array.new.tap do |fonts_paths|
          Dir.glob(File.join(dir, "**/*")).each do |path|
            filename = File.basename(path)
            next unless font_file?(filename)

            target_filename = target_filename(filename)
            font_path = fonts_path.join(target_filename).to_s
            FileUtils.mv(path, font_path)

            fonts_paths << font_path
          end
        end
      end
    end
  end
end
