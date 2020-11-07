module Fontist
  class FormulaTemplate
    def self.create_formula_class(formula)
      Class.new(FontFormula) do |klass|
        first_font = (formula.fonts || formula.font_collections.first.fonts).first
        cleanname = first_font.name.gsub(/ /, "")
        resource_name = formula.resources.to_h.keys.first
        font_filename = first_font.styles.first.font

        key formula.key&.to_sym || formula.name.gsub(/ /, "_").downcase.to_sym
        display_progress_bar formula.display_progress_bar if formula.display_progress_bar
        desc formula.description
        homepage formula.homepage

        formula.resources.to_h.each do |filename, options|
          resource filename do
            urls options.urls
            sha256 options.sha256
          end
        end

        if formula.font_collections
          formula.font_collections.each do |collection|
            provides_font_collection do
              filename collection.filename

              collection.fonts.each do |font|
                styles = font.styles.map { |s| [s.type, s.full_name] }.to_h
                provides_font font.name, extract_styles_from_collection: styles
              end
            end
          end
        end

        if formula.fonts
          formula.fonts.each do |font|
            provides_font(
              font.name,
              match_styles_from_file: font.styles.map do |style|
                {
                  family_name: style.family_name,
                  style: style.type,
                  full_name: style.full_name,
                  post_script_name: style.post_script_name,
                  version: style.version,
                  description: style.description,
                  filename: style.font,
                  copyright: style.copyright,
                }
              end
            )
          end
        end

        klass.define_method :extract do
          resource = resource(resource_name)

          [formula.extract].flatten.each do |operation|
            method = "#{operation.format}_extract"
            resource = if operation.options
                         send(method, resource, **operation.options.to_h)
                       else
                         send(method, resource)
                       end
          end

          if formula.fonts
            formula.fonts.each do |font|
              match_fonts(resource, font.name)
            end
          end

          if formula.font_collections
            formula.font_collections.each do |collection|
              collection.fonts.each do |font|
                match_fonts(resource, font.name)
              end
            end
          end
        end

        klass.define_method :install do
          case platform
          when :macos
            install_matched_fonts "$HOME/Library/Fonts/#{cleanname}"
          when :linux
            install_matched_fonts "/usr/share/fonts/truetype/#{cleanname.downcase}"
          end
        end

        test do
          case platform
          when :macos
            assert_predicate "$HOME/Library/Fonts/#{cleanname}/#{font_filename}", :exist?
          when :linux
            assert_predicate "/usr/share/fonts/truetype/#{cleanname.downcase}/#{font_filename}", :exist?
          end
        end

        copyright formula.copyright
        license_url formula.license_url

        open_license formula.open_license if formula.open_license
        requires_license_agreement formula.requires_license_agreement if formula.requires_license_agreement
      end
    end
  end
end
