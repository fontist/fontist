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
        styles: font_styles,
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
    instances :fonts, ManifestRequestFont

    def self.font_class
      ManifestRequestFont
    end
  end
end
