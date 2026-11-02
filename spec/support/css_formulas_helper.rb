module CssFormulasHelper
  CSS_FIXTURES = File.expand_path("../fixtures/css/Formulas", __dir__)

  # Copies css fixture formulas (by file name) into the isolated formulas
  # path and rebuilds the index. Call inside fresh_fonts_and_formulas.
  def install_css_formulas(*names)
    names.each do |name|
      source = Dir[File.join(CSS_FIXTURES, "**", "#{name}.yml")].first
      subdir = File.basename(File.dirname(source)) == "google" ? "google" : ""
      target = Fontist.formulas_path.join(subdir, "#{name}.yml")
      FileUtils.mkdir_p(target.dirname)
      FileUtils.cp(source, target)
    end
    Fontist::Index.rebuild
  end

  # Writes a placeholder font file into the fontist fonts path.
  def install_fake(stem, ext = "ttf")
    path = Fontist.fonts_path.join("space_mono", "#{stem}.#{ext}")
    FileUtils.mkdir_p(path.dirname)
    File.binwrite(path, "FAKE-#{stem}-#{ext}")
    path
  end

  def install_fake_fonts(stems, ext = "ttf")
    stems.each_value { |stem| install_fake(stem, ext) }
  end

  def with_out_dir
    Dir.mktmpdir { |dir| yield File.join(dir, "out") }
  end

  # Runs `fontist css ARGS` and returns [status, stdout, stderr].
  def run_css(*args)
    out = StringIO.new
    err = StringIO.new
    $stdout = out
    $stderr = err
    status = Fontist::CLI.start(["css", *args])
    [status, out.string, err.string]
  ensure
    $stdout = STDOUT
    $stderr = STDERR
  end
end

RSpec.configure { |config| config.include CssFormulasHelper }

module CssExampleMacro
  CSS_ALL = %w[source_code_pro space_mono lato source_sans_3 roboto
               andale].freeze

  # `it` that runs in an isolated fontist home with css fixture formulas.
  def css_it(description, formulas: CSS_ALL, &block)
    it(description) do
      fresh_fonts_and_formulas do
        install_css_formulas(*formulas)
        instance_exec(&block)
      end
    end
  end
end

RSpec.configure { |config| config.extend CssExampleMacro }
