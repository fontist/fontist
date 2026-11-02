require "fontisan"

module FontOperationsHelper
  def font_full_name(path, index: 0)
    Fontisan::FontLoader.load(path, font_index: index)
      .table("name").english_name(Fontisan::Tables::Name::FULL_NAME)
  end

  def font_magic(path)
    File.binread(path, 4)
  end

  # Installs one font file through FontInstaller with the given format
  # options. Needs `formula` and `license` from the example group.
  def install_with_operations(path, **spec)
    format_spec = Fontist::FormatSpec.from_options(spec)
    installer = Fontist::FontInstaller.new(formula, format_spec: format_spec,
                                                    confirmation: license)
    installer.send(:install_font_file, path)
  end
end

RSpec.configure { |config| config.include FontOperationsHelper }

module FontistHomeMacro
  # `it` that runs inside a fresh fontist home.
  def home_it(description, &block)
    it(description) { fresh_fonts_and_formulas { instance_exec(&block) } }
  end
end

RSpec.configure { |config| config.extend FontistHomeMacro }
