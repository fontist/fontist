RSpec.shared_context "empty home" do
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

    Fontist::Index.reset_cache
  end

  after do
    Fontist::Index.reset_cache
  end
end
