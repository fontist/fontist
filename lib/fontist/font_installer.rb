require "fontist/utils"
require "excavate"
require_relative "resources/archive_resource"
require_relative "resources/google_resource"

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
      return true unless @formula.license_required?

      "yes".casecmp?(confirmation)
    end

    def raise_licensing_error
      raise(Fontist::Errors::LicensingError)
    end

    def install_font
      fonts_paths = do_install_font
      fonts_paths.empty? ? nil : fonts_paths
    end

    def do_install_font
      Fontist.ui.say(%(Installing from formula "#{@formula.key}".))

      Array.new.tap do |fonts_paths|
        resource.files(source_files) do |path|
          fonts_paths << install_font_file(path) if font_file?(path)
        end
      end
    end

    def resource
      resource_class = if @formula.source == "google"
                         Resources::GoogleResource
                       else
                         Resources::ArchiveResource
                       end

      resource_class.new(resource_options, no_progress: @no_progress)
    end

    def resource_options
      @formula.resources.first
    end

    def font_file?(path)
      source_file?(path) && font_directory?(path)
    end

    def source_file?(path)
      source_files.include?(File.basename(path))
    end

    def source_files
      @source_files ||= fonts.flat_map do |font|
        font.styles.map do |style|
          style.source_font || style.font
        end
      end
    end

    def fonts
      @formula.fonts.select do |font|
        @font_name.nil? || font.name.casecmp?(@font_name)
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
