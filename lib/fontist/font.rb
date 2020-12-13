require "fontist/font_installer"

module Fontist
  class Font
    def initialize(options = {})
      @name = options.fetch(:name, nil)
      @confirmation = options.fetch(:confirmation, "no")
      @force = options.fetch(:force, false)

      check_or_create_fontist_path!
    end

    def self.all
      new.all
    end

    def self.find(name)
      new(name: name).find
    end

    def self.install(name, confirmation: "no", force: false)
      new(name: name, confirmation: confirmation, force: force).install
    end

    def self.uninstall(name)
      new(name: name).uninstall
    end

    def self.status(name)
      new(name: name).status
    end

    def self.list(name)
      new(name: name).list
    end

    def find
      find_system_font || downloadable_font || raise_non_supported_font
    end

    def install
      (find_system_font unless @force) || download_font || raise_non_supported_font
    end

    def uninstall
      uninstall_font || downloadable_font || raise_non_supported_font
    end

    def status
      return installed_statuses unless @name

      font_status || downloadable_font || raise_non_supported_font
    end

    def list
      return all_list unless @name

      font_list || raise_non_supported_font
    end

    def all
      Fontist::Formula.all.map(&:fonts).flatten
    end

    private

    attr_reader :name, :confirmation

    def find_system_font
      paths = Fontist::SystemFont.find(name)
      unless paths
        Fontist.ui.say(%(Font "#{name}" not found locally.))
        return
      end

      Fontist.ui.say("Fonts found at:")
      paths.each do |path|
        Fontist.ui.say("- #{path}")
      end
    end

    def check_or_create_fontist_path!
      unless Fontist.fonts_path.exist?
        require "fileutils"
        FileUtils.mkdir_p(Fontist.fonts_path)
      end
    end

    def font_installer(formula)
      FontInstaller.new(formula)
    end

    def formula
      @formula ||= Fontist::Formula.find(name)
    end

    def downloadable_font
      if formula
        raise(
          Fontist::Errors::MissingFontError,
          "#{name} fonts are missing, please run " \
          "`fontist install '#{name}'` to " \
          "download the font."
        )
      end
    end

    def download_font
      if formula
        check_and_confirm_required_license(formula)
        paths = font_installer(formula).install(confirmation: confirmation)

        Fontist.ui.say("Fonts installed at:")
        paths.each do |path|
          Fontist.ui.say("- #{path}")
        end
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

    def uninstall_font
      paths = find_fontist_font
      return unless paths

      paths.each do |path|
        File.delete(path)
      end

      paths
    end

    def find_fontist_font
      Fontist::FontistFont.find(name)
    end

    def installed_statuses
      installed_styles(all_formulas)
    end

    def all_formulas
      Fontist::Formula.all
    end

    def font_status
      return unless formula

      statuses = installed_styles([formula])
      statuses.empty? ? nil : statuses
    end

    def installed_styles(formulas)
      filter_blank(formulas) do |formula|
        filter_blank(formula.fonts) do |font|
          filter_blank(font.styles) do |style|
            path(style)
          end
        end
      end
    end

    def filter_blank(elements)
      elements.map { |e| [e, yield(e)] }
        .to_h
        .reject { |_k, v| v.nil? || v.empty? }
    end

    def path(style)
      font_paths.detect do |path|
        File.basename(path) == style.font
      end
    end

    def font_paths
      @font_paths ||= Dir.glob(Fontist.fonts_path.join("**"))
    end

    def all_list
      list_styles(all_formulas)
    end

    def font_list
      return unless formula

      list_styles([formula])
    end

    def list_styles(formulas)
      map_to_hash(formulas) do |formula|
        map_to_hash(formula.fonts) do |font|
          map_to_hash(font.styles) do |style|
            installed(style)
          end
        end
      end
    end

    def map_to_hash(elements)
      elements.map { |e| [e, yield(e)] }.to_h
    end

    def installed(style)
      path(style) ? true : false
    end

    def raise_non_supported_font
      raise Fontist::Errors::NonSupportedFontError.new(
        "Font '#{@name}' not found locally nor available in the Fontist " \
        "formula repository.\n" \
        "Perhaps it is available at the latest Fontist formula " \
        "repository.\n" \
        "You can update the formula repository using the command " \
        "`fontist update` and try again."
      )
    end
  end
end
