require "lutaml/model"
require_relative "manifest"

module Fontist
  class ManifestResponseFontStyle < Lutaml::Model::Serializable
    attribute :type, :string
    attribute :full_name, :string
    attribute :paths, :string, collection: true

    key_value do
      map "type", to: :type
      map "full_name", to: :full_name
      map "paths", to: :paths
    end

    def to_hash
      result = super
      $stderr.puts "[DEBUG] ManifestResponseFontStyle#to_hash: keys=#{result.keys.inspect} (#{result.keys.first.class}) content=#{result.inspect}"
      result
    end
  end

  class ManifestResponseFont < ManifestFont
    attribute :name, :string
    attribute :styles, ManifestResponseFontStyle, collection: true

    key_value do
      map "name", to: :name
      map "styles", to: :styles, child_mappings: {
        type: :key,
        full_name: :full_name,
        paths: :paths,
      }
    end

    def install(confirmation: "no", hide_licenses: false, no_progress: false, location: nil)
      styles.each do |style|
        if style.paths.nil?
          # If no paths are found, notify the user but continue with the
          # installation
          Fontist.ui.error("Font #{name} with style #{style} not found, skipping installation.")
        end
      end

      Fontist::Font.install(
        name,
        force: false,
        confirmation: confirmation,
        hide_licenses: hide_licenses,
        no_progress: no_progress,
        location: location,
      )
    end
  end

  # Yu Gothic:
  #   Bold:
  #     full_name: Yu Gothic Bold
  #     paths:
  #     - "/Applications/Microsoft Excel.app/Contents/Resources/DFonts/YuGothB.ttc"
  #     - "/Applications/Microsoft OneNote.app/Contents/Resources/DFonts/YuGothB.ttc"
  #   Regular:
  #     full_name: Yu Gothic Regular
  #     paths:
  #     - "/Applications/Microsoft Excel.app/Contents/Resources/DFonts/YuGothR.ttc"
  #     - "/Applications/Microsoft OneNote.app/Contents/Resources/DFonts/YuGothR.ttc"
  # Noto Sans Condensed:
  #   Regular:
  #     full_name: Noto Sans Condensed
  #     paths:
  #     - "/Users/foo/.fontist/fonts/NotoSans-Condensed.ttf"
  class ManifestResponse < Manifest
    instances :fonts, ManifestResponseFont

    def self.font_class
      ManifestResponseFont
    end
  end
end
