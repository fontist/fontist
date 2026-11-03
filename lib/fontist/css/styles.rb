module Fontist
  module Css
    # Style names as listed in formulas, mapped to CSS weights.
    module Styles
      # Fixed table: style name (case and separators ignored) => weight.
      WEIGHTS = {
        "thin" => 100, "hairline" => 100,
        "extralight" => 200, "ultralight" => 200,
        "light" => 300,
        "regular" => 400, "normal" => 400, "book" => 400,
        "medium" => 500,
        "semibold" => 600, "demibold" => 600,
        "bold" => 700,
        "extrabold" => 800, "ultrabold" => 800,
        "black" => 900, "heavy" => 900
      }.freeze

      # One available style: weight 100..900, italic flag, formula style.
      Face = Struct.new(:weight, :italic, :style, keyword_init: true) do
        def tuple
          [italic ? 1 : 0, weight]
        end

        def token
          Styles.token(tuple)
        end
      end

      class << self
        # "300,600i" or ["300", "600i"] => sorted unique [[ital, wght], ...]
        def parse(styles)
          Array(styles).flat_map { |s| s.to_s.split(",") }
            .map(&:strip).reject(&:empty?)
            .map { |token| parse_token(token) }.uniq.sort
        end

        def token(tuple)
          "#{tuple[1]}#{'i' if tuple[0] == 1}"
        end

        # Faces a formula lists, sorted upright first, by weight.
        def faces(formula)
          formula.all_fonts.flat_map(&:styles).filter_map { |s| face_for(s) }
            .uniq(&:tuple).sort_by(&:tuple)
        end

        # Face for one formula style; nil when its name is not in the table.
        def face_for(style)
          name = (style.preferred_type || style.type).to_s
          base = name.gsub(/italic|oblique/i, "").downcase.gsub(/[\s_-]+/, "")
          weight = WEIGHTS[base.empty? ? "regular" : base]
          return unless weight

          Face.new(weight: weight, italic: name.match?(/italic|oblique/i),
                   style: style)
        end

        # Raise unless every requested tuple is among the available faces.
        def verify(family, faces, requested)
          have = faces.map(&:tuple)
          missing = requested.find { |tuple| !have.include?(tuple) }
          return unless missing

          raise UnavailableStyleError.new(family, token(missing),
                                          faces.map(&:token))
        end

        private

        def parse_token(token)
          match = /\A([1-9]00)(i?)\z/.match(token)
          raise InvalidStyleError, token unless match

          [match[2] == "i" ? 1 : 0, match[1].to_i]
        end
      end
    end
  end
end
