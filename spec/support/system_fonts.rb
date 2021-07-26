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
    allow(YAML).to receive(:load_file).with(Fontist.system_file_path)
      .and_return(system_paths(system_dir))

    allow(YAML).to receive(:load_file).and_call_original
  end
end
