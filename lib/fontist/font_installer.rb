require "fontist/utils"
require "excavate"

module Fontist
  class FontInstaller
    def initialize(formula, no_progress: false)
      @formula = formula
      @no_progress = no_progress
    end

    def install(confirmation:)
      if @formula.license_required && !"yes".casecmp?(confirmation)
        raise(Fontist::Errors::LicensingError)
      end

      install_font
    end

    private

    attr_reader :formula

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
      request = source.urls.first
      url = request.respond_to?(:url) ? request.url : request
      Fontist.ui.say(%(Downloading font "#{@formula.key}" from #{url}))

      Fontist::Utils::Downloader.download(
        request,
        sha: source.sha256,
        file_size: source.file_size,
        progress_bar: !@no_progress
      )
    end

    def font_file?(path)
      source_file?(path) && font_directory?(path)
    end

    def source_file?(path)
      source_files.include?(File.basename(path))
    end

    def source_files
      @source_files ||= @formula.fonts.flat_map do |font|
        font.styles.map do |style|
          style.source_font || style.font
        end
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
