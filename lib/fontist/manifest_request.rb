require "lutaml/model"
require_relative "manifest"

module Fontist
  class ManifestRequestFont < ManifestFont
    def to_response
      font_styles = locate_styles.map do |style, detailed_styles|
        # puts "Detailed styles for #{name}: #{detailed_styles.inspect}"

        if detailed_styles.nil? || detailed_styles.empty?
          Fontist.ui.error("Font #{name} with style #{style} not found, skipping")
          ManifestResponseFontStyle.new(
            type: style,
          )
        else
          ManifestResponseFontStyle.new(
            full_name: detailed_styles.first.full_name,
            type: detailed_styles.first.type,
            paths: detailed_styles.map(&:path),
          )
        end
      end

      ManifestResponseFont.new(
        name: name,
        styles: font_styles
      )
    end

    private

    # Returns an array of paths for the font and all its styles
    # A SystemIndexFont array is returned, which has the following structure:
    # [{:path=>"/Library/Fonts/Arial Unicode.ttf",
    # :full_name=>"Arial Unicode MS",
    # :family_name=>"Arial Unicode MS",
    # :type=>"Regular"}, ...],
    def locate_styles
      Array(styles).map do |style|
        [
          style,
          Fontist::SystemFont.find_styles(name, style),
        ]
      end
    end
  end

  # ---
  # Andale Mono:
  # - Regular
  # Arial Black:
  # - Regular
  # Arial:
  # - Bold
  # - Italic
  # - Bold Italic
  class ManifestRequest < Manifest
    # Share key_value mappings with superclass, only change font class
    instances :fonts, ManifestRequestFont

    # TODO: This should be moved to base Manifest class
    # key_value do
    #   map to: :fonts
    #   map_key to_instance: :name
    #   map_value to_instance: :styles
    # end

    def to_response
      ManifestResponse.new.tap do |response|
        response.fonts = fonts.map do |font|
          font.to_response
        end
      end
    end
  end
end
