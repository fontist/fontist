RSpec.shared_context "fresh home" do
  attr_reader :temp_dir

  around do |example|
    Dir.mktmpdir do |dir|
      @temp_dir = dir

      example.run

      @temp_dir = nil
    end
  end

  before do
    allow(Fontist).to receive(:default_fontist_path)
      .and_return(Pathname.new(temp_dir))

    stub_system_fonts

    FileUtils.mkdir_p(Fontist.fonts_path)
    FileUtils.mkdir_p(Fontist.formulas_path)

    Fontist::Config.reset
    Fontist::Index.reset_cache
    Fontist::SystemIndex.reset_cache
    Fontist::SystemFont.reset_font_paths_cache
  end

  after do
    Fontist::Index.reset_cache
    Fontist::SystemIndex.reset_cache
    Fontist::SystemFont.reset_font_paths_cache
  end
end
