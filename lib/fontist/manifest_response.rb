require "lutaml/model"
require_relative "manifest"

module Fontist

  class ManifestResponseFontStyle < Lutaml::Model::Serializable
    attribute :full_name, :string
    attribute :type, :string
    attribute :paths, :string, collection: true

    key_value do
      map "full_name", to: :full_name
      map "type", to: :type
      map "paths", to: :paths
    end
  end

  class ManifestResponseFont < ManifestFont
    attribute :name, :string
    attribute :styles, ManifestResponseFontStyle, collection: true

    key_value do
      map to: :styles, child_mappings: {
        type: :key,
        full_name: :full_name,
        paths: :paths
      }
    end

    def install(confirmation: "no", hide_licenses: false, no_progress: false)
      styles.each do |style|
        if style.paths.nil?
          # If no paths are found, notify the user but continue with the
          # installation
          Fontist.ui.error("Font #{name} with style #{style} not found, skipping installation.")
        end
      end

      Fontist::Font.install(
        name,
        force: true,
        confirmation: confirmation,
        hide_licenses: hide_licenses,
        no_progress: no_progress
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
    # Share key_value mappings with superclass, only change font class
    instances :fonts, ManifestResponseFont

    # TODO: This should be moved to base Manifest class
    key_value do
      map to: :fonts, root_mappings: {
        name: :key,
        styles: :value,
      }
    end

    def install(confirmation: "no", hide_licenses: false, no_progress: false)
      fonts.each do |font|
        font.install(
          confirmation: confirmation,
          hide_licenses: hide_licenses,
          no_progress: no_progress
        )
      end
    end
  end
end
