module Fontist
  module Import
    class FormulaSerializer
      def initialize(formula, code)
        @formula = formula
        @code = code
      end

      def call
        to_h.compact
      end

      private

      def to_h
        info_attributes.merge(fonts_attributes).merge(license_attributes)
      end

      def info_attributes
        { key: @formula.key,
          name: formula_name(@formula),
          description: @formula.description,
          homepage: @formula.homepage }
      end

      def fonts_attributes
        { display_progress_bar: formula_progress_bar(@formula),
          resources: @formula.resources,
          font_collections: font_collections(@formula.all_fonts),
          fonts: standalone_fonts(@formula.all_fonts),
          extract: extract_type(@code) }
      end

      def license_attributes
        { copyright: @formula.copyright,
          license_url: @formula.license_url,
          requires_license_agreement: requires_license_agreement(@formula),
          open_license: open_license(@formula) }
      end

      def formula_name(formula)
        formula.class.name.match(/Formulas::(.+)Fonts?/)[1]
      end

      def formula_progress_bar(formula)
        formula.options&.dig(:progress_bar)
      end

      def font_collections(fonts)
        collections = collections(fonts)
        return if collections.empty?

        collections.map do |filename, coll_fonts|
          { filename: filename,
            fonts: collection_fonts(coll_fonts) }
        end
      end

      def collections(fonts)
        fonts.select { |f| collection_font?(f) }
          .group_by { |f| f[:styles].first[:font] }
      end

      def collection_font?(font)
        font[:styles].first[:font].end_with?(".ttc", ".TTC")
      end

      def collection_fonts(fonts)
        fonts.map do |f|
          { name: f[:name], styles: collection_font_styles(f[:styles]) }
        end
      end

      def collection_font_styles(styles)
        styles.map do |s|
          collection_font_style(s)
        end
      end

      def collection_font_style(style)
        Hash.new.tap do |h|
          h[:type] = style[:type]

          if style[:collection]
            h[:full_name] = collection_full_name(style[:collection])
          end
        end
      end

      def collection_full_name(collection_label)
        if collection_label.is_a?(Hash)
          collection_label.values_at(:name, :style).join(" ")
        else
          collection_label
        end
      end

      def standalone_fonts(fonts)
        standalone = fonts.reject do |f|
          collection_font?(f)
        end

        standalone.empty? ? nil : standalone
      end

      # rubocop:disable Metrics/MethodLength, Metrics/LineLength
      def extract_type(code)
        case code
        when /def extract.+exe_extract.+cab_extract.+ppviewer\.cab/m
          [{ format: :exe }, { format: :cab, file: "ppviewer.cab" }]
        when /def extract.+cab_extract/m
          { format: :cab }
        when /def extract.+(zip_extract|unzip).+fonts_sub_dir: "(.+?)"/m
          dir = code.match(/def extract.+(zip_extract|unzip).+fonts_sub_dir: "(.+?)"/m)[2]
          { format: :zip, options: { fonts_sub_dir: dir } }
        when /def extract.+(zip_extract|unzip)/m
          { format: :zip }
        else
          raise NotImplementedError, "Please implement an extract format"
        end
      end
      # rubocop:enable Metrics/MethodLength, Metrics/LineLength

      def requires_license_agreement(formula)
        formula.license if formula.license && formula.license_required?
      end

      def open_license(formula)
        formula.license if formula.license && !formula.license_required?
      end
    end
  end
end
