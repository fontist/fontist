require "excavate"
require_relative "format_matcher"

module Fontist
  class FontInstaller
    attr_reader :location

    def initialize(formula, font_name: nil, no_progress: false, location: nil,
                   format_spec: nil, confirmation: "no")
      @formula = formula
      @font_name = font_name
      @no_progress = no_progress
      @location = InstallLocation.create(formula, location_type: location)
      @format_spec = format_spec
      @confirmation = confirmation
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
      return true if @formula.licensed_for_current_platform?

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
      @resource_options ||= begin
        if @formula.resources.size == 1 || !@formula.v5?
          @formula.resources.first
        elsif @format_spec&.has_constraints?
          matcher = FormatMatcher.new(@format_spec)
          matcher.select_preferred_resource(@formula.resources)
        else
          find_desktop_resource || @formula.resources.first
        end
      end
    end

    def find_desktop_resource
      @formula.resources.find { |r| r.format && FormatMatcher::DESKTOP_FORMATS.include?(r.format) }
    end

    def font_file?(path)
      source_file?(path) && font_directory?(path)
    end

    def source_file?(path)
      source_files.include?(File.basename(path))
    end

    def source_files
      @source_files ||= begin
        styles = filtered_styles

        # Use FormatMatcher for filtering
        if @format_spec&.has_constraints? && @formula.v5?
          matcher = FormatMatcher.new(@format_spec)
          styles = matcher.filter_styles(styles)
        end

        file_names = styles.map { |s| s.source_font || s.font }

        if @formula.v5? && resource_options&.source == "google" && file_names.any?
          resource_basenames = Array(resource_options.files).map { |f| File.basename(f) }
          unless file_names.any? { |f| resource_basenames.include?(f) }
            return resource_basenames
          end
        end

        file_names
      end
    end

    def filtered_styles
      fonts.flat_map(&:styles)
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
      @subdirectories ||= begin
        extracts = [@formula.extract].flatten.compact
        # options is a collection, so we need to flatten it too
        options = extracts.flat_map { |e| e.options }.compact
        options.filter_map(&:fonts_sub_dir)
      end
    end

    def install_font_file(source)
      source_basename = File.basename(source)
      target_name = target_filename(source_basename) || source_basename
      source_format = detect_font_format(source)

      # Check if transcoding is needed (format requested but not available)
      if @format_spec&.format && @format_spec.format != source_format
        check_transcode_license_warning!
        install_with_conversion(source, target_name, source_format)
      else
        @location.install_font(source, target_name)
      end
    end

    def detect_font_format(path)
      ext = File.extname(path).downcase.delete(".")
      case ext
      when "ttf", "otf", "woff", "woff2", "ttc", "otc", "dfont"
        ext
      else
        "ttf" # Default
      end
    end

    # Check and warn about license implications of transcoding
    def check_transcode_license_warning!
      return unless @formula.license_required?

      if @confirmation != "yes"
        raise Errors::TranscodeLicenseNotAcceptedError.new(
          @formula.fonts.first&.name || @formula.name,
        )
      end

      # User has accepted the license, but we still warn them
      # that transcoding may not be permitted by all licenses
      Fontist.ui.warn("\n#{'=' * 60}")
      Fontist.ui.warn("LICENSE TRANSCODING NOTICE")
      Fontist.ui.warn("=" * 60)
      Fontist.ui.warn(
        "You are transcoding a font that requires a license agreement.",
      )
      Fontist.ui.warn(
        "Some font licenses do not permit conversion or modification,",
      )
      Fontist.ui.warn(
        "of which transcoding is a type. Please ensure your use of",
      )
      Fontist.ui.warn("this font complies with the license terms.")
      Fontist.ui.warn("#{'=' * 60}\n")
    end

    def install_with_conversion(source, target_name, source_format)
      target_format = @format_spec.format

      # Check if Fontisan can convert between formats
      matcher = FormatMatcher.new(@format_spec)
      unless matcher.can_convert?(source_format, target_format)
        Fontist.ui.warn(
          "Cannot convert from #{source_format} to #{target_format}",
        )
        Fontist.ui.warn("Installing original format instead")
        return @location.install_font(source, target_name)
      end

      begin
        converted_path = convert_with_fontisan(source, target_format)

        # Determine where to save converted font
        converted_name = target_name.sub(/\.[^.]+$/, ".#{target_format}")

        Fontist.ui.success(
          "Converted #{source_format} to #{target_format}: #{converted_name}",
        )

        # Install converted font
        result = @location.install_font(converted_path, converted_name)

        # Keep original if requested and transcode_path specified
        if @format_spec.keep_original && @format_spec.transcode_path
          @location.install_font(source, target_name)
        end

        # Clean up temp converted file if Fontisan created one
        cleanup_temp_file(converted_path) if converted_path != source

        result
      rescue StandardError => e
        Fontist.ui.warn("Could not convert to #{target_format}: #{e.message}")
        Fontist.ui.warn("Installing original format instead")
        @location.install_font(source, target_name)
      end
    end

    # Convert font using Fontisan library
    def convert_with_fontisan(source_path, target_format)
      require "fontisan"

      font = Fontisan::FontLoader.load(source_path)

      case target_format
      when "woff"
        font.to_woff(path: temp_path_for(source_path, "woff"))
      when "woff2"
        font.to_woff2(path: temp_path_for(source_path, "woff2"))
      else
        raise Errors::UnsupportedTranscodeError.new(
          File.extname(source_path),
          target_format,
        )
      end
    rescue LoadError
      Fontist.ui.error(
        "Fontisan gem not found. Transcoding requires the fontisan gem.",
      )
      Fontist.ui.error("Add it to your Gemfile or run: gem install fontisan")
      raise
    end

    def temp_path_for(source_path, format)
      base = File.basename(source_path, ".*")
      dir = @format_spec&.transcode_path || Dir.mktmpdir
      FileUtils.mkdir_p(dir) unless Dir.exist?(dir)
      File.join(dir, "#{base}.#{format}")
    end

    def cleanup_temp_file(path)
      File.delete(path) if File.exist?(path)
    rescue StandardError
      # Ignore cleanup errors
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
