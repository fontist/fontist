module Fontist
  class << self
    alias_method :orig_default_fontist_path, :default_fontist_path
    def default_fontist_path
      temp_fontist_path
    end

    def temp_fontist_path
      @temp_fontist_path ||= Pathname.new(Dir.mktmpdir)
    end

    # Reuse cached downloads
    def downloads_path
      orig_default_fontist_path.join("downloads")
    end

    alias_method :orig_system_file_path, :system_file_path
    def system_file_path
      Fontist.root_path.join("spec", "fixtures", "system.yml")
    end
  end

  class SystemFont
    class << self
      # avoid caching
      def system_font_paths
        load_system_font_paths
      end
    end
  end
end

RSpec.configure do |config|
  config.before(:suite) do
    FileUtils.mkdir_p(Fontist.fonts_path)
    FileUtils.mkdir_p(Fontist.formulas_path)

    Fontist::Index.reset_cache
  end

  config.before(:suite) do
    example_formula("andale.yml")
    example_formula("lato.yml")
    example_formula("courier.yml")
    example_formula("webcore.yml")
    Fontist::Index.rebuild
  end

  def example_formula(filename)
    example_path = File.join("spec", "examples", "formulas", filename)
    target_path = Fontist.formulas_path.join(filename)
    FileUtils.cp(example_path, target_path)
  end

  config.after(:suite) do
    FileUtils.rm_rf(Fontist.temp_fontist_path)
    Fontist::Index.reset_cache
  end
end
