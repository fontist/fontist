require "fontist/utils"
require "excavate"
require_relative "resources/archive_resource"
require_relative "resources/google_resource"
require_relative "resources/apple_cdn_resource"
require_relative "install_location"

module Fontist
  class FontInstaller
    attr_reader :location

    def initialize(formula, font_name: nil, no_progress: false, location: nil)
      @formula = formula
      @font_name = font_name
      @no_progress = no_progress
      @location = InstallLocation.create(formula, location_type: location)
    end

    def install(confirmation:)
      raise_platform_error unless platform_compatible?
      raise_fontist_version_error unless supported_version?
      raise_licensing_error unless license_is_accepted?(confirmation)

      install_font
    end

    private

    attr_reader :formula

    def platform_compatible?
      @formula.compatible_with_platform?
    end

    def raise_platform_error
      raise Fontist::Errors::PlatformMismatchError.new(
        @font_name || @formula.name,
        @formula.platforms,
        Fontist::Utils::System.user_os,
      )
    end

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
          if font_file?(path)
            installed_path = install_font_file(path)
            fonts_paths << installed_path if installed_path
          end
        end
      end
    end

    def resource
      resource_class = if @formula.source == "google"
                         Resources::GoogleResource
                       elsif @formula.source == "apple_cdn"
                         Resources::AppleCDNResource
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
      @formula.all_fonts.select do |font|
        @font_name.nil? || font.name.casecmp?(@font_name)
      end
    end

    def font_directory?(path)
      return true unless subdirectory_pattern

      File.fnmatch?(subdirectory_pattern, File.dirname(path))
    end

    def subdirectory_pattern
      @subdirectory_pattern ||= "*#{subdirectories.first.chomp('/')}" unless subdirectories.empty?
    end

    def subdirectories
      @subdirectories ||= [@formula.extract].flatten.compact.filter_map(&:options).filter_map(&:fonts_sub_dir)
    end

    def install_font_file(source)
      source_basename = File.basename(source)
      target_name = target_filename(source_basename) || source_basename

      # Use location object to handle installation
      # This handles all the logic for:
      # - Checking if font exists
      # - Managed vs non-managed location handling
      # - Unique filename generation
      # - Index updates
      # - Warning messages
      installed_path = @location.install_font(source, target_name)

      # Return path if installed, nil if skipped
      installed_path
    end

    def macos_asset_directory
      # Install to: /System/Library/AssetsV2/com_apple_MobileAsset_Font*/
      # Generate unique asset identifier from formula key
      require "digest"
      asset_id = Digest::SHA256.hexdigest(@formula.key)[0..39]
      version = detect_catalog_version

      Pathname.new("/System/Library/AssetsV2")
        .join("com_apple_MobileAsset_Font#{version}")
        .join("#{asset_id}.asset")
        .join("AssetData")
    end

    def detect_catalog_version
      # Extract from formula metadata or default to 8
      # This can be enhanced to parse from resource URL if needed
      8
    end

    def target_filename(source_filename)
      target_filenames[source_filename]
    end

    def target_filenames
      @target_filenames ||= @formula.all_fonts.flat_map do |font|
        font.styles.map do |style|
          source = style.source_font || style.font
          target = style.font
          [source, target]
        end
      end.to_h
    end
  end
end
