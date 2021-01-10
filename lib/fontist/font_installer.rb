require "fontist/utils"

module Fontist
  class FontInstaller
    include Import::Extractors
    include Utils::ZipExtractor
    include Utils::ExeExtractor
    include Utils::MsiExtractor
    include Utils::SevenZipExtractor
    include Utils::RpmExtractor
    include Utils::GzipExtractor
    include Utils::CpioExtractor
    include Utils::TarExtractor

    def initialize(formula)
      @formula = formula
    end

    def install(confirmation:)
      if @formula.license_required && !"yes".casecmp?(confirmation)
        raise(Fontist::Errors::LicensingError)
      end

      reinitialize
      install_font
    end

    private

    attr_reader :formula

    def reinitialize
      @downloaded = false
    end

    def install_font
      fonts_paths = run_in_temp_dir { extract }
      fonts_paths.empty? ? nil : fonts_paths
    end

    def run_in_temp_dir
      Dir.mktmpdir(nil, Dir.tmpdir) do |dir|
        @temp_dir = Pathname.new(dir)

        result = yield

        @temp_dir = nil

        result
      end
    end

    def extract
      resource = @formula.resources.first
      file = download_file(resource)
      operations = [@formula.extract].flatten
      last_operation = operations.pop

      operations.each do |operation|
        extractor = choose_extractor(operation.format)
        dir = extractor.new(file).extract
        file = search_archive(dir)
      end

      extractor = choose_extractor(last_operation.format)
      dir = extractor.new(file).extract
      search_fonts(dir)
    end

      # rubocop:disable Metrics/MethodLength
    def choose_extractor(format)
      case format
      when "msi"
        Extractors::OleExtractor
      when "cab"
        Extractors::CabExtractor
      when "seven_zip"
        Extractors::SevenZipExtractor
      when "zip"
        Extractors::ZipExtractor
      when "rpm"
        Extractors::RpmExtractor
      when "gzip"
        Extractors::GzipExtractor
      when "cpio"
        Extractors::CpioExtractor
      when "tar"
        Extractors::TarExtractor
      else
        raise Errors::UnknownArchiveError, "Could not unarchive `#{format}`."
      end
    end
    # rubocop:enable Metrics/MethodLength

    def extract_by_operation(operation, resource)
      method = "#{operation.format}_extract"
      if operation.options
        send(method, resource, **operation.options.to_h)
      else
        send(method, resource)
      end
    end

    def fonts_path
      Fontist.fonts_path
    end

    def download_file(source)
      url = source.urls.first
      Fontist.ui.say(%(Downloading font "#{@formula.key}" from #{url}))

      downloaded_file = Fontist::Utils::Downloader.download(
        url,
        sha: source.sha256,
        file_size: source.file_size,
        progress_bar: true
      )

      @downloaded = true
      downloaded_file
    end

    def font_file?(filename)
      source_files.include?(filename)
    end

    def source_files
      @source_files ||= @formula.fonts.flat_map do |font|
        font.styles.map do |style|
          style.source_font || style.font
        end
      end
    end

    def target_filename(source_filename)
      target_filenames[source_filename]
    end

    def target_filenames
      @target_filenames ||= @formula.fonts.flat_map do |font|
        font.styles.map do |style|
          source = style.source_font || style.font
          target = style.font
          [source, target]
        end
      end.to_h
    end
  end
end
