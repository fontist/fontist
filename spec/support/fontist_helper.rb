module Fontist
  module Helper
    def stub_fontist_path_to_assets
      allow(Fontist).to receive(:fontist_path).and_return(Fontist.assets_path)
    end
  end
end

