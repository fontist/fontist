require "fontist/font_installer"
require "fontist/font_path"
require "fontist/formula_picker"
require "fontist/fontconfig"
require "fontist/formula_suggestion"

module Fontist
  class Font
    def initialize(options = {})
      @name = options[:name]
      @confirmation = options[:confirmation] || "no"
      @hide_licenses = options[:hide_licenses]
      @no_progress = options[:no_progress] || false
      @force = options[:force] || false
      @version = options[:version]
      @smallest = options[:smallest]
      @newest = options[:newest]
      @size_limit = options[:size_limit]
      @by_formula = options[:formula]
      @update_fontconfig = options[:update_fontconfig]

      check_or_create_fontist_path!
    end

    def self.all
      new.all
    end

    def self.find(name)
      new(name: name).find
    end

    def self.install(name, options = {})
      new(options.merge(name: name)).install
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
      find_system_font || downloadable_font || manual_font ||
        raise_non_supported_font
    end

    def install
      return install_formula if @by_formula

      (find_system_font unless @force) || download_font || manual_font ||
        raise_non_supported_font
    end

    def uninstall
      uninstall_font || downloadable_font || manual_font ||
        raise_non_supported_font
    end

    def status
      return installed_paths unless @name

      find_system_font || downloadable_font || manual_font ||
        raise_non_supported_font
    end

    def list
      return all_list unless @name

      font_list || raise_non_supported_font
    end

    def all
      all_formulas.map(&:fonts).flatten
    end

    private

    attr_reader :name

    def find_system_font
      paths = Fontist::SystemFont.find(name)
      unless paths
        Fontist.ui.say(%(Font "#{name}" not found locally.))
        return
      end

      print_paths(paths)
    end

    def print_paths(paths)
      Fontist.ui.say("Fonts found at:")
      paths.each do |path|
        font_path = FontPath.new(path)
        Fontist.ui.say(font_path.to_s)
      end
    end

    def check_or_create_fontist_path!
      unless Fontist.fonts_path.exist?
        require "fileutils"
        FileUtils.mkdir_p(Fontist.fonts_path)
      end
    end

    def install_formula
      download_formula || make_suggestions || raise_formula_not_found
    end

    def download_formula
      formula = Formula.find_by_key_or_name(@name)
      return unless formula
      return unless formula.downloadable?

      request_formula_installation(formula)
    end

    def make_suggestions
      return unless Fontist.interactive?

      suggestions = fuzzy_search_formulas
      return if suggestions.empty?

      choice = offer_to_choose(suggestions)
      return unless choice

      request_formula_installation(choice)
    end

    def fuzzy_search_formulas
      @formula_suggestion ||= FormulaSuggestion.new
      @formula_suggestion.find(@name)
    end

    def offer_to_choose(formulas)
      Fontist.ui.say("Formula '#{@name}' not found. Did you mean?")

      formulas.each_with_index do |formula, index|
        Fontist.ui.say("[#{index}] #{formula.name}")
      end

      choice = Fontist.ui.ask("Please type number or " \
                              "press ENTER to skip installation:").chomp
      return unless choice.to_i.to_s == choice

      formulas[choice.to_i]
    end

    def raise_formula_not_found
      raise Errors::FormulaNotFoundError.new(@name)
    end

    def font_installer(formula)
      options = { no_progress: @no_progress }
      return FontInstaller.new(formula, **options) if @by_formula

      FontInstaller.new(formula, font_name: @name, **options)
    end

    def sufficient_formulas
      @sufficient_formulas ||=
        FormulaPicker.new(@name,
                          size_limit: @size_limit,
                          version: @version,
                          smallest: @smallest,
                          newest: @newest)
          .call(downloadable_formulas)
    end

    def downloadable_formulas
      @downloadable_formulas ||= formulas.select(&:downloadable?)
    end

    def manual_formulas
      @manual_formulas ||= formulas.reject(&:downloadable?)
    end

    def formulas
      @formulas ||= Fontist::Formula.find_many(name)
        .select { |f| supported_formula?(f) }
    end

    def supported_formula?(formula)
      return true if formula.platforms.nil?

      formula.platforms.any? do |platform|
        Utils::System.match?(platform)
      end
    end

    def downloadable_font
      return if downloadable_formulas.empty?

      raise Fontist::Errors::MissingFontError.new(name)
    end

    def download_font
      return if sufficient_formulas.empty?

      paths = sufficient_formulas.flat_map do |formula|
        request_formula_installation(formula)
      end

      update_fontconfig

      paths
    end

    def request_formula_installation(formula)
      confirmation = check_and_confirm_required_license(formula)
      paths = font_installer(formula).install(confirmation: confirmation)

      if paths.nil? || paths.empty?
        Fontist.ui.error("Fonts not found in formula #{formula}")
        return
      end

      Fontist.ui.say("Fonts installed at:")
      paths.each do |path|
        Fontist.ui.say("- #{path}")
      end
    end

    def check_and_confirm_required_license(formula)
      return @confirmation unless formula.license_required?

      show_license(formula) unless @hide_licenses
      return @confirmation if @confirmation.casecmp?("yes")

      confirmation = ask_for_agreement
      return confirmation if confirmation&.casecmp?("yes")

      raise Fontist::Errors::LicensingError.new(
        "Fontist will not download these fonts unless you accept the terms.",
      )
    end

    def show_license(formula)
      Fontist.ui.say(license_agrement_message(formula))
    end

    def ask_for_agreement
      Fontist.ui.ask(
        "\nDo you accept all presented font licenses, and want Fontist " \
        "to download these fonts for you? => TYPE 'Yes' or 'No':",
      )
    end

    def license_agrement_message(formula)
      human_name = human_name(formula)

      <<~MSG
        FONT LICENSE ACCEPTANCE REQUIRED FOR "#{human_name}":

        Fontist can install this font if you accept its licensing conditions.

        FONT LICENSE BEGIN ("#{human_name}")
        -----------------------------------------------------------------------
        #{formula.license}
        -----------------------------------------------------------------------
        FONT LICENSE END ("#{human_name}")
      MSG
    end

    def human_name(formula)
      return formula.name if @by_formula

      formula.font_by_name(@name).name
    end

    def update_fontconfig
      return unless @update_fontconfig

      Fontconfig.update
    end

    def manual_font
      return if manual_formulas.empty?

      raise Fontist::Errors::ManualFontError.new(name, manual_formulas.first)
    end

    def uninstall_font
      paths = find_fontist_paths
      return unless paths

      paths.each do |path|
        File.delete(path)
      end

      paths
    end

    def find_fontist_paths
      fonts = Fontist::SystemIndex.fontist_index.find(name, nil)
      return unless fonts

      fonts.map(&:path)
    end

    def installed_paths
      print_paths(SystemFont.font_paths)
    end

    def all_formulas
      Fontist::Formula.all.select { |f| supported_formula?(f) }
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
      return if formulas.empty?

      list_styles(formulas)
    end

    def list_styles(formulas)
      map_to_hash(formulas) do |formula|
        map_to_hash(requested_fonts(formula.fonts)) do |font|
          map_to_hash(font.styles) do |style|
            installed(style)
          end
        end
      end
    end

    def map_to_hash(elements)
      elements.map { |e| [e, yield(e)] }.to_h
    end

    def requested_fonts(fonts)
      return fonts unless @name

      fonts&.select do |font|
        font.name.casecmp?(name)
      end
    end

    def installed(style)
      path(style) ? true : false
    end

    def raise_non_supported_font
      raise Fontist::Errors::UnsupportedFontError.new(@name)
    end
  end
end
