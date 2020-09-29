module Fontist
  module Helper
    def stub_fontist_path_to_temp_path
      allow(Fontist).to receive(:fontist_path).and_return(
        Fontist.root_path.join("spec", "fixtures")
      )
    end

    def stub_fonts_path_to_new_path
      Dir.mktmpdir do |dir|
        allow(Fontist).to receive(:fonts_path).and_return(Pathname.new(dir))
        yield
      end
    end

    def stub_system_fonts
      allow(Fontist::SystemFont).to receive(:find).and_return(nil)
    end

    def stub_system_font_finder_to_fixture(name)
      allow(Fontist::SystemFont).to receive(:find).
        and_return(["spec/fixtures/fonts/#{name}"])
    end

    def stub_license_agreement_prompt_with(confirmation = "yes")
      allow(Fontist.ui).to receive(:ask).and_return(confirmation)
    end

    def fixtures_dir
      Dir.chdir(Fontist.root_path.join("spec", "fixtures")) do
        yield
      end
    end

    def font_file(filename)
      Pathname.new(Fontist.fonts_path.join(filename))
    end
  end
end

