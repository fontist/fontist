module Fontist
  module Helper
    def stub_fontist_path_to_temp_path
      allow(Fontist).to receive(:fontist_path).and_return(
        Fontist.root_path.join("spec", "fixtures")
      )
    end

    def fixtures_dir
      Dir.chdir(Fontist.root_path.join("spec", "fixtures")) do
        yield
      end
    end
  end
end

