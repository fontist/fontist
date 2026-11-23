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
        style_resource_groups.each do |resource, styles|
          install_style_group(resource, styles, fonts_paths)
        end
      end
    end

    # Groups the selected styles by the resource each one's file lives in.
    def style_resource_groups
      selected_styles.group_by { |style| resource_for_style(style) }
    end

    def selected_styles
      styles = filtered_styles
      styles = styles_in_requested_format(styles) if @formula.v5?
      prefer_static_styles(styles)
    end

    # With no explicit static/variable request, styles of a font that
    # offers both variants collapse to the static ones. An explicit
    # variable request was already filtered by the matcher; --both keeps
    # all variants.
    def prefer_static_styles(styles)
      return styles if @format_spec&.variable == true
      return styles if @format_spec&.all_variants
      return styles unless @formula.v5?

      by_font = styles.group_by(&:family_name)
      styles.reject do |style|
        siblings = by_font[style.family_name]
        siblings.any? { |s| !s.variable_font? } && style.variable_font?
      end
    end

    def install_style_group(resource, styles, fonts_paths)
      expected = styles.map { |s| s.source_font || s.font }
      seen = []

      resource_for(resource).files(expected) do |path|
        basename = File.basename(path)
        seen << basename
        next unless expected.include?(basename) && font_directory?(path)

        installed_path = install_font_file(path)
        fonts_paths << installed_path if installed_path
      end

      (expected - seen).each do |name|
        Fontist.ui.warn("Font file not found in #{resource.name}: #{name}")
      end
    end

    # Resolution order: named by the style, then by file membership, then
    # by the requested format (conversion path), then the first resource.
    def resource_for_style(style)
      named = style.source_resource &&
        @formula.resources.find { |r| r.name == style.source_resource }
      return named if named

      source_name = style.source_font || style.font
      by_file = @formula.resources.find do |r|
        Array(r.files).any? { |f| File.basename(f) == source_name }
      end
      return by_file if by_file

      by_format = @formula.resources.find do |r|
        @format_spec&.format && r.format == @format_spec.format
      end
      by_format || @formula.resources.first
    end

    def resource_for(resource)
      klass = case resource.source
              when "google" then Resources::GoogleResource
              when "apple_cdn" then Resources::AppleCDNResource
              when "windows_fod" then Resources::WindowsFodResource
              else Resources::ArchiveResource
              end
      klass.new(resource, no_progress: @no_progress)
    end

    # Styles already in the requested format. When none is, a plain format
    # request keeps every style so the files can be converted.
    def styles_in_requested_format(styles)
      return styles unless @format_spec&.has_constraints?

      matching = FormatMatcher.new(@format_spec).filter_styles(styles)
      return matching if matching.any? || @format_spec.variable_requested?

      @format_spec.format ? styles : matching
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
        options = extracts.flat_map(&:options).compact
        options.filter_map(&:fonts_sub_dir)
      end
    end

    def install_font_file(source)
      Dir.mktmpdir("fontist-ops") do |workdir|
        original_name = target_filename(File.basename(source)) ||
          File.basename(source)
        prepared, target_name = prepare_font(source, original_name, workdir)
        result = @location.install_font(prepared, target_name)
        install_original_too(source, original_name) if
          converted?(source, prepared)
        result
      end
    end

    def converted?(source, prepared)
      requested = @format_spec&.format
      requested && detect_font_format(prepared) == requested &&
        detect_font_format(source) != requested
    end

    # Keeps the untouched original alongside converted output when the user
    # asked for it with a transcode_path (existing --keep-original behavior).
    def install_original_too(source, name)
      return unless @format_spec&.keep_original && @format_spec.transcode_path

      @location.install_font(source, name)
    end

    # Applies the requested operations (collection member extraction,
    # instancing, subsetting, conversion) and returns the file to install and
    # its name.
    def prepare_font(source, target_name, workdir)
      if @format_spec&.specific_collection_index? &&
          FontOperations::Extract.collection?(source)
        source = FontOperations::Extract.call(
          source, index: @format_spec.collection_index, output_dir: workdir
        )
        target_name = File.basename(source)
      end

      source, target_name = apply_instance(source, target_name, workdir)
      source, target_name = apply_subset(source, target_name, workdir)
      apply_conversion(source, target_name, workdir)
    end

    def apply_instance(source, target_name, workdir)
      return [source, target_name] unless @format_spec&.instance_requested?

      check_transcode_license_warning!
      coordinates = @format_spec.instance_coordinates
      name = FontOperations::Instance.file_name(target_name, coordinates)
      output = File.join(workdir, name)
      FontOperations::Instance.call(source, output, coordinates: coordinates)
      [output, name]
    end

    def apply_subset(source, target_name, workdir)
      return [source, target_name] unless @format_spec&.subset_requested?

      check_transcode_license_warning!
      output = File.join(workdir, "subset-#{File.basename(source)}")
      FontOperations::Subset.call(
        source, output,
        unicodes: @format_spec.subset_unicodes,
        text: @format_spec.subset_text
      )
      [output, target_name]
    end

    def apply_conversion(source, target_name, workdir)
      requested = @format_spec&.format
      source_format = detect_font_format(source)
      return [source, target_name] if [nil, source_format].include?(requested)

      check_transcode_license_warning!
      name = target_name.sub(/\.[^.]+\z/, ".#{requested}")
      output = File.join(@format_spec.transcode_path || workdir, name)
      convert_or_fallback(source, target_name, output, name)
    end

    def convert_or_fallback(source, original_name, output, name)
      FontOperations::Convert.call(source, @format_spec.format, output)
      Fontist.ui.success("Converted to #{@format_spec.format}: #{name}")
      [output, name]
    rescue Errors::GeneralError => e
      raise unless @format_spec.fallback_to_original

      Fontist.ui.warn("Could not convert: #{e.message}")
      Fontist.ui.warn("Installing original format (--fallback-to-original)")
      [source, original_name]
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
