module Fontist
  class Downloader
    def initialize(file, file_size: nil, sha: nil, progress: nil)
      @sha = sha
      @file = file
      @progress = progress
      @file_size = (file_size || default_file_size).to_i
    end

    def download
      file = download_file

      if sha && Digest::SHA256.file(file) != sha
        raise(Fontist::Errors::TemparedFileError.new(
          "The downloaded file from #{@file} doesn't " \
          "match with the expected sha256 checksum!"
        ))
      end

      file
    end

    def self.download(file, options = {})
      new(file, options).download
    end

    private

    attr_reader :file, :sha, :file_size

    def default_file_size
      5 * byte_to_megabyte
    end

    def byte_to_megabyte
      @byte_to_megabyte ||= 1024 * 1024
    end

    def download_path
      options[:download_path] || Fontist.root_path.join("tmp")
    end

    def download_file
      bar = ProgressBar.new(file_size / byte_to_megabyte)

      Down.download(
        @file,
        progress_proc: -> (progress) {
          bar.increment(progress / byte_to_megabyte) if @progress === true
        }
      )

    rescue Down::NotFound
      raise(Fontist::Errors::InvalidResourceError.new("Invalid URL: #{@file}"))
    end
  end

  class ProgressBar
    def initialize(total)
      @counter = 1
      @total  = total
    end

    def increment(progress)
      complete = sprintf("%#.2f%%", ((@counter.to_f / @total.to_f) * 100))
      print "\r\e[0KDownloads: #{@counter}MB/#{@total}MB (#{complete})"
      @counter = progress
    end
  end
end
