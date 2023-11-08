RSpec.shared_context "system fonts" do
  attr_reader :system_dir

  around do |example|
    Dir.mktmpdir do |dir|
      @system_dir = dir

      example.run

      @system_dir = nil
    end
  end

  before do
    new_paths = system_paths(system_dir)
    allow(Fontist::SystemFont).to receive(:system_config).and_return(new_paths)

    disable_system_font_paths_caching
  end
end
