module Fontist
  class Font
    def initialize(options = {})
      @name = options.fetch(:name, nil)
      @style = options.fetch(:style, nil)
      @confirmation = options.fetch(:confirmation, "no")

      check_or_create_fontist_path!
    end

    def self.all
      new.all
    end

    def self.find(name)
      new(name: name).find
    end

    def self.install(name, style: nil, confirmation: "no")
      new(name: name, style: style, confirmation: confirmation).install
    end

    def find
      find_system_font || downloadable_font || raise(
        Fontist::Errors::NonSupportedFontError
      )
    end

    def install
      existing = find_system_font || []
      missing = missing_fonts(existing)

      raise(Fontist::Errors::NonSupportedFontError) if missing.empty? && existing.empty?
      return existing if missing.empty?

      installed = download_font
      existing.concat(installed).uniq
    end

    def all
      Fontist::Formula.all.to_h.map { |_name, formula| formula.fonts }.flatten
    end

    private

    attr_reader :name, :style, :confirmation

    def find_system_font
      Fontist::SystemFont.find(name, style)
    end

    def check_or_create_fontist_path!
      unless Fontist.fonts_path.exist?
        require "fileutils"
        FileUtils.mkdir_p(Fontist.fonts_path)
      end
    end

    def missing_fonts(existing_paths)
      available = available_fonts || []
      existing = filenames(existing_paths)
      available - existing
    end

    def available_fonts
      available_by_style || available_by_font || available_by_formula
    end

    def available_by_style
      return unless @style

      if formula
        formula.fonts.select do |f|
          if f.name.casecmp?(@name)
            f.styles.select do |s|
              s.font if s.type.casecmp?(@style)
            end
          end
        end.flatten
      end
    end

    def available_by_font
      if formula
        matched = formula.fonts.select do |f|
          if f.name.casecmp?(@name)
            f.styles.map do |s|
              s.font
            end
          end
        end.flatten

        matched.empty? ? nil : matched
      end
    end

    def available_by_formula
      if formula
        formula.fonts.map do |f|
          f.styles.map do |s|
            s.font
          end
        end.flatten
      end
    end

    def filenames(paths)
      paths.map do |path|
        File.basename(path)
      end
    end

    def font_installer(formula)
      Object.const_get(formula.installer)
    end

    def formula
      @formula ||= Fontist::Formula.find(name)
    end

    def downloadable_font
      if formula
        raise(
          Fontist::Errors::MissingFontError,
"#{name}"          "Fonts are missing, please run " \
          "Fontist::Font.install('#{name}', confirmation: 'yes') to " \
          "download the font."
        )
      end
    end

    def download_font
      if formula
        check_and_confirm_required_license(formula)
        font_installer(formula).fetch_font(name,
                                           style: style,
                                           confirmation: confirmation)
      end
    end

    def check_and_confirm_required_license(formula)
      if formula.license_required && !confirmation.casecmp("yes").zero?
        @confirmation = show_license_and_ask_for_input(formula.license)

        if !confirmation.casecmp("yes").zero?
          raise Fontist::Errors::LicensingError.new(
            "Fontist will not download these fonts unless you accept the terms."
          )
        end
      end
    end

    def show_license_and_ask_for_input(license)
      Fontist.ui.say(license_agrement_message(license))
      Fontist.ui.ask(
        "\nDo you accept all presented font licenses, and want Fontist " \
        "to download these fonts for you? => TYPE 'Yes' or 'No':"
      )
    end

    def license_agrement_message(license)
      <<~MSG
        FONT LICENSE ACCEPTANCE REQUIRED FOR "#{name}":

        Fontist can install this font if you accept its licensing conditions.

        FONT LICENSE BEGIN ("#{name}")
        -----------------------------------------------------------------------
        #{license}
        -----------------------------------------------------------------------
        FONT LICENSE END ("#{name}")
      MSG
    end
  end
end
