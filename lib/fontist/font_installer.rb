require "fontist/utils"
require "excavate"
require "diffy"

module Fontist
  class FontInstaller
    def initialize(formula, font_name: nil, no_progress: false)
      @formula = formula
      @font_name = font_name
      @no_progress = no_progress
    end

    def install(confirmation:)
      raise_fontist_version_error unless supported_version?
      raise_licensing_error unless license_is_accepted?(confirmation)

      install_font
    end

    private

    attr_reader :formula

    def supported_version?
      return true unless @formula.min_fontist

      fontist_version = Gem::Version.new(Fontist::VERSION)
      min_fontist_required = Gem::Version.new(@formula.min_fontist)

      fontist_version >= min_fontist_required
    end

    def raise_fontist_version_error
      raise Fontist::Errors::FontistVersionError,
            "Formula requires higher version of fontist. " \
            "Please upgrade fontist.\n" \
            "Minimum required version: #{formula.min_fontist}. " \
            "Current fontist version: #{Fontist::VERSION}."
    end

    def license_is_accepted?(confirmation)
      return true unless @formula.license_required

      "yes".casecmp?(confirmation)
    end

    def raise_licensing_error
      raise(Fontist::Errors::LicensingError)
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
      archive = download_file(@formula.resources.first)

      install_fonts_from_archive(archive)
    end

    def install_fonts_from_archive(archive)
      Fontist.ui.say(%(Installing font "#{@formula.key}".))

      Array.new.tap do |fonts_paths|
        Excavate::Archive.new(archive.path).files(recursive_packages: true) do |path|
          fonts_paths << install_font_file(path) if font_file?(path)
        end
      end
    end

    def download_file(source)
      errors = []
      source.urls.each do |request|
        url = request.respond_to?(:url) ? request.url : request
        Fontist.ui.say(%(Downloading font "#{@formula.key}" from #{url}))

        result = try_download_file(request, source)
        return result unless result.is_a?(Errors::InvalidResourceError)

        errors << result
      end

      raise Errors::InvalidResourceError, errors.join(" ")
    end

    def try_download_file(request, source)
      Fontist::Utils::Downloader.download(
        request,
        sha: source.sha256,
        file_size: source.file_size,
        progress_bar: !@no_progress
      )
    rescue Errors::InvalidResourceError => e
      Fontist.ui.say(e.message)
      e
    end

    def font_file?(path)
      source_file?(path) && font_directory?(path)
    end

    def source_file?(path)
      if path.match(/(otf|ttf|ttc)$/i)
        source_files.each do |sf|
          if sf.match(/(otf|ttf|ttc)$/i)
            puts Diffy::Diff.new(File.basename(path), sf, ignore_crlf: true)
          end
        end
      end

      source_files.include?(File.basename(path))
    end

    def source_files
      @source_files ||= @formula.fonts.flat_map do |font|
        next [] if @font_name && !font.name.casecmp?(@font_name)

        font_files(font)
      end
    end

    def font_files(font)
      font.styles.map do |style|
        style.source_font || style.font
      end
    end

    def font_directory?(path)
      return true unless subdirectory_pattern

      File.fnmatch?(subdirectory_pattern, File.dirname(path))
    end

    def subdirectory_pattern
      @subdirectory_pattern ||= "*" + subdirectories.first.chomp("/") unless subdirectories.empty?
    end

    def subdirectories
      @subdirectories ||= [@formula.extract].flatten.map(&:options).compact.map(&:fonts_sub_dir).compact
    end

    def install_font_file(source)
      target = Fontist.fonts_path.join(target_filename(File.basename(source))).to_s
      FileUtils.mv(source, target)

      target
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
