# frozen_string_literal: true

module Fontist
  module Utils
    # Builds Google Fonts CSS2 API URLs with proper axis specifiers.
    #
    # The bare URL (?family=Name) only works for fonts that include a
    # "regular" variant. All other fonts need explicit ital/wght specifiers
    # or the API returns 400.
    #
    # Accepts Google-style variant strings: "regular", "italic", "300",
    # "700italic", etc.
    module GoogleCssUrl
      CSS2_BASE = "https://fonts.googleapis.com/css2"

      # Standard CSS font-weight names → numeric values.
      WEIGHT_FROM_NAME = {
        "thin" => 100, "hairline" => 100,
        "extralight" => 200, "ultralight" => 200,
        "light" => 300,
        "regular" => 400, "normal" => 400,
        "medium" => 500,
        "semibold" => 600, "demibold" => 600,
        "bold" => 700,
        "extrabold" => 800, "ultrabold" => 800,
        "black" => 900, "heavy" => 900,
      }.freeze

      # Build a CSS2 URL from a family name and an array of Google-style
      # variant strings (e.g. ["300", "italic", "700italic"]).
      #
      # @param family_name [String] e.g. "Noto Sans"
      # @param variants [Array<String>] Google variant strings
      # @return [String] fully-qualified CSS2 URL
      def self.build(family_name, variants = [])
        base = "#{CSS2_BASE}?family=#{family_name.gsub(' ', '+')}"
        return base if variants.empty?

        # Collect numeric weights; "regular" = 400, "italic" = 400 italic
        normal_weights = []
        normal_weights << 400 if variants.include?("regular")
        normal_weights.concat(variants.select { |v| v.match?(/\A\d+\z/) }.map(&:to_i))
        normal_weights = normal_weights.sort.uniq

        italic_weights = []
        italic_weights << 400 if variants.include?("italic")
        italic_weights.concat(variants.select { |v| v.match?(/\A\d+italic\z/) }.map(&:to_i))
        italic_weights = italic_weights.sort.uniq

        has_normal = normal_weights.any?
        has_italic = italic_weights.any?

        if has_normal && has_italic
          tuples = normal_weights.map { |w| "0,#{w}" } +
                   italic_weights.map { |w| "1,#{w}" }
          "#{base}:ital,wght@#{tuples.join(';')}"
        elsif has_italic
          "#{base}:ital,wght@#{italic_weights.map { |w| "1,#{w}" }.join(';')}"
        elsif has_normal
          "#{base}:wght@#{normal_weights.join(';')}"
        else
          base
        end
      end

      # Convert a numeric weight to a Google variant string.
      #
      # @param weight [Integer] e.g. 400, 700
      # @return [String] e.g. "regular", "700"
      def self.variant_from_weight(weight)
        weight == 400 ? "regular" : weight.to_s
      end

      # Look up a numeric weight from a common name.
      #
      # @param name [String] e.g. "Bold", "light"
      # @return [Integer, nil] e.g. 700, 300
      def self.weight_from_name(name)
        WEIGHT_FROM_NAME[name.to_s.downcase.strip]
      end

      # Convert an array of numeric weights to variant strings suitable
      # for {.build}. Defaults to ["regular"] when empty.
      #
      # @param weights [Array<Integer>]
      # @return [Array<String>]
      def self.variants_from_weights(weights)
        weights = [400] if weights.empty?
        weights.uniq.map { |w| variant_from_weight(w) }
      end
    end
  end
end
