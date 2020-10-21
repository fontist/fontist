module Fontist
  module Helper
    def stub_fontist_path_to_temp_path
      allow(Fontist).to receive(:fontist_path).and_return(
        Fontist.root_path.join("spec", "fixtures")
      )
    end

    def stub_fonts_path_to_new_path
      Dir.mktmpdir do |dir|
        path = Dir.glob(dir).first # expand the ~1 suffix on Windows
        allow(Fontist).to receive(:fonts_path).and_return(Pathname.new(path))
        yield
      end
    end

    def stub_system_fonts_path_to_new_path
      Dir.mktmpdir do |dir|
        path = Dir.glob(dir).first # expand the ~1 suffix on Windows

        system_file = Tempfile.new
        system_file.write(YAML.dump(system_paths(path)))
        system_file.close

        stub_system_fonts(system_file)

        yield path
      end
    end

    def system_paths(path)
      pattern = File.join(path, "**", "*.{ttf,ttc}")
      paths = Array.new(4, "paths" => [pattern])
      { "system" => %w[linux windows macos unix].zip(paths).to_h }
    end

    def stub_system_fonts(system_file = nil)
      allow(Fontist).to receive(:system_file_path).and_return(
        system_file || Fontist.root_path.join("spec", "fixtures", "system.yml")
      )
    end

    def stub_system_font_finder_to_fixture(name)
      allow(Fontist::SystemFont).to receive(:find)
        .and_return(["spec/fixtures/fonts/#{name}"])
    end

    def stub_system_font_to(name)
      allow(Fontist::SystemFont).to receive(:find).and_return([name])
    end

    def stub_license_agreement_prompt_with(confirmation = "yes")
      allow(Fontist.ui).to receive(:ask).and_return(confirmation)
    end

    def fixtures_dir
      Dir.chdir(Fontist.root_path.join("spec", "fixtures")) do
        yield
      end
    end

    def stub_font_file(filename, dir = nil)
      dir ||= Fontist.fonts_path.to_s
      FileUtils.touch(File.join(dir, filename))
    end

    def font_file(filename)
      Pathname.new(Fontist.fonts_path.join(filename))
    end

    def font_path(filename, dir = nil)
      dir ||= Fontist.fonts_path.to_s
      File.join(dir, filename)
    end
  end
end
