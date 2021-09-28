require "fontist/font_installer"
require "fontist/font_path"

module Fontist
  class Font
    def initialize(options = {})
      @name = options[:name]
      @confirmation = options[:confirmation] || "no"
      @hide_licenses = options[:hide_licenses]
      @no_progress = options[:no_progress] || false
      @force = options[:force] || false

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
      find_system_font || downloadable_font || raise_non_supported_font
    end

    def install
      (find_system_font unless @force) || download_font || raise_non_supported_font
    end

    def uninstall
      uninstall_font || downloadable_font || raise_non_supported_font
    end

    def status
      return installed_paths unless @name

      find_system_font || downloadable_font || raise_non_supported_font
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

    def font_installer(formula)
      FontInstaller.new(formula, no_progress: @no_progress)
    end

    def formula
      @formula ||= formulas.first
    end

    def formulas
      @formulas ||= Fontist::Formula.find_many(name)
        .select { |f| supported_formula?(f) }
    end

    def supported_formula?(formula)
      formula.platforms.nil? ||
        formula.platforms.include?(Fontist::Utils::System.user_os.to_s)
    end

    def downloadable_font
      if formula
        raise Fontist::Errors::MissingFontError.new(name)
      end
    end

    def download_font
      return if formulas.empty?

      formulas.flat_map do |formula|
        confirmation = check_and_confirm_required_license(formula)
        paths = font_installer(formula).install(confirmation: confirmation)

        Fontist.ui.say("Fonts installed at:")
        paths.each do |path|
          Fontist.ui.say("- #{path}")
        end
      end
    end

    def check_and_confirm_required_license(formula)
      return @confirmation unless formula.license_required

      show_license(formula.license) unless @hide_licenses
      return @confirmation if @confirmation.casecmp?("yes")

      confirmation = ask_for_agreement
      return confirmation if confirmation&.casecmp?("yes")

      raise Fontist::Errors::LicensingError.new(
        "Fontist will not download these fonts unless you accept the terms."
      )
    end

    def show_license(license)
      Fontist.ui.say(license_agrement_message(license))
    end

    def ask_for_agreement
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

      fonts.map do |font|
        font[:path]
      end
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
      raise Fontist::Errors::UnsupportedFontError.new(@name)
    end
  end
end
